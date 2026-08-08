--!strict

--[[
    Milestone 4 exit gate: "migration fixtures cover every released schema."

    SaveSchema.spec already tests what each migration does. This file exists to
    answer a different question -- whether any released version has been left
    without a fixture at all -- and to make the answer fail loudly rather than
    quietly. The coverage case below reads the current version from Config, so
    bumping the schema without adding an era profile breaks the suite instead of
    shipping an untested upgrade path.

    An era profile is a representative save as it actually looked at that
    version: only the fields that existed then. That matters, because a fixture
    built from a modern profile with an old version number stamped on it does
    not exercise migration at all -- every field it needs is already present.
]]

local Config = require("../../src/shared/Config")
local SaveSchema = require("../../src/shared/SaveSchema")
local TownProgression = require("../../src/shared/TownProgression")
local TestRunner = require("../TestRunner")

local NOW = 4000

-- One representative profile per released schema version. Shapes are taken
-- from the migrations already covered in SaveSchema.spec rather than invented.
local ERA_PROFILES: { [number]: any } = {
    [1] = {
        schemaVersion = 1,
        createdAt = 10,
        updatedAt = 20,
        revision = 7,
        tutorial = { stage = "complete", complete = true },
    },
    [2] = {
        schemaVersion = 2,
        createdAt = 10,
        updatedAt = 20,
        revision = 3,
        tutorial = { stage = "gather", complete = false },
        profession = { selectedId = "profession_medic" },
    },
    [3] = {
        schemaVersion = 3,
        createdAt = 10,
        updatedAt = 20,
        revision = 4,
        tutorial = { stage = "complete", complete = true },
        profession = { selectedId = "profession_scout" },
        story = { chapterOne = { status = "unresolved" } },
    },
    [4] = {
        schemaVersion = 4,
        createdAt = 10,
        updatedAt = 20,
        revision = 5,
        tutorial = { stage = "complete", complete = true },
        story = { chapterOne = { status = "unresolved" } },
    },
    [5] = {
        schemaVersion = 5,
        createdAt = 10,
        updatedAt = 20,
        revision = 6,
        tutorial = { stage = "complete", complete = true },
        town = { nightNumber = 4 },
    },
    [6] = {
        schemaVersion = 6,
        createdAt = 10,
        updatedAt = 20,
        revision = 8,
        tutorial = { stage = "complete", complete = true },
        town = { nightNumber = 6 },
        gear = {},
    },
    [7] = {
        schemaVersion = 7,
        createdAt = 10,
        updatedAt = 20,
        revision = 9,
        tutorial = { stage = "complete", complete = true },
        town = { nightNumber = 7 },
        gear = {},
        quests = { claimed = {} },
    },
    [8] = {
        schemaVersion = 8,
        createdAt = 10,
        updatedAt = 20,
        revision = 11,
        tutorial = { stage = "complete", complete = true },
        town = { nightNumber = 9 },
        quests = { claimed = {} },
    },
    [9] = {
        schemaVersion = 9,
        createdAt = 10,
        updatedAt = 20,
        revision = 12,
        tutorial = { stage = "complete", complete = true },
        town = { nightNumber = 10, condition = {} },
    },
    [10] = {
        schemaVersion = 10,
        createdAt = 10,
        updatedAt = 20,
        revision = 14,
        tutorial = { stage = "complete", complete = true },
        town = { nightNumber = 12, condition = {} },
        profession = { selectedId = "profession_engineer" },
    },
    -- No town.construction field: construction orders (schema 12) did not
    -- exist yet, so this is exactly what a real player's save looked like
    -- the moment before this feature shipped -- nights and a resolved
    -- chapter one, nothing about paying for a stage.
    [11] = {
        schemaVersion = 11,
        createdAt = 10,
        updatedAt = 20,
        revision = 15,
        tutorial = { stage = "complete", complete = true },
        town = { nightNumber = 7, condition = {} },
        story = {
            chapterOne = {
                status = "complete",
                decision = "restore_farmland",
                wardenOutcome = "preserved",
                transactionId = "chapter_1:era11:hash:1",
                completedAt = 12,
            },
        },
        profession = { selectedId = "profession_engineer" },
    },
    -- Schema 12 is the last version to describe town damage as one town-wide
    -- integrity number, and the first to carry a construction ledger. Both
    -- matter to the 13 upgrade: the integrity has to spread across every
    -- building, and the ledger has to survive rather than be re-grandfathered
    -- from nights a second time.
    [12] = {
        schemaVersion = 12,
        createdAt = 10,
        updatedAt = 20,
        revision = 21,
        tutorial = { stage = "complete", complete = true },
        town = {
            nightNumber = 9,
            condition = {
                integrity = 60,
                lastNightNumber = 8,
                lastDamage = 35,
                repairsCompleted = 3,
            },
            construction = { building_archive = 2, building_workbench = 1 },
        },
        story = {
            chapterOne = {
                status = "complete",
                decision = "shared_agroforest",
                wardenOutcome = "scarred",
                transactionId = "chapter_1:era12:hash:1",
                completedAt = 14,
            },
        },
        profession = { selectedId = "profession_warden" },
        gear = { gear_amber_charm = 2 },
    },
    -- Schema 13 is the last version before memory fragments existed, and the
    -- first with per-building damage. The 14 upgrade must therefore leave the
    -- per-building map alone and arrive with an empty archive: nothing was
    -- collected before there was anything to collect, and inventing recoveries
    -- for a returning player would hand them a story they never found.
    [13] = {
        schemaVersion = 13,
        createdAt = 10,
        updatedAt = 20,
        revision = 34,
        tutorial = { stage = "complete", complete = true },
        town = {
            nightNumber = 12,
            condition = {
                buildings = { building_archive = 55, building_inn = 25 },
                lastNightNumber = 11,
                repairsCompleted = 4,
            },
            construction = { building_archive = 3, building_workbench = 2 },
        },
        story = {
            chapterOne = {
                status = "complete",
                decision = "wild_regrowth",
                wardenOutcome = "preserved",
                transactionId = "chapter_1:era13:hash:1",
                completedAt = 16,
            },
        },
        profession = { selectedId = "profession_medic" },
        gear = { gear_meadow_satchel = 1 },
        quests = { claimed = { quest_first_craft = true } },
    },

    -- Schema 14 shipped the memory archive (story.fragments); 15 adds
    -- resident life (town.residents + town.crisis). A 14-era save carries
    -- recovered fragments that must survive, and must arrive in 15 with
    -- every resident healthy, unbonded, and no crisis standing -- the
    -- systems did not exist, so nothing about them can be owed or held.
    [14] = {
        schemaVersion = 14,
        createdAt = 12,
        updatedAt = 30,
        revision = 51,
        tutorial = { stage = "complete", complete = true },
        town = {
            nightNumber = 18,
            condition = {
                buildings = { building_inn = 40, building_watchtower = 75 },
                lastNightNumber = 17,
                repairsCompleted = 9,
            },
            construction = { building_archive = 3, building_inn = 2 },
        },
        story = {
            chapterOne = {
                status = "complete",
                decision = "restore_farmland",
                wardenOutcome = "preserved",
                transactionId = "chapter_1:era14:hash:1",
                completedAt = 22,
            },
            fragments = { fragment_last_harvest = true },
        },
        profession = { selectedId = "profession_scout" },
        gear = { gear_bramble_boots = 1 },
        quests = { claimed = { quest_first_craft = true } },
    },

    -- Schema 15 shipped resident life; 16 adds decorations. A 15-era save
    -- carries bonds and possibly an open crisis that must survive, and must
    -- arrive in 16 with no decorations placed -- the slots did not exist.
    -- Schema 16 shipped decorations; 17 adds saved loadouts. A 16-era save
    -- carries decorations and gear that must survive, and must arrive in 17
    -- with no kits saved -- the slots did not exist.
    -- Schema 17 shipped loadouts; 18 adds equipment wear. A 17-era save
    -- carries kits that must survive, and must arrive in 18 with nothing
    -- worn -- no blade had dulled yet.
    -- Schema 18 shipped equipment wear; 19 adds rolled traits. An 18-era
    -- save carries wear that must survive, and must arrive in 19 traitless
    -- -- its items roll at their next craft, not retroactively.
    -- Schema 19 shipped rolled traits; 20 adds chapters II and III. A
    -- 19-era save carries traits that must survive, and must arrive in 20
    -- with no chapters beyond the first -- those regions did not exist.
    -- Schema 20 shipped chapters II and III; 21 adds the Hollow's finale
    -- record. A 20-era save carries chapters that must survive, and must
    -- arrive in 21 with an unresolved finale and its light untouched --
    -- nobody had been down there, because there was no down there.
    -- Schema 21 shipped the finale; 22 adds the rejoin ticket. A 21-era save
    -- carries a resolved finale that must survive, and must arrive in 22 with
    -- no ticket -- there were no parties to be a member of, so there is
    -- nothing to be sent back to.
    -- Schema 22 shipped the rejoin ticket; 23 adds the town visit policy. A
    -- 22-era save carries a ticket that must survive, and must arrive in 23
    -- OPEN -- every town before this schema was open to whoever the matchmaker
    -- sent, and migrating them shut would be a change of behaviour wearing a
    -- safe default's clothes.
    [22] = {
        schemaVersion = 22,
        createdAt = 44,
        updatedAt = 130,
        revision = 210,
        tutorial = { stage = "complete", complete = true, selectedTool = "hammer" },
        profession = { selectedId = "profession_warden" },
        gear = { gear_warden_cudgel = 1 },
        equipped = { weapon = "gear_warden_cudgel" },
        story = {
            chapterOne = {
                completedAt = 44,
                decision = "wild_regrowth",
                status = "complete",
                transactionId = "chapter_1:era22:hash:9",
                wardenOutcome = "scarred",
            },
            finale = {
                completedAt = 118,
                ending = "ending_ended",
                light = 20,
                status = "complete",
                transactionId = "finale:era22:hash:9",
            },
        },
        social = {
            rejoin = {
                partyId = "party_era22",
                accessCode = "era22-access-code",
                partySize = 3,
                issuedAt = 130,
                expiresAt = 4102444800,
            },
        },
    },
    [21] = {
        schemaVersion = 21,
        createdAt = 40,
        updatedAt = 120,
        revision = 190,
        tutorial = { stage = "complete", complete = true, selectedTool = "hammer" },
        profession = { selectedId = "profession_warden" },
        gear = { gear_warden_cudgel = 1 },
        equipped = { weapon = "gear_warden_cudgel" },
        story = {
            chapterOne = {
                completedAt = 44,
                decision = "wild_regrowth",
                status = "complete",
                transactionId = "chapter_1:era21:hash:3",
                wardenOutcome = "scarred",
            },
            finale = {
                completedAt = 110,
                ending = "ending_shared",
                light = 40,
                status = "complete",
                transactionId = "finale:era21:hash:3",
            },
        },
    },
    [20] = {
        schemaVersion = 20,
        createdAt = 36,
        updatedAt = 96,
        revision = 150,
        tutorial = { stage = "complete", complete = true, selectedTool = "axe" },
        profession = { selectedId = "profession_engineer" },
        gear = { gear_amber_edge = 1 },
        equipped = { weapon = "gear_amber_edge" },
        gearWear = { gear_amber_edge = 62 },
        gearTraits = { gear_amber_edge = "trait_keen" },
        story = {
            chapterOne = {
                completedAt = 40,
                decision = "shared_agroforest",
                status = "complete",
                transactionId = "chapter_1:era20:hash:7",
                wardenOutcome = "preserved",
            },
            chapters = {
                chapter_two = {
                    completedAt = 60,
                    decision = "vent_stope",
                    outcome = "cleared",
                    status = "complete",
                    transactionId = "chapter_2:era20:hash:7",
                },
            },
        },
    },
    [19] = {
        schemaVersion = 19,
        createdAt = 34,
        updatedAt = 90,
        revision = 140,
        tutorial = { stage = "complete", complete = true, selectedTool = "axe" },
        profession = { selectedId = "profession_engineer" },
        gear = { gear_amber_edge = 1 },
        equipped = { weapon = "gear_amber_edge" },
        gearWear = { gear_amber_edge = 62 },
        gearTraits = { gear_amber_edge = "trait_keen" },
    },
    [18] = {
        schemaVersion = 18,
        createdAt = 30,
        updatedAt = 80,
        revision = 120,
        tutorial = { stage = "complete", complete = true, selectedTool = "axe" },
        profession = { selectedId = "profession_scout" },
        gear = { gear_thornwood_bow = 1 },
        equipped = { weapon = "gear_thornwood_bow" },
        gearWear = { gear_thornwood_bow = 45 },
    },
    [17] = {
        schemaVersion = 17,
        createdAt = 22,
        updatedAt = 70,
        revision = 101,
        tutorial = { stage = "complete", complete = true, selectedTool = "sickle" },
        profession = { selectedId = "profession_beastkeeper" },
        gear = { gear_warden_cudgel = 1 },
        equipped = { weapon = "gear_warden_cudgel" },
        loadouts = {
            {
                professionId = "profession_beastkeeper",
                weaponItemId = "gear_warden_cudgel",
                toolId = "sickle",
            },
        },
    },
    [16] = {
        schemaVersion = 16,
        createdAt = 20,
        updatedAt = 60,
        revision = 90,
        tutorial = { stage = "complete", complete = true, selectedTool = "pick" },
        profession = { selectedId = "profession_alchemist" },
        gear = { gear_amber_edge = 1 },
        equipped = { weapon = "gear_amber_edge" },
        town = {
            nightNumber = 9,
            decorations = { decor_plaza_banner_east = true },
        },
    },
    [15] = {
        schemaVersion = 15,
        createdAt = 14,
        updatedAt = 40,
        revision = 77,
        tutorial = { stage = "complete", complete = true },
        town = {
            nightNumber = 21,
            condition = {
                buildings = { building_inn = 35 },
                lastNightNumber = 20,
                repairsCompleted = 12,
            },
            construction = { building_inn = 2, building_archive = 3 },
            residents = {
                npc_tomas_reed = { injuredUntilNight = 22, bond = 30, lastVisitNight = 20 },
                npc_pip_wren = { injuredUntilNight = 0, bond = 55, lastVisitNight = 21 },
            },
            crisis = {
                id = "crisis_clinic_20",
                kind = "care",
                title = "THE CLINIC IS FULL",
                detail = "Check on the injured residents.",
                startedNight = 20,
            },
        },
        story = {
            chapterOne = {
                status = "complete",
                decision = "shared_agroforest",
                wardenOutcome = "preserved",
                transactionId = "chapter_1:era15:hash:1",
                completedAt = 25,
            },
            fragments = { fragment_last_harvest = true },
        },
        profession = { selectedId = "profession_warden" },
        gear = { gear_ironroot_hood = 1 },
        quests = { claimed = { quest_first_craft = true } },
    },
}

