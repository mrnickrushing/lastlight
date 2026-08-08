--!strict

--[[
    What a player is allowed to say to another player, and where it lands.

    This is a closed vocabulary rather than a chat box, and that is the whole
    design. Free text in a game with a young audience means a moderation
    pipeline, a filter, an appeal path and a human reading reports; a fixed
    list of twenty-four phrases means moderation is structural -- there is no
    string a player can compose, so there is nothing to moderate. The safety
    review in Milestone 11 reads that as a property of the code rather than as
    a promise about it.

    A phrase does two things at once. It says something, and it marks a place:
    **the sender's own position, resolved by the server**. The payload that
    carries a phrase carries a phrase id and nothing else -- no vector, no
    target, no name -- which is both the one-extra-field contract every action
    here obeys and the reason a ping cannot be forged into marking somewhere
    the sender is not standing. #219 is the reason that rule is a wall: the
    departure press quietly grew a second field and every real press was
    dropped for months.

    Courtesy is the exception, and deliberately: a thank-you is speech, and
    speech has no place in it. Those six phrases resolve to a ping kind that
    marks nothing, so they appear in the call log and never as a marker in the
    world. Six people being polite must not put six cards over the town.

    Presentation lives here too, as plain numbers, for the reason the census
    keeps teaching: a colour the client picks by name is a colour a new ping
    kind silently does not have. Everything the HUD needs to draw a ping comes
    off the catalog entry, so a phrase that exists is a phrase that can be
    drawn.
]]

export type PingKind = {
    id: string,
    label: string,
    glyph: string,
    seconds: number,
    marks: boolean,
    colour: { number },
}

export type Phrase = {
    id: string,
    category: string,
    text: string,
    ping: string,
}

export type Call = {
    id: string,
    phraseId: string,
    category: string,
    text: string,
    ping: string,
    fromUserId: number,
    fromName: string,
    at: number,
    expiresAt: number,
    marks: boolean,
    x: number?,
    y: number?,
    z: number?,
}

local QuickChat = {
    -- A phrase id is a catalog key, and the catalog is the only source of
    -- them. The bound is here so the transport can refuse a long string
    -- before anything looks it up.
    MaxPhraseIdLength = 32,
    -- How many calls the server keeps. Long enough that a player who looked
    -- away sees what was said, short enough that a log is not a chat history.
    LogLength = 6,
}

local PING_KINDS: { PingKind } = {
    {
        id = "danger",
        label = "DANGER",
        glyph = "▲",
        seconds = 8,
        marks = true,
        colour = { 214, 88, 72 },
    },
    {
        id = "aid",
        label = "AID",
        glyph = "✚",
        -- The longest life of any marker. A player asking for help is asking
        -- for a walk, and a walk across a module takes longer than a callout
        -- is worth remembering.
        seconds = 20,
        marks = true,
        colour = { 255, 186, 92 },
    },
    {
        id = "move",
        label = "MOVE",
        glyph = "➤",
        seconds = 6,
        marks = true,
        colour = { 146, 206, 142 },
    },
    {
        id = "hold",
        label = "HOLD",
        glyph = "■",
        seconds = 12,
        marks = true,
        colour = { 168, 190, 200 },
    },
    {
        id = "found",
        label = "FOUND",
        glyph = "◆",
        -- A node does not walk away, so the marker on it outlives every other
        -- kind. This is the one a party actually navigates by.
        seconds = 30,
        marks = true,
        colour = { 226, 198, 128 },
    },
    {
        id = "reply",
        label = "REPLY",
        glyph = "·",
        -- Spoken, not placed. Zero seconds is not a marker that vanishes
        -- instantly; marks = false means one is never built at all.
        seconds = 6,
        marks = false,
        colour = { 200, 208, 202 },
    },
}

local CATEGORIES = {
    { id = "danger", label = "DANGER" },
    { id = "direction", label = "DIRECTION" },
    { id = "need", label = "NEED" },
    { id = "courtesy", label = "COURTESY" },
}

