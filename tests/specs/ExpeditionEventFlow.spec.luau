--!strict

local Catalog = require("../../src/shared/Content/Definitions/BramblewakeExpedition")
local ExpeditionEventFlow = require("../../src/shared/ExpeditionEventFlow")
local TestRunner = require("../TestRunner")

local EXPECTED_EVENT_IDS = {
    event_bw_foxlight_trail = true,
    event_bw_hungry_homestead = true,
    event_bw_lost_wagon = true,
    event_bw_moving_hedge = true,
    event_bw_pollen_storm = true,
    event_bw_root_bridge = true,
    event_bw_stag_tracks = true,
    event_bw_wildfire_choice = true,
}

local function definition(eventId: string): any
    for _, event in Catalog.Events do
        if event.id == eventId then
            return event
        end
    end
    error("missing event " .. eventId)
end

return {
    name = "ExpeditionEventFlow",
    cases = {
        {
            name = "validates every active Bramblewake event contract",
            run = function()
                local interactionCount = 0
                local seen = {}
                for _, event in Catalog.Events do
                    local valid, issues = ExpeditionEventFlow.validateDefinition(event)
                    TestRunner.truthy(valid, table.concat(issues, "; "))
                    TestRunner.truthy(EXPECTED_EVENT_IDS[event.id] == true)
                    TestRunner.truthy(not seen[event.id])
                    seen[event.id] = true
                    interactionCount += #event.steps
                end
                TestRunner.equal(#Catalog.Events, 8)
                TestRunner.equal(Catalog.EventCount, 8)
                TestRunner.equal(interactionCount, 25)
                TestRunner.equal(interactionCount, Catalog.EventInteractionCount)
                for eventId in EXPECTED_EVENT_IDS do
                    TestRunner.truthy(seen[eventId] == true)
                end
            end,
        },
        {
            name = "every event tells a stuck player what to do, alone and in a group",
            run = function()
                -- These strings were authored for all eight events and read by
                -- nothing, which is most of why the level was reported as
                -- leaving players with no idea what to do.
                for _, event in Catalog.Events do
                    local solo = ExpeditionEventFlow.guidanceFor(event, 1)
                    local group = ExpeditionEventFlow.guidanceFor(event, 3)
                    TestRunner.truthy(solo ~= nil and #(solo :: string) > 0, event.id)
                    TestRunner.truthy(group ~= nil and #(group :: string) > 0, event.id)
                    TestRunner.equal(solo, event.soloVariant.guidance)
                    TestRunner.equal(group, event.groupVariant.guidance)
                end
            end,
        },
        {
            name = "falls back to the solo line until a second player is actually there",
            run = function()
                -- Telling one player to split up is worse than telling them
                -- nothing, so the group line waits for a second participant.
                local event = definition("event_bw_moving_hedge")
                for _, count in { 0, 1, "3", -2, 1.5, 0 / 0 } do
                    TestRunner.equal(
                        ExpeditionEventFlow.guidanceFor(event, count),
                        event.soloVariant.guidance
                    )
                end
                TestRunner.equal(
                    ExpeditionEventFlow.guidanceFor(event, nil),
                    event.soloVariant.guidance
                )
                TestRunner.equal(
                    ExpeditionEventFlow.guidanceFor(event, 2),
                    event.groupVariant.guidance
                )
            end,
        },
        {
            name = "refuses an event that ships without guidance",
            run = function()
                local base = definition("event_bw_lost_wagon")
                for _, missing in { "soloVariant", "groupVariant" } do
                    local broken = table.clone(base)
                    broken[missing] = nil
                    local valid, issues = ExpeditionEventFlow.validateDefinition(broken)
                    TestRunner.equal(valid, false)
                    TestRunner.truthy(
                        string.find(table.concat(issues, "; "), missing) ~= nil,
                        table.concat(issues, "; ")
                    )
                end
                local blank = table.clone(base)
                blank.soloVariant = { guidance = "" }
                TestRunner.equal(ExpeditionEventFlow.validateDefinition(blank), false)
            end,
        },
        {
            name = "carries guidance into the snapshot the player actually sees",
            run = function()
                local event = definition("event_bw_moving_hedge")
                local state = ExpeditionEventFlow.create(event, "run-guidance", "hash-guidance")
                local alone = ExpeditionEventFlow.snapshot(state, event, 1)
                TestRunner.equal(alone.guidance, event.soloVariant.guidance)
            end,
        },
        {
            name = "completes a shared event with a deterministic reward transaction",
            run = function()
                local event = definition("event_bw_lost_wagon")
                local state = ExpeditionEventFlow.create(event, "run_1", "abcd1234")
                for index, step in event.steps do
                    local result = ExpeditionEventFlow.contribute(
                        state,
                        event,
                        step.id,
                        tostring(100 + index),
                        10 + index
                    )
                    TestRunner.equal(result.accepted, true)
                end

                TestRunner.equal(state.status, "completed")
                TestRunner.equal(state.progress, #event.steps)
                TestRunner.equal(
                    state.rewardTransactionId,
                    "event_reward:run_1:abcd1234:event_bw_lost_wagon"
                )
                local snapshot = ExpeditionEventFlow.snapshot(state, event, 30)
                TestRunner.equal(#snapshot.participants, #event.steps)
            end,
        },
        {
            name = "keeps every new event optional and profession independent",
            run = function()
                for _, eventId in
                    {
                        "event_bw_pollen_storm",
                        "event_bw_hungry_homestead",
                        "event_bw_stag_tracks",
                        "event_bw_wildfire_choice",
                    }
                do
                    local event = definition(eventId)
                    TestRunner.equal(event.defaultSolution, true)
                    TestRunner.equal(event.criticalPathBlocking, false)
                    TestRunner.truthy(event.safeFailure ~= "")
                    TestRunner.equal(#event.steps, 3)
                end
            end,
        },
        {
            name = "treats repeated interaction delivery as idempotent",
            run = function()
                local event = definition("event_bw_root_bridge")
                local state = ExpeditionEventFlow.create(event, "run_1", "manifest")
                local stepId = event.steps[1].id
                local first = ExpeditionEventFlow.contribute(state, event, stepId, "42", 100)
                local duplicate = ExpeditionEventFlow.contribute(state, event, stepId, "42", 101)

                TestRunner.equal(first.changed, true)
                TestRunner.equal(duplicate.accepted, true)
                TestRunner.equal(duplicate.changed, false)
                TestRunner.equal(duplicate.duplicate, true)
                TestRunner.equal(state.progress, 1)
            end,
        },
        {
            name = "separates reward transactions for repeated seeds in different runs",
            run = function()
                local first = ExpeditionEventFlow.transactionId(
                    "run_a",
                    "same_manifest",
                    "event_bw_root_bridge"
                )
                local second = ExpeditionEventFlow.transactionId(
                    "run_b",
                    "same_manifest",
                    "event_bw_root_bridge"
                )
                TestRunner.truthy(first ~= second)
            end,
        },
        {
            name = "fails expired events without blocking the expedition route",
            run = function()
                local event = definition("event_bw_moving_hedge")
                local state = ExpeditionEventFlow.create(event, "run_1", "manifest")
                ExpeditionEventFlow.contribute(state, event, event.steps[1].id, "7", 50)
                local late = ExpeditionEventFlow.contribute(
                    state,
                    event,
                    event.steps[2].id,
                    "7",
                    50 + event.durationSeconds
                )

                TestRunner.equal(late.accepted, false)
                TestRunner.equal(late.reason, "event_expired")
                TestRunner.equal(state.status, "failed")
                TestRunner.equal(event.criticalPathBlocking, false)
            end,
        },
        {
            name = "rejects forged steps and disabled event interactions",
            run = function()
                local event = definition("event_bw_foxlight_trail")
                local active = ExpeditionEventFlow.create(event, "run_1", "manifest")
                local forged = ExpeditionEventFlow.contribute(active, event, "not_a_step", "9", 1)
                TestRunner.equal(forged.accepted, false)
                TestRunner.equal(forged.reason, "unknown_step")

                local disabled = ExpeditionEventFlow.create(event, "run_1", "manifest", false)
                local blocked =
                    ExpeditionEventFlow.contribute(disabled, event, event.steps[1].id, "9", 1)
                TestRunner.equal(blocked.accepted, false)
                TestRunner.equal(blocked.reason, "event_disabled")
            end,
        },
    },
}
