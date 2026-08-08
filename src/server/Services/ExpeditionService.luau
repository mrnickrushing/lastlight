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
        _regionAccess: any,
        _catalog: any,
        _featureFlags: any,
        _eventFlow: any,
        _rewardLedger: any,
        _extractionPayoff: any,
        _profileService: any,
        _analyticsService: any,
        _seed: number,
        _regionId: string,
        _rebuilding: boolean,
        _manifest: any,
        _partCount: number,
        _eventStates: { [string]: any },
        _rewardLedgerState: any,
        _eventsEnabled: boolean,
        _runId: string,
        _pendingExtractionPayoffs: { [Player]: any },
    },
    ExpeditionService
))

function ExpeditionService.new(
    logger: Logger,
    worldService: any,
    generator: any,
    regionAccess: any,
    catalog: any,
    featureFlags: any,
    eventFlow: any,
    rewardLedger: any,
    extractionPayoff: any,
    profileService: any,
    analyticsService: any,
    seed: number,
    contracts: any
): ExpeditionService
    return setmetatable({
        Name = ExpeditionService.Name,
        _logger = logger,
        _contracts = contracts,
        _enemyService = nil,
        _contract = contracts.default(),
        _worldService = worldService,
        _generator = generator,
        _regionAccess = regionAccess,
        _catalog = catalog,
        _featureFlags = featureFlags,
        _eventFlow = eventFlow,
        _rewardLedger = rewardLedger,
        _extractionPayoff = extractionPayoff,
        _profileService = profileService,
        _analyticsService = analyticsService,
        _seed = seed,
        _regionId = "region_bramblewake",
        _rebuilding = false,
        _manifest = nil,
        _partCount = 0,
        _eventStates = {},
        _rewardLedgerState = rewardLedger.create(),
        _eventsEnabled = false,
        _runId = "",
        _pendingExtractionPayoffs = {},
    }, ExpeditionService)
end

function ExpeditionService.Init(self: ExpeditionService, _context: any)
    local jobId = game.JobId
    self._runId = if jobId ~= ""
        then jobId
        else string.format("studio_%d_%d", os.time(), math.floor(os.clock() * 1000))
    self._contract = self._contracts.default()
    local requestedSeed = game:GetAttribute("LastLightExpeditionSeed")
    -- Seed history, the boot half: with a thirty-module pool the same base
    -- seed forever would make every server walk one layout. The UTC day
    -- salts the default so consecutive days field different woods, while an
    -- explicit LastLightExpeditionSeed attribute still pins a build exactly
    -- (Studio tests and repro sessions depend on that).
    local daySalt = (tonumber(os.date("!%j")) or 0) * 131 + (tonumber(os.date("!%Y")) or 0)
    local seed = if type(requestedSeed) == "number" then requestedSeed else self._seed + daySalt
    --[[
        Which region this server walks. RegionAccess resolves the request
        (a Studio attribute for tests; a departure choice once more than
        one region is buildable) against the region registry's enabled
        flags and the story's chapters, and everything that is not an
        open region resolves to Bramblewake. The builder below is still
        Bramblewake's own, so the assert is load-bearing: if a region is
        ever enabled before its builder exists, this fails at boot in
        plain words instead of building a forest where a mine should be.
    ]]
    local requestedRegion = game:GetAttribute("LastLightExpeditionRegion")
    local regionId = self._regionAccess.destinationFor(requestedRegion, nil)
    local catalog = self._generator.catalogFor(regionId)
    assert(
        regionId == "region_bramblewake",
        "region " .. tostring(regionId) .. " is enabled but has no builder wired"
    )
    self._catalog = catalog
    self._regionId = regionId
    self:_buildRegion(seed)
end

--[[
    Roll a seed into a walkable wood and stand it up.

    Split out of Init because a private server's owner can ask for a different
    one at runtime, and the alternative -- a second copy of this sequence in the
    rebuild path -- is how a manifest gets built without its event states, or
    dressed without its fallback metric. `BramblewakeBuilder.build` already
    destroys whatever it finds before it builds, which is what makes calling
    this twice safe rather than merely possible.
]]
function ExpeditionService._buildRegion(self: ExpeditionService, seed: number)
    local regionId = self._regionId
    local manifest = self._generator.generate(seed, false, nil, regionId)
    local valid, issues = self._generator.validate(manifest)
    assert(valid, "expedition manifest is invalid: " .. table.concat(issues, "; "))

    --[[
        A seed that could not produce a walkable manifest, said out loud.

        The generator already handles this correctly -- it hands back the
        known-good walk rather than a broken world -- and that is exactly why
        it needed an emitter: the recovery is silent, so without this the
        fallback rate threshold in RELEASE_GATES.md reads zero whether the
        generator is perfect or broken. Nobody in a live session would notice
        either, because both look like an expedition.
    ]]
    -- GATE-METRIC: generator_fallback
    if manifest.source ~= "generated" then
        self._analyticsService:generatorFallback(regionId, manifest.seed, manifest.source)
    end

    local result = self._worldService:buildBramblewake(manifest, self._generator, self._catalog)
    self._manifest = manifest
    self._partCount = result.partCount
    self._eventsEnabled = self._featureFlags:isEnabled("bramblewake_events_enabled")
    self._worldService:setExpeditionEventsEnabled(self._eventsEnabled)
    self._eventStates = {}
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

