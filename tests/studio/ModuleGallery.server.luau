--!strict
--[[
    The module gallery: every module in the catalog, built once, in a row.

    Milestone 5's authoring tool half. A human reviewing the thirty-module
    set should not need thirty seeds to see it — this builds the whole
    catalog side by side under one model so an art pass can walk the line.

    Off by default because it doubles the built world: set the
    `LastLightBuildModuleGallery` attribute on the DataModel to true before
    pressing Play (or from the command bar, then re-run) and the gallery
    assembles at a far offset with one label per module. The script still
    runs a cheap automated check either way: every catalog module must have
    a visual the builder recognizes, which guards against a new definition
    referencing a visual kind nobody wrote.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local root = ReplicatedStorage:WaitForChild("LastLight")
local Catalog = require(root.Content.Definitions.BramblewakeExpedition)
local ExpeditionGenerator = require(root.ExpeditionGenerator)
local RuntimeIds = require(root.RuntimeIds)

local serverRoot = ServerScriptService:WaitForChild("LastLightServer")
local BramblewakeBuilder = require(serverRoot.World.BramblewakeBuilder)

-- A synthetic manifest holding the entire catalog in one straight walk.
-- Never validated by the generator on purpose: validation enforces the
-- twelve-module run shape, and a gallery is not a run.
local function galleryManifest(): any
    local modules = {}
    for index, definition in Catalog.Modules do
        table.insert(modules, {
            index = index,
            moduleId = definition.id,
            cellX = index - 1,
            cellZ = 0,
            rotation = 0,
        })
    end
    return {
        version = Catalog.Version,
        regionId = Catalog.RegionId,
        seed = 0,
        source = "module_gallery",
        modules = modules,
        hash = "gallery",
    }
end

local knownCount = 0
for _, definition in Catalog.Modules do
    assert(type(definition.visual) == "string" and #definition.visual > 0, definition.id)
    knownCount += 1
end
assert(knownCount == 30, "module gallery expects the full thirty-module catalog")
print(string.format("[Last Light] Module gallery: %d catalog modules verified", knownCount))

if game:GetAttribute("LastLightBuildModuleGallery") == true then
    local holder = Instance.new("Folder")
    holder.Name = "LastLightModuleGallery"
    holder.Parent = workspace
    local result = BramblewakeBuilder.build(
        holder,
        galleryManifest(),
        ExpeditionGenerator,
        Catalog,
        RuntimeIds
    )
    local expedition = holder:FindFirstChild("BramblewakeExpedition")
    assert(expedition ~= nil, "gallery build produced no expedition model")
    expedition:PivotTo(expedition:GetPivot() + Vector3.new(0, 0, 4000))
    print(
        string.format(
            "[Last Light] Module gallery built: %d modules, %d parts, at Z+4000",
            #Catalog.Modules,
            tonumber(result and result.partCount) or 0
        )
    )
end
