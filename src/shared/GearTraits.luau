--!strict

--[[
    Equipment traits -- the M6 "equipment traits" deliverable: gear uses
    authored families with rolled minor traits. Each item TYPE rolls one
    trait per profile at its first craft, deterministically from the
    profile's own creation time and the item id: the same save always
    rolls the same trait for the same item (reproducible, no RNG service,
    fully testable), while two different saves see different rolls -- your
    Amber Edge is not my Amber Edge.

    Traits are minor by charter. Every bonus is a sidegrade-scale nudge
    inside clamps combat already enforces, never a second progression
    axis: rarity and power stay with the families themselves.
]]

local CraftingCatalog = require("./CraftingCatalog")
local Equipment = require("./Equipment")

local GearTraits = {}

export type Trait = {
    id: string,
    displayName: string,
    description: string,
    strikeDamageBonus: number?,
    reachBonus: number?,
    wearPointsOverride: number?,
    damageReductionBonus: number?,
    staminaRegenBonus: number?,
}

local function trait(definition: any): Trait
    return table.freeze(definition)
end

local WEAPON_TRAITS: { Trait } = table.freeze({
    trait({
        id = "trait_keen",
        displayName = "KEEN",
        description = "Strikes land 5% harder.",
        strikeDamageBonus = 0.05,
    }),
    trait({
        id = "trait_balanced",
        displayName = "BALANCED",
        description = "Reaches 2 studs further.",
        reachBonus = 2,
    }),
    trait({
        id = "trait_tempered",
        displayName = "TEMPERED",
        description = "Dulls at half the pace.",
        wearPointsOverride = 1,
    }),
})

local PASSIVE_TRAITS: { Trait } = table.freeze({
    trait({
        id = "trait_sturdy",
        displayName = "STURDY",
        description = "Softens incoming damage 2% more.",
        damageReductionBonus = 0.02,
    }),
    trait({
        id = "trait_light",
        displayName = "LIGHT",
        description = "Stamina returns 5% faster.",
        staminaRegenBonus = 0.05,
    }),
})

local TRAITS_BY_ID: { [string]: Trait } = {}
for _, pool in { WEAPON_TRAITS, PASSIVE_TRAITS } do
    for _, definition in pool do
        TRAITS_BY_ID[definition.id] = definition
    end
end
table.freeze(TRAITS_BY_ID)

local function poolFor(itemId: string): { Trait }?
    local definition = Equipment.get(itemId)
    if definition == nil then
        return nil
    end
    return if definition.slot == "weapon" then WEAPON_TRAITS else PASSIVE_TRAITS
end

local function hash(text: string): number
    local result = 5381
    for index = 1, #text do
        result = (result * 33 + string.byte(text, index)) % 2147483647
    end
    return result
end

function GearTraits.get(traitId: any): Trait?
    return if type(traitId) == "string" then TRAITS_BY_ID[traitId] else nil
end

function GearTraits.isValidFor(itemId: any, traitId: any): boolean
    local pool = if type(itemId) == "string" then poolFor(itemId) else nil
    if pool == nil then
        return false
    end
    for _, definition in pool do
        if definition.id == traitId then
            return true
        end
    end
    return false
end

-- The deterministic roll: same profile + same item = same trait, forever.
function GearTraits.rollFor(itemId: any, profileCreatedAt: any): string?
    local pool = if type(itemId) == "string" then poolFor(itemId) else nil
    if pool == nil or type(profileCreatedAt) ~= "number" then
        return nil
    end
    return pool[hash(itemId .. ":" .. tostring(math.floor(profileCreatedAt))) % #pool + 1].id
end

function GearTraits.normalize(value: any): { [string]: string }
    local traits: { [string]: string } = {}
    if type(value) ~= "table" then
        return traits
    end
    for itemId, traitId in value do
        if CraftingCatalog.isKnownOutputItem(itemId) and GearTraits.isValidFor(itemId, traitId) then
            traits[itemId] = traitId
        end
    end
    return traits
end

return table.freeze(GearTraits)
