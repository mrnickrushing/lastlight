--!strict

local ForemanEcho = require("../../src/shared/ForemanEchoEncounter")
local IronWidow = require("../../src/shared/IronWidowEncounter")
local OldGrowth = require("../../src/shared/OldGrowthEncounter")
local TestRunner = require("../TestRunner")

local RUN = "run_delve"
local HASH = "abc12345"

local function activeEcho(): any
    local state = ForemanEcho.create(RUN, HASH, true)
    state = (ForemanEcho.activate(state, 7))
    return state
end

local function activeWidow(): any
    local state = IronWidow.create(RUN, HASH, true)
    state = (IronWidow.activate(state, 7))
    return state
end

return {
    name = "IronrootElites",
    cases = {
        {
            -- Both elites are disable-able and neither can be touched before
            -- it is activated: the kill switch is the first thing to hold.
            name = "a disabled elite refuses every interaction",
            run = function()
                local echo = ForemanEcho.create(RUN, HASH, false)
                TestRunner.equal(echo.status, "disabled")
                local _, activation = ForemanEcho.activate(echo, 7)
                TestRunner.equal(activation.accepted, false)
                local _, lever = ForemanEcho.throwLever(echo, 7, "lever_north")
                TestRunner.equal(lever.accepted, false)
                local _, strike = ForemanEcho.strike(echo, 7, 30)
                TestRunner.equal(strike.accepted, false)

                local widow = IronWidow.create(RUN, HASH, false)
                TestRunner.equal(widow.status, "disabled")
                local _, cut = IronWidow.cutAnchor(widow, 7, "anchor_head", 100)
                TestRunner.equal(cut.accepted, false)
                local _, widowStrike = IronWidow.strike(widow, 7, 30)
                TestRunner.equal(widowStrike.accepted, false)
            end,
        },
        {
            -- The Echo's fight is authority, not damage: it cannot be hurt
            -- while it holds the board, and taking the board is three plain
            -- interactions that stay done.
            name = "the foreman cannot be struck until all three levers are thrown",
            run = function()
                local state = activeEcho()
                TestRunner.equal(state.status, "commanding")
                local _, blocked = ForemanEcho.strike(state, 7, 40)
                TestRunner.equal(blocked.accepted, false)
                TestRunner.equal(blocked.reason, "commanding")

                for index, leverId in ForemanEcho.LeverIds do
                    local result
                    state, result = ForemanEcho.throwLever(state, 7, leverId)
                    TestRunner.equal(result.accepted, true)
                    TestRunner.equal(result.thrown, index)
                    TestRunner.equal(result.exposed, index == #ForemanEcho.LeverIds)
                    -- a lever thrown twice is refused, not double-counted
                    local repeated
                    state, repeated = ForemanEcho.throwLever(state, 7, leverId)
                    TestRunner.equal(repeated.accepted, false)
                end
                TestRunner.equal(state.status, "exposed")
                local _, junk = ForemanEcho.throwLever(state, 7, "lever_nowhere")
                TestRunner.equal(junk.accepted, false)
            end,
        },
        {
            -- Seizing the board back is the Echo's phase structure: levers
            -- reset, health holds at the threshold, and the whole thing
            -- converges to complete rather than looping forever.
            name = "the foreman seizes the board back twice, then falls",
            run = function()
                local state = activeEcho()
                local seizes = 0
                local guard = 0
                while state.status ~= "complete" and guard < 200 do
                    guard += 1
                    if state.status == "commanding" then
                        for _, leverId in ForemanEcho.LeverIds do
                            state = (ForemanEcho.throwLever(state, 7, leverId))
                        end
                    else
                        local result
                        state, result = ForemanEcho.strike(state, 7, 25)
                        if result.seized then
                            seizes += 1
                            -- the board comes back: levers must be walked again
                            TestRunner.equal(state.status, "commanding")
                            for _, leverId in ForemanEcho.LeverIds do
                                TestRunner.equal(state.levers[leverId], nil)
                            end
                        end
                    end
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(seizes, 2)
                TestRunner.equal(state.health, 0)
                TestRunner.equal(ForemanEcho.snapshot(state, 7, 0).rewardEligible, true)
                TestRunner.equal(ForemanEcho.snapshot(state, 9, 0).rewardEligible, false)
            end,
        },
        {
            -- Ground marks and their damage window agree on one clock, and
            -- a mark cannot be stacked on itself.
            name = "the foreman marks ground on a clock the server owns",
            run = function()
                local state = activeEcho()
                local result
                state, result = ForemanEcho.markGround(state, 100)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(result.markedUntil, 100 + ForemanEcho.MarkSeconds)
                local _, again = ForemanEcho.markGround(state, 101)
                TestRunner.equal(again.accepted, false)
                TestRunner.equal(ForemanEcho.snapshot(state, 7, 101).marked, true)
                local expired = ForemanEcho.expire(state, 200)
                TestRunner.equal(expired.markedUntil, 0)
                TestRunner.equal(ForemanEcho.snapshot(expired, 7, 200).marked, false)
            end,
        },
        {
            -- The Widow is tempo: every cut buys a window, windows close,
            -- and only the last cut keeps her down for good.
            name = "the widow's window opens on a cut and closes on its own",
            run = function()
                local state = activeWidow()
                TestRunner.equal(state.status, "webbed")
                local _, blocked = IronWidow.strike(state, 7, 30)
                TestRunner.equal(blocked.accepted, false)

                local result
                state, result = IronWidow.cutAnchor(state, 7, "anchor_head", 100)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(state.status, "grounded")
                TestRunner.equal(result.webDown, false)
                -- inside the window she takes damage
                local hit
                state, hit = IronWidow.strike(state, 7, 30)
                TestRunner.equal(hit.accepted, true)
                TestRunner.equal(state.health, IronWidow.MaxHealth - 30)
                -- the window closes and she is back in the web
                state = IronWidow.expire(state, 100 + IronWidow.GroundedSeconds)
                TestRunner.equal(state.status, "webbed")
                local _, late = IronWidow.strike(state, 7, 30)
                TestRunner.equal(late.accepted, false)
                -- progress never unwinds
                TestRunner.equal(state.anchors.anchor_head, true)
                local _, repeated = IronWidow.cutAnchor(state, 7, "anchor_head", 200)
                TestRunner.equal(repeated.accepted, false)
            end,
        },
        {
            -- Cutting the web fully keeps her grounded, and the ambush
            -- cadence eases as the fight closes so a slow run converges.
            name = "the full cut keeps her down and the fight calms as it closes",
            run = function()
                local state = activeWidow()
                local now = 100
                local previousCooldown = IronWidow.ambushCooldown(state)
                for index, anchorId in IronWidow.AnchorIds do
                    local result
                    state, result = IronWidow.cutAnchor(state, 7, anchorId, now)
                    TestRunner.equal(result.cut, index)
                    if index < #IronWidow.AnchorIds then
                        -- back into the web so the next cut is a fresh window
                        state = IronWidow.expire(state, now + IronWidow.GroundedSeconds)
                        local cooldown = IronWidow.ambushCooldown(state)
                        TestRunner.truthy(cooldown > previousCooldown)
                        previousCooldown = cooldown
                        now += 20
                    end
                end
                TestRunner.equal(state.status, "grounded")
                -- no expiry can put her back up once the web is cut
                state = IronWidow.expire(state, now + 100000)
                TestRunner.equal(state.status, "grounded")
                local guard = 0
                while state.status ~= "complete" and guard < 100 do
                    guard += 1
                    state = (IronWidow.strike(state, 7, 40))
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(IronWidow.snapshot(state, 7, now).webDown, true)
            end,
        },
        {
            -- Rewards are per run, per participant, per elite: the ids must
            -- never collide, or one elite's payout settles another's.
            name = "reward transaction ids are unique across elites and players",
            run = function()
                local echo = activeEcho()
                local widow = activeWidow()
                local seen: { [string]: boolean } = {}
                local ids = {
                    ForemanEcho.rewardTransactionId(echo, 7),
                    ForemanEcho.rewardTransactionId(echo, 9),
                    IronWidow.rewardTransactionId(widow, 7),
                    IronWidow.rewardTransactionId(widow, 9),
                    OldGrowth.rewardTransactionId(OldGrowth.create(RUN, HASH, true), 7),
                }
                for _, id in ids do
                    TestRunner.equal(seen[id], nil, "duplicate reward id: " .. id)
                    seen[id] = true
                end
                -- and the same participant in the same run is stable, so a
                -- retry settles once
                TestRunner.equal(
                    ForemanEcho.rewardTransactionId(echo, 7),
                    ForemanEcho.rewardTransactionId(echo, 7)
                )
            end,
        },
        {
            -- The Delve's elites must not be the forest's elite with new
            -- words: different verbs, different attack shapes, different pay.
            name = "neither elite is the Old Growth wearing a hat",
            run = function()
                TestRunner.equal(ForemanEcho.Reward.materialId, "material_ironroot_ore")
                TestRunner.equal(IronWidow.Reward.materialId, "material_coalglass")
                TestRunner.truthy(OldGrowth.Reward.materialId ~= ForemanEcho.Reward.materialId)
                local echoAttack = ForemanEcho.attack(1, 0)
                local widowAttack = IronWidow.attack(1, 0)
                local growthAttack = OldGrowth.attack(1, 0)
                TestRunner.truthy(echoAttack.attackId ~= growthAttack.attackId)
                TestRunner.truthy(widowAttack.attackId ~= growthAttack.attackId)
                TestRunner.truthy(echoAttack.attackId ~= widowAttack.attackId)
                -- second-phase attacks differ from first-phase ones
                TestRunner.truthy(ForemanEcho.attack(2, 1).attackId ~= echoAttack.attackId)
                TestRunner.truthy(IronWidow.attack(2, 2).attackId ~= widowAttack.attackId)
            end,
        },
    },
}
