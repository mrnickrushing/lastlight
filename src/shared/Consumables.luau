--!strict

--[[
    The things a player uses rather than wears.

    This game shipped with two of them, and both were three hardcoded
    branches: one in TutorialService deciding what using it does, one in
    HUDController drawing its button and icon, one in the client deciding
    which id a keypress sends. That is survivable at two and not at
    seventeen, and the recipe count this milestone asks for cannot be met
    honestly while every new consumable needs three files edited in
    agreement.

    So a consumable is data. It names an effect the server already knows
    how to apply, the precondition that must hold before the item is
    spent -- a player must never lose one to a no-op -- and the lines the
    toast says either way. Adding another is one entry here and one
    recipe; nothing in the client or the services learns its name.

    Deliberately not here: the effects themselves. `restore_stamina` is
    PlayerCombatService's job and stays there. This says which effect,
    how much, and what the player is told.
]]

local Strings = require("./Strings")

local Consumables = {}

export type Effect = {
    kind: string,
    amount: number,
    seconds: number?,
    radius: number?,
}

export type Consumable = {
    id: string,
    displayName: string,
    -- Short label for the HUD button, which has room for about eight.
    shortLabel: string,
    accent: { number },
    effect: Effect,
    --[[
        What has to be true before the item is spent. `nil` means the
        effect can always do something. The server owns the check; this
        names it, so a new consumable cannot quietly skip having one.
    ]]
    requires: string?,
    refusedMessage: string?,
    successMessage: string,
}

local function consumable(definition: Consumable): Consumable
    return table.freeze({
        accent = table.freeze(table.clone(definition.accent)),
        displayName = definition.displayName,
        effect = table.freeze(table.clone(definition.effect)),
        id = definition.id,
        refusedMessage = definition.refusedMessage,
        requires = definition.requires,
        shortLabel = definition.shortLabel,
        successMessage = definition.successMessage,
    })
end

--[[
    Three effect kinds, because three is what the services can already
    do: stamina back, a brief shield, and a heal that reaches the people
    standing near you. A fourth kind is a service change, not a catalog
    entry, and that boundary is the point of this file.
]]
local ORDER = table.freeze({
    "gear_meadow_satchel",
    "gear_amber_charm",
    "gear_delve_ration",
    "gear_coalglass_ward",
    "gear_reed_tonic",
    "gear_mirror_ward",
    "gear_fen_poultice",
    "gear_storm_ration",
    "gear_amberglass_ward",
    "gear_reach_poultice",
    "gear_ember_ration",
    "gear_rime_ward",
    "gear_vale_poultice",
    "gear_kiln_ration",
    "gear_cindersteel_ward",
    "gear_crown_poultice",
    -- The answers to threats this game already makes
    "gear_meadow_lantern_oil",
    "gear_meadow_clearwater",
    "gear_meadow_mending_kit",
    "gear_delve_lantern_oil",
    "gear_delve_clearwater",
    "gear_delve_mending_kit",
    "gear_fen_lantern_oil",
    "gear_fen_clearwater",
    "gear_fen_mending_kit",
    "gear_reach_lantern_oil",
    "gear_reach_clearwater",
    "gear_reach_mending_kit",
    "gear_vale_lantern_oil",
    "gear_vale_clearwater",
    "gear_vale_mending_kit",
    "gear_crown_lantern_oil",
    "gear_crown_clearwater",
    "gear_crown_mending_kit",
})

