--!strict

--[[
    The switches, the ladder, and the document, held against each other.

    A staged rollout adds a second table beside the flags and a third table in
    a document, and three tables drift faster than two. So none of them may
    move alone: every flag has a rung, every rung agrees with the boolean
    through `RolloutCohorts.globalDefault`, and every row of the matrix in
    BETA_ROLLOUT.md names a flag that exists at the stage and share the config
    gives it.

    The pin the wave plan asks for is the second of those. **The global answer
    for every flag that shipped before this is bit-identical**, which is what
    makes a cohort dimension safe to add to a service twenty-odd call sites
    already read globally: the table is the same table until somebody moves a
    flag onto the ladder deliberately.
]]

local fs = require("@lune/fs")
local Config = require("../../src/shared/Config")
local FeatureFlagService = require("../../src/server/Services/FeatureFlagService")
local RolloutCohorts = require("../../src/shared/RolloutCohorts")
local TestRunner = require("../TestRunner")

local DOC = "docs/BETA_ROLLOUT.md"

local silentLogger = {
    info = function() end,
    warn = function() end,
}

local function build(
    defaults: { [string]: boolean },
    rollouts: { [string]: any },
    roster: any,
    allowOverrides: boolean?
)
    return FeatureFlagService.new(
        defaults,
        allowOverrides ~= false,
        silentLogger,
        RolloutCohorts,
        rollouts,
        roster
    )
end

local EMPTY_ROSTER = { team = {}, allowlist = {} }

--[[
    The matrix rows, read out of the document rather than copied in here. A
    copy would be a fourth list, and the whole point is that there are not
    supposed to be four.
]]
local function rowsInDoc(): { [string]: { stage: string, percent: number } }
    local doc = fs.readFile(DOC)
    local rows: { [string]: { stage: string, percent: number } } = {}
    for flag, stage, percent in
        string.gmatch(doc, "\n|%s*`([a-z_]+)`%s*|%s*`([a-z]+)`%s*|%s*(%d+)%s*|")
    do
        rows[flag] = { stage = stage, percent = tonumber(percent) :: number }
    end
    return rows
end

