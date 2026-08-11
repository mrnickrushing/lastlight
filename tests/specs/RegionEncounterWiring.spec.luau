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
            --[[
                An arena names each anchor on a billboard, and two
                billboards reading the same words are two pillars a party
                has to tell apart by walking to both. The Regent's box
                shipped exactly that -- ten anchors, five names, each
                twice, because reading a statue and breaking it name the
                same statue -- and it is the worst place in the game for
                it, since one of each pair is free and the other ends the
                chapter and cannot be taken back. Held over every wired
                region, because the rule is about arenas rather than
                about the Crown.
            ]]
            name = "no two anchors in one arena are labelled the same",
            run = function()
                for _, regionId in
                    {
                        "region_ironroot",
                        "region_mireglass",
                        "region_tempest",
                        "region_frostmere",
                        "region_cinderfall",
                    }
                do
                    for _, definition in RegionEncounterWiring.definitionsFor(regionId) do
                        local labels = RegionEncounterWiring.anchorLabels(definition)
                        local seen: { [string]: string } = {}
                        for _, anchor in definition.anchors do
                            local label = labels[anchor.id]
                            TestRunner.truthy(
                                type(label) == "string" and #label > 0,
                                definition.id .. "/" .. anchor.id .. " has no label"
                            )
                            TestRunner.equal(
                                seen[label],
                                nil,
                                definition.id
                                    .. " labels "
                                    .. anchor.id
                                    .. " and "
                                    .. tostring(seen[label])
                                    .. " both "
                                    .. label
                            )
                            seen[label] = anchor.id
                        end
                    end
                end
            end,
        },
        {
            --[[
                The verb is borrowed only where it is needed. An anchor
                whose object nothing else in its ring shares keeps exactly
                the label its region's own live walk signed off, so this
                cannot quietly relabel arenas a person already looked at.

                Written as a rule rather than as a list of regions because
                the first draft was a list, and the list was wrong: it
                assumed only the Regent's box had a collision, and the
                Titan's tide gates -- EASE and SLAM on one gate, in a
                region that shipped open after a live walk -- have carried
                the same one since the Reach opened.
            ]]
            name = "the verb joins a label only where the object is ambiguous",
            run = function()
                for _, regionId in
                    {
                        "region_ironroot",
                        "region_mireglass",
                        "region_tempest",
                        "region_frostmere",
                        "region_cinderfall",
                    }
                do
                    for _, definition in RegionEncounterWiring.definitionsFor(regionId) do
                        local counts: { [string]: number } = {}
                        for _, anchor in definition.anchors do
                            counts[anchor.object] = (counts[anchor.object] or 0) + 1
                        end
                        local labels = RegionEncounterWiring.anchorLabels(definition)
                        for _, anchor in definition.anchors do
                            if counts[anchor.object] == 1 then
                                TestRunner.equal(
                                    labels[anchor.id],
                                    anchor.object,
                                    definition.id .. "/" .. anchor.id .. " was relabelled"
                                )
                            else
                                TestRunner.truthy(
                                    string.find(labels[anchor.id], anchor.action, 1, true) ~= nil
                                        and string.find(
                                                labels[anchor.id],
                                                anchor.object,
                                                1,
                                                true
                                            )
                                            ~= nil,
                                    definition.id
                                        .. "/"
                                        .. anchor.id
                                        .. " shares an object and does not name its verb"
                                )
                            end
                        end
                    end
                end
            end,
        },
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
                        "region_cinderfall",
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
        {
            --[[
                Both Crown elites are driven entirely by clocks the
                modules do not keep: the Actor's broken scene closes
                itself, and the Bailiff marks, sentences and adjourns on
                its own. Three waits and two tuning values, so the tick is
                the only place any of it can be wrong.
            ]]
            name = "the Crown's elites open their windows and the clocks close them",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_cinderfall")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end

                local actor = byId.elite_lead_actor
                local state = actor.module.create("run", "hash", true)
                state = (drive(actor, state, "challenge"))
                TestRunner.equal(state.status, "performing")
                -- the first line is two beats, called in the module's own
                -- order, and answering both breaks the scene
                for _ = 1, actor.module.lineLength(state) do
                    state = (drive(actor, state, actor.module.expectedBeat(state)))
                end
                TestRunner.equal(state.status, "broken")
                -- the tick's first sight of a broken scene only starts the
                -- clock; nothing resumes on the tick that broke it
                TestRunner.equal(actor.tick(state, 3000), nil)
                local resumed = actor.tick(state, 3000 + actor.module.Tuning.brokenSeconds) :: any
                TestRunner.equal(resumed.status, "performing")
                TestRunner.equal(resumed.linesCleared, 1)
                -- and the window is real: a strike lands only inside it
                local _, refused = actor.module.strike(resumed, PLAYER.UserId, 32)
                TestRunner.equal(refused.accepted, false)
                local hurt, landed = actor.module.strike(state, PLAYER.UserId, 32)
                TestRunner.equal(landed.accepted, true)
                TestRunner.equal(hurt.health, actor.module.MaxHealth - 32)

                local bailiff = byId.elite_glass_bailiff
                local court = bailiff.module.create("run", "hash", true)
                court = (drive(bailiff, court, "challenge"))
                TestRunner.equal(court.status, "sitting")
                TestRunner.equal(court.marked, nil)
                TestRunner.equal(bailiff.tick(court, 1000), nil)
                local marked =
                    bailiff.tick(court, 1000 + bailiff.module.Tuning.markIntervalSeconds) :: any
                TestRunner.truthy(marked.marked ~= nil, "the Bailiff marked nothing")
                -- an appeal keeps the wall and gives no window
                local upheld = (drive(bailiff, marked, marked.marked))
                TestRunner.equal(upheld.marked, nil)
                TestRunner.equal(upheld.status, "sitting")
                TestRunner.equal(bailiff.module.standingCount(upheld), 4)
                -- letting one fall is the only thing that opens one
                TestRunner.equal(bailiff.tick(upheld, 2000), nil)
                local remarked =
                    bailiff.tick(upheld, 2000 + bailiff.module.Tuning.markIntervalSeconds) :: any
                TestRunner.truthy(remarked.marked ~= nil, "the Bailiff stopped marking")
                TestRunner.equal(bailiff.tick(remarked, 3000), nil)
                local fallen =
                    bailiff.tick(remarked, 3000 + bailiff.module.Tuning.sentenceSeconds) :: any
                TestRunner.equal(fallen.status, "sentencing")
                TestRunner.equal(bailiff.module.standingCount(fallen), 3)
                -- a blow is worth its whole self only while it is occupied
                local _, deflected = bailiff.module.strike(upheld, PLAYER.UserId, 34)
                local _, full = bailiff.module.strike(fallen, PLAYER.UserId, 34)
                TestRunner.equal(full.damage, 34)
                TestRunner.truthy(
                    deflected.damage < full.damage,
                    "a sitting Bailiff took a full blow"
                )
                -- and the court reopens, or the fight has one window in it
                TestRunner.equal(bailiff.tick(fallen, 4000), nil)
                local adjourned =
                    bailiff.tick(fallen, 4000 + bailiff.module.Tuning.sentenceSeconds) :: any
                TestRunner.equal(adjourned.status, "sitting")
            end,
        },
        {
            --[[
                Two facts this region's fights turn on ride in snapshots
                no client reads: which beat the Actor called, and which
                structure the Bailiff marked. Unspoken, both arenas are a
                row of identical prompts under an instruction that only
                counts -- the Vale's aurora order again, twice. These
                cases hold the seam that says them out loud.
            ]]
            name = "a called beat and a marked structure are spoken, not guessed at",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_cinderfall")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end

                local actor = byId.elite_lead_actor
                local state, opened =
                    drive(actor, actor.module.create("run", "hash", true), "challenge")
                local bare = actor.module.snapshot(state, PLAYER.UserId).instruction
                TestRunner.truthy(
                    opened.message ~= bare,
                    "the Actor took the stage without naming the beat it called"
                )
                local names: { [string]: string } = {}
                for _, entry in actor.anchors do
                    names[entry.id] = entry.object
                end
                local called = actor.module.expectedBeat(state)
                TestRunner.truthy(
                    string.find(opened.message, names[called], 1, true) ~= nil,
                    "the Actor's call names no beat a player can find"
                )
                --[[
                    A missed beat resets the line and changes nothing else,
                    so the generic wrapper answers a party that just lost
                    its progress with the instruction it started on.
                ]]
                local wrong = called
                for _, beatId in actor.module.BeatIds do
                    if beatId ~= called then
                        wrong = beatId
                    end
                end
                local lost, missed = drive(actor, state, wrong)
                TestRunner.equal(missed.accepted, false)
                TestRunner.equal(lost.position, 0)
                TestRunner.truthy(
                    missed.message ~= bare,
                    "a missed beat answered with the line's own opening instruction"
                )

                local bailiff = byId.elite_glass_bailiff
                local court = (
                    drive(bailiff, bailiff.module.create("run", "hash", true), "challenge")
                )
                -- the first tick only starts the clock, so a mark takes two
                -- of them here the same way it does in the fight
                bailiff.tick(court, 1000)
                local marked =
                    bailiff.tick(court, 1000 + bailiff.module.Tuning.markIntervalSeconds) :: any
                local structureNames: { [string]: string } = {}
                for _, entry in bailiff.anchors do
                    structureNames[entry.id] = entry.object
                end
                -- appealing the wrong wall has to say which one it wanted,
                -- because the refusal is "not that one", not "nothing"
                local other = marked.marked
                for _, structureId in bailiff.module.StructureIds do
                    if structureId ~= marked.marked then
                        other = structureId
                    end
                end
                local _, wrongWall = drive(bailiff, marked, other)
                TestRunner.equal(wrongWall.accepted, false)
                TestRunner.truthy(
                    string.find(wrongWall.message, structureNames[marked.marked], 1, true) ~= nil,
                    "the Bailiff refused an appeal without naming what it marked"
                )
            end,
        },
        {
            --[[
                The Regent's whole chain -- read a statue, break enough of
                its anchors, strike the phase down, four times over -- and
                the chapter's decision, which is nothing but a count of
                the true faces a party smashed on the way. Driven the
                honest way first: every phase offers three false statues,
                so the Crown can always be finished without erasing
                anybody, and a run that cannot would be a chapter with one
                real ending.
            ]]
            name = "the Regent falls through its verbs and the broken statues resolve chapter six",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_cinderfall")
                local byId: { [string]: any } = {}
                for _, definition in definitions do
                    byId[definition.id] = definition
                end
                local regent = byId.boss_ash_regent
                TestRunner.truthy(regent.lockedUntil ~= nil, "the Regent must wait on the elites")

                local state = regent.module.create("run", "hash", true)
                TestRunner.equal(state.status, "locked")
                state = select(1, regent.module.unlock(state))
                state = (drive(regent, state, "challenge"))
                TestRunner.equal(state.status, "anchored")

                for phase = 1, 4 do
                    TestRunner.equal(state.phase, phase)
                    local authentic: { [string]: boolean } = {}
                    for _, statueId in regent.module.authenticIds(phase) do
                        authentic[statueId] = true
                    end
                    local casts = 0
                    for _, statueId in regent.module.StatueIds do
                        if not authentic[statueId] and state.status == "anchored" then
                            -- read it first, which is what makes the
                            -- choice a choice rather than a coin flip
                            local read, learned = drive(regent, state, statueId)
                            TestRunner.equal(learned.accepted, true)
                            state = read
                            state = (drive(regent, state, statueId .. "_break"))
                            casts += 1
                        end
                    end
                    TestRunner.equal(casts, 3, "a phase with no honest way through it")
                    TestRunner.equal(state.status, "exposed")
                    TestRunner.equal(state.erased, 0)
                    for _ = 1, 24 do
                        local result
                        state, result = regent.module.strike(state, PLAYER.UserId, 45)
                        if result.phase > phase or result.completed then
                            break
                        end
                    end
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(regent.module.outcome(state), "remembered")

                local resolve = assert(regent.chapterResolution, "the Regent resolves no chapter")
                local resolution = resolve(state)
                TestRunner.equal(resolution.chapterId, "chapter_six")
                TestRunner.equal(resolution.decision, "spared_memories")
                TestRunner.equal(resolution.outcome, "remembered")
                TestRunner.truthy(ChapterCatalog.isDecision("chapter_six", resolution.decision))
                TestRunner.truthy(ChapterCatalog.isOutcome("chapter_six", resolution.outcome))

                -- and the two costlier readings map to their own decisions
                local some = table.clone(state)
                some.erased = 1
                TestRunner.equal(resolve(some).decision, "broke_some")
                TestRunner.equal(resolve(some).outcome, "recast")
                TestRunner.truthy(ChapterCatalog.isDecision("chapter_six", "broke_some"))
                TestRunner.truthy(ChapterCatalog.isOutcome("chapter_six", "recast"))
                local all = table.clone(state)
                all.erased = 3
                TestRunner.equal(resolve(all).decision, "broke_them_all")
                TestRunner.equal(resolve(all).outcome, "erased")
                TestRunner.truthy(ChapterCatalog.isDecision("chapter_six", "broke_them_all"))
                TestRunner.truthy(ChapterCatalog.isOutcome("chapter_six", "erased"))
            end,
        },
        {
            --[[
                Reading a statue is the one thing in the Crown that costs
                nothing but time, and the Regent's instruction only ever
                counts anchors -- so a read wired through the generic
                wrapper answers exactly like a read that did nothing, and
                the fight's whole argument becomes a coin flip.
            ]]
            name = "reading a statue says what it is, and breaking it is a separate press",
            run = function()
                local definitions = RegionEncounterWiring.definitionsFor("region_cinderfall")
                local regent
                for _, definition in definitions do
                    if definition.id == "boss_ash_regent" then
                        regent = definition
                    end
                end
                local state = regent.module.create("run", "hash", true)
                state = select(1, regent.module.unlock(state))
                state = (drive(regent, state, "challenge"))
                local counting = regent.module.snapshot(state, PLAYER.UserId).instruction

                local real = regent.module.authenticIds(state.phase)[1]
                local cast
                for _, statueId in regent.module.StatueIds do
                    if not regent.module.isAuthentic(state.phase, statueId) then
                        cast = statueId
                    end
                end
                local _, realRead = drive(regent, state, real)
                local _, castRead = drive(regent, state, cast)
                TestRunner.truthy(realRead.message ~= counting, "a read answered with the count")
                TestRunner.truthy(
                    realRead.message ~= castRead.message,
                    "a true face and a cast read the same"
                )

                -- reading never breaks anything, and every statue's break
                -- is its own anchor, because breaking a true one is the
                -- chapter's decision and cannot be undone
                local looked = (drive(regent, state, real))
                TestRunner.equal(looked.broken[real], nil)
                TestRunner.equal(looked.erased, 0)
                local ids: { [string]: boolean } = {}
                for _, entry in regent.anchors do
                    ids[entry.id] = true
                end
                for _, statueId in regent.module.StatueIds do
                    TestRunner.truthy(ids[statueId], statueId .. " cannot be read")
                    TestRunner.truthy(ids[statueId .. "_break"], statueId .. " cannot be broken")
                end
                local smashed = (drive(regent, looked, real .. "_break"))
                TestRunner.equal(smashed.broken[real], true)
                TestRunner.equal(smashed.erased, 1)
            end,
        },
    },
}
