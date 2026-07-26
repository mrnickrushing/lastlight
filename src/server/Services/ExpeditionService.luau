--!strict

local Players = game:GetService("Players")

local ExpeditionService = {}
ExpeditionService.__index = ExpeditionService
ExpeditionService.Name = "ExpeditionService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type ExpeditionService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _worldService: any,
        _generator: any,
        _catalog: any,
        _featureFlags: any,
        _eventFlow: any,
        _rewardLedger: any,
        _profileService: any,
        _analyticsService: any,
        _seed: number,
        _manifest: any,
        _partCount: number,
        _eventStates: { [string]: any },
        _rewardLedgerState: any,
        _eventsEnabled: boolean,
        _runId: string,
    },
    ExpeditionService
))

function ExpeditionService.new(
    logger: Logger,
    worldService: any,
    generator: any,
    catalog: any,
    featureFlags: any,
    eventFlow: any,
    rewardLedger: any,
    profileService: any,
    analyticsService: any,
    seed: number
): ExpeditionService
    return setmetatable({
        Name = ExpeditionService.Name,
        _logger = logger,
        _worldService = worldService,
        _generator = generator,
        _catalog = catalog,
        _featureFlags = featureFlags,
        _eventFlow = eventFlow,
        _rewardLedger = rewardLedger,
        _profileService = profileService,
        _analyticsService = analyticsService,
        _seed = seed,
        _manifest = nil,
        _partCount = 0,
        _eventStates = {},
        _rewardLedgerState = rewardLedger.create(),
        _eventsEnabled = false,
        _runId = "",
    }, ExpeditionService)
end

function ExpeditionService.Init(self: ExpeditionService, _context: any)
    local jobId = game.JobId
    self._runId = if jobId ~= ""
        then jobId
        else string.format("studio_%d_%d", os.time(), math.floor(os.clock() * 1000))
    local requestedSeed = game:GetAttribute("LastLightExpeditionSeed")
    local seed = if type(requestedSeed) == "number" then requestedSeed else self._seed
    local manifest = self._generator.generate(seed)
    local valid, issues = self._generator.validate(manifest)
    assert(valid, "Bramblewake expedition manifest is invalid: " .. table.concat(issues, "; "))

    local result = self._worldService:buildBramblewake(manifest, self._generator, self._catalog)
    self._manifest = manifest
    self._partCount = result.partCount
    self._eventsEnabled = self._featureFlags:isEnabled("bramblewake_events_enabled")
    self._worldService:setExpeditionEventsEnabled(self._eventsEnabled)
    for _, placement in manifest.modules do
        if placement.eventId ~= nil then
            local definition = self._generator.eventDefinition(placement.eventId)
            local state =
                self._eventFlow.create(definition, self._runId, manifest.hash, self._eventsEnabled)
            self._eventStates[placement.eventId] = state
            self._worldService:setExpeditionEventState(placement.eventId, state)
        end
    end
end

function ExpeditionService.Start(self: ExpeditionService)
    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    self._logger:info("expedition_ready", {
        events = self._catalog.EventCount,
        eventInteractions = self._catalog.EventInteractionCount,
        eventsEnabled = self._eventsEnabled,
        hash = manifest.hash,
        modules = #manifest.modules,
        parts = self._partCount,
        pois = self._catalog.PointOfInterestCount,
        runId = self._runId,
        seed = manifest.seed,
        source = manifest.source,
    })
end

function ExpeditionService.enter(self: ExpeditionService, player: Player): boolean
    return self._worldService:enterBramblewake(player)
end

function ExpeditionService._participantCount(_self: ExpeditionService, state: any): number
    local count = 0
    for _ in state.participants do
        count += 1
    end
    return count
end

function ExpeditionService._refreshExpired(self: ExpeditionService, now: number)
    for eventId, state in self._eventStates do
        local definition = self._generator.eventDefinition(eventId)
        if self._eventFlow.expire(state, definition, now) then
            self._worldService:setExpeditionEventState(eventId, state)
            self._analyticsService:expeditionEventFailed(
                eventId,
                state.manifestHash,
                self:_participantCount(state)
            )
        end
    end
end

