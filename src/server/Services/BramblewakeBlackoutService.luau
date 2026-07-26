--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BramblewakeBlackoutService = {}
BramblewakeBlackoutService.__index = BramblewakeBlackoutService
BramblewakeBlackoutService.Name = "BramblewakeBlackoutService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type BramblewakeBlackoutService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _worldService: any,
        _expeditionService: any,
        _profileService: any,
        _survivalService: any,
        _oldGrowthService: any,
        _wardenStagService: any,
        _flow: any,
        _analyticsService: any,
        _featureFlags: any,
        _state: any,
        _arena: any,
        _onChanged: ((string?) -> ())?,
        _heartbeat: RBXScriptConnection?,
        _lastPublishedSecond: number,
        _persistedUsers: { [number]: boolean },
    },
    BramblewakeBlackoutService
))

local function rootPart(player: Player): BasePart?
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    return if root ~= nil and root:IsA("BasePart") then root else nil
end

function BramblewakeBlackoutService.new(
    logger: Logger,
    config: any,
    worldService: any,
    expeditionService: any,
    profileService: any,
    survivalService: any,
    oldGrowthService: any,
    wardenStagService: any,
    flow: any,
    analyticsService: any,
    featureFlags: any
): BramblewakeBlackoutService
    return setmetatable({
        Name = BramblewakeBlackoutService.Name,
        _logger = logger,
        _config = config,
        _worldService = worldService,
        _expeditionService = expeditionService,
        _profileService = profileService,
        _survivalService = survivalService,
        _oldGrowthService = oldGrowthService,
        _wardenStagService = wardenStagService,
        _flow = flow,
        _analyticsService = analyticsService,
        _featureFlags = featureFlags,
        _state = nil,
        _arena = nil,
        _onChanged = nil,
        _heartbeat = nil,
        _lastPublishedSecond = -1,
        _persistedUsers = {},
    }, BramblewakeBlackoutService)
end

function BramblewakeBlackoutService.Init(self: BramblewakeBlackoutService, _context: any)
    local manifest = assert(self._expeditionService:manifest(), "expedition manifest unavailable")
    self._arena = assert(self._worldService:blackoutArena(), "Blackout arena unavailable")
    self._state = self._flow.create(
        self._expeditionService:runId(),
        manifest.hash,
        self._featureFlags:isEnabled("bramblewake_blackout_enabled"),
        self._config.BlackoutNightSeconds
    )
    self._worldService:setBlackoutPresentation(self._state)
end

function BramblewakeBlackoutService.Start(self: BramblewakeBlackoutService)
    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.1 then
            return
        end
        accumulator = 0
        self:_step(workspace:GetServerTimeNow())
    end)
    self._logger:info("bramblewake_blackout_ready", {
        duration = self._config.BlackoutNightSeconds,
        enabled = self._state.status ~= "disabled",
        interval = self._config.BlackoutInterval,
        manifest = self._state.manifestHash,
    })
end

function BramblewakeBlackoutService.setChangedHandler(
    self: BramblewakeBlackoutService,
    callback: (string?) -> ()
)
    self._onChanged = callback
end

