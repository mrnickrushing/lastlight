--!strict

local Consumables = require("../../src/shared/Consumables")
local CraftingCatalog = require("../../src/shared/CraftingCatalog")
local Equipment = require("../../src/shared/Equipment")
local ExpeditionInventory = require("../../src/shared/ExpeditionInventory")
local TestRunner = require("../TestRunner")

local KNOWN_REQUIREMENTS = table.freeze({
    gear_worn = true,
    lantern_not_full = true,
    someone_hurt_nearby = true,
    stamina_not_full = true,
    status_active = true,
})

return {
    name = "Consumables",
    cases = {
        {
            --[[
                The point of the catalog is that adding one is data. This
                is the check that keeps it that way: every entry has to be
                complete enough for the server to apply it and the HUD to
                draw it without either of them knowing its name.
            ]]
            name = "every consumable is complete enough to be used without code",
            run = function()
                local kinds: { [string]: boolean } = {}
                for _, kind in Consumables.EffectKinds do
                    kinds[kind] = true
                end
                local seen: { [string]: boolean } = {}
                for _, definition in Consumables.list() do
                    TestRunner.equal(seen[definition.id], nil, "duplicate " .. definition.id)
                    seen[definition.id] = true
                    TestRunner.truthy(#definition.displayName > 4, definition.id .. " is unnamed")
                    TestRunner.truthy(
                        #definition.shortLabel > 2 and #definition.shortLabel <= 9,
                        definition.id .. " has no HUD-sized label"
                    )
                    TestRunner.equal(#definition.accent, 3, definition.id .. " has no colour")
                    TestRunner.truthy(
                        kinds[definition.effect.kind],
                        definition.id
                            .. " names an effect nothing applies: "
                            .. definition.effect.kind
                    )
                    TestRunner.truthy(
                        definition.effect.amount > 0,
                        definition.id .. " does nothing"
                    )
                    TestRunner.truthy(
                        #definition.successMessage > 12,
                        definition.id .. " says nothing when it works"
                    )
                    --[[
                        A precondition without a line is worse than none:
                        the item is refused and the player is told nothing
                        about why, which reads as the button being broken.
                    ]]
                    if definition.requires ~= nil then
                        TestRunner.truthy(
                            KNOWN_REQUIREMENTS[definition.requires],
                            definition.id .. " requires something nothing checks"
                        )
                        TestRunner.truthy(
                            definition.refusedMessage ~= nil
                                and #(definition.refusedMessage :: string) > 8,
                            definition.id .. " refuses silently"
                        )
                    end
                    -- an effect that reaches other people has to say how far
                    if definition.effect.kind == "heal_party" then
                        TestRunner.truthy(
                            (definition.effect.radius or 0) > 0,
                            definition.id .. " heals nowhere"
                        )
                    end
                    if definition.effect.kind == "shield" then
                        TestRunner.truthy(
                            (definition.effect.seconds or 0) > 0,
                            definition.id .. " shields for no time"
                        )
                    end
                end
                TestRunner.truthy(#Consumables.list() >= 16)
                TestRunner.equal(Consumables.get("gear_nothing"), nil)
                TestRunner.equal(Consumables.isKnown(42), false)
            end,
        },
        {
            --[[
                The orphan check, in both directions. A consumable nobody
                can craft is unreachable; a recipe whose output is neither
                worn nor used is a thing a player makes and then cannot do
                anything with, which is exactly what the milestone's gate
                refuses.
            ]]
            name = "every consumable is craftable, and every recipe output is worn or used",
            run = function()
                local craftable: { [string]: boolean } = {}
                for _, recipe in CraftingCatalog.list() do
                    craftable[recipe.outputItemId] = true
                    TestRunner.truthy(
                        Equipment.get(recipe.outputItemId) ~= nil
                            or Consumables.get(recipe.outputItemId) ~= nil,
                        recipe.id .. " makes something nobody can wear or use"
                    )
                    for materialId, amount in recipe.materials do
                        local _, result = ExpeditionInventory.addUnbanked(
                            ExpeditionInventory.default(),
                            "spec:" .. recipe.id .. materialId,
                            "spechash",
                            { materialId = materialId, amount = 1 },
                            1000
                        )
                        TestRunner.truthy(
                            result.applied,
                            recipe.id .. " costs a material the ledger refuses: " .. materialId
                        )
                        TestRunner.truthy(amount > 0 and amount <= 40)
                    end
                end
                for _, definition in Consumables.list() do
                    TestRunner.truthy(
                        craftable[definition.id],
                        definition.id .. " cannot be crafted anywhere"
                    )
                    -- and nothing is both worn and used
                    TestRunner.equal(
                        Equipment.get(definition.id),
                        nil,
                        definition.id .. " is both equipment and a consumable"
                    )
                end
            end,
        },
        {
            --[[
                The reason the catalog grew: this game makes threats it
                gave a player no way to answer. The spark thieves take the
                lantern, the drowsy strikers take your footing, and gear
                wears out a long way from the only bench that could fix
                it. Every effect kind past the first three exists because
                of one of those, and this is the check that a new kind
                cannot be added without something in the game it answers.
            ]]
            name = "every effect kind answers something the game actually does",
            run = function()
                local perKind: { [string]: number } = {}
                for _, definition in Consumables.list() do
                    perKind[definition.effect.kind] = (perKind[definition.effect.kind] or 0) + 1
                end
                for _, kind in Consumables.EffectKinds do
                    TestRunner.truthy(
                        (perKind[kind] or 0) > 0,
                        kind .. " is an effect nothing in the catalog uses"
                    )
                end
                -- the three answers are carried out of every region, so a
                -- player is never stuck with a threat they cannot answer
                -- because they have not reached the one place that sells it
                for _, kind in { "restore_lantern", "cure_status", "repair_gear" } do
                    TestRunner.truthy(
                        (perKind[kind] or 0) >= 6,
                        kind .. " is not craftable in every region"
                    )
                end

                -- the lantern answer scales, because a later night takes
                -- more off the lantern than an early one
                local first, last = 0, 0
                for _, definition in Consumables.list() do
                    if definition.effect.kind == "restore_lantern" then
                        if first == 0 then
                            first = definition.effect.amount
                        end
                        last = definition.effect.amount
                    end
                end
                TestRunner.truthy(last > first, "lantern oil does not deepen with the regions")
                -- and it can never restore more than a night's whole lantern
                TestRunner.truthy(last <= 40, "lantern oil is worth more than a night")
            end,
        },
        {
            --[[
                A cure that also strips the shield a player just put up
                would be worse than the condition in the exact moment it is
                reached for. This pins that clearing an affliction leaves
                what a player did to themselves alone.
            ]]
            name = "a cure clears what was done to you and leaves your own shield",
            run = function()
                local StatusEffectState = require("../../src/shared/StatusEffectState")
                local state = StatusEffectState.create()
                state = StatusEffectState.applyDrowsy(state, 100, 8, 0.7)
                state = StatusEffectState.applyRooted(state, 100, 3, 0)
                state = StatusEffectState.applyShield(state, 100, 5, 0.5)
                TestRunner.equal(StatusEffectState.afflicted(state, 101), true)

                local cleared, had = StatusEffectState.clearAfflictions(state)
                TestRunner.equal(had, true)
                TestRunner.equal(StatusEffectState.afflicted(cleared, 101), false)
                local snapshot = StatusEffectState.snapshot(cleared, 101)
                TestRunner.equal(snapshot.drowsy, false)
                TestRunner.equal(snapshot.rooted, false)
                TestRunner.equal(snapshot.shielded, true, "the cure took the player's own shield")

                -- and a player with nothing on them is not afflicted, so
                -- the item is refused rather than wasted
                local clean = StatusEffectState.create()
                TestRunner.equal(StatusEffectState.afflicted(clean, 101), false)
                local _, nothing = StatusEffectState.clearAfflictions(clean)
                TestRunner.equal(nothing, false)
            end,
        },
        {
            -- The two that shipped hardcoded must behave exactly as they
            -- did, because players already know what they do.
            name = "the first two consumables keep the numbers they always had",
            run = function()
                local satchel = Consumables.get("gear_meadow_satchel") :: any
                TestRunner.equal(satchel.effect.kind, "restore_stamina")
                TestRunner.equal(satchel.effect.amount, 50)
                TestRunner.equal(satchel.requires, "stamina_not_full")
                TestRunner.equal(satchel.refusedMessage, "STAMINA ALREADY FULL")
                TestRunner.equal(satchel.successMessage, "MEADOW SATCHEL — STAMINA RESTORED")

                local charm = Consumables.get("gear_amber_charm") :: any
                TestRunner.equal(charm.effect.kind, "shield")
                TestRunner.equal(charm.effect.amount, 5)
                TestRunner.equal(charm.effect.seconds, 0.6)
                TestRunner.equal(charm.requires, nil)
                TestRunner.equal(charm.successMessage, "AMBER CHARM — SHIELDED")

                -- and they are still the first two, so C and V do what they
                -- have always done for a player who owns only those
                TestRunner.equal(Consumables.Order[1], "gear_meadow_satchel")
                TestRunner.equal(Consumables.Order[2], "gear_amber_charm")
            end,
        },
        {
            --[[
                No item name may survive in the three places that used to
                hold them. This is a text check for the same reason the
                action-wiring spec is one: the failure is a file quietly
                keeping a branch, and only reading the files proves it did
                not.
            ]]
            name = "no consumable is named by the client, the HUD or the use handler",
            run = function()
                local fs = require("@lune/fs")
                for _, path in
                    {
                        "src/client/init.client.luau",
                        "src/client/Controllers/InputController.luau",
                        "src/server/Services/TutorialService.luau",
                    }
                do
                    TestRunner.truthy(fs.isFile(path), path .. " is missing")
                    local source = fs.readFile(path)
                    for _, definition in Consumables.list() do
                        TestRunner.equal(
                            string.find(source, definition.id, 1, true),
                            nil,
                            path .. " still names " .. definition.id
                        )
                    end
                end
                --[[
                    The HUD is allowed to name the two whose icons were
                    authored before the catalog existed, and nothing else.
                ]]
                local hud = fs.readFile("src/client/Controllers/HUDController.luau")
                for _, definition in Consumables.list() do
                    if
                        definition.id ~= "gear_meadow_satchel"
                        and definition.id ~= "gear_amber_charm"
                    then
                        TestRunner.equal(
                            string.find(hud, definition.id, 1, true),
                            nil,
                            "the HUD still names " .. definition.id
                        )
                    end
                end
            end,
        },
    },
}
