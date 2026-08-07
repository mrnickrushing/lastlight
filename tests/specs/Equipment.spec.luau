--!strict

local CraftingCatalog = require("../../src/shared/CraftingCatalog")
local Equipment = require("../../src/shared/Equipment")
local TestRunner = require("../TestRunner")

return {
    name = "Equipment",
    cases = {
        {
            --[[
                Six families, one per region, so thirty-six weapons. The
                count is asserted because the interesting failure is a
                region that quietly lost a family -- a player who reaches
                the Vale and finds it has no bow.
            ]]
            name = "the six weapon families each declare a distinct bounded moveset",
            run = function()
                local weaponIds = {}
                for _, entry in Equipment.list() do
                    if entry.slot == "weapon" then
                        table.insert(weaponIds, entry.itemId)
                    end
                end
                TestRunner.equal(#weaponIds, 36)
                local perKind: { [string]: number } = {}
                for _, itemId in weaponIds do
                    local profile = Equipment.weaponStrikeProfile({ weapon = itemId })
                    TestRunner.truthy(profile ~= nil)
                    perKind[profile.kind] = (perKind[profile.kind] or 0) + 1
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
                local families = 0
                for kind, count in perKind do
                    families += 1
                    TestRunner.equal(count, 6, kind .. " is not in every region")
                end
                TestRunner.equal(families, 6)
            end,
        },
        {
            --[[
                A region is an axis here, not a tier, and the check that
                keeps that honest is that no two regions' versions of a
                family are the same item. If they were, the set would be
                thirty extra names for six weapons.
            ]]
            name = "no two regions' versions of a family are the same weapon",
            run = function()
                local byKind: { [string]: { any } } = {}
                for _, entry in Equipment.list() do
                    if entry.slot == "weapon" then
                        local definition = Equipment.get(entry.itemId)
                        local kind = tostring(definition.kind)
                        byKind[kind] = byKind[kind] or {}
                        table.insert(byKind[kind], definition)
                    end
                end
                for kind, definitions in byKind do
                    local seen: { [string]: boolean } = {}
                    for _, definition in definitions do
                        local fingerprint = string.format(
                            "%s|%s|%s|%s|%s|%s",
                            tostring(definition.strikeDamageMultiplier),
                            tostring(definition.strikeRange),
                            tostring(definition.meleeReach),
                            tostring(definition.damageReduction),
                            tostring(definition.staminaRegenMultiplier),
                            tostring(definition.onHitStaminaRefund)
                        )
                        TestRunner.equal(
                            seen[fingerprint],
                            nil,
                            kind .. " has two regions with identical numbers"
                        )
                        seen[fingerprint] = true
                    end
                end
            end,
        },
        {
            -- Armour is two lines rather than a ladder, and every slot has
            -- to offer both or a player is forced into one way to survive.
            name = "every armour slot offers a light line and a heavy line",
            run = function()
                local light: { [string]: number } = {}
                local heavy: { [string]: number } = {}
                for _, entry in Equipment.list() do
                    if entry.slot ~= "weapon" then
                        local definition = Equipment.get(entry.itemId)
                        if definition.staminaRegenMultiplier > 1 then
                            light[entry.slot] = (light[entry.slot] or 0) + 1
                        end
                        if definition.damageReduction > 0 then
                            heavy[entry.slot] = (heavy[entry.slot] or 0) + 1
                        end
                        -- nothing may do both, and nothing may do neither
                        TestRunner.truthy(
                            (definition.staminaRegenMultiplier > 1)
                                ~= (definition.damageReduction > 0),
                            entry.itemId .. " is on both lines or neither"
                        )
                        TestRunner.truthy(definition.damageReduction <= 0.25)
                        TestRunner.truthy(definition.staminaRegenMultiplier <= 1.25)
                    end
                end
                for _, slot in { "head", "body", "hands", "feet", "charm" } do
                    TestRunner.truthy(light[slot] ~= nil, slot .. " has no light line")
                    TestRunner.truthy(heavy[slot] ~= nil, slot .. " has no heavy line")
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
