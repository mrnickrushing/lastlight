--!strict

--[[
    Departure platform state for the Emberhollow lobby.

    Pure logic: no Roblox instances, no players, no clock of its own. The
    service layer owns "who is physically standing on the platform" and passes
    that in as a count; everything about whether a departure may start, how long
    is left, and whether it may launch lives here so it can be tested and can
    never be decided by a client.

    The rules the countdown has to hold:

      * Only the platform counts. Players who are not standing on it when the
        countdown reaches zero are not taken, which is the whole point of a
        staging platform.
      * A departure cannot be started, resized, or rushed by a client. The
        client may only ask; every bound below is checked here.
      * An emptied platform cancels the countdown rather than launching nobody.
      * Launch happens exactly once per departure. The state is consumed on
        launch so a duplicated remote or a retried tick cannot send a party
        twice.
]]

local LobbyDeparture = {}

export type State = {
    partySize: number,
    countdownEndsAt: number,
    launchedAt: number,
}

export type Snapshot = {
    partySize: number,
    counting: boolean,
    secondsRemaining: number,
}

local COUNTDOWN_SECONDS = 10
local MIN_PARTY_SIZE = 1

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function wholeAtLeast(value: any, minimum: number): boolean
    return finite(value) and value >= minimum and value == math.floor(value)
end

function LobbyDeparture.countdownSeconds(): number
    return COUNTDOWN_SECONDS
end

function LobbyDeparture.create(): State
    return { partySize = 0, countdownEndsAt = 0, launchedAt = 0 }
end

function LobbyDeparture.normalize(value: any): State
    if
        type(value) ~= "table"
        or not finite(value.partySize)
        or not finite(value.countdownEndsAt)
        or not finite(value.launchedAt)
        or value.partySize < 0
        or value.countdownEndsAt < 0
        or value.launchedAt < 0
    then
        return LobbyDeparture.create()
    end
    return {
        partySize = math.floor(value.partySize),
        countdownEndsAt = value.countdownEndsAt,
        launchedAt = value.launchedAt,
    }
end

--[[
    Ask to start a departure for `size` players.

    `readyCount` is how many players are standing on the platform right now.
    Requiring at least one means the button cannot start a countdown for an
    empty platform, and `maxPartySize` is supplied by the caller so the bound
    stays with Config rather than being duplicated here.
]]
function LobbyDeparture.requestDeparture(
    state: State,
    size: any,
    now: number,
    readyCount: any,
    maxPartySize: any
): (State, any)
    local current = LobbyDeparture.normalize(state)
    if not finite(now) or now < 0 then
        return current, { accepted = false, reason = "invalid_time" }
    end
    if not wholeAtLeast(maxPartySize, MIN_PARTY_SIZE) then
        return current, { accepted = false, reason = "invalid_capacity" }
    end
    if not wholeAtLeast(readyCount, 0) then
        return current, { accepted = false, reason = "invalid_ready_count" }
    end
    if not wholeAtLeast(size, MIN_PARTY_SIZE) or size > maxPartySize then
        return current, { accepted = false, reason = "invalid_party_size" }
    end
    if readyCount < 1 then
        return current, { accepted = false, reason = "platform_empty" }
    end
    if current.countdownEndsAt > now then
        return current, { accepted = false, reason = "already_counting" }
    end

    return {
        partySize = size,
        countdownEndsAt = now + COUNTDOWN_SECONDS,
        launchedAt = 0,
    }, {
        accepted = true,
        partySize = size,
        secondsRemaining = COUNTDOWN_SECONDS,
    }
end

--[[
    Advance the countdown.

    Returns `launch = true` exactly once, on the first tick at or after the
    deadline, and only while someone is still standing on the platform. The
    returned `capacity` is how many of those players may board.
]]
function LobbyDeparture.tick(state: State, now: number, readyCount: any): (State, any)
    local current = LobbyDeparture.normalize(state)
    if not finite(now) or not wholeAtLeast(readyCount, 0) then
        return current, { launch = false, reason = "invalid_tick" }
    end
    if current.countdownEndsAt <= 0 then
        return current, { launch = false, reason = "idle" }
    end
    if readyCount < 1 then
        -- Everyone stepped off. Cancel rather than launch an empty party.
        return LobbyDeparture.create(), { launch = false, reason = "platform_emptied" }
    end
    if now < current.countdownEndsAt then
        return current, { launch = false, reason = "counting" }
    end

    return { partySize = 0, countdownEndsAt = 0, launchedAt = now }, {
        launch = true,
        capacity = math.min(current.partySize, readyCount),
        partySize = current.partySize,
    }
end

function LobbyDeparture.cancel(state: State): State
    local _ = LobbyDeparture.normalize(state)
    return LobbyDeparture.create()
end

function LobbyDeparture.snapshot(state: State, now: number): Snapshot
    local current = LobbyDeparture.normalize(state)
    if not finite(now) or current.countdownEndsAt <= now then
        return { partySize = current.partySize, counting = false, secondsRemaining = 0 }
    end
    return {
        partySize = current.partySize,
        counting = true,
        secondsRemaining = math.max(0, math.ceil(current.countdownEndsAt - now)),
    }
end

return table.freeze(LobbyDeparture)
