--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WardenStagService = {}
WardenStagService.__index = WardenStagService
WardenStagService.Name = "WardenStagService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
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

export type WardenStagService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _worldService: any,
        _expeditionService: any,
        _survivalService: any,
        _combatService: any,
        _professionService: any,
        _oldGrowthService: any,
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
        _unlockGate: (() -> boolean)?,
    },
    WardenStagService
))

local ACTIVATION_RADIUS = 27
local ENCOUNTER_RADIUS = 56
local STRIKE_RANGE = 15

local function rootPart(player: Player): BasePart?
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    return if root ~= nil and root:IsA("BasePart") then root else nil
end

local function weakPoint(model: Model): BasePart?
    local heart = model:FindFirstChild("MemoryHeart")
    return if heart ~= nil
            and heart:IsA("BasePart")
            and heart:GetAttribute("WeakPoint") == true
        then heart
        else nil
end

function WardenStagService.new(
    logger: Logger,
    worldService: any,
    expeditionService: any,
    survivalService: any,
    combatService: any,
    professionService: any,
    oldGrowthService: any,
    encounter: any,
    enemyAttackFlow: any,
    enemyCombatRules: any,
    builder: any,
    analyticsService: any,
    featureFlags: any
): WardenStagService
    return setmetatable({
        Name = WardenStagService.Name,
        _logger = logger,
        _worldService = worldService,
        _expeditionService = expeditionService,
        _survivalService = survivalService,
        _combatService = combatService,
        _professionService = professionService,
        _oldGrowthService = oldGrowthService,
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
        _unlockGate = nil,
    }, WardenStagService)
end

function WardenStagService.setUnlockGate(self: WardenStagService, gate: (() -> boolean)?)
    self._unlockGate = gate
end

function WardenStagService.Init(self: WardenStagService, _context: any)
    local manifest = assert(self._expeditionService:manifest(), "expedition manifest unavailable")
    self._arena = assert(self._worldService:wardenStagArena(), "Warden Stag arena unavailable")
    self._state = self._encounter.create(
        self._expeditionService:runId(),
        manifest.hash,
        self._featureFlags:isEnabled("warden_stag_boss_enabled")
    )
    self._worldService:setWardenStagPresentation(self._state)
end

function WardenStagService.Start(self: WardenStagService)
    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.05 then
            return
        end
        accumulator = 0
        self:_step(workspace:GetServerTimeNow())
    end)
    self._logger:info("warden_stag_ready", {
        boss = self._encounter.Id,
        enabled = self._state.status ~= "disabled",
        manifest = self._state.manifestHash,
    })
end

function WardenStagService.setChangedHandler(self: WardenStagService, callback: (string?) -> ())
    self._onChanged = callback
end