function ExpeditionService._grantReward(
    self: ExpeditionService,
    userId: number,
    state: any,
    definition: any
): boolean
    local transactionId = state.rewardTransactionId
    if type(transactionId) ~= "string" then
        return false
    end

    local reward = definition.reward
    local granted = self._rewardLedger.grant(
        self._rewardLedgerState,
        userId,
        transactionId,
        state.manifestHash,
        reward
    )
    if not granted then
        return false
    end
    self._logger:info("expedition_event_reward_granted", {
        amount = reward.amount,
        event = definition.id,
        material = reward.materialId,
        transaction = transactionId,
        userId = userId,
    })
    local player = Players:GetPlayerByUserId(userId)
    if player ~= nil then
        local profileResult = self._profileService:grantUnbankedExpeditionReward(
            player,
            transactionId,
            state.manifestHash,
            reward
        )
        self._logger:info("expedition_event_reward_persisted", {
            durable = profileResult.durable == true,
            event = definition.id,
            player = userId,
            transaction = transactionId,
        })
    end
    return true
end

function ExpeditionService.grantEncounterReward(
    self: ExpeditionService,
    userId: number,
    encounterId: string,
    transactionId: string,
    reward: any
): boolean
    if string.sub(encounterId, 1, 6) ~= "elite_" then
        self._logger:warn("expedition_encounter_reward_rejected", {
            encounter = encounterId,
            reason = "invalid_encounter_id",
            userId = userId,
        })
        return false
    end
    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    local granted = self._rewardLedger.grant(
        self._rewardLedgerState,
        userId,
        transactionId,
        manifest.hash,
        reward
    )
    if not granted then
        return false
    end
    self._logger:info("expedition_encounter_reward_granted", {
        amount = reward.amount,
        encounter = encounterId,
        material = reward.materialId,
        transaction = transactionId,
        userId = userId,
    })
    local player = Players:GetPlayerByUserId(userId)
    if player ~= nil then
        local profileResult = self._profileService:grantUnbankedExpeditionReward(
            player,
            transactionId,
            manifest.hash,
            reward
        )
        self._logger:info("expedition_encounter_reward_persisted", {
            durable = profileResult.durable == true,
            encounter = encounterId,
            player = userId,
            transaction = transactionId,
        })
    end
    return true
end

function ExpeditionService.interact(
    self: ExpeditionService,
    player: Player,
    prompt: ProximityPrompt
): any
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return {
            accepted = false,
            message = "ENTER BRAMBLEWAKE TO ANSWER THIS EVENT",
            reason = "player_not_in_expedition",
        }
    end

    local eventId = prompt:GetAttribute("EventId")
    local stepId = prompt:GetAttribute("EventStepId")
    if type(eventId) ~= "string" or type(stepId) ~= "string" then
        return {
            accepted = false,
            message = "THAT EVENT MARK IS INVALID",
            reason = "invalid_prompt_contract",
        }
    end
    local state = self._eventStates[eventId]
    local definition = self._generator.eventDefinition(eventId)
    if state == nil or definition == nil then
        return {
            accepted = false,
            message = "THAT EVENT IS NO LONGER AVAILABLE",
            reason = "unknown_event",
        }
    end

    local result =
        self._eventFlow.contribute(state, definition, stepId, tostring(player.UserId), os.clock())
    if result.changed then
        self._worldService:setExpeditionEventState(eventId, state)
    end
    if result.started then
        self._analyticsService:expeditionEventStarted(player, definition, state.manifestHash)
    end
    if result.completed then
        for participantId in state.participants do
            local userId = tonumber(participantId)
            if userId ~= nil then
                self:_grantReward(userId, state, definition)
            end
        end
        self._analyticsService:expeditionEventCompleted(
            player,
            definition,
            state.manifestHash,
            state.rewardTransactionId,
            self:_participantCount(state)
        )
    end

    if result.completed then
        result.message = definition.completionMessage
    elseif result.duplicate then
        result.message = "THAT EVENT MARK IS ALREADY SET"
    elseif result.failed or result.reason == "event_failed" or result.reason == "event_expired" then
        result.message = definition.failureMessage
    elseif result.accepted then
        result.message = string.format(
            "%s — %d/%d",
            string.upper(definition.displayName),
            state.progress,
            state.total
        )
    elseif result.reason == "event_disabled" then
        result.message = "THIS EVENT IS TEMPORARILY DORMANT"
    else
        result.message = "THAT EVENT ACTION WAS REJECTED"
    end

    if not result.accepted then
        self._logger:warn("expedition_event_interaction_rejected", {
            event = eventId,
            player = player.UserId,
            reason = result.reason,
            step = stepId,
        })
    end
    return result
end

