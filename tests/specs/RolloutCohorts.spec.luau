--!strict

--[[
    The rollout ladder, driven as properties rather than as cases.

    Three claims are worth more than any individual example here, and each of
    them is a way a staged rollout has gone wrong in somebody's live beta:

      * advancing a stage never takes the feature off anybody;
      * a player's bucket does not move, ever, for any reason;
      * two flags at the same share do not draw the same players.

    The third one is the one that had to be measured. The module's first
    version was affine end to end, and two flags at ten percent produced
    perfectly disjoint cohorts -- a rotation of one ordering rather than a
    different ordering per flag. Nothing about that is visible in a case
    checking one player against one flag, which is why the check here is an
    overlap count against what independence would predict.
]]

local RolloutCohorts = require("../../src/shared/RolloutCohorts")
local TestRunner = require("../TestRunner")

local EMPTY_ROSTER = {
    team = {},
    allowlist = {},
}

local function rosterWith(team: { number }, allowlist: { number })
    local roster = { team = {}, allowlist = {} }
    for _, userId in team do
        roster.team[userId] = true
    end
    for _, userId in allowlist do
        roster.allowlist[userId] = true
    end
    return roster
end

local function population(count: number): { number }
    local ids = {}
    for index = 1, count do
        -- Spread rather than sequential, because real user IDs are neither
        -- adjacent nor evenly spaced and a hash that only works on 1..n is a
        -- hash that works on the test.
        table.insert(ids, 1000000 + index * 7919)
    end
    return ids
end

