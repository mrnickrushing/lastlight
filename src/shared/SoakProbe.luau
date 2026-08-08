--!strict

--[[
    Whether a server left running is holding on to things.

    M12's soak gate asks that nothing grows without bound over a long
    session. The tempting way to check that is to read a counter at the
    start and again at the end and subtract, and it is wrong in three ways
    that all produce a pass on a leaking build.

    **The first cycle is not a baseline.** A server builds its town,
    spawns its residents and wires its world on the way into cycle one, so
    every one-time allocation in the game lands between the first sample
    and the second. Measured from sample one, a build that then holds
    perfectly steady reports a leak; widen the tolerance until that stops
    and the tolerance is now wide enough to hide a real one. So the
    baseline is the **second** sample, and a soak that has not run three
    cycles has not measured anything.

    **A sample is only comparable to a sample taken at the same point in
    the cycle.** Instance count during a night is legitimately higher than
    at dawn -- there are creatures in the world. A series that drifted
    across phases would produce a number that means nothing, and it would
    look exactly like a number that means something. Every sample carries
    the phase it was taken at and a series that mixes them is refused
    rather than averaged.

    **A leak's signature is that it does not stop.** A metric can rise at
    every single sample and still sit under a flat tolerance for the
    length of a test, which is the shape of every leak that was ever
    shipped: it was small enough for an hour. So growth is judged per
    cycle rather than in total, and a metric that rose at every step from
    the baseline onward is a breach on its own -- it has not levelled off,
    and a run twice as long would not have passed.

    One metric is declared **unobservable** and it is the one the gate
    names first: Roblox exposes no count of live script connections. There
    is no API, so a number here would be a number this game invented, and
    a gate reading an invented number is worse than a gate reading
    nothing. What a soak *can* watch is the residue this game leaves for
    itself -- the per-player tables every service keeps -- and that is a
    real metric with a real reading, because a connection that outlives a
    player is a connection whose table entry outlives them too. The count
    of unobservable metrics is pinned by its spec for the same reason the
    release gates pin their `review` rows: a threshold nobody wants to
    instrument becoming a second one is how a gate quietly stops being a
    gate.

    Pure. No Roblox services, no clock, no instances. Whatever samples it
    hands it numbers.
]]

local SoakProbe = {}

export type Verdict = "ok" | "watch" | "breach" | "incomplete"

export type Metric = {
    id: string,
    label: string,
    -- What one more cycle is allowed to add. A leak scales with cycles, so
    -- the allowance does too; a flat budget passes any leak slow enough.
    perCycleAllowance: number,
    --[[
        Whether the runtime can answer this at all. A metric declared
        unobservable is reported as such and never contributes a verdict,
        which is different from a metric nobody happened to sample.
    ]]
    observable: boolean,
    why: string,
}

export type Sample = {
    cycle: number,
    phase: string,
    counts: { [string]: number },
}

export type Run = {
    phase: string,
    samples: { Sample },
}

export type MetricReport = {
    id: string,
    verdict: Verdict,
    -- Why it read that way, so a breach names which of the two it is.
    reason: string,
    baseline: number,
    last: number,
    growthPerCycle: number,
    allowance: number,
    monotone: boolean,
    cycles: number,
}

export type Report = {
    verdict: Verdict,
    cycles: number,
    metrics: { MetricReport },
    missing: { string },
    unobservable: { string },
}

-- Three samples is the least that can say anything: one to warm up, one to
-- be the baseline, one to be compared against it.
SoakProbe.MinimumCycles = 3

--[[
    How many samples a monotone rise has to span before it is a breach on
    its own. Over three samples "rose every time" is two coin flips and
    happens by accident on a metric that idles between two values; over
    five it is a slope.
]]
SoakProbe.MonotoneCycles = 5

local ORDER: { string } = {
    "instances",
    "connections",
    "tracked_enemies",
    "player_residue",
    "profile_bytes",
}

