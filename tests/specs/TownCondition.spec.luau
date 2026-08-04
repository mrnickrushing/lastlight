--!strict

--[[
    Per-building town damage and repair.

    The cases are organised around what the single-number model could not do --
    damage one building, repair one building, and merge two players who each
    repaired a different one -- plus the migration that carries a schema-12
    town-wide integrity forward without losing outstanding repair work.
]]

local TestRunner = require("../TestRunner")
local TownCondition = require("../../src/shared/TownCondition")
local TownProgression = require("../../src/shared/TownProgression")

local ARCHIVE = "building_archive"
local INN = "building_inn"
local WORKBENCH = "building_workbench"

-- A small explicit roster keeps the selection cases readable: with three
-- damageable buildings, night 1 strikes the first, night 2 the second, and so
-- on, which is a property worth being able to see by eye.
local ROSTER = { ARCHIVE, INN, WORKBENCH }

return {
    name = "TownCondition",
    cases = {
        --
        -- Damage lands on buildings, not on the town
        --
        {
            name = "a clean defense records the night and strikes nothing",
            run = function()
                local state, result =
                    TownCondition.afterNight(TownCondition.default(), 95, 1, ROSTER)
                TestRunner.equal(result.reason, "clean_defense")
                TestRunner.equal(#result.struck, 0)
                TestRunner.equal(result.integrity, 100)
                TestRunner.equal(state.lastNightNumber, 1)
            end,
        },
        {
            name = "lantern pressure damages named buildings and leaves the rest whole",
            run = function()
                -- The point of the rewrite: after a bad night some buildings
                -- are broken and the others are untouched, rather than every
                -- building sharing one number.
                local state, result =
                    TownCondition.afterNight(TownCondition.default(), 55, 2, ROSTER)
                TestRunner.equal(#result.struck, 2)
                TestRunner.equal(result.damage, 70)

                local struckSet: { [string]: boolean } = {}
                for _, id in result.struck do
                    struckSet[id] = true
                end
                for _, id in ROSTER do
                    local integrity = TownCondition.integrityFor(state, id)
                    if struckSet[id] then
                        TestRunner.equal(integrity, 65)
                    else
                        TestRunner.equal(integrity, 100)
                    end
                end
            end,
        },
        {
            name = "severity decides how many buildings are struck",
            run = function()
                for _, case in
                    {
                        { health = 95, expected = 0 },
                        { health = 75, expected = 1 },
                        { health = 55, expected = 2 },
                        { health = 10, expected = 3 },
                    }
                do
                    local _, result =
                        TownCondition.afterNight(TownCondition.default(), case.health, 1, ROSTER)
                    TestRunner.equal(#result.struck, case.expected)
                end
            end,
        },
        {
            name = "which buildings are struck depends only on the night number",
            run = function()
                -- The same rule TownNightIncident uses. A player who reconnects,
                -- or a server that restarts, must not be able to reroll a
                -- gentler night.
                local first = TownCondition.struckBuildings(ROSTER, 75, 4)
                for _ = 1, 5 do
                    local again = TownCondition.struckBuildings(ROSTER, 75, 4)
                    TestRunner.equal(#again, #first)
                    TestRunner.equal(again[1], first[1])
                end

                -- And consecutive nights move along the roster rather than
                -- hitting the same building forever.
                local sorted = table.clone(ROSTER)
                table.sort(sorted)
                TestRunner.equal(TownCondition.struckBuildings(ROSTER, 75, 1)[1], sorted[1])
                TestRunner.equal(TownCondition.struckBuildings(ROSTER, 75, 2)[1], sorted[2])
                TestRunner.equal(TownCondition.struckBuildings(ROSTER, 75, 3)[1], sorted[3])
                -- Wraps rather than running off the end.
                TestRunner.equal(TownCondition.struckBuildings(ROSTER, 75, 4)[1], sorted[1])
            end,
        },
        {
            name = "a building is damaged, never destroyed",
            run = function()
                -- A bad night has to create work without deleting a building,
                -- its services, or the paths around it.
                local state = TownCondition.default()
                for night = 1, 12 do
                    state = TownCondition.afterNight(state, 0, night, ROSTER)
                end
                for _, id in ROSTER do
                    TestRunner.equal(TownCondition.integrityFor(state, id), 25)
                end
            end,
        },
        {
            name = "the same night cannot apply damage twice",
            run = function()
                local state = TownCondition.afterNight(TownCondition.default(), 20, 3, ROSTER)
                local repeated, result = TownCondition.afterNight(state, 20, 3, ROSTER)
                TestRunner.equal(result.reason, "night_already_recorded")
                for _, id in ROSTER do
                    TestRunner.equal(
                        TownCondition.integrityFor(repeated, id),
                        TownCondition.integrityFor(state, id)
                    )
                end
            end,
        },
        {
            name = "only buildings that exist to be broken are struck",
            run = function()
                -- Whether a building is a finished structure or still a
                -- construction site lives in TownConstruction, so the roster is
                -- the caller's to supply -- but nothing outside it may be hit.
                local _, result =
                    TownCondition.afterNight(TownCondition.default(), 10, 1, { ARCHIVE })
                TestRunner.equal(#result.struck, 1)
                TestRunner.equal(result.struck[1], ARCHIVE)
            end,
        },

        --
        -- Repair names its building
        --
        {
            name = "repairing one building leaves every other building alone",
            run = function()
                -- The tell that the old model was the wrong shape: repairing
                -- the inn could make the archive's damage disappear, because no
                -- repair belonged to a building.
                local damaged = TownCondition.afterNight(TownCondition.default(), 10, 1, ROSTER)
                local before = TownCondition.integrityFor(damaged, ARCHIVE)

                local repaired, result = TownCondition.repair(damaged, INN)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(result.buildingId, INN)
                TestRunner.equal(result.restored, 20)
                TestRunner.equal(TownCondition.integrityFor(repaired, INN), 85)
                TestRunner.equal(TownCondition.integrityFor(repaired, ARCHIVE), before)
                TestRunner.equal(repaired.repairsCompleted, 1)
            end,
        },
        {
            name = "repeated repairs restore a building fully and then stop",
            run = function()
                local state = TownCondition.afterNight(TownCondition.default(), 75, 1, ROSTER)
                local target = TownCondition.struckBuildings(ROSTER, 75, 1)[1]

                local result: any
                for _ = 1, 2 do
                    state, result = TownCondition.repair(state, target)
                    TestRunner.equal(result.applied, true)
                end
                TestRunner.equal(TownCondition.integrityFor(state, target), 100)

                state, result = TownCondition.repair(state, target)
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "building_already_repaired")
                TestRunner.equal(state.repairsCompleted, 2)
            end,
        },
        {
            name = "a repair cannot name a building that does not exist",
            run = function()
                local damaged = TownCondition.afterNight(TownCondition.default(), 10, 1, ROSTER)
                for _, bogus in { "building_moon_base", "", "archive" } do
                    local state, result = TownCondition.repair(damaged, bogus)
                    TestRunner.equal(result.applied, false)
                    TestRunner.equal(result.reason, "unknown_building")
                    TestRunner.equal(state.repairsCompleted, damaged.repairsCompleted)
                end
                local state, result = TownCondition.repair(damaged, nil)
                TestRunner.equal(result.applied, false)
                TestRunner.equal(state.repairsCompleted, damaged.repairsCompleted)
            end,
        },
        {
            name = "a fully repaired building stops being stored at all",
            run = function()
                -- An absent building is a whole one, so the saved map stays
                -- small and a building added to the roster later starts
                -- undamaged everywhere without touching a profile.
                local state = TownCondition.afterNight(TownCondition.default(), 75, 1, ROSTER)
                local target = TownCondition.struckBuildings(ROSTER, 75, 1)[1]
                state = TownCondition.repair(state, target)
                state = TownCondition.repair(state, target)
                TestRunner.equal(state.buildings[target], nil)
                TestRunner.equal(TownCondition.integrityFor(state, target), 100)
            end,
        },

        --
        -- Sharing one town between separate profiles
        --
        {
            name = "the newest defended night still wins outright",
            run = function()
                local older = TownCondition.afterNight(TownCondition.default(), 10, 2, ROSTER)
                local newer = TownCondition.afterNight(TownCondition.default(), 10, 3, ROSTER)
                TestRunner.equal(TownCondition.merge(older, newer).lastNightNumber, 3)
                TestRunner.equal(TownCondition.merge(newer, older).lastNightNumber, 3)
            end,
        },
        {
            name = "two players who repaired different buildings both keep their work",
            run = function()
                -- The behaviour the single-number merge could not express: it
                -- had to choose one player's whole town over the other's, which
                -- silently discarded half the repairs done that day.
                local damaged = TownCondition.afterNight(TownCondition.default(), 10, 1, ROSTER)
                local fixedArchive = TownCondition.repair(damaged, ARCHIVE)
                local fixedInn = TownCondition.repair(damaged, INN)

                local merged = TownCondition.merge(fixedArchive, fixedInn)
                TestRunner.equal(TownCondition.integrityFor(merged, ARCHIVE), 85)
                TestRunner.equal(TownCondition.integrityFor(merged, INN), 85)
                -- And the merge is order independent.
                local other = TownCondition.merge(fixedInn, fixedArchive)
                TestRunner.equal(TownCondition.integrityFor(other, ARCHIVE), 85)
                TestRunner.equal(TownCondition.integrityFor(other, INN), 85)
            end,
        },
        {
            name = "a stale profile cannot re-damage a building someone already fixed",
            run = function()
                local damaged = TownCondition.afterNight(TownCondition.default(), 10, 1, ROSTER)
                local repaired = TownCondition.repair(damaged, ARCHIVE)
                local merged = TownCondition.merge(repaired, damaged)
                TestRunner.equal(TownCondition.integrityFor(merged, ARCHIVE), 85)
            end,
        },

        --
        -- Migration and corrupt data
        --
        {
            name = "a schema-12 town-wide integrity carries forward to every building",
            run = function()
                -- The old model never recorded which buildings were hit, so the
                -- honest migration is that the whole town inherits its number:
                -- how damaged the town was, and how much work is outstanding,
                -- both survive.
                local migrated = TownCondition.normalize({
                    integrity = 60,
                    lastNightNumber = 4,
                    lastDamage = 40,
                    repairsCompleted = 2,
                })
                for _, buildingId in TownProgression.buildingIds() do
                    TestRunner.equal(TownCondition.integrityFor(migrated, buildingId), 60)
                end
                TestRunner.equal(migrated.lastNightNumber, 4)
                TestRunner.equal(migrated.repairsCompleted, 2)
            end,
        },
        {
            name = "an undamaged schema-12 town migrates to no stored damage at all",
            run = function()
                local migrated = TownCondition.normalize({ integrity = 100, lastNightNumber = 3 })
                TestRunner.equal(next(migrated.buildings), nil)
                TestRunner.equal(migrated.lastNightNumber, 3)
            end,
        },
        {
            name = "normalization rejects corrupt values and unknown buildings",
            run = function()
                local normalized = TownCondition.normalize({
                    buildings = {
                        [ARCHIVE] = 0 / 0,
                        building_moon_base = 40,
                        [INN] = 40,
                        [12] = 40,
                    },
                    lastNightNumber = math.huge,
                    lastDamage = -math.huge,
                    repairsCompleted = 0 / 0,
                })
                TestRunner.equal(TownCondition.integrityFor(normalized, ARCHIVE), 100)
                TestRunner.equal(TownCondition.integrityFor(normalized, INN), 40)
                TestRunner.equal(normalized.buildings.building_moon_base, nil)
                TestRunner.equal(normalized.lastNightNumber, 0)
                TestRunner.equal(normalized.lastDamage, 0)
                TestRunner.equal(normalized.repairsCompleted, 0)
            end,
        },
        {
            name = "integrity is clamped rather than trusted",
            run = function()
                local normalized = TownCondition.normalize({
                    buildings = { [ARCHIVE] = -500, [INN] = 5000 },
                })
                TestRunner.equal(TownCondition.integrityFor(normalized, ARCHIVE), 25)
                -- Above full is not damage, so it is not stored at all.
                TestRunner.equal(TownCondition.integrityFor(normalized, INN), 100)
            end,
        },

        --
        -- What the world and the HUD read
        --
        {
            name = "snapshot lists damaged buildings and the work each needs",
            run = function()
                local state = TownCondition.afterNight(TownCondition.default(), 55, 1, ROSTER)
                local snapshot = TownCondition.snapshot(state, ROSTER)

                TestRunner.equal(snapshot.damageLevel, 2)
                TestRunner.equal(#snapshot.damagedBuildings, 2)
                TestRunner.equal(snapshot.damagedBuildings[1].integrity, 65)
                -- 35 missing on each of two buildings, at 20 restored per repair.
                TestRunner.equal(snapshot.repairsRemaining, 4)
                TestRunner.equal(snapshot.lastNightNumber, 1)
            end,
        },
        {
            name = "the town's one number is derived from its buildings, never stored",
            run = function()
                -- Analytics, the HUD, and the world attributes all still speak
                -- in a single integrity, so it must not be able to disagree with
                -- the buildings it summarises.
                local state = TownCondition.afterNight(TownCondition.default(), 75, 1, ROSTER)
                local expected = math.floor((65 + 100 + 100) / 3)
                TestRunner.equal(TownCondition.averageIntegrity(state, ROSTER), expected)
                TestRunner.equal(TownCondition.snapshot(state, ROSTER).integrity, expected)

                local repaired =
                    TownCondition.repair(state, TownCondition.struckBuildings(ROSTER, 75, 1)[1])
                TestRunner.equal(
                    TownCondition.averageIntegrity(repaired, ROSTER),
                    math.floor((85 + 100 + 100) / 3)
                )
            end,
        },
        {
            name = "an undamaged town reports nothing to repair",
            run = function()
                local snapshot = TownCondition.snapshot(TownCondition.default(), ROSTER)
                TestRunner.equal(snapshot.damageLevel, 0)
                TestRunner.equal(#snapshot.damagedBuildings, 0)
                TestRunner.equal(snapshot.repairsRemaining, 0)
                TestRunner.equal(snapshot.integrity, 100)
            end,
        },
    },
}
