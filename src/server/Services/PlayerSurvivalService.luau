--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerSurvivalService = {}
PlayerSurvivalService.__index = PlayerSurvivalService
PlayerSurvivalService.Name = "PlayerSurvivalService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

type ReviveChannel = {
    target: Player,
    reviver: Player,
    flow: any,
    tuning: any,
}

type DownedVisual = {
    character: Model,
    highlight: Highlight,
    interactionId: string,
    label: TextLabel,
    prompt: ProximityPrompt,
}

export type PlayerSurvivalService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _runtimeIds: any,
        _reviveFlow: any,
        _survivalState: any,
        _featureFlags: any,
        _worldService: any,
        _analyticsService: any,
        _equipmentStatsProvider: ((Player) -> any)?,
        _reviveTuningProvider: ((Player) -> any)?,
        _expeditionFailureHandler: ((Player) -> any)?,
        _partyRecoveryProvider: ((number, number) -> any)?,
        _partyRecoveryPending: boolean,
        _states: { [Player]: any },
        _spawned: { [Player]: boolean },
        _channels: { [Player]: ReviveChannel },
        _prompts: { [string]: ProximityPrompt },
        _targets: { [string]: Player },
        _visuals: { [Player]: DownedVisual },
        _regenCarry: { [Player]: number },
        _lastRegenAt: number?,
        _onChanged: ((Player?, string?) -> ())?,
        _heartbeat: RBXScriptConnection?,
    },
    PlayerSurvivalService
))

local function rootPart(player: Player): BasePart?
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    return if root ~= nil and root:IsA("BasePart") then root else nil
end

local function humanoid(player: Player): Humanoid?
    local character = player.Character
    return if character == nil then nil else character:FindFirstChildOfClass("Humanoid")
end

local function playerLabel(player: Player): string
    return string.sub(player.DisplayName, 1, 20)
end

function PlayerSurvivalService.new(
    logger: Logger,
    config: any,
    runtimeIds: any,
    reviveFlow: any,
    survivalState: any,
    featureFlags: any,
    worldService: any,
    analyticsService: any
): PlayerSurvivalService
    return setmetatable({
        Name = PlayerSurvivalService.Name,
        _logger = logger,
        _config = config,
        _runtimeIds = runtimeIds,
        _reviveFlow = reviveFlow,
        _survivalState = survivalState,
        _featureFlags = featureFlags,
        _worldService = worldService,
        _analyticsService = analyticsService,
        _equipmentStatsProvider = nil,
        _reviveTuningProvider = nil,
        _expeditionFailureHandler = nil,
        _partyRecoveryProvider = nil,
        _partyRecoveryPending = false,
        _states = {},
        _spawned = {},
        _channels = {},
        _prompts = {},
        _targets = {},
        _visuals = {},
        -- SurvivalState.heal only accepts whole positive points, so lantern
        -- regen accumulates fractional progress here and spends it a point at
        -- a time. Without the carry every tick would round to an invalid heal
        -- and silently do nothing.
        _regenCarry = {},
        _lastRegenAt = nil,
        _onChanged = nil,
        _heartbeat = nil,
    }, PlayerSurvivalService)
end

function PlayerSurvivalService.setEquipmentStatsProvider(
    self: PlayerSurvivalService,
    provider: (Player) -> any
)
    self._equipmentStatsProvider = provider
end

function PlayerSurvivalService.setReviveTuningProvider(
    self: PlayerSurvivalService,
    provider: (Player) -> any
)
    self._reviveTuningProvider = provider
end

function PlayerSurvivalService.setExpeditionFailureHandler(
    self: PlayerSurvivalService,
    handler: (Player) -> any
)
    self._expeditionFailureHandler = handler
end

function PlayerSurvivalService.setPartyRecoveryProvider(
    self: PlayerSurvivalService,
    provider: (number, number) -> any
)
    self._partyRecoveryProvider = provider
end

function PlayerSurvivalService._recordExpeditionFailure(
    self: PlayerSurvivalService,
    player: Player
): string?
    local handler = self._expeditionFailureHandler
    if handler == nil or player:GetAttribute("LastLightInExpedition") ~= true then
        return nil
    end
    local result = handler(player)
    return if type(result) == "table" and type(result.message) == "string"
        then result.message
        else nil
