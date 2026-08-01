--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local EnemyService = {}
EnemyService.__index = EnemyService
EnemyService.Name = "EnemyService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

type AttackVisual = {
    label: TextLabel,
    marker: Part,
}

type Attack = {
    areaCFrame: CFrame,
    flow: any,
    target: Player,
    visual: AttackVisual,
}

type Enemy = {
    attack: Attack?,
    basePosition: Vector3,
    definition: any,
    facingPosition: Vector3,
    health: number,
    lastAttackAt: number,
    markedUntil: number,
    model: Model,
    spawnedAt: number,
}

export type EnemyService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _worldService: any,
        _survivalService: any,
        _combatService: any,
        _enemyAttackFlow: any,
        _enemyCatalog: any,
        _enemyCombatRules: any,
        _enemyMotion: any,
        _enemyBuilder: any,
        _analyticsService: any,
        _professionService: any,
        _eliteService: any,
        _bossService: any,
        _active: Enemy?,
        _queue: { string },
        _nextSpawnAt: number,
        _nightActive: boolean,
        _lanternHealth: number,
        _breachMultiplier: number,
        _onChanged: ((string?) -> ())?,
        _heartbeat: RBXScriptConnection?,
    },
    EnemyService
))

local function rootPart(player: Player): BasePart?
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    return if root ~= nil and root:IsA("BasePart") then root else nil
end

function EnemyService.new(
    logger: Logger,
    config: any,
    worldService: any,
    survivalService: any,
    combatService: any,
    enemyAttackFlow: any,
    enemyCatalog: any,
    enemyCombatRules: any,
    enemyMotion: any,
    enemyBuilder: any,
    analyticsService: any
): EnemyService
    return setmetatable({
        Name = EnemyService.Name,
        _logger = logger,
        _config = config,
        _worldService = worldService,
        _survivalService = survivalService,
        _combatService = combatService,
        _enemyAttackFlow = enemyAttackFlow,
        _enemyCatalog = enemyCatalog,
        _enemyCombatRules = enemyCombatRules,
        _enemyMotion = enemyMotion,
        _enemyBuilder = enemyBuilder,
        _analyticsService = analyticsService,
        _professionService = nil,
        _eliteService = nil,
        _bossService = nil,
        _active = nil,
        _queue = {},
        _nextSpawnAt = 0,
        _nightActive = false,
        _lanternHealth = 100,
        _breachMultiplier = 1,
        _onChanged = nil,
        _heartbeat = nil,
    }, EnemyService)
end

function EnemyService.Init(_self: EnemyService, _context: any) end

function EnemyService.Start(self: EnemyService)
    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.05 then
            return
        end
        local elapsed = accumulator
        accumulator = 0
        self:_step(elapsed)
    end)
end

function EnemyService.setChangedHandler(self: EnemyService, callback: (string?) -> ())
    self._onChanged = callback
end

function EnemyService.setProfessionService(self: EnemyService, professionService: any)
    self._professionService = professionService
end

function EnemyService.setEliteService(self: EnemyService, eliteService: any)
    self._eliteService = eliteService
end

function EnemyService.setBossService(self: EnemyService, bossService: any)
    self._bossService = bossService
end

function EnemyService._activeEncounterService(self: EnemyService): any
    if self._bossService ~= nil and self._bossService:combatActive() then
        return self._bossService
    end
    if self._eliteService ~= nil and self._eliteService:combatActive() then
        return self._eliteService
    end
    return nil
end

