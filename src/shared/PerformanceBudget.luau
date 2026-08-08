--!strict

--[[
    The performance budgets from docs/TECHNICAL_ARCHITECTURE.md, as data.

    Milestone 3's exit gate asks that "target device meets frame, memory, join,
    and network budgets for a 30-minute run." That sentence is only checkable
    if the budgets are numbers and the run produces samples, so both live here:
    the thresholds the architecture doc already fixed, and the arithmetic that
    turns a pile of samples into a verdict.

    Three things this module deliberately does:

      * It judges a tail, not an average. A 30-minute run that averages 50 FPS
        while stuttering through every night is a run that failed, and a mean
        hides exactly that. Each metric names the percentile that decides it --
        the low tail when higher is better, the high tail when lower is worse.
      * A metric with no samples is never "ok". An unmeasured budget reports
        `incomplete`, because the failure this gate exists to catch is claiming
        a pass for something nobody looked at.
      * It is pure. No Roblox services, no players, no clock. Whatever samples
        it, from the server or from a client, hands it numbers.

    The numbers are the architecture doc's, not new ones. Where that doc gave a
    qualitative hard threshold rather than a figure, the reading taken here is
    marked so it can be argued with instead of being quietly invented.
]]

local Config = require("./Config")

local PerformanceBudget = {}

export type Direction = "higher_is_better" | "lower_is_better"
export type Verdict = "ok" | "watch" | "breach" | "incomplete"

export type Definition = {
    id: string,
    label: string,
    unit: string,
    direction: Direction,
    target: number,
    hard: number,
    -- The percentile that decides this metric's verdict: the tail where the
    -- bad samples live.
    percentile: number,
    source: string,
}

export type Summary = {
    id: string,
    count: number,
    discarded: number,
    min: number,
    max: number,
    mean: number,
    p50: number,
    value: number,
    verdict: Verdict,
}

export type Report = {
    verdict: Verdict,
    metrics: { Summary },
    missing: { string },
}

local ORDER: { string } = {
    "join_seconds",
    "client_fps",
    "frame_spike_ms",
    "server_heartbeat_hz",
    "client_memory_headroom",
    "remote_actions_per_second",
}

local DEFINITIONS: { [string]: Definition } = {
    join_seconds = {
        id = "join_seconds",
        label = "Interactive join, warm network",
        unit = "s",
        direction = "lower_is_better",
        target = 5,
        hard = 8,
        percentile = 95,
        source = "TECHNICAL_ARCHITECTURE.md performance budgets",
    },
    client_fps = {
        id = "client_fps",
        label = "Client frame rate, normal play",
        unit = "FPS",
        direction = "higher_is_better",
        target = 45,
        hard = 30,
        -- "Sustained < 30 FPS" is the doc's failure case. The 5th percentile
        -- is the reading of "sustained": a fifth of a second in twenty spent
        -- below the line is a stutter, a twentieth of the whole run below it
        -- is the run being slow.
        percentile = 5,
        source = "TECHNICAL_ARCHITECTURE.md performance budgets",
    },
    frame_spike_ms = {
        id = "frame_spike_ms",
        label = "Client frame time spikes",
        unit = "ms",
        direction = "lower_is_better",
        target = 50,
        hard = 100,
        percentile = 95,
        source = "TECHNICAL_ARCHITECTURE.md performance budgets",
    },
    server_heartbeat_hz = {
        id = "server_heartbeat_hz",
        label = "Server heartbeat",
        unit = "Hz",
        direction = "higher_is_better",
        target = 30,
        hard = 20,
        percentile = 5,
        source = "TECHNICAL_ARCHITECTURE.md performance budgets",
    },
    client_memory_headroom = {
        id = "client_memory_headroom",
        label = "Client memory headroom",
        unit = "ratio",
        direction = "higher_is_better",
        target = 0.2,
        -- The doc's hard threshold here is "OOM/reload risk", which is a
        -- consequence rather than a number. Half the target is the reading
        -- taken: below a tenth of the device's memory free, a Roblox client
        -- is one asset load from being killed. Argue with this figure before
        -- the slice closes -- it is the one budget here nobody measured yet.
        hard = 0.1,
        percentile = 5,
        source = "TECHNICAL_ARCHITECTURE.md, numeric reading of OOM risk",
    },
    remote_actions_per_second = {
        id = "remote_actions_per_second",
        label = "Remote traffic, actions per client",
        unit = "/s",
        direction = "lower_is_better",
        -- The action limiter already owns this budget, so the budget is the
        -- limiter's own configuration rather than a second opinion: sustained
        -- traffic at the rate, never above the burst ceiling.
        target = Config.ActionRatePerSecond,
        hard = Config.ActionRatePerSecond * 2,
        percentile = 95,
        source = "Config.ActionRatePerSecond",
    },
}

