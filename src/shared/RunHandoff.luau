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
      * **The party's ID travels too, and is the only reason it is here.** A
        run server that knows which party it belongs to can recognise one of
        its own members arriving on a rejoin ticket and leave them where they
        landed, instead of forwarding them to the world they are standing in.
        Like everything else in the payload it is inert: it names a party, it
        does not prove membership of one, and nothing is granted on it.
]]

local Strings = require("./Strings")

local RunHandoff = {}

export type Payload = {
    schemaVersion: number,
    kind: string,
    partySize: number,
    departedAt: number,
    partyId: string?,
}

--[[
    Bumped to 2 when the party ID joined the payload. A server mid-flight
    across a deploy carries a version-1 payload, which now reads as a
    mismatch and resolves to a lobby -- the safe direction the whole module
    is built on, and the reason the version is checked before anything else.
]]
local SCHEMA_VERSION = 2
local RUN_KIND = "last_light_run"
local MAX_PARTY_SIZE = 8
local MAX_PARTY_ID_LENGTH = 64

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

local function isPartyId(value: any): boolean
    return type(value) == "string" and #value > 0 and #value <= MAX_PARTY_ID_LENGTH
end

--[[
    Build the payload a departing party carries to its run server.

    `partySize` is the size the lobby actually launched, not the size that was
    requested, so a party that shrank on the platform arrives described
    correctly.

    `partyId` is optional because this module has to keep working for a
    departure that formed no party -- one player stepping onto the platform
    and tapping a number is still a run, and refusing it for want of a roster
    would be the party system taking something away.
]]
function RunHandoff.buildPayload(partySize: any, now: any, partyId: any): (Payload?, any)
    if not wholeBetween(partySize, 1, MAX_PARTY_SIZE) then
        return nil, { accepted = false, reason = "invalid_party_size" }
    end
    if not finite(now) or now < 0 then
        return nil, { accepted = false, reason = "invalid_time" }
    end
    if partyId ~= nil and not isPartyId(partyId) then
        return nil, { accepted = false, reason = "invalid_party_id" }
    end
    return {
        schemaVersion = SCHEMA_VERSION,
        kind = RUN_KIND,
        partySize = partySize,
        departedAt = now,
        partyId = partyId,
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
    --[[
        An unreadable party ID is dropped rather than rejected. The run is
        still a run; what is lost is only the server's ability to recognise
        its own returning members, and refusing the whole payload over that
        would strand a party in the lodge to protect a convenience.
    ]]
    return {
        isRun = true,
        partySize = value.partySize,
        departedAt = value.departedAt,
        partyId = if isPartyId(value.partyId) then value.partyId else nil,
    }
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
        message = Strings.get("toast.the_road_did_not_open_everyone"),
    }
end

return table.freeze(RunHandoff)
