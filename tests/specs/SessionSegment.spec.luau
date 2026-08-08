--!strict

--[[
    The two labels every per-segment release gate is read on.

    RELEASE_GATES.md sets a second, looser threshold on every reliability and
    comprehension gate and then names who it applies to: each advertised
    platform class, and each supported device/performance segment. A
    misclassified session does not fail anything loudly -- it moves a phone's
    result into the desktop column, where it is averaged into hardware that was
    never in trouble. That is the same shape as every gap this project has
    paid for: the number still reads, it just reads about somebody else.
]]

local TestRunner = require("../TestRunner")
local SessionSegment = require("../../src/shared/SessionSegment")

return {
    name = "SessionSegment",
    cases = {
        {
            name = "a console is a console before it is anything else",
            run = function()
                -- A console reports a ten-foot interface *and* a gamepad, and
                -- some report touch. The most specific question is asked first
                -- so a device that answers yes twice is filed under the
                -- narrower answer.
                TestRunner.equal(
                    SessionSegment.platformClass(true, true, true, 1920, 1080),
                    "console"
                )
                TestRunner.equal(
                    SessionSegment.platformClass(true, false, false, 1920, 1080),
                    "console"
                )
            end,
        },
        {
            name = "no touch screen is a desktop whatever its size",
            run = function()
                TestRunner.equal(
                    SessionSegment.platformClass(false, false, true, 1280, 720),
                    "desktop"
                )
                -- A small window on a laptop is still a laptop. The mobile
                -- gates exist for reach and safe areas, which a mouse does not
                -- have.
                TestRunner.equal(
                    SessionSegment.platformClass(false, false, true, 392, 608),
                    "desktop"
                )
            end,
        },
        {
            name = "a touch screen is filed by its shorter edge, not its orientation",
            run = function()
                -- The owner's phone, portrait and landscape. Both are a phone.
                TestRunner.equal(
                    SessionSegment.platformClass(false, true, false, 392, 608),
                    "phone"
                )
                TestRunner.equal(
                    SessionSegment.platformClass(false, true, false, 608, 392),
                    "phone"
                )
                TestRunner.equal(
                    SessionSegment.platformClass(false, true, false, 1024, 768),
                    "tablet"
                )
                TestRunner.equal(
                    SessionSegment.platformClass(false, true, false, 768, 1024),
                    "tablet"
                )
            end,
        },
        {
            --[[
                A touch screen with a keyboard attached is a laptop or a Windows
                tablet being used as one, and it is filed by its screen. The
                keyboard only decides the case where there is no viewport to
                read at all, which is a client that answered before its camera
                existed rather than a device with no screen.
            ]]
            name = "a keyboard does not overrule a screen, but it does break a tie",
            run = function()
                TestRunner.equal(SessionSegment.platformClass(false, true, true, 400, 700), "phone")
                TestRunner.equal(SessionSegment.platformClass(false, true, true, 0, 0), "desktop")
                TestRunner.equal(SessionSegment.platformClass(false, true, false, 0, 0), "unknown")
                TestRunner.equal(
                    SessionSegment.platformClass(false, true, false, 0 / 0, 600),
                    "unknown"
                )
            end,
        },
        {
            --[[
                Unknown is a real answer and has to stay one. Guessing a
                session into `desktop` because nothing said otherwise is how a
                platform threshold passes on sessions that were never on that
                platform.
            ]]
            name = "a client that has not introduced itself is unknown, not assumed",
            run = function()
                TestRunner.equal(SessionSegment.platformOf(nil), nil)
                TestRunner.equal(SessionSegment.platformOf({}), nil)
                TestRunner.equal(SessionSegment.platformOf({ platform = "unknown" }), nil)
                TestRunner.equal(SessionSegment.platformOf({ platform = "PHONE" }), nil)
                TestRunner.equal(SessionSegment.platformOf({ platform = 7 }), nil)
                TestRunner.equal(SessionSegment.platformOf({ platform = "phone" }), "phone")
            end,
        },
        {
            --[[
                A client naming a platform this game does not advertise is
                refused rather than recorded. It is a label and nothing branches
                on it, but a label a client can invent is a column nobody can
                read.
            ]]
            name = "only the four advertised classes are accepted",
            run = function()
                for _, id in { "console", "desktop", "phone", "tablet", "unknown" } do
                    TestRunner.truthy(
                        SessionSegment.isValidPlatform(id),
                        id .. " should be a platform"
                    )
                end
                TestRunner.equal(SessionSegment.isValidPlatform("vr"), false)
                TestRunner.equal(SessionSegment.isValidPlatform(""), false)
                TestRunner.equal(SessionSegment.isValidPlatform(nil), false)
            end,
        },
        {
            --[[
                Two phones are not one segment. The boundaries are the numbers
                the performance budget already treats as meaningful, so a tier
                cannot disagree with a budget verdict about the same device.
            ]]
            name = "the performance tier splits the slow half from the fast half",
            run = function()
                TestRunner.equal(SessionSegment.tier(60), "high")
                TestRunner.equal(SessionSegment.tier(50), "high")
                TestRunner.equal(SessionSegment.tier(49.9), "mid")
                TestRunner.equal(SessionSegment.tier(30), "mid")
                TestRunner.equal(SessionSegment.tier(29.9), "low")
                TestRunner.equal(SessionSegment.tier(1), "low")
                TestRunner.equal(SessionSegment.tier(nil), "unknown")
                TestRunner.equal(SessionSegment.tier(0), "unknown")
                TestRunner.equal(SessionSegment.tier(0 / 0), "unknown")
            end,
        },
        {
            name = "the segment is one word, and an unknown half never poisons the other",
            run = function()
                TestRunner.equal(SessionSegment.id("phone", "low"), "phone/low")
                TestRunner.equal(SessionSegment.id("phone", nil), "phone/unknown")
                TestRunner.equal(SessionSegment.id("vr", "high"), "unknown/high")
                TestRunner.equal(SessionSegment.id(nil, nil), "unknown/unknown")
            end,
        },
    },
}