-- Every field SaveSchema.default produces. A migrated profile that is missing
-- one of these is a profile some later system will index into and fault on.
local REQUIRED_FIELDS: { string } = {
    "schemaVersion",
    "createdAt",
    "updatedAt",
    "revision",
    "tutorial",
    "inventory",
    "profession",
    "story",
    "town",
    "gear",
    "equipped",
    "loadouts",
    "gearWear",
    "gearTraits",
    "quests",
    "social",
}

local function assertCurrentShape(profile: any, label: string)
    for _, field in REQUIRED_FIELDS do
        TestRunner.truthy(
            profile[field] ~= nil,
            string.format("%s: migrated profile is missing %s", label, field)
        )
    end
    TestRunner.equal(profile.schemaVersion, Config.SaveSchemaVersion)
    TestRunner.truthy(type(profile.revision) == "number", label .. ": revision is not a number")
    TestRunner.truthy(profile.revision >= 0, label .. ": revision went negative")
    TestRunner.truthy(
        type(profile.tutorial.stage) == "string",
        label .. ": tutorial lost its stage"
    )
    TestRunner.truthy(
        type(profile.town.nightNumber) == "number" and profile.town.nightNumber >= 1,
        label .. ": night number is not a real night"
    )
    TestRunner.truthy(
        type(profile.story.chapterOne.status) == "string",
        label .. ": chapter one lost its status"
    )
    TestRunner.truthy(
        type(profile.town.construction) == "table",
        label .. ": construction ledger is missing"
    )
