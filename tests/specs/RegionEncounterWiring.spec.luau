--!strict

--[[
    The wiring is the seam between six pure fights and the arenas that
    hold them, and it is the seam where a fight becomes unfinishable
    without anything failing: a lever with no handler is a fight that
    cannot be exposed, an anchor list missing a verb's id is an arena
    built without the thing the instruction tells you to find. The live
    walks that opened the Delve and the Fen each drove one seed's worth
    of this; these cases drive every handler against the modules' own
    state machines so the next region cannot ship a dead anchor.
]]

local ChapterCatalog = require("../../src/shared/ChapterCatalog")
local RegionEncounterWiring = require("../../src/shared/RegionEncounterWiring")
local TestRunner = require("../TestRunner")

local PLAYER = { UserId = 77 }

local function anchorIds(definition: any): { [string]: boolean }
    local ids: { [string]: boolean } = {}
    for _, anchor in definition.anchors do
        TestRunner.equal(ids[anchor.id], nil, definition.id .. " repeats anchor " .. anchor.id)
        ids[anchor.id] = true
        TestRunner.truthy(#anchor.action > 0, anchor.id .. " has no action text")
        TestRunner.truthy(#anchor.object > 0, anchor.id .. " has no object text")
    end
    return ids
end

local function drive(definition: any, state: any, anchorId: string): (any, any)
    local handler = definition.interactions[anchorId]
    TestRunner.truthy(handler ~= nil, definition.id .. " has no handler for " .. anchorId)
    local nextState, result = handler(state, PLAYER, 1000)
    TestRunner.truthy(
        type(result) == "table" and type(result.message) == "string" and #result.message > 0,
        definition.id .. "/" .. anchorId .. " answered without a message"
    )
    return nextState, result
end

return {
    name = "RegionEncounterWiring",
    cases = {
        {
            -- Every handler answers an anchor the arena builds, and every
            -- anchor the arena builds has a handler. Either direction
            -- broken is a prompt wired to nothing.
            name = "handlers and anchors cover each other in both regions",
            run = function()
                for _, regionId in { "region_ironroot", "region_mireglass" } do
                    local definitions = RegionEncounterWiring.definitionsFor(regionId)
                    TestRunner.equal(#definitions, 3, regionId .. " should wire three fights")
                    for _, definition in definitions do
                        local ids = anchorIds(definition)
                        TestRunner.truthy(
                            ids[RegionEncounterWiring.ChallengeAnchorId],
                            definition.id .. " has no challenge anchor"
                        )
                        for anchorId in definition.interactions do
                            TestRunner.truthy(
                                ids[anchorId],
                                definition.id .. " handles " .. anchorId .. " with no anchor"
                            )
                        end
                        for anchorId in ids do
                            TestRunner.truthy(
                                definition.interactions[anchorId] ~= nil,
                                definition.id .. " builds " .. anchorId .. " with no handler"
                            )
                        end
                    end
                end
            end,
        },
        {
            -- The Delve's fights, driven through the wiring's own
            -- handlers rather than the modules directly, to completion.
            name = "the Delve's three fights complete through their anchors",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_ironroot")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end

                local echo = byId.elite_foreman_echo
                local state = echo.module.create("run", "hash", true)
                state = (drive(echo, state, "challenge"))
                for _, leverId in echo.module.LeverIds do
                    state = (drive(echo, state, leverId))
                end
                TestRunner.equal(state.status, "exposed")

                local maw = byId.boss_bellows_maw
                TestRunner.truthy(maw.lockedUntil ~= nil, "the Maw must wait on the elites")
                local mawState = maw.module.create("run", "hash", true)
                TestRunner.equal(mawState.status, "locked")
                mawState = select(1, maw.module.unlock(mawState))
                mawState = (drive(maw, mawState, "challenge"))
                mawState = (drive(maw, mawState, "line_head"))
                mawState = (drive(maw, mawState, "line_deep"))
                TestRunner.equal(mawState.status, "pressured")
                mawState = (drive(maw, mawState, "vent_stope"))
                TestRunner.equal(mawState.status, "exposed")
                local resolve = maw.chapterResolution
                TestRunner.truthy(resolve ~= nil, "the Maw resolves no chapter")
                local finished = maw.module.create("run", "hash", true)
                finished = select(1, maw.module.unlock(finished))
                finished = select(1, maw.module.activate(finished, PLAYER.UserId))
                finished.status = "complete"
                finished.outcome = "cleared"
                finished.ventedInto = { vent_stope = true }
                local resolution = (resolve :: any)(finished)
                TestRunner.equal(resolution.chapterId, "chapter_two")
                TestRunner.truthy(
                    ChapterCatalog.isDecision(resolution.chapterId, resolution.decision)
                )
                TestRunner.truthy(
                    ChapterCatalog.isOutcome(resolution.chapterId, resolution.outcome)
                )
            end,
        },
        {
            --[[
                The Fen's boss ends on an answer rather than a blow, and
                her module exports no strike at all -- which is exactly
                why the strike router needed its guard. The wiring is
                driven to her question and both answers checked against
                the chapter the resolution feeds.
            ]]
            name = "the Witch reaches her question and both answers resolve chapter three",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_mireglass")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end
                local witch = byId.boss_lantern_witch
                TestRunner.truthy(witch.lockedUntil ~= nil, "the Witch must wait on the elites")
                TestRunner.equal(type(witch.module.strike), "nil")

                local state = witch.module.create("run", "hash", true)
                state = select(1, witch.module.unlock(state))
                state = (drive(witch, state, "challenge"))
                for _ = 1, 3 do
                    local falseCopy = witch.module.falseCopy(state.round, state.phase)
                    state = (drive(witch, state, falseCopy))
                    TestRunner.equal(state.status, "found")
                    state = (drive(witch, state, falseCopy))
                end
                TestRunner.equal(state.status, "asking")

                local resolve = assert(witch.chapterResolution, "the Witch resolves no chapter")
                local spared, sparedResult = drive(witch, state, "witch_spare")
                TestRunner.equal(sparedResult.completed, true)
                local sparedResolution = resolve(spared)
                TestRunner.equal(sparedResolution.chapterId, "chapter_three")
                TestRunner.truthy(
                    ChapterCatalog.isDecision("chapter_three", sparedResolution.decision)
                )
                TestRunner.truthy(
                    ChapterCatalog.isOutcome("chapter_three", sparedResolution.outcome)
                )

                local refused, refusedResult = drive(witch, state, "witch_take")
                TestRunner.equal(refusedResult.completed, true)
                local refusedResolution = resolve(refused)
                TestRunner.equal(refusedResolution.decision, "refused_her")
                TestRunner.equal(refusedResolution.outcome, "broken")
            end,
        },
    },
}
