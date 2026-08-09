--!strict

--[[
    How the six region encounters plug into a world.

    RegionEncounterService drives any encounter that describes itself as
    an interaction table, and the encounter modules are pure state
    machines that never name a part or a prompt. This module is the seam
    between them: for each encounter it lists the anchors its arena needs
    with the words each prompt says, and wires each anchor to the verb the
    encounter answers it with. It lives in shared code so the Lune suite
    can hold the wiring against the encounter modules' own id lists --
    a lever with no handler, or a handler for a lever no arena builds, is
    a fight that cannot be finished, and nothing else would notice.

    Handlers return the encounter's own next instruction as the message,
    because the instruction lines already carry the progress a player
    needs ("THROW THE SIGNAL LEVERS -- 2 OF 3") and a second copy of that
    text would drift from the first.
]]

local AdmiralWreckEncounter = require("./AdmiralWreckEncounter")
local BellowsMawEncounter = require("./BellowsMawEncounter")
local DrownedCallerEncounter = require("./DrownedCallerEncounter")
local ForemanEchoEncounter = require("./ForemanEchoEncounter")
local IronWidowEncounter = require("./IronWidowEncounter")
local LanternWitchEncounter = require("./LanternWitchEncounter")
local LighthouseEaterEncounter = require("./LighthouseEaterEncounter")
local ManyFaceEncounter = require("./ManyFaceEncounter")
local Strings = require("./Strings")
local TideboundTitanEncounter = require("./TideboundTitanEncounter")

local RegionEncounterWiring = {}

export type Anchor = {
    id: string,
    action: string,
    object: string,
}

export type Definition = {
    id: string,
    regionId: string,
    module: any,
    anchors: { Anchor },
    interactions: { [string]: (state: any, player: any, now: number) -> (any, any) },
    tick: ((state: any, now: number) -> any?)?,
    -- Elite ids that must be complete before this encounter's challenge
    -- anchor will wake it. The Maw and the Witch wait on their region's
    -- elites, the way the Warden's Seal waits on the Old Growth.
    lockedUntil: { string }?,
    -- For a boss: how a finished state resolves its chapter.
    chapterResolution: ((
        state: any
    ) -> {
        chapterId: string,
        decision: string,
        outcome: string,
    })?,
}

-- Every arena gets one challenge anchor: the thing you touch to start
-- the fight. Its id is shared so the service can special-case nothing.
RegionEncounterWiring.ChallengeAnchorId = "challenge"

local function instructionOf(module: any, state: any, userId: number, now: number): string
    return tostring(module.snapshot(state, userId, now).instruction)
end

--[[
    Wrap an encounter verb so the toast a player reads is always the
    encounter's next instruction. `completed` rides through untouched;
    it is what tells the service to settle rewards.
]]
local function verb(
    module: any,
    call: (state: any, userId: number, now: number) -> (any, any)
): (state: any, player: any, now: number) -> (any, any)
    return function(state: any, player: any, now: number): (any, any)
        local nextState, result = call(state, player.UserId, now)
        local message = instructionOf(module, nextState, player.UserId, now)
        return nextState,
            {
                accepted = if type(result) == "table" then result.accepted else false,
                completed = if type(result) == "table" then result.completed == true else false,
                message = message,
            }
    end
end

local function challenge(module: any): (state: any, player: any, now: number) -> (any, any)
    return verb(module, function(state: any, userId: number, _now: number): (any, any)
        return module.activate(state, userId)
    end)
end

local function anchor(id: string, action: string, object: string): Anchor
    return { id = id, action = action, object = object }
end

