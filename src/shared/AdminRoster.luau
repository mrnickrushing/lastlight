--!strict

--[[
    Who may run admin commands, and what a command is allowed to say.

    Pure logic: no players, no services, no chat. It answers two questions --
    is this user an admin, and is this text a command they may run with these
    arguments -- so both can be tested and neither can be decided by a client.

    The rules:

      * Membership is by Roblox user ID, never by name. Display names and
        usernames can change; the numeric ID a player joins with cannot be
        chosen by them.
      * Every argument is bounded here. A command cannot set night nine
        thousand or grant a million heartwood, because the range lives with
        the parser rather than with whoever wired the handler.
      * An unknown command, a bad argument, or a non-admin all produce the
        same outcome: refused. Nothing partially applies.
      * These commands exist to make testing possible, not to hand out power.
        Everything they do, the game already does on its own schedule.
]]

local AdminRoster = {}

export type Command = {
    name: string,
    value: number?,
    text: string?,
}

-- Nick (owner) and zacksigma472.
local ADMIN_USER_IDS = table.freeze({
    [1213625298] = true,
    [8772161919] = true,
})

local PHASES = table.freeze({ day = true, dusk = true, night = true })

-- Where /go can send an admin. Both directions exist so a tester can reach
-- the expedition without playing to the reveal, and get back out without
-- having to reach the Wayhome gate.
local DESTINATIONS = table.freeze({
    town = true,
    bramblewake = true,
})

-- Every numeric command carries its own bounds so a handler cannot be handed
-- a value the game was never designed to hold.
local NUMERIC_LIMITS: { [string]: { low: number, high: number } } = {
    night = { low = 1, high = 60 },
    give = { low = 0, high = 99 },
}

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function AdminRoster.isAdmin(userId: any): boolean
    return finite(userId) and ADMIN_USER_IDS[userId] == true
end

function AdminRoster.adminUserIds(): { number }
    local ids = {}
    for userId in ADMIN_USER_IDS do
        table.insert(ids, userId)
    end
    table.sort(ids)
    return ids
end

function AdminRoster.commandNames(): { string }
    return { "night", "give", "heal", "phase", "where", "go" }
end

--[[
    Parse a chat line into a command.

    Returns nil for anything that is not an admin command, including ordinary
    chat that happens to start with a slash, so the caller can ignore it
    silently rather than answering every message a player types.
]]
function AdminRoster.parse(message: any): Command?
    if type(message) ~= "string" then
        return nil
    end
    local body = string.match(message, "^%s*/(%S+)%s*(.*)$")
    local rest = string.match(message, "^%s*/%S+%s*(.*)$")
    if body == nil then
        return nil
    end
    local name = string.lower(body)
    local known = false
    for _, candidate in AdminRoster.commandNames() do
        if candidate == name then
            known = true
            break
        end
    end
    if not known then
        return nil
    end
    local argument = if type(rest) == "string" then string.match(rest, "^%s*(%S*)") else nil
    return {
        name = name,
        value = if argument ~= nil then tonumber(argument) else nil,
        text = if argument ~= nil and #argument > 0 then string.lower(argument) else nil,
    }
end

--[[
    Decide whether this user may run this line, and with what argument.

    `enabled` is the feature flag. A disabled admin system refuses everyone,
    including the roster, so turning the flag off is a complete off switch
    rather than a suggestion.
]]
function AdminRoster.authorize(userId: any, message: any, enabled: boolean): any
    local command = AdminRoster.parse(message)
    if command == nil then
        return { allowed = false, reason = "not_a_command" }
    end
    if not enabled then
        return { allowed = false, reason = "admin_disabled" }
    end
    if not AdminRoster.isAdmin(userId) then
        return { allowed = false, reason = "not_an_admin" }
    end

    local limits = NUMERIC_LIMITS[command.name]
    if limits ~= nil then
        local value = command.value
        if
            not finite(value)
            or value ~= math.floor(value :: number)
            or (value :: number) < limits.low
            or (value :: number) > limits.high
        then
            return {
                allowed = false,
                reason = "out_of_range",
                command = command.name,
                low = limits.low,
                high = limits.high,
            }
        end
        return { allowed = true, command = command.name, value = value }
    end

    if command.name == "go" then
        if command.text == nil or DESTINATIONS[command.text] ~= true then
            return { allowed = false, reason = "unknown_destination", command = command.name }
        end
        return { allowed = true, command = command.name, text = command.text }
    end

    if command.name == "phase" then
        if command.text == nil or PHASES[command.text] ~= true then
            return { allowed = false, reason = "unknown_phase", command = command.name }
        end
        return { allowed = true, command = command.name, text = command.text }
    end

    return { allowed = true, command = command.name }
end

return table.freeze(AdminRoster)