function EnemyService._notify(self: EnemyService, toast: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(toast)
    end
end

function EnemyService._poseEnemy(
    self: EnemyService,
    enemy: Enemy,
    now: number,
    motionState: string,
    attackProgress: number?
)
    if enemy.model.Parent == nil then
        return
    end
    local pose = self._enemyMotion.pose(
        math.max(0, now - enemy.spawnedAt),
        enemy.definition.modelKey,
        motionState,
        attackProgress
    )
    local position = enemy.basePosition + Vector3.new(0, pose.height, 0)
    local flatFacing = Vector3.new(enemy.facingPosition.X, position.Y, enemy.facingPosition.Z)
    if (flatFacing - position).Magnitude <= 0.01 then
        flatFacing = position + Vector3.new(0, 0, -1)
    end
    enemy.model:PivotTo(
        CFrame.lookAt(position, flatFacing) * CFrame.Angles(pose.pitch, 0, pose.roll)
    )
end

function EnemyService._showSpawnPulse(_self: EnemyService, position: Vector3, color: Color3)
    local pulse = Instance.new("Part")
    pulse.Name = "BramblewakeSpawnPulse"
    pulse.Anchored = true
    pulse.CanCollide = false
    pulse.CanQuery = false
    pulse.CanTouch = false
    pulse.CastShadow = false
    pulse.Shape = Enum.PartType.Cylinder
    pulse.Material = Enum.Material.Neon
    pulse.Color = color
    pulse.Transparency = 0.18
    pulse.Size = Vector3.new(0.16, 4, 4)
    pulse.CFrame = CFrame.new(position + Vector3.new(0, 0.12, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    pulse.Parent = workspace

    local tween = TweenService:Create(
        pulse,
        TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.16, 18, 18),
            Transparency = 1,
        }
    )
    tween:Play()
    task.delay(0.95, function()
        if pulse.Parent ~= nil then
            pulse:Destroy()
        end
    end)
end

function EnemyService._showDamageFeedback(
    self: EnemyService,
    enemy: Enemy,
    damage: number,
    strikeResult: string
)
    local primary = enemy.model.PrimaryPart
    if primary == nil then
        return
    end

    local revision = (tonumber(enemy.model:GetAttribute("HitRevision")) or 0) + 1
    enemy.model:SetAttribute("HitRevision", revision)
    local highlight = enemy.model:FindFirstChild("ThreatOutline")
    if highlight ~= nil and highlight:IsA("Highlight") then
        highlight.FillColor = Color3.fromRGB(255, 238, 188)
        highlight.FillTransparency = 0.18
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        task.delay(0.13, function()
            if
                enemy.model.Parent ~= nil
                and enemy.model:GetAttribute("HitRevision") == revision
            then
                self:_setMarkedVisual(enemy, workspace:GetServerTimeNow() < enemy.markedUntil)
            end
        end)
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamageFeedback"
    billboard.Adornee = primary
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 95
    billboard.Size = UDim2.fromOffset(130, 48)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0)
    billboard.Parent = primary

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBlack
    label.Text = if strikeResult == "flanked"
        then string.format("FLANK  -%d", damage)
        elseif strikeResult == "shielded" then string.format("BLOCK  -%d", damage)
        else string.format("-%d", damage)
    label.TextColor3 = if strikeResult == "flanked"
        then Color3.fromRGB(255, 213, 105)
        elseif strikeResult == "shielded" then Color3.fromRGB(169, 201, 188)
        else Color3.fromRGB(255, 238, 205)
    label.TextScaled = true
    label.TextStrokeColor3 = Color3.fromRGB(31, 25, 22)
    label.TextStrokeTransparency = 0.2
    label.Parent = billboard

    TweenService:Create(
        billboard,
        TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { StudsOffsetWorldSpace = Vector3.new(0, 7.2, 0) }
    ):Play()
    TweenService:Create(
        label,
        TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { TextTransparency = 1, TextStrokeTransparency = 1 }
    ):Play()
    task.delay(0.62, function()
        if billboard.Parent ~= nil then
            billboard:Destroy()
        end
    end)
end

function EnemyService._defeatActive(self: EnemyService, enemy: Enemy)
    self:_clearAttack(enemy)
    if self._active == enemy then
        self._active = nil
    end
    enemy.model:SetAttribute("Defeated", true)
    local pivot = enemy.model:GetPivot().Position
    self:_showSpawnPulse(pivot, Color3.fromRGB(255, 194, 105))

    for _, descendant in enemy.model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
            TweenService
                :Create(
                    descendant,
                    TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {
                        Position = descendant.Position + Vector3.new(0, 1.4, 0),
                        Transparency = 1,
                    }
                )
                :Play()
        end
    end
    task.delay(0.55, function()
        if enemy.model.Parent ~= nil then
            enemy.model:Destroy()
        end
    end)
