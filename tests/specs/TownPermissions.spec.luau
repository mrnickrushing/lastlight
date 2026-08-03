--!strict

--[[
    Milestone 4 exit gate: "visitors cannot modify or steal without permission."

    Written from the visiting griefer's side. Every case asks whether a player
    who joined someone else's town can leave it worse than they found it.
]]

local TestRunner = require("../TestRunner")
local TownCondition = require("../../src/shared/TownCondition")
local TownPermissions = require("../../src/shared/TownPermissions")
local TownProgression = require("../../src/shared/TownProgression")

local HOST = 1213625298
local VISITOR = 4242

local function condition(integrity: number, night: number, repairs: number?): any
    return TownCondition.normalize({
        integrity = integrity,
        lastNightNumber = night,
        repairsCompleted = repairs or 0,
    })
end

return {
    name = "TownPermissions",
    cases = {
        {
            name = "ownership is by user ID and nothing else",
            run = function()
                TestRunner.equal(TownPermissions.roleFor(HOST, HOST), "host")
                TestRunner.equal(TownPermissions.roleFor(VISITOR, HOST), "visitor")

                -- Nothing that is not a real, matching, positive ID is a host.
                for _, actor in { 0, -1, 0 / 0, math.huge, "1213625298", true, nil } do
                    TestRunner.equal(TownPermissions.roleFor(actor, HOST), "visitor")
                end
                -- Nor does a missing host make everyone the host.
                for _, host in { 0, -1, 0 / 0, "1213625298", nil } do
                    TestRunner.equal(TownPermissions.roleFor(HOST, host), "visitor")
                end
            end,
        },
        {
            name = "only the host may lower anything",
            run = function()
                local host = TownPermissions.canDegrade(HOST, HOST)
                TestRunner.equal(host.allowed, true)

                local visitor = TownPermissions.canDegrade(VISITOR, HOST)
                TestRunner.equal(visitor.allowed, false)
                TestRunner.equal(visitor.reason, "visitors_cannot_damage_a_town")
            end,
        },
        {
            name = "a visitor from a later, wrecked town cannot break an intact one",
            run = function()
                -- The exploit this exists for: town condition resolves on night
                -- number first, so a visitor at night fifty with a wrecked town
                -- used to replace a host's intact one outright. A stranger walks
                -- in and the walls are suddenly broken.
                --
                -- 25 rather than 0 because TownCondition floors integrity at
                -- MIN_INTEGRITY: a town is never more than damaged, it is never
                -- rubble. The worst a visitor could impose is still a quarter.
                local standing = condition(100, 12)
                local wrecked = condition(25, 50)

                local plain = TownCondition.merge(standing, wrecked)
                TestRunner.equal(plain.integrity, 25)

                local guarded = TownPermissions.resolveCondition(
                    standing,
                    wrecked,
                    "visitor",
                    TownCondition.merge
                )
                TestRunner.equal(guarded.integrity, 100)
            end,
        },
        {
            name = "a host's own nights still damage their own town",
            run = function()
                -- The guard must not make towns indestructible. A host's own
                -- night is exactly how a town is supposed to get worse.
                local standing = condition(100, 12)
                local afterABadNight = condition(35, 13)

                local resolved = TownPermissions.resolveCondition(
                    standing,
                    afterABadNight,
                    "host",
                    TownCondition.merge
                )
                TestRunner.equal(resolved.integrity, 35)
            end,
        },
        {
            name = "a visitor's repairs and later nights still count",
            run = function()
                -- Visiting should be able to help. Only the downward half is
                -- refused, not the whole contribution.
                local standing = condition(40, 12)
                local helpful = condition(90, 20, 3)

                local resolved = TownPermissions.resolveCondition(
                    standing,
                    helpful,
                    "visitor",
                    TownCondition.merge
                )
                TestRunner.truthy(
                    resolved.integrity >= 90,
                    "a visitor's repair work must survive the guard"
                )
            end,
        },
        {
            name = "no arrival by anyone can ever lower integrity",
            run = function()
                -- Swept rather than sampled: for every pairing of standing and
                -- arriving town, a visitor never leaves it worse.
                for standingIntegrity = 0, 100, 10 do
                    for incomingIntegrity = 0, 100, 10 do
                        for _, night in { 1, 12, 50 } do
                            local standing = condition(standingIntegrity, 12)
                            local incoming = condition(incomingIntegrity, night)
                            local resolved = TownPermissions.resolveCondition(
                                standing,
                                incoming,
                                "visitor",
                                TownCondition.merge
                            )
                            TestRunner.truthy(
                                resolved.integrity >= standing.integrity,
                                string.format(
                                    "visitor lowered integrity from %d to %d",
                                    standing.integrity,
                                    resolved.integrity
                                )
                            )
                        end
                    end
                end
            end,
        },
        {
            name = "a fresh visitor cannot tear down buildings or send residents home",
            run = function()
                -- This half was already safe: TownProgression.merge is
                -- monotonic. The sweep is here so it stays that way.
                local built = TownProgression.merge(nil, {
                    tier = 3,
                    growthStage = 3,
                    buildingStages = {
                        building_first_lantern = 3,
                        building_archive = 3,
                        building_town_board = 3,
                        building_workbench = 3,
                        building_inn = 2,
                    },
                    residentIds = { "npc_tomas_reed", "npc_pip_wren", "npc_ena_moss" },
                })

                local afterFreshArrival = TownProgression.merge(built, {
                    tier = 0,
                    growthStage = 0,
                    buildingStages = {
                        building_first_lantern = 0,
                        building_archive = 0,
                        building_town_board = 0,
                        building_workbench = 0,
                        building_inn = 0,
                    },
                    residentIds = {},
                })

                TestRunner.equal(afterFreshArrival.tier, 3)
                TestRunner.equal(afterFreshArrival.growthStage, 3)
                for buildingId, stage in built.buildingStages do
                    TestRunner.truthy(
                        afterFreshArrival.buildingStages[buildingId] >= stage,
                        "a fresh arrival lowered " .. buildingId
                    )
                end
                TestRunner.equal(#afterFreshArrival.residentIds, 3)
            end,
        },
        {
            name = "an owned object belongs to its owner and nobody else",
            run = function()
                local owner = TownPermissions.canTake(HOST, HOST)
                TestRunner.equal(owner.allowed, true)
                TestRunner.equal(owner.reason, "owner")

                local thief = TownPermissions.canTake(VISITOR, HOST)
                TestRunner.equal(thief.allowed, false)
                TestRunner.equal(thief.reason, "belongs_to_another_traveler")

                -- Unowned objects are free to anyone, which is what makes the
                -- check safe to apply everywhere rather than selectively.
                for _, unowned in { 0, -1, nil, 0 / 0, "nobody" } do
                    TestRunner.equal(TownPermissions.canTake(VISITOR, unowned).allowed, true)
                end

                -- A forged actor ID cannot match a real owner.
                for _, actor in { "1213625298", 0 / 0, nil, true } do
                    TestRunner.equal(TownPermissions.canTake(actor, HOST).allowed, false)
                end
            end,
        },
    },
}
