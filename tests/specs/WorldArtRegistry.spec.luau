--!strict

local WorldArtRegistry = require("../../src/server/World/WorldArtRegistry")
local TestRunner = require("../TestRunner")

return {
    name = "WorldArtRegistry",
    cases = {
        {
            name = "maps all six first-world notice panels to one measured atlas",
            run = function()
                local ids = WorldArtRegistry.noticePanelIds()
                TestRunner.equal(#ids, 6)
                local occupied = {}
                for _, id in ids do
                    local panel = WorldArtRegistry.noticePanel(id)
                    TestRunner.truthy(panel ~= nil, "missing panel " .. id)
                    local resolved = panel :: WorldArtRegistry.Panel
                    TestRunner.equal(resolved.assetId, 83727643922166)
                    TestRunner.equal(resolved.width, 627)
                    TestRunner.equal(resolved.height, 418)
                    local cell = string.format("%d:%d", resolved.offsetX, resolved.offsetY)
                    TestRunner.equal(occupied[cell], nil, "duplicate atlas cell " .. cell)
                    occupied[cell] = true
                end
            end,
        },
        {
            name = "rejects an unknown notice panel instead of guessing art",
            run = function()
                TestRunner.equal(WorldArtRegistry.noticePanel("generic_notice"), nil)
            end,
        },
    },
}
