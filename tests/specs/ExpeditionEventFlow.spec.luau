--!strict

local Catalog = require("../../src/shared/Content/Definitions/BramblewakeExpedition")
local ExpeditionEventFlow = require("../../src/shared/ExpeditionEventFlow")
local TestRunner = require("../TestRunner")

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
                for _, event in Catalog.Events do
                    local valid, issues = ExpeditionEventFlow.validateDefinition(event)
                    TestRunner.truthy(valid, table.concat(issues, "; "))
                    interactionCount += #event.steps
                end
                TestRunner.equal(interactionCount, Catalog.EventInteractionCount)
            end,
        },
        {
            name = "completes a shared event with a deterministic reward transaction",
            run = function()
                local event = definition("event_bw_lost_wagon")
                local state = ExpeditionEventFlow.create(event, "abcd1234")
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
                    "event_reward:abcd1234:event_bw_lost_wagon"
                )
                local snapshot = ExpeditionEventFlow.snapshot(state, event, 30)
                TestRunner.equal(#snapshot.participants, #event.steps)
            end,
        },
        {
            name = "treats repeated interaction delivery as idempotent",
            run = function()
                local event = definition("event_bw_root_bridge")
                local state = ExpeditionEventFlow.create(event, "manifest")
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
            name = "fails expired events without blocking the expedition route",
            run = function()
                local event = definition("event_bw_moving_hedge")
                local state = ExpeditionEventFlow.create(event, "manifest")
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
                local active = ExpeditionEventFlow.create(event, "manifest")
                local forged = ExpeditionEventFlow.contribute(active, event, "not_a_step", "9", 1)
                TestRunner.equal(forged.accepted, false)
                TestRunner.equal(forged.reason, "unknown_step")

                local disabled = ExpeditionEventFlow.create(event, "manifest", false)
                local blocked =
                    ExpeditionEventFlow.contribute(disabled, event, event.steps[1].id, "9", 1)
                TestRunner.equal(blocked.accepted, false)
                TestRunner.equal(blocked.reason, "event_disabled")
            end,
        },
    },
}