--[[
    Walk a different seed, in a server that has already given up on rewards.

    Refused while anybody is inside, and that refusal is the whole safety
    argument: rebuilding the wood destroys the model the people in it are
    standing on. Refused too when the seed is one this build cannot resolve, so
    a history entry from an older catalog fails here rather than half-way
    through a rebuild.
]]
function ExpeditionService.rebuildWithSeed(self: ExpeditionService, seed: any): (boolean, string)
    local numericSeed = tonumber(seed)
    if numericSeed == nil then
        return false, "invalid_seed"
    end
    if self:occupied() then
        return false, "expedition_occupied"
    end
    --[[
        The flag, and it is the whole safety argument rather than bookkeeping.

        `_buildRegion` yields -- the generator and the world builder both run
        across frames -- so the check above and the finished wood are not the
        same moment. Without this, `enter` can admit somebody in between and
        put them on a model that is about to be destroyed under them, which is
        precisely the failure the refusal exists to prevent, arrived at through
        the door the refusal is guarding.
    ]]
    self._rebuilding = true
    local ok, err = pcall(function()
        self:_buildRegion(numericSeed)
    end)
    self._rebuilding = false
    if not ok then
        self._logger:warn("expedition_rebuild_failed", { reason = tostring(err) })
        return false, "invalid_seed"
    end
    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    self._logger:warn("expedition_rebuilt", {
        hash = manifest.hash,
        seed = manifest.seed,
        source = manifest.source,
    })
    return true, "rebuilt"
end

function ExpeditionService.currentSeed(self: ExpeditionService): (string, number)
    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    return self._regionId, manifest.seed
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
    local function bindPlayer(player: Player)
        player.CharacterAdded:Connect(function(character: Model)
            task.defer(function()
                local root = character:WaitForChild("HumanoidRootPart", 5)
                if
                    root ~= nil
                    and player.Parent ~= nil
                    and player.Character == character
                    and player:GetAttribute("LastLightInExpedition") ~= true
                then
                    self:_deliverPendingPayoff(player)
                end
            end)
        end)
    end
    Players.PlayerAdded:Connect(bindPlayer)
    for _, player in Players:GetPlayers() do
        bindPlayer(player)
    end
    Players.PlayerRemoving:Connect(function(player: Player)
        self._pendingExtractionPayoffs[player] = nil
        self._worldService:clearRecoveryCache(player)
    end)
end

-- Whether anybody is standing in the wood. Read by the rebuild and by the
-- control that asks for one, so the refusal a player is shown and the refusal
-- the service enforces are the same question rather than two copies of it.
function ExpeditionService.occupied(_self: ExpeditionService): boolean
    for _, player in Players:GetPlayers() do
        if player:GetAttribute("LastLightInExpedition") == true then
            return true
        end
    end
    return false
end

function ExpeditionService.enter(self: ExpeditionService, player: Player): boolean
    if self._rebuilding then
        -- The wood is being torn down and stood up again. Admitting somebody
        -- now would drop them onto a model that is about to be destroyed.
        return false
    end
    local entered = self._worldService:enterBramblewake(player)
    if entered then
        --[[
            A seed is discovered by being walked, not by being rolled.

            Recorded here rather than at departure because a run somebody never
            reached is a layout they have never seen, and "among already
            discovered seeds" is the only bound private-server seed selection
            has. A practice server records nothing, which is correct twice
            over: the profile is read-only there anyway, and a seed handed to
            you by a control is not one you found.
        ]]
        local manifest = self._manifest
        if manifest ~= nil then
            self._profileService:recordDiscoveredSeed(player, self._regionId, manifest.seed)
        end
        local cache = self._profileService:recoveryCache(player)
        if cache ~= nil then
            self._worldService:showRecoveryCache(player, cache)
        end
    end
    return entered
end

