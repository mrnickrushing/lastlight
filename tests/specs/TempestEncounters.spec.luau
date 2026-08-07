--!strict

local AdmiralWreck = require("../../src/shared/AdmiralWreckEncounter")
local BellowsMaw = require("../../src/shared/BellowsMawEncounter")
local LighthouseEater = require("../../src/shared/LighthouseEaterEncounter")
local TempestEnemies = require("../../src/shared/TempestEnemies")
local TideboundTitan = require("../../src/shared/TideboundTitanEncounter")
local TestRunner = require("../TestRunner")

local RUN = "run_reach"
local HASH = "aa998877"

local function activeEater(): any
    return (LighthouseEater.activate(LighthouseEater.create(RUN, HASH, true), 7))
end

local function activeWreck(): any
    return (AdmiralWreck.activate(AdmiralWreck.create(RUN, HASH, true), 7))
end

local function openedTitan(): any
    local state = TideboundTitan.create(RUN, HASH, true)
    state = (TideboundTitan.unlock(state))
    return (TideboundTitan.activate(state, 7))
end

-- Walk one Titan phase: climb what this phase asks, ground both rods,
-- work the gates the given way, then strike until the phase turns over.
local function walkTitanPhase(state: any, slam: boolean): any
    for _, wreckId in TideboundTitan.WreckIds do
        if state.status ~= "unreachable" then
            break
        end
        state = (TideboundTitan.climbWreck(state, 7, wreckId))
    end
    for _, rodId in TideboundTitan.RodIds do
        state = (TideboundTitan.groundRod(state, 7, rodId))
    end
    for gateId in TideboundTitan.GateIds do
        state = (TideboundTitan.lowerTide(state, 7, gateId, slam))
    end
    local guard = 0
    while state.status == "exposed" and guard < 60 do
        guard += 1
        state = (TideboundTitan.strike(state, 7, 45))
    end
    return state
end

