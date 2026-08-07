--!strict

--[[
    The Delve's catalog and its builder have to agree, and nothing else in
    the suite can check that: the builder is a server module full of
    Instance.new, so Lune cannot run it. What Lune can do is read it, and
    the one fact worth reading is which visual keys have a case.

    This is deliberately a text check rather than a mock. A mock would
    prove the builder answers for a key; only the catalog's own list
    proves it answers for every key a run can actually place, and that is
    the failure that matters -- a module drawn into a manifest with no
    geometry behind it is an empty cell a player walks into.
]]

local fs = require("@lune/fs")
local Ironroot = require("../../src/shared/Content/Definitions/IronrootExpedition")
local Mireglass = require("../../src/shared/Content/Definitions/MireglassExpedition")
local TestRunner = require("../TestRunner")

local REGIONS = {
    { catalog = Ironroot, builder = "src/server/World/IronrootBuilder.luau" },
    { catalog = Mireglass, builder = "src/server/World/MireglassBuilder.luau" },
}

local function builderSource(path: string): string
    assert(fs.isFile(path), path .. " is missing")
    return fs.readFile(path)
end

return {
    name = "RegionBuilderCoverage",
    cases = {
        {
            name = "every module a new region can place has geometry behind it",
            run = function()
                for _, region in REGIONS do
                    local source = builderSource(region.builder)
                    local missing: { string } = {}
                    for _, definition in region.catalog.Modules do
                        local needle = string.format("visual == %q", definition.visual)
                        if string.find(source, needle, 1, true) == nil then
                            table.insert(missing, definition.visual)
                        end
                    end
                    TestRunner.truthy(
                        #missing == 0,
                        region.catalog.RegionId
                            .. " visuals with no case in its builder: "
                            .. table.concat(missing, ", ")
                    )
                end
            end,
        },
        {
            -- The region must not open until it is whole. This pins the
            -- other half of that promise: the builder answering for every
            -- key is what earns the enabled flag, not the reverse.
            name = "the new regions stay closed until their runtimes land",
            run = function()
                local Regions = require("../../src/shared/Content/Definitions/Regions")
                local byId: { [string]: any } = {}
                for _, region in Regions do
                    byId[region.id] = region
                end
                -- Geometry is necessary, not sufficient: these stay shut
                -- until their services and arenas exist too. When one flips
                -- to true, the coverage case above is what says it was
                -- allowed to.
                TestRunner.equal(byId.region_ironroot.enabled, false)
                TestRunner.equal(byId.region_mireglass.enabled, false)
            end,
        },
        {
            --[[
                Every material a region's nodes pay must be one the ledger
                already accepts. This is the #212 lesson applied one layer
                earlier: there, a reward shape the ledger refused meant a
                node that paid nothing, silently, for weeks. A node made of
                a material nobody registered is the same bug with a longer
                fuse, and it is cheap to refuse here.
            ]]
            name = "every region's nodes are made of materials the ledger knows",
            run = function()
                local ExpeditionInventory = require("../../src/shared/ExpeditionInventory")
                local registrySource = fs.readFile("src/server/World/RegionBuilders.luau")
                for _, region in REGIONS do
                    local regionId = region.catalog.RegionId
                    --[[
                        The node material list lives beside the builders
                        (it is a fact about the region's world, not its
                        economy), and RegionBuilders cannot be required
                        here -- it reaches for `script` like every server
                        module. So the ids are read out of its source, from
                        the region's own slice of the table.
                    ]]
                    -- take everything from this region's key to the next
                    -- region key (or the end of the table), which is its slice
                    local afterKey = string.match(registrySource, regionId .. " = table(.*)$")
                    local slice = if afterKey == nil
                        then nil
                        else string.match(afterKey, "^(.-)\n    region_") or afterKey
                    TestRunner.truthy(
                        slice ~= nil,
                        regionId .. " has no node material list beside the builders"
                    )
                    local seen = 0
                    for materialId in string.gmatch(slice or "", 'id = "(material_[a-z_]+)"') do
                        seen += 1
                        local _, result = ExpeditionInventory.addUnbanked(
                            ExpeditionInventory.default(),
                            "spec:" .. materialId,
                            "spechash",
                            { materialId = materialId, amount = 1 },
                            1000
                        )
                        TestRunner.truthy(
                            result.applied,
                            regionId .. " plants a node the ledger refuses: " .. materialId
                        )
                    end
                    TestRunner.truthy(seen >= 3, regionId .. " has too few node materials")
                end
            end,
        },
    },
}
