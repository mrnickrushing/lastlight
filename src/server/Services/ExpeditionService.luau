--!strict

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
        _analyticsService: any,
        _seed: number,
        _manifest: any,
        _partCount: number,
        _eventStates: { [string]: any },
        _rewardLedgerState: any,
        _eventsEnabled: boolean,
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
        _analyticsService = analyticsService,
        _seed = seed,
        _manifest = nil,
        _partCount = 0,
        _eventStates = {},
        _rewardLedgerState = rewardLedger.create(),
        _eventsEnabled = false,
    }, ExpeditionService)
end

function ExpeditionService.Init(self: ExpeditionService, _context: any)
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
            local state = self._eventFlow.create(definition, manifest.hash, self._eventsEnabled)
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
    local granted = self._rewardLedger.grant(self._rewardLedgerState, userId, transactionId, reward)
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

function ExpeditionService.snapshot(self: ExpeditionService, player: Player): any
    self:_refreshExpired(os.clock())
    local snapshot = self._worldService:expeditionSnapshot(player)
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
    snapshot.unbankedRewards =
        self._rewardLedger.snapshot(self._rewardLedgerState, player.UserId).materials
    return snapshot
end

function ExpeditionService.manifest(self: ExpeditionService): any
    return self._manifest
end

return table.freeze(ExpeditionService)
