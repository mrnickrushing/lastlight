--!strict

--[[
    The pure half of a companion's movement: where it wants to stand
    relative to its keeper, and how far it moves this step. Number pairs
    only -- like every module in the shared layer, it knows no Roblox
    datatypes, so the Lune suite can hold its behavior without a world.
    The service assembles Vector3s and CFrames from these numbers.

    A companion keeps to its keeper's flank, not their heels: the follow
    offset sits beside and slightly behind, so the hound frames its keeper
    instead of shoving through them, and it only moves at all outside a
    settle radius so it rests when the keeper does.
]]

local CompanionMotion = {}

local FOLLOW_SIDE = 3.2
local FOLLOW_BACK = 2.4
local SETTLE_RADIUS = 1.6
local WALK_SPEED = 12
local RUN_SPEED = 22
local RUN_AT = 14
local TELEPORT_AT = 60

-- The flank offset in the keeper's local space: +X is their right side,
-- +Z is behind them (Roblox look vector is -Z).
function CompanionMotion.followOffset(): (number, number)
    return FOLLOW_SIDE, FOLLOW_BACK
end

--[[
    One flat movement step from (px, pz) toward (tx, tz). Returns the new
    coordinates and whether the companion is moving (for pose selection).
    Far past TELEPORT_AT the companion simply arrives -- a keeper who
    outran streaming should not watch their hound jog across the map.
]]
function CompanionMotion.step(
    px: number,
    pz: number,
    tx: number,
    tz: number,
    deltaTime: number
): (number, number, boolean)
    local dx = tx - px
    local dz = tz - pz
    local distance = math.sqrt(dx * dx + dz * dz)
    if distance <= SETTLE_RADIUS then
        return px, pz, false
    end
    if distance >= TELEPORT_AT then
        return tx, tz, false
    end
    local speed = if distance >= RUN_AT then RUN_SPEED else WALK_SPEED
    local travel = math.min(distance - SETTLE_RADIUS * 0.5, speed * math.max(deltaTime, 0))
    local scale = travel / distance
    return px + dx * scale, pz + dz * scale, true
end

CompanionMotion.Constants = table.freeze({
    SettleRadius = SETTLE_RADIUS,
    WalkSpeed = WALK_SPEED,
    RunSpeed = RUN_SPEED,
    RunAt = RUN_AT,
    TeleportAt = TELEPORT_AT,
})

return table.freeze(CompanionMotion)
