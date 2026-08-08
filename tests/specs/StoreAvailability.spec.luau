--!strict

--[[
    The store never interrupts onboarding, active defense, downed state, or
    defeat.

    That is Milestone 11's exit gate word for word, and
    MONETIZATION_LIVEOPS_ANALYTICS lists the same four among the explicitly
    prohibited. Both are rules about a *moment*, which is why the predicate
    exists at all -- a rule about a moment enforced by remembering not to draw
    a button is a rule that lasts until somebody draws a button.

    Every forbidden state named in the gate is a case below and each one
    refuses. The whole point of the suite is that adding a fifth state is a
    line in one file rather than an audit of every caller.
]]

local RuntimeIds = require("../../src/shared/RuntimeIds")
local StoreAvailability = require("../../src/shared/StoreAvailability")
local TestRunner = require("../TestRunner")

-- A player standing in the town square with the store switched on. Every case
-- below is this, spoiled in exactly one way.
local function ready(): { [string]: any }
    return {
        storeEnabled = true,
        tutorialComplete = true,
        nightActive = false,
        enemyCount = 0,
        downed = false,
        partyDown = false,
    }
end

local function spoiled(field: string, value: any): { [string]: any }
    local context = ready()
    context[field] = value
    return context
end

return {
    name = "StoreAvailability",
    cases = {
        {
            name = "a player in town with the store open may browse",
            run = function()
                local verdict = StoreAvailability.evaluate(ready())
                TestRunner.equal(verdict.open, true)
                TestRunner.equal(verdict.reason, "open")
                TestRunner.truthy(#verdict.label > 0, "an open store still needs a name")
            end,
        },
        {
            --[[
                The four the exit gate names, each on its own, each refusing.
                A table rather than four cases so that a fifth forbidden state
                is one row: the failure this suite is written against is a
                state that stops being checked, not a state that is checked
                wrongly.
            ]]
            name = "every state the exit gate names refuses",
            run = function()
                local forbidden = {
                    { field = "tutorialComplete", value = false, reason = "onboarding" },
                    { field = "nightActive", value = true, reason = "active_defense" },
                    { field = "downed", value = true, reason = "downed" },
                    { field = "partyDown", value = true, reason = "defeat" },
                }
                for _, entry in forbidden do
                    local verdict = StoreAvailability.evaluate(spoiled(entry.field, entry.value))
                    TestRunner.equal(verdict.open, false, entry.field .. " did not close the store")
                    TestRunner.equal(verdict.reason, entry.reason)
                    TestRunner.truthy(
                        #verdict.label > 0,
                        entry.reason .. " refuses without saying anything"
                    )
                end
            end,
        },
        {
            --[[
                Defense is not only night.

                A blackout relay, a town incident and both boss fights all put
                a player in a fight during daylight, and every one of them is
                a moment the document's "urgent defense" is about. Reading
                only the night flag would have let the store open in the
                middle of the Warden Stag.
            ]]
            name = "anything walking in the world closes the store",
            run = function()
                local verdict = StoreAvailability.evaluate(spoiled("enemyCount", 1))
                TestRunner.equal(verdict.open, false)
                TestRunner.equal(verdict.reason, "active_defense")
                TestRunner.equal(StoreAvailability.evaluate(spoiled("enemyCount", 0)).open, true)
            end,
        },
        {
            --[[
                The kill switch is a kill switch.

                MONETIZATION_LIVEOPS_ANALYTICS requires one, and a flag that
                only hides a button is not one: this is the answer the server
                gives to the door and to every store action behind it, so the
                store being off closes all of them at once.
            ]]
            name = "the feature flag closes the store no matter what else is true",
            run = function()
                local verdict = StoreAvailability.evaluate(spoiled("storeEnabled", false))
                TestRunner.equal(verdict.open, false)
                TestRunner.equal(verdict.reason, "store_disabled")
                -- and a caller who passes nothing at all gets the same answer,
                -- because an absent context is not a permission
                TestRunner.equal(StoreAvailability.evaluate(nil).open, false)
                TestRunner.equal(StoreAvailability.evaluate({}).open, false)
                TestRunner.equal(StoreAvailability.evaluate("open").open, false)
            end,
        },
        {
            --[[
                The order the refusals are asked in is the message a player
                gets, and a wiped party during a night should be told about
                the wipe. Checking defense first would answer a lost night
                with "not while something is out there", which is true and
                reads as the game not having noticed.
            ]]
            name = "the worst true reason is the one a player is given",
            run = function()
                local lost = ready()
                lost.nightActive = true
                lost.enemyCount = 6
                lost.downed = true
                lost.partyDown = true
                TestRunner.equal(StoreAvailability.evaluate(lost).reason, "defeat")
                lost.partyDown = false
                TestRunner.equal(StoreAvailability.evaluate(lost).reason, "downed")
                lost.downed = false
                TestRunner.equal(StoreAvailability.evaluate(lost).reason, "active_defense")
            end,
        },
        {
            --[[
                Every refusal has a line, and no two of them share one.

                A player refused twice for different reasons and told the same
                sentence learns nothing from the second refusal, and a store
                that says the same thing during a night and during onboarding
                is a store that looks broken in both.
            ]]
            name = "no two refusals say the same thing",
            run = function()
                local seenReason: { [string]: boolean } = {}
                local seenLabel: { [string]: boolean } = {}
                for _, entry in StoreAvailability.reasons() do
                    TestRunner.equal(seenReason[entry.reason], nil, "duplicate " .. entry.reason)
                    TestRunner.equal(seenLabel[entry.label], nil, "duplicate line: " .. entry.label)
                    seenReason[entry.reason] = true
                    seenLabel[entry.label] = true
                    TestRunner.equal(
                        entry.label,
                        string.upper(entry.label),
                        entry.reason .. " is not in the HUD's voice"
                    )
                end
                TestRunner.truthy(seenReason.onboarding == true)
                TestRunner.truthy(seenReason.active_defense == true)
                TestRunner.truthy(seenReason.downed == true)
                TestRunner.truthy(seenReason.defeat == true)
            end,
        },
        {
            --[[
                And the structural half: the door is a thing in the world, not
                a button on the HUD.

                A storefront openable from the HUD is openable in every one of
                the four moments above, and the predicate would then be the
                only thing standing between a player and a shop over a boss
                fight. Making the outfitter's stand the only door means the
                gate is the second line rather than the only one.
            ]]
            name = "the only way in is an interaction in the world",
            run = function()
                TestRunner.truthy(
                    RuntimeIds.InteractionIds.Outfitter ~= nil,
                    "nothing in the world opens the store"
                )
                TestRunner.equal(RuntimeIds.Actions.OpenStore, "open_store")
            end,
        },
    },
}
