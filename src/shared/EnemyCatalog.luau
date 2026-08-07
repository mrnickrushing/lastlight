--!strict

--[[
    One roster for the night systems, assembled from the regional ones.

    EnemyService took the Bramblewake catalog directly for as long as
    there was only one region. Now that the Delve exists, it takes this
    instead: the same get/require/order/all surface, backed by every
    region's roster, plus orderFor(regionId) when a caller genuinely
    means "this region's enemies" rather than "any enemy".

    Ids carry their own meaning across regions -- there is exactly one
    enemy_rail_hound -- so a merged lookup can never be ambiguous, and the
    default order stays Bramblewake's exact sequence so every existing
    schedule and spec keeps its behavior.
]]

local BramblewakeEnemies = require("./BramblewakeEnemies")
local IronrootEnemies = require("./IronrootEnemies")
local MireglassEnemies = require("./MireglassEnemies")
local TempestEnemies = require("./TempestEnemies")
local CinderfallEnemies = require("./CinderfallEnemies")
local FrostmereEnemies = require("./FrostmereEnemies")

local EnemyCatalog = {}

export type EnemyDefinition = BramblewakeEnemies.EnemyDefinition

local ROSTERS: { { regionId: string, roster: any } } = {
    { regionId = "region_bramblewake", roster = BramblewakeEnemies },
    { regionId = "region_ironroot", roster = IronrootEnemies },
    { regionId = "region_mireglass", roster = MireglassEnemies },
    { regionId = "region_tempest", roster = TempestEnemies },
    { regionId = "region_frostmere", roster = FrostmereEnemies },
    { regionId = "region_cinderfall", roster = CinderfallEnemies },
}

local ROSTER_BY_REGION: { [string]: any } = {}
local ORDER: { string } = {}
local REGION_BY_ENEMY: { [string]: string } = {}
for _, entry in ROSTERS do
    ROSTER_BY_REGION[entry.regionId] = entry.roster
    for _, enemyId in entry.roster.order() do
        assert(
            REGION_BY_ENEMY[enemyId] == nil,
            string.format("enemy ID %q is claimed by two regions", enemyId)
        )
        REGION_BY_ENEMY[enemyId] = entry.regionId
        table.insert(ORDER, enemyId)
    end
end
table.freeze(ORDER)

function EnemyCatalog.get(enemyId: string): EnemyDefinition?
    local regionId = REGION_BY_ENEMY[enemyId]
    if regionId == nil then
        return nil
    end
    return ROSTER_BY_REGION[regionId].get(enemyId)
end

function EnemyCatalog.require(enemyId: string): EnemyDefinition
    local definition = EnemyCatalog.get(enemyId)
    assert(definition ~= nil, string.format("unknown enemy ID %q", enemyId))
    return definition
end

function EnemyCatalog.regionOf(enemyId: string): string?
    return REGION_BY_ENEMY[enemyId]
end

-- Every enemy, regions in declaration order. Bramblewake's six come
-- first, in their original sequence.
function EnemyCatalog.order(): { string }
    return table.clone(ORDER)
end

function EnemyCatalog.orderFor(regionId: string): { string }
    local roster = ROSTER_BY_REGION[regionId]
    return if roster == nil then {} else roster.order()
end

function EnemyCatalog.all(): { EnemyDefinition }
    local result: { EnemyDefinition } = {}
    for _, enemyId in ORDER do
        table.insert(result, EnemyCatalog.require(enemyId))
    end
    return result
end

return table.freeze(EnemyCatalog)
