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

local AbbeySilenceEncounter = require("./AbbeySilenceEncounter")
local AdmiralWreckEncounter = require("./AdmiralWreckEncounter")
local AshRegentEncounter = require("./AshRegentEncounter")
local AuroraHartEncounter = require("./AuroraHartEncounter")
local BellowsMawEncounter = require("./BellowsMawEncounter")
local DrownedCallerEncounter = require("./DrownedCallerEncounter")
local ForemanEchoEncounter = require("./ForemanEchoEncounter")
local GlassBailiffEncounter = require("./GlassBailiffEncounter")
local IronWidowEncounter = require("./IronWidowEncounter")
local LanternWitchEncounter = require("./LanternWitchEncounter")
local LeadActorEncounter = require("./LeadActorEncounter")
local LighthouseEaterEncounter = require("./LighthouseEaterEncounter")
local ManyFaceEncounter = require("./ManyFaceEncounter")
local Strings = require("./Strings")
local TideboundTitanEncounter = require("./TideboundTitanEncounter")
local WhiteHowlerEncounter = require("./WhiteHowlerEncounter")

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
    elseif regionId == "region_frostmere" then
        local silenceInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(AbbeySilenceEncounter),
        }
        local silenceAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.abbey_silence")
            ),
        }
        local bellObjects: { [string]: string } = {
            bell_cloister = Strings.get("encounter.cloister_bell"),
            bell_refectory = Strings.get("encounter.refectory_bell"),
            bell_stair = Strings.get("encounter.stair_bell"),
        }
        for _, bellId in AbbeySilenceEncounter.BellIds do
            table.insert(
                silenceAnchors,
                anchor(bellId, Strings.get("encounter.toll"), bellObjects[bellId])
            )
            silenceInteractions[bellId] = verb(
                AbbeySilenceEncounter,
                function(state: any, userId: number, now: number): (any, any)
                    return AbbeySilenceEncounter.ringBell(state, userId, bellId, now)
                end
            )
        end

        local hartInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(AuroraHartEncounter),
        }
        local hartAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.aurora_hart")
            ),
        }
        local hearthObjects: { [string]: string } = {
            hearth_north = Strings.get("encounter.north_embers"),
            hearth_east = Strings.get("encounter.east_embers"),
            hearth_south = Strings.get("encounter.south_embers"),
            hearth_west = Strings.get("encounter.west_embers"),
        }
        --[[
            The module's verb names both ends of the carry and an anchor
            names one, so the wiring finds the other -- and the anchor has
            to be the end warmth *leaves*, with the hottest hearth always
            the end it arrives at. Anchored the other way round, touching
            a cold hearth pulls an ember back out of the banked one, so
            the press that reads most like pursuing the fight's goal is
            the press that undoes it. This way every accepted carry
            gathers, and touching the hearth that already holds the fire
            is refused by the module as the same hearth, which is the
            true answer rather than a wiring branch.
        ]]
        for _, hearthId in AuroraHartEncounter.HearthIds do
            table.insert(
                hartAnchors,
                anchor(hearthId, Strings.get("world.gather"), hearthObjects[hearthId])
            )
            hartInteractions[hearthId] = verb(
                AuroraHartEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    local hottest = AuroraHartEncounter.HearthIds[1]
                    for _, candidate in AuroraHartEncounter.HearthIds do
                        if (state.hearths[candidate] or 0) > (state.hearths[hottest] or 0) then
                            hottest = candidate
                        end
                    end
                    return AuroraHartEncounter.carryEmber(state, userId, hearthId, hottest)
                end
            )
        end
        --[[
            The Hart divides the clearing on its own clock and the state
            counts splits without timing them, so the cadence lives here
            the way the Admiral's re-rig does. Its first sight of a live
            fight only starts the clock; nothing splits on the tick that
            opened the fight.
        ]]
        local nextSplitAt: number? = nil
        local function hartTick(state: any, now: number): any?
            if state.status ~= "split" and state.status ~= "banked" then
                nextSplitAt = nil
                return nil
            end
            if nextSplitAt == nil or now < nextSplitAt then
                if nextSplitAt == nil then
                    nextSplitAt = now + AuroraHartEncounter.Tuning.splitIntervalSeconds
                end
                return nil
            end
            nextSplitAt = now + AuroraHartEncounter.Tuning.splitIntervalSeconds
            local nextState = AuroraHartEncounter.split(state)
            return if nextState == state then nil else nextState
        end

        local howlerInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(WhiteHowlerEncounter),
        }
        local howlerAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.white_howler")
            ),
        }
        local noiseObjects: { [string]: string } = {
            noise_bell_rope = Strings.get("encounter.bell_rope"),
            noise_kettle_line = Strings.get("encounter.kettle_line"),
            noise_wind_vane = Strings.get("encounter.wind_vane"),
            noise_kennel_gate = Strings.get("encounter.kennel_gate"),
        }
        for _, noiseId in WhiteHowlerEncounter.NoiseIds do
            table.insert(
                howlerAnchors,
                anchor(noiseId, Strings.get("encounter.hush"), noiseObjects[noiseId])
            )
            howlerInteractions[noiseId] = verb(
                WhiteHowlerEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return WhiteHowlerEncounter.hush(state, userId, noiseId)
                end
            )
        end
        --[[
            The chapter's decision, and like the Titan's gates it is two
            anchors rather than a menu on one. The Reach left both of its
            anchors carrying the same name, which the walk recorded as an
            authoring question; here each destination is written into the
            name, because where the warmth went is the whole decision and
            a player should be able to read it off the post they are
            standing at.
        ]]
        local warmthFireObjects: { [string]: string } = {
            warmth_lantern = Strings.get("encounter.lantern_to_our_fire"),
            warmth_kettle = Strings.get("encounter.kettle_to_our_fire"),
            warmth_coat = Strings.get("encounter.coat_to_our_fire"),
        }
        local warmthDenObjects: { [string]: string } = {
            warmth_lantern = Strings.get("encounter.lantern_to_the_den"),
            warmth_kettle = Strings.get("encounter.kettle_to_the_den"),
            warmth_coat = Strings.get("encounter.coat_to_the_den"),
        }
        for _, warmthId in WhiteHowlerEncounter.WarmthIds do
            table.insert(
                howlerAnchors,
                anchor(warmthId, Strings.get("encounter.share"), warmthFireObjects[warmthId])
            )
            howlerInteractions[warmthId] = verb(
                WhiteHowlerEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return WhiteHowlerEncounter.shareWarmth(state, userId, warmthId, false)
                end
            )
            local denId = warmthId .. "_den"
            table.insert(
                howlerAnchors,
                anchor(denId, Strings.get("encounter.carry_up"), warmthDenObjects[warmthId])
            )
            howlerInteractions[denId] = verb(
                WhiteHowlerEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return WhiteHowlerEncounter.shareWarmth(state, userId, warmthId, true)
                end
            )
        end
        --[[
            The aurora's own order, written on the marks.

            The module reads them in a fixed order and a wrong one loses
            the trail, which sends the phase back to the noise -- and the
            instruction never names which mark is next, so the first read
            of a walk is a one-in-four guess that throws away every hush
            and every warmth already spent. That is not the fight the
            module describes: "only the light over the ridge shows where"
            means the aurora *tells* you, so it tells you here. What the
            phase still costs is getting quiet, spending the warmth, and
            reading four marks under a whiteout while the clock runs.
        ]]
        local trackObjects: { [string]: string } = {
            track_ridge = Strings.get("encounter.first_mark_ridge"),
            track_bowl = Strings.get("encounter.second_mark_bowl"),
            track_stair = Strings.get("encounter.third_mark_stair"),
            track_cairn = Strings.get("encounter.fourth_mark_cairn"),
        }
        for _, trackId in WhiteHowlerEncounter.TrackIds do
            table.insert(
                howlerAnchors,
                anchor(trackId, Strings.get("encounter.trace"), trackObjects[trackId])
            )
            howlerInteractions[trackId] = function(state: any, player: any, now: number): (any, any)
                local nextState, result =
                    WhiteHowlerEncounter.followTrack(state, player.UserId, trackId)
                --[[
                    A lost trail is the one branch in this region where
                    the next instruction is a lie by omission: it reads
                    "QUIET THE BOWL -- 0 OF 3" and a party that just did
                    all of that is told nothing happened. The loss gets
                    its own line, the way the Titan's already-worked gate
                    does.
                ]]
                if type(result) == "table" and result.lost == true then
                    return nextState,
                        {
                            accepted = false,
                            completed = false,
                            message = Strings.get("encounter.the_trail_is_lost_the_bowl"),
                        }
                end
                return nextState,
                    {
                        accepted = if type(result) == "table" then result.accepted else false,
                        completed = false,
                        message = instructionOf(
                            WhiteHowlerEncounter,
                            nextState,
                            player.UserId,
                            now
                        ),
                    }
            end
        end

        return {
            {
                id = AbbeySilenceEncounter.Id,
                regionId = regionId,
                module = AbbeySilenceEncounter,
                anchors = silenceAnchors,
                interactions = silenceInteractions,
                tick = AbbeySilenceEncounter.expire,
            },
            {
                id = AuroraHartEncounter.Id,
                regionId = regionId,
                module = AuroraHartEncounter,
                anchors = hartAnchors,
                interactions = hartInteractions,
                tick = hartTick,
            },
            {
                id = WhiteHowlerEncounter.Id,
                regionId = regionId,
                module = WhiteHowlerEncounter,
                anchors = howlerAnchors,
                interactions = howlerInteractions,
                lockedUntil = { AbbeySilenceEncounter.Id, AuroraHartEncounter.Id },
                chapterResolution = function(state: any)
                    --[[
                        Warmth carried to the den is the only thing the
                        fight records about the decision, so the decision
                        reads off the same count the outcome does: every
                        phase paid is a party that chose the pups over
                        itself, none is a party that kept its fire, and
                        the middle is the night that went both ways.
                    ]]
                    local dens = 0
                    for _, warmed in state.denPhases do
                        if warmed then
                            dens += 1
                        end
                    end
                    local decision = if dens >= #state.denPhases
                        then "warmed_den"
                        elseif dens == 0 then "kept_warmth"
                        else "split_warmth"
                    return {
                        chapterId = "chapter_five",
                        decision = decision,
                        outcome = tostring(state.outcome),
                    }
                end,
            },
        }
    elseif regionId == "region_cinderfall" then
        local beatObjects: { [string]: string } = {
            beat_bow = Strings.get("encounter.the_bow"),
            beat_turn = Strings.get("encounter.the_turn"),
            beat_kneel = Strings.get("encounter.the_kneel"),
            beat_raise = Strings.get("encounter.the_raise"),
        }
        --[[
            The Actor's own description is that it announces its line
            "loudly, in order" and that the fight is "not a memory test
            with the answer hidden". Its instruction only counts the
            beats ("ANSWER THE LINE -- 1 OF 3"), and the beat it is
            actually calling rides in `calledBeat`, which no client
            reads. Announced nowhere, a party is guessing one in four
            with a wrong guess costing the whole line -- the White
            Howler's aurora order again, one region later. So the call is
            spoken here, appended to the encounter's own line rather than
            replacing it, and every Actor handler goes through this
            instead of the shared `verb`.
        ]]
        local function actorMessage(state: any, userId: number): string
            local snapshot = LeadActorEncounter.snapshot(state, userId)
            local instruction = tostring(snapshot.instruction)
            local called = snapshot.calledBeat
            if called == nil then
                return instruction
            end
            return string.format(
                Strings.get("encounter.line_call"),
                instruction,
                beatObjects[called]
            )
        end

        local actorInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = function(
                state: any,
                player: any,
                _now: number
            ): (any, any)
                local nextState, result = LeadActorEncounter.activate(state, player.UserId)
                return nextState,
                    {
                        accepted = if type(result) == "table" then result.accepted else false,
                        completed = false,
                        message = actorMessage(nextState, player.UserId),
                    }
            end,
        }
        local actorAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.lead_actor")
            ),
        }
        for _, beatId in LeadActorEncounter.BeatIds do
            table.insert(
                actorAnchors,
                anchor(beatId, Strings.get("expedition.answer"), beatObjects[beatId])
            )
            actorInteractions[beatId] = function(state: any, player: any, _now: number): (any, any)
                local nextState, result =
                    LeadActorEncounter.answerBeat(state, player.UserId, beatId)
                --[[
                    A missed beat sends the line back to its first beat
                    and nothing else changes, so the instruction returns
                    to "ANSWER THE LINE -- 0 OF n" and a party reads it
                    as the press having done nothing. The loss gets its
                    own line, the way the Titan's already-worked gate and
                    the Howler's lost trail do -- and it still carries the
                    next call, because the scene does not stop to explain
                    itself.
                ]]
                if type(result) == "table" and result.missed == true then
                    return nextState,
                        {
                            accepted = false,
                            completed = false,
                            message = string.format(
                                Strings.get("encounter.line_call"),
                                Strings.get("encounter.the_line_starts_again_from_the"),
                                beatObjects[LeadActorEncounter.expectedBeat(nextState)]
                            ),
                        }
                end
                return nextState,
                    {
                        accepted = if type(result) == "table" then result.accepted else false,
                        completed = false,
                        message = actorMessage(nextState, player.UserId),
                    }
            end
        end
        --[[
            The broken scene closes on its own. `resume` is the Actor's
            own verb and the state carries no timestamp, so the clock
            lives here the way the Admiral's re-rig and the Hart's split
            do. The first tick that sees a broken scene only starts the
            count; nothing resumes on the tick that broke it.
        ]]
        local resumeAt: number? = nil
        local function actorTick(state: any, now: number): any?
            if state.status ~= "broken" then
                resumeAt = nil
                return nil
            end
            if resumeAt == nil then
                resumeAt = now + LeadActorEncounter.Tuning.brokenSeconds
                return nil
            end
            if now < resumeAt then
                return nil
            end
            resumeAt = nil
            local nextState = LeadActorEncounter.resume(state)
            return if nextState == state then nil else nextState
        end

        local structureObjects: { [string]: string } = {
            structure_west_arcade = Strings.get("encounter.the_west_arcade"),
            structure_stand = Strings.get("encounter.the_stand"),
            structure_press = Strings.get("encounter.the_press"),
            structure_dock = Strings.get("encounter.the_dock"),
        }
        --[[
            Which structure is marked is the only fact this fight turns
            on, and like the Actor's called beat it rides in the snapshot
            (`marked`) and reaches no client. An arena of four identical
            prompts with "IT HAS MARKED SOMETHING -- APPEAL IT" over them
            is four guesses at a seven-second clock, so the mark is named
            here beside the instruction. It answers the wrong-structure
            press too: the module's refusal is `not_marked`, whose honest
            reading is "not that one, that one" rather than "nothing".
        ]]
        local function bailiffMessage(state: any, userId: number): string
            local snapshot = GlassBailiffEncounter.snapshot(state, userId)
            local instruction = tostring(snapshot.instruction)
            if snapshot.marked == nil then
                return instruction
            end
            return string.format(
                Strings.get("encounter.marked_call"),
                instruction,
                structureObjects[snapshot.marked]
            )
        end

        local bailiffInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = function(
                state: any,
                player: any,
                _now: number
            ): (any, any)
                local nextState, result = GlassBailiffEncounter.activate(state, player.UserId)
                return nextState,
                    {
                        accepted = if type(result) == "table" then result.accepted else false,
                        completed = false,
                        message = bailiffMessage(nextState, player.UserId),
                    }
            end,
        }
        local bailiffAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.glass_bailiff")
            ),
        }
        for _, structureId in GlassBailiffEncounter.StructureIds do
            table.insert(
                bailiffAnchors,
                anchor(structureId, Strings.get("encounter.appeal"), structureObjects[structureId])
            )
            bailiffInteractions[structureId] = function(
                state: any,
                player: any,
                _now: number
            ): (any, any)
                local nextState, result =
                    GlassBailiffEncounter.appeal(state, player.UserId, structureId)
                return nextState,
                    {
                        accepted = if type(result) == "table" then result.accepted else false,
                        completed = false,
                        message = bailiffMessage(nextState, player.UserId),
                    }
            end
        end
        --[[
            The Bailiff's whole cycle is on the service's clock: it marks,
            it carries the sentence out, and it sits back down. The module
            exports all three verbs and stores no timestamps, so the
            cadence lives here.

            Two tuning values cover three waits, and the one they do not
            name is how long the window stays open. It gets
            `sentenceSeconds` as well, deliberately: the opening a party
            buys is exactly as long as the sentence it paid a wall for,
            which is the trade the fight is about stated in its own
            currency rather than a third number invented at the seam.
        ]]
        local markAt: number? = nil
        local sentenceAt: number? = nil
        local adjournAt: number? = nil
        local function bailiffTick(state: any, now: number): any?
            if state.status == "sitting" then
                adjournAt = nil
                if state.marked == nil then
                    sentenceAt = nil
                    if markAt == nil then
                        markAt = now + GlassBailiffEncounter.Tuning.markIntervalSeconds
                        return nil
                    end
                    if now < markAt then
                        return nil
                    end
                    markAt = nil
                    local nextState = GlassBailiffEncounter.mark(state)
                    return if nextState == state then nil else nextState
                end
                markAt = nil
                if sentenceAt == nil then
                    sentenceAt = now + GlassBailiffEncounter.Tuning.sentenceSeconds
                    return nil
                end
                if now < sentenceAt then
                    return nil
                end
                sentenceAt = nil
                local nextState = (GlassBailiffEncounter.carryOut(state))
                return if nextState == state then nil else nextState
            elseif state.status == "sentencing" then
                markAt, sentenceAt = nil, nil
                if adjournAt == nil then
                    adjournAt = now + GlassBailiffEncounter.Tuning.sentenceSeconds
                    return nil
                end
                if now < adjournAt then
                    return nil
                end
                adjournAt = nil
                local nextState = GlassBailiffEncounter.adjourn(state)
                return if nextState == state then nil else nextState
            end
            markAt, sentenceAt, adjournAt = nil, nil, nil
            return nil
        end

        local statueObjects: { [string]: string } = {
            statue_first = Strings.get("encounter.the_first_statue"),
            statue_second = Strings.get("encounter.the_second_statue"),
            statue_third = Strings.get("encounter.the_third_statue"),
            statue_fourth = Strings.get("encounter.the_fourth_statue"),
            statue_fifth = Strings.get("encounter.the_fifth_statue"),
        }
        local regentInteractions: { [string]: any } = {
            [RegionEncounterWiring.ChallengeAnchorId] = challenge(AshRegentEncounter),
        }
        local regentAnchors = {
            anchor(
                RegionEncounterWiring.ChallengeAnchorId,
                Strings.get("encounter.face"),
                Strings.get("encounter.ash_regent")
            ),
        }
        for _, statueId in AshRegentEncounter.StatueIds do
            --[[
                Reading a statue and breaking it are separate anchors, for
                the Witch's and the Titan's reason: reading is free and
                repeatable, breaking cannot be undone, and breaking a true
                one is the chapter's decision. A decision that shares a
                button with the free look at it is a misclick somebody
                has to live with for an epilogue.
            ]]
            table.insert(
                regentAnchors,
                anchor(statueId, Strings.get("expedition.read"), statueObjects[statueId])
            )
            --[[
                What a read taught you is the entire point of reading, and
                the Regent's instruction only ever counts anchors -- so an
                inspection that answered with the instruction would look
                exactly like an inspection that did nothing. `authentic`
                is spoken here; it is the one thing in this fight that
                costs nothing but time, and the Crown's threat is time.
            ]]
            regentInteractions[statueId] = function(
                state: any,
                player: any,
                now: number
            ): (any, any)
                local nextState, result = AshRegentEncounter.inspect(state, player.UserId, statueId)
                if type(result) == "table" and result.accepted == true then
                    --[[
                        Both keys are written out rather than chosen into
                        a variable, because `validate_localization.py`
                        follows `Strings.get` by its literal argument and
                        a key it cannot see is a key it reports as read by
                        nothing -- which is how a translator ends up
                        paying for a line no player was ever shown.
                    ]]
                    local message = if result.authentic == true
                        then string.format(
                            Strings.get("encounter.statue_reads_real"),
                            statueObjects[statueId]
                        )
                        else string.format(
                            Strings.get("encounter.statue_reads_cast"),
                            statueObjects[statueId]
                        )
                    return nextState, { accepted = true, completed = false, message = message }
                end
                return nextState,
                    {
                        accepted = false,
                        completed = false,
                        message = instructionOf(AshRegentEncounter, nextState, player.UserId, now),
                    }
            end
            local breakId = statueId .. "_break"
            table.insert(
                regentAnchors,
                anchor(breakId, Strings.get("town.break"), statueObjects[statueId])
            )
            regentInteractions[breakId] = verb(
                AshRegentEncounter,
                function(state: any, userId: number, _now: number): (any, any)
                    return AshRegentEncounter.breakStatue(state, userId, statueId)
                end
            )
        end

        return {
            {
                id = LeadActorEncounter.Id,
                regionId = regionId,
                module = LeadActorEncounter,
                anchors = actorAnchors,
                interactions = actorInteractions,
                tick = actorTick,
            },
            {
                id = GlassBailiffEncounter.Id,
                regionId = regionId,
                module = GlassBailiffEncounter,
                anchors = bailiffAnchors,
                interactions = bailiffInteractions,
                tick = bailiffTick,
            },
            {
                id = AshRegentEncounter.Id,
                regionId = regionId,
                module = AshRegentEncounter,
                anchors = regentAnchors,
                interactions = regentInteractions,
                lockedUntil = { LeadActorEncounter.Id, GlassBailiffEncounter.Id },
                chapterResolution = function(state: any)
                    --[[
                        The fight counts the authentic statues a party
                        chose to break and nothing else, so the decision
                        reads off the same count the outcome does. The
                        catalog already names all three, because the
                        chapter was written before the fight was wired.
                    ]]
                    local erased = tonumber(state.erased) or 0
                    local decision = if erased == 0
                        then "spared_memories"
                        elseif erased >= 3 then "broke_them_all"
                        else "broke_some"
                    return {
                        chapterId = "chapter_six",
                        decision = decision,
                        outcome = tostring(AshRegentEncounter.outcome(state)),
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
