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
            name = "handlers and anchors cover each other in every wired region",
            run = function()
                for _, regionId in
                    {
                        "region_ironroot",
                        "region_mireglass",
                        "region_tempest",
                        "region_frostmere",
                    }
                do
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
        {
            --[[
                The Reach's elites rent their windows rather than buying
                them: the Eater's beacons gutter and the Admiral's crew
                re-rigs cut lines, and both clocks live in the wiring
                because neither state keeps a timestamp. Driven through
                the definitions' own ticks so the region cannot ship with
                a window that never closes.
            ]]
            name = "the Reach's elites open their windows and the clocks close them",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_tempest")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end

                local eater = byId.elite_lighthouse_eater
                local state = eater.module.create("run", "hash", true)
                state = (drive(eater, state, "challenge"))
                TestRunner.equal(state.status, "hidden")
                state = (drive(eater, state, "beacon_point"))
                TestRunner.equal(state.status, "drawn")
                local guttered = eater.tick(state, 1000 + eater.module.BeaconSeconds + 1) :: any
                TestRunner.equal(guttered.status, "hidden")

                local wreck = byId.elite_admiral_wreck
                local wreckState = wreck.module.create("run", "hash", true)
                wreckState = (drive(wreck, wreckState, "challenge"))
                TestRunner.equal(wreckState.status, "covered")
                for _, lineId in wreck.module.LineIds do
                    wreckState = (drive(wreck, wreckState, lineId))
                end
                TestRunner.equal(wreckState.status, "exposed")
                -- the tick's first sight of a cut only starts its clock
                TestRunner.equal(wreck.tick(wreckState, 2000), nil)
                local rerigged =
                    wreck.tick(wreckState, 2000 + wreck.module.Tuning.lineRerigSeconds) :: any
                TestRunner.equal(rerigged.status, "covered")
                TestRunner.truthy(wreck.module.cutCount(rerigged) < #wreck.module.LineIds)
            end,
        },
        {
            --[[
                The Titan's whole verb chain -- climb, ground, work the
                gates, strike -- driven through the wiring to completion,
                with the gate cadence the module's outcome thresholds
                assume: a gate answers once a phase, whichever verb worked
                it, so slams count decisions rather than presses.
            ]]
            name = "the Titan falls through its verbs and the gates resolve chapter four",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_tempest")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end
                local titan = byId.boss_tidebound_titan
                TestRunner.truthy(titan.lockedUntil ~= nil, "the Titan must wait on the elites")

                local state = titan.module.create("run", "hash", true)
                TestRunner.equal(state.status, "locked")
                state = select(1, titan.module.unlock(state))
                state = (drive(titan, state, "challenge"))
                TestRunner.equal(state.status, "unreachable")

                -- ease both, then mixed, then slam both: three slams in
                -- all, which is a night that went both ways
                local gatePlan = {
                    { gate_north = "gate_north", gate_south = "gate_south" },
                    { gate_north = "gate_north", gate_south = "gate_south_slam" },
                    { gate_north = "gate_north_slam", gate_south = "gate_south_slam" },
                }
                for phase = 1, 3 do
                    TestRunner.equal(state.phase, phase)
                    for _, wreckId in titan.module.WreckIds do
                        if state.status == "unreachable" then
                            state = (drive(titan, state, wreckId))
                        end
                    end
                    TestRunner.equal(state.status, "grounding")
                    for _, rodId in titan.module.RodIds do
                        state = (drive(titan, state, rodId))
                    end
                    TestRunner.equal(state.status, "exposed")
                    state = (drive(titan, state, gatePlan[phase].gate_north))
                    state = (drive(titan, state, gatePlan[phase].gate_south))
                    if phase == 1 then
                        -- a second working of the same gate in the same
                        -- phase is refused, by either verb
                        local held, easedAgain = drive(titan, state, "gate_north")
                        TestRunner.equal(easedAgain.accepted, false)
                        TestRunner.equal(held.slammedGates, state.slammedGates)
                        local heldSlam, slamAfter = drive(titan, state, "gate_north_slam")
                        TestRunner.equal(slamAfter.accepted, false)
                        TestRunner.equal(heldSlam.slammedGates, state.slammedGates)
                    end
                    local finished = false
                    for _ = 1, 8 do
                        local result
                        state, result = titan.module.strike(state, PLAYER.UserId, 100)
                        if result.phaseFinished then
                            finished = result.completed == true
                            break
                        end
                    end
                    TestRunner.equal(finished, phase == 3, "phase " .. phase .. " did not turn")
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.slammedGates, 3)
                TestRunner.equal(state.outcome, "scoured")

                local resolve = assert(titan.chapterResolution, "the Titan resolves no chapter")
                local resolution = resolve(state)
                TestRunner.equal(resolution.chapterId, "chapter_four")
                TestRunner.equal(resolution.decision, "mixed_gates")
                TestRunner.equal(resolution.outcome, "scoured")
                TestRunner.truthy(ChapterCatalog.isDecision("chapter_four", resolution.decision))
                TestRunner.truthy(ChapterCatalog.isOutcome("chapter_four", resolution.outcome))

                -- and the two policies map to their own decisions
                local eased = table.clone(state)
                eased.slammedGates = 0
                eased.outcome = "navigable"
                TestRunner.equal(resolve(eased).decision, "eased_gates")
                TestRunner.truthy(ChapterCatalog.isDecision("chapter_four", "eased_gates"))
                local slammed = table.clone(state)
                slammed.slammedGates = 6
                slammed.outcome = "broken"
                TestRunner.equal(resolve(slammed).decision, "slammed_gates")
                TestRunner.truthy(ChapterCatalog.isOutcome("chapter_four", "broken"))
            end,
        },
        {
            --[[
                The Vale's elites both rent their windows on a clock, and
                only one of the two states keeps a timestamp. The Silence
                writes its bells' own expiry into the state, so its tick
                is the module's; the Hart counts splits and times nothing,
                so its clock lives in the wiring the way the Admiral's
                re-rig does. Driven through the definitions' own ticks so
                neither can ship with a window that never closes -- or
                one that closes on the tick that opened it.
            ]]
            name = "the Vale's elites open their windows and the clocks close them",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_frostmere")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end

                local silence = byId.elite_abbey_silence
                local state = silence.module.create("run", "hash", true)
                state = (drive(silence, state, "challenge"))
                TestRunner.equal(state.status, "silent")
                state = (drive(silence, state, "bell_cloister"))
                TestRunner.equal(state.status, "ringing")
                local smothered = silence.tick(state, 1000 + silence.module.BellSeconds + 1) :: any
                TestRunner.equal(smothered.status, "silent")

                local hart = byId.elite_aurora_hart
                local hartState = hart.module.create("run", "hash", true)
                hartState = (drive(hart, hartState, "challenge"))
                -- the clearing starts gathered, which is what the Hart is
                -- there to undo
                TestRunner.equal(hartState.status, "banked")
                -- the tick's first sight of a live fight only starts the
                -- clock; nothing splits on the tick that opened the fight
                TestRunner.equal(hart.tick(hartState, 2000), nil)
                local split =
                    hart.tick(hartState, 2000 + hart.module.Tuning.splitIntervalSeconds) :: any
                TestRunner.equal(split.status, "split")
                TestRunner.equal(split.splits, 1)

                --[[
                    Every accepted carry gathers, which is the whole
                    reason the anchor is the hearth warmth leaves rather
                    than the one it arrives at. Written the other way
                    round this case passes its first assertion and then
                    the fight comes apart under a player pressing the
                    hearth they are trying to build up.
                ]]
                local scattered: string? = nil
                for _, hearthId in hart.module.HearthIds do
                    if hearthId ~= "hearth_north" and (split.hearths[hearthId] or 0) > 0 then
                        scattered = hearthId
                    end
                end
                TestRunner.truthy(scattered ~= nil, "the Hart split nothing out of the north")
                local regathered = (drive(hart, split, scattered :: string))
                TestRunner.equal(regathered.status, "banked")
                TestRunner.equal(regathered.hearths[scattered :: string], 0)
                TestRunner.equal(regathered.hearths.hearth_north, hart.module.BankedLevel)
                -- the hearth that holds the fire is refused rather than
                -- emptied into a cold one
                local held, refused = drive(hart, regathered, "hearth_north")
                TestRunner.equal(refused.accepted, false)
                TestRunner.equal(held.hearths.hearth_north, hart.module.BankedLevel)
                -- and so is a hearth with nothing left in it
                local stillHeld, cold = drive(hart, regathered, scattered :: string)
                TestRunner.equal(cold.accepted, false)
                TestRunner.equal(stillHeld.status, "banked")
            end,
        },
        {
            --[[
                The Howler's whole verb chain -- hush the bowl, share the
                warmth, read the aurora in order, strike -- driven through
                the wiring to completion three times over, because the
                chapter's decision is made once per phase and only the
                count of them is recorded.
            ]]
            name = "the Howler falls through its verbs and the warmth resolves chapter five",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_frostmere")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end
                local howler = byId.boss_white_howler
                TestRunner.truthy(howler.lockedUntil ~= nil, "the Howler must wait on the elites")

                local state = howler.module.create("run", "hash", true)
                TestRunner.equal(state.status, "locked")
                state = select(1, howler.module.unlock(state))
                state = (drive(howler, state, "challenge"))
                TestRunner.equal(state.status, "listening")

                -- our fire, then the den, then the den: two phases paid,
                -- which is the night that went both ways
                local warmthPlan = {
                    { "warmth_lantern", "warmth_kettle" },
                    { "warmth_lantern_den", "warmth_kettle" },
                    { "warmth_lantern_den", "warmth_kettle" },
                }
                for phase = 1, 3 do
                    TestRunner.equal(state.phase, phase)
                    for _, noiseId in howler.module.NoiseIds do
                        if state.status == "listening" then
                            state = (drive(howler, state, noiseId))
                        end
                    end
                    TestRunner.equal(state.status, "warming")
                    for _, warmthId in warmthPlan[phase] do
                        state = (drive(howler, state, warmthId))
                    end
                    TestRunner.equal(state.status, "tracking")
                    local required = howler.module.tracksRequired(state)
                    -- the den is paid for in marks: a phase that warmed it
                    -- has one more of them to read
                    TestRunner.equal(required, if phase == 1 then 2 else 3)
                    for index = 1, required do
                        state = (drive(howler, state, howler.module.TrackIds[index]))
                    end
                    TestRunner.equal(state.status, "exposed")
                    for _ = 1, 20 do
                        local result
                        state, result = howler.module.strike(state, PLAYER.UserId, 45)
                        if result.phase > phase or result.completed then
                            break
                        end
                    end
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.outcome, "thinned")

                local resolve = assert(howler.chapterResolution, "the Howler resolves no chapter")
                local resolution = resolve(state)
                TestRunner.equal(resolution.chapterId, "chapter_five")
                TestRunner.equal(resolution.decision, "split_warmth")
                TestRunner.equal(resolution.outcome, "thinned")
                TestRunner.truthy(ChapterCatalog.isDecision("chapter_five", resolution.decision))
                TestRunner.truthy(ChapterCatalog.isOutcome("chapter_five", resolution.outcome))

                -- and the two policies map to their own decisions
                local kept = table.clone(state)
                kept.denPhases = { false, false, false }
                kept.outcome = "silenced"
                TestRunner.equal(resolve(kept).decision, "kept_warmth")
                TestRunner.truthy(ChapterCatalog.isDecision("chapter_five", "kept_warmth"))
                TestRunner.truthy(ChapterCatalog.isOutcome("chapter_five", "silenced"))
                local warmed = table.clone(state)
                warmed.denPhases = { true, true, true }
                warmed.outcome = "sheltered"
                TestRunner.equal(resolve(warmed).decision, "warmed_den")
                TestRunner.truthy(ChapterCatalog.isDecision("chapter_five", "warmed_den"))
                TestRunner.truthy(ChapterCatalog.isOutcome("chapter_five", "sheltered"))
            end,
        },
        {
            --[[
                A lost trail is the one branch in the Vale where the next
                instruction is a lie by omission. The module sends the
                phase back to the noise, so the generic wrapper would
                answer a party that had just hushed the bowl and spent
                its warmth with "QUIET THE BOWL -- 0 OF 3" and no reason.
                The walk read exactly that and could not tell a reset
                from a press that did nothing.
            ]]
            name = "a misread aurora mark says so instead of reading as a fresh phase",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_frostmere")
                local howler
                for _, definition in definitions do
                    if definition.id == "boss_white_howler" then
                        howler = definition
                    end
                end
                local state = howler.module.create("run", "hash", true)
                state = select(1, howler.module.unlock(state))
                state = (drive(howler, state, "challenge"))
                for _, noiseId in howler.module.NoiseIds do
                    if state.status == "listening" then
                        state = (drive(howler, state, noiseId))
                    end
                end
                state = (drive(howler, state, "warmth_lantern"))
                state = (drive(howler, state, "warmth_kettle"))
                TestRunner.equal(state.status, "tracking")
                local expected = howler.module.TrackIds[1]
                local wrong = howler.module.TrackIds[#howler.module.TrackIds]
                TestRunner.truthy(wrong ~= expected, "the Vale needs more than one aurora mark")
                local lost, result = drive(howler, state, wrong)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(lost.status, "listening")
                local reset = howler.module.snapshot(lost, PLAYER.UserId, 1000).instruction
                TestRunner.truthy(
                    result.message ~= reset,
                    "a lost trail answered with the phase's opening instruction"
                )
                -- and the marks carry the aurora's own order, because the
                -- fight is lost by guessing at an order nothing states
                local names = {}
                for _, entry in howler.anchors do
                    names[entry.id] = entry.object
                end
                for index, trackId in howler.module.TrackIds do
                    TestRunner.truthy(
                        names[trackId] ~= nil and #names[trackId] > 0,
                        trackId .. " has no name"
                    )
                    TestRunner.truthy(
                        names[trackId] ~= names[howler.module.TrackIds[1]] or index == 1,
                        "two aurora marks share a name"
                    )
                end
            end,
        },
    },
}