return {
    name = "TempestEncounters",
    cases = {
        {
            -- The Reach throws rather than charges: almost everything here
            -- attacks along a line, and two of its six cannot be answered
            -- with damage alone.
            name = "the Reach fights along lines the weather is already pushing",
            run = function()
                local lanes = 0
                local statusBearing = 0
                for _, definition in TempestEnemies.all() do
                    if definition.shape == "lane" then
                        lanes += 1
                    end
                    if definition.statusEffect ~= nil then
                        statusBearing += 1
                    end
                    TestRunner.truthy(definition.windup > 0.9, definition.id .. " gives no warning")
                end
                TestRunner.truthy(lanes >= 3, "the Reach does not fight along lines")
                TestRunner.truthy(statusBearing >= 1)
                -- the breaker is the region's wall: a face and a flank, the
                -- Crank Guard's lesson taught by water
                local breaker = TempestEnemies.require("enemy_breaker")
                TestRunner.equal(breaker.frontShield, true)
                TestRunner.truthy(
                    (breaker.flankStrikeDamage :: number)
                        > (breaker.frontalStrikeDamage :: number) * 3
                )
            end,
        },
        {
            -- The Eater's windows are rented, not bought: beacons burn
            -- down whether or not anyone is watching.
            name = "the lighthouse eater can only be struck by the light you are paying for",
            run = function()
                local state = activeEater()
                TestRunner.equal(state.status, "hidden")
                local _, blind = LighthouseEater.strike(state, 7, 40, 100)
                TestRunner.equal(blind.accepted, false)

                local lit
                state, lit = LighthouseEater.lightBeacon(state, 7, "beacon_point", 100)
                TestRunner.equal(lit.accepted, true)
                TestRunner.equal(state.status, "drawn")
                local hit
                state, hit = LighthouseEater.strike(state, 7, 40, 101)
                TestRunner.equal(hit.accepted, true)
                TestRunner.equal(state.health, LighthouseEater.MaxHealth - 40)

                -- the beam burns down on its own and it is gone again
                state = LighthouseEater.expire(state, 100 + LighthouseEater.BeaconSeconds + 1)
                TestRunner.equal(state.status, "hidden")
                local _, late = LighthouseEater.strike(state, 7, 40, 200)
                TestRunner.equal(late.accepted, false)
                -- and a beacon already burning cannot be re-lit for free
                state = (LighthouseEater.lightBeacon(state, 7, "beacon_jetty", 200))
                local _, again = LighthouseEater.lightBeacon(state, 7, "beacon_jetty", 201)
                TestRunner.equal(again.accepted, false)
            end,
        },
        {
            -- The Admiral is the Widow's opposite: her cuts stay cut and
            -- his do not, so his is a fight about holding a state.
            name = "the admiral's cover comes back if a party lets go",
            run = function()
                local state = activeWreck()
                local guarded
                state, guarded = AdmiralWreck.strike(state, 7, 40)
                TestRunner.equal(guarded.covered, true)
                TestRunner.truthy(guarded.damage < 40 and guarded.damage >= 1)

                for _, lineId in AdmiralWreck.LineIds do
                    state = (AdmiralWreck.cutLine(state, 7, lineId))
                end
                TestRunner.equal(state.status, "exposed")
                local full
                state, full = AdmiralWreck.strike(state, 7, 40)
                TestRunner.equal(full.covered, false)
                TestRunner.equal(full.damage, 40)

                -- his crew re-rigs one and the ring turns again
                state = (AdmiralWreck.rerigLine(state, "tow_bow"))
                TestRunner.equal(state.status, "covered")
                local coveredAgain
                state, coveredAgain = AdmiralWreck.strike(state, 7, 40)
                TestRunner.equal(coveredAgain.covered, true)
            end,
        },
        {
            -- Climb, ground, lower -- in that order, every phase, with the
            -- climb count ratcheting and the wrecks pulled back under.
            name = "the titan asks for its three verbs in order, and more climbing each phase",
            run = function()
                local state = openedTitan()
                local expected = { 2, 3, 4 }
                for phase = 1, 3 do
                    TestRunner.equal(state.phase, phase)
                    TestRunner.equal(state.status, "unreachable")
                    TestRunner.equal(
                        TideboundTitan.snapshot(state, 7).climbsRequired,
                        expected[phase]
                    )
                    -- nothing out of order works
                    local _, earlyStrike = TideboundTitan.strike(state, 7, 40)
                    TestRunner.equal(earlyStrike.accepted, false)
                    local _, earlyRod = TideboundTitan.groundRod(state, 7, "rod_seaward")
                    TestRunner.equal(earlyRod.accepted, false)
                    for wreckId in state.climbed do
                        TestRunner.equal(state.climbed[wreckId], nil)
                    end
                    state = walkTitanPhase(state, false)
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.health, 0)
                TestRunner.equal(TideboundTitan.snapshot(state, 7).rewardEligible, true)
            end,
        },
        {
            -- The gates are the chapter's decision, and it is made by how
            -- a party ends the fight rather than in a menu.
            name = "how the tide was lowered is what the harbour keeps",
            run = function()
                local eased = openedTitan()
                for _ = 1, 3 do
                    eased = walkTitanPhase(eased, false)
                end
                TestRunner.equal(eased.outcome, "navigable")

                local slammed = openedTitan()
                for _ = 1, 3 do
                    slammed = walkTitanPhase(slammed, true)
                end
                TestRunner.equal(slammed.outcome, "broken")

                local mixed = openedTitan()
                mixed = walkTitanPhase(mixed, true)
                mixed = walkTitanPhase(mixed, false)
                mixed = walkTitanPhase(mixed, false)
                TestRunner.equal(mixed.outcome, "scoured")

                local lines: { [string]: boolean } = {}
                for _, state in { eased, slammed, mixed } do
                    local line = TideboundTitan.snapshot(state, 7).instruction
                    TestRunner.equal(lines[line], nil, "two outcomes share a line")
                    lines[line] = true
                end
            end,
        },
        {
            -- No telegraph, reward or transaction id may be shared with a
            -- fight from an earlier region.
            name = "the Reach's fights borrow nothing from the Delve's",
            run = function()
                local seen: { [string]: boolean } = {}
                for _, id in
                    {
                        LighthouseEater.attack(1, 0).attackId,
                        LighthouseEater.attack(2, 1).attackId,
                        AdmiralWreck.attack(1, 0).attackId,
                        AdmiralWreck.attack(2, 4).attackId,
                        TideboundTitan.attack(1, 1).attackId,
                        TideboundTitan.attack(1, 1, "grounding").attackId,
                        TideboundTitan.attack(2, 3).attackId,
                        BellowsMaw.attack(1, 1).attackId,
                        BellowsMaw.attack(1, 1, "pressured").attackId,
                    }
                do
                    TestRunner.equal(seen[id], nil, "shared telegraph: " .. id)
                    seen[id] = true
                end

                local ids: { [string]: boolean } = {}
                for _, id in
                    {
                        LighthouseEater.rewardTransactionId(activeEater(), 7),
                        AdmiralWreck.rewardTransactionId(activeWreck(), 7),
                        TideboundTitan.rewardTransactionId(openedTitan(), 7),
                        BellowsMaw.rewardTransactionId(BellowsMaw.create(RUN, HASH, true), 7),
                    }
                do
                    TestRunner.equal(ids[id], nil, "duplicate reward id: " .. id)
                    ids[id] = true
                end
            end,
        },
        {
            name = "every Reach encounter honors its kill switch",
            run = function()
                local eater = LighthouseEater.create(RUN, HASH, false)
                local _, lit = LighthouseEater.lightBeacon(eater, 7, "beacon_point", 10)
                TestRunner.equal(lit.accepted, false)

                local wreck = AdmiralWreck.create(RUN, HASH, false)
                local _, cut = AdmiralWreck.cutLine(wreck, 7, "tow_bow")
                TestRunner.equal(cut.accepted, false)

                local titan = TideboundTitan.create(RUN, HASH, false)
                local _, unlocked = TideboundTitan.unlock(titan)
                TestRunner.equal(unlocked.accepted, false)
            end,
        },
    },
}