function ExpeditionService.failExpedition(self: ExpeditionService, player: Player): any
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return { accepted = false, message = nil, reason = "player_not_in_expedition" }
    end
    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    local sessionPending = self._rewardLedger.pending(self._rewardLedgerState, player.UserId)
    local result = self._profileService:cacheExpeditionFailure(
        player,
        self._runId,
        manifest.hash,
        sessionPending.rewards
    )
    self._worldService:clearRecoveryCache(player)
    if result.cached and result.cacheId ~= nil then
        self._logger:info("expedition_recovery_cache_created", {
            cache = result.cacheId,
            player = player.UserId,
            retained = result.retained,
        })
        return {
            accepted = result.accepted,
            cacheId = result.cacheId,
            message = "SAFE RETREAT — HALF THE POUCH WAITS IN A LOST SATCHEL",
            reason = result.reason,
        }
    end
    return {
        accepted = result.accepted,
        message = if result.accepted
            then "SAFE RETREAT — SMALL POUCH RETAINED"
            else "SAFE RETREAT — POUCH RETAINED WHILE PROFILE RECOVERS",
        reason = result.reason,
    }
end

function ExpeditionService.recoverCache(
    self: ExpeditionService,
    player: Player,
    prompt: ProximityPrompt
): any
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return { accepted = false, message = "ENTER BRAMBLEWAKE TO RECOVER THE SATCHEL" }
    end
    if prompt:GetAttribute("OwnerUserId") ~= player.UserId then
        return { accepted = false, message = "THAT LOST SATCHEL BELONGS TO ANOTHER TRAVELER" }
    end
    local cacheId = prompt:GetAttribute("Payload")
    if type(cacheId) ~= "string" then
        return { accepted = false, message = "THAT RECOVERY MARK IS INVALID" }
    end
    local result = self._profileService:recoverExpeditionCache(player, cacheId)
    if not result.accepted then
        return {
            accepted = false,
            message = if result.reason == "save_pending"
                then "SATCHEL RECOVERY WILL RETRY WHEN YOUR PROFILE IS READY"
                else "THAT SATCHEL HAS ALREADY BEEN RECOVERED",
            reason = result.reason,
        }
    end
    self._worldService:clearRecoveryCache(player)
    local amount = 0
    for _, count in result.materials do
        amount += count
    end
    self._logger:info("expedition_recovery_cache_claimed", {
        amount = amount,
        cache = cacheId,
        player = player.UserId,
    })
    return {
        accepted = true,
        message = string.format("LOST SATCHEL RECOVERED — %d MATERIALS BACK IN POUCH", amount),
        reason = "recovered",
    }
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

function ExpeditionService._grant(
    self: ExpeditionService,
    userId: number,
    transactionId: string,
    manifestHash: string,
    reward: any,
    sourceKind: string,
    sourceId: string
): boolean
    local granted = self._rewardLedger.grant(
        self._rewardLedgerState,
        userId,
        transactionId,
        manifestHash,
        reward
    )
    if not granted then
        return false
    end
    local sourceField = if sourceKind == "event" then "event" else "encounter"
    local grantedFields: { [string]: any } = {
        amount = reward.amount,
        material = reward.materialId,
        transaction = transactionId,
        userId = userId,
    }
    grantedFields[sourceField] = sourceId
    self._logger:info("expedition_" .. sourceKind .. "_reward_granted", grantedFields)
    local player = Players:GetPlayerByUserId(userId)
    if player ~= nil then
        -- The active contract's trade lands here, at the single point every
        -- expedition reward passes through. The transaction id is untouched,
        -- so idempotency and replay behave exactly as before.
        local contracted = table.clone(reward)
        contracted.amount = self._contracts.applyReward(self._contract, reward.amount)
        local profileResult = self._profileService:grantUnbankedExpeditionReward(
            player,
            transactionId,
            manifestHash,
            contracted
        )
        local persistedFields: { [string]: any } = {
            durable = profileResult.durable == true,
            player = userId,
            transaction = transactionId,
        }
        persistedFields[sourceField] = sourceId
        self._logger:info("expedition_" .. sourceKind .. "_reward_persisted", persistedFields)
    end
    return true
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
    return self:_grant(
        userId,
        transactionId,
        state.manifestHash,
        definition.reward,
        "event",
        definition.id
    )
end