end

function PlayerSurvivalService._reviveTuning(self: PlayerSurvivalService, player: Player): any
    local provider = self._reviveTuningProvider
    if provider == nil then
        return {
            duration = self._config.ReviveChannelSeconds,
            health = self._config.ReviveHealth,
            professionId = nil,
            rescueTitle = "FIELD RESCUE",
            specialized = false,
            wardSeconds = self._config.ReviveInvulnerabilitySeconds,
        }
    end
    return provider(player)
end

function PlayerSurvivalService._equipmentDamage(
    self: PlayerSurvivalService,
    player: Player,
    amount: number
): (number, number)
    if amount ~= amount or amount <= 0 or amount >= math.huge or amount ~= math.floor(amount) then
        return amount, 0
    end
    local provider = self._equipmentStatsProvider
    if provider == nil then
        return amount, 0
    end
    local stats = provider(player)
    local reduction = math.clamp(
        if type(stats) == "table" and type(stats.damageReduction) == "number"
            then stats.damageReduction
            else 0,
        0,
        0.25
    )
    return math.max(1, math.ceil(amount * (1 - reduction))), reduction
end

function PlayerSurvivalService.Init(_self: PlayerSurvivalService, _context: any) end

function PlayerSurvivalService.setChangedHandler(
    self: PlayerSurvivalService,
    callback: (Player?, string?) -> ()
)
    self._onChanged = callback
end

function PlayerSurvivalService._notify(
    self: PlayerSurvivalService,
    player: Player?,
    message: string?
)
    local callback = self._onChanged
    if callback ~= nil then
        callback(player, message)
    end
end

function PlayerSurvivalService._syncPlayer(self: PlayerSurvivalService, player: Player)
    local state = self._states[player]
    if state == nil then
        return
    end
    local snapshot = self._survivalState.snapshot(state, workspace:GetServerTimeNow())
    player:SetAttribute("LastLightHealth", snapshot.health)
    player:SetAttribute("LastLightMaxHealth", snapshot.maxHealth)
    player:SetAttribute("LastLightDowned", snapshot.downed)
    player:SetAttribute("LastLightBleedoutAt", snapshot.bleedoutAt)
    local _, equipmentReduction = self:_equipmentDamage(player, 100)
    player:SetAttribute("LastLightEquipmentDamageReduction", equipmentReduction)

    local activeHumanoid = humanoid(player)
    if activeHumanoid ~= nil then
        activeHumanoid.MaxHealth = snapshot.maxHealth
        activeHumanoid.Health = math.max(1, snapshot.health)
        activeHumanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        activeHumanoid.WalkSpeed = if snapshot.downed
            then self._config.DownedWalkSpeed
            else self._config.BaseWalkSpeed
        activeHumanoid.JumpHeight = if snapshot.downed then 0 else self._config.BaseJumpHeight
        activeHumanoid.JumpPower = if snapshot.downed then 0 else self._config.BaseJumpPower
    end
end

function PlayerSurvivalService._clearVisual(self: PlayerSurvivalService, player: Player)
    player:SetAttribute("LastLightReviveEndsAt", nil)
    player:SetAttribute("LastLightReviverUserId", nil)
    player:SetAttribute("LastLightReviveProfessionId", nil)
    player:SetAttribute("LastLightReviveHealth", nil)
    player:SetAttribute("LastLightReviveWardSeconds", nil)
    local visual = self._visuals[player]
    if visual == nil then
        local character = player.Character
        if
            character ~= nil
            and CollectionService:HasTag(character, self._runtimeIds.PlayerDownedTag)
        then
            CollectionService:RemoveTag(character, self._runtimeIds.PlayerDownedTag)
        end
        return
    end
    self._prompts[visual.interactionId] = nil
    self._targets[visual.interactionId] = nil
    if visual.prompt.Parent ~= nil then
        visual.prompt:Destroy()
    end
    if visual.highlight.Parent ~= nil then
        visual.highlight:Destroy()
    end
    if CollectionService:HasTag(visual.character, self._runtimeIds.PlayerDownedTag) then
        CollectionService:RemoveTag(visual.character, self._runtimeIds.PlayerDownedTag)
    end
    self._visuals[player] = nil
end