end

return {
    name = "SaveMigration",
    cases = {
        {
            name = "every released schema version has a migration fixture",
            run = function()
                -- The current version is not in the table by design: it is what
                -- everything migrates *to*, and SaveSchema.default covers it.
                for version = 1, Config.SaveSchemaVersion - 1 do
                    TestRunner.truthy(
                        ERA_PROFILES[version] ~= nil,
                        string.format(
                            "schema %d was released with no migration fixture -- add an era "
                                .. "profile to SaveMigration.spec before shipping the bump",
                            version
                        )
                    )
                end
            end,
        },
        {
            name = "no fixture claims a version that was never released",
            run = function()
                for version in ERA_PROFILES do
                    TestRunner.truthy(
                        version >= 1 and version < Config.SaveSchemaVersion,
                        string.format("fixture for unreleased schema version %d", version)
                    )
                end
            end,
        },
        {
            name = "every released schema normalizes into a complete current profile",
            run = function()
                for version = 1, Config.SaveSchemaVersion - 1 do
                    local profile = SaveSchema.normalize(ERA_PROFILES[version], NOW)
                    assertCurrentShape(profile, string.format("schema %d", version))
                end
            end,
        },
        {
            name = "migration preserves what the old save actually earned",
            run = function()
                -- A migration that quietly resets progress passes a shape check
                -- and still loses the player's game.
                local one = SaveSchema.normalize(ERA_PROFILES[1], NOW)
                TestRunner.equal(one.revision, 7)
                TestRunner.equal(one.tutorial.complete, true)

                local five = SaveSchema.normalize(ERA_PROFILES[5], NOW)
                TestRunner.equal(five.town.nightNumber, 4)

                local ten = SaveSchema.normalize(ERA_PROFILES[10], NOW)
                TestRunner.equal(ten.town.nightNumber, 12)
                TestRunner.equal(ten.profession.selectedId, "profession_engineer")
            end,
        },
        {
            name = "migrating twice changes nothing the second time",
            run = function()
                -- Every save is normalized on load and again on write, so a
                -- migration that is not idempotent drifts a little on every
                -- session until something downstream breaks.
                for version = 1, Config.SaveSchemaVersion - 1 do
                    local once = SaveSchema.normalize(ERA_PROFILES[version], NOW)
                    local twice = SaveSchema.normalize(once, NOW + 100)

                    local label = string.format("schema %d", version)
                    TestRunner.equal(twice.schemaVersion, once.schemaVersion)
                    TestRunner.equal(twice.revision, once.revision)
                    TestRunner.equal(twice.tutorial.stage, once.tutorial.stage)
                    TestRunner.equal(twice.tutorial.complete, once.tutorial.complete)
                    TestRunner.equal(twice.town.nightNumber, once.town.nightNumber)
                    TestRunner.equal(twice.profession.selectedId, once.profession.selectedId)
                    TestRunner.equal(twice.story.chapterOne.status, once.story.chapterOne.status)
                    for _, buildingId in TownProgression.buildingIds() do
                        TestRunner.equal(
                            twice.town.construction[buildingId],
                            once.town.construction[buildingId],
                            label .. ": construction drifted on re-migration for " .. buildingId
                        )
                    end
                    assertCurrentShape(twice, label .. " (second pass)")
                end
            end,
        },
        {
            name = "a migrated profile still accepts every current wrapper",
            run = function()
                -- Shape alone is not enough: the migrated profile has to work
                -- with the code that will touch it next.
                for version = 1, Config.SaveSchemaVersion - 1 do
                    local profile = SaveSchema.normalize(ERA_PROFILES[version], NOW)
                    local label = string.format("schema %d", version)

                    local advanced = SaveSchema.withNightNumber(profile, 40, NOW)
                    TestRunner.equal(advanced.town.nightNumber, 40)
                    TestRunner.equal(advanced.revision, profile.revision + 1)

                    local rewarded = SaveSchema.withUnbankedExpeditionReward(
                        advanced,
                        "txn_" .. version,
                        "manifest_migration",
                        { materialId = "material_heartwood", amount = 2 },
                        NOW
                    )
                    TestRunner.truthy(
                        SaveSchema.hasExpeditionReward(rewarded, "txn_" .. version),
                        label .. ": a migrated profile could not take a reward"
                    )
                end
            end,
        },
        {
            name = "a hostile save from any era is refused rather than carried forward",
            run = function()
                -- The oldest saves are the likeliest to have been edited by
                -- hand, so every era gets the same forged payload treatment.
                for version = 1, Config.SaveSchemaVersion - 1 do
                    local forged = table.clone(ERA_PROFILES[version])
                    forged.revision = -500
                    forged.schemaVersion = version
                    forged.tutorial = { stage = "own_the_server", complete = "yes" }
                    forged.profession = { selectedId = "profession_admin" }
                    forged.story = {
                        chapterOne = {
                            status = "complete",
                            decision = "grant_everything",
                            wardenOutcome = "cheated",
                            transactionId = "",
                        },
                    }
                    forged.town = { nightNumber = -9000 }

                    local profile = SaveSchema.normalize(forged, NOW)
                    local label = string.format("schema %d", version)

                    assertCurrentShape(profile, label .. " (forged)")
                    TestRunner.equal(profile.profession.selectedId, nil)
                    TestRunner.equal(profile.story.chapterOne.status, "unresolved")
                    TestRunner.equal(profile.story.chapterOne.decision, nil)
                    TestRunner.truthy(
                        profile.tutorial.stage ~= "own_the_server",
                        label .. ": an invented tutorial stage survived migration"
                    )
                end
            end,
        },
        {
            --[[
                The rejoin ticket is the only saved field that resolves to a
                teleport, so a forged one is a door into a world the forger
                names. It has to arrive absent from every save written before
                it existed, and unreadable from any save that invents one.
            ]]
            name = "no save written before parties arrives holding a rejoin ticket",
            run = function()
                --[[
                    Bounded at the schema parties shipped in rather than at the
                    current one. An era-22 save may legitimately carry a ticket
                    -- 22 is where tickets began -- and the second half of this
                    case is that its ticket survives the migration intact,
                    which is the claim that actually matters to a player who
                    dropped out of a run and updated between.
                ]]
                local PARTIES_SCHEMA = 22
                for version = 1, PARTIES_SCHEMA - 1 do
                    local profile = SaveSchema.normalize(ERA_PROFILES[version], NOW)
                    TestRunner.equal(
                        SaveSchema.rejoinTicket(profile),
                        nil,
                        string.format("schema %d arrived holding a ticket", version)
                    )
                end
                local carried = SaveSchema.rejoinTicket(SaveSchema.normalize(ERA_PROFILES[22], NOW))
                TestRunner.truthy(carried ~= nil, "an era-22 ticket was dropped by migration")
                TestRunner.equal(carried.partyId, "party_era22")
                TestRunner.equal(carried.accessCode, "era22-access-code")

                local forged = table.clone(ERA_PROFILES[21])
                forged.social = {
                    rejoin = {
                        partyId = "party_1_1",
                        accessCode = "",
                        issuedAt = NOW,
                        expiresAt = NOW + 10,
                    },
                }
                TestRunner.equal(SaveSchema.rejoinTicket(SaveSchema.normalize(forged, NOW)), nil)
            end,
        },
        {
            -- The construction-orders migration is the one this suite's own
            -- header warns about: a fixture that merely has the right shape
            -- can still quietly reset a player's town. ERA_PROFILES[11] has
            -- no town.construction field at all, exactly like a real save
            -- written before this feature existed, so migrating it has to
            -- grandfather the ledger to precisely what nights and chapter
            -- one had already granted -- not zero, and not anything higher.
            name = "grandfathers construction to exactly what nights already unlocked",
            run = function()
                local profile = SaveSchema.normalize(ERA_PROFILES[11], NOW)
                local expected = TownProgression.resolve(profile).buildingStages

                local sawAnyBuiltStage = false
                for _, buildingId in TownProgression.buildingIds() do
                    TestRunner.equal(
                        profile.town.construction[buildingId],
                        expected[buildingId],
                        string.format("%s was not grandfathered to its tier ceiling", buildingId)
                    )
                    if expected[buildingId] > 0 then
                        sawAnyBuiltStage = true
                    end
                end
                -- A fixture where every building happens to be at stage zero
                -- would let this pass even if grandfathering were entirely
                -- broken. ERA_PROFILES[11] plays seven nights with a
                -- resolved chapter one specifically so at least one building
                -- is already built, and the comparison above has to catch a
                -- real discrepancy.
                TestRunner.truthy(
                    sawAnyBuiltStage,
                    "fixture is too thin to exercise grandfathering: nothing was built"
                )

                -- Re-migrating the already-current profile must not add
                -- anything further: grandfathering only ever fires once, on
                -- the save that never had the field.
                local twice = SaveSchema.normalize(profile, NOW + 10)
                for _, buildingId in TownProgression.buildingIds() do
                    TestRunner.equal(
                        twice.town.construction[buildingId],
                        profile.town.construction[buildingId],
                        buildingId .. " changed on a second migration pass"
                    )
                end
            end,
        },
    },
}