end

function EnemyService._clearAttack(_self: EnemyService, enemy: Enemy)
    local attack = enemy.attack
    if attack == nil then
        return
    end
    if attack.visual.marker.Parent ~= nil then
        attack.visual.marker:Destroy()
    end
    enemy.attack = nil
end

function EnemyService._destroyActive(self: EnemyService)
    local active = self._active
    if active == nil then
        return
    end
    self:_clearAttack(active)
    if active.model.Parent ~= nil then
        active.model:Destroy()
    end
    self._active = nil
end

function EnemyService.startNight(self: EnemyService)
    self:_destroyActive()
    table.clear(self._queue)
    self._nightActive = true
    self._lanternHealth = 100
    self._worldService:setLanternHealth(self._lanternHealth)
    self._breachMultiplier = 1
    self._nextSpawnAt = 0
    self:_notify(nil)
end

function EnemyService.stopNight(self: EnemyService)
    self._nightActive = false
    self:_destroyActive()
    table.clear(self._queue)
    self._lanternHealth = 100
    self._worldService:setLanternHealth(self._lanternHealth)
    self._breachMultiplier = 1
    self._nextSpawnAt = 0
    self:_notify(nil)
end

function EnemyService._spawnPosition(self: EnemyService, definition: any): Vector3
    local origin = self._worldService:enemySpawnPosition()
    if definition.stationary ~= true then
        return origin
    end
    local lantern = self._worldService:lanternPosition()
    local flatDelta = Vector3.new(lantern.X - origin.X, 0, lantern.Z - origin.Z)
    if flatDelta.Magnitude <= 1 then
        return origin
    end
    return origin + flatDelta.Unit * math.min(34, flatDelta.Magnitude * 0.45)
end

function EnemyService._spawnNow(self: EnemyService, enemyId: string): boolean
    if not self._nightActive or self._active ~= nil then
        return false
    end
    local definition = self._enemyCatalog.get(enemyId)
    if definition == nil then
        self._logger:info("enemy_spawn_rejected", { enemy = enemyId, reason = "unknown_enemy" })
        return false
    end

    local origin = self:_spawnPosition(definition)
    self:_showSpawnPulse(
        origin,
        if definition.statusEffect == "spark_theft"
            then Color3.fromRGB(103, 191, 175)
            else Color3.fromRGB(255, 119, 79)
    )
    local model = self._enemyBuilder.build(
        definition,
        origin,
        if definition.targetMode == "player"
            then origin + Vector3.new(0, 0, -10)
            else self._worldService:lanternPosition()
    )
    model.Parent = workspace
    local spawnedAt = workspace:GetServerTimeNow()
    local basePosition = model:GetPivot().Position
    self._active = {
        attack = nil,
        basePosition = basePosition,
        definition = definition,
        facingPosition = if definition.targetMode == "player"
            then basePosition + Vector3.new(0, 0, -10)
            else self._worldService:lanternPosition(),
        health = definition.health,
        lastAttackAt = spawnedAt,
        markedUntil = 0,
        model = model,
        spawnedAt = spawnedAt,
    }
    self._logger:info("bramblewake_enemy_spawned", {
        enemy = definition.id,
        queued = #self._queue,
    })
    self:_notify(string.upper(definition.displayName) .. " ENTERS THE TRAIL")
    return true
end

function EnemyService.spawn(self: EnemyService, enemyId: string?): boolean
    if not self._nightActive then
        return false
    end
    local resolvedId = enemyId or "enemy_rootling"
    if self._enemyCatalog.get(resolvedId) == nil then
        self._logger:info("enemy_spawn_rejected", {
            enemy = resolvedId,
            reason = "unknown_enemy",
        })
        return false
    end
    if self._active ~= nil or workspace:GetServerTimeNow() < self._nextSpawnAt then
        table.insert(self._queue, resolvedId)
        self._logger:info("bramblewake_enemy_queued", {
            enemy = resolvedId,
            position = #self._queue,
        })
        return true
    end
    return self:_spawnNow(resolvedId)
end