local SEVERITY: { [string]: number } = {
    ok = 0,
    watch = 1,
    incomplete = 2,
    breach = 3,
}

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function PerformanceBudget.order(): { string }
    return table.clone(ORDER)
end

function PerformanceBudget.definition(metricId: string): Definition
    local definition = DEFINITIONS[metricId]
    assert(definition ~= nil, string.format("unknown performance metric %q", tostring(metricId)))
    return definition
end

function PerformanceBudget.isValidMetric(value: any): boolean
    return type(value) == "string" and DEFINITIONS[value] ~= nil
end

-- Where a single sample falls against its budget. Used for live warnings while
-- a run is in progress; the verdict that closes the gate comes from summarize.
function PerformanceBudget.classify(metricId: string, value: number): Verdict
    local definition = PerformanceBudget.definition(metricId)
    if not finite(value) then
        return "incomplete"
    end
    if definition.direction == "higher_is_better" then
        if value >= definition.target then
            return "ok"
        elseif value >= definition.hard then
            return "watch"
        end
        return "breach"
    end
    if value <= definition.target then
        return "ok"
    elseif value <= definition.hard then
        return "watch"
    end
    return "breach"
end

function PerformanceBudget.percentile(sorted: { number }, percentile: number): number
    local count = #sorted
    assert(count > 0, "percentile needs at least one sample")
    if count == 1 then
        return sorted[1]
    end
    local rank = (percentile / 100) * (count - 1) + 1
    local low = math.floor(rank)
    local high = math.ceil(rank)
    if low == high then
        return sorted[low]
    end
    return sorted[low] + (sorted[high] - sorted[low]) * (rank - low)
end