function RegionEncounterWiring.definitionsFor(regionId: string): { Definition }
    if regionId == "region_ironroot" then
        local echoInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(ForemanEchoEncounter),
        }
        local echoAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.foreman_echo")
            ),
            anchor(
                "lever_north",
                Strings.get("encounter.throw"),
                Strings.get("encounter.north_signal_lever")
            ),
            anchor(
                "lever_shaft",
                Strings.get("encounter.throw"),
                Strings.get("encounter.shaft_signal_lever")
            ),
            anchor(
                "lever_south",
                Strings.get("encounter.throw"),
                Strings.get("encounter.south_signal_lever")
            ),
        }
        for _, leverId in ForemanEchoEncounter.LeverIds do
            echoInteractions[leverId] = verb(
                ForemanEchoEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return ForemanEchoEncounter.throwLever(state, userId, leverId)
                end
            )
        end

        local widowInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(IronWidowEncounter),
        }
        local widowAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.iron_widow")
            ),
        }
        local widowAnchorObjects: { [string]: string } = {
            anchor_head = Strings.get("encounter.head_web_anchor"),
            anchor_spur = Strings.get("encounter.spur_web_anchor"),
            anchor_tail = Strings.get("encounter.tail_web_anchor"),
            anchor_crown = Strings.get("encounter.crown_web_anchor"),
        }
        for _, anchorId in IronWidowEncounter.AnchorIds do
            table.insert(
                widowAnchors,
                anchor(anchorId, Strings.get("encounter.cut"), widowAnchorObjects[anchorId])
            )
            widowInteractions[anchorId] = verb(
                IronWidowEncounter,
                function(state: any, userId: number, now: number): (any, any)
                    return IronWidowEncounter.cutAnchor(state, userId, anchorId, now)
                end
            )
        end

        local mawInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(BellowsMawEncounter),
        }
        local mawAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.bellows_maw")
            ),
        }
        local mawObjects: { [string]: string } = {
            line_head = Strings.get("encounter.head_feed_line"),
            line_spur = Strings.get("encounter.spur_feed_line"),
            line_deep = Strings.get("encounter.deep_feed_line"),
            line_return = Strings.get("encounter.return_feed_line"),
            vent_drift = Strings.get("encounter.drift_vent_wheel"),
            vent_stope = Strings.get("encounter.stope_vent_wheel"),
        }
        for lineId in BellowsMawEncounter.LineIds :: { [string]: boolean } do
            table.insert(
                mawAnchors,
                anchor(lineId, Strings.get("encounter.reroute"), mawObjects[lineId])
            )
            mawInteractions[lineId] = verb(
                BellowsMawEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return BellowsMawEncounter.rerouteLine(state, userId, lineId)
                end
            )
        end
        for ventId in BellowsMawEncounter.VentIds :: { [string]: boolean } do
            table.insert(
                mawAnchors,
                anchor(ventId, Strings.get("expedition.vent"), mawObjects[ventId])
            )
            mawInteractions[ventId] = verb(
                BellowsMawEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return BellowsMawEncounter.ventPressure(state, userId, ventId)
                end
            )
        end
        table.sort(mawAnchors, function(left: Anchor, right: Anchor): boolean
            return left.id < right.id
        end)

        return {
            {
                id = ForemanEchoEncounter.Id,
                regionId = regionId,
                module = ForemanEchoEncounter,
                anchors = echoAnchors,
                interactions = echoInteractions,
                tick = ForemanEchoEncounter.expire,
            },
            {
                id = IronWidowEncounter.Id,
                regionId = regionId,
                module = IronWidowEncounter,
                anchors = widowAnchors,
                interactions = widowInteractions,
                tick = IronWidowEncounter.expire,
            },
            {
                id = BellowsMawEncounter.Id,
                regionId = regionId,
                module = BellowsMawEncounter,
                anchors = mawAnchors,
                interactions = mawInteractions,
                lockedUntil = { ForemanEchoEncounter.Id, IronWidowEncounter.Id },
                chapterResolution = function(state: any)
                    local drift = state.ventedInto.vent_drift == true
                    local stope = state.ventedInto.vent_stope == true
                    local decision = if drift and stope
                        then "vent_both"
                        elseif drift then "vent_drifts"
                        else "vent_stope"
                    return {
                        chapterId = "chapter_two",
                        decision = decision,
                        outcome = tostring(state.outcome),
                    }
                end,
            },
        }
    elseif regionId == "region_mireglass" then
        local faceInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(ManyFaceEncounter),
        }
        local faceAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.the_many_face")
            ),
        }
        local mirrorObjects: { [string]: string } = {
            mirror_left = Strings.get("encounter.left_court_mirror"),
            mirror_center = Strings.get("encounter.center_court_mirror"),
            mirror_right = Strings.get("encounter.right_court_mirror"),
        }
        for mirrorId in ManyFaceEncounter.MirrorIds :: { [string]: boolean } do
            table.insert(
                faceAnchors,
                anchor(mirrorId, Strings.get("expedition.turn"), mirrorObjects[mirrorId])
            )
            faceInteractions[mirrorId] = verb(
                ManyFaceEncounter,
                function(state: any, userId: number, now: number): (any, any)
                    return ManyFaceEncounter.turnMirror(state, userId, mirrorId, now)
                end
            )
        end
        table.sort(faceAnchors, function(left: Anchor, right: Anchor): boolean
            return left.id < right.id
        end)
        --[[
            The Many-Face changes face on its own clock as well as closing
            its counter window, so its tick carries a second timestamp the
            state does not: when the next face is due. A closure holds it
            because the cadence belongs to this run of the fight, and
            beginRun builds fresh definitions for every run.
        ]]
        local nextFaceAt = 0
        local function manyFaceTick(state: any, now: number): any?
            local expired = ManyFaceEncounter.expire(state, now)
            if expired.status ~= "wearing" and expired.status ~= "countered" then
                nextFaceAt = 0
                return if expired == state then nil else expired
            end
            if nextFaceAt == 0 then
                nextFaceAt = now + ManyFaceEncounter.Tuning.faceSeconds
            end
            if now >= nextFaceAt then
                nextFaceAt = now + ManyFaceEncounter.Tuning.faceSeconds
                local cycled = ManyFaceEncounter.cycleFace(expired)
                return cycled
            end
            return if expired == state then nil else expired
        end

        local callerInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(DrownedCallerEncounter),
        }
        local callerAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.drowned_caller")
            ),
        }
        local poolObjects: { [string]: string } = {
            pool_north = Strings.get("encounter.north_reflected_pool"),
            pool_east = Strings.get("encounter.east_reflected_pool"),
            pool_south = Strings.get("encounter.south_reflected_pool"),
            pool_west = Strings.get("encounter.west_reflected_pool"),
        }
        for _, poolId in DrownedCallerEncounter.PoolIds do
            table.insert(
                callerAnchors,
                anchor(poolId, Strings.get("encounter.silt"), poolObjects[poolId])
            )
            callerInteractions[poolId] = verb(
                DrownedCallerEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return DrownedCallerEncounter.siltPool(state, userId, poolId)
                end
            )
        end

        local witchInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(LanternWitchEncounter),
        }
        local witchAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.lantern_witch")
            ),
        }
        local copyObjects: { [string]: string } = {
            copy_first = Strings.get("encounter.first_lantern_copy"),
            copy_second = Strings.get("encounter.second_lantern_copy"),
            copy_third = Strings.get("encounter.third_lantern_copy"),
            copy_fourth = Strings.get("encounter.fourth_lantern_copy"),
        }
        for _, copyId in LanternWitchEncounter.CopyIds do
            table.insert(
                witchAnchors,
                anchor(copyId, Strings.get("encounter.name"), copyObjects[copyId])
            )
            --[[
                One anchor, two verbs, chosen by the state rather than the
                payload: while she hides, touching a copy names it; once
                she is found, touching the found copy spends it against
                her. Sparing and the final answer live on their own
                anchors, because a mercy that shares a button with an
                attack is a misclick with a consequence.
            ]]
            witchInteractions[copyId] = function(state: any, player: any, now: number): (any, any)
                local nextState, result
                if state.status == "found" then
                    nextState, result = LanternWitchEncounter.useCopy(state, player.UserId, true)
                else
                    nextState, result = LanternWitchEncounter.nameCopy(state, player.UserId, copyId)
                end
                return nextState,
                    {
                        accepted = if type(result) == "table" then result.accepted else false,
                        completed = if type(result) == "table"
                            then result.completed == true
                            else false,
                        message = instructionOf(
                            LanternWitchEncounter,
                            nextState,
                            player.UserId,
                            now
                        ),
                    }
            end
        end
        table.insert(
            witchAnchors,
            anchor(
                "witch_spare",
                Strings.get("encounter.spare"),
                Strings.get("encounter.the_found_copy")
            )
        )
        witchInteractions.witch_spare = verb(
            LanternWitchEncounter,
            function(state: any, userId: number, _now: number): (any, any)
                if state.status == "asking" then
                    return LanternWitchEncounter.answer(state, userId, true)
                end
                return LanternWitchEncounter.useCopy(state, userId, false)
            end
        )
        table.insert(
            witchAnchors,
            anchor(
                "witch_take",
                Strings.get("encounter.refuse"),
                Strings.get("encounter.her_question")
            )
        )
        witchInteractions.witch_take = verb(
            LanternWitchEncounter,
            function(state: any, userId: number, _now: number): (any, any)
                return LanternWitchEncounter.answer(state, userId, false)
            end
        )

        return {
            {
                id = ManyFaceEncounter.Id,
                regionId = regionId,
                module = ManyFaceEncounter,
                anchors = faceAnchors,
                interactions = faceInteractions,
                tick = manyFaceTick,
            },
            {
                id = DrownedCallerEncounter.Id,
                regionId = regionId,
                module = DrownedCallerEncounter,
                anchors = callerAnchors,
                interactions = callerInteractions,
            },
            {
                id = LanternWitchEncounter.Id,
                regionId = regionId,
                module = LanternWitchEncounter,
                anchors = witchAnchors,
                interactions = witchInteractions,
                lockedUntil = { ManyFaceEncounter.Id, DrownedCallerEncounter.Id },
                chapterResolution = function(state: any)
                    local decision = if state.outcome == "broken"
                        then "refused_her"
                        elseif state.outcome == "sealed" then "spared_copies"
                        else "spent_copies"
                    return {
                        chapterId = "chapter_three",
                        decision = decision,
                        outcome = tostring(state.outcome),
                    }
                end,
            },
        }
    elseif regionId == "region_tempest" then
        local eaterInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(LighthouseEaterEncounter),
        }
        local eaterAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.lighthouse_eater")
            ),
        }
        local beaconObjects: { [string]: string } = {
            beacon_point = Strings.get("encounter.point_beacon"),
            beacon_jetty = Strings.get("encounter.jetty_beacon"),
            beacon_shoal = Strings.get("encounter.shoal_beacon"),
            beacon_wall = Strings.get("encounter.wall_beacon"),
        }
        for _, beaconId in LighthouseEaterEncounter.BeaconIds do
            table.insert(
                eaterAnchors,
                anchor(beaconId, Strings.get("world.light"), beaconObjects[beaconId])
            )
            eaterInteractions[beaconId] = verb(
                LighthouseEaterEncounter,
                function(state: any, userId: number, now: number): (any, any)
                    return LighthouseEaterEncounter.lightBeacon(state, userId, beaconId, now)
                end
            )
        end

        local wreckInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(AdmiralWreckEncounter),
        }
        local wreckAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.admiral_wreck")
            ),
        }
        local lineObjects: { [string]: string } = {
            tow_bow = Strings.get("encounter.bow_tow_line"),
            tow_quarter = Strings.get("encounter.quarter_tow_line"),
            tow_stern = Strings.get("encounter.stern_tow_line"),
            tow_spring = Strings.get("encounter.spring_tow_line"),
        }
        for _, lineId in AdmiralWreckEncounter.LineIds do
            table.insert(
                wreckAnchors,
                anchor(lineId, Strings.get("encounter.cut"), lineObjects[lineId])
            )
            wreckInteractions[lineId] = verb(
                AdmiralWreckEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return AdmiralWreckEncounter.cutLine(state, userId, lineId)
                end
            )
        end
        --[[
            His crew re-rigs each cut line after a fixed span. The state
            keeps no timestamps -- a cut is a boolean -- so the cadence
            lives here, the way the Many-Face's face clock does: remember
            when each cut appeared, and give it back when its time is up.
        ]]
        local rerigAt: { [string]: number } = {}
        local function wreckTick(state: any, now: number): any?
            if state.status ~= "covered" and state.status ~= "exposed" then
                if next(rerigAt) ~= nil then
                    rerigAt = {}
                end
                return nil
            end
            local nextState = state
            for _, lineId in AdmiralWreckEncounter.LineIds do
                if nextState.lines[lineId] then
                    if rerigAt[lineId] == nil then
                        rerigAt[lineId] = now + AdmiralWreckEncounter.Tuning.lineRerigSeconds
                    elseif now >= rerigAt[lineId] then
                        rerigAt[lineId] = nil
                        nextState = (AdmiralWreckEncounter.rerigLine(nextState, lineId))
                    end
                else
                    rerigAt[lineId] = nil
                end
            end
            return if nextState == state then nil else nextState
        end

        local titanInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(TideboundTitanEncounter),
        }
        local titanAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.tidebound_titan")
            ),
        }
        local wreckObjects: { [string]: string } = {
            wreck_collier = Strings.get("encounter.collier_wreck"),
            wreck_packet = Strings.get("encounter.packet_wreck"),
            wreck_trawler = Strings.get("encounter.trawler_wreck"),
            wreck_cutter = Strings.get("encounter.cutter_wreck"),
        }
        for _, wreckId in TideboundTitanEncounter.WreckIds do
            table.insert(
                titanAnchors,
                anchor(wreckId, Strings.get("encounter.climb"), wreckObjects[wreckId])
            )
            titanInteractions[wreckId] = verb(
                TideboundTitanEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return TideboundTitanEncounter.climbWreck(state, userId, wreckId)
                end
            )
        end
        local rodObjects: { [string]: string } = {
            rod_seaward = Strings.get("encounter.seaward_storm_rod"),
            rod_landward = Strings.get("encounter.landward_storm_rod"),
        }
        for _, rodId in TideboundTitanEncounter.RodIds do
            table.insert(
                titanAnchors,
                anchor(rodId, Strings.get("encounter.ground"), rodObjects[rodId])
            )
            titanInteractions[rodId] = verb(
                TideboundTitanEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return TideboundTitanEncounter.groundRod(state, userId, rodId)
                end
            )
        end
        --[[
            The chapter's decision, worked with two verbs per gate rather
            than chosen at a menu -- and easing shares no anchor with
            slamming, for the Witch's reason: a decision that shares a
            button with its opposite is a misclick with a consequence.
            The module counts slams and nothing else, so the once-a-phase
            cadence its outcome comment assumes ("three phases offer two
            gates each") is held here: a gate already worked this phase
            answers with its own refusal instead of double-counting.
        ]]
        local gateWorkedInPhase: { [string]: number } = {}
        local gateObjects: { [string]: string } = {
            gate_north = Strings.get("encounter.north_tide_gate"),
            gate_south = Strings.get("encounter.south_tide_gate"),
        }
        for gateId in TideboundTitanEncounter.GateIds :: { [string]: boolean } do
            local function workGate(state: any, player: any, now: number, slam: boolean): (any, any)
                if state.status == "exposed" and gateWorkedInPhase[gateId] == state.phase then
                    return state,
                        {
                            accepted = false,
                            completed = false,
                            message = Strings.get("encounter.this_gate_is_worked_the_tide"),
                        }
                end
                local nextState, result =
                    TideboundTitanEncounter.lowerTide(state, player.UserId, gateId, slam)
                if type(result) == "table" and result.accepted == true then
                    gateWorkedInPhase[gateId] = nextState.phase
                end
                return nextState,
                    {
                        accepted = if type(result) == "table" then result.accepted else false,
                        completed = false,
                        message = instructionOf(
                            TideboundTitanEncounter,
                            nextState,
                            player.UserId,
                            now
                        ),
                    }
            end
            table.insert(
                titanAnchors,
                anchor(gateId, Strings.get("encounter.ease"), gateObjects[gateId])
            )
            titanInteractions[gateId] = function(state: any, player: any, now: number): (any, any)
                return workGate(state, player, now, false)
            end
            local slamId = gateId .. "_slam"
            table.insert(
                titanAnchors,
                anchor(slamId, Strings.get("encounter.slam"), gateObjects[gateId])
            )
            titanInteractions[slamId] = function(state: any, player: any, now: number): (any, any)
                return workGate(state, player, now, true)
            end
        end
        table.sort(titanAnchors, function(left: Anchor, right: Anchor): boolean
            if left.id == RegionEncounterWiring.ChallengeAnchorId then
                return true
            elseif right.id == RegionEncounterWiring.ChallengeAnchorId then
                return false
            end
            return left.id < right.id
        end)

        return {
            {
                id = LighthouseEaterEncounter.Id,
                regionId = regionId,
                module = LighthouseEaterEncounter,
                anchors = eaterAnchors,
                interactions = eaterInteractions,
                tick = LighthouseEaterEncounter.expire,
            },
            {
                id = AdmiralWreckEncounter.Id,
                regionId = regionId,
                module = AdmiralWreckEncounter,
                anchors = wreckAnchors,
                interactions = wreckInteractions,
                tick = wreckTick,
            },
            {
                id = TideboundTitanEncounter.Id,
                regionId = regionId,
                module = TideboundTitanEncounter,
                anchors = titanAnchors,
                interactions = titanInteractions,
                lockedUntil = { LighthouseEaterEncounter.Id, AdmiralWreckEncounter.Id },
                chapterResolution = function(state: any)
                    --[[
                        Slams are the only thing the fight counts, so the
                        decision reads off the same thresholds the outcome
                        does: never slammed is a party that took the long
                        turn every time, four or more is a policy, and the
                        stretch between is a night that went both ways.
                    ]]
                    local slams = tonumber(state.slammedGates) or 0
                    local decision = if slams == 0
                        then "eased_gates"
                        elseif slams >= 4 then "slammed_gates"
                        else "mixed_gates"
                    return {
                        chapterId = "chapter_four",
                        decision = decision,
                        outcome = tostring(state.outcome),
                    }
                end,
            },
        }
    end
    return {}
end

-- The anchor id list an arena is built from, in the order the wiring
-- declares them. RegionBuilders.buildArena spaces them evenly, so order
-- is placement.
function RegionEncounterWiring.anchorIds(definition: Definition): { string }
    local ids: { string } = {}
    for _, entry in definition.anchors do
        table.insert(ids, entry.id)
    end
    return ids
end

return table.freeze(RegionEncounterWiring)
