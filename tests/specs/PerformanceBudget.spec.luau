--!strict

local Config = require("../../src/shared/Config")
local PerformanceBudget = require("../../src/shared/PerformanceBudget")
local TestRunner = require("../TestRunner")

-- Headroom is a division, so it lands a few bits off a round number. Compare
-- within tolerance rather than pretending binary floats are decimals.
local function near(actual: number, expected: number)
    TestRunner.truthy(
        math.abs(actual - expected) < 1e-9,
        string.format("expected %f, received %f", expected, actual)
    )
end

local function repeated(value: number, times: number): { number }
    local samples = {}
    for _ = 1, times do
        table.insert(samples, value)
    end
    return samples
end

return {
    name = "PerformanceBudget",
    cases = {
        {
            name = "carries the architecture document's budgets unchanged",
            run = function()
                -- If one of these ever disagrees with
                -- docs/TECHNICAL_ARCHITECTURE.md, the document is the source
                -- of truth and this module is the thing that is wrong.
                local join = PerformanceBudget.definition("join_seconds")
                TestRunner.equal(join.target, 5)
                TestRunner.equal(join.hard, 8)
                TestRunner.equal(join.direction, "lower_is_better")

                local fps = PerformanceBudget.definition("client_fps")
                TestRunner.equal(fps.target, 45)
                TestRunner.equal(fps.hard, 30)
                TestRunner.equal(fps.direction, "higher_is_better")

                local spike = PerformanceBudget.definition("frame_spike_ms")
                TestRunner.equal(spike.target, 50)
                TestRunner.equal(spike.hard, 100)

                local heartbeat = PerformanceBudget.definition("server_heartbeat_hz")
                TestRunner.equal(heartbeat.target, 30)
                TestRunner.equal(heartbeat.hard, 20)

                local memory = PerformanceBudget.definition("client_memory_headroom")
                TestRunner.equal(memory.target, 0.2)

                -- The remote budget is the action limiter's own configuration,
                -- so it can never drift from what the server actually enforces.
                local remote = PerformanceBudget.definition("remote_actions_per_second")
                TestRunner.equal(remote.target, Config.ActionRatePerSecond)
                TestRunner.equal(remote.hard, Config.ActionRatePerSecond * 2)
            end,
        },
        {
            name = "every metric judges the tail where bad samples live",
            run = function()
                for _, metricId in PerformanceBudget.order() do
                    local definition = PerformanceBudget.definition(metricId)
                    if definition.direction == "higher_is_better" then
                        TestRunner.equal(definition.percentile, 5)
                        TestRunner.truthy(
                            definition.hard < definition.target,
                            "a higher-is-better hard threshold sits below its target"
                        )
                    else
                        TestRunner.equal(definition.percentile, 95)
                        TestRunner.truthy(
                            definition.hard > definition.target,
                            "a lower-is-better hard threshold sits above its target"
                        )
                    end
                end
            end,
        },
        {
            name = "classifies both directions at their boundaries",
            run = function()
                TestRunner.equal(PerformanceBudget.classify("join_seconds", 4.9), "ok")
                TestRunner.equal(PerformanceBudget.classify("join_seconds", 5), "ok")
                TestRunner.equal(PerformanceBudget.classify("join_seconds", 5.01), "watch")
                TestRunner.equal(PerformanceBudget.classify("join_seconds", 8), "watch")
                TestRunner.equal(PerformanceBudget.classify("join_seconds", 8.01), "breach")

                TestRunner.equal(PerformanceBudget.classify("client_fps", 60), "ok")
                TestRunner.equal(PerformanceBudget.classify("client_fps", 45), "ok")
                TestRunner.equal(PerformanceBudget.classify("client_fps", 44.9), "watch")
                TestRunner.equal(PerformanceBudget.classify("client_fps", 30), "watch")
                TestRunner.equal(PerformanceBudget.classify("client_fps", 29.9), "breach")

                -- Garbage never reads as a pass.
                for _, value in { 0 / 0, math.huge, -math.huge } do
                    TestRunner.equal(PerformanceBudget.classify("client_fps", value), "incomplete")
                end
            end,
        },
        {
            name = "rejects a metric it does not define",
            run = function()
                TestRunner.equal(PerformanceBudget.isValidMetric("client_fps"), true)
                for _, value in { "fps", "", 7, true, nil } do
                    TestRunner.equal(PerformanceBudget.isValidMetric(value), false)
                end
                TestRunner.throws(function()
                    PerformanceBudget.definition("made_up_metric")
                end)
            end,
        },
        {
            name = "interpolates percentiles and survives a single sample",
            run = function()
                local sorted = { 10, 20, 30, 40, 50 }
                TestRunner.equal(PerformanceBudget.percentile(sorted, 50), 30)
                TestRunner.equal(PerformanceBudget.percentile(sorted, 0), 10)
                TestRunner.equal(PerformanceBudget.percentile(sorted, 100), 50)
                TestRunner.equal(PerformanceBudget.percentile(sorted, 95), 48)
                TestRunner.equal(PerformanceBudget.percentile(sorted, 5), 12)
                TestRunner.equal(PerformanceBudget.percentile({ 42 }, 95), 42)
                TestRunner.throws(function()
                    PerformanceBudget.percentile({}, 50)
                end)
            end,
        },
        {
            name = "a good average does not rescue a bad tail",
            run = function()
                -- Ninety-four percent of a run at 60 FPS and six percent at
                -- 20: a mean of 57.6, which is exactly the reading that would
                -- let a stuttering run claim the gate.
                local samples = repeated(20, 6)
                for _, sample in repeated(60, 94) do
                    table.insert(samples, sample)
                end

                local summary = PerformanceBudget.summarize("client_fps", samples)
                TestRunner.truthy(summary ~= nil, "a hundred samples must summarize")
                local resolved = summary :: any
                TestRunner.equal(resolved.count, 100)
                TestRunner.truthy(resolved.mean > 57, "the mean really is comfortable")
                TestRunner.equal(PerformanceBudget.classify("client_fps", resolved.mean), "ok")

                -- The verdict comes from the low tail instead.
                TestRunner.equal(resolved.value, 20)
                TestRunner.equal(resolved.verdict, "breach")
                TestRunner.equal(resolved.min, 20)
                TestRunner.equal(resolved.max, 60)
            end,
        },
        {
            name = "drops unusable samples instead of letting them decide",
            run = function()
                local summary =
                    PerformanceBudget.summarize("client_fps", { 60, 0 / 0, 60, math.huge, 60 })
                local resolved = summary :: any
                TestRunner.equal(resolved.count, 3)
                TestRunner.equal(resolved.discarded, 2)
                TestRunner.equal(resolved.verdict, "ok")

                TestRunner.equal(PerformanceBudget.summarize("client_fps", {}), nil)
                TestRunner.equal(PerformanceBudget.summarize("client_fps", { 0 / 0 }), nil)
            end,
        },
        {
            name = "an unmeasured budget is incomplete, never a pass",
            run = function()
                -- The failure this gate exists to catch: every metric that was
                -- measured looks fine, and the report still cannot say pass.
                local report = PerformanceBudget.report({
                    client_fps = repeated(60, 10),
                    server_heartbeat_hz = repeated(58, 10),
                })
                TestRunner.equal(report.verdict, "incomplete")
                TestRunner.equal(#report.metrics, 2)
                TestRunner.equal(#report.missing, #PerformanceBudget.order() - 2)
                for _, summary in report.metrics do
                    TestRunner.equal(summary.verdict, "ok")
                end

                local empty = PerformanceBudget.report({})
                TestRunner.equal(empty.verdict, "incomplete")
                TestRunner.equal(#empty.metrics, 0)
                TestRunner.equal(#empty.missing, #PerformanceBudget.order())
            end,
        },
        {
            name = "a complete run reports the worst metric it found",
            run = function()
                local function fullRun(overrides: { [string]: { number } }): any
                    local samples: { [string]: { number } } = {
                        join_seconds = repeated(3, 8),
                        client_fps = repeated(60, 20),
                        frame_spike_ms = repeated(18, 20),
                        server_heartbeat_hz = repeated(58, 20),
                        client_memory_headroom = repeated(0.45, 20),
                        remote_actions_per_second = repeated(2, 20),
                    }
                    for metricId, values in overrides do
                        samples[metricId] = values
                    end
                    return PerformanceBudget.report(samples)
                end

                local clean = fullRun({})
                TestRunner.equal(clean.verdict, "ok")
                TestRunner.equal(#clean.missing, 0)
                TestRunner.equal(#clean.metrics, #PerformanceBudget.order())

                -- One metric merely close to the line pulls the whole run to
                -- watch, and one over it pulls the whole run to breach.
                TestRunner.equal(fullRun({ join_seconds = repeated(6, 8) }).verdict, "watch")
                TestRunner.equal(fullRun({ join_seconds = repeated(20, 8) }).verdict, "breach")
                TestRunner.equal(fullRun({ frame_spike_ms = repeated(400, 20) }).verdict, "breach")

                -- A breach outranks an absent metric; a watch does not.
                local mixed = PerformanceBudget.report({
                    client_fps = repeated(10, 20),
                })
                TestRunner.equal(mixed.verdict, "breach")
            end,
        },
        {
            name = "refuses a client report that no real device could produce",
            run = function()
                local good = PerformanceBudget.sanitizeClientReport({
                    schemaVersion = 1,
                    fps = 58.4,
                    spikeMs = 42,
                    memoryMb = 380,
                })
                TestRunner.truthy(good ~= nil, "an ordinary sample is accepted")
                TestRunner.equal((good :: any).fps, 58.4)

                local rejected: { any } = {
                    nil,
                    "fine",
                    42,
                    {},
                    { fps = 60, spikeMs = 10, memoryMb = 300 }, -- no schema version
                    { schemaVersion = 2, fps = 60, spikeMs = 10, memoryMb = 300 },
                    { schemaVersion = 1, spikeMs = 10, memoryMb = 300 },
                    { schemaVersion = 1, fps = 60, memoryMb = 300 },
                    { schemaVersion = 1, fps = 60, spikeMs = 10 },
                    -- A client claiming impossible numbers is refused rather
                    -- than clamped, so it shows up as a discard instead of
                    -- quietly moving a percentile.
                    { schemaVersion = 1, fps = 0, spikeMs = 10, memoryMb = 300 },
                    { schemaVersion = 1, fps = -60, spikeMs = 10, memoryMb = 300 },
                    { schemaVersion = 1, fps = 100000, spikeMs = 10, memoryMb = 300 },
                    { schemaVersion = 1, fps = 60, spikeMs = -1, memoryMb = 300 },
                    { schemaVersion = 1, fps = 60, spikeMs = 999999, memoryMb = 300 },
                    { schemaVersion = 1, fps = 60, spikeMs = 10, memoryMb = 0 },
                    { schemaVersion = 1, fps = 60, spikeMs = 10, memoryMb = 999999 },
                    { schemaVersion = 1, fps = 0 / 0, spikeMs = 10, memoryMb = 300 },
                    { schemaVersion = 1, fps = math.huge, spikeMs = 10, memoryMb = 300 },
                    { schemaVersion = 1, fps = "60", spikeMs = 10, memoryMb = 300 },
                    {
                        schemaVersion = 1,
                        fps = 60,
                        spikeMs = 10,
                        memoryMb = 300,
                        extra = "smuggled",
                    },
                }
                for _, candidate in rejected do
                    TestRunner.equal(PerformanceBudget.sanitizeClientReport(candidate), nil)
                end
            end,
        },
        {
            name = "converts reported memory into headroom against the device ceiling",
            run = function()
                near(PerformanceBudget.memoryHeadroom(350, 700), 0.5)
                near(PerformanceBudget.memoryHeadroom(560, 700), 0.2)
                near(PerformanceBudget.memoryHeadroom(700, 700), 0)

                -- Over the ceiling is zero headroom, not negative: how far
                -- past the line tells the gate nothing it does not know.
                TestRunner.equal(PerformanceBudget.memoryHeadroom(2000, 700), 0)

                -- 400 MB of a 700 MB ceiling leaves 43% free, comfortably
                -- inside the budget. The exact 20% line is not asserted here
                -- because a division lands either side of it by a few bits,
                -- and which side is a fact about floats rather than about
                -- whether the device had headroom.
                TestRunner.equal(
                    PerformanceBudget.classify(
                        "client_memory_headroom",
                        PerformanceBudget.memoryHeadroom(400, 700)
                    ),
                    "ok"
                )
                TestRunner.equal(
                    PerformanceBudget.classify(
                        "client_memory_headroom",
                        PerformanceBudget.memoryHeadroom(690, 700)
                    ),
                    "breach"
                )

                TestRunner.throws(function()
                    PerformanceBudget.memoryHeadroom(300, 0)
                end)
            end,
        },
        {
            name = "formats one readable line per metric, including the gaps",
            run = function()
                local report = PerformanceBudget.report({
                    client_fps = repeated(60, 10),
                })
                local lines = PerformanceBudget.format(report)
                TestRunner.equal(#lines, #PerformanceBudget.order())

                local joined = table.concat(lines, "\n")
                TestRunner.truthy(
                    string.find(joined, "OK Client frame rate", 1, true) ~= nil,
                    "the measured metric reports its verdict and label"
                )
                TestRunner.truthy(
                    string.find(joined, "INCOMPLETE", 1, true) ~= nil,
                    "an unmeasured metric is named rather than omitted"
                )
                TestRunner.truthy(
                    string.find(joined, "no samples", 1, true) ~= nil,
                    "and says why it has no verdict"
                )
            end,
        },
    },
}
