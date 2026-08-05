--!strict

local AdminRoster = require("../../src/shared/AdminRoster")
local TestRunner = require("../TestRunner")

local OWNER = 1213625298
local ZACK = 8772161919
local STRANGER = 999

return {
    name = "AdminRoster",
    cases = {
        {
            name = "recognises the roster by user ID and nobody else",
            run = function()
                TestRunner.equal(AdminRoster.isAdmin(OWNER), true)
                TestRunner.equal(AdminRoster.isAdmin(ZACK), true)
                for _, value in { STRANGER, 0, -1, "1213625298", nil, 0 / 0 } do
                    TestRunner.equal(AdminRoster.isAdmin(value), false)
                end
            end,
        },
        {
            name = "ignores ordinary chat and unknown slash commands",
            run = function()
                for _, message in { "hello", "/dance", "/", "night 4", "", 12, nil, "/nightfall 4" } do
                    TestRunner.equal(AdminRoster.parse(message), nil)
                end
            end,
        },
        {
            name = "parses a known command and its argument",
            run = function()
                local command = AdminRoster.parse("/night 4")
                TestRunner.equal((command :: any).name, "night")
                TestRunner.equal((command :: any).value, 4)
                local heal = AdminRoster.parse("/heal")
                TestRunner.equal((heal :: any).name, "heal")
                local phase = AdminRoster.parse("/phase NIGHT")
                TestRunner.equal((phase :: any).text, "night")
            end,
        },
        {
            name = "the feature flag is a complete off switch, roster included",
            run = function()
                local result = AdminRoster.authorize(OWNER, "/night 4", false)
                TestRunner.equal(result.allowed, false)
                TestRunner.equal(result.reason, "admin_disabled")
            end,
        },
        {
            name = "refuses a player who is not on the roster",
            run = function()
                local result = AdminRoster.authorize(STRANGER, "/night 4", true)
                TestRunner.equal(result.allowed, false)
                TestRunner.equal(result.reason, "not_an_admin")
            end,
        },
        {
            name = "bounds every numeric argument",
            run = function()
                for _, message in { "/night 0", "/night 61", "/night 2.5", "/night", "/night x" } do
                    local result = AdminRoster.authorize(OWNER, message, true)
                    TestRunner.equal(result.allowed, false)
                    TestRunner.equal(result.reason, "out_of_range")
                end
                for _, message in { "/give -1", "/give 100" } do
                    local result = AdminRoster.authorize(OWNER, message, true)
                    TestRunner.equal(result.allowed, false)
                end
                TestRunner.equal(AdminRoster.authorize(OWNER, "/night 4", true).value, 4)
                TestRunner.equal(AdminRoster.authorize(OWNER, "/give 0", true).allowed, true)
            end,
        },
        {
            name = "accepts only the three real phases",
            run = function()
                for _, phase in { "day", "dusk", "night" } do
                    local result = AdminRoster.authorize(ZACK, "/phase " .. phase, true)
                    TestRunner.equal(result.allowed, true)
                    TestRunner.equal(result.text, phase)
                end
                for _, message in { "/phase", "/phase midnight", "/phase 3" } do
                    local result = AdminRoster.authorize(ZACK, message, true)
                    TestRunner.equal(result.allowed, false)
                    TestRunner.equal(result.reason, "unknown_phase")
                end
            end,
        },
        {
            name = "an unknown command is refused before authorization is considered",
            run = function()
                -- Ordinary chat from a non-admin must not report "not_an_admin",
                -- because that would tell every player the roster exists.
                local result = AdminRoster.authorize(STRANGER, "just talking", true)
                TestRunner.equal(result.allowed, false)
                TestRunner.equal(result.reason, "not_a_command")
            end,
        },
        {
            name = "go accepts only the two levels",
            run = function()
                for _, place in { "town", "bramblewake" } do
                    local result = AdminRoster.authorize(OWNER, "/go " .. place, true)
                    TestRunner.equal(result.allowed, true)
                    TestRunner.equal(result.text, place)
                end
                for _, message in { "/go", "/go emberhollow", "/go 2" } do
                    local result = AdminRoster.authorize(OWNER, message, true)
                    TestRunner.equal(result.allowed, false)
                    TestRunner.equal(result.reason, "unknown_destination")
                end
            end,
        },
        {
            name = "inspect takes a username or a raw user ID as text",
            run = function()
                for _, message in { "/inspect UncleNickRush", "/inspect 8772161919" } do
                    local result = AdminRoster.authorize(OWNER, message, true)
                    TestRunner.equal(result.allowed, true)
                    TestRunner.equal(result.command, "inspect")
                    TestRunner.truthy(result.text ~= nil and #result.text > 0)
                end
            end,
        },
        {
            name = "inspect refuses a missing or oversized target",
            run = function()
                for _, message in { "/inspect", "/inspect " .. string.rep("a", 33) } do
                    local result = AdminRoster.authorize(OWNER, message, true)
                    TestRunner.equal(result.allowed, false)
                    TestRunner.equal(result.reason, "invalid_inspection_target")
                end
                -- Exactly at the bound is allowed; one character over is not.
                local atBound =
                    AdminRoster.authorize(OWNER, "/inspect " .. string.rep("a", 32), true)
                TestRunner.equal(atBound.allowed, true)
            end,
        },
        {
            name = "unlock takes a username or a raw user ID as text",
            run = function()
                for _, message in { "/unlock UncleNickRush", "/unlock 8772161919" } do
                    local result = AdminRoster.authorize(OWNER, message, true)
                    TestRunner.equal(result.allowed, true)
                    TestRunner.equal(result.command, "unlock")
                    TestRunner.truthy(result.text ~= nil and #result.text > 0)
                end
            end,
        },
        {
            name = "unlock refuses a missing or oversized target",
            run = function()
                for _, message in { "/unlock", "/unlock " .. string.rep("a", 33) } do
                    local result = AdminRoster.authorize(OWNER, message, true)
                    TestRunner.equal(result.allowed, false)
                    TestRunner.equal(result.reason, "invalid_unlock_target")
                end
                local atBound =
                    AdminRoster.authorize(OWNER, "/unlock " .. string.rep("a", 32), true)
                TestRunner.equal(atBound.allowed, true)
            end,
        },
        {
            name = "lists both admins",
            run = function()
                local ids = AdminRoster.adminUserIds()
                TestRunner.equal(#ids, 2)
                TestRunner.equal(ids[1], OWNER)
                TestRunner.equal(ids[2], ZACK)
            end,
        },
        {
            name = "restoreat demands a bounded copy index and export a target",
            run = function()
                local good = AdminRoster.authorize(OWNER, "/restoreat 555 2", true)
                TestRunner.equal(good.allowed, true)
                TestRunner.equal(good.text, "555")
                TestRunner.equal(good.value, 2)

                local noIndex = AdminRoster.authorize(OWNER, "/restoreat 555", true)
                TestRunner.equal(noIndex.allowed, false)
                TestRunner.equal(noIndex.reason, "invalid_backup_index")

                local wild = AdminRoster.authorize(OWNER, "/restoreat 555 99", true)
                TestRunner.equal(wild.allowed, false)

                local exportGood = AdminRoster.authorize(OWNER, "/export 555", true)
                TestRunner.equal(exportGood.allowed, true)
                TestRunner.equal(exportGood.text, "555")

                local exportBare = AdminRoster.authorize(OWNER, "/export", true)
                TestRunner.equal(exportBare.allowed, false)
            end,
        },
    },
}
