--!strict

-- Wayhome is a door, not a reward gate.
--
-- Banking a pouch can fail for reasons a player has no control over and
-- cannot clear from inside the wood: a session lock lost to a server
-- migration, a DataStore write that has not confirmed durable yet, a profile
-- still loading, an unbanked pouch that has hit its transaction cap. The
-- first version of the extraction flow returned early on every one of those
-- and never asked the world to move the player, so the failure a player
-- actually experienced was being stuck in the expedition -- and because an
-- empty pouch skips settlement entirely, *earning rewards* was what trapped
-- them.
--
-- Every decision this module returns leaves. Rewards that did not bank stay
-- unsettled in the session ledger and in the profile's pending rewards, so
-- the next extraction retries them; nothing here spends or discards value.
-- The only thing a failed settlement costs is the banking, and the message
-- says so.
--
-- No wording lives here. The localization guard only recognizes a literal
-- `Strings.get("...")`, so an indirect key handed back from this module would
-- read to it as a table entry nobody uses. This module owns the decision --
-- whether the player leaves, and whether anything banked -- and the caller
-- picks the sentence.

local ExtractionOutcome = {}

export type Decision = {
    exit: boolean,
    settled: boolean,
    reason: string?,
}

function ExtractionOutcome.unbanked(reason: any): Decision
    return {
        exit = true,
        reason = if type(reason) == "string" and reason ~= "" then reason else nil,
        settled = false,
    }
end

-- Used when the world itself could not move the player (no character, or a
-- transition already in flight). This is the one outcome that legitimately
-- leaves someone in the wood, and it clears by pressing the prompt again --
-- unlike a settlement failure, which never clears on its own.
function ExtractionOutcome.transitionUnavailable(reason: any): Decision
    local key = if type(reason) == "string" and reason ~= "" then reason else nil
    return {
        exit = false,
        reason = key or "transition_unavailable",
        settled = false,
    }
end

return table.freeze(ExtractionOutcome)
