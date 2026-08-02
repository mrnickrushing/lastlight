--!strict

local MusicCatalog = require("../../src/shared/MusicCatalog")
local TestRunner = require("../TestRunner")

return {
    name = "MusicCatalog",
    cases = {
        {
            name = "gives every launch world distinct day dusk and night music",
            run = function()
                TestRunner.equal(#MusicCatalog.regionIds(), 8)
                local assetIds = {}
                for _, track in MusicCatalog.tracks() do
                    TestRunner.truthy(
                        assetIds[track.assetId] == nil,
                        "music asset reused across states"
                    )
                    assetIds[track.assetId] = true
                    TestRunner.truthy(track.duration >= 60, "music loop is too short")
                end
                TestRunner.equal(#MusicCatalog.tracks(), 25)
            end,
        },
        {
            name = "makes dusk and night progressively more threatening",
            run = function()
                for _, regionId in MusicCatalog.regionIds() do
                    local day = MusicCatalog.resolve(regionId, "day", false)
                    local dusk = MusicCatalog.resolve(regionId, "dusk", false)
                    local night = MusicCatalog.resolve(regionId, "night", false)
                    TestRunner.truthy(day.intensity < dusk.intensity)
                    TestRunner.truthy(dusk.intensity < night.intensity)
                end
            end,
        },
        {
            name = "uses the Blackout pulse for active crisis stages",
            run = function()
                local normal = MusicCatalog.resolveSnapshot({
                    regionId = "region_bramblewake",
                    phase = "night",
                })
                local blackout = MusicCatalog.resolveSnapshot({
                    regionId = "region_bramblewake",
                    phase = "night",
                    blackout = { status = "old_growth" },
                })
                TestRunner.equal(normal.id, "music_bramblewake_night")
                TestRunner.equal(blackout.id, "music_blackout_pulse")
                TestRunner.truthy(blackout.intensity > normal.intensity)
            end,
        },
        {
            name = "falls back safely to Emberhollow day music",
            run = function()
                TestRunner.equal(MusicCatalog.resolveSnapshot(nil).id, "music_emberhollow_day")
                TestRunner.equal(
                    MusicCatalog.resolve("region_unknown", "reveal", false).id,
                    "music_emberhollow_day"
                )
            end,
        },
    },
}
