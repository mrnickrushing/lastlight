--!strict

local AdminInspectionReport = require("../../src/shared/AdminInspectionReport")
local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

local NOW = 1_000_000
local STALE_AFTER = 90

return {
    name = "AdminInspectionReport",
    cases = {
        {
            name = "reports a save that was never written as not found",
            run = function()
                local report = AdminInspectionReport.build(nil, NOW, STALE_AFTER)
                TestRunner.equal(report.found, false)
                TestRunner.equal(report.lock.held, false)
            end,
        },
        {
            name = "summarizes a fresh default profile",
            run = function()
                local profile = SaveSchema.default(NOW)
                local report = AdminInspectionReport.build(profile, NOW, STALE_AFTER)
                TestRunner.equal(report.found, true)
                TestRunner.equal(report.schemaVersion, profile.schemaVersion)
                TestRunner.equal(report.nightNumber, 1)
                TestRunner.equal(report.tutorialStage, "arrive")
                TestRunner.equal(report.tutorialComplete, false)
                TestRunner.equal(report.chapterOneStatus, "unresolved")
                TestRunner.equal(report.chapterOneDecision, nil)
                TestRunner.equal(report.professionId, nil)
                TestRunner.equal(report.professionsWithMastery, 0)
                TestRunner.equal(report.equippedCount, 0)
                TestRunner.equal(report.gearStacks, 0)
                TestRunner.equal(report.lock.held, false)
            end,
        },
        {
            name = "counts mastery, equipment, and gear from a lived-in profile",
            run = function()
                local profile = SaveSchema.default(NOW)
                profile = SaveSchema.withNightNumber(profile, 12, NOW)
                profile = SaveSchema.withProfession(profile, "profession_scout", NOW)
                profile.profession.mastery = {
                    profession_scout = { xp = 40, level = 2, specializationId = nil },
                }
                profile.equipped = { head = "gear_ironroot_hood" }
                profile.gear = { gear_amber_charm = 3, gear_bramble_boots = 1 }
                local report = AdminInspectionReport.build(profile, NOW, STALE_AFTER)
                TestRunner.equal(report.nightNumber, 12)
                TestRunner.equal(report.professionId, "profession_scout")
                TestRunner.equal(report.professionsWithMastery, 1)
                TestRunner.equal(report.equippedCount, 1)
                TestRunner.equal(report.gearStacks, 2)
            end,
        },
        {
            name = "an unheld lock reports as not held",
            run = function()
                local profile: any = SaveSchema.default(NOW)
                profile.sessionLock = nil
                local report = AdminInspectionReport.build(profile, NOW, STALE_AFTER)
                TestRunner.equal(report.lock.held, false)
                TestRunner.equal(report.lock.holder, nil)
            end,
        },
        {
            name = "a recent lock reports as held and active",
            run = function()
                local profile: any = SaveSchema.default(NOW)
                profile.sessionLock = { jobId = "server-a", heartbeat = NOW - 5 }
                local report = AdminInspectionReport.build(profile, NOW, STALE_AFTER)
                TestRunner.equal(report.lock.held, true)
                TestRunner.equal(report.lock.holder, "server-a")
                TestRunner.equal(report.lock.stale, false)
            end,
        },
        {
            name = "a lock past the stale threshold reports as stale",
            run = function()
                local profile: any = SaveSchema.default(NOW)
                profile.sessionLock = { jobId = "server-b", heartbeat = NOW - 500 }
                local report = AdminInspectionReport.build(profile, NOW, STALE_AFTER)
                TestRunner.equal(report.lock.held, true)
                TestRunner.equal(report.lock.stale, true)
            end,
        },
        {
            name = "a lock with no heartbeat cannot be judged for staleness",
            run = function()
                local profile: any = SaveSchema.default(NOW)
                profile.sessionLock = { jobId = "server-c" }
                local report = AdminInspectionReport.build(profile, NOW, STALE_AFTER)
                TestRunner.equal(report.lock.held, true)
                TestRunner.equal(report.lock.stale, nil)
            end,
        },
        {
            name = "garbage in place of a lock is reported as unheld, not an error",
            run = function()
                for _, garbage in { "server-a", 42, {}, { jobId = 5 }, { jobId = "" } } do
                    local profile: any = SaveSchema.default(NOW)
                    profile.sessionLock = garbage
                    local report = AdminInspectionReport.build(profile, NOW, STALE_AFTER)
                    TestRunner.equal(report.lock.held, false)
                end
            end,
        },
        {
            name = "requires a finite time and a positive stale threshold",
            run = function()
                for _, badNow in { 0 / 0, math.huge, -math.huge } do
                    TestRunner.equal(
                        pcall(AdminInspectionReport.build, nil, badNow, STALE_AFTER),
                        false
                    )
                end
                for _, badStale in { 0, -1, 0 / 0 } do
                    TestRunner.equal(pcall(AdminInspectionReport.build, nil, NOW, badStale), false)
                end
            end,
        },
    },
}
