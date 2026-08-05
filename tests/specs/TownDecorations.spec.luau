--!strict

local SaveSchema = require("../../src/shared/SaveSchema")
local TownDecorations = require("../../src/shared/TownDecorations")
local TestRunner = require("../TestRunner")

return {
    name = "TownDecorations",
    cases = {
        {
            name = "every slot is complete and costs real materials",
            run = function()
                TestRunner.equal(#TownDecorations.Slots >= 8, true)
                for _, slot in TownDecorations.Slots do
                    TestRunner.equal(TownDecorations.slot(slot.id), slot)
                    TestRunner.equal(#slot.displayName > 0, true)
                    local costs = 0
                    for materialId, amount in slot.cost do
                        TestRunner.equal(string.sub(materialId, 1, 9), "material_")
                        TestRunner.equal(amount > 0, true)
                        costs += 1
                    end
                    TestRunner.equal(costs > 0, true)
                end
            end,
        },
        {
            name = "the cap grows with tier and stays below the slot count",
            run = function()
                TestRunner.equal(TownDecorations.capForTier(0), 2)
                TestRunner.equal(TownDecorations.capForTier(3), 8)
                TestRunner.equal(TownDecorations.capForTier(99), 8)
                TestRunner.equal(TownDecorations.capForTier(3) <= #TownDecorations.Slots, true)
            end,
        },
        {
            name = "placement charges the wallet exactly once and is idempotent",
            run = function()
                local wallet = { material_meadow_fiber = 5, material_heartwood = 3 }
                local nextWallet, state, result = TownDecorations.place(
                    wallet,
                    TownDecorations.default(),
                    "decor_plaza_banner_east",
                    1
                )
                TestRunner.equal(result.applied, true)
                TestRunner.equal(nextWallet.material_meadow_fiber, 2)
                TestRunner.equal(nextWallet.material_heartwood, 2)
                TestRunner.equal(wallet.material_meadow_fiber, 5)

                local _, _, again =
                    TownDecorations.place(nextWallet, state, "decor_plaza_banner_east", 1)
                TestRunner.equal(again.applied, false)
                TestRunner.equal(again.reason, "already_placed")
            end,
        },
        {
            name = "refusals never mutate: cap, funds, unknown",
            run = function()
                local wallet = {
                    material_meadow_fiber = 100,
                    material_heartwood = 100,
                    material_brightcap = 100,
                    material_amber_sap = 100,
                }
                local state = TownDecorations.default()
                -- Fill to the tier-0 cap of two.
                wallet, state = TownDecorations.place(wallet, state, "decor_plaza_banner_east", 0)
                wallet, state = TownDecorations.place(wallet, state, "decor_plaza_banner_west", 0)
                TestRunner.equal(TownDecorations.count(state), 2)
                local cappedWallet, cappedState, capped =
                    TownDecorations.place(wallet, state, "decor_planter_gate", 0)
                TestRunner.equal(capped.reason, "decoration_cap")
                TestRunner.equal(cappedWallet, wallet)
                TestRunner.equal(cappedState, state)

                local _, _, poor = TownDecorations.place(
                    { material_heartwood = 0 },
                    TownDecorations.default(),
                    "decor_planter_gate",
                    3
                )
                TestRunner.equal(poor.reason, "insufficient_materials")

                local _, _, unknown =
                    TownDecorations.place({}, TownDecorations.default(), "decor_nope", 3)
                TestRunner.equal(unknown.reason, "unknown_decoration")
            end,
        },
        {
            name = "shared towns keep both players' decorations",
            run = function()
                local merged = TownDecorations.merge(
                    { decor_plaza_banner_east = true, decor_bogus = true },
                    { decor_planter_inn = true }
                )
                TestRunner.equal(merged.decor_plaza_banner_east, true)
                TestRunner.equal(merged.decor_planter_inn, true)
                TestRunner.equal((merged :: any).decor_bogus, nil)
            end,
        },
        {
            name = "the profile transaction persists and reloads",
            run = function()
                local profile = SaveSchema.normalize(nil, 100)
                TestRunner.equal(profile.schemaVersion, 17)
                profile.inventory.materials.material_meadow_fiber = 6
                profile.inventory.materials.material_heartwood = 4
                local placed, result =
                    SaveSchema.withPlacedDecoration(profile, "decor_plaza_banner_east", 101)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(placed.revision, profile.revision + 1)
                local reloaded = SaveSchema.normalize(placed, 102)
                TestRunner.equal(reloaded.town.decorations.decor_plaza_banner_east, true)
                local snapshot = SaveSchema.decorationsSnapshot(reloaded)
                TestRunner.equal(snapshot.count, 1)
                TestRunner.equal(snapshot.cap >= 2, true)
            end,
        },
    },
}