local DEFINITIONS: { [string]: Metric } = {
    instances = table.freeze({
        id = "instances",
        label = "Instances under the world",
        --[[
            Not zero. Dressing a town is not instant and a decoration a
            player placed on cycle four is a permanent instance that is
            supposed to persist, so a hard zero would fail on the game
            working. Sixteen a cycle is far under any leak that matters
            and far over the handful a played cycle legitimately adds.
        ]]
        perCycleAllowance = 16,
        observable = true,
        why = "A creature, a marker or a billboard that is never destroyed is an "
            .. "instance the world keeps forever.",
    }),
    connections = table.freeze({
        id = "connections",
        label = "Live script connections",
        perCycleAllowance = 0,
        observable = false,
        why = "Roblox exposes no count of live connections. A number here would be "
            .. "one this game invented, so the residue metric watches the tables a "
            .. "leaked connection would keep alive instead.",
    }),
    tracked_enemies = table.freeze({
        id = "tracked_enemies",
        label = "Creatures the server still believes in",
        -- Zero, and this one really is zero: a night ends by clearing its
        -- queue, so a creature outliving the night it belongs to is the
        -- bug rather than a cost of playing.
        perCycleAllowance = 0,
        observable = true,
        why = "A defeated creature still counted is a wave schedule that stalls "
            .. "behind something nobody can fight.",
    }),
    player_residue = table.freeze({
        id = "player_residue",
        label = "Entries held for players who have left",
        perCycleAllowance = 0,
        observable = true,
        why = "Every service keeps tables keyed by player. One that survives the "
            .. "player is the observable half of a connection that survived them.",
    }),
    profile_bytes = table.freeze({
        id = "profile_bytes",
        label = "Encoded size of a profile",
        --[[
            A profile is supposed to grow -- a night survived, a recipe
            crafted, a seed walked are all things a save remembers. What
            it may not do is grow *per cycle without bound*, which is why
            the seed history is capped. 256 bytes a cycle is generous for
            the former and nowhere near enough to hide the latter.
        ]]
        perCycleAllowance = 256,
        observable = true,
        why = "A save that grows every night eventually stops fitting in a "
            .. "DataStore value, and it fails for the player who played most.",
    }),
}

SoakProbe.Order = table.freeze(ORDER)
SoakProbe.Metrics = table.freeze(DEFINITIONS)

function SoakProbe.metric(metricId: any): Metric?
    return if type(metricId) == "string" then DEFINITIONS[metricId] else nil
end

function SoakProbe.isObservable(metricId: any): boolean
    local definition = SoakProbe.metric(metricId)
    return definition ~= nil and definition.observable
end

--[[
    Start a run at a named phase. The phase is fixed here rather than read
    off the first sample, because a sampler wired to the wrong hook would
    otherwise define its own correctness.
]]
function SoakProbe.begin(phase: string): Run
    assert(type(phase) == "string" and phase ~= "", "a soak run needs a phase to sample at")
    return { phase = phase, samples = {} }
end

export type RecordResult = {
    accepted: boolean,
    reason: string,
}

