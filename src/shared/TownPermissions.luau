--!strict

--[[
    Who may change a shared town, and in which direction.

    Milestone 4's exit gate asks that "visitors cannot modify or steal without
    permission." Most of that is already true by construction: every profile
    write is keyed to the player it belongs to, so a visitor has no path to a
    host's save, and TownProgression.merge is monotonic -- tier, growth stage,
    and building stages only ever take the maximum, so arriving with a fresh
    profile can never tear down what a host has built.

    Town condition was the exception. Its merge resolves on night number first,
    so a visitor arriving from night fifty with a wrecked town replaced a host's
    intact one outright: a stranger walks in and the walls are suddenly broken.
    Nobody stole anything, but the host's town changed because someone else
    visited, which is the thing the gate is asking about.

    The rule here restores the same shape the rest of the town already has:

      * a **host** may move their own town in either direction, because their
        own nights are what damage it and their own repairs are what fix it;
      * a **visitor** may only ever contribute upward. Their higher night count
        and their completed repairs carry, their damage does not.

    Stated as an invariant: no arrival by another player may lower integrity,
    reduce a building stage, or remove a resident. A town gets better when
    people visit, or it stays the same.
]]

local TownPermissions = {}

export type Role = "host" | "visitor"

export type Decision = {
    allowed: boolean,
    reason: string,
}

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function integrityOf(value: any): number
    if type(value) ~= "table" or not finite(value.integrity) then
        return 0
    end
    return math.clamp(value.integrity, 0, 100)
end

--[[
    Which role a player holds in the town they are standing in.

    Ownership is by user ID and nothing else. A display name can be changed to
    match someone else's; the numeric ID a player joins with cannot.
]]
function TownPermissions.roleFor(actorUserId: any, hostUserId: any): Role
    if
        finite(actorUserId)
        and finite(hostUserId)
        and actorUserId > 0
        and actorUserId == hostUserId
    then
        return "host"
    end
    return "visitor"
end

function TownPermissions.isHost(actorUserId: any, hostUserId: any): boolean
    return TownPermissions.roleFor(actorUserId, hostUserId) == "host"
end

--[[
    Whether this actor may apply a change that lowers shared town state.

    Only the host may. Everything else is refused with a reason rather than
    silently dropped, so a caller can tell a player why nothing happened.
]]
function TownPermissions.canDegrade(actorUserId: any, hostUserId: any): Decision
    if TownPermissions.isHost(actorUserId, hostUserId) then
        return { allowed = true, reason = "host" }
    end
    return { allowed = false, reason = "visitors_cannot_damage_a_town" }
end

--[[
    Resolve an incoming town condition against the current one.

    `merge` is the existing TownCondition.merge, passed in rather than required
    so this module stays free of a dependency it would only use once and so the
    host path provably keeps its old behaviour.

    The visitor path never returns anything with lower integrity than what is
    already standing, whatever night number rides along with it.
]]
function TownPermissions.resolveCondition(
    current: any,
    incoming: any,
    role: Role,
    merge: (any, any) -> any
): any
    local merged = merge(current, incoming)
    if role == "host" then
        return merged
    end

    -- A visitor's contribution is accepted only where it does not cost the host
    -- anything. If the merge would lower integrity, the town keeps what it had.
    if integrityOf(merged) < integrityOf(current) then
        return current
    end
    return merged
end

--[[
    Whether an actor may take a specific owned object.

    The recovery satchels and delivery crates already carry an OwnerUserId, and
    this is the same question asked in one place: an unowned object is free to
    anyone, an owned one belongs to its owner.
]]
function TownPermissions.canTake(actorUserId: any, ownerUserId: any): Decision
    if not finite(ownerUserId) or ownerUserId <= 0 then
        return { allowed = true, reason = "unowned" }
    end
    if finite(actorUserId) and actorUserId == ownerUserId then
        return { allowed = true, reason = "owner" }
    end
    return { allowed = false, reason = "belongs_to_another_traveler" }
end

return table.freeze(TownPermissions)
