--!strict
--[[
    The Milestone 5 gate's manifest sampling run: ten thousand seeds through
    the real generator, every manifest held to the validator, with variety
    and spine checks. The CI suite runs the five-hundred-seed slice of this
    same loop (tests/specs/ExpeditionSampling.spec.luau); this script is the
    full-scale evidence pass, run on demand:

        lune run scripts/sample_expedition_manifests

    Exit is nonzero on any failure so the run can gate a release script.
]]

local ExpeditionGenerator = require("../src/shared/ExpeditionGenerator")
local Catalog = require("../src/shared/Content/Definitions/BramblewakeExpedition")

local SEEDS = 10_000

local failures = 0
local hashes: { [string]: boolean } = {}
local distinct = 0
local missingSpine = 0

for index = 1, SEEDS do
    local seed = index * 7717
    local manifest = ExpeditionGenerator.generate(seed)
    local valid, issues = ExpeditionGenerator.validate(manifest)
    if not valid then
        failures += 1
        if failures <= 10 then
            print(string.format("INVALID seed %d: %s", seed, table.concat(issues, "; ")))
        end
    end
    if #manifest.modules ~= Catalog.ModuleCount then
        failures += 1
    end
    local hasOldGrowth = false
    for _, placement in manifest.modules do
        if placement.moduleId == "module_bw_old_growth_approach" then
            hasOldGrowth = true
            break
        end
    end
    if not hasOldGrowth then
        missingSpine += 1
    end
    if not hashes[manifest.hash] then
        hashes[manifest.hash] = true
        distinct += 1
    end
    if index % 1000 == 0 then
        print(string.format("sampled %d / %d (distinct %d)", index, SEEDS, distinct))
    end
end

print(
    string.format(
        "manifest sampling: %d seeds, %d invalid, %d missing spine, %d distinct layouts",
        SEEDS,
        failures,
        missingSpine,
        distinct
    )
)

if failures > 0 or missingSpine > 0 then
    error("manifest sampling failed")
end
if distinct < SEEDS * 0.9 then
    error(string.format("variety collapse: only %d distinct layouts in %d seeds", distinct, SEEDS))
end
print("manifest sampling PASSED")