function PerformanceBudget.summarize(metricId: string, samples: { number }): Summary?
    local definition = PerformanceBudget.definition(metricId)

    -- A NaN would sort unpredictably and an infinity would swallow the tail,
    -- so garbage is counted and dropped rather than allowed to decide a gate.
    local clean = {}
    local discarded = 0
    for _, sample in samples do
        if finite(sample) then
            table.insert(clean, sample)
        else
            discarded += 1
        end
    end
    if #clean == 0 then
        return nil
    end
    table.sort(clean)

    local total = 0
    for _, sample in clean do
        total += sample
    end
    local value = PerformanceBudget.percentile(clean, definition.percentile)

    return {
        id = metricId,
        count = #clean,
        discarded = discarded,
        min = clean[1],
        max = clean[#clean],
        mean = total / #clean,
        p50 = PerformanceBudget.percentile(clean, 50),
        value = value,
        verdict = PerformanceBudget.classify(metricId, value),
    }
end

--[[
    Roll every metric into one verdict.

    A metric with no samples lands in `missing` and forces the report to
    `incomplete`, which outranks `watch` deliberately: a budget nobody measured
    is a worse position to close a milestone from than one measured and found
    merely close to the line.
]]
function PerformanceBudget.report(samplesByMetric: { [string]: { number } }): Report
    local metrics: { Summary } = {}
    local missing: { string } = {}
    local worst = "ok"

    for _, metricId in ORDER do
        local samples = samplesByMetric[metricId]
        local summary = if samples == nil
            then nil
            else PerformanceBudget.summarize(metricId, samples)
        if summary == nil then
            table.insert(missing, metricId)
        else
            table.insert(metrics, summary)
            if SEVERITY[summary.verdict] > SEVERITY[worst] then
                worst = summary.verdict
            end
        end
    end

    if #missing > 0 and SEVERITY.incomplete > SEVERITY[worst] then
        worst = "incomplete"
    end

    return {
        verdict = worst :: Verdict,
        metrics = metrics,
        missing = missing,
    }
end

-- One line per metric, in the order the architecture doc lists them, for the
-- admin readout at the end of a run.
function PerformanceBudget.format(report: Report): { string }
    local lines = {}
    for _, summary in report.metrics do
        local definition = PerformanceBudget.definition(summary.id)
        table.insert(
            lines,
            string.format(
                "%s %s: p%d %.1f%s (target %.1f, hard %.1f, n=%d)",
                string.upper(summary.verdict),
                definition.label,
                definition.percentile,
                summary.value,
                definition.unit,
                definition.target,
                definition.hard,
                summary.count
            )
        )
    end
    for _, metricId in report.missing do
        table.insert(
            lines,
            string.format("INCOMPLETE %s: no samples", PerformanceBudget.definition(metricId).label)
        )
    end
    return lines
end

--[[
    Validate a client's self-reported frame and memory sample.

    Client-reported numbers are diagnostic and never authoritative: nothing
    here grants a player anything, so a lying client only corrupts its own row
    in the report. That is still worth refusing rather than clamping -- a
    rejected sample is visible in the discard count, while a clamped one turns
    into a plausible-looking data point that quietly moves a percentile.

    Returns nil for anything malformed or outside the range a real device can
    physically produce.
]]
function PerformanceBudget.sanitizeClientReport(payload: any): any
    if type(payload) ~= "table" or payload.schemaVersion ~= 1 then
        return nil
    end

    local fps = payload.fps
    local spikeMs = payload.spikeMs
    local memoryMb = payload.memoryMb
    if not finite(fps) or not finite(spikeMs) or not finite(memoryMb) then
        return nil
    end

    -- No device renders a thousand frames a second, stalls for a minute and
    -- keeps running, or addresses 32 GB from a Roblox client.
    if fps <= 0 or fps > 1000 then
        return nil
    end
    if spikeMs < 0 or spikeMs > 60000 then
        return nil
    end
    if memoryMb <= 0 or memoryMb > 32768 then
        return nil
    end

    -- Named rather than counted. A count was enough while the payload had four
    -- fields and a fifth was by definition smuggled; adding the platform label
    -- would have made room for one extra field of a client's choosing, which is
    -- the one-extra-field rule failing in the direction it was written against.
    for key in payload do
        if
            key ~= "schemaVersion"
            and key ~= "fps"
            and key ~= "spikeMs"
            and key ~= "memoryMb"
            and key ~= "platform"
        then
            return nil
        end
    end

    return {
        fps = fps,
        spikeMs = spikeMs,
        memoryMb = memoryMb,
    }
end

-- Memory headroom as a fraction of the baseline device's ceiling. Clamped to
-- zero rather than going negative: a client over the ceiling is at zero
-- headroom, and how far over tells the gate nothing it does not already know.
function PerformanceBudget.memoryHeadroom(memoryMb: number, ceilingMb: number): number
    assert(finite(ceilingMb) and ceilingMb > 0, "memory ceiling must be positive")
    if not finite(memoryMb) or memoryMb < 0 then
        return 0 / 0
    end
    return math.max(0, 1 - memoryMb / ceilingMb)
end

return table.freeze(PerformanceBudget)
