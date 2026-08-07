--!strict

local AshRegent = require("../../src/shared/AshRegentEncounter")
local HollowFinale = require("../../src/shared/Content/Definitions/HollowFinale")
local NamelessNight = require("../../src/shared/NamelessNightEncounter")
local ResidentRoster = require("../../src/shared/ResidentRoster")
local TestRunner = require("../TestRunner")

local RUN = "run_hollow"
local HASH = "ee7733bb"
local TRAPPED = { "npc_pip_wren", "npc_ivy_thorn" }

local function opened(): any
    local state = NamelessNight.create(RUN, HASH, true)
    state = (NamelessNight.unlock(state))
    return (NamelessNight.activate(state, 7, TRAPPED))
end

-- Walk the finale to the seat, taking the given post and person.
local function toTheSeat(state: any, keptPost: string, rescuedId: string?): any
    for _, postId in NamelessNight.PostIds do
        if state.scene ~= 1 then
            break
        end
        if postId ~= keptPost then
            state = (NamelessNight.holdPost(state, 7, postId))
        end
    end
    for _, markId in NamelessNight.MarkIds do
        if state.scene ~= 2 then
            break
        end
        state = (NamelessNight.follow(state, 7, markId))
    end
    if rescuedId ~= nil then
        state = (NamelessNight.rescue(state, 7, rescuedId))
    else
        state = (NamelessNight.passBy(state, 7))
    end
    for _, momentId in NamelessNight.MomentIds do
        if state.scene ~= 4 then
            break
        end
        state = (NamelessNight.witness(state, 7, momentId))
    end
    return state
end