--[[
    Grant a harvested resource node.

    Nodes are the reason to walk the route at all, so they go through the same
    idempotent grant path as events and encounters: one transaction per node
    per run, recorded against the run's manifest, so a node cannot be farmed by
    re-clicking it or by a duplicated remote.
]]
function ExpeditionService.grantNodeReward(
    self: ExpeditionService,
    userId: number,
    nodeId: string,
    reward: any
): boolean
    if type(nodeId) ~= "string" or string.sub(nodeId, 1, 5) ~= "node_" then
        self._logger:warn("expedition_node_reward_rejected", {
            node = nodeId,
            reason = "invalid_node_id",
            userId = userId,
        })
        return false
    end
    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    -- The node's own ID is the transaction, so harvesting is exactly-once for
    -- the life of the run regardless of how many times it is asked for.
    return self:_grant(userId, nodeId, manifest.hash, reward, "node", nodeId)
end

function ExpeditionService.grantEncounterReward(
    self: ExpeditionService,
    userId: number,
    encounterId: string,
    transactionId: string,
    reward: any
): boolean
    local validEncounter = string.sub(encounterId, 1, 6) == "elite_"
        or string.sub(encounterId, 1, 5) == "boss_"
    if not validEncounter then
        self._logger:warn("expedition_encounter_reward_rejected", {
            encounter = encounterId,
            reason = "invalid_encounter_id",
            userId = userId,
        })
        return false
    end
    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    return self:_grant(userId, transactionId, manifest.hash, reward, "encounter", encounterId)
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
    for _, transactionId in profileInventory.cachedTransactionIds do
        seen[transactionId] = true
    end
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
        recovery = profileInventory.recovery,
        rewards = rewards,
    }
end

--[[
    The departing party names its contract; the server resolves it safely
    (unknown ids become the standard sweep) and everything downstream reads
    the resolved contract, never the requested id.
]]
function ExpeditionService.bindEnemyService(self: ExpeditionService, enemyService: any)
    -- Late-bound: EnemyService is constructed after this service in the
    -- bootstrap, and the contract multiplier is the only thing crossing.
    self._enemyService = enemyService
end

function ExpeditionService.setContract(self: ExpeditionService, contractId: any)
    self._contract = self._contracts.resolve(contractId)
    if self._enemyService ~= nil then
        self._enemyService:setExpeditionDamageMultiplier(self._contract.enemyDamageMultiplier)
    end
    self._logger:info("expedition_contract_set", { contract = self._contract.id })
end

function ExpeditionService.contractSnapshot(self: ExpeditionService): any
    return {
        id = self._contract.id,
        title = self._contract.title,
        detail = self._contract.detail,
        rewardMultiplier = self._contract.rewardMultiplier,
        enemyDamageMultiplier = self._contract.enemyDamageMultiplier,
        weather = self._contract.weather,
    }
end

function ExpeditionService._deliverPendingPayoff(self: ExpeditionService, player: Player): boolean
    local payoff = self._extractionPayoff.claim(self._pendingExtractionPayoffs, player)
    if payoff == nil then
        return false
    end
    self._worldService:showExtractionPayoff(player, payoff.materials, payoff.overflow)
    return true
end

function ExpeditionService._exitWithPayoff(self: ExpeditionService, player: Player): boolean
    self._worldService:clearRecoveryCache(player)
    return self._worldService:exitBramblewake(player, function()
        self:_deliverPendingPayoff(player)
    end)
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
        local pendingPayoff = self._pendingExtractionPayoffs[player]
        if not self:_exitWithPayoff(player) then
            return {
                accepted = false,
                message = if pendingPayoff ~= nil
                    then "REWARDS BANKED — WAYHOME TRANSITION WILL RETRY"
                    else "WAYHOME TRANSITION WILL RETRY",
                reason = "transition_unavailable",
            }
        end
        self._analyticsService:expeditionExtracted(player, manifest.hash, nil, 0)
        return {
            accepted = true,
            banked = combinedPending.banked,
            message = if pendingPayoff ~= nil
                then "RETURNING TO EMBERHOLLOW — BANKED DELIVERY READY"
                else "RETURNING TO EMBERHOLLOW — POUCH EMPTY",
            settlementId = if pendingPayoff ~= nil then pendingPayoff.settlementId else nil,
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
    -- Overflow rides the payoff so whoever announces the banked delivery can
    -- also say the stores were full -- one moment, one message stream.
    self._pendingExtractionPayoffs[player] = {
        materials = settlement.materials or {},
        overflow = settlement.overflow,
        settlementId = settlement.settlementId,
    }
    if not self:_exitWithPayoff(player) then
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
    snapshot.recoveryCache = inventory.recovery
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
    -- Carried so the point of interest can say something specific to itself.
    -- Without it every landmark on the route shares one generic line, which
    -- is indistinguishable from having no landmark there at all.
    snapshot.pointOfInterestDetail = if poiDefinition == nil then nil else poiDefinition.detail
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
