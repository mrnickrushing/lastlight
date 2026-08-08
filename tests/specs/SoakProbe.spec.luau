--!strict

--[[
    The soak gate, driven the three ways it can be wrong.

    M12 asks that N cycles leave the same counts they started with, within
    a declared tolerance. The cases below are less interested in the run
    that passes than in the runs that pass *wrongly*, because a soak that
    cannot fail is the most expensive kind of green: it is the one nobody
    re-runs.

    So: a build that leaks steadily has to fail; a build that allocates
    once on the way in has to pass, because otherwise the tolerance gets
    widened until it hides the first one; a series sampled at different
    points in the cycle has to be refused rather than averaged into a
    number that means nothing; and a metric nobody sampled has to read
    `incomplete` rather than `ok`.
]]

local fs = require("@lune/fs")

local SoakProbe = require("../../src/shared/SoakProbe")
local TestRunner = require("../TestRunner")

local function run(values: { { [string]: number } }, phase: string?): any
    local soak = SoakProbe.begin(phase or "day")
    for index, counts in values do
        local next, result = SoakProbe.record(soak, index, phase or "day", counts)
        TestRunner.equal(result.accepted, true, result.reason)
        soak = next
    end
    return soak
end

-- Everything but the metric under test, held flat, so a verdict is about
-- the one number that moved.
local function flat(instances: number): { [string]: number }
    return {
        instances = instances,
        tracked_enemies = 0,
        player_residue = 0,
        profile_bytes = 4096,
    }
end

