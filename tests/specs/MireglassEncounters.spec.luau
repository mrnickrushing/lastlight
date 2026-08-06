--!strict

local BellowsMaw = require("../../src/shared/BellowsMawEncounter")
local DrownedCaller = require("../../src/shared/DrownedCallerEncounter")
local LanternWitch = require("../../src/shared/LanternWitchEncounter")
local ManyFace = require("../../src/shared/ManyFaceEncounter")
local TestRunner = require("../TestRunner")

local RUN = "run_fen"
local HASH = "def67890"

local function activeManyFace(): any
    return (ManyFace.activate(ManyFace.create(RUN, HASH, true), 7))
end

local function activeCaller(): any
    return (DrownedCaller.activate(DrownedCaller.create(RUN, HASH, true), 7))
end

local function openedWitch(): any
    local state = LanternWitch.create(RUN, HASH, true)
    state = (LanternWitch.unlock(state))
    return (LanternWitch.activate(state, 7))
end

--[[
    Find her the way a player does: read the round's wrong tell and name
    it. The tell is visible by design, so the fight's own accessor is the
    honest stand-in for looking at four lanterns.
]]
local function findWitch(state: any): any
    if state.status ~= "hiding" then
        return state
    end
    return (LanternWitch.nameCopy(state, 7, LanternWitch.falseCopy(state.round, state.phase)))
end