--[[
    Add one cycle's counts. Refused, rather than absorbed, when the sample
    cannot be compared to the ones beside it: a different phase means a
    different question, and a repeated or reversed cycle number means the
    sampler fired twice and would halve the apparent growth of a real
    leak.
]]
function SoakProbe.record(run: Run, cycle: any, phase: any, counts: any): (Run, RecordResult)
    if type(cycle) ~= "number" or cycle ~= math.floor(cycle) or cycle < 1 then
        return run, { accepted = false, reason = "cycle_invalid" }
    end
    if phase ~= run.phase then
        return run, { accepted = false, reason = "phase_mismatch" }
    end
    if type(counts) ~= "table" then
        return run, { accepted = false, reason = "counts_invalid" }
    end
    local previous = run.samples[#run.samples]
    if previous ~= nil and cycle <= previous.cycle then
        return run, { accepted = false, reason = "cycle_repeated" }
    end

    local kept: { [string]: number } = {}
    for metricId, value in counts do
        --[[
            An unknown metric is dropped rather than carried, and an
            unobservable one is dropped too: accepting a reading for
            `connections` would let a caller quietly supply the invented
            number this module exists to refuse.
        ]]
        if
            SoakProbe.isObservable(metricId)
            and type(value) == "number"
            and value == value
            and value >= 0
            and value < math.huge
        then
            kept[metricId] = value
        end
    end

    local nextRun: Run = { phase = run.phase, samples = table.clone(run.samples) }
    table.insert(nextRun.samples, { cycle = cycle, phase = phase, counts = kept })
    return nextRun, { accepted = true, reason = "recorded" }
end

local function reportFor(run: Run, definition: Metric): MetricReport?
    local values: { number } = {}
    local cycles: { number } = {}
    for _, sample in run.samples do
        local value = sample.counts[definition.id]
        if value ~= nil then
            table.insert(values, value)
            table.insert(cycles, sample.cycle)
        end
    end
    if #values < SoakProbe.MinimumCycles then
        return nil
    end

    -- The second sample, because the first one paid for everything the
    -- server builds on its way in.
    local baseline = values[2]
    local last = values[#values]

    --[[
        Growth is measured over the **tail**, from the middle sample to the
        last, and that is a lesson a live run taught rather than a
        refinement. Emberhollow builds more of itself as it tiers up: a
        real seven-cycle soak stepped 982 instances in one cycle when the
        town raised new buildings, then held flat for three. Measured from
        the baseline that reads as 200 a cycle forever, so a healthy server
        breaches on the game working -- and a gate that cries wolf on every
        server is a gate nobody reads.

        The tail asks the question the gate actually has: **is it still
        growing?** A one-time build-out is over by the time the tail starts;
        a leak is not, because a leak is defined by not stopping. It is also
        the rule `PerformanceBudget` already argued for on frame rate: judge
        the tail, because a mean hides the thing you are looking for.
    ]]
    local middle = math.max(2, math.ceil((#values + 1) / 2))
    local from = values[middle]
    local span = cycles[#cycles] - cycles[middle]
    local growth = if span > 0 then (last - from) / span else 0

    local monotone = true
    for index = 3, #values do
        if values[index] <= values[index - 1] then
            monotone = false
            break
        end
    end

    --[[
        Two ways to fail, and they are worth telling apart in the report
        rather than only in the verdict. `over_allowance` is a metric
        growing faster than it is allowed to. `still_climbing` is the
        quieter one: under the allowance, and up at every step from the
        baseline, so this run passed and a longer one would not have --
        which makes it a result about the length of the test rather than
        about the build.
    ]]
    local overAllowance = growth > definition.perCycleAllowance
    local stillClimbing = monotone and #values >= SoakProbe.MonotoneCycles

    local verdict: Verdict = "ok"
    local reason = "steady"
    if overAllowance or stillClimbing then
        verdict = "breach"
        reason = if overAllowance then "over_allowance" else "still_climbing"
    elseif monotone and growth > 0 then
        verdict = "watch"
        reason = "climbing"
    end

    return {
        id = definition.id,
        verdict = verdict,
        reason = reason,
        baseline = baseline,
        last = last,
        growthPerCycle = growth,
        allowance = definition.perCycleAllowance,
        monotone = monotone,
        cycles = #values,
    }
end

--[[
    The run's verdict. A metric nobody sampled is `missing` and drags the
    whole run to `incomplete`, which is PerformanceBudget's rule and the
    same reasoning: the failure a soak gate exists to catch is somebody
    claiming a pass for something nobody looked at.
]]
function SoakProbe.report(run: Run): Report
    local metrics: { MetricReport } = {}
    local missing: { string } = {}
    local unobservable: { string } = {}
    local worst: Verdict = "ok"

    for _, metricId in ORDER do
        local definition = DEFINITIONS[metricId]
        if not definition.observable then
            table.insert(unobservable, metricId)
            continue
        end
        local report = reportFor(run, definition)
        if report == nil then
            table.insert(missing, metricId)
        else
            table.insert(metrics, report)
            if report.verdict == "breach" then
                worst = "breach"
            elseif report.verdict == "watch" and worst == "ok" then
                worst = "watch"
            end
        end
    end

    if #missing > 0 and worst ~= "breach" then
        worst = "incomplete"
    end

    return {
        verdict = worst,
        cycles = #run.samples,
        metrics = metrics,
        missing = missing,
        unobservable = unobservable,
    }
end

return table.freeze(SoakProbe)
