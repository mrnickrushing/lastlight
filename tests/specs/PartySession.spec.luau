--!strict

local PartySession = require("../../src/shared/PartySession")
local TestRunner = require("../TestRunner")

local LEADER = 101
local SECOND = 202
local THIRD = 303
local STRANGER = 404

local function party(now: number): any
    local state = PartySession.create(LEADER, now)
    return state
end

-- A party of two, formed the ordinary way: invite, then accept.
local function partyOfTwo(now: number): any
    local state = party(now)
    state = PartySession.invite(state, LEADER, SECOND, now, 8)
    state = PartySession.accept(state, SECOND, now + 1, 8)
    return state
end

return {
    name = "PartySession",
    cases = {
        {
            name = "a new party is its leader and nobody else",
            run = function()
                local state, result = PartySession.create(LEADER, 500)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(PartySession.size(state), 1)
                TestRunner.equal(PartySession.isMember(state, LEADER), true)
                TestRunner.equal(PartySession.isMember(state, SECOND), false)
            end,
        },
        {
            name = "a party cannot be formed by nobody, or outside time",
            run = function()
                for _, userId in { 0, -1, 2.5, "101" } do
                    local state, result = PartySession.create(userId, 500)
                    TestRunner.equal(state, nil)
                    TestRunner.equal(result.reason, "invalid_leader")
                end
                local state, result = PartySession.create(LEADER, -1)
                TestRunner.equal(state, nil)
                TestRunner.equal(result.reason, "invalid_time")
            end,
        },
        {
            --[[
                The rule that makes a party a party rather than a proximity
                accident: an invitation on its own puts nobody anywhere.
            ]]
            name = "an invite alone puts nobody in the party",
            run = function()
                local state = PartySession.invite(party(500), LEADER, SECOND, 500, 8)
                TestRunner.equal(PartySession.size(state), 1)
                TestRunner.equal(PartySession.isMember(state, SECOND), false)
                TestRunner.truthy(PartySession.pendingInvite(state, SECOND, 500) ~= nil)
            end,
        },
        {
            name = "accepting an invitation joins; declining does not",
            run = function()
                local state = PartySession.invite(party(500), LEADER, SECOND, 500, 8)
                local joined, result = PartySession.accept(state, SECOND, 510, 8)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(PartySession.isMember(joined, SECOND), true)

                local declined, declineResult = PartySession.decline(state, SECOND, 510)
                TestRunner.equal(declineResult.accepted, true)
                TestRunner.equal(PartySession.isMember(declined, SECOND), false)
                TestRunner.equal(PartySession.pendingInvite(declined, SECOND, 510), nil)
            end,
        },
        {
            name = "an unanswered invitation stops being an offer",
            run = function()
                local state = PartySession.invite(party(500), LEADER, SECOND, 500, 8)
                local late = 500 + PartySession.inviteSeconds() + 1
                TestRunner.equal(PartySession.pendingInvite(state, SECOND, late), nil)
                local _, result = PartySession.accept(state, SECOND, late, 8)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "no_invite")
            end,
        },
        {
            name = "nobody joins a party they were never asked into",
            run = function()
                local _, result = PartySession.accept(party(500), STRANGER, 500, 8)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "no_invite")
            end,
        },
        {
            name = "only a member may invite",
            run = function()
                local _, result = PartySession.invite(party(500), STRANGER, SECOND, 500, 8)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "not_a_member")
            end,
        },
        {
            -- Any member, not only the leader: leadership decides boarding
            -- order here and nothing else.
            name = "a member who is not the leader may invite",
            run = function()
                local state = partyOfTwo(500)
                local invited, result = PartySession.invite(state, SECOND, THIRD, 502, 8)
                TestRunner.equal(result.accepted, true)
                TestRunner.truthy(PartySession.pendingInvite(invited, THIRD, 502) ~= nil)
            end,
        },
        {
            name = "a full party refuses both the invitation and the acceptance",
            run = function()
                local state = partyOfTwo(500)
                local _, inviteResult = PartySession.invite(state, LEADER, THIRD, 502, 2)
                TestRunner.equal(inviteResult.reason, "party_full")

                --[[
                    Invites deliberately do not reserve seats, so the race for
                    the last one is settled at accept time. The loser is told
                    the party is full rather than silently dropped, which is
                    the difference between a refusal and a bug.
                ]]
                local open = PartySession.invite(party(500), LEADER, SECOND, 500, 8)
                open = PartySession.invite(open, LEADER, THIRD, 500, 8)
                local first = PartySession.accept(open, SECOND, 501, 2)
                local _, secondResult = PartySession.accept(first, THIRD, 502, 2)
                TestRunner.equal(secondResult.accepted, false)
                TestRunner.equal(secondResult.reason, "party_full")
            end,
        },
        {
            name = "a member cannot be invited into the party they are in",
            run = function()
                local _, result = PartySession.invite(partyOfTwo(500), LEADER, SECOND, 502, 8)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "already_a_member")
            end,
        },
        {
            --[[
                Dissolving a party because one person stepped away punishes
                everyone else for it, so the leader hands over instead. The
                longest-standing remaining member takes it.
            ]]
            name = "a leader who leaves hands over rather than dissolving",
            run = function()
                local state = partyOfTwo(500)
                state = PartySession.invite(state, LEADER, THIRD, 502, 8)
                state = PartySession.accept(state, THIRD, 503, 8)

                local after, result = PartySession.leave(state, LEADER, 510)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(result.dissolved, false)
                TestRunner.equal(result.handedTo, SECOND)
                TestRunner.equal(PartySession.size(after), 2)
                TestRunner.equal(PartySession.memberIds(after)[1], SECOND)
            end,
        },
        {
            name = "the last member out dissolves the party",
            run = function()
                local after, result = PartySession.leave(party(500), LEADER, 510)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(result.dissolved, true)
                TestRunner.equal(after, nil)
            end,
        },
        {
            name = "somebody who is not in a party cannot leave it",
            run = function()
                local _, result = PartySession.leave(partyOfTwo(500), STRANGER, 510)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "not_a_member")
            end,
        },
        {
            name = "a departed party takes no more invitations",
            run = function()
                local state = PartySession.depart(partyOfTwo(500), 520)
                local _, inviteResult = PartySession.invite(state, LEADER, THIRD, 521, 8)
                TestRunner.equal(inviteResult.reason, "already_departed")
                local _, departResult = PartySession.depart(state, 522)
                TestRunner.equal(departResult.reason, "already_departed")
                -- The roster survives sealing, because that is what the
                -- rejoin tickets are checked against.
                TestRunner.equal(PartySession.size(state), 2)
            end,
        },
        {
            --[[
                The concrete change this whole wave makes to a departure: the
                platform used to spend its seats in whatever order the engine
                listed players, so a bystander standing on the dais could take
                a seat from somebody's party.
            ]]
            name = "a party boards ahead of the bystanders standing with it",
            run = function()
                local state = partyOfTwo(500)
                local order = PartySession.boardingOrder(state, { STRANGER, SECOND, LEADER }, 3)
                TestRunner.equal(order[1], LEADER)
                TestRunner.equal(order[2], SECOND)
                TestRunner.equal(order[3], STRANGER)
            end,
        },
        {
            name = "a party never boards more than the chosen size",
            run = function()
                local state = partyOfTwo(500)
                local order = PartySession.boardingOrder(state, { STRANGER, SECOND, LEADER }, 2)
                TestRunner.equal(#order, 2)
                TestRunner.equal(order[1], LEADER)
                TestRunner.equal(order[2], SECOND)
            end,
        },
        {
            -- The platform is still the authority on presence. A roster can
            -- reorder who boards; it cannot conjure somebody onto the dais.
            name = "a member who is not standing there does not board",
            run = function()
                local order = PartySession.boardingOrder(partyOfTwo(500), { STRANGER }, 4)
                TestRunner.equal(#order, 1)
                TestRunner.equal(order[1], STRANGER)
            end,
        },
        {
            --[[
                The travelling party is the boarding list, not the friendship
                group: a party of two that chose three seats picks up a
                stranger, and the stranger is in that reserved world with
                them. A ticket has to name the world's population or the
                stranger has no way home.
            ]]
            name = "the party that travels is whoever actually boarded",
            run = function()
                local state, result =
                    PartySession.createForDeparture({ LEADER, SECOND, STRANGER }, 600)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(PartySession.size(state), 3)
                TestRunner.equal(PartySession.isMember(state, STRANGER), true)
                TestRunner.equal(PartySession.memberIds(state)[1], LEADER)

                -- Duplicates are one person, and an empty dais is no party.
                TestRunner.equal(
                    PartySession.size(PartySession.createForDeparture({ LEADER, LEADER }, 600)),
                    1
                )
                local empty, emptyResult = PartySession.createForDeparture({}, 600)
                TestRunner.equal(empty, nil)
                TestRunner.equal(emptyResult.reason, "empty_roster")
            end,
        },
        {
            name = "a ticket is issued to a member and refused to anyone else",
            run = function()
                local state = partyOfTwo(500)
                local ticket, result = PartySession.issueTicket(state, SECOND, "ACCESS", 600)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal((ticket :: any).partyId, (state :: any).partyId)
                TestRunner.equal((ticket :: any).partySize, 2)

                local refused, refusal = PartySession.issueTicket(state, STRANGER, "ACCESS", 600)
                TestRunner.equal(refused, nil)
                TestRunner.equal(refusal.reason, "not_a_member")

                local codeless, codeResult = PartySession.issueTicket(state, LEADER, "", 600)
                TestRunner.equal(codeless, nil)
                TestRunner.equal(codeResult.reason, "invalid_access_code")
            end,
        },
        {
            name = "a live ticket sends its holder back to their own party",
            run = function()
                local ticket = PartySession.issueTicket(partyOfTwo(500), LEADER, "ACCESS", 600)
                local read = PartySession.readTicket(ticket, 900, nil)
                TestRunner.equal(read.rejoin, true)
                TestRunner.equal(read.accessCode, "ACCESS")
                TestRunner.equal(read.partySize, 2)
            end,
        },
        {
            --[[
                The far end of a stale code is the bad failure: a reserved
                server still accepts a teleport long after everyone has left,
                and arriving alone in the world your party left reads as the
                game breaking rather than as a rejoin.
            ]]
            name = "an expired ticket returns to the lodge instead of an empty world",
            run = function()
                local ticket = PartySession.issueTicket(partyOfTwo(500), LEADER, "ACCESS", 600)
                local read =
                    PartySession.readTicket(ticket, 600 + PartySession.rejoinSeconds() + 1, nil)
                TestRunner.equal(read.rejoin, false)
                TestRunner.equal(read.reason, "expired")
            end,
        },
        {
            -- Without this a member who dropped and came back would be
            -- forwarded to the world they are standing in, forever.
            name = "a member already in their party's own run is not sent again",
            run = function()
                local state = partyOfTwo(500)
                local ticket = PartySession.issueTicket(state, LEADER, "ACCESS", 600)
                local read = PartySession.readTicket(ticket, 700, (state :: any).partyId)
                TestRunner.equal(read.rejoin, false)
                TestRunner.equal(read.reason, "already_here")
            end,
        },
        {
            name = "a malformed or forged ticket is no ticket at all",
            run = function()
                local cases = {
                    nil,
                    "ticket",
                    {},
                    { partyId = "p", accessCode = "", issuedAt = 1, expiresAt = 2 },
                    { partyId = "", accessCode = "A", issuedAt = 1, expiresAt = 2 },
                    { partyId = "p", accessCode = "A", issuedAt = 5, expiresAt = 5 },
                    { partyId = "p", accessCode = "A", issuedAt = -1, expiresAt = 2 },
                    {
                        partyId = string.rep("p", 200),
                        accessCode = "A",
                        issuedAt = 1,
                        expiresAt = 2,
                    },
                }
                --[[
                    Absent is a case, and it cannot live in the list above: a
                    table constructor stores nothing for a leading nil, so
                    generalized iteration stops before the first real entry
                    and the whole loop runs zero times. This spec ran zero
                    times exactly that way before somebody read it.
                ]]
                TestRunner.equal(PartySession.normalizeTicket(nil), nil)
                TestRunner.equal(PartySession.readTicket(nil, 10, nil).reason, "no_ticket")
                for _, case in cases do
                    TestRunner.equal(PartySession.normalizeTicket(case), nil)
                    TestRunner.equal(PartySession.readTicket(case, 10, nil).rejoin, false)
                end
            end,
        },
        {
            --[[
                The access code is the entire key to a private world. The
                client half of a ticket is built by construction rather than
                by remembering to omit a field, because the latter does not
                survive somebody adding one.
            ]]
            name = "the client half of a ticket carries no access code",
            run = function()
                local ticket = PartySession.issueTicket(partyOfTwo(500), LEADER, "ACCESS", 600)
                local public = PartySession.publicTicket(ticket, 700, nil) :: any
                TestRunner.equal(public.available, true)
                TestRunner.equal(public.partySize, 2)
                TestRunner.equal(public.accessCode, nil)
                TestRunner.equal(public.partyId, nil)
                TestRunner.truthy(public.secondsRemaining > 0)
                TestRunner.equal(
                    PartySession.publicTicket(ticket, 600 + PartySession.rejoinSeconds() + 1, nil),
                    nil
                )
            end,
        },
        {
            name = "a state that cannot be read admits nobody",
            run = function()
                local cases = {
                    "party",
                    {},
                    { partyId = "p", leaderUserId = LEADER, members = {} },
                    -- A leader who is not on their own roster is not a party.
                    {
                        partyId = "p",
                        leaderUserId = LEADER,
                        members = { { userId = SECOND, joinedAt = 1 } },
                    },
                    -- Longer than a ticket can carry, so a party that kept it
                    -- could issue tickets nobody can read back.
                    {
                        partyId = string.rep("p", 200),
                        leaderUserId = LEADER,
                        members = { { userId = LEADER, joinedAt = 1 } },
                    },
                }
                -- No party at all, kept out of the list for the reason above:
                -- a leading nil makes the loop iterate nothing.
                TestRunner.equal(PartySession.normalize(nil), nil)
                TestRunner.equal(PartySession.size(nil), 0)
                for _, case in cases do
                    TestRunner.equal(PartySession.normalize(case), nil)
                    TestRunner.equal(PartySession.size(case), 0)
                    TestRunner.equal(PartySession.isMember(case, LEADER), false)
                    local _, result = PartySession.invite(case, LEADER, SECOND, 10, 8)
                    TestRunner.equal(result.reason, "no_party")
                end
            end,
        },
    },
}