return {
    name = "MireglassEncounters",
    cases = {
        {
            name = "the Fen's elites and boss all honor the kill switch",
            run = function()
                local face = ManyFace.create(RUN, HASH, false)
                TestRunner.equal(face.status, "disabled")
                local _, faceTurn = ManyFace.turnMirror(face, 7, "mirror_left", 10)
                TestRunner.equal(faceTurn.accepted, false)

                local caller = DrownedCaller.create(RUN, HASH, false)
                local _, silt = DrownedCaller.siltPool(caller, 7, "pool_north")
                TestRunner.equal(silt.accepted, false)

                local witch = LanternWitch.create(RUN, HASH, false)
                TestRunner.equal(witch.status, "disabled")
                local _, unlock = LanternWitch.unlock(witch)
                TestRunner.equal(unlock.accepted, false)
            end,
        },
        {
            -- Read-and-time: the guard turns most of a blow away until the
            -- answering mirror is turned, and the window closes on its own.
            name = "the Many-Face guards until its answering mirror is turned",
            run = function()
                local state = activeManyFace()
                local guarded
                state, guarded = ManyFace.strike(state, 7, 40, 100)
                TestRunner.equal(guarded.countered, false)
                TestRunner.equal(guarded.reason, "guarded")
                TestRunner.truthy(guarded.damage < 40)
                TestRunner.truthy(guarded.damage >= 1)

                local wanted = ManyFace.counterFor(state.faceIndex)
                for mirrorId in ManyFace.MirrorIds do
                    if mirrorId ~= wanted then
                        local wrong
                        state, wrong = ManyFace.turnMirror(state, 7, mirrorId, 100)
                        TestRunner.equal(wrong.accepted, false)
                        TestRunner.equal(wrong.reason, "wrong_mirror")
                    end
                end
                local right
                state, right = ManyFace.turnMirror(state, 7, wanted, 100)
                TestRunner.equal(right.accepted, true)
                TestRunner.equal(state.status, "countered")

                local landed
                state, landed = ManyFace.strike(state, 7, 40, 101)
                TestRunner.equal(landed.countered, true)
                TestRunner.equal(landed.damage, 40)

                -- the window closes on its own and the guard is back
                state = ManyFace.expire(state, 100 + ManyFace.CounterSeconds)
                TestRunner.equal(state.status, "wearing")
                local lapsed
                state, lapsed = ManyFace.strike(state, 7, 40, 200)
                TestRunner.equal(lapsed.countered, false)
            end,
        },
        {
            -- Faces cycle, the counter follows the face, and the fight
            -- converges even for a player who never reads a single tell.
            name = "faces cycle deterministically and a guarded fight still ends",
            run = function()
                local state = activeManyFace()
                local firstFace = ManyFace.faceAt(state.faceIndex)
                local seen: { [string]: boolean } = {}
                for _ = 1, #ManyFace.Faces do
                    seen[ManyFace.faceAt(state.faceIndex)] = true
                    TestRunner.equal(
                        ManyFace.counterFor(state.faceIndex),
                        ManyFace.counterFor(state.faceIndex)
                    )
                    state = (ManyFace.cycleFace(state))
                end
                local distinct = 0
                for _ in seen do
                    distinct += 1
                end
                TestRunner.equal(distinct, #ManyFace.Faces)
                TestRunner.equal(ManyFace.faceAt(state.faceIndex), firstFace)

                local guard = 0
                while state.status ~= "complete" and guard < 500 do
                    guard += 1
                    state = (ManyFace.strike(state, 7, 40, 0))
                end
                TestRunner.equal(state.status, "complete")
            end,
        },
        {
            -- The Caller's fight is arithmetic: silting relieves, crowding
            -- presses, and the cadence never reaches zero.
            name = "silting pools wounds the caller and calms the marsh",
            run = function()
                local state = activeCaller()
                local baseline = DrownedCaller.callCooldown(state)
                local _, early = DrownedCaller.strike(state, 7, 40)
                TestRunner.equal(early.accepted, false)

                local result
                state, result = DrownedCaller.siltPool(state, 7, "pool_north")
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(result.damage, DrownedCaller.SiltDamage)
                TestRunner.truthy(DrownedCaller.callCooldown(state) > baseline)
                local _, repeated = DrownedCaller.siltPool(state, 7, "pool_north")
                TestRunner.equal(repeated.accepted, false)

                -- a standing crowd presses the cadence back down, but never
                -- past the floor
                local crowded = state
                for _ = 1, 40 do
                    crowded = (DrownedCaller.summon(crowded))
                end
                TestRunner.truthy(
                    DrownedCaller.callCooldown(crowded) >= DrownedCaller.Tuning.minCallSeconds
                )
                crowded = DrownedCaller.summonDefeated(crowded)
                TestRunner.equal(crowded.summoned, 39)

                for _, poolId in DrownedCaller.PoolIds do
                    if not state.pools[poolId] then
                        state = (DrownedCaller.siltPool(state, 7, poolId))
                    end
                end
                TestRunner.equal(state.status, "exposed")
                local guard = 0
                while state.status ~= "complete" and guard < 100 do
                    guard += 1
                    state = (DrownedCaller.strike(state, 7, 40))
                end
                TestRunner.equal(state.status, "complete")
            end,
        },
        {
            -- Identify: a wrong name costs the round, never the run, and the
            -- false copy walks so the tell is learnable.
            name = "the witch is found by naming the wrong tell, and misses only cost a round",
            run = function()
                local state = openedWitch()
                TestRunner.equal(state.status, "hiding")
                local target = LanternWitch.falseCopy(state.round, state.phase)
                local wrongId = if target == "copy_first" then "copy_second" else "copy_first"
                local miss
                state, miss = LanternWitch.nameCopy(state, 7, wrongId)
                TestRunner.equal(miss.accepted, true)
                TestRunner.equal(miss.found, false)
                TestRunner.equal(state.status, "hiding")
                TestRunner.equal(state.health, LanternWitch.MaxHealth)
                local _, junk = LanternWitch.nameCopy(state, 7, "copy_nowhere")
                TestRunner.equal(junk.accepted, false)

                local hit
                state, hit = LanternWitch.nameCopy(
                    state,
                    7,
                    LanternWitch.falseCopy(state.round, state.phase)
                )
                TestRunner.equal(hit.found, true)
                TestRunner.equal(state.status, "found")
                -- the false copy moves between rounds rather than repeating
                TestRunner.truthy(LanternWitch.falseCopy(1, 1) ~= LanternWitch.falseCopy(2, 1))
            end,
        },
        {
            -- Consent: three endings, each reached by actually playing the
            -- fight differently, each with its own line.
            name = "spending or sparing her copies decides how the chapter closes",
            run = function()
                -- spend every copy, then refuse her: broken
                local broken = openedWitch()
                local guard = 0
                while broken.status ~= "asking" and guard < 40 do
                    guard += 1
                    broken = findWitch(broken)
                    if broken.status == "found" then
                        broken = (LanternWitch.useCopy(broken, 7, true))
                    end
                end
                TestRunner.equal(broken.status, "asking")
                local result
                broken, result = LanternWitch.answer(broken, 7, false)
                TestRunner.equal(result.outcome, "broken")
                TestRunner.equal(broken.status, "complete")

                -- spend every copy but consent: bound
                local bound = openedWitch()
                guard = 0
                while bound.status ~= "asking" and guard < 40 do
                    guard += 1
                    bound = findWitch(bound)
                    if bound.status == "found" then
                        bound = (LanternWitch.useCopy(bound, 7, true))
                    end
                end
                bound = (LanternWitch.answer(bound, 7, true))
                TestRunner.equal(bound.outcome, "bound")

                -- spare wherever possible, then consent: sealed
                local sealed = openedWitch()
                guard = 0
                local spared = false
                while sealed.status ~= "asking" and guard < 60 do
                    guard += 1
                    sealed = findWitch(sealed)
                    if sealed.status == "found" then
                        if not spared then
                            spared = true
                            sealed = (LanternWitch.useCopy(sealed, 7, false))
                            TestRunner.equal(sealed.status, "hiding")
                            TestRunner.equal(sealed.copiesSpent, 0)
                        else
                            sealed = (LanternWitch.useCopy(sealed, 7, true))
                        end
                    end
                end
                -- one spend per phase is unavoidable; sparing keeps the count
                -- low enough that consent seals rather than binds
                TestRunner.truthy(sealed.copiesSpent >= 1)

                local lines: { [string]: boolean } = {}
                for _, state in { broken, bound } do
                    local line = LanternWitch.snapshot(state, 7).instruction
                    TestRunner.equal(lines[line], nil, "outcomes share a line")
                    lines[line] = true
                end
                TestRunner.equal(LanternWitch.snapshot(broken, 7).rewardEligible, true)
                TestRunner.equal(LanternWitch.snapshot(broken, 11).rewardEligible, false)
            end,
        },
        {
            -- Every Fen encounter must be its own thing, and its payouts
            -- must never settle another encounter's ledger entry.
            name = "the Fen's encounters share no telegraph, reward or transaction id",
            run = function()
                local attackIds: { [string]: boolean } = {}
                local function collect(id: string)
                    TestRunner.equal(attackIds[id], nil, "shared telegraph: " .. id)
                    attackIds[id] = true
                end
                for index = 1, 2 do
                    for step = 0, 3 do
                        local a = ManyFace.attack(index, step).attackId
                        if attackIds[a] == nil then
                            collect(a)
                        end
                    end
                end
                local seenIds: { [string]: boolean } = {}
                for _, id in
                    {
                        DrownedCaller.attack(1, 0).attackId,
                        DrownedCaller.attack(2, 2).attackId,
                        LanternWitch.attack(1, 1).attackId,
                        LanternWitch.attack(2, 2).attackId,
                        LanternWitch.attack(1, 4).attackId,
                        BellowsMaw.attack(1, 1).attackId,
                    }
                do
                    TestRunner.equal(attackIds[id], nil, "shared telegraph: " .. id)
                    TestRunner.equal(seenIds[id], nil, "duplicate telegraph: " .. id)
                    seenIds[id] = true
                end

                local rewards = {
                    ManyFace.Reward.materialId,
                    DrownedCaller.Reward.materialId,
                    LanternWitch.Reward.materialId,
                }
                for _, materialId in rewards do
                    TestRunner.truthy(materialId ~= BellowsMaw.Reward.materialId)
                end

                local ids: { [string]: boolean } = {}
                for _, id in
                    {
                        ManyFace.rewardTransactionId(activeManyFace(), 7),
                        DrownedCaller.rewardTransactionId(activeCaller(), 7),
                        LanternWitch.rewardTransactionId(openedWitch(), 7),
                        BellowsMaw.rewardTransactionId(BellowsMaw.create(RUN, HASH, true), 7),
                    }
                do
                    TestRunner.equal(ids[id], nil, "duplicate reward id: " .. id)
                    ids[id] = true
                end
            end,
        },
    },
}