function ExpeditionService._combinedPending(self: ExpeditionService, player: Player): any
    local sessionPending = self._rewardLedger.pending(self._rewardLedgerState, player.UserId)
    local profileInventory = self._profileService:inventorySnapshot(player)
    local materials: { [string]: number } = {}
    local rewards = {}
    local seen: { [string]: boolean } = {}
    for _, reward in profileInventory.pendingRewards do
        seen[reward.transactionId] = true
        materials[reward.materialId] = (materials[reward.materialId] or 0) + reward.amount
        table.insert(rewards, reward)
    end
    for _, reward in sessionPending.rewards do
        if not seen[reward.transactionId] then
            seen[reward.transactionId] = true
            materials[reward.materialId] = (materials[reward.materialId] or 0) + reward.amount
            table.insert(rewards, reward)
        end
    end
    table.sort(rewards, function(left: any, right: any): boolean
        return left.transactionId < right.transactionId
    end)
    return {
        banked = profileInventory.banked,
        materials = materials,
        rewards = rewards,
    }
end

function ExpeditionService.extract(self: ExpeditionService, player: Player): any
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return {
            accepted = false,
            message = "YOU ARE NOT INSIDE BRAMBLEWAKE",
            reason = "player_not_in_expedition",
        }
    end

    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    local sessionPending = self._rewardLedger.pending(self._rewardLedgerState, player.UserId)
    local combinedPending = self:_combinedPending(player)
    if #combinedPending.rewards == 0 then
        if not self._worldService:exitBramblewake(player) then
            return {
                accepted = false,
                message = "WAYHOME TRANSITION WILL RETRY",
                reason = "transition_unavailable",
            }
        end
        self._analyticsService:expeditionExtracted(player, manifest.hash, nil, 0)
        return {
            accepted = true,
            banked = combinedPending.banked,
            message = "RETURNING TO EMBERHOLLOW — POUCH EMPTY",
            settlementId = nil,
        }
    end

    local settlement = self._profileService:settleExpedition(
        player,
        self._runId,
        manifest.hash,
        sessionPending.rewards
    )
    if not settlement.accepted then
        self._analyticsService:expeditionExtractionFailed(player, manifest.hash, settlement.reason)
        return {
            accepted = false,
            message = if settlement.reason == "profile_read_only"
                then "PROFILE OFFLINE — REWARDS REMAIN UNBANKED"
                elseif
                    settlement.reason == "save_pending"
                then "BANKING RETRY NEEDED — REWARDS REMAIN UNBANKED"
                else "WAYHOME GATE IS WAITING FOR YOUR PROFILE",
            reason = settlement.reason,
        }
    end

    if settlement.settlementId ~= nil then
        self._rewardLedger.settle(
            self._rewardLedgerState,
            player.UserId,
            settlement.settlementId,
            sessionPending.transactionIds
        )
    end
    if not self._worldService:exitBramblewake(player) then
        return {
            accepted = false,
            message = "REWARDS BANKED — WAYHOME TRANSITION WILL RETRY",
            reason = "transition_unavailable",
        }
    end

    local bankedAmount = 0
    for _, amount in settlement.materials or {} do
        bankedAmount += amount
    end
    self._analyticsService:expeditionExtracted(
        player,
        manifest.hash,
        settlement.settlementId,
        bankedAmount
    )
    return {
        accepted = true,
        banked = settlement.inventory,
        message = if settlement.empty
            then "RETURNING TO EMBERHOLLOW — POUCH EMPTY"
            else string.format("WAYHOME — %d MATERIALS BANKED", bankedAmount),
        settlementId = settlement.settlementId,
    }
end

function ExpeditionService.snapshot(self: ExpeditionService, player: Player): any
    self:_refreshExpired(os.clock())
    local snapshot = self._worldService:expeditionSnapshot(player)
    local inventory = self:_combinedPending(player)
    snapshot.unbankedRewards = inventory.materials
    snapshot.bankedMaterials = inventory.banked
    if not snapshot.active then
        return snapshot
    end

    local moduleDefinition = self._generator.moduleDefinition(snapshot.moduleId)
    local poiDefinition = if snapshot.poiId == nil
        then nil
        else self._generator.pointOfInterestDefinition(snapshot.poiId)
    local eventDefinition = if snapshot.eventId == nil
        then nil
        else self._generator.eventDefinition(snapshot.eventId)
    snapshot.moduleName = moduleDefinition.displayName
    snapshot.pointOfInterestName = if poiDefinition == nil then nil else poiDefinition.displayName
    snapshot.eventName = if eventDefinition == nil then nil else eventDefinition.displayName
    if eventDefinition ~= nil then
        local state = self._eventStates[snapshot.eventId]
        if state ~= nil then
            snapshot.event = self._eventFlow.snapshot(state, eventDefinition, os.clock())
            snapshot.eventRevision = state.revision
        end
    end
    return snapshot
end

function ExpeditionService.manifest(self: ExpeditionService): any
    return self._manifest
end

function ExpeditionService.runId(self: ExpeditionService): string
    return self._runId
end

return table.freeze(ExpeditionService)
