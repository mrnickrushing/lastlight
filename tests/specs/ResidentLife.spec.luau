--!strict

local Config = require("../../src/shared/Config")
local ResidentLife = require("../../src/shared/ResidentLife")
local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

local function night(nightNumber: number, integrity: { [string]: number }, floorHit: boolean?)
    return {
        nightNumber = nightNumber,
        buildingIntegrity = integrity,
        lanternHitFloor = floorHit == true,
    }
end

return {
    name = "ResidentLife",
    cases = {
        {
            name = "every resident has a job at a real building",
            run = function()
                for _, residentId in ResidentLife.Ids do
                    local job = ResidentLife.Jobs[residentId]
                    TestRunner.truthy(job ~= nil, residentId .. " has no job")
                    TestRunner.equal(job.residentId, residentId)
                    TestRunner.equal(#job.buildingId > 0, true)
                    TestRunner.equal(#job.boonLabel > 0, true)
                end
            end,
        },
        {
            name = "a fallen workplace injures its keeper; a standing one does not",
            run = function()
                local state = ResidentLife.default()
                local nextState, report =
                    ResidentLife.resolveNight(state, night(5, { building_inn = 0.3 }))
                TestRunner.equal(#report.injuries, 1)
                TestRunner.equal(report.injuries[1], "npc_tomas_reed")
                TestRunner.equal(ResidentLife.isInjured(nextState, "npc_tomas_reed", 6), true)
                TestRunner.equal(ResidentLife.isInjured(nextState, "npc_pip_wren", 6), false)

                local calm = ResidentLife.resolveNight(state, night(5, { building_inn = 0.9 }))
                TestRunner.equal(ResidentLife.isInjured(calm, "npc_tomas_reed", 6), false)
            end,
        },
        {
            name = "rest runs its course and recovery is reported once",
            run = function()
                local state = ResidentLife.default()
                state = ResidentLife.resolveNight(state, night(5, { building_inn = 0.2 }))
                -- Injured through nights 6 and 7; the night-8 resolution
                -- reports the recovery.
                TestRunner.equal(ResidentLife.isInjured(state, "npc_tomas_reed", 7), true)
                local recoveredState, report = ResidentLife.resolveNight(state, night(8, {}))
                TestRunner.equal(#report.recoveries, 1)
                TestRunner.equal(ResidentLife.isInjured(recoveredState, "npc_tomas_reed", 8), false)
            end,
        },
        {
            name = "two injuries at once is a crisis and care can end it",
            run = function()
                local state = ResidentLife.default()
                local hurtState, report = ResidentLife.resolveNight(
                    state,
                    night(3, { building_inn = 0.1, building_town_board = 0.2 })
                )
                TestRunner.truthy(report.crisis ~= nil, "expected a crisis")
                TestRunner.equal((report.crisis :: any).kind, "care")

                -- Care: checking on an injured resident shortens the rest.
                local caredState, care = ResidentLife.checkOn(hurtState, "npc_tomas_reed", 4)
                TestRunner.equal(care.accepted, true)
                TestRunner.equal(care.bond >= 5, true)
                TestRunner.equal(
                    (caredState.npc_tomas_reed :: any).injuredUntilNight
                        < (hurtState.npc_tomas_reed :: any).injuredUntilNight,
                    true
                )
            end,
        },
        {
            name = "healthy visits bond once per night",
            run = function()
                local state = ResidentLife.default()
                local visited, first = ResidentLife.checkOn(state, "npc_ena_moss", 2)
                TestRunner.equal(first.accepted, true)
                TestRunner.equal(first.bond, 1)
                local _, second = ResidentLife.checkOn(visited, "npc_ena_moss", 2)
                TestRunner.equal(second.accepted, false)
                TestRunner.equal(second.reason, "already_visited")
                local _, nextNight = ResidentLife.checkOn(visited, "npc_ena_moss", 3)
                TestRunner.equal(nextNight.accepted, true)
            end,
        },
        {
            name = "boons come only from healthy residents with standing workplaces",
            run = function()
                local state = ResidentLife.default()
                local all = ResidentLife.dawnBoons(
                    state,
                    4,
                    { building_inn = 2, building_town_board = 1, building_workbench = 1 },
                    { "npc_tomas_reed", "npc_pip_wren", "npc_ena_moss" }
                )
                TestRunner.equal(#all, 3)

                local hurt = ResidentLife.resolveNight(state, night(4, { building_inn = 0.1 }))
                local afterInjury = ResidentLife.dawnBoons(
                    hurt,
                    5,
                    { building_inn = 2, building_town_board = 1, building_workbench = 1 },
                    { "npc_tomas_reed", "npc_pip_wren", "npc_ena_moss" }
                )
                TestRunner.equal(#afterInjury, 2)

                local unbuilt = ResidentLife.dawnBoons(
                    state,
                    4,
                    { building_inn = 0, building_town_board = 1, building_workbench = 1 },
                    { "npc_tomas_reed", "npc_pip_wren", "npc_ena_moss" }
                )
                TestRunner.equal(#unbuilt, 2)

                local absent = ResidentLife.dawnBoons(
                    state,
                    4,
                    { building_inn = 2, building_town_board = 1, building_workbench = 1 },
                    { "npc_tomas_reed" }
                )
                TestRunner.equal(#absent, 1)
            end,
        },
        {
            name = "normalization refuses garbage and clamps bonds",
            run = function()
                local normalized = ResidentLife.normalize({
                    npc_tomas_reed = { injuredUntilNight = -3, bond = 900, lastVisitNight = 2.7 },
                    npc_nobody = { bond = 50 },
                })
                TestRunner.equal((normalized.npc_tomas_reed :: any).bond, 100)
                TestRunner.equal((normalized.npc_tomas_reed :: any).injuredUntilNight, 0)
                TestRunner.equal((normalized.npc_tomas_reed :: any).lastVisitNight, 2)
                TestRunner.equal((normalized :: any).npc_nobody, nil)
                TestRunner.equal(next(ResidentLife.normalize("junk")) ~= nil, true)
            end,
        },
        {
            name = "profile transactions persist a night and a check-on",
            run = function()
                local profile = SaveSchema.normalize(nil, 100)
                TestRunner.equal(profile.schemaVersion, Config.SaveSchemaVersion)
                profile.town.nightNumber = 6
                local afterNight, report = SaveSchema.withResidentNight(
                    profile,
                    night(6, { building_inn = 0.2, building_town_board = 0.2 }),
                    101
                )
                TestRunner.equal(#report.injuries, 2)
                TestRunner.truthy(afterNight.town.crisis ~= nil, "crisis should persist")
                TestRunner.equal(afterNight.revision, profile.revision + 1)

                local afterCare = SaveSchema.withResidentCheck(afterNight, "npc_tomas_reed", 102)
                local healedBoth = SaveSchema.withResidentCheck(afterCare, "npc_pip_wren", 103)
                -- Both tended enough to drop below the injury line for the
                -- current night ends the crisis in the same write.
                local reloaded = SaveSchema.normalize(healedBoth, 104)
                TestRunner.equal(reloaded.town.residents.npc_tomas_reed.bond >= 5, true)
            end,
        },
        {
            name = "bond titles ladder",
            run = function()
                TestRunner.equal(ResidentLife.bondTitle(0), "NEWCOMER")
                TestRunner.equal(ResidentLife.bondTitle(25), "ACQUAINTED")
                TestRunner.equal(ResidentLife.bondTitle(50), "TRUSTED")
                TestRunner.equal(ResidentLife.bondTitle(99), "KINDRED")
            end,
        },
    },
}
