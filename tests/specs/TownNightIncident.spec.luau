--!strict

local TownNightIncident = require("../../src/shared/TownNightIncident")
local TestRunner = require("../TestRunner")

return {
    name = "TownNightIncident",
    cases = {
        {
            name = "maps every normal-night theme to a distinct physical incident",
            run = function()
                local seen = {}
                for _, theme in { "EMBERFALL", "MIRETIDE", "ROOTMOON", "ASHEN VEIL" } do
                    local definition = TownNightIncident.forTheme(theme)
                    TestRunner.truthy(definition ~= nil)
                    TestRunner.equal(seen[definition.id], nil)
                    TestRunner.equal(#definition.sites, 3)
                    seen[definition.id] = true
                end
            end,
        },
        {
            name = "creates a bounded deterministic incident window",
            run = function()
                local state = TownNightIncident.create("EMBERFALL", 3, 100)
                TestRunner.equal(state.status, "active")
                TestRunner.equal(state.nightNumber, 3)
                TestRunner.equal(state.endsAt, 142)
                TestRunner.equal(state.resolvedCount, 0)
            end,
        },
        {
            name = "completes only after three distinct sites",
            run = function()
                local state = TownNightIncident.create("MIRETIDE", 2, 10)
                state = TownNightIncident.interact(state, "archive", 12)
                state = TownNightIncident.interact(state, "workshop", 13)
                local complete, result = TownNightIncident.interact(state, "inn", 14)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(result.completed, true)
                TestRunner.equal(complete.status, "complete")
            end,
        },
        {
            name = "keeps repeated site delivery idempotent",
            run = function()
                local state = TownNightIncident.create("ROOTMOON", 4, 10)
                local progressed = TownNightIncident.interact(state, "archive", 12)
                local unchanged, duplicate = TownNightIncident.interact(progressed, "archive", 13)
                TestRunner.equal(duplicate.accepted, false)
                TestRunner.equal(duplicate.reason, "site_resolved")
                TestRunner.equal(unchanged, progressed)
            end,
        },
        {
            name = "fails at the deadline with one bounded lantern penalty",
            run = function()
                local state = TownNightIncident.create("ASHEN VEIL", 5, 20)
                state = TownNightIncident.interact(state, "archive", 21)
                local failed, result = TownNightIncident.expire(state, 62)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(result.unresolved, 2)
                TestRunner.equal(result.lanternPenalty, 12)
                TestRunner.equal(failed.status, "failed")
                local same, repeated = TownNightIncident.expire(failed, 70)
                TestRunner.equal(same, failed)
                TestRunner.equal(repeated.applied, false)
            end,
        },
        {
            name = "rejects unknown sites and late interaction",
            run = function()
                local state = TownNightIncident.create("EMBERFALL", 1, 0)
                local same, unknown = TownNightIncident.interact(state, "lantern", 2)
                TestRunner.equal(same, state)
                TestRunner.equal(unknown.reason, "unknown_site")
                local failed, late = TownNightIncident.interact(state, "archive", 42)
                TestRunner.equal(late.reason, "incident_expired")
                TestRunner.equal(failed.status, "failed")
            end,
        },
    },
}
