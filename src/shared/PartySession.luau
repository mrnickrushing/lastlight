--!strict

--[[
    A party is a named thing, and until now it was not one.

    What the game has had since the lodge shipped is a platform: whoever is
    standing on it when the countdown reaches zero boards, in whatever order
    `Players:GetPlayers()` happened to return them, up to the size somebody
    tapped. That is a party in the sense that several people left at once. It
    is not a party in any sense that survives anything -- not a bystander who
    wandered onto the dais and took the fourth seat, and certainly not a
    disconnect, because a run server is reserved and a player who drops out of
    one has no way to name the world their friends are still in.

    So this module gives a departure an identity and a roster, and then gives
    each member a ticket back to it.

    Pure logic: no players, no TeleportService, no clock of its own. The
    service layer owns who is physically present and what a user ID belongs
    to; every rule about who may join, who boards first, and whether a
    returning player may be sent back lives here so it can be tested without a
    live game -- which matters more than usual, because reserved-server
    teleports cannot be exercised in Studio at all.

    The rules:

      * **Membership is by invitation and acceptance, both.** An invite alone
        does not put anyone in a party. This is the difference between a party
        and the set of people standing near you, and it is also what makes a
        block meaningful later: there is a moment where somebody says yes.
      * **A party boards ahead of bystanders.** Capacity is spent on members
        first, in roster order, and only then on whoever else is standing
        there. A party of three that chose four seats can still pick up a
        stranger; a party of four never loses a seat to one.
      * **A leader who leaves hands over.** Dissolving a party because one
        person stepped away punishes everyone else for it. The longest-
        standing remaining member takes it, and only the last member out
        dissolves anything.
      * **The ticket the server holds and the fact the client sees are
        different objects.** The ticket carries a reserved-server access code,
        which is the whole key to a private world; the client is told only
        that a rejoin is available and how big the party was. `publicTicket`
        exists so that split is a function rather than a habit.
      * **A stale ticket returns you to the lodge rather than into an empty
        world.** Reserved servers outlive their parties; a code that still
        resolves an hour after everybody left teleports a player alone into a
        world with no one in it, which is a worse answer than the lobby.
]]

local PartySession = {}

export type Member = {
    userId: number,
    joinedAt: number,
}

export type Invite = {
    toUserId: number,
    fromUserId: number,
    expiresAt: number,
}

export type State = {
    partyId: string,
    leaderUserId: number,
    members: { Member },
    invites: { Invite },
    departedAt: number,
}

export type Ticket = {
    partyId: string,
    accessCode: string,
    partySize: number,
    issuedAt: number,
    expiresAt: number,
}

-- An invite that nobody answers should stop being an offer. Long enough to
-- notice a toast and reach the button, short enough that a party formed
-- twenty minutes ago is not still holding a seat open for somebody who walked
-- away.
local INVITE_SECONDS = 45

--[[
    How long a rejoin ticket is worth trying.

    A run is not short, and a player who drops on a phone may take several
    minutes to get back, so this is generous. It is not unbounded because the
    failure mode at the far end is the bad one: a reserved server that has
    emptied out still accepts a teleport, and arriving alone in the world your
    party left an hour ago reads as the game breaking rather than as a rejoin.
]]
local REJOIN_SECONDS = 5400

local MAX_ACCESS_CODE_LENGTH = 128
local MAX_PARTY_ID_LENGTH = 64

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function wholeAtLeast(value: any, minimum: number): boolean
    return finite(value) and value >= minimum and value == math.floor(value)
end

local function isUserId(value: any): boolean
    return wholeAtLeast(value, 1)
end

function PartySession.inviteSeconds(): number
    return INVITE_SECONDS
end

function PartySession.rejoinSeconds(): number
    return REJOIN_SECONDS
end

--[[
    Start a party with one member, its leader.

    The ID is derived rather than random so the module stays pure and its
    tests stay readable. A leader can hold only one party at a time, so the
    only way to collide is for the same person to form two parties inside the
    same second, which the service layer refuses on its own by looking them up
    before creating.
]]
function PartySession.create(leaderUserId: any, now: any): (State?, any)
    if not isUserId(leaderUserId) then
        return nil, { accepted = false, reason = "invalid_leader" }
    end
    if not finite(now) or now < 0 then
        return nil, { accepted = false, reason = "invalid_time" }
    end
    return {
        partyId = string.format("party_%d_%d", leaderUserId, math.floor(now)),
        leaderUserId = leaderUserId,
        members = { { userId = leaderUserId, joinedAt = now } },
        invites = {},
        departedAt = 0,
    }, { accepted = true }
