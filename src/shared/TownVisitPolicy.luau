--!strict

--[[
    Who may stand in your Emberhollow, and what standing there gets them.

    A town in this game has always had a host and visitors -- `TownPermissions`
    settled that in Milestone 4, and its invariant has held since: a visit may
    improve a town or leave it alone, never break it. What was missing is the
    other half of the sentence. A player had no say in *who* visited, and no
    way to be told that they were the one being let in.

    This module is that say, as four values and one question.

    **What a policy actually governs, and what it cannot.** It does not govern
    presence. Roblox decides which server a player lands in, and a game that
    tried to eject somebody on arrival would be a game that bricks a public
    join -- the player did nothing wrong by being matched. So the policy
    governs what this game does control: whether the arriving player's town
    record is **adopted into** the host's town, and whether they may **read**
    the host's showcase. Refused, they are an outsider: they walk the same
    world, they play their own nights and their own expeditions and their own
    profile, and the host's Emberhollow is scenery they may not touch or
    inspect. That is a real boundary rather than a decorative one, because
    adoption is the only channel by which one player's save has ever reached
    another player's town.

    **A refusal cannot silently become a downgrade.** An outsider contributes
    nothing, which is strictly less than the visitor's upward-only
    contribution, so the Milestone 4 invariant is not merely preserved by this
    change -- it is preserved twice over, and the spec re-asserts it against
    this path rather than trusting that.

    The four values are ordered from most open to least, and that order is
    load-bearing: cycling the gate walks it, and a spec pins it so a value
    added in the middle cannot quietly change what a press does.
]]

export type Policy = "open" | "friends" | "invited" | "closed"

--[[
    What the arriving player is to the host, decided by the server before this
    module is asked anything. Deliberately not "friend or not": a party member
    is admitted by a town set to `invited` whether or not they are on the
    host's friends list, because being asked along is the invitation.
]]
export type Relation = "host" | "friend" | "invited" | "stranger"

export type Decision = {
    allowed: boolean,
    reason: string,
}

local TownVisitPolicy = {
    Default = "open" :: Policy,
}

local ORDER: { Policy } = { "open", "friends", "invited", "closed" }

local LABELS: { [string]: string } = {
    open = "OPEN TO ALL TRAVELLERS",
    friends = "OPEN TO FRIENDS",
    invited = "OPEN TO THOSE YOU ASKED ALONG",
    closed = "CLOSED — THIS TOWN IS YOURS ALONE",
}

--[[
    Which relations each policy admits.

    Written out rather than derived from the order, because "friends admits an
    invited stranger" is a decision and not an accident of sorting: somebody
    you asked onto the departure platform is somebody you chose, and a town
    that admits your friends but not the party you just built is a town that
    refuses the people you are actually playing with.
]]
local ADMITS: { [string]: { [string]: boolean } } = {
    open = { host = true, friend = true, invited = true, stranger = true },
    friends = { host = true, friend = true, invited = true, stranger = false },
    invited = { host = true, friend = false, invited = true, stranger = false },
    closed = { host = true, friend = false, invited = false, stranger = false },
}

local POLICY_SET: { [string]: boolean } = {}
for _, policy in ORDER do
    POLICY_SET[policy] = true
    assert(ADMITS[policy] ~= nil, "policy with no admission row: " .. policy)
    assert(LABELS[policy] ~= nil, "policy with no label: " .. policy)
end
assert(POLICY_SET[TownVisitPolicy.Default], "default policy is not a policy")

function TownVisitPolicy.isValid(policy: any): boolean
    return type(policy) == "string" and POLICY_SET[policy] == true
end

--[[
    Bound whatever came out of storage. An unreadable policy resolves to the
    default rather than to `closed`: a corrupt byte must not lock a player out
    of their own town's social life, and the default is the state every save
    before this schema was in anyway.
]]
function TownVisitPolicy.normalize(policy: any): Policy
    if TownVisitPolicy.isValid(policy) then
        return policy :: Policy
    end
    return TownVisitPolicy.Default
end

function TownVisitPolicy.list(): { Policy }
    return ORDER
end

function TownVisitPolicy.label(policy: any): string
    return LABELS[TownVisitPolicy.normalize(policy)]
end

-- The gate is one prompt, so a press walks the list and wraps. The order is
-- pinned by spec for exactly this reason.
function TownVisitPolicy.next(policy: any): Policy
    local current = TownVisitPolicy.normalize(policy)
    for index, value in ORDER do
        if value == current then
            return ORDER[(index % #ORDER) + 1]
        end
    end
    return TownVisitPolicy.Default
end

--[[
    The one question. A host is always admitted to their own town, and that is
    checked first rather than left to the table, because a policy value nobody
    thought about must never be able to lock a founder out of the place they
    built.
]]
function TownVisitPolicy.admits(policy: any, relation: any): Decision
    if relation == "host" then
        return { allowed = true, reason = "host" }
    end
    if relation ~= "friend" and relation ~= "invited" and relation ~= "stranger" then
        -- An unknown relation is treated as the least of them. Guessing
        -- upward here would mean a new relation kind ships admitted by every
        -- town in the game before anybody decides it should be.
        relation = "stranger"
    end
    local row = ADMITS[TownVisitPolicy.normalize(policy)]
    if row[relation] == true then
        return { allowed = true, reason = tostring(relation) }
    end
    return { allowed = false, reason = "refused_" .. tostring(relation) }
end

--[[
    The role a player holds once the policy has spoken.

    Three roles rather than TownPermissions' two, and the third is a narrowing
    of the second: `visitor` is what `TownPermissions` has always meant, and
    `outsider` is a visitor whose contribution and whose reading are both
    refused. Everything downstream that already asks TownPermissions about a
    host or a visitor keeps working unchanged, because an outsider never
    reaches it.
]]
function TownVisitPolicy.roleFor(policy: any, relation: any): string
    if relation == "host" then
        return "host"
    end
    return if TownVisitPolicy.admits(policy, relation).allowed then "visitor" else "outsider"
end

return table.freeze(TownVisitPolicy)
