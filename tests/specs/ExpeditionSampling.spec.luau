--!strict
--[[
    Mass sampling over the grown module catalog.

    Milestone 5's gate asks for manifest sampling at scale. The CI-sized
    slice lives here: five hundred seeds through the real generator, every
    one held to the validator, plus the properties the validator cannot see
    from one manifest alone — variety across seeds, repetition control, and
    a fallback that never moves. The ten-thousand-seed version of this loop
    is scripts/sample_expedition_manifests.luau, for the gate evidence run.
]]

local ExpeditionGenerator = require("../../src/shared/ExpeditionGenerator")
local Catalog = require("../../src/shared/Content/Definitions/BramblewakeExpedition")
local TestRunner = require("../TestRunner")

local SAMPLE_SEEDS = 500

return {
    name = "ExpeditionSampling",
    cases = {
        {
            name = "the catalog holds the full thirty-module set",
            run = function()
                TestRunner.equal(#Catalog.Modules, 30)
                local arrivals, extractions = 0, 0
                for _, definition in Catalog.Modules do
                    if definition.role == "arrival" then
                        arrivals += 1
                    elseif definition.role == "extraction" then
                        extractions += 1
                    end
                end
                TestRunner.equal(arrivals, 1)
                TestRunner.equal(extractions, 1)
            end,
        },
        {
            name = "five hundred seeds all validate and vary",
            run = function()
                local hashes: { [string]: boolean } = {}
                local distinct = 0
                for seed = 1, SAMPLE_SEEDS do
                    local manifest = ExpeditionGenerator.generate(seed * 7717)
                    local valid, issues = ExpeditionGenerator.validate(manifest)
                    TestRunner.truthy(
                        valid,
                        string.format(
                            "seed %d invalid: %s",
                            seed * 7717,
                            table.concat(issues, "; ")
                        )
                    )
                    TestRunner.equal(#manifest.modules, Catalog.ModuleCount)
                    if not hashes[manifest.hash] then
                        hashes[manifest.hash] = true
                        distinct += 1
                    end
                end
                -- A thirty-module pool choosing twelve should almost never
                -- repeat across five hundred seeds; demanding at least ninety
                -- percent distinct catches a selection collapse without
                -- flaking on honest hash coincidence.
                TestRunner.truthy(
                    distinct >= SAMPLE_SEEDS * 0.9,
                    string.format("only %d distinct manifests in %d seeds", distinct, SAMPLE_SEEDS)
                )
            end,
        },
        {
            name = "every generated run keeps its mandatory spine",
            run = function()
                for seed = 1, 50 do
                    local manifest = ExpeditionGenerator.generate(seed * 104729)
                    local first = manifest.modules[1]
                    local last = manifest.modules[#manifest.modules]
                    TestRunner.equal(
                        ExpeditionGenerator.moduleDefinition(first.moduleId).role,
                        "arrival"
                    )
                    TestRunner.equal(
                        ExpeditionGenerator.moduleDefinition(last.moduleId).role,
                        "extraction"
                    )
                    local hasOldGrowth = false
                    for _, placement in manifest.modules do
                        if placement.moduleId == "module_bw_old_growth_approach" then
                            hasOldGrowth = true
                        end
                    end
                    TestRunner.truthy(hasOldGrowth, "run is missing the Old Growth approach")
                end
            end,
        },
        {
            name = "repetition control avoids a remembered manifest when it can",
            run = function()
                local seed = 424243
                local first = ExpeditionGenerator.generate(seed)
                local avoided = ExpeditionGenerator.generate(seed, false, { [first.hash] = true })
                TestRunner.truthy(
                    avoided.hash ~= first.hash,
                    "generator repeated an avoided manifest with attempts to spare"
                )
                local validAvoided = ExpeditionGenerator.validate(avoided)
                TestRunner.equal(validAvoided, true)
            end,
        },
        {
            name = "validity outranks novelty when everything is avoided",
            run = function()
                local seed = 87178
                local everything: { [string]: boolean } = {}
                for attempt = 1, 8 do
                    local manifest = ExpeditionGenerator.generate(seed + attempt * 977)
                    everything[manifest.hash] = true
                end
                local cornered = ExpeditionGenerator.generate(seed, false, everything)
                local valid = ExpeditionGenerator.validate(cornered)
                TestRunner.equal(valid, true)
            end,
        },
        {
            name = "the known-good fallback never moves",
            run = function()
                local one = ExpeditionGenerator.generate(1, true)
                local two = ExpeditionGenerator.generate(999, true)
                TestRunner.equal(one.source, "known_good_fallback")
                -- Fallback layout is seed-independent by construction; only
                -- the recorded seed differs.
                TestRunner.equal(#one.modules, #two.modules)
                for index, placement in one.modules do
                    TestRunner.equal(placement.moduleId, two.modules[index].moduleId)
                end
            end,
        },
    },
}