function BramblewakeBlackoutService._notify(self: BramblewakeBlackoutService, toast: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(toast)
    end
end

function BramblewakeBlackoutService._syncCarrierVisuals(
    self: BramblewakeBlackoutService,
    now: number
)
    for _, player in Players:GetPlayers() do
        local snapshot = self._flow.snapshot(self._state, player.UserId, now)
        player:SetAttribute("LastLightCarryingBlackoutFire", snapshot.carryingFire)
        player:SetAttribute("LastLightBlackoutFireExpiresAt", snapshot.fireExpiresAt)
        local root = rootPart(player)
        if root ~= nil then
            local light = root:FindFirstChild("BlackoutCarryLight")
            if snapshot.carryingFire and light == nil then
                local pointLight = Instance.new("PointLight")
                pointLight.Name = "BlackoutCarryLight"
                pointLight.Color = Color3.fromRGB(255, 146, 78)
                pointLight.Brightness = 2.4
                pointLight.Range = 20
                pointLight.Shadows = false
                pointLight.Parent = root
            elseif not snapshot.carryingFire and light ~= nil then
                light:Destroy()
            end
        end
    end
end

function BramblewakeBlackoutService._activeParticipantIds(
    self: BramblewakeBlackoutService
): { number }
    local result = {}
    for _, player in Players:GetPlayers() do
        if
            player:GetAttribute("LastLightInExpedition") == true
            and self._state.participants[tostring(player.UserId)] == true
        then
            table.insert(result, player.UserId)
        end
    end
    table.sort(result)
    return result
end

function BramblewakeBlackoutService._persistResolution(self: BramblewakeBlackoutService)
    if
        self._state.status ~= "complete"
        or self._state.decision == nil
        or self._state.wardenOutcome == nil
    then
        return
    end
    for _, player in Players:GetPlayers() do
        if
            self._state.participants[tostring(player.UserId)] == true
            and self._persistedUsers[player.UserId] ~= true
        then
            local transactionId = self._flow.chapterTransactionId(self._state, player.UserId)
            local result = self._profileService:completeChapterOne(
                player,
                transactionId,
                self._state.decision,
                self._state.wardenOutcome
            )
            if result.accepted and result.applied then
                self._analyticsService:chapterCompleted(
                    player,
                    1,
                    self._state.decision,
                    self._state.wardenOutcome,
                    transactionId
                )
                if result.durable then
                    self._persistedUsers[player.UserId] = true
                end
            elseif
                (result.accepted and result.durable)
                or (not result.accepted and result.reason == "chapter_already_resolved")
            then
                self._persistedUsers[player.UserId] = true
            elseif not result.accepted and result.reason ~= "profile_loading" then
                self._logger:warn("chapter_one_resolution_rejected", {
                    player = player.UserId,
                    reason = result.reason,
                    transaction = transactionId,
                })
            end
        end
    end
end

function BramblewakeBlackoutService._transition(
    self: BramblewakeBlackoutService,
    nextState: any,
    player: Player?,
    stageReason: string,
    toast: string
)
    self._state = nextState
    self._worldService:setBlackoutPresentation(self._state)
    if player ~= nil then
        self._analyticsService:blackoutStage(
            player,
            self._flow.Id,
            self._state.status,
            stageReason,
            self._state.revision
        )
    end
    self:_notify(toast)
end

function BramblewakeBlackoutService._representativePlayer(self: BramblewakeBlackoutService): Player?
    for _, player in Players:GetPlayers() do
        if self._state.participants[tostring(player.UserId)] == true then
            return player
        end
    end
    return nil
end

function BramblewakeBlackoutService._step(self: BramblewakeBlackoutService, now: number)
    if self._state.status == "old_growth" and self._oldGrowthService:isComplete() then
        local nextState, result = self._flow.completeOldGrowth(self._state)
        if result.accepted then
            self:_transition(
                nextState,
                self:_representativePlayer(),
                "old_growth_complete",
                "OLD GROWTH RELEASES THE WARDEN'S SEAL"
            )
        end
    elseif self._state.status == "warden" and self._wardenStagService:isComplete() then
        local outcome = self._wardenStagService:outcome()
        if outcome ~= nil then
            local nextState, result = self._flow.completeWarden(self._state, outcome)
            if result.accepted then
                self:_transition(
                    nextState,
                    self:_representativePlayer(),
                    "warden_complete",
                    "THE GREENWARD AWAITS YOUR VOTE"
                )
            end
        end
    elseif self._state.status == "resolution" then
        local eligibleUserIds = self:_activeParticipantIds()
        local nextState, result = self._flow.reconcileVote(self._state, eligibleUserIds)
        if result.resolved then
            self._state = nextState
            self._worldService:setBlackoutPresentation(self._state)
            self._worldService:setBlackoutLighting(false)
            self:_persistResolution()
            local player = Players:GetPlayerByUserId(eligibleUserIds[1])
            if player ~= nil then
                self._analyticsService:blackoutResult(
                    player,
                    self._flow.Id,
                    self._state.manifestHash,
                    self._state.decision,
                    self._state.wardenOutcome,
                    self._state.startedAt,
                    now
                )
            end
            self:_notify("CHAPTER I RESOLVED — " .. string.upper(self._state.decision))
        end
    elseif self._state.status == "complete" then
        self:_persistResolution()
    end

    self:_syncCarrierVisuals(now)
    if self._state.status ~= "dormant" and self._state.status ~= "disabled" then
        local second = math.floor(now)
        if second ~= self._lastPublishedSecond then
            self._lastPublishedSecond = second
            self:_notify(nil)
        end
    end
end

function BramblewakeBlackoutService.participantEntered(
    self: BramblewakeBlackoutService,
    player: Player
): any
    local story = self._profileService:chapterOneSnapshot(player)
    if self._state.status == "disabled" then
        return {
            accepted = false,
            message = "BLACKOUT PREVIEW DISABLED — BRAMBLEWAKE REMAINS OPEN",
            reason = "disabled",
        }
    end
    if not self._oldGrowthService:enabled() or not self._wardenStagService:enabled() then
        return {
            accepted = false,
            message = "BLACKOUT ENCOUNTERS ARE TEMPORARILY UNAVAILABLE",
            reason = "dependency_disabled",
        }
    end
    if self._state.status == "dormant" then
        if story ~= nil and story.status == "complete" then
            return {
                accepted = true,
                message = "CHAPTER I ALREADY RESOLVED — EXPEDITION OPEN",
                reason = "chapter_complete",
            }
        end
        local nextState, result =
            self._flow.start(self._state, player.UserId, workspace:GetServerTimeNow())
        if result.accepted then
            self._state = nextState
            self._worldService:setBlackoutLighting(true)
            self._worldService:setBlackoutPresentation(self._state)
            self._analyticsService:blackoutStarted(
                player,
                self._flow.Id,
                self._state.manifestHash,
                self._state.duration
            )
            self:_notify("BLACKOUT — CARRY ROOTFIRE BETWEEN LIVING ROOTS")
            return {
                accepted = true,
                message = "BLACKOUT — ROOTFIRE RELAY ACTIVE",
                reason = "started",
            }
        end
    elseif
        self._state.status == "relay"
        or self._state.status == "old_growth"
        or self._state.status == "warden"
        or self._state.status == "resolution"
    then
        self._state = self._flow.join(self._state, player.UserId)
        self._worldService:setBlackoutPresentation(self._state)
        self:_notify(nil)
        return {
            accepted = true,
            message = "JOINED THE ACTIVE BRAMBLEWAKE BLACKOUT",
            reason = "joined",
        }
    elseif self._state.status == "complete" then
        return {
            accepted = true,
            message = "BLACKOUT COMPLETE — CHAPTER RESULT RECORDED",
            reason = "complete",
        }
    end
    return {
        accepted = false,
        message = "BLACKOUT COULD NOT START",
        reason = self._state.status,
    }
end

function BramblewakeBlackoutService.interact(
    self: BramblewakeBlackoutService,
    player: Player,
    prompt: ProximityPrompt
): any
    if
        player:GetAttribute("LastLightInExpedition") ~= true
        or not self._survivalService:canAct(player)
    then
        return {
            accepted = false,
            message = "ENTER BRAMBLEWAKE WHILE ACTIVE",
            reason = "player_unavailable",
        }
    end
    local target = prompt.Parent
    local interaction = if target == nil then nil else target:GetAttribute("BlackoutInteraction")
    local nextState, result
    local now = workspace:GetServerTimeNow()
    if interaction == "take_fire" then
        nextState, result = self._flow.takeFire(self._state, player.UserId, now)
    elseif interaction == "deliver_fire" then
        local nodeId = tostring(target:GetAttribute("BlackoutNodeId"))
        if self._state.deliveredNodes[nodeId] == true then
            nextState, result = self._flow.takeFire(self._state, player.UserId, now)
        else
            nextState, result = self._flow.deliverFire(self._state, player.UserId, nodeId, now)
        end
    elseif interaction == "chapter_decision" then
        nextState, result = self._flow.vote(
            self._state,
            player.UserId,
            tostring(target:GetAttribute("BlackoutDecisionId")),
            self:_activeParticipantIds()
        )
    else
        return {
            accepted = false,
            message = "INVALID BLACKOUT INTERACTION",
            reason = "invalid_interaction",
        }
    end
    if not result.accepted then
        result.message = if result.reason == "fire_required"
                or result.reason == "fire_expired"
            then "TAKE FRESH ROOTFIRE FROM THE BLACKOUT LANTERN"
            elseif result.reason == "already_delivered" then "THAT LIVING ROOT ALREADY HOLDS FIRE"
            elseif
                self._state.status == "resolution"
            then "ONLY ACTIVE BLACKOUT PARTICIPANTS CAN VOTE"
            else "THAT BLACKOUT STEP IS NOT ACTIVE"
        return result
    end

    self._state = nextState
    self._worldService:setBlackoutPresentation(self._state)
    self:_syncCarrierVisuals(now)
    if result.reason == "fire_taken" then
        result.message = string.format(
            "ROOTFIRE TAKEN — DELIVER WITHIN %d SECONDS",
            self._flow.FireCarrySeconds
        )
    elseif result.reason == "fire_delivered" then
        result.message =
            string.format("LIVING ROOT LIT — %d / %d", result.delivered, result.required)
    elseif result.reason == "relay_complete" then
        result.message = "ROOTFIRE RELAY COMPLETE — OLD GROWTH AWAKENS"
        self._analyticsService:blackoutStage(
            player,
            self._flow.Id,
            self._state.status,
            "relay_complete",
            self._state.revision
        )
    elseif result.reason == "vote_recorded" then
        result.message = "GREENWARD VOTE RECORDED — WAITING FOR ACTIVE TRAVELERS"
    elseif result.reason == "resolved" then
        result.message = "CHAPTER I RESOLVED — " .. string.upper(self._state.decision)
        self._worldService:setBlackoutLighting(false)
        self:_persistResolution()
        self._analyticsService:blackoutResult(
            player,
            self._flow.Id,
            self._state.manifestHash,
            self._state.decision,
            self._state.wardenOutcome,
            self._state.startedAt,
            now
        )
    else
        result.message = "BLACKOUT UPDATED"
    end
    self:_notify(result.message)
    return result
end

function BramblewakeBlackoutService.allowsOldGrowth(self: BramblewakeBlackoutService): boolean
    return self._state.status == "old_growth"
end

function BramblewakeBlackoutService.allowsWarden(self: BramblewakeBlackoutService): boolean
    return self._state.status == "warden"
        or self._state.status == "resolution"
        or self._state.status == "complete"
end

function BramblewakeBlackoutService.snapshot(self: BramblewakeBlackoutService, player: Player): any
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return nil
    end
    local snapshot = self._flow.snapshot(self._state, player.UserId, workspace:GetServerTimeNow())
    snapshot.story = self._profileService:chapterOneSnapshot(player)
    return snapshot
end

return table.freeze(BramblewakeBlackoutService)