function WardenStagService._notify(self: WardenStagService, toast: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(toast)
    end
end

function WardenStagService._inArena(
    self: WardenStagService,
    player: Player,
    radius: number
): boolean
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return false
    end
    local root = rootPart(player)
    return root ~= nil and (root.Position - self._arena.center).Magnitude <= radius
end

function WardenStagService._spawnModel(self: WardenStagService, target: Player)
    if self._model ~= nil and self._model.Parent ~= nil then
        return
    end
    local targetRoot = rootPart(target)
    local lookAt = if targetRoot == nil
        then self._arena.center + Vector3.new(0, 0, -10)
        else targetRoot.Position
    local model = self._builder.build(self._arena.center, lookAt, self._encounter.MaxHealth)
    model.Parent = self._arena.model
    task.spawn(function()
        if model.Parent ~= nil then
            self._worldService:placeEnemyVisual(model, "warden_stag")
        end
    end)
    self._model = model
    self:_syncModel()
end

function WardenStagService._syncModel(self: WardenStagService)
    if self._model == nil then
        return
    end
    self._builder.setState(
        self._model,
        self._state.health,
        self._state.status,
        workspace:GetServerTimeNow() < self._markedUntil,
        self._state.brokenAntlers,
        self._state.outcome
    )
end

function WardenStagService._clearAttack(self: WardenStagService)
    local attack = self._attack
    if attack == nil then
        return
    end
    if attack.visual.marker.Parent ~= nil then
        attack.visual.marker:Destroy()
    end
    self._attack = nil
end

function WardenStagService._groundPosition(self: WardenStagService, targetRoot: BasePart): Vector3
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

function WardenStagService._attackArea(
    self: WardenStagService,
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

function WardenStagService._createAttackVisual(
    self: WardenStagService,
    definition: any,
    areaCFrame: CFrame
): AttackVisual
    local marker = Instance.new("Part")
    marker.Name = "WardenStagAttackWarning"
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanQuery = false
    marker.CanTouch = false
    marker.CastShadow = false
    marker.Color = if definition.shape == "lane"
        then Color3.fromRGB(105, 200, 148)
        else Color3.fromRGB(255, 157, 91)
    marker.Material = Enum.Material.Neon
    marker.Transparency = 0.48
    if definition.shape == "lane" then
        marker.Size = Vector3.new(definition.width, 0.2, definition.length)
        marker.CFrame = areaCFrame
    else
        marker.Shape = Enum.PartType.Cylinder
        marker.Size = Vector3.new(0.2, definition.radius * 2, definition.radius * 2)
        marker.CFrame = areaCFrame * CFrame.Angles(0, 0, math.rad(90))
    end
    marker.Parent = self._arena.model

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WardenStagAttackLabel"
    billboard.Adornee = marker
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 120
    billboard.Size = UDim2.fromOffset(300, 72)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
    billboard.Parent = marker

    local label = Instance.new("TextLabel")
    label.Name = "Warning"
    label.BackgroundColor3 = Color3.fromRGB(23, 36, 29)
    label.BackgroundTransparency = 0.06
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
    local outline = Instance.new("UIStroke")
    outline.Color = marker.Color
    outline.Thickness = 2
    outline.Transparency = 0.08
    outline.Parent = label
    return {
        label = label,
        marker = marker,
    }
end

function WardenStagService._startAttack(self: WardenStagService, target: Player, now: number)
    local targetRoot = rootPart(target)
    if targetRoot == nil then
        return
    end
    self._attackIndex += 1
    local definition = self._encounter.attack(self._attackIndex, self._state.phase)
    local areaCFrame = self:_attackArea(definition, targetRoot)
    self._attack = {
        areaCFrame = areaCFrame,
        definition = definition,
        flow = self._enemyAttackFlow.create(target.UserId, now, definition.windup),
        target = target,
        visual = self:_createAttackVisual(definition, areaCFrame),
    }
    self._lastAttackAt = now
    self._analyticsService:bossAttackTelegraphed(
        target,
        self._encounter.Id,
        definition.attackId,
        definition.shape,
        definition.windup
    )
    self:_notify(nil)
end

function WardenStagService._clearPath(self: WardenStagService, target: Player): boolean
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

function WardenStagService._insideAttack(
    self: WardenStagService,
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

function WardenStagService._stepAttack(self: WardenStagService, now: number)
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
        self._analyticsService:bossAttackResult(
            target,
            self._encounter.Id,
            definition.attackId,
            decision.reason or decision.status
        )
        self:_notify(nil)
        return
    end
    if self._combatService:avoidsDamage(target, now) then
        self._analyticsService:bossAttackResult(
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
    damage = self._combatService:mitigateShieldedDamage(target, damage, now)
    local result = self._survivalService:damage(target, damage, self._encounter.Id)
    if result.applied and definition.rootedDuration ~= nil then
        self._combatService:applyRooted(
            target,
            definition.rootedDuration,
            definition.rootedMultiplier
        )
    end
    self._analyticsService:bossAttackResult(
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

function WardenStagService._playersInArena(self: WardenStagService): { Player }
    local players = {}
    for _, player in Players:GetPlayers() do
        if self:_inArena(player, ENCOUNTER_RADIUS) and self._survivalService:canAct(player) then
            table.insert(players, player)
        end
    end
    return players
end

function WardenStagService._nearestPlayer(self: WardenStagService, players: { Player }): Player?
    local anchor = self._arena.center
    if self._model ~= nil and self._model.PrimaryPart ~= nil then
        anchor = self._model.PrimaryPart.Position
    end
    local nearest: Player? = nil
    local nearestDistance = math.huge
    for _, player in players do
        local root = rootPart(player)
        if root ~= nil then
            local distance = (root.Position - anchor).Magnitude
            if distance < nearestDistance then
                nearest = player
                nearestDistance = distance
            end
        end
    end
    return nearest
end

function WardenStagService._step(self: WardenStagService, now: number)
    if
        self._state.status == "locked"
        and self._oldGrowthService:isComplete()
        and (self._unlockGate == nil or (self._unlockGate :: () -> boolean)())
    then
        local nextState, result = self._encounter.unlock(self._state)
        if result.accepted then
            self._state = nextState
            self._worldService:setWardenStagPresentation(self._state)
            self:_notify("THE WARDEN'S SEAL OPENS BEYOND OLD GROWTH")
        end
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
                    self._worldService:setWardenStagPresentation(self._state)
                    self._analyticsService:bossStarted(
                        player,
                        self._encounter.Id,
                        self._state.manifestHash
                    )
                    self._analyticsService:bossPhase(
                        player,
                        self._encounter.Id,
                        self._state.phase,
                        "cleansing_started",
                        self._state.antlersBroken
                    )
                    self:_notify("WARDEN STAG AWAKENS — CLEANSE THE LIVING ROOTS")
                end
                break
            end
        end
        return
    end
    if not self:combatActive() then
        return
    end

    local players = self:_playersInArena()
    for _, player in players do
        self._state = self._encounter.join(self._state, player.UserId)
    end
    if self._model == nil or self._model.Parent == nil then
        local target = self:_nearestPlayer(players)
        if target ~= nil then
            self:_spawnModel(target)
        end
    end
    if self._markedUntil > 0 and now >= self._markedUntil then
        self._markedUntil = 0
        self:_syncModel()
        self:_notify(nil)
    end
    if self._attack ~= nil then
        self:_stepAttack(now)
        return
    end
    local target = self:_nearestPlayer(players)
    if target == nil then
        return
    end
    local tuning = self._encounter.Tuning
    local cooldown = if self._state.status == "cleansing"
        then tuning.cleansingAttackCooldownSeconds
        else tuning.attackCooldownSeconds
    if now < self._markedUntil then
        cooldown *= tuning.markedAttackCooldownMultiplier
    end
    if now - self._lastAttackAt >= cooldown then
        self:_startAttack(target, now)
    end
end

function WardenStagService.interact(
    self: WardenStagService,
    player: Player,
    prompt: ProximityPrompt
): any
    if not self:_inArena(player, ENCOUNTER_RADIUS) or not self._survivalService:canAct(player) then
        return {
            accepted = false,
            message = "ENTER THE WARDEN'S SEAL WHILE ACTIVE",
            reason = "player_unavailable",
        }
    end
    local target = prompt.Parent
    local interaction = if target == nil then nil else target:GetAttribute("BossInteraction")
    local nextState, result
    if interaction == "cleanse_root" then
        nextState, result = self._encounter.cleanseRoot(
            self._state,
            player.UserId,
            tostring(target:GetAttribute("BossNodeId"))
        )
    elseif interaction == "break_antler" then
        nextState, result = self._encounter.breakAntler(
            self._state,
            player.UserId,
            tostring(target:GetAttribute("BossAntlerId"))
        )
    else
        return {
            accepted = false,
            message = "THAT WARDEN INTERACTION IS INVALID",
            reason = "invalid_interaction",
        }
    end
    if not result.accepted then
        result.message = if result.reason == "already_cleansed"
            then "THAT LIVING ROOT IS ALREADY CLEAN"
            elseif
                result.reason == "antler_already_broken"
                or result.reason == "phase_antler_already_broken"
            then "THAT ANTLER SHORTCUT IS NO LONGER AVAILABLE"
            elseif
                self._state.status == "vulnerable"
            then "THE MEMORY HEART IS EXPOSED — STRIKE NOW"
            else "THE WARDEN IS NOT CALLING FOR THAT CHOICE"
        return result
    end

    self._state = nextState
    self._worldService:setWardenStagPresentation(self._state)
    self:_syncModel()
    if result.reason == "antler_broken" then
        result.message = "ANTLER BROKEN — THE FOREST WILL REMEMBER THIS HARM"
        self._analyticsService:bossPhase(
            player,
            self._encounter.Id,
            self._state.phase,
            "antler_shortcut",
            self._state.antlersBroken
        )
    elseif result.exposed then
        result.message = "LIVING ROOTS CLEANSED — MEMORY HEART EXPOSED"
        self._analyticsService:bossPhase(
            player,
            self._encounter.Id,
            self._state.phase,
            "heart_exposed",
            self._state.antlersBroken
        )
    else
        result.message =
            string.format("LIVING ROOT CLEANSED — %d / %d", result.cleansed, result.required)
    end
    self:_notify(result.message)
    return result
end

function WardenStagService._lineOfSight(
    _self: WardenStagService,
    player: Player,
    model: Model
): boolean
    local root = rootPart(player)
    local heart = weakPoint(model)
    local character = player.Character
    if root == nil or heart == nil or character == nil then
        return false
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    -- Exclude the boss itself for the same reason OldGrowthService does: its
    -- invisible hitbox parts are not cover against its own exposed heart, and
    -- the old first-hit-must-be-the-heart check could never pass once the
    -- visual pass cleared the heart's CanQuery. Only world geometry blocks.
    params.FilterDescendantsInstances = { character, model }
    local result = workspace:Raycast(root.Position, heart.Position - root.Position, params)
    return result == nil
end

function WardenStagService.damageNearest(self: WardenStagService, player: Player): (boolean, string)
    if self._state.status ~= "vulnerable" and self._state.status ~= "cleansing" then
        return false, "No Warden Stag threat is active."
    end
    if self._state.status == "cleansing" then
        return false, "CLEANSE LIVING ROOTS OR ACCEPT THE ANTLER CONSEQUENCE"
    end
    if not self:_inArena(player, ENCOUNTER_RADIUS) or not self._survivalService:canAct(player) then
        return false, "Enter the Warden's Seal to strike."
    end
    local model = self._model
    local root = rootPart(player)
    local heart = if model == nil then nil else weakPoint(model)
    if model == nil or root == nil or heart == nil then
        return false, "The Warden Stag is still taking shape."
    end
    if (root.Position - heart.Position).Magnitude > STRIKE_RANGE then
        return false, "Move closer to the memory heart."
    end
    if not self:_lineOfSight(player, model) then
        return false, "The memory heart is hidden behind the Warden."
    end

    local tuning = self._encounter.Tuning
    local amount = if workspace:GetServerTimeNow() < self._markedUntil
        then tuning.markedStrikeDamage
        else tuning.strikeDamage
    local nextState, result = self._encounter.strike(self._state, player.UserId, amount)
    if not result.accepted then
        return false, "The Warden Stag cannot be struck right now."
    end
    self._state = nextState
    self._worldService:setWardenStagPresentation(self._state)
    self:_syncModel()
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
        self._analyticsService:bossResult(
            player,
            self._encounter.Id,
            self._state.manifestHash,
            self._state.outcome,
            self._state.antlersBroken,
            self:_participantCount()
        )
        local message = if self._state.outcome == "preserved"
            then "WARDEN STAG CALMED — FOREST ALLY PRESERVED · +5 AMBER SAP"
            elseif
                self._state.outcome == "harmed"
            then "WARDEN STAG DEFEATED — FOREST HARMED · +5 AMBER SAP"
            else "WARDEN STAG DEFEATED — FOREST SCARRED · +5 AMBER SAP"
        self:_notify(message)
        return true, message
    end
    if result.phaseFinished then
        self._analyticsService:bossPhase(
            player,
            self._encounter.Id,
            self._state.phase,
            "cleansing_started",
            self._state.antlersBroken
        )
        self:_notify(string.format("PHASE %d/3 — CLEANSE THE LIVING ROOTS", self._state.phase))
        return true, "The memory heart closes. Cleanse the next root pattern."
    end
    self:_notify(
        string.format("HIT — WARDEN STAG %d / %d", self._state.health, self._encounter.MaxHealth)
    )
    return true, "Your tool strikes the exposed memory heart."
end

function WardenStagService._participantCount(self: WardenStagService): number
    local count = 0
    for _ in self._state.participants do
        count += 1
    end
    return count
end

function WardenStagService.canMarkNearest(
    self: WardenStagService,
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
        or not self._survivalService:canAct(player)
    then
        return false, "NO BOSS THREAT CAN BE MARKED"
    end
    if (root.Position - model.PrimaryPart.Position).Magnitude > range then
        return false, "MOVE CLOSER TO MARK THE WARDEN STAG"
    end
    return true, "FOXFIRE MARK READY"
end

function WardenStagService.markNearest(
    self: WardenStagService,
    player: Player,
    range: number,
    duration: number
): (boolean, string)
    local allowed, reason = self:canMarkNearest(player, range)
    if not allowed then
        return false, reason
    end
    self._markedUntil = workspace:GetServerTimeNow() + duration
    self:_syncModel()
    local message = "FOXFIRE MARK — WARDEN STAG TELEGRAPHS SLOWED"
    self:_notify(message)
    return true, message
end

function WardenStagService.threatSnapshot(self: WardenStagService, viewer: Player): any
    local attack = self._attack
    if attack == nil or attack.target ~= viewer then
        return nil
    end
    return {
        attackId = attack.definition.attackId,
        displayName = attack.definition.attackName,
        enemyId = self._encounter.Id,
        enemyName = "WARDEN STAG",
        instruction = attack.definition.instruction,
        resolvesAt = attack.flow.endsAt,
        shape = attack.definition.shape,
    }
end

function WardenStagService.snapshot(self: WardenStagService, player: Player): any
    if player:GetAttribute("LastLightInExpedition") ~= true then
        return nil
    end
    -- Same contract as the Old Growth rail: no boss rail before the fight
    -- exists. "locked" is the sealed annex and "dormant" the unlocked but
    -- not-yet-entered arena; the physical seal already explains both states
    -- in the world.
    if self._state.status == "locked" or self._state.status == "dormant" then
        return nil
    end
    if not self:_inArena(player, ENCOUNTER_RADIUS + 20) then
        return nil
    end
    return self._encounter.snapshot(self._state, player.UserId)
end

function WardenStagService.combatActive(self: WardenStagService): boolean
    return self._state.status == "cleansing" or self._state.status == "vulnerable"
end

function WardenStagService.isComplete(self: WardenStagService): boolean
    return self._state.status == "complete"
end

function WardenStagService.outcome(self: WardenStagService): string?
    return self._state.outcome
end

function WardenStagService.enabled(self: WardenStagService): boolean
    return self._state.status ~= "disabled"
end

return table.freeze(WardenStagService)