function PlayerSurvivalService._createVisual(self: PlayerSurvivalService, player: Player)
    self:_clearVisual(player)
    local targetRoot = rootPart(player)
    local character = player.Character
    local state = self._states[player]
    if targetRoot == nil or character == nil or state == nil then
        return
    end

    local interactionId = string.format("revive:%d:%d", player.UserId, state.revision)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "LastLightRevivePrompt"
    prompt.ActionText = "REVIVE"
    prompt.ObjectText = playerLabel(player)
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = self._config.ReviveDistance
    prompt.RequiresLineOfSight = true
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt:SetAttribute("ActionId", self._runtimeIds.Actions.Revive)
    prompt:SetAttribute("InteractionId", interactionId)
    prompt:SetAttribute("TargetUserId", player.UserId)
    prompt.Parent = targetRoot
    CollectionService:AddTag(prompt, self._runtimeIds.InteractionTag)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DownedMarker"
    billboard.Adornee = targetRoot
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 120
    billboard.Size = UDim2.fromOffset(210, 58)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0)
    billboard.Parent = prompt

    local label = Instance.new("TextLabel")
    label.Name = "DownedLabel"
    label.BackgroundColor3 = Color3.fromRGB(47, 20, 18)
    label.BackgroundTransparency = 0.08
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = Color3.fromRGB(255, 230, 194)
    label.TextScaled = true
    label.TextStrokeTransparency = 0.72
    label.TextWrapped = true
    label.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 181, 76)
    stroke.Thickness = 2
    stroke.Transparency = 0.12
    stroke.Parent = label

    local highlight = Instance.new("Highlight")
    highlight.Name = "DownedOutline"
    highlight.FillColor = Color3.fromRGB(165, 55, 47)
    highlight.FillTransparency = 0.72
    highlight.OutlineColor = Color3.fromRGB(255, 181, 76)
    highlight.OutlineTransparency = 0.08
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    CollectionService:AddTag(character, self._runtimeIds.PlayerDownedTag)

    self._prompts[interactionId] = prompt
    self._targets[interactionId] = player
    self._visuals[player] = {
        character = character,
        highlight = highlight,
        interactionId = interactionId,
        label = label,
        prompt = prompt,
    }
end

function PlayerSurvivalService._updateVisual(
    self: PlayerSurvivalService,
    player: Player,
    now: number
)
    local visual = self._visuals[player]
    local state = self._states[player]
    if visual == nil or state == nil then
        return
    end
    local snapshot = self._survivalState.snapshot(state, now)
    visual.label.Text = string.format(
        "✚ %s DOWN\n%02ds · REVIVE",
        string.upper(playerLabel(player)),
        snapshot.timeRemaining
    )
end

function PlayerSurvivalService._bindPlayer(self: PlayerSurvivalService, player: Player)
    if self._states[player] ~= nil then
        return
    end
    self._states[player] = self._survivalState.create(workspace:GetServerTimeNow())

    local function characterAdded(character: Model)
        local now = workspace:GetServerTimeNow()
        local previousState = self._states[player]
        local returningCharacter = self._spawned[player] == true
        self._spawned[player] = true
        local resetFromDowned = previousState ~= nil and previousState.status == "downed"
        self:_cancelChannel(player, "target_character_reset")
        for target, channel in self._channels do
            if channel.reviver == player then
                self:_cancelChannel(target, "reviver_character_reset")
            end
        end
        self:_clearVisual(player)
        if returningCharacter then
            self._states[player] = self._survivalState.respawn(previousState, now)
        elseif resetFromDowned then
            self._states[player] = self._survivalState.safeRetreat(previousState, now)
        else
            self._states[player] = self._survivalState.create(now)
        end
        task.spawn(function()
            local activeHumanoid = character:WaitForChild("Humanoid", 8)
            if
                activeHumanoid ~= nil
                and activeHumanoid:IsA("Humanoid")
                and player.Parent ~= nil
            then
                activeHumanoid.BreakJointsOnDeath = false
                self:_syncPlayer(player)
                if returningCharacter or resetFromDowned then
                    local retreatMessage = nil
                    if player:GetAttribute("LastLightInExpedition") == true then
                        retreatMessage = self:_recordExpeditionFailure(player)
                        self._worldService:exitBramblewake(player)
                    end
                    self._analyticsService:playerRecovered(
                        player,
                        if resetFromDowned
                            then "character_reset_safe_retreat"
                            else "character_respawn_safe_retreat"
                    )
                    self:_notify(player, retreatMessage or "SAFE RETREAT — CHARACTER RESET")
                end
                self:_notify(nil, nil)
            end
        end)
    end
    player.CharacterAdded:Connect(characterAdded)
    if player.Character ~= nil then
        characterAdded(player.Character)
    else
        self:_syncPlayer(player)
    end