end

--[[
    The party a departure forms out of whoever actually boarded.

    This is the one path into a roster that does not go through an invitation,
    and it is not a back door: standing on the dais while the countdown runs
    out is the older and more physical form of the same consent, and it is the
    one the game shipped with. What the invitation system decides is who
    boards *first* and who gets asked at all -- not who is allowed to travel.

    It matters that the travelling party is the boarding list rather than the
    party formed at the lodge, because those can differ: a party of three that
    chose four seats picks up a stranger, and the stranger is in that world
    with them. A rejoin ticket has to name the world's population, not the
    friendship group's, or the stranger has no way home.
]]
function PartySession.createForDeparture(userIds: any, now: any): (State?, any)
    if type(userIds) ~= "table" then
        return nil, { accepted = false, reason = "invalid_roster" }
    end
    if not finite(now) or now < 0 then
        return nil, { accepted = false, reason = "invalid_time" }
    end

    local members: { Member } = {}
    local seen: { [number]: boolean } = {}
    for _, userId in userIds do
        if isUserId(userId) and not seen[userId] then
            seen[userId] = true
            table.insert(members, { userId = userId, joinedAt = now })
        end
    end
    if #members == 0 then
        return nil, { accepted = false, reason = "empty_roster" }
    end

    return {
        partyId = string.format("party_%d_%d", members[1].userId, math.floor(now)),
        leaderUserId = members[1].userId,
        members = members,
        invites = {},
        departedAt = 0,
    }, { accepted = true, size = #members }
end

--[[
    Bound whatever a caller hands in.

    Party state never leaves the server and is never persisted, so this is not
    guarding against a forged save -- it is guarding against a service passing
    a table it built itself and got slightly wrong, which is the failure this
    codebase has actually had. A state that cannot be read is empty, and an
    empty party admits nobody.
]]
function PartySession.normalize(value: any): State?
    if type(value) ~= "table" then
        return nil
    end
    if type(value.partyId) ~= "string" or #value.partyId == 0 then
        return nil
    end
    if not isUserId(value.leaderUserId) then
        return nil
    end
    if type(value.members) ~= "table" then
        return nil
    end

    local members: { Member } = {}
    local seen: { [number]: boolean } = {}
    for _, member in value.members do
        if
            type(member) == "table"
            and isUserId(member.userId)
            and finite(member.joinedAt)
            and not seen[member.userId]
        then
            seen[member.userId] = true
            table.insert(members, { userId = member.userId, joinedAt = member.joinedAt })
        end
    end
    if not seen[value.leaderUserId] then
        return nil
    end

    local invites: { Invite } = {}
    if type(value.invites) == "table" then
        local invited: { [number]: boolean } = {}
        for _, invite in value.invites do
            if
                type(invite) == "table"
                and isUserId(invite.toUserId)
                and isUserId(invite.fromUserId)
                and finite(invite.expiresAt)
                and not invited[invite.toUserId]
                and not seen[invite.toUserId]
            then
                invited[invite.toUserId] = true
                table.insert(invites, {
                    toUserId = invite.toUserId,
                    fromUserId = invite.fromUserId,
                    expiresAt = invite.expiresAt,
                })
            end
        end
    end

    return {
        partyId = value.partyId,
        leaderUserId = value.leaderUserId,
        members = members,
        invites = invites,
        departedAt = if finite(value.departedAt) and value.departedAt > 0
            then value.departedAt
            else 0,
    }
end

function PartySession.isMember(state: any, userId: any): boolean
    local current = PartySession.normalize(state)
    if current == nil or not isUserId(userId) then
        return false
    end
    for _, member in current.members do
        if member.userId == userId then
            return true
        end
    end
    return false
end

function PartySession.size(state: any): number
    local current = PartySession.normalize(state)
    return if current == nil then 0 else #current.members
end

-- Roster order, leader first. This is the order capacity is spent in, so it
-- is deliberately not the order people happened to accept in: whoever formed
-- the party is the one person guaranteed a seat on it.
function PartySession.memberIds(state: any): { number }
    local current = PartySession.normalize(state)
    if current == nil then
        return {}
    end
    local ids = { current.leaderUserId }
    for _, member in current.members do
        if member.userId ~= current.leaderUserId then
            table.insert(ids, member.userId)
        end
    end
    return ids
end

function PartySession.pendingInvite(state: any, userId: any, now: any): Invite?
    local current = PartySession.normalize(state)
    if current == nil or not isUserId(userId) or not finite(now) then
        return nil
    end
    for _, invite in current.invites do
        if invite.toUserId == userId and invite.expiresAt > now then
            return invite
        end
    end
    return nil
end

local function withoutInvite(invites: { Invite }, userId: number, now: number): { Invite }
    local kept: { Invite } = {}
    for _, invite in invites do
        -- Expired invites are swept here rather than by a timer. Nothing else
        -- needs a tick, and an offer that has run out is indistinguishable
        -- from one that was never made.
        if invite.toUserId ~= userId and invite.expiresAt > now then
            table.insert(kept, invite)
        end
    end
    return kept
end

--[[
    Offer a seat to somebody.

    Any member may invite, not only the leader: a party at a departure
    platform is a group of people standing together, and making three of them
    route every introduction through a fourth is ceremony the situation does
    not have. What only the leader can do is nothing, which is the point --
    leadership here decides boarding order and nothing else.

    A full party refuses rather than queueing. Invites deliberately do not
    reserve seats, so two people accepting the last one is resolved at accept
    time by whoever gets there first, and the loser is told the party is full
    rather than being silently dropped.
]]
function PartySession.invite(
    state: any,
    fromUserId: any,
    toUserId: any,
    now: any,
    maxSize: any
): (State?, any)
    local current = PartySession.normalize(state)
    if current == nil then
        return nil, { accepted = false, reason = "no_party" }
    end
    if not finite(now) or now < 0 then
        return current, { accepted = false, reason = "invalid_time" }
    end
    if not wholeAtLeast(maxSize, 1) then
        return current, { accepted = false, reason = "invalid_capacity" }
    end
    if not isUserId(toUserId) then
        return current, { accepted = false, reason = "invalid_target" }
    end
    if not PartySession.isMember(current, fromUserId) then
        return current, { accepted = false, reason = "not_a_member" }
    end
    if current.departedAt > 0 then
        return current, { accepted = false, reason = "already_departed" }
    end
    if PartySession.isMember(current, toUserId) then
        return current, { accepted = false, reason = "already_a_member" }
    end
    if #current.members >= maxSize then
        return current, { accepted = false, reason = "party_full" }
    end

    local invites = withoutInvite(current.invites, toUserId, now)
    table.insert(invites, {
        toUserId = toUserId,
        fromUserId = fromUserId,
        expiresAt = now + INVITE_SECONDS,
    })
    return {
        partyId = current.partyId,
        leaderUserId = current.leaderUserId,
        members = current.members,
        invites = invites,
        departedAt = current.departedAt,
    }, { accepted = true, expiresAt = now + INVITE_SECONDS }
end

function PartySession.accept(state: any, userId: any, now: any, maxSize: any): (State?, any)
    local current = PartySession.normalize(state)
    if current == nil then
        return nil, { accepted = false, reason = "no_party" }
    end
    if not finite(now) or now < 0 then
        return current, { accepted = false, reason = "invalid_time" }
    end
    if not wholeAtLeast(maxSize, 1) then
        return current, { accepted = false, reason = "invalid_capacity" }
    end
    if PartySession.pendingInvite(current, userId, now) == nil then
        return current, { accepted = false, reason = "no_invite" }
    end
    if current.departedAt > 0 then
        return current, { accepted = false, reason = "already_departed" }
    end
    if #current.members >= maxSize then
        return current, { accepted = false, reason = "party_full" }
    end

    local members = table.clone(current.members)
    table.insert(members, { userId = userId, joinedAt = now })
    return {
        partyId = current.partyId,
        leaderUserId = current.leaderUserId,
        members = members,
        invites = withoutInvite(current.invites, userId, now),
        departedAt = current.departedAt,
    }, { accepted = true, size = #members }
end

function PartySession.decline(state: any, userId: any, now: any): (State?, any)
    local current = PartySession.normalize(state)
    if current == nil then
        return nil, { accepted = false, reason = "no_party" }
    end
    if not finite(now) or not isUserId(userId) then
        return current, { accepted = false, reason = "invalid_time" }
    end
    if PartySession.pendingInvite(current, userId, now) == nil then
        return current, { accepted = false, reason = "no_invite" }
    end
    return {
        partyId = current.partyId,
        leaderUserId = current.leaderUserId,
        members = current.members,
        invites = withoutInvite(current.invites, userId, now),
        departedAt = current.departedAt,
    }, { accepted = true }
end

--[[
    Leave, including as the leader.

    Handover goes to the longest-standing remaining member rather than to
    whoever is alphabetically first or last to arrive, because the party's own
    history is the only ordering that means anything: the person who has been
    in it longest is the one most likely to know what it was formed to do.

    The last member out dissolves the party, and `dissolved` says so, so the
    service can drop it rather than keeping an empty roster that would gladly
    accept an invite.
]]
function PartySession.leave(state: any, userId: any, now: any): (State?, any)
    local current = PartySession.normalize(state)
    if current == nil then
        return nil, { accepted = false, reason = "no_party" }
    end
    if not finite(now) then
        return current, { accepted = false, reason = "invalid_time" }
    end
    if not PartySession.isMember(current, userId) then
        return current, { accepted = false, reason = "not_a_member" }
    end

    local members: { Member } = {}
    for _, member in current.members do
        if member.userId ~= userId then
            table.insert(members, member)
        end
    end
    if #members == 0 then
        return nil, { accepted = true, dissolved = true }
    end

    local leaderUserId = current.leaderUserId
    local handedTo: number? = nil
    if leaderUserId == userId then
        local longest = members[1]
        for _, member in members do
            if member.joinedAt < longest.joinedAt then
                longest = member
            end
        end
        leaderUserId = longest.userId
        handedTo = leaderUserId
    end

    return {
        partyId = current.partyId,
        leaderUserId = leaderUserId,
        members = members,
        invites = withoutInvite(current.invites, if isUserId(userId) then userId else 0, now),
        departedAt = current.departedAt,
    }, { accepted = true, dissolved = false, handedTo = handedTo }
end

--[[
    Seal a party at the moment it leaves.

    A departed party stops taking invitations for the obvious reason -- there
    is no longer any way to reach it from the lodge -- but the roster stays
    intact, because that is what the rejoin tickets are checked against.
]]
function PartySession.depart(state: any, now: any): (State?, any)
    local current = PartySession.normalize(state)
    if current == nil then
        return nil, { accepted = false, reason = "no_party" }
    end
    if not finite(now) or now < 0 then
        return current, { accepted = false, reason = "invalid_time" }
    end
    if current.departedAt > 0 then
        return current, { accepted = false, reason = "already_departed" }
    end
    return {
        partyId = current.partyId,
        leaderUserId = current.leaderUserId,
        members = current.members,
        invites = {},
        departedAt = now,
    }, { accepted = true }
end

--[[
    Who boards, in what order, out of everyone standing on the platform.

    `candidates` is the service's own reading of the dais, in whatever order
    it found them; `capacity` is what the chosen party size allows. Members go
    first in roster order, then everyone else in the order given. Nobody who
    is not standing there is ever returned, whatever the roster says: the
    platform is still the authority on presence, and this only re-orders what
    it reports.
]]
function PartySession.boardingOrder(state: any, candidates: any, capacity: any): { number }
    local ordered: { number } = {}
    if type(candidates) ~= "table" or not wholeAtLeast(capacity, 0) then
        return ordered
    end

    local present: { [number]: boolean } = {}
    for _, userId in candidates do
        if isUserId(userId) then
            present[userId] = true
        end
    end

    local taken: { [number]: boolean } = {}
    for _, userId in PartySession.memberIds(state) do
        if present[userId] and not taken[userId] and #ordered < capacity then
            taken[userId] = true
            table.insert(ordered, userId)
        end
    end
    for _, userId in candidates do
        if isUserId(userId) and not taken[userId] and #ordered < capacity then
            taken[userId] = true
            table.insert(ordered, userId)
        end
    end
    return ordered
end

--[[
    The ticket a member carries home.

    `accessCode` is a reserved-server access code: the entire key to a private
    world. It is written to the profile, which is server-owned storage, and it
    must never reach a client -- see `publicTicket`, which is the shape that
    may. Issuing one for a non-member is refused rather than clamped, because
    a ticket handed to the wrong person is a door into somebody else's run.
]]
function PartySession.issueTicket(
    state: any,
    userId: any,
    accessCode: any,
    now: any
): (Ticket?, any)
    local current = PartySession.normalize(state)
    if current == nil then
        return nil, { accepted = false, reason = "no_party" }
    end
    if not PartySession.isMember(current, userId) then
        return nil, { accepted = false, reason = "not_a_member" }
    end
    if type(accessCode) ~= "string" or #accessCode == 0 or #accessCode > MAX_ACCESS_CODE_LENGTH then
        return nil, { accepted = false, reason = "invalid_access_code" }
    end
    if not finite(now) or now < 0 then
        return nil, { accepted = false, reason = "invalid_time" }
    end
    return {
        partyId = current.partyId,
        accessCode = accessCode,
        partySize = #current.members,
        issuedAt = now,
        expiresAt = now + REJOIN_SECONDS,
    }, { accepted = true }
end

--[[
    Bound a ticket read back off a save.

    This one IS guarding against a forged profile, unlike `normalize` above:
    the ticket persists, so it comes back through the same door every other
    saved field does. Anything malformed is no ticket at all, which lands the
    player in the lodge -- the same safe direction `RunHandoff` takes with an
    unreadable teleport payload, and for the same reason.
]]
function PartySession.normalizeTicket(value: any): Ticket?
    if type(value) ~= "table" then
        return nil
    end
    if
        type(value.partyId) ~= "string"
        or #value.partyId == 0
        or #value.partyId > MAX_PARTY_ID_LENGTH
    then
        return nil
    end
    if
        type(value.accessCode) ~= "string"
        or #value.accessCode == 0
        or #value.accessCode > MAX_ACCESS_CODE_LENGTH
    then
        return nil
    end
    if not finite(value.issuedAt) or value.issuedAt < 0 then
        return nil
    end
    if not finite(value.expiresAt) or value.expiresAt <= value.issuedAt then
        return nil
    end
    return {
        partyId = value.partyId,
        accessCode = value.accessCode,
        partySize = if wholeAtLeast(value.partySize, 1) then value.partySize else 1,
        issuedAt = value.issuedAt,
        expiresAt = value.expiresAt,
    }
end

--[[
    Whether a returning player may be sent back, and where.

    `currentPartyId` is the party this server already belongs to, if any: a
    run server adopts its identity from the teleport payload, so a member
    landing back in the world their ticket names has arrived rather than
    needing to be sent, and forwarding them again would be a loop.
]]
function PartySession.readTicket(ticket: any, now: any, currentPartyId: any): any
    local bounded = PartySession.normalizeTicket(ticket)
    if bounded == nil then
        return { rejoin = false, reason = "no_ticket" }
    end
    if not finite(now) then
        return { rejoin = false, reason = "invalid_time" }
    end
    if bounded.expiresAt <= now then
        return { rejoin = false, reason = "expired" }
    end
    if type(currentPartyId) == "string" and currentPartyId == bounded.partyId then
        return { rejoin = false, reason = "already_here" }
    end
    return {
        rejoin = true,
        partyId = bounded.partyId,
        accessCode = bounded.accessCode,
        partySize = bounded.partySize,
    }
end

--[[
    The half of a ticket a client may be told.

    Everything here is presentation: that a rejoin is on offer, how many
    people were in the party, how long the offer lasts. The access code is
    absent by construction rather than by remembering to omit it, which is the
    only version of that rule that survives somebody adding a field later.
]]
function PartySession.publicTicket(ticket: any, now: any, currentPartyId: any): any?
    local read = PartySession.readTicket(ticket, now, currentPartyId)
    if not read.rejoin then
        return nil
    end
    local bounded = PartySession.normalizeTicket(ticket) :: Ticket
    return {
        available = true,
        partySize = read.partySize,
        secondsRemaining = math.max(0, math.floor(bounded.expiresAt - now)),
    }
end

return table.freeze(PartySession)
