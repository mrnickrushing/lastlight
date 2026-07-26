--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local OldGrowthService = {}
OldGrowthService.__index = OldGrowthService
OldGrowthService.Name = "OldGrowthService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

type AttackVisual = {
    label: TextLabel,
    marker: Part,
}

type Attack = {
    areaCFrame: CFrame,
    definition: any,
    flow: any,
    target: Player,
    visual: AttackVisual,
}

export type OldGrowthService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _worldService: any,
        _expeditionService: any,
        _survivalService: any,
        _combatService: any,
        _professionService: any,
        _encounter: any,
        _enemyAttackFlow: any,
        _enemyCombatRules: any,
        _builder: any,
        _analyticsService: any,
        _featureFlags: any,
        _state: any,
        _arena: any,
        _model: Model?,
        _attack: Attack?,
        _attackIndex: number,
        _lastAttackAt: number,
        _markedUntil: number,
        _onChanged: ((string?) -> ())?,
        _heartbeat: RBXScriptConnection?,
    },
    OldGrowthService
))

local ACTIVATION_RADIUS = 28
local ENCOUNTER_RADIUS = 58
local STRIKE_RANGE = 14

local function rootPart(player: Player): BasePart?
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    return if root ~= nil and root:IsA("BasePart") then root else nil
end

function OldGrowthService.new(
    logger: Logger,
    worldService: any,
    expeditionService: any,
    survivalService: any,
    combatService: any,
    professionService: any,
    encounter: any,
    enemyAttackFlow: any,
    enemyCombatRules: any,
    builder: any,
    analyticsService: any,
    featureFlags: any
): OldGrowthService
    return setmetatable({
        Name = OldGrowthService.Name,
        _logger = logger,
        _worldService = worldService,
        _expeditionService = expeditionService,
        _survivalService = survivalService,
        _combatService = combatService,
        _professionService = professionService,
        _encounter = encounter,
        _enemyAttackFlow = enemyAttackFlow,
        _enemyCombatRules = enemyCombatRules,
        _builder = builder,
        _analyticsService = analyticsService,
        _featureFlags = featureFlags,
        _state = nil,
        _arena = nil,
        _model = nil,
        _attack = nil,
        _attackIndex = 0,
        _lastAttackAt = 0,
        _markedUntil = 0,
        _onChanged = nil,
        _heartbeat = nil,
    }, OldGrowthService)
end

function OldGrowthService.Init(self: OldGrowthService, _context: any)
    local manifest = assert(self._expeditionService:manifest(), "expedition manifest unavailable")
    self._arena = assert(self._worldService:oldGrowthArena(), "Old Growth arena unavailable")
    self._state = self._encounter.create(
        self._expeditionService:runId(),
        manifest.hash,
        self._featureFlags:isEnabled("old_growth_elite_enabled")
    )
    self._worldService:setOldGrowthPresentation(self._state.status)
end

function OldGrowthService.Start(self: OldGrowthService)
    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.05 then
            return
        end
        accumulator = 0
        self:_step(workspace:GetServerTimeNow())
    end)
    self._logger:info("old_growth_ready", {
        enabled = self._state.status ~= "disabled",
        elite = self._encounter.Id,
        manifest = self._state.manifestHash,
    })
end

function OldGrowthService.setChangedHandler(self: OldGrowthService, callback: (string?) -> ())
    self._onChanged = callback
end

