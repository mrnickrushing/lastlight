--!strict

--[[
    When the store may open, and -- more to the point -- when it may not.

    Milestone 11's exit gate is one sentence: *the store never interrupts
    onboarding, active defense, downed state, or defeat.* The monetization
    document says the same thing from the other side, listing "popups during
    downed, defeat, urgent defense, or first-session teaching" among the
    explicitly prohibited. Both are rules about a moment rather than about a
    product, which is why they belong in a predicate rather than in a comment
    beside a button.

    **It is pure, and both sides call it.** The server decides -- a client that
    decided would be a client that could decide otherwise -- but the HUD asks
    the same function with the same snapshot fields, so a panel that is open
    when a night starts closes itself on the frame the state changes rather
    than waiting for somebody to press something. One rule, two readers, no
    second copy to drift.

    **The order the refusals are checked in is the message a player gets.** A
    player who is downed during a lost night is being refused for the worst
    reason that applies, not the first one the code happened to look at.
]]

local Strings = require("./Strings")

local StoreAvailability = {}

export type Context = {
    -- The kill switch. `cosmetic_store_enabled` is false until there are
    -- products to sell, and a flag that only hides the button is not a kill
    -- switch.
    storeEnabled: boolean?,
    tutorialComplete: boolean?,
    nightActive: boolean?,
    -- Creatures standing in the world right now. Night is not the only defense
    -- this game runs: a blackout relay, a town incident and both boss fights
    -- all put a player in one during daylight, and every one of them is a
    -- moment a store is not welcome in.
    enemyCount: number?,
    downed: boolean?,
    -- Everybody who could act is down. This game has no permanent loss, so
    -- defeat is the party wipe -- the moment the guard's last stand exists to
    -- answer, and the single worst moment in the game to be sold something.
    partyDown: boolean?,
}

export type Verdict = {
    open: boolean,
    reason: string,
    label: string,
}

--[[
    Every refusal, in the order they are asked, with the line a player reads.

    The labels are the same voice as every other refusal in the HUD, and none
    of them apologises for the store: a player told "not now" during a night
    should read it as the game protecting the night.
]]
local REFUSALS: { { reason: string, label: string } } = table.freeze({
    table.freeze({
        reason = "store_disabled",
        label = Strings.get("tutorial.the_outfitter_is_not_open_yet"),
    }),
    table.freeze({
        reason = "defeat",
        label = Strings.get("store.the_party_is_down_that_is"),
    }),
    table.freeze({ reason = "downed", label = Strings.get("store.get_back_on_your_feet_first") }),
    table.freeze({
        reason = "active_defense",
        label = Strings.get("store.not_while_something_is_out_there"),
    }),
    table.freeze({
        reason = "onboarding",
        label = Strings.get("store.finish_the_first_night_first"),
    }),
})

local OPEN: Verdict =
    table.freeze({ open = true, reason = "open", label = Strings.get("world.outfitter") })

local function refusal(reason: string): Verdict
    for _, entry in REFUSALS do
        if entry.reason == reason then
            return table.freeze({ open = false, reason = entry.reason, label = entry.label })
        end
    end
    -- Unreachable through `evaluate`; kept as a total function so a caller
    -- asking about a reason nobody wrote gets a closed store rather than nil.
    return table.freeze({
        open = false,
        reason = reason,
        label = Strings.get("store.the_outfitter_is_closed"),
    })
end

function StoreAvailability.reasons(): { { reason: string, label: string } }
    return REFUSALS
end

function StoreAvailability.evaluate(context: any): Verdict
    if type(context) ~= "table" then
        return refusal("store_disabled")
    end
    if context.storeEnabled ~= true then
        return refusal("store_disabled")
    end
    --[[
        Defeat before downed, and downed before the defense that caused it.

        A wiped party is one refusal, not one per member, and the player being
        told about it is being told the most important true thing. Checking in
        the other order would answer a lost night with "not while something is
        out there", which is technically correct and reads as the game not
        having noticed.
    ]]
    if context.partyDown == true then
        return refusal("defeat")
    end
    if context.downed == true then
        return refusal("downed")
    end
    local enemyCount = tonumber(context.enemyCount) or 0
    if context.nightActive == true or enemyCount > 0 then
        return refusal("active_defense")
    end
    --[[
        Onboarding last, and it is the only one that is not about danger.

        First-session teaching is a prohibited moment for its own reason: a
        player who has not finished the first night has not yet been shown what
        any of this is for, and a storefront is the loudest possible answer to
        a question they have not asked.
    ]]
    if context.tutorialComplete ~= true then
        return refusal("onboarding")
    end
    return OPEN
end

return table.freeze(StoreAvailability)
