--!strict

local BellowsMaw = require("../../src/shared/BellowsMawEncounter")
local WardenStag = require("../../src/shared/WardenStagEncounter")
local TestRunner = require("../TestRunner")

local RUN = "run_delve"
local HASH = "abc12345"

local function opened(): any
    local state = BellowsMaw.create(RUN, HASH, true)
    state = (BellowsMaw.unlock(state))
    state = (BellowsMaw.activate(state, 7))
    return state
end

-- Walk one phase: reroute until the feed starves, vent through the given
-- wheel, then strike until the phase turns over.
local function walkPhase(state: any, ventId: string, userId: number): any
    for lineId in BellowsMaw.LineIds do
        if state.status ~= "feeding" then
            break
        end
        state = (BellowsMaw.rerouteLine(state, userId, lineId))
    end
    state = (BellowsMaw.ventPressure(state, userId, ventId))
    local guard = 0
    while state.status == "exposed" and guard < 60 do
        guard += 1
        state = (BellowsMaw.strike(state, userId, 40))
    end
    return state
end

return {
    name = "BellowsMawEncounter",
    cases = {
        {
            name = "the chamber stays shut until the Delve is cleared",
            run = function()
                local state = BellowsMaw.create(RUN, HASH, true)
                TestRunner.equal(state.status, "locked")
                local _, early = BellowsMaw.activate(state, 7)
                TestRunner.equal(early.accepted, false)
                local _, reroute = BellowsMaw.rerouteLine(state, 7, "line_head")
                TestRunner.equal(reroute.accepted, false)
                local unlocked, result = BellowsMaw.unlock(state)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(unlocked.status, "dormant")
                local _, again = BellowsMaw.unlock(unlocked)
                TestRunner.equal(again.accepted, false)

                local disabled = BellowsMaw.create(RUN, HASH, false)
                TestRunner.equal(disabled.status, "disabled")
                local _, blocked = BellowsMaw.unlock(disabled)
                TestRunner.equal(blocked.accepted, false)
            end,
        },
        {
            -- The three verbs must happen in order: no striking a fed Maw,
            -- no venting one that is still eating.
            name = "reroute, vent, strike — and never out of order",
            run = function()
                local state = opened()
                TestRunner.equal(state.status, "feeding")
                local _, earlyStrike = BellowsMaw.strike(state, 7, 40)
                TestRunner.equal(earlyStrike.accepted, false)
                local _, earlyVent = BellowsMaw.ventPressure(state, 7, "vent_drift")
                TestRunner.equal(earlyVent.accepted, false)

                local first
                state, first = BellowsMaw.rerouteLine(state, 7, "line_head")
                TestRunner.equal(first.accepted, true)
                TestRunner.equal(first.starved, false)
                TestRunner.equal(first.remaining, 1)
                local repeated
                state, repeated = BellowsMaw.rerouteLine(state, 7, "line_head")
                TestRunner.equal(repeated.accepted, false)
                local junk
                state, junk = BellowsMaw.rerouteLine(state, 7, "line_nowhere")
                TestRunner.equal(junk.accepted, false)

                local second
                state, second = BellowsMaw.rerouteLine(state, 7, "line_spur")
                TestRunner.equal(second.starved, true)
                TestRunner.equal(state.status, "pressured")
                -- still not strikeable: pressure must be bled first
                local _, pressuredStrike = BellowsMaw.strike(state, 7, 40)
                TestRunner.equal(pressuredStrike.accepted, false)

                local vented
                state, vented = BellowsMaw.ventPressure(state, 7, "vent_stope")
                TestRunner.equal(vented.accepted, true)
                TestRunner.equal(state.status, "exposed")
                local hit
                state, hit = BellowsMaw.strike(state, 7, 40)
                TestRunner.equal(hit.accepted, true)
                TestRunner.equal(state.health, BellowsMaw.MaxHealth - 40)
            end,
        },
        {
            -- Phase gates ratchet, and each new phase re-locks the fight
            -- behind the same three verbs with one more line to reroute.
            name = "each phase asks for one more line and resets its switches",
            run = function()
                local state = opened()
                local expected = { 2, 3, 4 }
                for phase = 1, 3 do
                    TestRunner.equal(state.phase, phase)
                    TestRunner.equal(state.status, "feeding")
                    TestRunner.equal(BellowsMaw.snapshot(state, 7).linesRequired, expected[phase])
                    for lineId in BellowsMaw.LineIds do
                        TestRunner.equal(state.reroutedLines[lineId], nil)
                    end
                    state = walkPhase(state, "vent_stope", 7)
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.health, 0)
                TestRunner.equal(BellowsMaw.snapshot(state, 7).rewardEligible, true)
                TestRunner.equal(BellowsMaw.snapshot(state, 11).rewardEligible, false)
            end,
        },
        {
            -- The vent is the chapter's decision, and it is decided by play:
            -- the outcome must reflect what the crew actually reached for.
            name = "the vent chosen is the outcome remembered",
            run = function()
                local clean = opened()
                for _ = 1, 3 do
                    clean = walkPhase(clean, "vent_stope", 7)
                end
                TestRunner.equal(clean.outcome, "cleared")

                local fouled = opened()
                for _ = 1, 3 do
                    fouled = walkPhase(fouled, "vent_drift", 7)
                end
                TestRunner.equal(fouled.outcome, "fouled")

                local mixed = opened()
                mixed = walkPhase(mixed, "vent_drift", 7)
                mixed = walkPhase(mixed, "vent_stope", 7)
                mixed = walkPhase(mixed, "vent_stope", 7)
                TestRunner.equal(mixed.outcome, "mixed")
                -- and the completion line differs per outcome, so the
                -- consequence is legible without opening a menu
                local seen: { [string]: boolean } = {}
                for _, state in { clean, fouled, mixed } do
                    local line = BellowsMaw.snapshot(state, 7).instruction
                    TestRunner.equal(seen[line], nil, "outcomes share a line: " .. line)
                    seen[line] = true
                end
            end,
        },
        {
            -- Over-pressure has its own danger, and the Maw is not the Stag.
            name = "the Maw telegraphs its own way",
            run = function()
                TestRunner.equal(
                    BellowsMaw.attack(1, 1, "pressured").attackId,
                    "bellows_maw_pressure_burst"
                )
                TestRunner.truthy(
                    BellowsMaw.attack(1, 1).attackId ~= BellowsMaw.attack(2, 2).attackId
                )
                local mawIds: { [string]: boolean } = {}
                for phase = 1, 3 do
                    for index = 1, 2 do
                        mawIds[BellowsMaw.attack(index, phase).attackId] = true
                    end
                end
                for phase = 1, 3 do
                    for index = 1, 2 do
                        TestRunner.equal(
                            mawIds[WardenStag.attack(index, phase).attackId],
                            nil,
                            "the Maw borrows the Stag's telegraph"
                        )
                    end
                end
                TestRunner.truthy(BellowsMaw.Reward.materialId ~= WardenStag.Reward.materialId)
                TestRunner.truthy(
                    BellowsMaw.rewardTransactionId(opened(), 7)
                        ~= WardenStag.rewardTransactionId(WardenStag.create(RUN, HASH, true), 7)
                )
            end,
        },
    },
}