local DEFINITIONS: { [string]: Consumable } = {
    -- The two that were hardcoded. Their numbers and their toast lines are
    -- exactly what they were, so nothing a player already knows changes.
    gear_meadow_satchel = consumable({
        id = "gear_meadow_satchel",
        displayName = Strings.get("world.meadow_satchel"),
        shortLabel = Strings.get("item.satchel"),
        accent = { 133, 176, 108 },
        effect = { kind = "restore_stamina", amount = 50 },
        requires = "stamina_not_full",
        refusedMessage = Strings.get("item.stamina_already_full"),
        successMessage = Strings.get("item.meadow_satchel_stamina_restored"),
    }),
    gear_amber_charm = consumable({
        id = "gear_amber_charm",
        displayName = Strings.get("world.amber_charm"),
        shortLabel = Strings.get("item.charm"),
        accent = { 255, 181, 76 },
        effect = { kind = "shield", amount = 5, seconds = 0.6 },
        requires = nil,
        refusedMessage = nil,
        successMessage = Strings.get("item.amber_charm_shielded"),
    }),

    --[[
        One of each kind per region after that. A ration is stamina, a
        ward is a shield, a poultice reaches the people near you -- and
        the deeper the region the more it gives, which is the only thing
        region depth is used for here.
    ]]
    gear_delve_ration = consumable({
        id = "gear_delve_ration",
        displayName = Strings.get("item.delve_ration"),
        shortLabel = Strings.get("item.ration"),
        accent = { 196, 142, 58 },
        effect = { kind = "restore_stamina", amount = 60 },
        requires = "stamina_not_full",
        refusedMessage = Strings.get("item.stamina_already_full"),
        successMessage = Strings.get("item.delve_ration_stamina_restored"),
    }),
    gear_coalglass_ward = consumable({
        id = "gear_coalglass_ward",
        displayName = Strings.get("item.coalglass_ward"),
        shortLabel = Strings.get("item.ward"),
        accent = { 255, 168, 66 },
        effect = { kind = "shield", amount = 7, seconds = 0.7 },
        successMessage = Strings.get("item.coalglass_ward_shielded"),
    }),
    gear_reed_tonic = consumable({
        id = "gear_reed_tonic",
        displayName = Strings.get("item.reed_tonic"),
        shortLabel = Strings.get("item.tonic"),
        accent = { 146, 214, 226 },
        effect = { kind = "restore_stamina", amount = 70 },
        requires = "stamina_not_full",
        refusedMessage = Strings.get("item.stamina_already_full"),
        successMessage = Strings.get("item.reed_tonic_stamina_restored"),
    }),
    gear_mirror_ward = consumable({
        id = "gear_mirror_ward",
        displayName = Strings.get("item.mirror_ward"),
        shortLabel = Strings.get("item.mirror"),
        accent = { 146, 214, 226 },
        effect = { kind = "shield", amount = 8, seconds = 0.8 },
        successMessage = Strings.get("item.mirror_ward_shielded"),
    }),
    gear_fen_poultice = consumable({
        id = "gear_fen_poultice",
        displayName = Strings.get("item.fen_poultice"),
        shortLabel = Strings.get("item.poultice"),
        accent = { 120, 186, 140 },
        effect = { kind = "heal_party", amount = 20, radius = 18 },
        requires = "someone_hurt_nearby",
        refusedMessage = Strings.get("tutorial.nobody_near_you_needs_it"),
        successMessage = Strings.get("item.fen_poultice_the_party_is_patched"),
    }),
    gear_storm_ration = consumable({
        id = "gear_storm_ration",
        displayName = Strings.get("item.storm_ration"),
        shortLabel = Strings.get("item.ration"),
        accent = { 238, 178, 96 },
        effect = { kind = "restore_stamina", amount = 80 },
        requires = "stamina_not_full",
        refusedMessage = Strings.get("item.stamina_already_full"),
        successMessage = Strings.get("item.storm_ration_stamina_restored"),
    }),
    gear_amberglass_ward = consumable({
        id = "gear_amberglass_ward",
        displayName = Strings.get("item.amberglass_ward"),
        shortLabel = Strings.get("item.ward"),
        accent = { 238, 178, 96 },
        effect = { kind = "shield", amount = 9, seconds = 0.9 },
        successMessage = Strings.get("item.amberglass_ward_shielded"),
    }),
    gear_reach_poultice = consumable({
        id = "gear_reach_poultice",
        displayName = Strings.get("item.reach_poultice"),
        shortLabel = Strings.get("item.poultice"),
        accent = { 120, 186, 140 },
        effect = { kind = "heal_party", amount = 26, radius = 20 },
        requires = "someone_hurt_nearby",
        refusedMessage = Strings.get("tutorial.nobody_near_you_needs_it"),
        successMessage = Strings.get("item.reach_poultice_the_party_is_patched"),
    }),
    gear_ember_ration = consumable({
        id = "gear_ember_ration",
        displayName = Strings.get("item.ember_ration"),
        shortLabel = Strings.get("item.ration"),
        accent = { 238, 128, 54 },
        effect = { kind = "restore_stamina", amount = 90 },
        requires = "stamina_not_full",
        refusedMessage = Strings.get("item.stamina_already_full"),
        successMessage = Strings.get("item.ember_ration_stamina_restored"),
    }),
    gear_rime_ward = consumable({
        id = "gear_rime_ward",
        displayName = Strings.get("item.rime_ward"),
        shortLabel = Strings.get("item.ward"),
        accent = { 168, 202, 216 },
        effect = { kind = "shield", amount = 10, seconds = 1 },
        successMessage = Strings.get("item.rime_ward_shielded"),
    }),
    gear_vale_poultice = consumable({
        id = "gear_vale_poultice",
        displayName = Strings.get("item.vale_poultice"),
        shortLabel = Strings.get("item.poultice"),
        accent = { 120, 186, 140 },
        effect = { kind = "heal_party", amount = 32, radius = 22 },
        requires = "someone_hurt_nearby",
        refusedMessage = Strings.get("tutorial.nobody_near_you_needs_it"),
        successMessage = Strings.get("item.vale_poultice_the_party_is_patched"),
    }),
    gear_kiln_ration = consumable({
        id = "gear_kiln_ration",
        displayName = Strings.get("item.kiln_ration"),
        shortLabel = Strings.get("item.ration"),
        accent = { 214, 172, 88 },
        effect = { kind = "restore_stamina", amount = 100 },
        requires = "stamina_not_full",
        refusedMessage = Strings.get("item.stamina_already_full"),
        successMessage = Strings.get("item.kiln_ration_stamina_restored"),
    }),
    gear_cindersteel_ward = consumable({
        id = "gear_cindersteel_ward",
        displayName = Strings.get("item.cindersteel_ward"),
        shortLabel = Strings.get("item.ward"),
        accent = { 148, 142, 134 },
        effect = { kind = "shield", amount = 12, seconds = 1.1 },
        successMessage = Strings.get("item.cindersteel_ward_shielded"),
    }),
    gear_crown_poultice = consumable({
        id = "gear_crown_poultice",
        displayName = Strings.get("item.crown_poultice"),
        shortLabel = Strings.get("item.poultice"),
        accent = { 120, 186, 140 },
        effect = { kind = "heal_party", amount = 38, radius = 24 },
        requires = "someone_hurt_nearby",
        refusedMessage = Strings.get("tutorial.nobody_near_you_needs_it"),
        successMessage = Strings.get("item.crown_poultice_the_party_is_patched"),
    }),
    gear_meadow_lantern_oil = consumable({
        id = "gear_meadow_lantern_oil",
        displayName = Strings.get("item.meadow_lantern_oil"),
        shortLabel = "OIL",
        accent = { 255, 216, 150 },
        effect = { kind = "restore_lantern", amount = 14 },
        requires = "lantern_not_full",
        refusedMessage = Strings.get("tutorial.the_lantern_is_already_full"),
        successMessage = Strings.get("item.meadow_lantern_oil_the_light_comes"),
    }),
    gear_meadow_clearwater = consumable({
        id = "gear_meadow_clearwater",
        displayName = Strings.get("item.meadow_clearwater"),
        shortLabel = Strings.get("town.clear"),
        accent = { 176, 226, 236 },
        effect = { kind = "cure_status", amount = 1 },
        requires = "status_active",
        refusedMessage = Strings.get("tutorial.nothing_is_on_you"),
        successMessage = Strings.get("item.meadow_clearwater_your_head_clears"),
    }),
    gear_meadow_mending_kit = consumable({
        id = "gear_meadow_mending_kit",
        displayName = Strings.get("item.meadow_mending_kit"),
        shortLabel = Strings.get("item.mend"),
        accent = { 186, 168, 132 },
        effect = { kind = "repair_gear", amount = 1 },
        requires = "gear_worn",
        refusedMessage = Strings.get("tutorial.nothing_needs_mending"),
        successMessage = Strings.get("item.meadow_mending_kit_the_worst_of"),
    }),
    gear_delve_lantern_oil = consumable({
        id = "gear_delve_lantern_oil",
        displayName = Strings.get("item.delve_lantern_oil"),
        shortLabel = "OIL",
        accent = { 255, 216, 150 },
        effect = { kind = "restore_lantern", amount = 18 },
        requires = "lantern_not_full",
        refusedMessage = Strings.get("tutorial.the_lantern_is_already_full"),
        successMessage = Strings.get("item.delve_lantern_oil_the_light_comes"),
    }),
    gear_delve_clearwater = consumable({
        id = "gear_delve_clearwater",
        displayName = Strings.get("item.delve_clearwater"),
        shortLabel = Strings.get("town.clear"),
        accent = { 176, 226, 236 },
        effect = { kind = "cure_status", amount = 1 },
        requires = "status_active",
        refusedMessage = Strings.get("tutorial.nothing_is_on_you"),
        successMessage = Strings.get("item.delve_clearwater_your_head_clears"),
    }),
    gear_delve_mending_kit = consumable({
        id = "gear_delve_mending_kit",
        displayName = Strings.get("item.delve_mending_kit"),
        shortLabel = Strings.get("item.mend"),
        accent = { 186, 168, 132 },
        effect = { kind = "repair_gear", amount = 1 },
        requires = "gear_worn",
        refusedMessage = Strings.get("tutorial.nothing_needs_mending"),
        successMessage = Strings.get("item.delve_mending_kit_the_worst_of"),
    }),
    gear_fen_lantern_oil = consumable({
        id = "gear_fen_lantern_oil",
        displayName = Strings.get("item.fen_lantern_oil"),
        shortLabel = "OIL",
        accent = { 255, 216, 150 },
        effect = { kind = "restore_lantern", amount = 22 },
        requires = "lantern_not_full",
        refusedMessage = Strings.get("tutorial.the_lantern_is_already_full"),
        successMessage = Strings.get("item.fen_lantern_oil_the_light_comes"),
    }),
    gear_fen_clearwater = consumable({
        id = "gear_fen_clearwater",
        displayName = Strings.get("item.fen_clearwater"),
        shortLabel = Strings.get("town.clear"),
        accent = { 176, 226, 236 },
        effect = { kind = "cure_status", amount = 1 },
        requires = "status_active",
        refusedMessage = Strings.get("tutorial.nothing_is_on_you"),
        successMessage = Strings.get("item.fen_clearwater_your_head_clears"),
    }),
    gear_fen_mending_kit = consumable({
        id = "gear_fen_mending_kit",
        displayName = Strings.get("item.fen_mending_kit"),
        shortLabel = Strings.get("item.mend"),
        accent = { 186, 168, 132 },
        effect = { kind = "repair_gear", amount = 1 },
        requires = "gear_worn",
        refusedMessage = Strings.get("tutorial.nothing_needs_mending"),
        successMessage = Strings.get("item.fen_mending_kit_the_worst_of"),
    }),
    gear_reach_lantern_oil = consumable({
        id = "gear_reach_lantern_oil",
        displayName = Strings.get("item.reach_lantern_oil"),
        shortLabel = "OIL",
        accent = { 255, 216, 150 },
        effect = { kind = "restore_lantern", amount = 26 },
        requires = "lantern_not_full",
        refusedMessage = Strings.get("tutorial.the_lantern_is_already_full"),
        successMessage = Strings.get("item.reach_lantern_oil_the_light_comes"),
    }),
    gear_reach_clearwater = consumable({
        id = "gear_reach_clearwater",
        displayName = Strings.get("item.reach_clearwater"),
        shortLabel = Strings.get("town.clear"),
        accent = { 176, 226, 236 },
        effect = { kind = "cure_status", amount = 1 },
        requires = "status_active",
        refusedMessage = Strings.get("tutorial.nothing_is_on_you"),
        successMessage = Strings.get("item.reach_clearwater_your_head_clears"),
    }),
    gear_reach_mending_kit = consumable({
        id = "gear_reach_mending_kit",
        displayName = Strings.get("item.reach_mending_kit"),
        shortLabel = Strings.get("item.mend"),
        accent = { 186, 168, 132 },
        effect = { kind = "repair_gear", amount = 1 },
        requires = "gear_worn",
        refusedMessage = Strings.get("tutorial.nothing_needs_mending"),
        successMessage = Strings.get("item.reach_mending_kit_the_worst_of"),
    }),
    gear_vale_lantern_oil = consumable({
        id = "gear_vale_lantern_oil",
        displayName = Strings.get("item.vale_lantern_oil"),
        shortLabel = "OIL",
        accent = { 255, 216, 150 },
        effect = { kind = "restore_lantern", amount = 30 },
        requires = "lantern_not_full",
        refusedMessage = Strings.get("tutorial.the_lantern_is_already_full"),
        successMessage = Strings.get("item.vale_lantern_oil_the_light_comes"),
    }),
    gear_vale_clearwater = consumable({
        id = "gear_vale_clearwater",
        displayName = Strings.get("item.vale_clearwater"),
        shortLabel = Strings.get("town.clear"),
        accent = { 176, 226, 236 },
        effect = { kind = "cure_status", amount = 1 },
        requires = "status_active",
        refusedMessage = Strings.get("tutorial.nothing_is_on_you"),
        successMessage = Strings.get("item.vale_clearwater_your_head_clears"),
    }),
    gear_vale_mending_kit = consumable({
        id = "gear_vale_mending_kit",
        displayName = Strings.get("item.vale_mending_kit"),
        shortLabel = Strings.get("item.mend"),
        accent = { 186, 168, 132 },
        effect = { kind = "repair_gear", amount = 1 },
        requires = "gear_worn",
        refusedMessage = Strings.get("tutorial.nothing_needs_mending"),
        successMessage = Strings.get("item.vale_mending_kit_the_worst_of"),
    }),
    gear_crown_lantern_oil = consumable({
        id = "gear_crown_lantern_oil",
        displayName = Strings.get("item.crown_lantern_oil"),
        shortLabel = "OIL",
        accent = { 255, 216, 150 },
        effect = { kind = "restore_lantern", amount = 34 },
        requires = "lantern_not_full",
        refusedMessage = Strings.get("tutorial.the_lantern_is_already_full"),
        successMessage = Strings.get("item.crown_lantern_oil_the_light_comes"),
    }),
    gear_crown_clearwater = consumable({
        id = "gear_crown_clearwater",
        displayName = Strings.get("item.crown_clearwater"),
        shortLabel = Strings.get("town.clear"),
        accent = { 176, 226, 236 },
        effect = { kind = "cure_status", amount = 1 },
        requires = "status_active",
        refusedMessage = Strings.get("tutorial.nothing_is_on_you"),
        successMessage = Strings.get("item.crown_clearwater_your_head_clears"),
    }),
    gear_crown_mending_kit = consumable({
        id = "gear_crown_mending_kit",
        displayName = Strings.get("item.crown_mending_kit"),
        shortLabel = Strings.get("item.mend"),
        accent = { 186, 168, 132 },
        effect = { kind = "repair_gear", amount = 1 },
        requires = "gear_worn",
        refusedMessage = Strings.get("tutorial.nothing_needs_mending"),
        successMessage = Strings.get("item.crown_mending_kit_the_worst_of"),
    }),
}

Consumables.Order = ORDER
--[[
    Six effect kinds, and every one of them answers something this game
    already does to a player. Stamina and a shield and a party heal were
    the first three. The other three exist because the spark thieves take
    the lantern, the drowsy strikers take your footing, and gear wears out
    a long way from the only bench that could fix it -- three threats the
    game had been making with no answer a player could carry.
]]
Consumables.EffectKinds = table.freeze({
    "restore_stamina",
    "shield",
    "heal_party",
    "restore_lantern",
    "cure_status",
    "repair_gear",
})

function Consumables.get(itemId: any): Consumable?
    return if type(itemId) == "string" then DEFINITIONS[itemId] else nil
end

function Consumables.isKnown(itemId: any): boolean
    return Consumables.get(itemId) ~= nil
end

function Consumables.list(): { Consumable }
    local result: { Consumable } = {}
    for _, itemId in ORDER do
        table.insert(result, DEFINITIONS[itemId])
    end
    return result
end

return table.freeze(Consumables)
