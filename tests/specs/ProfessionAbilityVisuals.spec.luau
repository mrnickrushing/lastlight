--!strict

local ProfessionAbilityVisuals = require("../../src/shared/ProfessionAbilityVisuals")
local ProfessionCatalog = require("../../src/shared/ProfessionCatalog")
local TestRunner = require("../TestRunner")

return {
    name = "ProfessionAbilityVisuals",
    cases = {
        {
            name = "covers every playable profession with a distinct motif",
            run = function()
                local motifs = {}
                for _, profession in ProfessionCatalog.list() do
                    local visual = ProfessionAbilityVisuals.get(profession.id)
                    TestRunner.truthy(visual, profession.id .. " has no ability visual")
                    TestRunner.equal(motifs[visual.motif], nil)
                    motifs[visual.motif] = true
                end
                TestRunner.equal(#ProfessionAbilityVisuals.list(), #ProfessionCatalog.list())
            end,
        },
        {
            name = "keeps every effect bounded and color-independent",
            run = function()
                for _, visual in ProfessionAbilityVisuals.list() do
                    TestRunner.truthy(visual.pulseLifetime >= 0.8)
                    TestRunner.truthy(visual.pulseLifetime <= 1.5)
                    TestRunner.truthy(visual.minimumRadius >= 8)
                    TestRunner.truthy(visual.minimumRadius <= 12)
                    TestRunner.equal(#visual.color, 3)
                    TestRunner.equal(#visual.accent, 3)
                    TestRunner.truthy(visual.motif ~= "")
                end
            end,
        },
    },
}