return {
    name = "FeatureFlagService",
    cases = {
        {
            name = "reads defaults and local overrides",
            run = function()
                local flags = build(
                    { example = false },
                    { example = { stage = "off", percent = 0 } },
                    EMPTY_ROSTER
                )
                TestRunner.equal(flags:isEnabled("example"), false)

                local changed = flags:setOverride("example", true)
                TestRunner.equal(changed, true)
                TestRunner.equal(flags:isEnabled("example"), true)

                flags:clearOverride("example")
                TestRunner.equal(flags:isEnabled("example"), false)
            end,
        },
        {
            name = "rejects production overrides",
            run = function()
                local flags = build(
                    { example = false },
                    { example = { stage = "off", percent = 0 } },
                    EMPTY_ROSTER,
                    false
                )
                local changed, message = flags:setOverride("example", true)

                TestRunner.equal(changed, false)
                TestRunner.truthy(message)
                TestRunner.equal(flags:isEnabled("example"), false)
            end,
        },
        {
            name = "a cohort-scoped flag is off outside the cohort and on inside it",
            run = function()
                local flags = build(
                    { staged = false },
                    { staged = { stage = "team", percent = 0 } },
                    { team = { [4242] = true }, allowlist = {} }
                )

                TestRunner.equal(flags:isEnabled("staged", 4242), true)
                TestRunner.equal(flags:isEnabled("staged", 4243), false)

                local enabled, reason = flags:explain("staged", 4242)
                TestRunner.equal(enabled, true)
                TestRunner.equal(reason, "team")

                local off, why = flags:explain("staged", 4243)
                TestRunner.equal(off, false)
                TestRunner.equal(why, "outside_cohort")
            end,
        },
        {
            name = "a cohort-scoped flag read without a player throws rather than guessing",
            run = function()
                local flags = build(
                    { staged = false },
                    { staged = { stage = "cohort", percent = 50 } },
                    EMPTY_ROSTER
                )

                TestRunner.throws(function()
                    flags:isEnabled("staged")
                end, "was read without a player")

                -- The report form answers rather than throwing, because a
                -- report is allowed to say "nobody asked about anybody".
                local enabled, reason = flags:explain("staged")
                TestRunner.equal(enabled, false)
                TestRunner.equal(reason, "no_subject")
            end,
        },
        {
            name = "a flag with no rung throws, so a flag cannot be added to one table only",
            run = function()
                local flags = build({ orphan = true }, {}, EMPTY_ROSTER)
                TestRunner.throws(function()
                    flags:isEnabled("orphan")
                end, "has no rollout stage")
            end,
        },
        {
            name = "an unscoped flag answers globally whether or not a player is named",
            run = function()
                local flags = build({ shipped = true, dark = false }, {
                    shipped = { stage = "everyone", percent = 100 },
                    dark = { stage = "off", percent = 0 },
                }, EMPTY_ROSTER)
                TestRunner.equal(flags:isEnabled("shipped"), true)
                TestRunner.equal(flags:isEnabled("shipped", 77), true)
                TestRunner.equal(flags:isEnabled("dark"), false)
                TestRunner.equal(flags:isEnabled("dark", 77), false)
            end,
        },
        {
            name = "an override still wins over the ladder",
            run = function()
                local flags = build(
                    { staged = false },
                    { staged = { stage = "team", percent = 0 } },
                    EMPTY_ROSTER
                )
                flags:setOverride("staged", true)
                -- Including without a player, because an override is a
                -- developer holding the switch rather than a rollout.
                TestRunner.equal(flags:isEnabled("staged"), true)
                TestRunner.equal(flags:isEnabled("staged", 1), true)
            end,
        },
        {
            name = "every flag has a rung and every rung has a flag",
            run = function()
                for flag in Config.FeatureFlags do
                    TestRunner.truthy(
                        Config.FeatureFlagRollouts[flag],
                        string.format("flag %q has no rollout stage", flag)
                    )
                end
                for flag, rollout in Config.FeatureFlagRollouts do
                    TestRunner.truthy(
                        Config.FeatureFlags[flag] ~= nil,
                        string.format("rollout %q names a flag that does not exist", flag)
                    )
                    TestRunner.truthy(
                        RolloutCohorts.isStage(rollout.stage),
                        string.format(
                            "flag %q is at unknown stage %q",
                            flag,
                            tostring(rollout.stage)
                        )
                    )
                    TestRunner.equal(type(rollout.percent), "number")
                    TestRunner.equal(rollout.percent >= 0 and rollout.percent <= 100, true)
                end
            end,
        },
        {
            name = "the shipped global answer is bit-identical to the stage matrix",
            run = function()
                --[[
                    The pin. A flag is `true` if and only if it stands at
                    `everyone`, so the switch and the rung are one fact. This
                    is also what makes the cohort dimension safe to add under
                    twenty-odd call sites that still ask globally: nothing
                    they read has changed.
                ]]
                local flags =
                    build(Config.FeatureFlags, Config.FeatureFlagRollouts, Config.RolloutRoster)
                for flag, value in Config.FeatureFlags do
                    local rollout = Config.FeatureFlagRollouts[flag]
                    TestRunner.equal(
                        value,
                        RolloutCohorts.globalDefault(rollout.stage),
                        string.format(
                            "flag %q is %s but stands at stage %q",
                            flag,
                            tostring(value),
                            tostring(rollout.stage)
                        )
                    )
                    -- And the service agrees, read the way the game reads it.
                    TestRunner.equal(flags:isEnabled(flag), value)
                end
            end,
        },
        {
            name = "the document's matrix and the config agree in both directions",
            run = function()
                local rows = rowsInDoc()
                for flag, rollout in Config.FeatureFlagRollouts do
                    local row = rows[flag]
                    TestRunner.truthy(
                        row,
                        string.format("flag %q is not in the %s matrix", flag, DOC)
                    )
                    TestRunner.equal(
                        row.stage,
                        rollout.stage,
                        string.format("%s says %q is at %q", DOC, flag, row.stage)
                    )
                    TestRunner.equal(row.percent, rollout.percent)
                end
                for flag in rows do
                    TestRunner.truthy(
                        Config.FeatureFlagRollouts[flag],
                        string.format("%s lists %q, which is not a flag", DOC, flag)
                    )
                end
            end,
        },
        {
            name = "no flag is mid-ladder without a roster to stand on",
            run = function()
                --[[
                    Not a rule about the future -- a flag at `team` with an
                    empty roster is on for nobody, which is the safe way for
                    this to be wrong. It is a check that the current state is
                    the one BETA_ROLLOUT.md describes, so moving a flag onto
                    the ladder is a deliberate edit here as well as there.
                ]]
                local flags =
                    build(Config.FeatureFlags, Config.FeatureFlagRollouts, Config.RolloutRoster)
                TestRunner.equal(flags:scopedCount(), 0)
            end,
        },
    },
}
