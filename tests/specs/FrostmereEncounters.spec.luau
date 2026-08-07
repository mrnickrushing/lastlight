--!strict

local AbbeySilence = require("../../src/shared/AbbeySilenceEncounter")
local AuroraHart = require("../../src/shared/AuroraHartEncounter")
local FrostmereEnemies = require("../../src/shared/FrostmereEnemies")
local LighthouseEater = require("../../src/shared/LighthouseEaterEncounter")
local TideboundTitan = require("../../src/shared/TideboundTitanEncounter")
local WhiteHowler = require("../../src/shared/WhiteHowlerEncounter")
local TestRunner = require("../TestRunner")

local RUN = "run_vale"
local HASH = "cc4411dd"

local function activeSilence(): any
    return (AbbeySilence.activate(AbbeySilence.create(RUN, HASH, true), 7))
end

local function activeHart(): any
    return (AuroraHart.activate(AuroraHart.create(RUN, HASH, true), 7))
end

local function openedHowler(): any
    local state = WhiteHowler.create(RUN, HASH, true)
    state = (WhiteHowler.unlock(state))
    return (WhiteHowler.activate(state, 7))
end

-- Walk one Howler phase: quiet what this phase asks, share both warmths
-- the given way, read the trail, then strike until the phase turns over.
local function walkHowlerPhase(state: any, toDen: boolean): any
    for _, noiseId in WhiteHowler.NoiseIds do
        if state.status ~= "listening" then
            break
        end
        state = (WhiteHowler.hush(state, 7, noiseId))
    end
    for _, warmthId in WhiteHowler.WarmthIds do
        if state.status ~= "warming" then
            break
        end
        state = (WhiteHowler.shareWarmth(state, 7, warmthId, toDen))
    end
    for _, trackId in WhiteHowler.TrackIds do
        if state.status ~= "tracking" then
            break
        end
        state = (WhiteHowler.followTrack(state, 7, trackId))
    end
    local guard = 0
    while state.status == "exposed" and guard < 60 do
        guard += 1
        state = (WhiteHowler.strike(state, 7, 45))
    end
    return state
end