function EnemyService._spawnNext(self: EnemyService, now: number)
    if
        not self._nightActive
        or self._active ~= nil
        or #self._queue == 0
        or now < self._nextSpawnAt
    then
        return
    end
    local enemyId = table.remove(self._queue, 1)
    if enemyId ~= nil then
        self:_spawnNow(enemyId)
    end
end

function EnemyService._attackGroundPosition(
    _self: EnemyService,
    enemy: Enemy,
    root: BasePart
): Vector3
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { enemy.model, root.Parent :: Model }
    local result =
        workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), params)
    return if result == nil
        then root.Position - Vector3.new(0, 2.8, 0)
        else result.Position + Vector3.new(0, 0.12, 0)
end

function EnemyService._attackArea(self: EnemyService, enemy: Enemy, root: BasePart): CFrame
    local definition = enemy.definition
    local ground = self:_attackGroundPosition(enemy, root)
    if definition.shape == "circle" or enemy.model.PrimaryPart == nil then
        return CFrame.new(ground)
    end

    local origin = enemy.model.PrimaryPart.Position
    local flatDirection = Vector3.new(root.Position.X - origin.X, 0, root.Position.Z - origin.Z)
    if flatDirection.Magnitude < 0.01 then
        flatDirection = Vector3.new(
            enemy.model.PrimaryPart.CFrame.LookVector.X,
            0,
            enemy.model.PrimaryPart.CFrame.LookVector.Z
        )
    end
    flatDirection = flatDirection.Unit
    local length = definition.length or 0
    local center = Vector3.new(origin.X, ground.Y, origin.Z) + flatDirection * length * 0.5
    return CFrame.lookAt(center, center + flatDirection)
end

function EnemyService._createAttackVisual(
    _self: EnemyService,
    definition: any,
    areaCFrame: CFrame
): AttackVisual
    local marker = Instance.new("Part")
    marker.Name = definition.modelKey .. "AttackWarning"
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanQuery = false
    marker.CanTouch = false
    marker.CastShadow = false
    marker.Color = if definition.statusEffect == "drowsy"
        then Color3.fromRGB(218, 184, 86)
        elseif definition.statusEffect == "spark_theft" then Color3.fromRGB(103, 191, 175)
        else Color3.fromRGB(255, 119, 79)
    marker.Material = Enum.Material.Neon
    marker.Transparency = 0.52
    if definition.shape == "lane" then
        marker.Size = Vector3.new(definition.width or 0, 0.18, definition.length or 0)
        marker.CFrame = areaCFrame
    else
        local diameter = (definition.radius or 0) * 2
        marker.Shape = Enum.PartType.Cylinder
        marker.Size = Vector3.new(0.18, diameter, diameter)
        marker.CFrame = areaCFrame * CFrame.Angles(0, 0, math.rad(90))
    end
    marker.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AttackLabel"
    billboard.Adornee = marker
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 110
    billboard.Size = UDim2.fromOffset(250, 66)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    billboard.Parent = marker

    local label = Instance.new("TextLabel")
    label.Name = "Warning"
    label.BackgroundColor3 = Color3.fromRGB(39, 25, 22)
    label.BackgroundTransparency = 0.08
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.Size = UDim2.fromScale(1, 1)
    label.Text = definition.attackName .. "\n" .. definition.instruction
    label.TextColor3 = Color3.fromRGB(255, 236, 205)
    label.TextScaled = true
    label.TextStrokeTransparency = 0.72
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

function EnemyService._startAttack(self: EnemyService, enemy: Enemy, target: Player, now: number)
    local root = rootPart(target)
    if root == nil then
        return
    end
    local areaCFrame = self:_attackArea(enemy, root)
    enemy.facingPosition = root.Position
    enemy.attack = {
        areaCFrame = areaCFrame,
        flow = self._enemyAttackFlow.create(target.UserId, now, enemy.definition.windup),
        target = target,
        visual = self:_createAttackVisual(enemy.definition, areaCFrame),
    }
    enemy.lastAttackAt = now
    self._logger:info("enemy_attack_telegraphed", {
        attack = enemy.definition.attackId,
        enemy = enemy.definition.id,
        player = target.UserId,
        shape = enemy.definition.shape,
        windup = enemy.definition.windup,
    })
    self:_notify(nil)