return {
    name = "SoakProbe",
    cases = {
        {
            name = "a server that holds steady passes, and one that leaks does not",
            run = function()
                local steady = SoakProbe.report(run({
                    flat(9000),
                    flat(9120),
                    flat(9118),
                    flat(9124),
                    flat(9119),
                }))
                TestRunner.equal(steady.verdict, "ok")
                TestRunner.equal(#steady.missing, 0)

                -- 200 an hour-long cycle is nothing to look at and 200 a
                -- cycle for a night is a server that will not survive a
                -- session, which is the whole reason growth is judged per
                -- cycle rather than in total.
                local leaking = SoakProbe.report(run({
                    flat(9000),
                    flat(9120),
                    flat(9320),
                    flat(9520),
                    flat(9720),
                }))
                TestRunner.equal(leaking.verdict, "breach")
                for _, metric in leaking.metrics do
                    if metric.id == "instances" then
                        TestRunner.equal(metric.verdict, "breach")
                        TestRunner.equal(metric.baseline, 9120)
                        TestRunner.equal(metric.last, 9720)
                        TestRunner.equal(metric.growthPerCycle, 200)
                    end
                end
            end,
        },
        {
            --[[
                The case the baseline rule exists for. A server builds its
                town, spawns its residents and wires its world between the
                first sample and the second, and then holds. Measured from
                sample one that is a 1200-instance leak; measured from
                sample two it is a game working.
            ]]
            name = "the world a server builds on the way in is not a leak",
            run = function()
                local report = SoakProbe.report(run({
                    flat(400),
                    flat(9600),
                    flat(9600),
                    flat(9601),
                    flat(9600),
                }))
                TestRunner.equal(report.verdict, "ok")

                -- and two samples is not a measurement, because with two the
                -- baseline is also the last.
                local short = SoakProbe.report(run({ flat(400), flat(9600) }))
                TestRunner.equal(short.verdict, "incomplete")
                TestRunner.equal(#short.metrics, 0)
                TestRunner.truthy(#short.missing > 0)
            end,
        },
        {
            --[[
                The leak that hides under a tolerance. Four instances a
                cycle is well inside the sixteen the metric allows, and it
                has not stopped -- a run twice as long fails and this one
                passes, which is a gate that reports on the length of the
                test rather than on the build.
            ]]
            name = "a metric that has not levelled off is a breach under its own tolerance",
            run = function()
                local climbing = SoakProbe.report(run({
                    flat(9000),
                    flat(9100),
                    flat(9104),
                    flat(9108),
                    flat(9112),
                    flat(9116),
                }))
                TestRunner.equal(climbing.verdict, "breach")

                -- but the same drift that stops is not: a metric that rose
                -- and then settled has settled, and calling that a leak is
                -- how a tolerance gets widened.
                local settled = SoakProbe.report(run({
                    flat(9000),
                    flat(9100),
                    flat(9104),
                    flat(9108),
                    flat(9108),
                    flat(9108),
                }))
                TestRunner.equal(settled.verdict, "ok")

                -- and a short monotone run is `watch` rather than `breach`,
                -- because over three samples "rose every time" is two coin
                -- flips on a counter that idles between two values.
                local brief = SoakProbe.report(run({ flat(9000), flat(9100), flat(9101) }))
                TestRunner.equal(brief.verdict, "watch")
            end,
        },
        {
            --[[
                The seven cycles a live server actually produced, kept as a
                case with its real numbers.

                Emberhollow builds more of itself as it tiers up, and on
                cycle four it raised new buildings and the world gained 982
                instances in one step -- then held for three cycles and came
                back down. Measured from the baseline that is 200 a cycle
                forever, so the gate breached on the game working, which is
                how a gate gets ignored. Measured over the tail it is what
                it is: a build-out that finished.

                This is why the numbers are the observed ones rather than
                round ones. A tolerance tuned against invented data is a
                tolerance tuned against nothing.
            ]]
            name = "a town that builds itself out and then holds is not a leak",
            run = function()
                local observed = SoakProbe.report(run({
                    flat(15550),
                    flat(15550),
                    flat(15550),
                    flat(16532),
                    flat(16597),
                    flat(16597),
                    flat(16552),
                }))
                TestRunner.equal(observed.verdict, "ok")
                for _, metric in observed.metrics do
                    if metric.id == "instances" then
                        TestRunner.equal(metric.reason, "steady")
                        TestRunner.equal(metric.monotone, false)
                        TestRunner.equal(metric.baseline, 15550)
                        TestRunner.equal(metric.last, 16552)
                    end
                end

                -- and the same step followed by a climb that does not stop
                -- is still caught, so the tail did not buy the pass by
                -- looking away.
                local thenLeaking = SoakProbe.report(run({
                    flat(15550),
                    flat(15550),
                    flat(15550),
                    flat(16532),
                    flat(16750),
                    flat(16970),
                    flat(17190),
                }))
                TestRunner.equal(thenLeaking.verdict, "breach")
            end,
        },
        {
            --[[
                The one that would make every other number here meaningless.
                Instance count during a night is legitimately higher than at
                dawn, because there are creatures in the world, so a series
                that drifted across phases would produce a difference that
                looks exactly like a leak and is not.
            ]]
            name = "a sample taken somewhere else in the cycle is refused, not averaged",
            run = function()
                local soak = SoakProbe.begin("day")
                local first, accepted = SoakProbe.record(soak, 1, "day", flat(9000))
                TestRunner.equal(accepted.accepted, true)

                local _, wrongPhase = SoakProbe.record(first, 2, "night", flat(9600))
                TestRunner.equal(wrongPhase.accepted, false)
                TestRunner.equal(wrongPhase.reason, "phase_mismatch")

                -- A sampler that fires twice in one cycle would halve the
                -- apparent growth of a real leak, so a repeated or reversed
                -- cycle is refused too.
                local second = (SoakProbe.record(first, 2, "day", flat(9100)))
                local _, repeated = SoakProbe.record(second, 2, "day", flat(9100))
                TestRunner.equal(repeated.accepted, false)
                TestRunner.equal(repeated.reason, "cycle_repeated")
                local _, backwards = SoakProbe.record(second, 1, "day", flat(9100))
                TestRunner.equal(backwards.accepted, false)
                TestRunner.equal(backwards.reason, "cycle_repeated")

                -- and the refusals changed nothing: the run is still the two
                -- samples it accepted.
                TestRunner.equal(#second.samples, 2)
            end,
        },
        {
            --[[
                Zero is a reading and an absent metric is not, which is the
                rule PerformanceBudget already settled: the failure a gate
                like this exists to catch is somebody claiming a pass for
                something nobody looked at.
            ]]
            name = "a metric nobody sampled reads incomplete rather than ok",
            run = function()
                local partial = SoakProbe.report(run({
                    { instances = 9000, tracked_enemies = 0, player_residue = 0 },
                    { instances = 9100, tracked_enemies = 0, player_residue = 0 },
                    { instances = 9100, tracked_enemies = 0, player_residue = 0 },
                }))
                TestRunner.equal(partial.verdict, "incomplete")
                TestRunner.equal(#partial.missing, 1)
                TestRunner.equal(partial.missing[1], "profile_bytes")

                -- and a breach still outranks it: a run with a hole in it and
                -- a leak in it is a failing run, not an unfinished one.
                local both = SoakProbe.report(run({
                    { instances = 9000, tracked_enemies = 0, player_residue = 0 },
                    { instances = 9100, tracked_enemies = 0, player_residue = 0 },
                    { instances = 9900, tracked_enemies = 0, player_residue = 0 },
                }))
                TestRunner.equal(both.verdict, "breach")
            end,
        },
        {
            --[[
                Two metrics are allowed nothing at all, and the reasons are
                different. A creature outliving the night it belongs to is a
                wave schedule that stalls behind something nobody can fight;
                an entry held for a player who has left is the observable
                half of a connection that outlived them.
            ]]
            name = "a creature or a table entry that outlives its owner is allowed nothing",
            run = function()
                local enemies = SoakProbe.report(run({
                    {
                        instances = 9000,
                        tracked_enemies = 0,
                        player_residue = 0,
                        profile_bytes = 1,
                    },
                    {
                        instances = 9000,
                        tracked_enemies = 0,
                        player_residue = 0,
                        profile_bytes = 1,
                    },
                    {
                        instances = 9000,
                        tracked_enemies = 1,
                        player_residue = 0,
                        profile_bytes = 1,
                    },
                }))
                TestRunner.equal(enemies.verdict, "breach")

                local residue = SoakProbe.report(run({
                    {
                        instances = 9000,
                        tracked_enemies = 0,
                        player_residue = 0,
                        profile_bytes = 1,
                    },
                    {
                        instances = 9000,
                        tracked_enemies = 0,
                        player_residue = 0,
                        profile_bytes = 1,
                    },
                    {
                        instances = 9000,
                        tracked_enemies = 0,
                        player_residue = 2,
                        profile_bytes = 1,
                    },
                }))
                TestRunner.equal(residue.verdict, "breach")

                for _, metricId in { "tracked_enemies", "player_residue" } do
                    local definition = SoakProbe.metric(metricId)
                    TestRunner.equal((definition :: any).perCycleAllowance, 0, metricId)
                end
            end,
        },
        {
            --[[
                The declared gap, pinned the way RELEASE_GATES pins its
                `review` rows. Roblox exposes no count of live script
                connections; a number here would be one this game invented,
                and a gate reading an invented number is worse than a gate
                reading nothing. One metric may say so, and the count is
                pinned so a second threshold nobody wants to instrument
                cannot quietly join it.
            ]]
            name = "exactly one metric is unobservable, and it cannot be supplied anyway",
            run = function()
                local unobservable = 0
                for _, metricId in SoakProbe.Order do
                    local definition = SoakProbe.metric(metricId)
                    TestRunner.truthy(definition, metricId)
                    TestRunner.truthy(
                        #(definition :: any).why > 40,
                        string.format("%s does not say why it is watched", metricId)
                    )
                    if not (definition :: any).observable then
                        unobservable += 1
                    end
                end
                TestRunner.equal(unobservable, 1)
                TestRunner.equal(SoakProbe.isObservable("connections"), false)

                local report = SoakProbe.report(run({ flat(1), flat(1), flat(1) }))
                TestRunner.equal(#report.unobservable, 1)
                TestRunner.equal(report.unobservable[1], "connections")
                -- and it is never `missing`, because nobody failed to
                -- measure it -- it cannot be measured.
                for _, metricId in report.missing do
                    TestRunner.truthy(metricId ~= "connections")
                end

                -- A caller handing one over anyway is dropped rather than
                -- believed, which is what stops the invented number from
                -- arriving through the back door.
                local soak = (
                    SoakProbe.record(
                        SoakProbe.begin("day"),
                        1,
                        "day",
                        { connections = 42, instances = 10 }
                    )
                )
                TestRunner.equal(soak.samples[1].counts.connections, nil)
                TestRunner.equal(soak.samples[1].counts.instances, 10)
            end,
        },
        {
            --[[
                The wiring, read as text for the reason `GateMetrics` reads
                its call sites as text: a probe with no sampler is a gate
                reading nothing, and it looks identical to a gate reading a
                clean run. Every observable metric has to have somebody
                actually counting it, and the count has to happen once per
                cycle at one fixed phase.
            ]]
            name = "every observable metric has something in the server counting it",
            run = function()
                local wiring = fs.readFile("src/server/init.server.luau")
                for _, metricId in SoakProbe.Order do
                    if SoakProbe.isObservable(metricId) then
                        TestRunner.truthy(
                            string.find(wiring, metricId .. " = function", 1, true),
                            string.format("%s has no counter wired", metricId)
                        )
                    else
                        TestRunner.equal(
                            string.find(wiring, metricId .. " = function", 1, true),
                            nil,
                            string.format("%s is unobservable and something counts it", metricId)
                        )
                    end
                end

                -- and the sample is taken from the town's cycle observer, at
                -- the top of the day, rather than from a timer that would
                -- drift across phases.
                local night = fs.readFile("src/server/Services/TownNightService.luau")
                TestRunner.truthy(
                    string.find(night, '_observeCycle(cycle, "day")', 1, true),
                    "nothing samples the cycle"
                )
                TestRunner.truthy(
                    string.find(wiring, "setCycleObserver", 1, true),
                    "the soak is not attached to the town cycle"
                )
            end,
        },
        {
            --[[
                The defect a live pass found in this wave, kept as a case
                because it is invisible from every other angle: the switch
                was read once at boot, and a Studio Play session starts from
                a fresh DataModel that does not carry attributes set in Edit
                mode. So the whole thing ran on every server and could never
                be turned on from the only place anybody drives it. Nothing
                failed -- the wiring was there, the counters were there, the
                spec was green, and the log was silent.

                A top-level read is what that looks like in the source, so
                that is what this refuses: the switch has to be read inside
                something that runs later than boot.
            ]]
            name = "the soak switch is read per cycle, not once at boot",
            run = function()
                local found = false
                for line in string.gmatch(fs.readFile("src/server/init.server.luau"), "[^\n]+") do
                    if string.find(line, "LastLightSoak", 1, true) ~= nil then
                        found = true
                        TestRunner.truthy(
                            string.match(line, "^%s") ~= nil,
                            "LastLightSoak is read at the top level, so a Play session "
                                .. "started from Edit mode can never turn it on"
                        )
                    end
                end
                TestRunner.truthy(found, "nothing reads the soak switch at all")
            end,
        },
    },
}