end

function PlayerSurvivalService.Start(self: PlayerSurvivalService)
    Players.PlayerAdded:Connect(function(player: Player)
        self:_bindPlayer(player)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        self:_cancelChannel(player, "target_left")
        self:_clearVisual(player)
        self._states[player] = nil
        self._spawned[player] = nil
        self._regenCarry[player] = nil
        for target, channel in self._channels do
            if channel.reviver == player then
                self:_cancelChannel(target, "reviver_left")
            end
        end
        task.defer(function()
            self:_attemptPartyRecovery()
        end)
    end)
    for _, player in Players:GetPlayers() do
        self:_bindPlayer(player)
    end

    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.1 then
            return
        end
        accumulator = 0
        self:_step(workspace:GetServerTimeNow())
    end)
end

function PlayerSurvivalService.canAct(self: PlayerSurvivalService, player: Player): boolean
    local state = self._states[player]
    return state ~= nil and self._survivalState.canAct(state)
end

function PlayerSurvivalService.damage(
    self: PlayerSurvivalService,
    player: Player,
    amount: number,
    source: string
): any
    if not self._featureFlags:isEnabled("player_survival_enabled") then
        return {
            applied = false,
            reason = "survival_disabled",
        }
    end
    local state = self._states[player]
    if state == nil then
        return {
            applied = false,
            reason = "player_loading",
        }
    end
    local now = workspace:GetServerTimeNow()
    local mitigatedAmount, equipmentReduction = self:_equipmentDamage(player, amount)
    local nextState, result = self._survivalState.damage(state, mitigatedAmount, now)
    if not result.applied then
        return result
    end

    self._states[player] = nextState
    result.rawDamage = amount
    result.equipmentReduction = equipmentReduction
    self:_syncPlayer(player)
    if result.downed then
        self:_createVisual(player)
        self._analyticsService:playerDowned(player, string.sub(source, 1, 48))
        self:_notify(player, "DOWNED — CRAWL TOWARD LIGHT")
        self:_attemptPartyRecovery()
    else
        self:_notify(nil, nil)
    end
    return result
end