end

function EnemyService._clearPath(_self: EnemyService, enemy: Enemy, target: Player): boolean
    local character = target.Character
    local root = rootPart(target)
    local origin = enemy.model.PrimaryPart
    if root == nil or origin == nil or character == nil then
        return false
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { enemy.model }
    local result = workspace:Raycast(origin.Position, root.Position - origin.Position, params)
    return result == nil or result.Instance:IsDescendantOf(character)
end

function EnemyService._insideAttack(
    self: EnemyService,
    enemy: Enemy,
    attack: Attack,
    root: BasePart
): boolean
    local localPosition = attack.areaCFrame:PointToObjectSpace(root.Position)
    return self._enemyCombatRules.contains(
        enemy.definition.shape,
        localPosition.X,
        localPosition.Z,
        enemy.definition.radius,
        enemy.definition.width,
        enemy.definition.length
    )
end

function EnemyService._stepAttack(self: EnemyService, enemy: Enemy, now: number)
    local attack = enemy.attack
    if attack == nil then
        return
    end
    local root = rootPart(attack.target)
    if root ~= nil then
        enemy.facingPosition = root.Position
    end
    local attackDuration = math.max(0.01, attack.flow.endsAt - attack.flow.startedAt)
    self:_poseEnemy(
        enemy,
        now,
        "attacking",
        math.clamp((now - attack.flow.startedAt) / attackDuration, 0, 1)
    )
    local resolving = now >= attack.flow.endsAt
    local decision = self._enemyAttackFlow.evaluate(attack.flow, now, {
        clearPath = not resolving or self:_clearPath(enemy, attack.target),
        inImpactArea = not resolving or (root ~= nil and self:_insideAttack(enemy, attack, root)),
        targetCanAct = self._survivalService:canAct(attack.target),
        targetPresent = attack.target.Parent ~= nil and root ~= nil,
    })
    if decision.status == "pending" then
        attack.visual.label.Text = string.format(
            "%s\n%s · %.1fs",
            enemy.definition.attackName,
            enemy.definition.instruction,
            math.max(0, decision.remaining or 0)
        )
        return
    end

    local target = attack.target
    local enemyId = enemy.definition.id
    self:_clearAttack(enemy)
    if decision.status == "cancel" then
        self._analyticsService:enemyAttackResult(target, decision.reason or "cancelled", enemyId)
        self:_notify(nil)
        return
    end
    if decision.status == "miss" then
        self._analyticsService:enemyAttackResult(target, decision.reason or "missed", enemyId)
        self:_notify(nil)
        return
    end
    if self._combatService:avoidsDamage(target, now) then
        self._analyticsService:enemyAttackResult(target, "dodged", enemyId)
        self:_notify(nil)
        return
    end

    local damage = enemy.definition.playerDamage
    local guarded = false
    if self._professionService ~= nil then
        damage, guarded = self._professionService:mitigateIncomingDamage(target, damage, now)
    end
    damage = self._combatService:mitigateShieldedDamage(target, damage, now)
    local result = self._survivalService:damage(target, damage, enemyId)
    if result.applied and enemy.definition.statusEffect == "drowsy" then
        self._combatService:applyDrowsy(
            target,
            enemy.definition.statusDuration or 0,
            enemy.definition.statusMultiplier or 1
        )
    elseif result.applied and enemy.definition.statusEffect == "spark_theft" then
        self._lanternHealth =
            math.max(18, self._lanternHealth - (enemy.definition.statusLanternDamage or 0))
        self._worldService:setLanternHealth(self._lanternHealth)
    end
    self._analyticsService:enemyAttackResult(
        target,
        if result.applied then (if guarded then "guarded_hit" else "hit") else "blocked",
        enemyId
    )
    if result.downed then
        self:_notify("ALLY DOWN — " .. enemy.definition.attackName)
    elseif guarded and result.applied then
        self:_notify("LANTERN GUARD ABSORBS " .. enemy.definition.attackName)
    elseif result.applied and enemy.definition.statusEffect == "spark_theft" then
        self:_notify("HOLLOW CROW STOLE AN EXPOSED LANTERN SPARK")
    else
        self:_notify(nil)
    end
