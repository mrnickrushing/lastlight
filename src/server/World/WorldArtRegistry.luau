--!strict

-- Data-only cloud art mapping. Keep this synchronized with
-- assets/images/manifest.json so pure Luau tests can validate every atlas cell
-- without Roblox engine types.

local WorldArtRegistry = {}

export type Panel = {
    assetId: number,
    offsetX: number,
    offsetY: number,
    width: number,
    height: number,
}

local ASSET_ID = 83727643922166
local CELL_WIDTH = 627
local CELL_HEIGHT = 418

local PANELS: { [string]: Panel } = table.freeze({
    evacuation_route = {
        assetId = ASSET_ID,
        offsetX = 0,
        offsetY = 0,
        width = CELL_WIDTH,
        height = CELL_HEIGHT,
    },
    lantern_maintenance = {
        assetId = ASSET_ID,
        offsetX = CELL_WIDTH,
        offsetY = 0,
        width = CELL_WIDTH,
        height = CELL_HEIGHT,
    },
    supply_inventory = {
        assetId = ASSET_ID,
        offsetX = 0,
        offsetY = CELL_HEIGHT,
        width = CELL_WIDTH,
        height = CELL_HEIGHT,
    },
    bramble_hazard = {
        assetId = ASSET_ID,
        offsetX = CELL_WIDTH,
        offsetY = CELL_HEIGHT,
        width = CELL_WIDTH,
        height = CELL_HEIGHT,
    },
    field_botany = {
        assetId = ASSET_ID,
        offsetX = 0,
        offsetY = CELL_HEIGHT * 2,
        width = CELL_WIDTH,
        height = CELL_HEIGHT,
    },
    community_watch = {
        assetId = ASSET_ID,
        offsetX = CELL_WIDTH,
        offsetY = CELL_HEIGHT * 2,
        width = CELL_WIDTH,
        height = CELL_HEIGHT,
    },
})

local ORDER = table.freeze({
    "evacuation_route",
    "lantern_maintenance",
    "supply_inventory",
    "bramble_hazard",
    "field_botany",
    "community_watch",
})

function WorldArtRegistry.noticePanel(panelId: string): Panel?
    return PANELS[panelId]
end

function WorldArtRegistry.noticePanelIds(): { string }
    return table.clone(ORDER)
end

return table.freeze(WorldArtRegistry)