return {
    name = "FrostmereEncounters",
    cases = {
        {
            -- The Vale spends a player's options rather than their health:
            -- the softest damage in the game and the most status on it.
            name = "the Vale takes what you can do before it takes what you have",
            run = function()
                local statusBearing = 0
                local heaviest = 0
                for _, definition in FrostmereEnemies.all() do
                    if definition.statusEffect ~= nil then
                        statusBearing += 1
                    end
                    heaviest = math.max(heaviest, definition.playerDamage)
                    TestRunner.truthy(definition.windup > 0.7, definition.id .. " gives no warning")
                end
                TestRunner.truthy(statusBearing >= 2, "nothing in the Vale costs you a choice")
                TestRunner.truthy(heaviest <= 26, "the Vale hits like a region that means to")
                -- the shell is the one that has to be fought near a fire
                local shell = FrostmereEnemies.require("enemy_rime_shell")
                TestRunner.equal(shell.frontShield, true)
                TestRunner.equal(shell.targetMode, "lantern")
                TestRunner.truthy(
                    (shell.flankStrikeDamage :: number) > (shell.frontalStrikeDamage :: number) * 3
                )
            end,
        },
        {
            -- Silence is the guard, bells are the key, and both are on
            -- clocks the party does not own.
            name = "the abbey silence can only be struck in a room that has sound",
            run = function()
                local state = activeSilence()
                TestRunner.equal(state.status, "silent")
                local muffled
                state, muffled = AbbeySilence.strike(state, 7, 40, 100)
                TestRunner.equal(muffled.accepted, true)
                TestRunner.equal(muffled.heard, false)
                TestRunner.truthy(muffled.damage < 40 and muffled.damage >= 1)

                local rung
                state, rung = AbbeySilence.ringBell(state, 7, "bell_cloister", 100)
                TestRunner.equal(rung.accepted, true)
                TestRunner.equal(state.status, "ringing")
                local heard
                state, heard = AbbeySilence.strike(state, 7, 40, 101)
                TestRunner.equal(heard.heard, true)
                TestRunner.equal(heard.damage, 40)

                -- a second bell is worth more than the first was
                state = (AbbeySilence.ringBell(state, 7, "bell_stair", 101))
                local louder
                state, louder = AbbeySilence.strike(state, 7, 40, 102)
                TestRunner.truthy(louder.damage > 40)

                -- and the Silence smothers them again on its own schedule
                state = AbbeySilence.expire(state, 102 + AbbeySilence.BellSeconds + 1)
                TestRunner.equal(state.status, "silent")
                local late
                state, late = AbbeySilence.strike(state, 7, 40, 200)
                TestRunner.equal(late.heard, false)
                local again
                state, again = AbbeySilence.ringBell(state, 7, "bad_bell", 200)
                TestRunner.equal(again.accepted, false)
            end,
        },
        {
            -- The Hart never destroys warmth; it only divides it. The
            -- fight is refusing to let that finish.
            name = "the aurora hart splits the clearing and a party carries it back",
            run = function()
                local state = activeHart()
                TestRunner.equal(state.status, "banked")

                -- its own verb, on a clock: hottest hearth loses, coldest gains
                local before = state.hearths[AuroraHart.HearthIds[1]]
                state = AuroraHart.split(state)
                TestRunner.equal(state.hearths[AuroraHart.HearthIds[1]], before - 1)
                TestRunner.equal(state.status, "split")
                local scattered
                state, scattered = AuroraHart.strike(state, 7, 40)
                TestRunner.equal(scattered.banked, false)
                TestRunner.truthy(scattered.damage < 40 and scattered.damage >= 1)

                -- and nothing it took has left the clearing
                local total = 0
                for _, id in AuroraHart.HearthIds do
                    total += state.hearths[id]
                end
                TestRunner.equal(total, before)

                local carried
                state, carried = AuroraHart.carryEmber(
                    state,
                    7,
                    AuroraHart.HearthIds[2],
                    AuroraHart.HearthIds[1]
                )
                TestRunner.equal(carried.accepted, true)
                TestRunner.equal(state.status, "banked")
                local full
                state, full = AuroraHart.strike(state, 7, 40)
                TestRunner.equal(full.banked, true)
                TestRunner.equal(full.damage, 40)

                -- a cold hearth has nothing to give and a hearth is not a hearth
                local _, cold = AuroraHart.carryEmber(
                    state,
                    7,
                    AuroraHart.HearthIds[3],
                    AuroraHart.HearthIds[1]
                )
                TestRunner.equal(cold.accepted, false)
                local _, unknown =
                    AuroraHart.carryEmber(state, 7, "hearth_nowhere", AuroraHart.HearthIds[1])
                TestRunner.equal(unknown.accepted, false)
            end,
        },
        {
            -- Quiet, warm, track -- in that order, every phase, with the
            -- hush count ratcheting and the bowl waking between phases.
            name = "the howler asks for its three verbs in order, and more quiet each phase",
            run = function()
                local state = openedHowler()
                local expected = { 2, 3, 4 }
                for phase = 1, 3 do
                    TestRunner.equal(state.phase, phase)
                    TestRunner.equal(state.status, "listening")
                    TestRunner.equal(WhiteHowler.snapshot(state, 7).hushRequired, expected[phase])
                    -- nothing out of order works
                    local _, earlyStrike = WhiteHowler.strike(state, 7, 40)
                    TestRunner.equal(earlyStrike.accepted, false)
                    local _, earlyWarmth = WhiteHowler.shareWarmth(state, 7, "warmth_kettle", false)
                    TestRunner.equal(earlyWarmth.accepted, false)
                    local _, earlyTrack = WhiteHowler.followTrack(state, 7, "track_ridge")
                    TestRunner.equal(earlyTrack.accepted, false)
                    for noiseId in state.hushed do
                        TestRunner.equal(state.hushed[noiseId], nil)
                    end
                    state = walkHowlerPhase(state, false)
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.health, 0)
                TestRunner.equal(WhiteHowler.snapshot(state, 7).rewardEligible, true)
            end,
        },
        {
            -- Reading a mark that is not the next one loses the trail,
            -- and the phase restarts at the noise it started at.
            name = "guessing at the aurora costs the whole phase",
            run = function()
                local state = openedHowler()
                for _, noiseId in WhiteHowler.NoiseIds do
                    if state.status ~= "listening" then
                        break
                    end
                    state = (WhiteHowler.hush(state, 7, noiseId))
                end
                for _, warmthId in WhiteHowler.WarmthIds do
                    if state.status ~= "warming" then
                        break
                    end
                    state = (WhiteHowler.shareWarmth(state, 7, warmthId, false))
                end
                TestRunner.equal(state.status, "tracking")

                local lost
                state, lost = WhiteHowler.followTrack(state, 7, "track_stair")
                TestRunner.equal(lost.accepted, false)
                TestRunner.equal(lost.lost, true)
                TestRunner.equal(state.status, "listening")
                TestRunner.equal(WhiteHowler.snapshot(state, 7).hushed, 0)
                TestRunner.equal(WhiteHowler.snapshot(state, 7).shared, 0)
                TestRunner.equal(state.phase, 1)
            end,
        },
        {
            -- Warming the den is paid for in the same phase that chose it,
            -- and what the Vale keeps is the sum of those choices.
            name = "what the vale keeps is decided by where the warmth went",
            run = function()
                local kept = openedHowler()
                for _ = 1, 3 do
                    kept = walkHowlerPhase(kept, false)
                end
                TestRunner.equal(kept.outcome, "silenced")

                local given = openedHowler()
                for _ = 1, 3 do
                    given = walkHowlerPhase(given, true)
                end
                TestRunner.equal(given.outcome, "sheltered")

                local mixed = openedHowler()
                mixed = walkHowlerPhase(mixed, true)
                mixed = walkHowlerPhase(mixed, false)
                mixed = walkHowlerPhase(mixed, false)
                TestRunner.equal(mixed.outcome, "thinned")

                -- the den costs a mark in the phase that warmed it
                local paying = openedHowler()
                for _, noiseId in WhiteHowler.NoiseIds do
                    if paying.status ~= "listening" then
                        break
                    end
                    paying = (WhiteHowler.hush(paying, 7, noiseId))
                end
                TestRunner.equal(WhiteHowler.tracksRequired(paying), 2)
                paying = (WhiteHowler.shareWarmth(paying, 7, "warmth_lantern", true))
                TestRunner.equal(WhiteHowler.tracksRequired(paying), 3)

                local lines: { [string]: boolean } = {}
                for _, state in { kept, given, mixed } do
                    local line = WhiteHowler.snapshot(state, 7).instruction
                    TestRunner.equal(lines[line], nil, "two outcomes share a line")
                    lines[line] = true
                end
            end,
        },
        {
            -- No telegraph, reward or transaction id may be shared with a
            -- fight from an earlier region.
            name = "the Vale's fights borrow nothing from the Reach's",
            run = function()
                local seen: { [string]: boolean } = {}
                for _, id in
                    {
                        AbbeySilence.attack(1, 0).attackId,
                        AbbeySilence.attack(2, 1).attackId,
                        AuroraHart.attack(1, true).attackId,
                        AuroraHart.attack(2, false).attackId,
                        WhiteHowler.attack(1, 1, "listening").attackId,
                        WhiteHowler.attack(1, 1, "tracking").attackId,
                        WhiteHowler.attack(1, 1, "exposed").attackId,
                        LighthouseEater.attack(1, 0).attackId,
                        TideboundTitan.attack(1, 1).attackId,
                    }
                do
                    TestRunner.equal(seen[id], nil, "shared telegraph: " .. id)
                    seen[id] = true
                end

                local ids: { [string]: boolean } = {}
                for _, id in
                    {
                        AbbeySilence.rewardTransactionId(activeSilence(), 7),
                        AuroraHart.rewardTransactionId(activeHart(), 7),
                        WhiteHowler.rewardTransactionId(openedHowler(), 7),
                        LighthouseEater.rewardTransactionId(
                            LighthouseEater.create(RUN, HASH, true),
                            7
                        ),
                        TideboundTitan.rewardTransactionId(
                            TideboundTitan.create(RUN, HASH, true),
                            7
                        ),
                    }
                do
                    TestRunner.equal(ids[id], nil, "duplicate reward id: " .. id)
                    ids[id] = true
                end

                -- and no two of them pay out the same material
                TestRunner.truthy(AbbeySilence.Reward.materialId ~= AuroraHart.Reward.materialId)
                TestRunner.truthy(AuroraHart.Reward.materialId ~= WhiteHowler.Reward.materialId)
                TestRunner.truthy(AbbeySilence.Reward.materialId ~= WhiteHowler.Reward.materialId)
            end,
        },
        {
            name = "every Vale encounter honors its kill switch",
            run = function()
                local silence = AbbeySilence.create(RUN, HASH, false)
                local _, rung = AbbeySilence.ringBell(silence, 7, "bell_cloister", 10)
                TestRunner.equal(rung.accepted, false)

                local hart = AuroraHart.create(RUN, HASH, false)
                local _, carried =
                    AuroraHart.carryEmber(hart, 7, AuroraHart.HearthIds[1], AuroraHart.HearthIds[2])
                TestRunner.equal(carried.accepted, false)
                TestRunner.equal(AuroraHart.split(hart).splits, 0)

                local howler = WhiteHowler.create(RUN, HASH, false)
                local _, unlocked = WhiteHowler.unlock(howler)
                TestRunner.equal(unlocked.accepted, false)
                local _, hushed = WhiteHowler.hush(howler, 7, "noise_bell_rope")
                TestRunner.equal(hushed.accepted, false)
            end,
        },
    },
}