end

function EnemyService._setMarkedVisual(_self: EnemyService, enemy: Enemy, marked: boolean)
    enemy.model:SetAttribute("LastLightMarked", marked)
    local highlight = enemy.model:FindFirstChild("ThreatOutline")
    if highlight ~= nil and highlight:IsA("Highlight") then
        highlight.FillColor = if marked
            then Color3.fromRGB(41, 91, 74)
            else Color3.fromRGB(80, 29, 29)
        highlight.FillTransparency = if marked then 0.52 else 0.76
        highlight.OutlineColor = if marked
            then Color3.fromRGB(255, 210, 96)
            else Color3.fromRGB(255, 143, 91)
    end
end

function EnemyService._closestPlayer(self: EnemyService, enemy: Enemy): (Player?, number)
    local closestPlayer = nil
    local closestDistance = math.huge
    local primary = enemy.model.PrimaryPart
    if primary == nil then
        return nil, closestDistance
    end
    for _, player in Players:GetPlayers() do
        local root = rootPart(player)
        if
            root ~= nil
            and self._survivalService:canAct(player)
            and player:GetAttribute("LastLightTutorialSurvivalReady") == true
            and player:GetAttribute("LastLightInExpedition") ~= true
        then
            local distance = (root.Position - primary.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    return closestPlayer, closestDistance
end

function EnemyService._lanternImpact(self: EnemyService, enemy: Enemy, now: number)
    if now - enemy.lastAttackAt < enemy.definition.attackCooldown then
        return
    end
    enemy.lastAttackAt = now
    self._lanternHealth =
        math.max(0, self._lanternHealth - math.max(0, enemy.definition.lanternDamage))
    if self._lanternHealth <= 0 then
        self._lanternHealth = 18
        local collapsedId = enemy.definition.id
        self:_destroyActive()
        self._nextSpawnAt = now + 2
        self._logger:info("lantern_emergency_restore", { enemy = collapsedId })
        self:_notify("THE LIGHT FLICKERS — MARA RESTORES A SPARK")
    else
        self:_notify(nil)
    end
    self._worldService:setLanternHealth(self._lanternHealth)
end

function EnemyService._step(self: EnemyService, deltaTime: number)
    if not self._nightActive then
        return
    end
    local now = workspace:GetServerTimeNow()
    local enemy = self._active
    if enemy == nil then
        self:_spawnNext(now)
        return
    end
    if enemy.model.Parent == nil then
        self:_clearAttack(enemy)
        self._active = nil
        self._nextSpawnAt = now + 1
        self:_notify(nil)
        return
    end

    if enemy.markedUntil > 0 and now >= enemy.markedUntil then
        enemy.markedUntil = 0
        self:_setMarkedVisual(enemy, false)
        self:_notify(nil)
    end
    if enemy.attack ~= nil then
        self:_stepAttack(enemy, now)
        return
    end

    local closestPlayer, closestDistance = self:_closestPlayer(enemy)
    if
        closestPlayer ~= nil
        and closestDistance <= enemy.definition.attackRange
        and now - enemy.lastAttackAt >= enemy.definition.attackCooldown
    then
        self:_startAttack(enemy, closestPlayer, now)
        return
    end
    if enemy.definition.stationary then
        self:_poseEnemy(enemy, now, "idle", nil)
        return
    end

    local destination = self._worldService:lanternPosition()
    if enemy.definition.targetMode == "player" and closestPlayer ~= nil then
        local targetRoot = rootPart(closestPlayer)
        if targetRoot ~= nil then
            destination = targetRoot.Position
        end
    end
    local flatTarget = Vector3.new(destination.X, enemy.basePosition.Y, destination.Z)
    local delta = flatTarget - enemy.basePosition
    local stoppingDistance = if enemy.definition.targetMode == "player"
        then enemy.definition.attackRange * 0.72
        else 10
    if delta.Magnitude > stoppingDistance then
        local speed = enemy.definition.speed * self._breachMultiplier
        if now < enemy.markedUntil then
            speed *= 0.65
        end
        local distance = math.min(delta.Magnitude - stoppingDistance, speed * deltaTime)
        if distance > 0 then
            enemy.basePosition += delta.Unit * distance
            enemy.facingPosition = flatTarget
            self:_poseEnemy(enemy, now, "moving", nil)
        end
        return
    end

    enemy.facingPosition = flatTarget
    self:_poseEnemy(enemy, now, "idle", nil)

    if enemy.definition.targetMode == "lantern" then
        self:_lanternImpact(enemy, now)
    end
end

function EnemyService._enemyInRange(
    self: EnemyService,
    player: Player,
    range: number
): (Enemy?, string?)
    if not self._nightActive then
        return nil, "NO NIGHT THREAT IS ACTIVE IN DAYLIGHT"
    end
    if not self._survivalService:canAct(player) then
        return nil, "YOU CANNOT TRACK WHILE DOWNED"
    end
    local enemy = self._active
    local root = rootPart(player)
    if enemy == nil or root == nil or enemy.model.PrimaryPart == nil then
        return nil, "NO THREAT CAN BE MARKED"
    end
    if (root.Position - enemy.model.PrimaryPart.Position).Magnitude > range then
        return nil, "MOVE CLOSER TO MARK THE THREAT"
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { player.Character :: Model }
    local result =
        workspace:Raycast(root.Position, enemy.model.PrimaryPart.Position - root.Position, params)
    if result ~= nil and not result.Instance:IsDescendantOf(enemy.model) then
        return nil, "THE THREAT IS HIDDEN BEHIND COVER"
    end
    return enemy, nil
end

function EnemyService.canMarkNearest(
    self: EnemyService,
    player: Player,
    range: number
): (boolean, string)
    -- Checked before (not instead of) the town-night branch below: a normal
    -- town night and an active Old Growth/Warden Stag encounter can now run
    -- concurrently (the town cycle repeats independently of Bramblewake), so
    -- _nightActive can no longer be used to infer "no encounter is active."
    local encounterService = self:_activeEncounterService()
    if encounterService ~= nil then
        return encounterService:canMarkNearest(player, range)
    end
    local enemy, reason = self:_enemyInRange(player, range)
    if enemy == nil then
        return false, reason or "NO THREAT CAN BE MARKED"
    end
    return true, "FOXFIRE MARK READY"
end

function EnemyService.markNearest(
    self: EnemyService,
    player: Player,
    range: number,
    duration: number
): (boolean, string)
    local encounterService = self:_activeEncounterService()
    if encounterService ~= nil then
        return encounterService:markNearest(player, range, duration)
    end
    local enemy, reason = self:_enemyInRange(player, range)
    if enemy == nil then
        return false, reason or "NO THREAT CAN BE MARKED"
    end
    enemy.markedUntil = workspace:GetServerTimeNow() + duration
    self:_setMarkedVisual(enemy, true)
    local message = "FOXFIRE MARK — "
        .. string.upper(enemy.definition.displayName)
        .. " REVEALED AND SLOWED"
    self:_notify(message)
    return true, message
end

function EnemyService.canRepairLantern(
    self: EnemyService,
    player: Player,
    range: number
): (boolean, string)
    if not self._nightActive then
        return false, "THE FIRST LANTERN DOES NOT NEED A NIGHT REPAIR"
    end
    if not self._survivalService:canAct(player) then
        return false, "YOU CANNOT REPAIR WHILE DOWNED"
    end
    if self._lanternHealth >= 100 then
        return false, "THE FIRST LANTERN IS ALREADY AT FULL STRENGTH"
    end
    local root = rootPart(player)
    if root == nil or (root.Position - self._worldService:lanternPosition()).Magnitude > range then
        return false, "MOVE CLOSER TO THE FIRST LANTERN"
    end
    return true, "EMERGENCY PATCH READY"
end

function EnemyService.repairLantern(
    self: EnemyService,
    player: Player,
    range: number,
    amount: number
): (boolean, string)
    local allowed, reason = self:canRepairLantern(player, range)
    if not allowed then
        return false, reason
    end
    local previous = self._lanternHealth
    self._lanternHealth = math.min(100, self._lanternHealth + amount)
    self._worldService:setLanternHealth(self._lanternHealth)
    local restored = self._lanternHealth - previous
    local message = string.format("EMERGENCY PATCH — FIRST LANTERN +%d", restored)
    self:_notify(message)
    return true, message
end

function EnemyService.damageNearest(self: EnemyService, player: Player): (boolean, string)
    local encounterService = self:_activeEncounterService()
    if encounterService ~= nil then
        return encounterService:damageNearest(player)
    end
    if not self._nightActive then
        return false, "The tool is calm in daylight."
    end
    if not self._survivalService:canAct(player) then
        return false, "You cannot strike while downed."
    end

    local enemy = self._active
    local root = rootPart(player)
    if enemy == nil or root == nil or enemy.model.PrimaryPart == nil then
        return false, "No threat is close enough."
    end
    local displayName = enemy.definition.displayName
    local primary = enemy.model.PrimaryPart
    local distance = (root.Position - primary.Position).Magnitude
    if distance > enemy.definition.strikeRange then
        return false, "Move closer to the " .. displayName .. "."
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { player.Character :: Model }
    local result = workspace:Raycast(root.Position, primary.Position - root.Position, raycastParams)
    if result ~= nil and not result.Instance:IsDescendantOf(enemy.model) then
        return false, "The " .. displayName .. " is behind cover."
    end

    local directionToPlayer = root.Position - primary.Position
    local facingDot = if directionToPlayer.Magnitude > 0.01
        then primary.CFrame.LookVector:Dot(directionToPlayer.Unit)
        else 1
    local damage, strikeResult = self._enemyCombatRules.strikeDamage(enemy.definition, facingDot)
    enemy.health -= damage
    enemy.model:SetAttribute("EnemyHealth", math.max(0, enemy.health))
    self:_showDamageFeedback(enemy, damage, strikeResult)
    if enemy.health <= 0 then
        local defeatedId = enemy.definition.id
        self:_defeatActive(enemy)
        self._nextSpawnAt = workspace:GetServerTimeNow() + 1.25
        self._logger:info("bramblewake_enemy_defeated", {
            enemy = defeatedId,
            player = player.UserId,
            strikeResult = strikeResult,
        })
        self:_notify(string.upper(displayName) .. " DRIVEN BACK")
        return true, displayName .. " driven back!"
    end

    local remaining = tostring(math.max(0, math.ceil(enemy.health)))
    if strikeResult == "shielded" then
        self:_notify("SHIELD BLOCKED MOST OF THE HIT — FLANK THE BRIARBACK")
        return true, "The front shield absorbs most of the strike. Flank it."
    elseif strikeResult == "flanked" then
        self:_notify("FLANK HIT — " .. string.upper(displayName) .. " " .. remaining)
        return true, "Clean flank hit."
    end
    self:_notify("HIT — " .. string.upper(displayName) .. " " .. remaining)
    return true, "Your tool strikes the " .. displayName .. "."
end

function EnemyService.threatSnapshot(self: EnemyService, viewer: Player): any
    local enemy = self._active
    local attack = if enemy == nil then nil else enemy.attack
    if enemy == nil or attack == nil or attack.target ~= viewer then
        local encounterService = self:_activeEncounterService()
        return if encounterService == nil then nil else encounterService:threatSnapshot(viewer)
    end
    return {
        attackId = enemy.definition.attackId,
        displayName = enemy.definition.attackName,
        enemyName = string.upper(enemy.definition.displayName),
        enemyId = enemy.definition.id,
        instruction = enemy.definition.instruction,
        resolvesAt = attack.flow.endsAt,
        shape = enemy.definition.shape,
    }
end

function EnemyService.setBreach(self: EnemyService)
    self._breachMultiplier = 1.35
    self:_notify("THE ROOTS SURGE — HOLD THE LIGHT")
end

function EnemyService.lanternHealth(self: EnemyService): number
    return self._lanternHealth
end

function EnemyService.activeCount(self: EnemyService): number
    return if self._active == nil then 0 else 1
end

function EnemyService.combatActive(self: EnemyService): boolean
    return (self._nightActive and self._active ~= nil) or self:_activeEncounterService() ~= nil
end

return table.freeze(EnemyService)