--[[
    Twenty-four phrases, six per category, written to be useful on a night
    rather than to be a greeting card. Every one of them is something this
    game actually asks a party to say: the lantern is the shared clock, being
    downed is the loudest thing that happens to anybody, and a harvest node
    somebody else found is the difference between banking a pouch and not.
]]
local PHRASES: { Phrase } = {
    { id = "qc_enemy_here", category = "danger", text = "ENEMY HERE", ping = "danger" },
    { id = "qc_something_big", category = "danger", text = "SOMETHING BIG", ping = "danger" },
    {
        id = "qc_lantern_failing",
        category = "danger",
        text = "THE LANTERN IS FAILING",
        ping = "danger",
    },
    { id = "qc_i_am_down", category = "danger", text = "I AM DOWN", ping = "aid" },
    { id = "qc_fall_back", category = "danger", text = "FALL BACK", ping = "danger" },
    { id = "qc_watch_the_dark", category = "danger", text = "WATCH THE DARK", ping = "danger" },

    { id = "qc_going_here", category = "direction", text = "GOING HERE", ping = "move" },
    { id = "qc_this_way", category = "direction", text = "THIS WAY", ping = "move" },
    { id = "qc_holding_here", category = "direction", text = "HOLDING HERE", ping = "hold" },
    { id = "qc_wait_for_me", category = "direction", text = "WAIT FOR ME", ping = "hold" },
    {
        id = "qc_for_the_gate",
        category = "direction",
        text = "HEADING FOR THE GATE",
        ping = "move",
    },
    { id = "qc_splitting_off", category = "direction", text = "SPLITTING OFF", ping = "move" },

    { id = "qc_need_help", category = "need", text = "NEED HELP", ping = "aid" },
    { id = "qc_need_rootfire", category = "need", text = "NEED ROOTFIRE", ping = "aid" },
    { id = "qc_short_materials", category = "need", text = "SHORT ON MATERIALS", ping = "aid" },
    { id = "qc_harvest_here", category = "need", text = "HARVEST HERE", ping = "found" },
    { id = "qc_memory_here", category = "need", text = "A MEMORY HERE", ping = "found" },
    { id = "qc_event_here", category = "need", text = "SOMETHING HAPPENING HERE", ping = "found" },

    { id = "qc_yes", category = "courtesy", text = "YES", ping = "reply" },
    { id = "qc_no", category = "courtesy", text = "NO", ping = "reply" },
    { id = "qc_ready", category = "courtesy", text = "READY", ping = "reply" },
    { id = "qc_thank_you", category = "courtesy", text = "THANK YOU", ping = "reply" },
    { id = "qc_my_mistake", category = "courtesy", text = "MY MISTAKE", ping = "reply" },
    { id = "qc_well_done", category = "courtesy", text = "WELL DONE", ping = "reply" },
}

local pingById: { [string]: PingKind } = {}
for _, kind in PING_KINDS do
    assert(pingById[kind.id] == nil, "duplicate quick chat ping kind: " .. kind.id)
    pingById[kind.id] = table.freeze(kind)
end

local categoryById: { [string]: { id: string, label: string } } = {}
for _, category in CATEGORIES do
    assert(categoryById[category.id] == nil, "duplicate quick chat category: " .. category.id)
    categoryById[category.id] = table.freeze(category)
end

local phraseById: { [string]: Phrase } = {}
local phrasesByCategory: { [string]: { Phrase } } = {}
for _, phrase in PHRASES do
    assert(phraseById[phrase.id] == nil, "duplicate quick chat phrase: " .. phrase.id)
    assert(
        categoryById[phrase.category] ~= nil,
        string.format("quick chat phrase %s names no category", phrase.id)
    )
    assert(
        pingById[phrase.ping] ~= nil,
        string.format("quick chat phrase %s names no ping kind", phrase.id)
    )
    assert(
        #phrase.id <= QuickChat.MaxPhraseIdLength,
        string.format("quick chat phrase id %s is longer than the transport allows", phrase.id)
    )
    phraseById[phrase.id] = table.freeze(phrase)
    local bucket = phrasesByCategory[phrase.category]
    if bucket == nil then
        bucket = {}
        phrasesByCategory[phrase.category] = bucket
    end
    table.insert(bucket, phraseById[phrase.id])
end
for _, bucket in phrasesByCategory do
    table.freeze(bucket)
end