return {
    name = "RolloutCohorts",
    cases = {
        {
            name = "the ladder is the roadmap's four rungs and an off state",
            run = function()
                local stages = RolloutCohorts.stages()
                TestRunner.equal(#stages, 5)
                TestRunner.equal(stages[1], "off")
                TestRunner.equal(stages[2], "team")
                TestRunner.equal(stages[3], "allowlist")
                TestRunner.equal(stages[4], "cohort")
                TestRunner.equal(stages[5], "everyone")
                TestRunner.equal(RolloutCohorts.isStage("cohort"), true)
                TestRunner.equal(RolloutCohorts.isStage("beta"), false)
                TestRunner.equal(RolloutCohorts.isStage(4), false)
            end,
        },
        {
            name = "only the ends of the ladder have a global answer",
            run = function()
                TestRunner.equal(RolloutCohorts.isScoped("off"), false)
                TestRunner.equal(RolloutCohorts.isScoped("everyone"), false)
                TestRunner.equal(RolloutCohorts.isScoped("team"), true)
                TestRunner.equal(RolloutCohorts.isScoped("allowlist"), true)
                TestRunner.equal(RolloutCohorts.isScoped("cohort"), true)

                TestRunner.equal(RolloutCohorts.globalDefault("everyone"), true)
                TestRunner.equal(RolloutCohorts.globalDefault("off"), false)
                TestRunner.equal(RolloutCohorts.globalDefault("team"), false)
                TestRunner.equal(RolloutCohorts.globalDefault("allowlist"), false)
                TestRunner.equal(RolloutCohorts.globalDefault("cohort"), false)
            end,
        },
        {
            name = "off admits nobody, including the people on both rosters",
            run = function()
                local roster = rosterWith({ 11 }, { 22 })
                local rollout = { stage = "off" :: any, percent = 100 }
                for _, userId in { 11, 22, 33 } do
                    local admitted, reason = RolloutCohorts.admits("flag", rollout, roster, userId)
                    TestRunner.equal(admitted, false)
                    TestRunner.equal(reason, "stage_off")
                end
            end,
        },
        {
            name = "each rung admits its own list and refuses the one above it",
            run = function()
                local roster = rosterWith({ 11 }, { 22 })

                local team = { stage = "team" :: any, percent = 100 }
                TestRunner.equal(RolloutCohorts.admits("flag", team, roster, 11), true)
                TestRunner.equal(RolloutCohorts.admits("flag", team, roster, 22), false)

                local allowlist = { stage = "allowlist" :: any, percent = 100 }
                TestRunner.equal(RolloutCohorts.admits("flag", allowlist, roster, 22), true)
                local _, reason = RolloutCohorts.admits("flag", allowlist, roster, 33)
                TestRunner.equal(reason, "outside_cohort")
            end,
        },
        {
            name = "advancing a stage never takes the feature off anybody",
            run = function()
                --[[
                    The property the whole module exists for, driven over the
                    ladder rather than asserted at one step. For every player
                    in a mixed population, the set of stages that admit them
                    is upward closed: once a rung lets somebody in, no rung
                    above it may refuse.
                ]]
                local ids = population(400)
                local roster = rosterWith({ ids[3], ids[9] }, { ids[9], ids[40] })
                local stages = RolloutCohorts.stages()

                for _, userId in ids do
                    local admittedAt: number? = nil
                    for rank, stage in stages do
                        local rollout = { stage = stage, percent = 25 }
                        local admitted = RolloutCohorts.admits("some_flag", rollout, roster, userId)
                        if admitted then
                            if admittedAt == nil then
                                admittedAt = rank
                            end
                        else
                            TestRunner.equal(admittedAt, nil)
                        end
                    end
                end
            end,
        },
        {
            name = "a bucket does not move, for any reason",
            run = function()
                local ids = population(200)
                for _, userId in ids do
                    local first = RolloutCohorts.bucket("region_ironroot_enabled", userId)
                    for _ = 1, 5 do
                        TestRunner.equal(
                            RolloutCohorts.bucket("region_ironroot_enabled", userId),
                            first
                        )
                    end
                    TestRunner.equal(first >= 0 and first < 100, true)
                end
            end,
        },
        {
            name = "percent 0 admits nobody outside the rosters and 100 admits everybody",
            run = function()
                local ids = population(300)
                local none = { stage = "cohort" :: any, percent = 0 }
                local all = { stage = "cohort" :: any, percent = 100 }
                for _, userId in ids do
                    TestRunner.equal(RolloutCohorts.admits("f", none, EMPTY_ROSTER, userId), false)
                    TestRunner.equal(RolloutCohorts.admits("f", all, EMPTY_ROSTER, userId), true)
                end
            end,
        },
        {
            name = "a share is roughly the share it says it is",
            run = function()
                local ids = population(2000)
                local rollout = { stage = "cohort" :: any, percent = 25 }
                local admitted = 0
                for _, userId in ids do
                    if
                        RolloutCohorts.admits(
                            "cosmetic_store_enabled",
                            rollout,
                            EMPTY_ROSTER,
                            userId
                        )
                    then
                        admitted += 1
                    end
                end
                -- Wide, because this is a hash and not a quota: what would
                -- fail here is a bucket that is not spread at all.
                TestRunner.equal(admitted > 400 and admitted < 600, true)
            end,
        },
        {
            name = "two flags at the same share do not draw the same players",
            run = function()
                --[[
                    The measurement the module's first version failed. With
                    2000 players and two independent 20% cohorts, roughly 80
                    should be in both. The affine version scored zero, which
                    reads as a wonderful property until you notice it means
                    no player in the beta ever sees two new features.
                ]]
                local ids = population(2000)
                local rollout = { stage = "cohort" :: any, percent = 20 }

                local first: { [number]: boolean } = {}
                local firstCount = 0
                local secondCount = 0
                local both = 0

                for _, userId in ids do
                    if
                        RolloutCohorts.admits("first_flag_enabled", rollout, EMPTY_ROSTER, userId)
                    then
                        first[userId] = true
                        firstCount += 1
                    end
                end
                for _, userId in ids do
                    if
                        RolloutCohorts.admits("second_flag_enabled", rollout, EMPTY_ROSTER, userId)
                    then
                        secondCount += 1
                        if first[userId] then
                            both += 1
                        end
                    end
                end

                local expected = firstCount * secondCount / #ids
                TestRunner.equal(both > expected * 0.5, true)
                TestRunner.equal(both < expected * 1.5, true)
            end,
        },
        {
            name = "an unknown stage and a subject that is not a user id both refuse",
            run = function()
                local unknown = { stage = "beta" :: any, percent = 100 }
                local admitted, reason = RolloutCohorts.admits("f", unknown, EMPTY_ROSTER, 11)
                TestRunner.equal(admitted, false)
                TestRunner.equal(reason, "unknown_stage")

                local everyone = { stage = "everyone" :: any, percent = 100 }
                local _, why = RolloutCohorts.admits("f", everyone, EMPTY_ROSTER, 0 / 0)
                TestRunner.equal(why, "no_subject")
            end,
        },
    },
}
