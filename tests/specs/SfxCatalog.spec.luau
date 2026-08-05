--!strict

local SfxCatalog = require("../../src/shared/SfxCatalog")
local TestRunner = require("../TestRunner")

local function snapshot(overrides: { [string]: any }?): { [string]: any }
    local base: { [string]: any } = {
        resources = 0,
        bankedMaterials = {},
        objective = "FREE MARA",
        nightActive = false,
        blackout = { status = "idle" },
        elite = { active = false },
        boss = { active = false },
        survival = { downed = false },
    }
    for key, value in overrides or {} do
        base[key] = value
    end
    return base
end

local function has(cues: { string }, id: string): boolean
    for _, cue in cues do
        if cue == id then
            return true
        end
    end
    return false
end

return {
    name = "SfxCatalog",
    cases = {
        {
            name = "every cue is complete and uses an engine-bundled sound",
            run = function()
                for id, cue in SfxCatalog.Cues do
                    TestRunner.equal(cue.id, id)
                    TestRunner.equal(string.sub(cue.soundId, 1, 9), "rbxasset:")
                    TestRunner.equal(cue.volume > 0 and cue.volume <= 1, true)
                    TestRunner.equal(cue.minSpeed <= cue.maxSpeed, true)
                    TestRunner.equal(cue.cooldown >= 0, true)
                end
                TestRunner.equal(SfxCatalog.get("swing") ~= nil, true)
                TestRunner.equal(SfxCatalog.get("nope"), nil)
            end,
        },
        {
            name = "the first snapshot seeds silently",
            run = function()
                local cues = SfxCatalog.resolveTransitions(
                    nil,
                    snapshot({ nightActive = true, resources = 5 })
                )
                TestRunner.equal(#cues, 0)
            end,
        },
        {
            name = "gaining resources earns a gather, spending them earns nothing",
            run = function()
                local _, signature = SfxCatalog.resolveTransitions(nil, snapshot())
                local cues, next1 =
                    SfxCatalog.resolveTransitions(signature, snapshot({ resources = 3 }))
                TestRunner.equal(has(cues, "gather"), true)
                local spent = SfxCatalog.resolveTransitions(next1, snapshot({ resources = 0 }))
                TestRunner.equal(has(spent, "gather"), false)
            end,
        },
        {
            name = "banking counts the table total",
            run = function()
                local _, signature = SfxCatalog.resolveTransitions(
                    nil,
                    snapshot({ bankedMaterials = { heartwood = 2 } })
                )
                local cues = SfxCatalog.resolveTransitions(
                    signature,
                    snapshot({ bankedMaterials = { heartwood = 2, amber_sap = 1 } })
                )
                TestRunner.equal(has(cues, "bank"), true)
            end,
        },
        {
            name = "a new objective chimes; an empty one stays silent",
            run = function()
                local _, signature = SfxCatalog.resolveTransitions(nil, snapshot())
                local cues = SfxCatalog.resolveTransitions(
                    signature,
                    snapshot({ objective = "GATHER HEARTWOOD" })
                )
                TestRunner.equal(has(cues, "objective"), true)
                local _, signature2 = SfxCatalog.resolveTransitions(nil, snapshot())
                local blank =
                    SfxCatalog.resolveTransitions(signature2, snapshot({ objective = "" }))
                TestRunner.equal(has(blank, "objective"), false)
            end,
        },
        {
            name = "night and blackout and encounters sting on their rising edge only",
            run = function()
                local _, signature = SfxCatalog.resolveTransitions(nil, snapshot())
                local night, nightSignature =
                    SfxCatalog.resolveTransitions(signature, snapshot({ nightActive = true }))
                TestRunner.equal(has(night, "night"), true)
                local still =
                    SfxCatalog.resolveTransitions(nightSignature, snapshot({ nightActive = true }))
                TestRunner.equal(has(still, "night"), false)

                local relay = SfxCatalog.resolveTransitions(
                    nightSignature,
                    snapshot({ nightActive = true, blackout = { status = "relay" } })
                )
                TestRunner.equal(has(relay, "encounter"), true)

                local elite = SfxCatalog.resolveTransitions(
                    nightSignature,
                    snapshot({ nightActive = true, elite = { active = true } })
                )
                TestRunner.equal(has(elite, "encounter"), true)
            end,
        },
        {
            name = "going down and getting up each speak once",
            run = function()
                local _, signature = SfxCatalog.resolveTransitions(nil, snapshot())
                local down, downSignature = SfxCatalog.resolveTransitions(
                    signature,
                    snapshot({ survival = { downed = true } })
                )
                TestRunner.equal(has(down, "downed"), true)
                local up = SfxCatalog.resolveTransitions(
                    downSignature,
                    snapshot({ survival = { downed = false } })
                )
                TestRunner.equal(has(up, "revived"), true)
            end,
        },
    },
}
