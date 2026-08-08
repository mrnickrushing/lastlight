--!strict

--[[
    No private-server setting changes a reward, and a practice phase grants
    nothing.

    That is Milestone 11 wave I's gate, and it is two claims of different
    kinds. The first is about the control catalog: it holds whatever anybody
    adds to it, so the check has to be a property over the whole list rather
    than a case per entry -- a case per entry is a check that a fifth control
    silently escapes. The second is about the one seam every write in the game
    passes through, and it is checked here as a rule about the catalog and in
    `ProfileService` as the two lines that hold it.

    The load-bearing case is the first one below. It drives every control the
    catalog contains through `apply` on a fresh state and demands that each one
    leaves rewards off. Nobody has to remember to extend it.
]]

local PrivateServerControls = require("../../src/shared/PrivateServerControls")
local RuntimeIds = require("../../src/shared/RuntimeIds")
local TestRunner = require("../TestRunner")

local OWNER = 4242
local STRANGER = 99

local function privateServer(): { [string]: any }
    return { privateServerId = "private-abc", privateServerOwnerId = OWNER }
end

local function history(): { any }
    return {
        { regionId = "region_bramblewake", seed = 11 },
        { regionId = "region_bramblewake", seed = 22 },
    }
end

return {
    name = "PrivateServerControls",
    cases = {
        {
            --[[
                The gate line, as a property of the catalog rather than of the
                four things currently in it.

                A control that did not latch practice would be a control that
                changes the world in a server that still pays, which is the one
                thing MONETIZATION_LIVEOPS_ANALYTICS says private-server
                settings may never be.
            ]]
            name = "every control there is turns rewards off, and none turns them back on",
            run = function()
                local controls = PrivateServerControls.controls()
                TestRunner.truthy(#controls > 0, "the control catalog is empty")
                for _, control in controls do
                    local fresh = PrivateServerControls.default()
                    TestRunner.truthy(
                        PrivateServerControls.rewardsAllowed(fresh),
                        "a fresh server should still pay"
                    )
                    local result = PrivateServerControls.apply(fresh, control.id, history())
                    TestRunner.truthy(result.ok, control.id .. " was refused on a fresh server")
                    TestRunner.equal(
                        PrivateServerControls.rewardsAllowed(result.state),
                        false,
                        control.id .. " left rewards on"
                    )

                    -- And pressing it again cannot undo the latch, which is
                    -- the two-press bypass: hold the clock, arrange a night,
                    -- release it, bank.
                    local second = PrivateServerControls.apply(result.state, control.id, history())
                    TestRunner.truthy(second.ok, control.id .. " refused its own second press")
                    TestRunner.equal(
                        PrivateServerControls.rewardsAllowed(second.state),
                        false,
                        control.id .. " released the latch on a second press"
                    )
                end
            end,
        },
        {
            name = "every control has a board in the world to be pressed on",
            run = function()
                for _, control in PrivateServerControls.controls() do
                    local interactionId = RuntimeIds.PrivateControlInteractionIds[control.id]
                    TestRunner.truthy(
                        type(interactionId) == "string" and interactionId ~= "",
                        control.id .. " has no interaction id"
                    )
                end
                -- And nothing in that table is an id the catalog does not
                -- contain, which would be a board that answers to nothing.
                for controlId in RuntimeIds.PrivateControlInteractionIds do
                    TestRunner.truthy(
                        PrivateServerControls.byId(controlId) ~= nil,
                        "an interaction id names no control: " .. tostring(controlId)
                    )
                end
            end,
        },
        {
            --[[
                A reserved server is the interesting refusal.

                Every expedition this game launches runs in one, and Roblox
                reports it with a non-empty `PrivateServerId` and an owner of
                zero -- so the obvious test admits the reward-bearing half of
                the game to a rail that stops its clock.
            ]]
            name = "only a bought server's owner may work the rail",
            run = function()
                local ok, reason = PrivateServerControls.authority(privateServer(), OWNER)
                TestRunner.equal(ok, true)
                TestRunner.equal(reason, "owner")

                local strangerOk, strangerReason =
                    PrivateServerControls.authority(privateServer(), STRANGER)
                TestRunner.equal(strangerOk, false)
                TestRunner.equal(strangerReason, "not_server_owner")

                local publicOk, publicReason = PrivateServerControls.authority({
                    privateServerId = "",
                    privateServerOwnerId = 0,
                }, OWNER)
                TestRunner.equal(publicOk, false)
                TestRunner.equal(publicReason, "not_private_server")

                local reservedOk, reservedReason = PrivateServerControls.authority({
                    privateServerId = "reserved-run-server",
                    privateServerOwnerId = 0,
                }, OWNER)
                TestRunner.equal(reservedOk, false)
                TestRunner.equal(reservedReason, "reserved_server")

                -- Nothing at all is a refusal rather than an error, because
                -- this is asked on the press path.
                local nilOk = PrivateServerControls.authority(nil, OWNER)
                TestRunner.equal(nilOk, false)
            end,
        },
        {
            name = "every refusal says something a player can act on",
            run = function()
                for _, reason in
                    {
                        "not_private_server",
                        "reserved_server",
                        "not_server_owner",
                        "unknown_control",
                        "no_seeds_discovered",
                    }
                do
                    local line = PrivateServerControls.refusal(reason)
                    TestRunner.truthy(#line > 0, reason .. " has no message")
                    TestRunner.truthy(
                        line ~= PrivateServerControls.refusal("nonsense"),
                        reason .. " falls through to the catch-all message"
                    )
                end
            end,
        },
        {
            --[[
                Seed selection reaches the presser's own history and nothing
                else. "Among already-discovered seeds" is the entire bound the
                monetization document puts on this control, and a bound that
                can be stepped past by pressing a board more times is not one.
            ]]
            name = "a seed cannot be chosen out of a history that does not hold it",
            run = function()
                local empty =
                    PrivateServerControls.apply(PrivateServerControls.default(), "choose_seed", {})
                TestRunner.equal(empty.ok, false)
                TestRunner.equal(empty.reason, "no_seeds_discovered")
                TestRunner.truthy(
                    PrivateServerControls.rewardsAllowed(empty.state),
                    "a refused press latched practice anyway"
                )

                local seeds = history()
                local state = PrivateServerControls.default()
                local seen: { number } = {}
                -- Two entries plus the server's own roll is a cycle of three,
                -- walked twice to prove it wraps rather than running off the
                -- end into the last entry forever.
                for _ = 1, 6 do
                    local result = PrivateServerControls.apply(state, "choose_seed", seeds)
                    TestRunner.truthy(result.ok, "a seed press was refused")
                    state = result.state
                    local chosen = PrivateServerControls.chosenSeed(state, seeds)
                    table.insert(seen, if chosen == nil then -1 else chosen.seed)
                end
                TestRunner.equal(table.concat(seen, ","), "11,22,-1,11,22,-1")

                -- A history that lost its tail stops choosing rather than
                -- quietly choosing something else.
                local shortened = { { regionId = "region_bramblewake", seed = 11 } }
                local far = PrivateServerControls.normalize({ practice = true, seedIndex = 2 })
                TestRunner.equal(PrivateServerControls.chosenSeed(far, shortened), nil)
            end,
        },
        {
            name = "a board nobody wrote is refused and changes nothing",
            run = function()
                local result = PrivateServerControls.apply(
                    PrivateServerControls.default(),
                    "hold_everything",
                    history()
                )
                TestRunner.equal(result.ok, false)
                TestRunner.equal(result.reason, "unknown_control")
                TestRunner.truthy(
                    PrivateServerControls.rewardsAllowed(result.state),
                    "an unknown control latched practice"
                )
                TestRunner.equal(PrivateServerControls.byId(42), nil)
                TestRunner.equal(PrivateServerControls.byId(nil), nil)
            end,
        },
        {
            --[[
                A momentary control leaves an effect rather than a state,
                because there is nothing about "the phase was called" to
                remember -- and a control that remembered it would call the
                next phase again on every read of the state.
            ]]
            name = "a moment leaves an effect and a toggle leaves a value",
            run = function()
                local moment =
                    PrivateServerControls.apply(PrivateServerControls.default(), "call_phase", {})
                TestRunner.equal(moment.ok, true)
                TestRunner.equal(moment.effect, "call_phase")
                TestRunner.equal(moment.state.hold, false)
                TestRunner.equal(moment.state.still, false)

                local held =
                    PrivateServerControls.apply(PrivateServerControls.default(), "hold_clock", {})
                TestRunner.equal(held.effect, nil)
                TestRunner.equal(held.state.hold, true)
                TestRunner.equal(PrivateServerControls.readout(held.state, "hold_clock", {}), "ON")
                local released = PrivateServerControls.apply(held.state, "hold_clock", {})
                TestRunner.equal(released.state.hold, false)
                TestRunner.equal(
                    PrivateServerControls.readout(released.state, "hold_clock", {}),
                    "OFF"
                )
                TestRunner.equal(
                    PrivateServerControls.rewardsAllowed(released.state),
                    false,
                    "releasing a hold released the latch"
                )
            end,
        },
        {
            name = "a forged state cannot claim rewards back",
            run = function()
                -- normalize is what a stored or replicated state passes
                -- through, and the only value it may not invent is a paying
                -- server: practice is true or the field was absent.
                TestRunner.equal(
                    PrivateServerControls.normalize({ practice = "no" }).practice,
                    false
                )
                TestRunner.equal(
                    PrivateServerControls.normalize({ practice = true }).practice,
                    true
                )
                TestRunner.equal(PrivateServerControls.normalize("nonsense").practice, false)
                TestRunner.equal(PrivateServerControls.normalize({ seedIndex = -4 }).seedIndex, 0)
                TestRunner.equal(PrivateServerControls.normalize({ seedIndex = 3.7 }).seedIndex, 3)
            end,
        },
    },
}
