--!strict

--[[
    The town's authored approach lanes and the snare plots that guard them.
    Pure numbers only, like everything in the shared layer: lanes are yaw
    rotations of the night spawn point around the First Lantern, plots are
    fixed points along each lane, and the trap's rules are constants -- so
    the Lune suite pins lane selection, geometry, and trigger boundaries
    without a world.

    The GDD's defense loop asks for three to five authored lanes per town
    layout. This town gets three. The first wave of every night always
    walks the Meadow Gate -- the straight approach players have faced since
    the first night, bit-identical to the pre-lane behavior -- and later
    waves rotate through the flanks deterministically, so a night's layout
    is knowable at nightfall and two runs of the same night match.
]]

local DefenseLanes = {}

export type Lane = {
    id: string,
    displayName: string,
    yaw: number,
}

local LANES: { Lane } = table.freeze({
    table.freeze({ id = "lane_meadow_gate", displayName = "MEADOW GATE", yaw = 0 }),
    table.freeze({ id = "lane_east_hollow", displayName = "EAST HOLLOW", yaw = math.rad(52) }),
    table.freeze({ id = "lane_west_break", displayName = "WEST BREAK", yaw = math.rad(-52) }),
}) :: { Lane }

-- How far from the lantern a lane's snare plot sits: inside the enemy's
-- walk, outside the commons, close enough to reach during dusk.
local PLOT_DISTANCE = 46

DefenseLanes.Trap = table.freeze({
    armCost = table.freeze({ material_meadow_fiber = 2, material_heartwood = 1 }),
    charges = 2,
    triggerRadius = 9,
    snareSeconds = 3.5,
})

function DefenseLanes.list(): { Lane }
    return LANES
end

function DefenseLanes.get(laneId: any): Lane?
    for _, lane in LANES do
        if lane.id == laneId then
            return lane
        end
    end
    return nil
end

--[[
    Which lane a wave walks. Wave 1 is always the Meadow Gate; later waves
    step through the lanes from a night-dependent start, so consecutive
    waves change direction and different nights lead with different flanks.
]]
function DefenseLanes.laneForWave(night: number, wave: number): Lane
    if wave <= 1 then
        return LANES[1]
    end
    return LANES[(night + wave) % #LANES + 1]
end

-- Rotate (x, z) about (cx, cz) by a lane's yaw. Yaw 0 is the identity, so
-- the Meadow Gate reproduces the authored spawn point exactly.
function DefenseLanes.rotatedPoint(
    lane: Lane,
    x: number,
    z: number,
    cx: number,
    cz: number
): (number, number)
    if lane.yaw == 0 then
        return x, z
    end
    local dx = x - cx
    local dz = z - cz
    local cos = math.cos(lane.yaw)
    local sin = math.sin(lane.yaw)
    return cx + dx * cos - dz * sin, cz + dx * sin + dz * cos
end

-- Where a lane's snare plot sits: PLOT_DISTANCE from the lantern along the
-- lane's rotated spawn direction.
function DefenseLanes.plotPoint(
    lane: Lane,
    spawnX: number,
    spawnZ: number,
    cx: number,
    cz: number
): (number, number)
    local rx, rz = DefenseLanes.rotatedPoint(lane, spawnX, spawnZ, cx, cz)
    local dx = rx - cx
    local dz = rz - cz
    local distance = math.sqrt(dx * dx + dz * dz)
    if distance < 1 then
        return cx, cz + PLOT_DISTANCE
    end
    local scale = PLOT_DISTANCE / distance
    return cx + dx * scale, cz + dz * scale
end

function DefenseLanes.trapTriggers(
    enemyX: number,
    enemyZ: number,
    plotX: number,
    plotZ: number
): boolean
    local dx = enemyX - plotX
    local dz = enemyZ - plotZ
    return dx * dx + dz * dz <= DefenseLanes.Trap.triggerRadius ^ 2
end

return table.freeze(DefenseLanes)