function PlayerSurvivalService._attemptPartyRecovery(self: PlayerSurvivalService)
    local provider = self._partyRecoveryProvider
    if provider == nil or self._partyRecoveryPending then
        return
    end

    local eligible: { Player } = {}
    local downed = 0
    for player, state in self._states do
        if
            player.Parent ~= nil
            and player:GetAttribute("LastLightTutorialSurvivalReady") == true
            and player:GetAttribute("LastLightInExpedition") ~= true
        then
            table.insert(eligible, player)
            if state.status == "downed" then
                downed += 1
            end
        end
    end
    if #eligible < 1 or downed ~= #eligible then
        return
    end

    self._partyRecoveryPending = true
    local result = provider(#eligible, downed)
    if type(result) ~= "table" or result.accepted ~= true then
        self._partyRecoveryPending = false
        return
    end

    local channelTargets: { Player } = {}
    for target in self._channels do
        table.insert(channelTargets, target)
    end
    for _, target in channelTargets do
        self:_cancelChannel(target, "town_guard_last_stand")
    end
    local now = workspace:GetServerTimeNow()
    local recovered = {}
    for _, player in eligible do
        local state = self._states[player]
        if state ~= nil and state.status == "downed" then
            local nextState, recovery = self._survivalState.revive(state, now, {
                health = result.recoveryHealth,
                wardSeconds = result.recoveryWardSeconds,
            })
            if recovery.applied then
                self._states[player] = nextState
                self:_clearVisual(player)
                self:_syncPlayer(player)
                player:SetAttribute("LastLightGuardRecoveryNight", result.nightNumber)
                table.insert(recovered, player)
                self._analyticsService:playerRecovered(player, "town_guard_last_stand")
            end
        end
    end
    self._worldService:showTownGuardRecovery(recovered, result)
    self:_notify(
        nil,
        string.format(
            "THE NIGHT WATCH ANSWERS — %d TRAVELER%s RALLIED · LANTERN -%d",
            #recovered,
            if #recovered == 1 then "" else "S",
            result.lanternSpent or result.lanternCost or 0
        )
    )
    self._partyRecoveryPending = false
end

function PlayerSurvivalService.canHealInRadius(
    self: PlayerSurvivalService,
    source: Player,
    radius: number
): (boolean, string)
    if not self:canAct(source) then
        return false, "YOU CANNOT HEAL WHILE DOWNED"
    end
    local sourceRoot = rootPart(source)
    if sourceRoot == nil then
        return false, "YOUR CHARACTER IS STILL LOADING"
    end
    for player, state in self._states do
        local targetRoot = rootPart(player)
        if
            state.status == "active"
            and state.health < state.maxHealth
            and targetRoot ~= nil
            and (sourceRoot.Position - targetRoot.Position).Magnitude <= radius
        then
            return true, "GUIDING PULSE READY"
        end
    end
    return false, "NO INJURED TRAVELER IS WITHIN THE PULSE"
end

function PlayerSurvivalService.healInRadius(
    self: PlayerSurvivalService,
    source: Player,
    amount: number,
    radius: number
): any
    local canHeal, reason = self:canHealInRadius(source, radius)
    if not canHeal then
        return {
            affected = 0,
            healed = 0,
            reason = reason,
        }
    end

    local sourceRoot = assert(rootPart(source), "healing source root disappeared")
    local affected = 0
    local totalHealed = 0
    for player, state in self._states do
        local targetRoot = rootPart(player)
        if
            targetRoot ~= nil
            and (sourceRoot.Position - targetRoot.Position).Magnitude <= radius
        then
            local nextState, result = self._survivalState.heal(state, amount)
            if result.applied then
                self._states[player] = nextState
                affected += 1
                totalHealed += result.healed or 0
                self:_syncPlayer(player)
            end
        end
    end
    self:_notify(nil, nil)
    return {
        affected = affected,
        healed = totalHealed,
        reason = "healed",
    }
end

function PlayerSurvivalService.interaction(
    self: PlayerSurvivalService,
    interactionId: string
): ProximityPrompt?
    return self._prompts[interactionId]
end

function PlayerSurvivalService._canReach(
    self: PlayerSurvivalService,
    reviver: Player,
    target: Player
): boolean
    local reviverRoot = rootPart(reviver)
    local targetRoot = rootPart(target)
    local reviverCharacter = reviver.Character
    local targetCharacter = target.Character
    if
        reviverRoot == nil
        or targetRoot == nil
        or reviverCharacter == nil
        or targetCharacter == nil
        or (reviverRoot.Position - targetRoot.Position).Magnitude > self._config.ReviveDistance
    then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { reviverCharacter }
    local result =
        workspace:Raycast(reviverRoot.Position, targetRoot.Position - reviverRoot.Position, params)
    return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end

function PlayerSurvivalService.beginRevive(
    self: PlayerSurvivalService,
    reviver: Player,
    interactionId: string
): any
    local target = self._targets[interactionId]
    local prompt = self._prompts[interactionId]
    if target == nil or prompt == nil or not prompt.Enabled then
        return {
            accepted = false,
            message = "THAT RESCUE MARK IS NO LONGER ACTIVE",
            reason = "unknown_revive",
        }
    end
    if target == reviver then
        return {
            accepted = false,
            message = "AN ALLY MUST COMPLETE THE REVIVE",
            reason = "self_revive",
        }
    end
    if not self:canAct(reviver) then
        return {
            accepted = false,
            message = "YOU CANNOT REVIVE WHILE DOWNED",
            reason = "reviver_downed",
        }
    end
    local targetState = self._states[target]
    if targetState == nil or targetState.status ~= "downed" then
        return {
            accepted = false,
            message = "THAT ALLY IS ALREADY SAFE",
            reason = "target_not_downed",
        }
    end
    if not self:_canReach(reviver, target) then
        return {
            accepted = false,
            message = "MOVE CLOSER WITH A CLEAR PATH",
            reason = "revive_out_of_range",
        }
    end

    local existing = self._channels[target]
    if existing ~= nil then
        return {
            accepted = existing.reviver == reviver,
            message = if existing.reviver == reviver
                then "REVIVE IN PROGRESS — STAY CLOSE"
                else "ANOTHER ALLY IS REVIVING THEM",
            reason = "revive_in_progress",
        }
    end

    local reviverState = assert(self._states[reviver], "reviver survival state is missing")
    local now = workspace:GetServerTimeNow()
    local tuning = self:_reviveTuning(reviver)
    local channel = {
        target = target,
        reviver = reviver,
        tuning = tuning,
        flow = self._reviveFlow.create(
            target.UserId,
            reviver.UserId,
            reviverState.revision,
            now,
            tuning.duration
        ),
    }
    self._channels[target] = channel
    prompt.ActionText = if tuning.specialized then tuning.rescueTitle else "REVIVING"
    target:SetAttribute("LastLightReviveEndsAt", channel.flow.endsAt)
    target:SetAttribute("LastLightReviverUserId", reviver.UserId)
    target:SetAttribute("LastLightReviveProfessionId", tuning.professionId)
    target:SetAttribute("LastLightReviveHealth", tuning.health)
    target:SetAttribute("LastLightReviveWardSeconds", tuning.wardSeconds)
    self:_notify(nil, nil)
    return {
        accepted = true,
        message = string.format(
            "%s — %s — STAY CLOSE",
            tuning.rescueTitle,
            string.upper(playerLabel(target))
        ),
        reason = "revive_started",
    }
end

function PlayerSurvivalService._cancelChannel(
    self: PlayerSurvivalService,
    target: Player,
    reason: string
)
    local channel = self._channels[target]
    if channel == nil then
        return
    end
    self._channels[target] = nil
    target:SetAttribute("LastLightReviveEndsAt", nil)
    target:SetAttribute("LastLightReviverUserId", nil)
    target:SetAttribute("LastLightReviveProfessionId", nil)
    target:SetAttribute("LastLightReviveHealth", nil)
    target:SetAttribute("LastLightReviveWardSeconds", nil)
    local visual = self._visuals[target]
    if visual ~= nil then
        visual.prompt.ActionText = "REVIVE"
    end
    self._logger:info("player_revive_cancelled", {
        reason = reason,
        reviver = channel.reviver.UserId,
        target = target.UserId,
    })
    self:_notify(channel.reviver, "REVIVE INTERRUPTED")
end

function PlayerSurvivalService._completeRevive(
    self: PlayerSurvivalService,
    target: Player,
    channel: ReviveChannel,
    now: number
)
    local state = self._states[target]
    if state == nil then
        self:_cancelChannel(target, "target_left")
        return
    end
    local nextState, result = self._survivalState.revive(state, now, {
        health = channel.tuning.health,
        wardSeconds = channel.tuning.wardSeconds,
    })
    if not result.applied then
        self:_cancelChannel(target, result.reason)
        return
    end

    self._channels[target] = nil
    self._states[target] = nextState
    self:_clearVisual(target)
    self:_syncPlayer(target)
    self._analyticsService:playerRevived(
        target,
        channel.reviver,
        math.max(0, now - channel.flow.startedAt)
    )
    self:_notify(
        target,
        string.format(
            "BACK ON YOUR FEET — %d HEALTH · %.1fs LIGHT WARD",
            result.health,
            channel.tuning.wardSeconds
        )
    )
    self:_notify(channel.reviver, channel.tuning.rescueTitle .. " COMPLETE")
end

function PlayerSurvivalService._recover(self: PlayerSurvivalService, player: Player, now: number)
    local state = self._states[player]
    if state == nil then
        return
    end
    local nextState, result = self._survivalState.recover(state, now)
    if not result.applied then
        return
    end

    self._channels[player] = nil
    self._states[player] = nextState
    self:_clearVisual(player)
    self:_syncPlayer(player)
    local retreatMessage = nil
    if player:GetAttribute("LastLightInExpedition") == true then
        retreatMessage = self:_recordExpeditionFailure(player)
        self._worldService:exitBramblewake(player)
    else
        local character = player.Character
        if character ~= nil then
            character:PivotTo(self._worldService:spawnCFrame())
        end
    end
    self._analyticsService:playerRecovered(player, "bleedout_safe_retreat")
    self:_notify(player, retreatMessage or "SAFE RETREAT — UNBANKED POUCH RETAINED")
end

--[[
    Slow health recovery for players standing in the First Lantern's light.

    Without this a player who is not a Medic has no way back to full health at
    all: the only other sources are the Medic's ability and the health granted
    by a revive. Kept deliberately weak and anchored to the town so it does not
    replace the Medic in the field.
]]
function PlayerSurvivalService._stepLanternRegen(self: PlayerSurvivalService, now: number)
    local radius = tonumber(self._config.LanternSafeRadius)
    local rate = tonumber(self._config.LanternRegenPerSecond)
    if radius == nil or rate == nil or rate <= 0 then
        return
    end
    local worldService = self._worldService
    if worldService == nil or worldService.lanternSafeCenter == nil then
        return
    end
    local center = worldService:lanternSafeCenter()
    if center == nil then
        return
    end

    -- Clamped so a long server hitch cannot bank a full heal in one tick.
    local elapsed = math.clamp(now - (self._lastRegenAt or now), 0, 1)
    self._lastRegenAt = now
    if elapsed <= 0 then
        return
    end

    -- Anyone currently channeling a revive is excluded. SurvivalState.heal
    -- bumps the healed player's revision, and ReviveFlow.evaluate cancels a
    -- channel with reviver_state_changed the moment the reviver's revision
    -- differs from the one captured at revive start. Since a whole point lands
    -- roughly every 0.6s and a revive runs 2.5s, an injured player reviving an
    -- ally inside the safe zone would have the channel cancelled out from
    -- under them every single time -- and the town, next to the lantern, is
    -- exactly where reviving is most likely to happen.
    local reviving: { [Player]: boolean } = {}
    for _, channel in self._channels do
        reviving[channel.reviver] = true
    end

    local healedAny = false
    for player, state in self._states do
        local root = rootPart(player)
        -- Out of the light, downed, mid-revive, and already at full health all
        -- mean the same thing here: bank nothing and drop whatever fractional
        -- progress was carried, so leaving and returning does not resume
        -- mid-point.
        local eligible = root ~= nil
            and (root.Position - center).Magnitude <= radius
            and self._survivalState.canAct(state)
            and not reviving[player]
            and state.health < state.maxHealth
        if not eligible then
            self._regenCarry[player] = nil
        else
            local carried = (self._regenCarry[player] or 0) + rate * elapsed
            local whole = math.floor(carried)
            self._regenCarry[player] = carried - whole
            if whole >= 1 then
                local nextState, result = self._survivalState.heal(state, whole)
                if result.applied then
                    self._states[player] = nextState
                    self:_syncPlayer(player)
                    healedAny = true
                end
            end
        end
    end

    -- _syncPlayer only writes attributes and the Humanoid. The HUD renders
    -- from the survival snapshot published through the changed handler, so
    -- without this the health pill sits at its stale value while the
    -- authoritative state climbs, then jumps when some unrelated event
    -- finally triggers a publish.
    if healedAny then
        self:_notify(nil, nil)
    end
end

function PlayerSurvivalService._step(self: PlayerSurvivalService, now: number)
    for player, state in self._states do
        local activeHumanoid = humanoid(player)
        if activeHumanoid ~= nil then
            local expectedHealth = math.max(1, state.health)
            if activeHumanoid.Health ~= expectedHealth then
                activeHumanoid.Health = expectedHealth
            end
        end
        if state.status == "downed" then
            self:_updateVisual(player, now)
            if type(state.bleedoutAt) == "number" and now >= state.bleedoutAt then
                self:_recover(player, now)
            end
        end
    end

    self:_stepLanternRegen(now)

    for target, channel in self._channels do
        local reviverState = self._states[channel.reviver]
        local targetState = self._states[target]
        local decision = self._reviveFlow.evaluate(channel.flow, now, {
            reachable = reviverState ~= nil
                and targetState ~= nil
                and self:_canReach(channel.reviver, target),
            reviverCanAct = reviverState ~= nil and self._survivalState.canAct(reviverState),
            reviverPresent = channel.reviver.Parent ~= nil and reviverState ~= nil,
            reviverRevision = if reviverState == nil then -1 else reviverState.revision,
            targetDowned = targetState ~= nil and targetState.status == "downed",
            targetPresent = target.Parent ~= nil and targetState ~= nil,
        })
        if decision.status == "cancel" then
            self:_cancelChannel(target, decision.reason)
        elseif decision.status == "complete" then
            self:_completeRevive(target, channel, now)
        end
    end
end

local function directionLabel(viewerRoot: BasePart, targetRoot: BasePart): string
    local offset = targetRoot.Position - viewerRoot.Position
    if offset.Magnitude < 0.01 then
        return "HERE"
    end
    local direction = offset.Unit
    local forward = viewerRoot.CFrame.LookVector:Dot(direction)
    local right = viewerRoot.CFrame.RightVector:Dot(direction)
    if math.abs(forward) >= math.abs(right) then
        return if forward >= 0 then "AHEAD" else "BEHIND"
    end
    return if right >= 0 then "RIGHT" else "LEFT"
end

function PlayerSurvivalService.snapshot(self: PlayerSurvivalService, viewer: Player): any
    local now = workspace:GetServerTimeNow()
    local state = self._states[viewer]
    local selfSnapshot = if state == nil
        then self._survivalState.snapshot(self._survivalState.create(now), now)
        else self._survivalState.snapshot(state, now)
    local viewerRoot = rootPart(viewer)

    local downedCount = 0
    local priorityAlly = nil
    local priorityTime = math.huge
    local priorityDistance = math.huge
    for player, candidateState in self._states do
        if player ~= viewer and candidateState.status == "downed" then
            downedCount += 1
            local candidateRoot = rootPart(player)
            local timeRemaining = self._survivalState.snapshot(candidateState, now).timeRemaining
            local distance = if viewerRoot == nil or candidateRoot == nil
                then math.huge
                else (viewerRoot.Position - candidateRoot.Position).Magnitude
            if
                timeRemaining < priorityTime
                or (timeRemaining == priorityTime and distance < priorityDistance)
            then
                priorityAlly = player
                priorityTime = timeRemaining
                priorityDistance = distance
            end
        end
    end

    local ally = nil
    if priorityAlly ~= nil then
        local allyState = self._states[priorityAlly]
        local allyRoot = rootPart(priorityAlly)
        local channel = self._channels[priorityAlly]
        ally = {
            bleedoutAt = allyState.bleedoutAt,
            direction = if viewerRoot == nil or allyRoot == nil
                then "UNKNOWN"
                else directionLabel(viewerRoot, allyRoot),
            distance = if priorityDistance == math.huge
                then nil
                else math.floor(priorityDistance + 0.5),
            displayName = playerLabel(priorityAlly),
            inReviveRange = priorityDistance <= self._config.ReviveDistance,
            reviveEndsAt = if channel == nil then nil else channel.flow.endsAt,
            userId = priorityAlly.UserId,
        }
    end

    local nearestActive = nil
    local nearestActiveDistance = math.huge
    if selfSnapshot.downed and viewerRoot ~= nil then
        for player, candidateState in self._states do
            if player ~= viewer and self._survivalState.canAct(candidateState) then
                local candidateRoot = rootPart(player)
                if candidateRoot ~= nil then
                    local distance = (viewerRoot.Position - candidateRoot.Position).Magnitude
                    if distance < nearestActiveDistance then
                        nearestActive = player
                        nearestActiveDistance = distance
                    end
                end
            end
        end
    end

    local nearestAlly = nil
    if nearestActive ~= nil then
        local nearestRoot = rootPart(nearestActive)
        nearestAlly = {
            direction = if nearestRoot == nil
                then "UNKNOWN"
                else directionLabel(viewerRoot :: BasePart, nearestRoot),
            distance = math.floor(nearestActiveDistance + 0.5),
            displayName = playerLabel(nearestActive),
        }
    end

    selfSnapshot.nearestAlly = nearestAlly
    selfSnapshot.reviveEndsAt = viewer:GetAttribute("LastLightReviveEndsAt")
    return {
        ally = ally,
        downedCount = downedCount,
        enabled = self._featureFlags:isEnabled("player_survival_enabled"),
        self = selfSnapshot,
    }
end

return table.freeze(PlayerSurvivalService)
