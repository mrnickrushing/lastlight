--!strict

local AshRegent = require("../../src/shared/AshRegentEncounter")
local CinderfallEnemies = require("../../src/shared/CinderfallEnemies")
local GlassBailiff = require("../../src/shared/GlassBailiffEncounter")
local LeadActor = require("../../src/shared/LeadActorEncounter")
local WhiteHowler = require("../../src/shared/WhiteHowlerEncounter")
local AbbeySilence = require("../../src/shared/AbbeySilenceEncounter")
local TestRunner = require("../TestRunner")

local RUN = "run_crown"
local HASH = "dd2200aa"

local function activeActor(): any
    return (LeadActor.activate(LeadActor.create(RUN, HASH, true), 7))
end

local function activeBailiff(): any
    return (GlassBailiff.activate(GlassBailiff.create(RUN, HASH, true), 7))
end

local function openedRegent(): any
    local state = AshRegent.create(RUN, HASH, true)
    state = (AshRegent.unlock(state))
    return (AshRegent.activate(state, 7))
end

-- Answer the Actor's whole line correctly, whatever it is.
local function performLine(state: any): any
    local guard = 0
    while state.status == "performing" and guard < 12 do
        guard += 1
        state = (LeadActor.answerBeat(state, 7, LeadActor.expectedBeat(state)))
    end
    return state
end

--[[
    Walk one Regent phase. `sparing` decides the chapter's question: take
    the anchors off false casts only, or reach for the authentic ones
    because they are worth double.
]]
local function walkRegentPhase(state: any, sparing: boolean): any
    for _, statueId in AshRegent.StatueIds do
        if state.status ~= "anchored" then
            break
        end
        local authentic = AshRegent.isAuthentic(state.phase, statueId)
        if authentic ~= sparing then
            state = (AshRegent.breakStatue(state, 7, statueId))
        end
    end
    -- sparing parties still need three anchors, and false casts are worth
    -- one each, so all three false ones come down
    for _, statueId in AshRegent.StatueIds do
        if state.status ~= "anchored" then
            break
        end
        state = (AshRegent.breakStatue(state, 7, statueId))
    end
    local guard = 0
    while state.status == "exposed" and guard < 60 do
        guard += 1
        state = (AshRegent.strike(state, 7, 45))
    end
    return state
end