--[[
    The wheel the client draws, as data.

    The equip panel shipped as a hardcoded list of eight items and left ninety
    craftable items unwearable with every spec green (#299). A phrase wheel is
    the same shape: a hand-written list of buttons beside a catalog is a
    catalog with entries nobody can reach. So the layout is derived here and
    the spec can assert that walking it visits every phrase exactly once.
]]
function QuickChat.wheel(): { { category: string, label: string, phrases: { Phrase } } }
    local wheel = {}
    for _, category in CATEGORIES do
        table.insert(wheel, {
            category = category.id,
            label = category.label,
            phrases = phrasesByCategory[category.id] or {},
        })
    end
    return wheel
end

function QuickChat.list(): { Phrase }
    return PHRASES
end

function QuickChat.categories(): { { id: string, label: string } }
    return CATEGORIES
end

function QuickChat.pingKinds(): { PingKind }
    return PING_KINDS
end

function QuickChat.byId(phraseId: any): Phrase?
    if type(phraseId) ~= "string" or #phraseId > QuickChat.MaxPhraseIdLength then
        return nil
    end
    return phraseById[phraseId]
end

function QuickChat.pingKind(kindId: any): PingKind?
    if type(kindId) ~= "string" then
        return nil
    end
    return pingById[kindId]
end

--[[
    Build the record of one thing said.

    Pure, and given the position rather than asking for it: the shared layer
    cannot hold a Vector3 (the Lune runner has no Roblox datatypes, and a
    first draft of CompanionMotion failed typecheck for exactly this), and
    more importantly the position must come from the server reading the
    sender's own character. A caller that has no position -- a player without
    a character, mid-respawn -- still gets a call; it simply marks nothing.
]]
function QuickChat.call(
    phrase: Phrase,
    fromUserId: number,
    fromName: string,
    now: number,
    sequence: number,
    x: number?,
    y: number?,
    z: number?
): Call
    local kind = assert(pingById[phrase.ping], "phrase names no ping kind")
    local placed = kind.marks and x ~= nil and y ~= nil and z ~= nil
    return table.freeze({
        id = string.format("call_%d", sequence),
        phraseId = phrase.id,
        category = phrase.category,
        text = phrase.text,
        ping = phrase.ping,
        fromUserId = fromUserId,
        fromName = fromName,
        at = now,
        expiresAt = now + kind.seconds,
        marks = placed,
        x = if placed then x else nil,
        y = if placed then y else nil,
        z = if placed then z else nil,
    })
end

--[[
    Who may see what was said, as a pure rule over a list of calls.

    Three things suppress a call and all three are checked here rather than at
    the four places a snapshot is built, because the door a rule is enforced
    at is the door it can be forgotten at:

      * it has expired;
      * the recipient has blocked the sender, which the caller answers through
        `isSuppressed` -- the platform's block list is the authority and it is
        asynchronous, so resolving it is the service's job and applying it is
        this one's;
      * for a marker, it is further away than a marker is useful. A ping is
        guidance, and guidance to somewhere four hundred studs off is noise on
        the screen. Distance is not applied to the log line: hearing that a
        party member is down is the point even when you cannot get there.

    A player always sees their own calls. Blocking yourself is not a thing,
    and a wheel press that appears to do nothing is a wheel press a player
    presses again.
]]
function QuickChat.visibleCalls(
    calls: { Call },
    recipientUserId: number,
    isSuppressed: (number) -> boolean,
    now: number
): { Call }
    local visible = {}
    for _, call in calls do
        if call.expiresAt > now then
            if call.fromUserId == recipientUserId or not isSuppressed(call.fromUserId) then
                table.insert(visible, call)
            end
        end
    end
    return visible
end

function QuickChat.visiblePings(
    calls: { Call },
    recipientUserId: number,
    isSuppressed: (number) -> boolean,
    now: number,
    originX: number?,
    originY: number?,
    originZ: number?,
    radius: number
): { Call }
    local visible = {}
    for _, call in QuickChat.visibleCalls(calls, recipientUserId, isSuppressed, now) do
        if call.marks and call.x ~= nil and call.y ~= nil and call.z ~= nil then
            local withinRange = true
            if originX ~= nil and originY ~= nil and originZ ~= nil then
                local dx = call.x - originX
                local dy = call.y - originY
                local dz = call.z - originZ
                withinRange = dx * dx + dy * dy + dz * dz <= radius * radius
            end
            if withinRange then
                table.insert(visible, call)
            end
        end
    end
    return visible
end

return table.freeze(QuickChat)
