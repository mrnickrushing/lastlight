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
local TestRunner = require("../TestRunner")

local BUILDER_PATH = "src/server/World/IronrootBuilder.luau"

local function builderSource(): string
    assert(fs.isFile(BUILDER_PATH), "IronrootBuilder is missing")
    return fs.readFile(BUILDER_PATH)
end

return {
    name = "IronrootBuilderCoverage",
    cases = {
        {
            name = "every module the Delve can place has geometry behind it",
            run = function()
                local source = builderSource()
                local missing: { string } = {}
                for _, definition in Ironroot.Modules do
                    local needle = string.format("visual == %q", definition.visual)
                    if string.find(source, needle, 1, true) == nil then
                        table.insert(missing, definition.visual)
                    end
                end
                TestRunner.truthy(
                    #missing == 0,
                    "module visuals with no case in the builder: " .. table.concat(missing, ", ")
                )
            end,
        },
        {
            -- The region must not open until it is whole. This pins the
            -- other half of that promise: the builder answering for every
            -- key is what earns the enabled flag, not the reverse.
            name = "the Delve stays closed until its geometry is complete",
            run = function()
                local Regions = require("../../src/shared/Content/Definitions/Regions")
                local ironroot
                for _, region in Regions do
                    if region.id == "region_ironroot" then
                        ironroot = region
                        break
                    end
                end
                TestRunner.truthy(ironroot ~= nil)
                -- When this flips to true, the coverage case above is what
                -- says it was allowed to.
                TestRunner.equal((ironroot :: any).enabled, false)
            end,
        },
    },
}
