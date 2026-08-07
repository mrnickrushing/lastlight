--!strict

--[[
    Which regions a departure may actually target.

    Three regions now exist as content, but existence is not access: a
    region is walkable only when its catalog has a builder (the Regions
    registry's `enabled` flag, still false for everything but
    Bramblewake), its registry dependencies are themselves enabled, and
    the story has reached its chapter. This module is the one place those
    three tests compose, so the departure flow, the generator call, and a
    future region-select UI all refuse for the same reasons in the same
    order.

    Today every request resolves to Bramblewake, exactly as before this
    module existed. When the Delve's builder lands, flipping its `enabled`
    flag in Content/Definitions/Regions.luau is the whole switch -- the
    chapter gate is already waiting behind it.
]]

local ChapterCatalog = require("./ChapterCatalog")
local Regions = require("./Content/Definitions/Regions")

local RegionAccess = {}

export type Verdict = {
    allowed: boolean,
    reason: string,
}

local REGIONS_BY_ID: { [string]: any } = {}
for _, region in Regions do
    REGIONS_BY_ID[region.id] = region
end
table.freeze(REGIONS_BY_ID)

local DEFAULT_REGION_ID = "region_bramblewake"

RegionAccess.DefaultRegionId = DEFAULT_REGION_ID

local function chapterComplete(story: any, chapterId: string?): boolean
    if chapterId == nil then
        return true
    end
    if type(story) ~= "table" then
        return false
    end
    if chapterId == "chapter_one" then
        return type(story.chapterOne) == "table" and story.chapterOne.status == "complete"
    end
    local chapters = story.chapters
    if type(chapters) ~= "table" then
        return false
    end
    local record = chapters[chapterId]
    return type(record) == "table" and record.status == "complete"
end

--[[
    Has the story reached a region's chapter? A region belongs to the
    chapter it hosts, and that chapter is playable once its prerequisite
    chapter is complete -- Bramblewake needs nothing, the Delve needs the
    Warden resolved, the Fen needs the Maw.
]]
function RegionAccess.chapterReached(story: any, regionId: any): boolean
    local chapter = ChapterCatalog.forRegion(regionId)
    if chapter == nil then
        -- a region with no chapter (a future postgame area) is gated only
        -- by its enabled flag
        return true
    end
    return chapterComplete(story, (chapter :: any).requires)
end

--[[
    Readiness is the server's business (the builders live there), so the
    shared layer takes it as an injected fact rather than reaching for a
    server module it cannot see. Absent, every enabled region is treated
    as walkable, which is the behavior this module had before readiness
    existed.
]]
local readinessProvider: ((string) -> boolean)? = nil

function RegionAccess.setReadinessProvider(provider: ((string) -> boolean)?)
    readinessProvider = provider
end

function RegionAccess.evaluate(regionId: any, story: any): Verdict
    local region = if type(regionId) == "string" then REGIONS_BY_ID[regionId] else nil
    if region == nil then
        return { allowed = false, reason = "region_unknown" }
    end
    if region.enabled ~= true then
        return { allowed = false, reason = "region_not_built" }
    end
    for _, dependencyId in region.dependencies do
        local dependency = REGIONS_BY_ID[dependencyId]
        if dependency == nil or dependency.enabled ~= true then
            return { allowed = false, reason = "region_dependency_missing" }
        end
    end
    if not RegionAccess.chapterReached(story, regionId) then
        return { allowed = false, reason = "chapter_not_reached" }
    end
    -- A region whose builder cannot yet draw a walkable world is refused
    -- even if somebody flips its enabled flag: the flag says "we mean to
    -- ship this", readiness says "a party would find something there".
    if readinessProvider ~= nil and not readinessProvider(regionId :: string) then
        return { allowed = false, reason = "region_not_walkable" }
    end
    return { allowed = true, reason = "open" }
end

-- The regions a departure could offer this profile, in registry order.
function RegionAccess.available(story: any): { string }
    local ids: { string } = {}
    for _, region in Regions do
        if RegionAccess.evaluate(region.id, story).allowed then
            table.insert(ids, region.id)
        end
    end
    return ids
end

--[[
    Resolve a requested destination. Anything that is not an open region
    resolves to Bramblewake rather than erroring -- a malformed or
    too-early request earns the default walk, never a broken server. The
    same shape ExpeditionContracts.resolve gives malformed contract ids.
]]
function RegionAccess.destinationFor(regionId: any, story: any): string
    if RegionAccess.evaluate(regionId, story).allowed then
        return regionId :: string
    end
    return DEFAULT_REGION_ID
end

return table.freeze(RegionAccess)
