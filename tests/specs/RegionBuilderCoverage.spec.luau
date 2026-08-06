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
    },
}
