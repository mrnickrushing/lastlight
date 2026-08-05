--!strict

local CraftingCatalog = require("../../src/shared/CraftingCatalog")
local Equipment = require("../../src/shared/Equipment")
local TestRunner = require("../TestRunner")

return {
    name = "Equipment",
    cases = {
        {
            name = "the six weapon families each declare a distinct bounded moveset",
            run = function()
                local weaponIds = {}
                for _, entry in Equipment.list() do
                    if entry.slot == "weapon" then
                        table.insert(weaponIds, entry.itemId)
                    end
                end
                TestRunner.equal(#weaponIds, 6)
                local seenKinds = {}
                for _, itemId in weaponIds do
                    local profile = Equipment.weaponStrikeProfile({ weapon = itemId })
                    TestRunner.truthy(profile ~= nil)
                    TestRunner.equal(seenKinds[profile.kind], nil)
                    seenKinds[profile.kind] = true
                    -- Every family stays inside the clamps combat applies:
                    -- damage 0.5-1.5, and only ranged kinds carry a range.
                    TestRunner.truthy(profile.strikeDamageMultiplier >= 0.5)
                    TestRunner.truthy(profile.strikeDamageMultiplier <= 1.5)
                    TestRunner.equal(profile.ranged, profile.strikeRange ~= nil)
                    if profile.onHitStaminaRefund ~= nil then
                        TestRunner.truthy(profile.onHitStaminaRefund <= 12)
                    end
                    if profile.onHitSnareSeconds ~= nil then
                        TestRunner.truthy(profile.onHitSnareSeconds <= 4)
                    end
                end
            end,
        },
        {
            name = "every weapon family is craftable at a bench",
            run = function()
                local craftable = {}
                for _, recipe in CraftingCatalog.list() do
                    craftable[recipe.outputItemId] = true
                end
                for _, entry in Equipment.list() do
                    if entry.slot == "weapon" then
                        TestRunner.truthy(craftable[entry.itemId] == true)
                    end
                end
            end,
        },
        {
            name = "bare hands keep their defaults",
            run = function()
                TestRunner.equal(Equipment.weaponStrikeProfile({}), nil)
            end,
        },
        {
            name = "equips owned passive gear into its slot",
            run = function()
                local equipped, result = Equipment.equip(
                    { gear_ironroot_hood = 1 },
                    {},
                    "gear_ironroot_hood"
                )
                TestRunner.truthy(result.applied)
                TestRunner.equal(equipped.head, "gear_ironroot_hood")
                TestRunner.equal(Equipment.stats(equipped).damageReduction, 0.05)
            end,
        },
        {
            name = "rejects unowned gear without mutating loadout",
            run = function()
                local equipped, result = Equipment.equip({}, {}, "gear_bramble_boots")
                TestRunner.equal(result.applied, false)
                TestRunner.equal(equipped.feet, nil)
            end,
        },
        {
            name = "combines equipped passives by their authoritative slots",
            run = function()
                local stats = Equipment.stats({
                    head = "gear_ironroot_hood",
                    feet = "gear_bramble_boots",
                    body = "gear_ironroot_hood",
                })
                TestRunner.equal(stats.damageReduction, 0.05)
                TestRunner.equal(stats.staminaRegenMultiplier, 1.1)
            end,
        },
    },
}
