--!strict

local CraftingCatalog = require("../../src/shared/CraftingCatalog")
local DefenseLanes = require("../../src/shared/DefenseLanes")
local ExtractionPayoff = require("../../src/shared/ExtractionPayoff")
local TestRunner = require("../TestRunner")
local TownDecorations = require("../../src/shared/TownDecorations")

return {
    name = "ExtractionPayoff",
    cases = {
        {
            --[[
				`summarize` drops a material it has no presentation for, which
				is right for a pouch -- a payoff carrying something the client
				cannot draw should show the rest rather than nothing. It is
				wrong for a price. A decoration slot priced in a material with
				no label quotes a player a shorter price than it charges, and
				the town square already read `1 heartwood + 3 meadow_fiber` at
				somebody because the prompt sawed the label off the id instead
				of asking here.

				So every material a player is ever quoted a price in is held
				against the labels, in the three places a price is quoted: a
				decoration slot, the snare, and a recipe. Silence here is what
				the drop turns into on a plank.
			]]
            name = "every material a player is quoted a price in has a name",
            run = function()
                local priced: { [string]: string } = {}
                for _, slot in TownDecorations.Slots do
                    for materialId in slot.cost do
                        priced[materialId] = "decoration " .. slot.id
                    end
                end
                for materialId in DefenseLanes.Trap.armCost do
                    priced[materialId] = "the snare"
                end
                for _, recipe in CraftingCatalog.list() do
                    for materialId in recipe.materials do
                        priced[materialId] = "recipe " .. recipe.id
                    end
                end

                local unnamed = {}
                local counted = 0
                for materialId, where in priced do
                    counted += 1
                    local entries = ExtractionPayoff.summarize({ [materialId] = 1 })
                    if #entries ~= 1 or entries[1].label == nil or entries[1].label == "" then
                        table.insert(unnamed, materialId .. " (" .. where .. ")")
                    end
                end

                TestRunner.truthy(counted > 20, "nothing was priced, so nothing was checked")
                TestRunner.equal(
                    #unnamed,
                    0,
                    "priced in a material with no name: " .. table.concat(unnamed, ", ")
                )
            end,
        },
        {
            name = "a price reads in the material's own words, not its id",
            run = function()
                -- SHIP'S IRON is the case that settles it: upper-casing the id
                -- and swapping underscores for spaces gives SHIPS IRON, which
                -- is close enough to look deliberate and wrong every time.
                local entries = ExtractionPayoff.summarize({ material_ships_iron = 2 })
                TestRunner.equal(entries[1].label, "SHIP'S IRON")
                local fiber = ExtractionPayoff.summarize({ material_meadow_fiber = 3 })
                TestRunner.equal(fiber[1].label, "MEADOW FIBER")
            end,
        },
        {
            name = "summarizes every known Bramblewake material",
            run = function()
                local entries, total = ExtractionPayoff.summarize({
                    material_amber_sap = 3,
                    material_brightcap = 2,
                    material_heartwood = 4,
                    material_meadow_fiber = 1,
                })
                TestRunner.equal(#entries, 4)
                TestRunner.equal(total, 10)
            end,
        },
        {
            name = "sorts entries into a deterministic physical layout",
            run = function()
                local entries = ExtractionPayoff.summarize({
                    material_meadow_fiber = 1,
                    material_amber_sap = 1,
                })
                TestRunner.equal(entries[1].id, "material_amber_sap")
                TestRunner.equal(entries[2].id, "material_meadow_fiber")
            end,
        },
        {
            name = "ignores unknown and empty material values",
            run = function()
                local entries, total = ExtractionPayoff.summarize({
                    material_heartwood = 0,
                    material_unknown = 99,
                })
                TestRunner.equal(#entries, 0)
                TestRunner.equal(total, 0)
            end,
        },
        {
            name = "preserves an aggregate banked material total",
            run = function()
                local entries, total = ExtractionPayoff.summarize({ material_heartwood = 1000 })
                TestRunner.equal(entries[1].amount, 1000)
                TestRunner.equal(total, 1000)
            end,
        },
        {
            name = "allocates the first open delivery slot",
            run = function()
                local slot = ExtractionPayoff.firstAvailableSlot({ [1] = true, [3] = true }, 4)
                TestRunner.equal(slot, 2)
            end,
        },
        {
            name = "claims one retained payoff exactly once",
            run = function()
                local owner = {}
                local pending = { [owner] = { materials = { material_heartwood = 4 } } }
                local payoff = ExtractionPayoff.claim(pending, owner)
                TestRunner.equal(payoff.materials.material_heartwood, 4)
                TestRunner.equal(ExtractionPayoff.claim(pending, owner), nil)
            end,
        },
        {
            name = "reports when every delivery slot is occupied",
            run = function()
                local slot = ExtractionPayoff.firstAvailableSlot({ true, true, true }, 3)
                TestRunner.equal(slot, nil)
            end,
        },
    },
}
