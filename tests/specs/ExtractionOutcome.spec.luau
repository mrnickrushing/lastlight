--!strict

local ExtractionOutcome = require("../../src/shared/ExtractionOutcome")
local TestRunner = require("../TestRunner")

-- Every reason `ProfileService.settleExpedition` can return, traced from its
-- own two early returns plus every `reason` field `ExpeditionInventory` can
-- produce through `withUnbankedExpeditionReward` and
-- `withExpeditionSettlement`. If a new failure mode is added to that path it
-- belongs here, and the "leaves on every settlement failure" case below is
-- what makes forgetting expensive.
local SETTLEMENT_FAILURE_REASONS = {
    "invalid_reward",
    "invalid_settlement",
    "invalid_transaction",
    "profile_loading",
    "profile_read_only",
    "save_pending",
    "unbanked_pouch_full",
}

return {
    name = "ExtractionOutcome",
    cases = {
        {
            name = "leaves the wood on every settlement failure",
            run = function()
                for _, reason in SETTLEMENT_FAILURE_REASONS do
                    local decision = ExtractionOutcome.unbanked(reason)
                    TestRunner.equal(decision.exit, true)
                    TestRunner.equal(decision.settled, false)
                    TestRunner.equal(decision.reason, reason)
                end
            end,
        },
        {
            name = "leaves the wood for a failure reason it has never seen",
            run = function()
                local decision = ExtractionOutcome.unbanked("some_future_datastore_fault")
                TestRunner.equal(decision.exit, true)
                TestRunner.equal(decision.settled, false)
                TestRunner.equal(decision.reason, "some_future_datastore_fault")
            end,
        },
        {
            name = "leaves the wood when no reason was reported at all",
            run = function()
                for _, reason in { 0, false, "" } do
                    local decision = ExtractionOutcome.unbanked(reason)
                    TestRunner.equal(decision.exit, true)
                    TestRunner.equal(decision.reason, nil)
                end
                -- Checked separately: a generic-for over an array literal
                -- skips a leading nil, so a nil folded into the list above
                -- would silently never be tested.
                local decision = ExtractionOutcome.unbanked(nil)
                TestRunner.equal(decision.exit, true)
                TestRunner.equal(decision.reason, nil)
            end,
        },
        {
            name = "hands the caller back the reason it was given, verbatim",
            run = function()
                -- The caller picks the sentence from this, and the service logs
                -- it -- so a reason that arrives mangled is a diagnostic that
                -- points at the wrong failure.
                for _, reason in SETTLEMENT_FAILURE_REASONS do
                    TestRunner.equal(ExtractionOutcome.unbanked(reason).reason, reason)
                end
            end,
        },
        {
            name = "never claims a failed settlement banked anything",
            run = function()
                for _, reason in SETTLEMENT_FAILURE_REASONS do
                    TestRunner.equal(ExtractionOutcome.unbanked(reason).settled, false)
                end
            end,
        },
        {
            name = "keeps the player put only when the world cannot move them",
            run = function()
                local decision = ExtractionOutcome.transitionUnavailable(nil)
                TestRunner.equal(decision.exit, false)
                TestRunner.equal(decision.settled, false)
                TestRunner.equal(decision.reason, "transition_unavailable")
            end,
        },
        {
            name = "remembers why a retryable transition was refused",
            run = function()
                local decision = ExtractionOutcome.transitionUnavailable("save_pending")
                TestRunner.equal(decision.exit, false)
                TestRunner.equal(decision.reason, "save_pending")
            end,
        },
    },
}
