--!strict

--[[
    The contract for handing a departing party to its own run server.

    Pure logic: no TeleportService, no players. It decides what a departure
    payload must contain, whether an arriving server should trust one, and
    what a server should do when a teleport fails. Keeping that here means the
    rules can be tested without a live game, which matters more than usual
    because reserved-server teleports cannot be exercised in Studio at all.

    The rules:

      * A run server is told what it is by its teleport payload. A server that
        receives no payload, or one it cannot verify, behaves as a lobby --
        the safe default, because a wrong guess in that direction strands a
        player in an empty world rather than merely showing them the lodge.
      * Payloads are validated field by field on arrival. Teleport data is
        reachable by exploiters on some paths, so nothing in it is trusted as
        authority: it may say "this is a run", never "give me rewards".
      * A failed teleport returns the party to the lobby with the departure
        cancelled and nothing consumed. A half-sent party that lost its
        staging state is worse than a party that never left.
      * The party size that was chosen travels with the payload so the run
        server can bound its own population without asking the lobby.
]]

local RunHandoff = {}

export type Payload = {
    schemaVersion: number,
    kind: string,
    partySize: number,
    departedAt: number,
}

local SCHEMA_VERSION = 1
local RUN_KIND = "last_light_run"
local MAX_PARTY_SIZE = 8

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function wholeBetween(value: any, low: number, high: number): boolean
    return finite(value) and value >= low and value <= high and value == math.floor(value)
end

function RunHandoff.schemaVersion(): number
    return SCHEMA_VERSION
end

function RunHandoff.runKind(): string
    return RUN_KIND
end

--[[
    Build the payload a departing party carries to its run server.

    `partySize` is the size the lobby actually launched, not the size that was
    requested, so a party that shrank on the platform arrives described
    correctly.
]]
function RunHandoff.buildPayload(partySize: any, now: any): (Payload?, any)
    if not wholeBetween(partySize, 1, MAX_PARTY_SIZE) then
        return nil, { accepted = false, reason = "invalid_party_size" }
    end
    if not finite(now) or now < 0 then
        return nil, { accepted = false, reason = "invalid_time" }
    end
    return {
        schemaVersion = SCHEMA_VERSION,
        kind = RUN_KIND,
        partySize = partySize,
        departedAt = now,
    }, { accepted = true }
end

--[[
    Decide what an arriving server is.

    Anything unrecognised resolves to a lobby. A server that wrongly believes
    it is a run skips the lodge and drops a player into the world with no way
    to start one; a server that wrongly believes it is a lobby merely shows a
    staging room the player can depart from again.
]]
function RunHandoff.readPayload(value: any): any
    if type(value) ~= "table" then
        return { isRun = false, reason = "no_payload" }
    end
    if value.schemaVersion ~= SCHEMA_VERSION then
        return { isRun = false, reason = "schema_mismatch" }
    end
    if value.kind ~= RUN_KIND then
        return { isRun = false, reason = "unknown_kind" }
    end
    if not wholeBetween(value.partySize, 1, MAX_PARTY_SIZE) then
        return { isRun = false, reason = "invalid_party_size" }
    end
    if not finite(value.departedAt) or value.departedAt < 0 then
        return { isRun = false, reason = "invalid_time" }
    end
    return { isRun = true, partySize = value.partySize, departedAt = value.departedAt }
end

--[[
    What to do when a teleport attempt fails.

    Always returns the party to the lobby and always cancels the departure.
    Reserving and teleporting are separate calls that can each fail, and the
    only safe response to either is to put everyone back where they were
    standing with nothing spent.
]]
function RunHandoff.failureRecovery(reason: any): any
    return {
        returnToLobby = true,
        cancelDeparture = true,
        reason = if type(reason) == "string" and #reason > 0 then reason else "unknown",
        message = "THE ROAD DID NOT OPEN - EVERYONE IS STILL HERE",
    }
end

return table.freeze(RunHandoff)