function OldGrowthService._notify(self: OldGrowthService, toast: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(toast)
    end
end

function OldGrowthService._inArena(self: OldGrowthService, player: Player, radius: number): boolean
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return false
    end
    local root = rootPart(player)
    return root ~= nil and (root.Position - self._arena.center).Magnitude <= radius
end

function OldGrowthService._spawnModel(self: OldGrowthService, target: Player)
    if self._model ~= nil and self._model.Parent ~= nil then
        return
    end
    local targetRoot = rootPart(target)
    local lookAt = if targetRoot == nil
        then self._arena.center + Vector3.new(0, 0, -10)
        else targetRoot.Position
    local model = self._builder.build(self._arena.center, lookAt, self._encounter.MaxHealth)
    model.Parent =
        assert(self._arena.fireSource.Parent, "Old Growth arena lost its streamed module")
    self._model = model
    self._builder.setState(model, self._state.health, false, false)
end

function OldGrowthService._clearAttack(self: OldGrowthService)
    local attack = self._attack
    if attack == nil then
        return
    end
    if attack.visual.marker.Parent ~= nil then
        attack.visual.marker:Destroy()
    end
    self._attack = nil
end

function OldGrowthService._groundPosition(self: OldGrowthService, targetRoot: BasePart): Vector3
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = { targetRoot.Parent :: Model }
    if self._model ~= nil then
        table.insert(excluded, self._model)
    end
    params.FilterDescendantsInstances = excluded
    local result = workspace:Raycast(
        targetRoot.Position + Vector3.new(0, 3, 0),
        Vector3.new(0, -18, 0),
        params
    )
    return if result == nil
        then targetRoot.Position - Vector3.new(0, 2.8, 0)
        else result.Position + Vector3.new(0, 0.14, 0)
end

function OldGrowthService._attackArea(
    self: OldGrowthService,
    definition: any,
    targetRoot: BasePart
): CFrame
    local ground = self:_groundPosition(targetRoot)
    if definition.shape == "circle" or self._model == nil or self._model.PrimaryPart == nil then
        return CFrame.new(ground)
    end
    local origin = self._model.PrimaryPart.Position
    local direction =
        Vector3.new(targetRoot.Position.X - origin.X, 0, targetRoot.Position.Z - origin.Z)
    if direction.Magnitude < 0.01 then
        direction = Vector3.new(0, 0, -1)
    end
    direction = direction.Unit
    local center = Vector3.new(origin.X, ground.Y, origin.Z) + direction * definition.length * 0.5
    return CFrame.lookAt(center, center + direction)
end

function OldGrowthService._createAttackVisual(
    _self: OldGrowthService,
    definition: any,
    areaCFrame: CFrame
): AttackVisual
    local marker = Instance.new("Part")
    marker.Name = "OldGrowthAttackWarning"
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanQuery = false
    marker.CanTouch = false
    marker.CastShadow = false
    marker.Color = if definition.shape == "lane"
        then Color3.fromRGB(101, 187, 112)
        else Color3.fromRGB(255, 148, 82)
    marker.Material = Enum.Material.Neon
    marker.Transparency = 0.5
    if definition.shape == "lane" then
        marker.Size = Vector3.new(definition.width, 0.2, definition.length)
        marker.CFrame = areaCFrame
    else
        marker.Shape = Enum.PartType.Cylinder
        marker.Size = Vector3.new(0.2, definition.radius * 2, definition.radius * 2)
        marker.CFrame = areaCFrame * CFrame.Angles(0, 0, math.rad(90))
    end
    marker.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OldGrowthAttackLabel"
    billboard.Adornee = marker
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 120
    billboard.Size = UDim2.fromOffset(270, 68)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
    billboard.Parent = marker

    local label = Instance.new("TextLabel")
    label.Name = "Warning"
    label.BackgroundColor3 = Color3.fromRGB(26, 38, 29)
    label.BackgroundTransparency = 0.08
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.Size = UDim2.fromScale(1, 1)
    label.Text = definition.attackName .. "\n" .. definition.instruction
    label.TextColor3 = Color3.fromRGB(248, 233, 198)
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = marker.Color
    stroke.Thickness = 2
    stroke.Transparency = 0.08
    stroke.Parent = label
    return {
        label = label,
        marker = marker,
    }
end

function OldGrowthService._startAttack(self: OldGrowthService, target: Player, now: number)
    local targetRoot = rootPart(target)
    if targetRoot == nil then
        return
    end
    self._attackIndex += 1
    local definition = self._encounter.attack(self._attackIndex, self._state.shieldIndex)
    local areaCFrame = self:_attackArea(definition, targetRoot)
    self._attack = {
        areaCFrame = areaCFrame,
        definition = definition,
        flow = self._enemyAttackFlow.create(target.UserId, now, definition.windup),
        target = target,
        visual = self:_createAttackVisual(definition, areaCFrame),
    }
    self._lastAttackAt = now
    self._analyticsService:eliteAttackTelegraphed(
        target,
        self._encounter.Id,
        definition.attackId,
        definition.shape,
        definition.windup
    )
    self:_notify(nil)
end

function OldGrowthService._clearPath(self: OldGrowthService, target: Player): boolean
    local model = self._model
    local root = rootPart(target)
    local character = target.Character
    if model == nil or model.PrimaryPart == nil or root == nil or character == nil then
        return false
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { model }
    local result = workspace:Raycast(
        model.PrimaryPart.Position,
        root.Position - model.PrimaryPart.Position,
        params
    )
    return result == nil or result.Instance:IsDescendantOf(character)
end

function OldGrowthService._insideAttack(
    self: OldGrowthService,
    attack: Attack,
    targetRoot: BasePart
): boolean
    local localPosition = attack.areaCFrame:PointToObjectSpace(targetRoot.Position)
    return self._enemyCombatRules.contains(
        attack.definition.shape,
        localPosition.X,
        localPosition.Z,
        attack.definition.radius,
        attack.definition.width,
        attack.definition.length
    )
end

function OldGrowthService._stepAttack(self: OldGrowthService, now: number)
    local attack = self._attack
    if attack == nil then
        return
    end
    local targetRoot = rootPart(attack.target)
    local resolving = now >= attack.flow.endsAt
    local decision = self._enemyAttackFlow.evaluate(attack.flow, now, {
        clearPath = not resolving or self:_clearPath(attack.target),
        inImpactArea = not resolving
            or (targetRoot ~= nil and self:_insideAttack(attack, targetRoot)),
        targetCanAct = self._survivalService:canAct(attack.target),
        targetPresent = attack.target.Parent ~= nil and attack.target:GetAttribute(
            "LastLightInExpedition"
        ) == true and targetRoot ~= nil,
    })
    if decision.status == "pending" then
        attack.visual.label.Text = string.format(
            "%s\n%s · %.1fs",
            attack.definition.attackName,
            attack.definition.instruction,
            math.max(0, decision.remaining or 0)
        )
        return
    end

    local target = attack.target
    local definition = attack.definition
    self:_clearAttack()
    if decision.status == "cancel" or decision.status == "miss" then
        self._analyticsService:eliteAttackResult(
            target,
            self._encounter.Id,
            definition.attackId,
            decision.reason or decision.status
        )
        self:_notify(nil)
        return
    end
    if self._combatService:avoidsDamage(target, now) then
        self._analyticsService:eliteAttackResult(
            target,
            self._encounter.Id,
            definition.attackId,
            "dodged"
        )
        self:_notify(nil)
        return
    end

    local damage, guarded =
        self._professionService:mitigateIncomingDamage(target, definition.damage, now)
    local result = self._survivalService:damage(target, damage, self._encounter.Id)
    if result.applied and definition.attackId == "old_growth_root_lane" then
        self._combatService:applyRooted(
            target,
            definition.rootedDuration,
            definition.rootedMultiplier
        )
    end
    self._analyticsService:eliteAttackResult(
        target,
        self._encounter.Id,
        definition.attackId,
        if result.applied then (if guarded then "guarded_hit" else "hit") else "blocked"
    )
    if result.downed then
        self:_notify("ALLY DOWN — " .. definition.attackName)
    elseif guarded and result.applied then
        self:_notify("LANTERN GUARD ABSORBS " .. definition.attackName)
    else
        self:_notify(nil)
    end
end

function OldGrowthService._syncCarrierVisuals(self: OldGrowthService, now: number)
    for _, player in Players:GetPlayers() do
        local snapshot = self._encounter.snapshot(self._state, player.UserId, now)
        player:SetAttribute("LastLightCarryingOldGrowthFire", snapshot.carryingFire)
        player:SetAttribute("LastLightOldGrowthFireExpiresAt", snapshot.fireExpiresAt)
        local root = rootPart(player)
        if root ~= nil then
            local light = root:FindFirstChild("OldGrowthCarryLight")
            if snapshot.carryingFire and light == nil then
                local pointLight = Instance.new("PointLight")
                pointLight.Name = "OldGrowthCarryLight"
                pointLight.Color = Color3.fromRGB(255, 181, 76)
                pointLight.Brightness = 2.2
                pointLight.Range = 18
                pointLight.Shadows = false
                pointLight.Parent = root
            elseif not snapshot.carryingFire and light ~= nil then
                light:Destroy()
            end
        end
    end
end

function OldGrowthService._playersInArena(self: OldGrowthService): { Player }
    local players = {}
    for _, player in Players:GetPlayers() do
        if self:_inArena(player, ENCOUNTER_RADIUS) and self._survivalService:canAct(player) then
            table.insert(players, player)
        end
    end
    return players
end

function OldGrowthService._step(self: OldGrowthService, now: number)
    local previousRevision = self._state.revision
    self._state = self._encounter.expire(self._state, now)
    if self._state.revision ~= previousRevision then
        self:_syncCarrierVisuals(now)
        self:_notify("LANTERN FIRE FADED — TAKE ANOTHER FLAME")
    end

    if self._state.status == "dormant" then
        for _, player in Players:GetPlayers() do
            if
                self:_inArena(player, ACTIVATION_RADIUS) and self._survivalService:canAct(player)
            then
                local nextState, result = self._encounter.activate(self._state, player.UserId)
                if result.accepted then
                    self._state = nextState
                    self:_spawnModel(player)
                    self._lastAttackAt = now
                    self._worldService:setOldGrowthPresentation(self._state.status)
                    self._analyticsService:eliteStarted(
                        player,
                        self._encounter.Id,
                        self._state.manifestHash
                    )
                    self:_notify("OLD GROWTH AWAKENS — STRIKE THE AMBER HEART")
                end
                break
            end
        end
        return
    end
    if self._state.status ~= "vulnerable" and self._state.status ~= "shielded" then
        return
    end

    local players = self:_playersInArena()
    for _, player in players do
        self._state = self._encounter.join(self._state, player.UserId)
    end
    if self._model == nil or self._model.Parent == nil then
        local target = players[1]
        if target ~= nil then
            self:_spawnModel(target)
        end
    end
    if self._markedUntil > 0 and now >= self._markedUntil then
        self._markedUntil = 0
        if self._model ~= nil then
            self._builder.setState(
                self._model,
                self._state.health,
                self._state.status == "shielded",
                false
            )
        end
        self:_notify(nil)
    end
    if self._attack ~= nil then
        self:_stepAttack(now)
        return
    end
    local target = players[1]
    if target == nil then
        return
    end
    local cooldown = if self._state.status == "shielded" then 4.2 else 3
    if now < self._markedUntil then
        cooldown *= 1.35
    end
    if now - self._lastAttackAt >= cooldown then
        self:_startAttack(target, now)
    end
end

function OldGrowthService.interact(
    self: OldGrowthService,
    player: Player,
    prompt: ProximityPrompt
): any
    if not self:_inArena(player, ENCOUNTER_RADIUS) or not self._survivalService:canAct(player) then
        return {
            accepted = false,
            message = "ENTER THE OLD GROWTH ARENA WHILE ACTIVE",
            reason = "player_unavailable",
        }
    end
    local interaction = prompt.Parent:GetAttribute("EliteInteraction")
    local now = workspace:GetServerTimeNow()
    local nextState, result
    if interaction == "fire_source" then
        nextState, result = self._encounter.takeFire(self._state, player.UserId, now)
    elseif interaction == "root_heart" then
        nextState, result = self._encounter.burnHeart(self._state, player.UserId, now)
    else
        return {
            accepted = false,
            message = "THAT ELITE INTERACTION IS INVALID",
            reason = "invalid_interaction",
        }
    end
    if not result.accepted then
        result.message = if result.reason == "fire_required"
            then "TAKE LANTERN FIRE BEFORE TOUCHING THE ROOT HEART"
            elseif result.reason == "fire_claimed" then "AN ALLY ALREADY CARRIES THE FIRE"
            else "THE ROOT SHIELD IS NOT CALLING FOR FIRE"
        return result
    end

    self._state = nextState
    self._worldService:setOldGrowthPresentation(self._state.status)
    self:_syncCarrierVisuals(now)
    if result.reason == "fire_taken" then
        result.message = "LANTERN FIRE HELD — REACH THE ROOT HEART"
        self:_notify(result.message)
    else
        result.message = "ROOT SHIELD BURNED — AMBER HEART EXPOSED"
        if self._model ~= nil then
            self._builder.setState(self._model, self._state.health, false, now < self._markedUntil)
        end
        self._analyticsService:elitePhase(
            player,
            self._encounter.Id,
            self._state.shieldIndex + 1,
            "shield_burned"
        )
        self:_notify(result.message)
    end
    return result
end

function OldGrowthService._lineOfSight(
    _self: OldGrowthService,
    player: Player,
    model: Model
): boolean
    local root = rootPart(player)
    local primary = model.PrimaryPart
    local character = player.Character
    if root == nil or primary == nil or character == nil then
        return false
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    local result = workspace:Raycast(root.Position, primary.Position - root.Position, params)
    return result == nil or result.Instance:IsDescendantOf(model)
end

function OldGrowthService.damageNearest(self: OldGrowthService, player: Player): (boolean, string)
    if self._state.status ~= "vulnerable" and self._state.status ~= "shielded" then
        return false, "No elite threat is active."
    end
    if not self:_inArena(player, ENCOUNTER_RADIUS) or not self._survivalService:canAct(player) then
        return false, "Enter the Old Growth arena to strike."
    end
    local model = self._model
    local root = rootPart(player)
    if model == nil or root == nil or model.PrimaryPart == nil then
        return false, "Old Growth is still taking shape."
    end
    if (root.Position - model.PrimaryPart.Position).Magnitude > STRIKE_RANGE then
        return false, "Move closer to the amber heart."
    end
    if not self:_lineOfSight(player, model) then
        return false, "The amber heart is behind the trunk."
    end

    local amount = if workspace:GetServerTimeNow() < self._markedUntil then 40 else 34
    local nextState, result = self._encounter.strike(self._state, player.UserId, amount)
    if not result.accepted then
        if result.reason == "shielded" then
            return false, "ROOT SHIELD — MOVE LANTERN FIRE TO THE HEART"
        end
        return false, "Old Growth cannot be struck right now."
    end
    self._state = nextState
    self._builder.setState(
        model,
        self._state.health,
        self._state.status == "shielded",
        workspace:GetServerTimeNow() < self._markedUntil
    )
    self._worldService:setOldGrowthPresentation(self._state.status)
    if result.completed then
        self:_clearAttack()
        for participantId in self._state.participants do
            local userId = tonumber(participantId)
            if userId ~= nil then
                self._expeditionService:grantEncounterReward(
                    userId,
                    self._encounter.Id,
                    self._encounter.rewardTransactionId(self._state, userId),
                    self._encounter.Reward
                )
            end
        end
        self:_syncCarrierVisuals(workspace:GetServerTimeNow())
        self._analyticsService:eliteCompleted(
            player,
            self._encounter.Id,
            self._state.manifestHash,
            self._state.shieldIndex,
            self:_participantCount()
        )
        self:_notify("OLD GROWTH CLEANSED — +3 AMBER SAP UNBANKED")
        return true, "Old Growth cleansed. Amber Sap added to the expedition pouch."
    end
    if result.shieldStarted then
        self._analyticsService:elitePhase(
            player,
            self._encounter.Id,
            self._state.shieldIndex,
            "shield_started"
        )
        self:_notify("ROOT SHIELD — TAKE LANTERN FIRE TO THE HEART")
        return true, "A root shield closes around the amber heart."
    end
    self:_notify(
        string.format("HIT — OLD GROWTH %d / %d", self._state.health, self._encounter.MaxHealth)
    )
    return true, "Your tool strikes the amber heart."
end

function OldGrowthService._participantCount(self: OldGrowthService): number
    local count = 0
    for _ in self._state.participants do
        count += 1
    end
    return count
end

function OldGrowthService.canMarkNearest(
    self: OldGrowthService,
    player: Player,
    range: number
): (boolean, string)
    local model = self._model
    local root = rootPart(player)
    if
        not self:combatActive()
        or model == nil
        or model.PrimaryPart == nil
        or root == nil
        or not self:_inArena(player, ENCOUNTER_RADIUS)
    then
        return false, "NO ELITE THREAT CAN BE MARKED"
    end
    if (root.Position - model.PrimaryPart.Position).Magnitude > range then
        return false, "MOVE CLOSER TO MARK OLD GROWTH"
    end
    if not self:_lineOfSight(player, model) then
        return false, "OLD GROWTH IS HIDDEN BY THE TRUNK"
    end
    return true, "FOXFIRE MARK READY"
end

function OldGrowthService.markNearest(
    self: OldGrowthService,
    player: Player,
    range: number,
    duration: number
): (boolean, string)
    local allowed, reason = self:canMarkNearest(player, range)
    if not allowed then
        return false, reason
    end
    self._markedUntil = workspace:GetServerTimeNow() + duration
    if self._model ~= nil then
        self._builder.setState(
            self._model,
            self._state.health,
            self._state.status == "shielded",
            true
        )
    end
    local message = "FOXFIRE MARK — OLD GROWTH TELEGRAPHS SLOWED"
    self:_notify(message)
    return true, message
end

function OldGrowthService.threatSnapshot(self: OldGrowthService, viewer: Player): any
    local attack = self._attack
    if attack == nil or attack.target ~= viewer then
        return nil
    end
    return {
        attackId = attack.definition.attackId,
        displayName = attack.definition.attackName,
        enemyId = self._encounter.Id,
        enemyName = "OLD GROWTH",
        instruction = attack.definition.instruction,
        resolvesAt = attack.flow.endsAt,
        shape = attack.definition.shape,
    }
end

function OldGrowthService.snapshot(self: OldGrowthService, player: Player): any
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return nil
    end
    local snapshot =
        self._encounter.snapshot(self._state, player.UserId, workspace:GetServerTimeNow())
    if not self:_inArena(player, ENCOUNTER_RADIUS + 18) and not snapshot.carryingFire then
        return nil
    end
    return snapshot
end

function OldGrowthService.combatActive(self: OldGrowthService): boolean
    return self._state.status == "vulnerable" or self._state.status == "shielded"
end

return table.freeze(OldGrowthService)