return {
    name = "HollowFinale",
    cases = {
        {
            --[[
                The Hollow is authored, not generated, and the spec has to
                say so: no module list and no event pool, because a finale
                that could come out differently is one nobody can be told
                about.
            ]]
            name = "the Hollow is authored rather than generated",
            run = function()
                TestRunner.equal(HollowFinale.Authored, true)
                TestRunner.equal(HollowFinale.RegionId, "region_hollow")
                TestRunner.equal(HollowFinale.BossId, NamelessNight.Id)
                TestRunner.equal((HollowFinale :: any).Modules, nil)
                TestRunner.equal((HollowFinale :: any).Events, nil)
                TestRunner.equal(#HollowFinale.PointsOfInterest, 7)
                TestRunner.equal(#HollowFinale.Scenes, NamelessNight.SceneCount)
                TestRunner.equal(#HollowFinale.Endings, 3)

                -- every POI belongs to a real scene and says something
                local scenes: { [number]: boolean } = {}
                for index, scene in HollowFinale.Scenes do
                    TestRunner.equal(scene.number, index)
                    scenes[scene.number] = true
                    TestRunner.truthy(#scene.instruction > 12, scene.id .. " asks nothing")
                end
                local covered: { [number]: boolean } = {}
                for _, poi in HollowFinale.PointsOfInterest do
                    TestRunner.truthy(scenes[poi.scene], poi.id .. " belongs to no scene")
                    covered[poi.scene] = true
                    TestRunner.truthy(#poi.detail > 40, poi.id .. " has nothing to say")
                end
                for number in scenes do
                    TestRunner.truthy(covered[number], "scene " .. number .. " has nowhere to be")
                end
                -- the endings the definition names are the ones the fight
                -- can actually produce
                for _, ending in HollowFinale.Endings do
                    local found = false
                    for _, id in NamelessNight.EndingIds do
                        if id == ending.id then
                            found = true
                        end
                    end
                    TestRunner.truthy(found, ending.id .. " cannot be reached")
                end
            end,
        },
        {
            -- Five scenes in order, each with its own verb, and no verb
            -- works outside the scene it belongs to.
            name = "the five scenes happen in order and only in order",
            run = function()
                local state = opened()
                TestRunner.equal(state.scene, 1)
                -- nothing from a later scene works yet
                local _, earlyFollow = NamelessNight.follow(state, 7, "mark_kerb")
                TestRunner.equal(earlyFollow.reason, "wrong_scene")
                local _, earlyChoose = NamelessNight.choose(state, 7, "ending_kept")
                TestRunner.equal(earlyChoose.reason, "wrong_scene")

                state = (NamelessNight.holdPost(state, 7, "post_gate"))
                TestRunner.equal(state.scene, 1)
                state = (NamelessNight.holdPost(state, 7, "post_road"))
                TestRunner.equal(state.scene, 2)
                -- and the post nobody stood at is recorded
                TestRunner.equal(state.abandonedPost, "post_hearth")
                -- scene one's verb is spent
                local _, lateHold = NamelessNight.holdPost(state, 7, "post_hearth")
                TestRunner.equal(lateHold.reason, "wrong_scene")

                -- the way down costs light, and guessing costs more
                local before = state.light
                local wrong
                state, wrong = NamelessNight.follow(state, 7, "mark_sill")
                TestRunner.equal(wrong.accepted, false)
                TestRunner.equal(state.light, before - 2)
                state = (NamelessNight.follow(state, 7, "mark_kerb"))
                TestRunner.equal(state.light, before - 3)
                state = (NamelessNight.follow(state, 7, "mark_stair"))
                state = (NamelessNight.follow(state, 7, "mark_sill"))
                TestRunner.equal(state.scene, 3)

                state = (NamelessNight.rescue(state, 7, TRAPPED[2]))
                TestRunner.equal(state.rescued, TRAPPED[2])
                TestRunner.equal(state.leftBehind, TRAPPED[1])
                TestRunner.equal(state.scene, 4)

                for _, momentId in NamelessNight.MomentIds do
                    state = (NamelessNight.witness(state, 7, momentId))
                end
                TestRunner.equal(state.scene, 5)
                TestRunner.equal(state.status, "playing")

                state = (NamelessNight.choose(state, 7, "ending_shared"))
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.chosenEnding, "ending_shared")
            end,
        },
        {
            -- Three endings, all reachable, and the game does not refuse a
            -- player who will not choose in scene three -- it records it.
            name = "all three endings are reachable and refusing to choose is an answer",
            run = function()
                local reached: { [string]: boolean } = {}
                for _, endingId in NamelessNight.EndingIds do
                    local state = toTheSeat(opened(), "post_gate", TRAPPED[1])
                    state = (NamelessNight.choose(state, 7, endingId))
                    TestRunner.equal(state.status, "complete")
                    TestRunner.equal(state.chosenEnding, endingId)
                    reached[endingId] = true
                end
                TestRunner.equal(reached.ending_kept, true)
                TestRunner.equal(reached.ending_ended, true)
                TestRunner.equal(reached.ending_shared, true)

                local passed = toTheSeat(opened(), "post_road", nil)
                TestRunner.equal(passed.rescued, nil)
                TestRunner.equal(passed.leftBehind, nil)
                TestRunner.equal(passed.scene, 5)
                passed = (NamelessNight.choose(passed, 7, "ending_ended"))
                TestRunner.equal(passed.status, "complete")

                -- and what a party did on the way down is on the snapshot,
                -- because the epilogue reads it rather than the ending alone
                local snapshot = NamelessNight.snapshot(passed, 7)
                TestRunner.equal(snapshot.abandonedPost, "post_road")
                TestRunner.equal(snapshot.rescued, nil)
                TestRunner.truthy(snapshot.light < NamelessNight.StartingLight)
            end,
        },
        {
            --[[
                Idempotency is load-bearing here in a way it is not
                anywhere else: a disconnect at the bottom of the Hollow
                must not let the finale resolve twice. Every scene carries
                its own transaction id and so does the ending.
            ]]
            name = "no scene and no ending can be resolved twice",
            run = function()
                local state = toTheSeat(opened(), "post_hearth", TRAPPED[1])
                local chosen = (NamelessNight.choose(state, 7, "ending_kept"))
                local _, again = NamelessNight.choose(chosen, 7, "ending_ended")
                TestRunner.equal(again.accepted, false)
                TestRunner.equal(again.reason, "wrong_scene")
                TestRunner.equal(chosen.chosenEnding, "ending_kept")

                local ids: { [string]: boolean } = {}
                for _, scene in HollowFinale.Scenes do
                    local id = NamelessNight.sceneTransactionId(chosen, scene.id)
                    TestRunner.equal(ids[id], nil, "two scenes share a transaction id")
                    ids[id] = true
                    TestRunner.truthy(string.find(id, RUN, 1, true) ~= nil)
                    TestRunner.truthy(string.find(id, HASH, 1, true) ~= nil)
                end
                local ending = NamelessNight.endingTransactionId(chosen)
                TestRunner.equal(ids[ending], nil, "the ending shares a scene's id")
                TestRunner.equal(
                    ending,
                    NamelessNight.endingTransactionId(chosen),
                    "the ending id is not stable"
                )
                -- a different run is a different id, so a replay pays again
                -- and a rejoin does not
                local other = NamelessNight.create("run_other", HASH, true)
                TestRunner.truthy(
                    NamelessNight.endingTransactionId(other) ~= ending,
                    "two runs share an ending id"
                )
                TestRunner.truthy(
                    NamelessNight.rewardTransactionId(chosen, 7)
                        ~= NamelessNight.rewardTransactionId(chosen, 8)
                )
            end,
        },
        {
            -- The two people in scene three come from the save rather than
            -- from this module, which is what makes the choice cost
            -- anything.
            name = "the trapped are named by the save, and must be real people",
            run = function()
                for _, residentId in TRAPPED do
                    TestRunner.truthy(
                        ResidentRoster.get(residentId) ~= nil,
                        residentId .. " is not somebody in this game"
                    )
                end
                local state = NamelessNight.create(RUN, HASH, true)
                state = (NamelessNight.unlock(state))
                local _, none = NamelessNight.activate(state, 7, {})
                TestRunner.equal(none.accepted, false)
                local _, twinned =
                    NamelessNight.activate(state, 7, { "npc_pip_wren", "npc_pip_wren" })
                TestRunner.equal(twinned.accepted, false)

                local live = opened()
                local _, stranger = NamelessNight.rescue(live, 7, "npc_tomas_reed")
                TestRunner.equal(stranger.reason, "wrong_scene")
            end,
        },
        {
            -- Two scenes have no attack at all, and that is deliberate
            -- rather than missing.
            name = "the last two scenes have nothing to fight",
            run = function()
                for scene = 1, 3 do
                    TestRunner.truthy(
                        NamelessNight.attack(scene) ~= nil,
                        "scene " .. scene .. " has no telegraph"
                    )
                end
                TestRunner.equal(NamelessNight.attack(4), nil)
                TestRunner.equal(NamelessNight.attack(5), nil)

                -- and none of them is borrowed from the Crown
                local seen: { [string]: boolean } = {}
                for _, telegraph in
                    {
                        NamelessNight.attack(1),
                        NamelessNight.attack(2),
                        NamelessNight.attack(3),
                        AshRegent.attack(1, 1, "anchored"),
                        AshRegent.attack(1, 1, "exposed"),
                    }
                do
                    local id = (telegraph :: any).attackId
                    TestRunner.equal(seen[id], nil, "shared telegraph: " .. id)
                    seen[id] = true
                end
            end,
        },
        {
            name = "the finale honors its kill switch",
            run = function()
                local dark = NamelessNight.create(RUN, HASH, false)
                local _, unlocked = NamelessNight.unlock(dark)
                TestRunner.equal(unlocked.accepted, false)
                local _, held = NamelessNight.holdPost(dark, 7, "post_gate")
                TestRunner.equal(held.accepted, false)
                local _, chosen = NamelessNight.choose(dark, 7, "ending_kept")
                TestRunner.equal(chosen.accepted, false)
            end,
        },
    },
}