return {
    name = "CinderfallEncounters",
    cases = {
        {
            -- The Crown's roster asks whether a thing is real before it
            -- asks anything else, so half of it does no damage worth
            -- speaking of and makes everything else worse.
            name = "the Crown's threat is indirect, and one of them is a prop",
            run = function()
                local support = 0
                for _, definition in CinderfallEnemies.all() do
                    if definition.playerDamage <= 10 or definition.stationary then
                        support += 1
                    end
                    TestRunner.truthy(definition.windup > 1, definition.id .. " gives no warning")
                end
                TestRunner.truthy(support >= 2, "nothing in the Crown plays a support part")
                -- the spark is the correct target and never the obvious one
                local spark = CinderfallEnemies.require("enemy_crown_spark")
                TestRunner.truthy(spark.playerDamage <= 10)
                TestRunner.equal(spark.statusEffect, "spark_theft")
                -- the false citizen is scenery until it is caught working
                local citizen = CinderfallEnemies.require("enemy_false_citizen")
                TestRunner.equal(citizen.stationary, true)
                -- and the knight punishes the safe answer
                local knight = CinderfallEnemies.require("enemy_glass_knight")
                TestRunner.equal(knight.frontShield, true)
                TestRunner.truthy(
                    (knight.flankStrikeDamage :: number)
                        > (knight.frontalStrikeDamage :: number) * 3
                )
            end,
        },
        {
            -- Readable, not hidden: the beat is on the snapshot before it
            -- has to be answered, and a wrong answer costs the line rather
            -- than health.
            name = "the lead actor announces its line and is only open when it ends",
            run = function()
                local state = activeActor()
                TestRunner.equal(state.status, "performing")
                TestRunner.equal(
                    LeadActor.snapshot(state, 7).calledBeat,
                    LeadActor.expectedBeat(state)
                )
                local _, early = LeadActor.strike(state, 7, 40)
                TestRunner.equal(early.accepted, false)
                TestRunner.equal(early.reason, "still_performing")

                -- a wrong beat restarts the line and nothing else
                local wrong = LeadActor.expectedBeat(state) == LeadActor.BeatIds[1]
                        and LeadActor.BeatIds[2]
                    or LeadActor.BeatIds[1]
                local missedState, missed = LeadActor.answerBeat(state, 7, wrong)
                TestRunner.equal(missed.accepted, false)
                TestRunner.equal(missed.missed, true)
                TestRunner.equal(missedState.health, state.health)
                TestRunner.equal(missedState.position, 0)

                state = performLine(state)
                TestRunner.equal(state.status, "broken")
                local hit
                state, hit = LeadActor.strike(state, 7, 40)
                TestRunner.equal(hit.accepted, true)
                TestRunner.equal(state.health, LeadActor.MaxHealth - 40)

                -- and the next scene is longer than the last
                local before = LeadActor.lineLength(state)
                state = LeadActor.resume(state)
                TestRunner.equal(state.status, "performing")
                TestRunner.truthy(LeadActor.lineLength(state) > before)
            end,
        },
        {
            -- The Bailiff's fight is a negotiation with the arena: cover
            -- can be kept or spent, and spending it is the only opening.
            name = "the glass bailiff sells its openings for the party's cover",
            run = function()
                local state = activeBailiff()
                TestRunner.equal(GlassBailiff.standingCount(state), 4)
                local sitting
                state, sitting = GlassBailiff.strike(state, 7, 40)
                TestRunner.equal(sitting.occupied, false)
                TestRunner.truthy(sitting.damage < 40 and sitting.damage >= 1)

                state = GlassBailiff.mark(state)
                TestRunner.truthy(state.marked ~= nil)
                -- appealing keeps the wall and gives nothing back
                local appealed
                state, appealed = GlassBailiff.appeal(state, 7, state.marked)
                TestRunner.equal(appealed.accepted, true)
                TestRunner.equal(GlassBailiff.standingCount(state), 4)
                TestRunner.equal(state.marked, nil)
                local _, notMarked = GlassBailiff.appeal(state, 7, GlassBailiff.StructureIds[1])
                TestRunner.equal(notMarked.accepted, false)

                -- letting it fall costs the wall and buys the window
                state = GlassBailiff.mark(state)
                local carried
                state, carried = GlassBailiff.carryOut(state)
                TestRunner.equal(carried.accepted, true)
                TestRunner.equal(state.status, "sentencing")
                TestRunner.equal(GlassBailiff.standingCount(state), 3)
                local full
                state, full = GlassBailiff.strike(state, 7, 40)
                TestRunner.equal(full.occupied, true)
                TestRunner.equal(full.damage, 40)

                state = GlassBailiff.adjourn(state)
                TestRunner.equal(state.status, "sitting")
            end,
        },
        {
            -- Four phases, five statues each, and the anchors only come
            -- off in the order a party is willing to pay for.
            name = "the regent cannot be touched until its anchors are gone",
            run = function()
                local state = openedRegent()
                for phase = 1, 4 do
                    TestRunner.equal(state.phase, phase)
                    TestRunner.equal(state.status, "anchored")
                    TestRunner.equal(#AshRegent.authenticIds(phase), 2)
                    local _, early = AshRegent.strike(state, 7, 40)
                    TestRunner.equal(early.accepted, false)
                    -- inspection is free, repeatable and tells the truth
                    for _, statueId in AshRegent.StatueIds do
                        local _, looked = AshRegent.inspect(state, 7, statueId)
                        TestRunner.equal(looked.accepted, true)
                        TestRunner.equal(looked.authentic, AshRegent.isAuthentic(phase, statueId))
                    end
                    state = walkRegentPhase(state, true)
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.health, 0)
                TestRunner.equal(AshRegent.snapshot(state, 7).rewardEligible, true)
                -- and a phase's statues come back for the next phase
                TestRunner.equal(
                    AshRegent.isAuthentic(1, "statue_first"),
                    AshRegent.isAuthentic(6, "statue_first")
                )
            end,
        },
        {
            -- The chapter's decision is the shortcut: an authentic statue
            -- is worth two anchors because the Regent is rooted deeper in
            -- something true, so the fast way through destroys the only
            -- record of the people who died here.
            name = "what the court remembers is a count of what was smashed to win",
            run = function()
                local spared = openedRegent()
                for _ = 1, 4 do
                    spared = walkRegentPhase(spared, true)
                end
                TestRunner.equal(spared.erased, 0)
                TestRunner.equal(AshRegent.outcome(spared), "remembered")

                local smashed = openedRegent()
                for _ = 1, 4 do
                    smashed = walkRegentPhase(smashed, false)
                end
                TestRunner.truthy(smashed.erased >= 3)
                TestRunner.equal(AshRegent.outcome(smashed), "erased")

                -- an authentic statue really is the shortcut: two anchors
                -- rather than one, so two of them end a phase outright
                local quick = openedRegent()
                local authentic = AshRegent.authenticIds(quick.phase)
                quick = (AshRegent.breakStatue(quick, 7, authentic[1]))
                TestRunner.equal(quick.status, "anchored")
                quick = (AshRegent.breakStatue(quick, 7, authentic[2]))
                TestRunner.equal(quick.status, "exposed")
                TestRunner.equal(quick.erased, 2)

                -- and nothing reads the outcome before the fight is over
                TestRunner.equal(AshRegent.outcome(quick), nil)

                local lines: { [string]: boolean } = {}
                for _, state in { spared, smashed } do
                    local line = AshRegent.snapshot(state, 7).instruction
                    TestRunner.equal(lines[line], nil, "two outcomes share a line")
                    lines[line] = true
                end
            end,
        },
        {
            -- No telegraph, reward or transaction id may be shared with a
            -- fight from an earlier region.
            name = "the Crown's fights borrow nothing from the Vale's",
            run = function()
                local seen: { [string]: boolean } = {}
                for _, id in
                    {
                        LeadActor.attack(1, true).attackId,
                        LeadActor.attack(2, false).attackId,
                        GlassBailiff.attack(1, 4).attackId,
                        GlassBailiff.attack(2, 4).attackId,
                        AshRegent.attack(1, 1, "anchored").attackId,
                        AshRegent.attack(2, 3, "anchored").attackId,
                        AshRegent.attack(1, 1, "exposed").attackId,
                        AbbeySilence.attack(1, 0).attackId,
                        WhiteHowler.attack(1, 1, "listening").attackId,
                    }
                do
                    TestRunner.equal(seen[id], nil, "shared telegraph: " .. id)
                    seen[id] = true
                end

                local ids: { [string]: boolean } = {}
                for _, id in
                    {
                        LeadActor.rewardTransactionId(activeActor(), 7),
                        GlassBailiff.rewardTransactionId(activeBailiff(), 7),
                        AshRegent.rewardTransactionId(openedRegent(), 7),
                        AbbeySilence.rewardTransactionId(AbbeySilence.create(RUN, HASH, true), 7),
                        WhiteHowler.rewardTransactionId(WhiteHowler.create(RUN, HASH, true), 7),
                    }
                do
                    TestRunner.equal(ids[id], nil, "duplicate reward id: " .. id)
                    ids[id] = true
                end

                TestRunner.truthy(LeadActor.Reward.materialId ~= GlassBailiff.Reward.materialId)
                TestRunner.truthy(GlassBailiff.Reward.materialId ~= AshRegent.Reward.materialId)
                TestRunner.truthy(LeadActor.Reward.materialId ~= AshRegent.Reward.materialId)
            end,
        },
        {
            name = "every Crown encounter honors its kill switch",
            run = function()
                local actor = LeadActor.create(RUN, HASH, false)
                local _, answered = LeadActor.answerBeat(actor, 7, LeadActor.BeatIds[1])
                TestRunner.equal(answered.accepted, false)

                local bailiff = GlassBailiff.create(RUN, HASH, false)
                local _, appealed = GlassBailiff.appeal(bailiff, 7, GlassBailiff.StructureIds[1])
                TestRunner.equal(appealed.accepted, false)
                TestRunner.equal(GlassBailiff.mark(bailiff).marked, nil)

                local regent = AshRegent.create(RUN, HASH, false)
                local _, unlocked = AshRegent.unlock(regent)
                TestRunner.equal(unlocked.accepted, false)
                local _, broke = AshRegent.breakStatue(regent, 7, AshRegent.StatueIds[1])
                TestRunner.equal(broke.accepted, false)
            end,
        },
    },
}
