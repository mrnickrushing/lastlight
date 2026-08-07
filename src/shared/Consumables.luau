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
})

local DEFINITIONS: { [string]: Consumable } = {
    -- The two that were hardcoded. Their numbers and their toast lines are
    -- exactly what they were, so nothing a player already knows changes.
    gear_meadow_satchel = consumable({
        id = "gear_meadow_satchel",
        displayName = "MEADOW SATCHEL",
        shortLabel = "SATCHEL",
        accent = { 133, 176, 108 },
        effect = { kind = "restore_stamina", amount = 50 },
        requires = "stamina_not_full",
        refusedMessage = "STAMINA ALREADY FULL",
        successMessage = "MEADOW SATCHEL — STAMINA RESTORED",
    }),
    gear_amber_charm = consumable({
        id = "gear_amber_charm",
        displayName = "AMBER CHARM",
        shortLabel = "CHARM",
        accent = { 255, 181, 76 },
        effect = { kind = "shield", amount = 5, seconds = 0.6 },
        requires = nil,
        refusedMessage = nil,
        successMessage = "AMBER CHARM — SHIELDED",
    }),

    --[[
        One of each kind per region after that. A ration is stamina, a
        ward is a shield, a poultice reaches the people near you -- and
        the deeper the region the more it gives, which is the only thing
        region depth is used for here.
    ]]
    gear_delve_ration = consumable({
        id = "gear_delve_ration",
        displayName = "DELVE RATION",
        shortLabel = "RATION",
        accent = { 196, 142, 58 },
        effect = { kind = "restore_stamina", amount = 60 },
        requires = "stamina_not_full",
        refusedMessage = "STAMINA ALREADY FULL",
        successMessage = "DELVE RATION — STAMINA RESTORED",
    }),
    gear_coalglass_ward = consumable({
        id = "gear_coalglass_ward",
        displayName = "COALGLASS WARD",
        shortLabel = "WARD",
        accent = { 255, 168, 66 },
        effect = { kind = "shield", amount = 7, seconds = 0.7 },
        successMessage = "COALGLASS WARD — SHIELDED",
    }),
    gear_reed_tonic = consumable({
        id = "gear_reed_tonic",
        displayName = "REED TONIC",
        shortLabel = "TONIC",
        accent = { 146, 214, 226 },
        effect = { kind = "restore_stamina", amount = 70 },
        requires = "stamina_not_full",
        refusedMessage = "STAMINA ALREADY FULL",
        successMessage = "REED TONIC — STAMINA RESTORED",
    }),
    gear_mirror_ward = consumable({
        id = "gear_mirror_ward",
        displayName = "MIRROR WARD",
        shortLabel = "MIRROR",
        accent = { 146, 214, 226 },
        effect = { kind = "shield", amount = 8, seconds = 0.8 },
        successMessage = "MIRROR WARD — SHIELDED",
    }),
    gear_fen_poultice = consumable({
        id = "gear_fen_poultice",
        displayName = "FEN POULTICE",
        shortLabel = "POULTICE",
        accent = { 120, 186, 140 },
        effect = { kind = "heal_party", amount = 20, radius = 18 },
        requires = "someone_hurt_nearby",
        refusedMessage = "NOBODY NEAR YOU NEEDS IT",
        successMessage = "FEN POULTICE — THE PARTY IS PATCHED UP",
    }),
    gear_storm_ration = consumable({
        id = "gear_storm_ration",
        displayName = "STORM RATION",
        shortLabel = "RATION",
        accent = { 238, 178, 96 },
        effect = { kind = "restore_stamina", amount = 80 },
        requires = "stamina_not_full",
        refusedMessage = "STAMINA ALREADY FULL",
        successMessage = "STORM RATION — STAMINA RESTORED",
    }),
    gear_amberglass_ward = consumable({
        id = "gear_amberglass_ward",
        displayName = "AMBERGLASS WARD",
        shortLabel = "WARD",
        accent = { 238, 178, 96 },
        effect = { kind = "shield", amount = 9, seconds = 0.9 },
        successMessage = "AMBERGLASS WARD — SHIELDED",
    }),
    gear_reach_poultice = consumable({
        id = "gear_reach_poultice",
        displayName = "REACH POULTICE",
        shortLabel = "POULTICE",
        accent = { 120, 186, 140 },
        effect = { kind = "heal_party", amount = 26, radius = 20 },
        requires = "someone_hurt_nearby",
        refusedMessage = "NOBODY NEAR YOU NEEDS IT",
        successMessage = "REACH POULTICE — THE PARTY IS PATCHED UP",
    }),
    gear_ember_ration = consumable({
        id = "gear_ember_ration",
        displayName = "EMBER RATION",
        shortLabel = "RATION",
        accent = { 238, 128, 54 },
        effect = { kind = "restore_stamina", amount = 90 },
        requires = "stamina_not_full",
        refusedMessage = "STAMINA ALREADY FULL",
        successMessage = "EMBER RATION — STAMINA RESTORED",
    }),
    gear_rime_ward = consumable({
        id = "gear_rime_ward",
        displayName = "RIME WARD",
        shortLabel = "WARD",
        accent = { 168, 202, 216 },
        effect = { kind = "shield", amount = 10, seconds = 1 },
        successMessage = "RIME WARD — SHIELDED",
    }),
    gear_vale_poultice = consumable({
        id = "gear_vale_poultice",
        displayName = "VALE POULTICE",
        shortLabel = "POULTICE",
        accent = { 120, 186, 140 },
        effect = { kind = "heal_party", amount = 32, radius = 22 },
        requires = "someone_hurt_nearby",
        refusedMessage = "NOBODY NEAR YOU NEEDS IT",
        successMessage = "VALE POULTICE — THE PARTY IS PATCHED UP",
    }),
    gear_kiln_ration = consumable({
        id = "gear_kiln_ration",
        displayName = "KILN RATION",
        shortLabel = "RATION",
        accent = { 214, 172, 88 },
        effect = { kind = "restore_stamina", amount = 100 },
        requires = "stamina_not_full",
        refusedMessage = "STAMINA ALREADY FULL",
        successMessage = "KILN RATION — STAMINA RESTORED",
    }),
    gear_cindersteel_ward = consumable({
        id = "gear_cindersteel_ward",
        displayName = "CINDERSTEEL WARD",
        shortLabel = "WARD",
        accent = { 148, 142, 134 },
        effect = { kind = "shield", amount = 12, seconds = 1.1 },
        successMessage = "CINDERSTEEL WARD — SHIELDED",
    }),
    gear_crown_poultice = consumable({
        id = "gear_crown_poultice",
        displayName = "CROWN POULTICE",
        shortLabel = "POULTICE",
        accent = { 120, 186, 140 },
        effect = { kind = "heal_party", amount = 38, radius = 24 },
        requires = "someone_hurt_nearby",
        refusedMessage = "NOBODY NEAR YOU NEEDS IT",
        successMessage = "CROWN POULTICE — THE PARTY IS PATCHED UP",
    }),
}

Consumables.Order = ORDER
Consumables.EffectKinds = table.freeze({ "restore_stamina", "shield", "heal_party" })

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
