--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerCombatService = {}
PlayerCombatService.__index = PlayerCombatService
PlayerCombatService.Name = "PlayerCombatService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type PlayerCombatService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _combatState: any,
        _statusEffectState: any,
        _featureFlags: any,
        _survivalService: any,
        _analyticsService: any,
        _equipmentStatsProvider: ((Player) -> any)?,
        _states: { [Player]: any },
        _statusStates: { [Player]: any },
        _lastPublishedStamina: { [Player]: number },
        _lastPublishedDrowsy: { [Player]: boolean },
        _lastPublishedRooted: { [Player]: boolean },
        _lastRejectionAt: { [Player]: number },
        _nextPublishAt: { [Player]: number },
        _onChanged: ((Player, string?) -> ())?,
        _heartbeat: RBXScriptConnection?,
    },
    PlayerCombatService
))

local function humanoid(player: Player): Humanoid?
    local character = player.Character
    return if character == nil then nil else character:FindFirstChildOfClass("Humanoid")
end

local function rootPart(player: Player): BasePart?
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    return if root ~= nil and root:IsA("BasePart") then root else nil
end

function PlayerCombatService.new(
    logger: Logger,
    config: any,
    combatState: any,
    statusEffectState: any,
    featureFlags: any,
    survivalService: any,
    analyticsService: any
): PlayerCombatService
    return setmetatable({
        Name = PlayerCombatService.Name,
        _logger = logger,
        _config = config,
        _combatState = combatState,
        _statusEffectState = statusEffectState,
        _featureFlags = featureFlags,
        _survivalService = survivalService,
        _analyticsService = analyticsService,
        _equipmentStatsProvider = nil,
        _states = {},
        _statusStates = {},
        _lastPublishedStamina = {},
        _lastPublishedDrowsy = {},
        _lastPublishedRooted = {},
        _lastRejectionAt = {},
        _nextPublishAt = {},
        _onChanged = nil,
        _heartbeat = nil,
    }, PlayerCombatService)
end

function PlayerCombatService.setEquipmentStatsProvider(
    self: PlayerCombatService,
    provider: (Player) -> any
)
    self._equipmentStatsProvider = provider
end

function PlayerCombatService._staminaRegenMultiplier(
    self: PlayerCombatService,
    player: Player
): number
    local provider = self._equipmentStatsProvider
    if provider == nil then
        return 1
    end
    local stats = provider(player)
    return math.clamp(
        if type(stats) == "table" and type(stats.staminaRegenMultiplier) == "number"
            then stats.staminaRegenMultiplier
            else 1,
        0.75,
        1.5
    )
end

function PlayerCombatService.Init(_self: PlayerCombatService, _context: any) end

function PlayerCombatService.setChangedHandler(
    self: PlayerCombatService,
    callback: (Player, string?) -> ()
)
    self._onChanged = callback
end

function PlayerCombatService._notify(self: PlayerCombatService, player: Player, message: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(player, message)
    end
end

function PlayerCombatService._syncPlayer(self: PlayerCombatService, player: Player)
    local state = self._states[player]
    if state == nil then
        return
    end
    local now = workspace:GetServerTimeNow()
    local snapshot = self._combatState.snapshot(state, now)
    local statusState = self._statusStates[player] or self._statusEffectState.create()
    local status = self._statusEffectState.snapshot(statusState, now)
    local dodgeActive = self._featureFlags:isEnabled("combat_mobility_enabled")
        and snapshot.dodgeActive
    player:SetAttribute("LastLightStamina", snapshot.stamina)
    player:SetAttribute("LastLightMaxStamina", snapshot.maxStamina)
    player:SetAttribute("LastLightSprinting", snapshot.sprinting)
    player:SetAttribute("LastLightDodging", dodgeActive)
    player:SetAttribute("LastLightDodgeActiveUntil", snapshot.dodgeActiveUntil)
    player:SetAttribute("LastLightDodgeReadyAt", snapshot.dodgeReadyAt)
    player:SetAttribute("LastLightDrowsy", status.drowsy)
    player:SetAttribute("LastLightDrowsyUntil", status.drowsyUntil)
    player:SetAttribute("LastLightRooted", status.rooted)
    player:SetAttribute("LastLightRootedUntil", status.rootedUntil)
    player:SetAttribute("LastLightShielded", status.shielded)
    player:SetAttribute("LastLightShieldUntil", status.shieldUntil)
    player:SetAttribute("LastLightStaminaRegenMultiplier", self:_staminaRegenMultiplier(player))

    local activeHumanoid = humanoid(player)
    if activeHumanoid ~= nil then
        activeHumanoid.WalkSpeed = if not self._survivalService:canAct(player)
            then self._config.DownedWalkSpeed
            elseif snapshot.sprinting then self._config.SprintWalkSpeed * status.movementMultiplier
            else self._config.BaseWalkSpeed * status.movementMultiplier
    end
end

function PlayerCombatService._markPublished(self: PlayerCombatService, player: Player, now: number)
    local state = self._states[player]
    if state == nil then
        return
    end
    local snapshot = self._combatState.snapshot(state, now)
    self._lastPublishedStamina[player] = snapshot.stamina
    self._nextPublishAt[player] = now + 0.25
end

function PlayerCombatService._bindPlayer(self: PlayerCombatService, player: Player)
    if self._states[player] ~= nil then
        return
    end
    local now = workspace:GetServerTimeNow()
    self._states[player] = self._combatState.create(now)
    self._statusStates[player] = self._statusEffectState.create()
    self._lastPublishedStamina[player] = self._config.MaxStamina
    self._lastPublishedDrowsy[player] = false
    self._lastPublishedRooted[player] = false
    self._nextPublishAt[player] = now

    player.CharacterAdded:Connect(function(character: Model)
        local resetAt = workspace:GetServerTimeNow()
        self._states[player] = self._combatState.create(resetAt)
        self._statusStates[player] = self._statusEffectState.create()
        self._lastPublishedStamina[player] = self._config.MaxStamina
        self._lastPublishedDrowsy[player] = false
        self._lastPublishedRooted[player] = false
        self._nextPublishAt[player] = resetAt
        task.spawn(function()
            local activeHumanoid = character:WaitForChild("Humanoid", 8)
            if
                activeHumanoid ~= nil
                and activeHumanoid:IsA("Humanoid")
                and player.Parent ~= nil
            then
                self:_syncPlayer(player)
                self:_notify(player, nil)
            end
        end)
    end)
    self:_syncPlayer(player)
end

function PlayerCombatService.Start(self: PlayerCombatService)
    Players.PlayerAdded:Connect(function(player: Player)
        self:_bindPlayer(player)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        self._states[player] = nil
        self._statusStates[player] = nil
        self._lastPublishedStamina[player] = nil
        self._lastPublishedDrowsy[player] = nil
        self._lastPublishedRooted[player] = nil
        self._lastRejectionAt[player] = nil
        self._nextPublishAt[player] = nil
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

function PlayerCombatService._step(self: PlayerCombatService, now: number)
    local enabled = self._featureFlags:isEnabled("combat_mobility_enabled")
    for player, state in self._states do
        -- Read real movement from the humanoid so a player standing still with
        -- run toggled on is not charged for going nowhere.
        local activeHumanoid = humanoid(player)
        local moving = activeHumanoid ~= nil and activeHumanoid.MoveDirection.Magnitude > 0.05
        local nextState = self._combatState.advance(
            state,
            now,
            enabled and self._survivalService:canAct(player),
            self:_staminaRegenMultiplier(player),
            moving
        )
        self._states[player] = nextState

        local snapshot = self._combatState.snapshot(nextState, now)
        local statusState = self._statusStates[player] or self._statusEffectState.create()
        local status = self._statusEffectState.snapshot(statusState, now)
        local lastStamina = self._lastPublishedStamina[player]
        local nextPublishAt = self._nextPublishAt[player] or now
        local resourcePublish = lastStamina ~= snapshot.stamina and now >= nextPublishAt
        local sprintChanged = state.sprinting ~= nextState.sprinting
        local dodgeChanged = player:GetAttribute("LastLightDodging")
            ~= (enabled and snapshot.dodgeActive)
        local drowsyChanged = self._lastPublishedDrowsy[player] ~= status.drowsy
        local rootedChanged = self._lastPublishedRooted[player] ~= status.rooted
        if resourcePublish or sprintChanged or dodgeChanged or drowsyChanged or rootedChanged then
            self:_syncPlayer(player)
        end
        if drowsyChanged then
            self._lastPublishedDrowsy[player] = status.drowsy
            self:_notify(
                player,
                if status.drowsy then "DROWSY — KEEP MOVING" else "DROWSINESS CLEARED"
            )
        end
        if rootedChanged then
            self._lastPublishedRooted[player] = status.rooted
            self:_notify(
                player,
                if status.rooted then "ROOTED — KEEP MOVING" else "ROOTS RELEASED"
            )
        end
        if resourcePublish then
            self:_markPublished(player, now)
            self:_notify(player, nil)
        end
    end
end

function PlayerCombatService.applyRooted(
    self: PlayerCombatService,
    player: Player,
    duration: number,
    multiplier: number
): boolean
    local state = self._states[player]
    local statusState = self._statusStates[player]
    if state == nil or statusState == nil or not self._survivalService:canAct(player) then
        return false
    end
    local now = workspace:GetServerTimeNow()
    local nextState, _result =
        self._combatState.setSprint(state, false, now, true, self:_staminaRegenMultiplier(player))
    self._states[player] = nextState
    self._statusStates[player] =
        self._statusEffectState.applyRooted(statusState, now, duration, multiplier)
    self._lastPublishedRooted[player] = true
    self:_syncPlayer(player)
    self:_markPublished(player, now)
    self:_notify(player, "ROOTED — MOVEMENT SLOWED")
    return true
end

function PlayerCombatService.applyDrowsy(
    self: PlayerCombatService,
    player: Player,
    duration: number,
    multiplier: number
): boolean
    local state = self._states[player]
    local statusState = self._statusStates[player]
    if state == nil or statusState == nil or not self._survivalService:canAct(player) then
        return false
    end
    local now = workspace:GetServerTimeNow()
    local nextState, _result =
        self._combatState.setSprint(state, false, now, true, self:_staminaRegenMultiplier(player))
    self._states[player] = nextState
    self._statusStates[player] =
        self._statusEffectState.applyDrowsy(statusState, now, duration, multiplier)
    self._lastPublishedDrowsy[player] = true
    self:_syncPlayer(player)
    self:_markPublished(player, now)
    self:_notify(player, "DROWSY — MOVEMENT SLOWED")
    return true
end

function PlayerCombatService.applyShield(
    self: PlayerCombatService,
    player: Player,
    duration: number,
    multiplier: number
): boolean
    local statusState = self._statusStates[player]
    if statusState == nil or not self._survivalService:canAct(player) then
        return false
    end
    local now = workspace:GetServerTimeNow()
    self._statusStates[player] =
        self._statusEffectState.applyShield(statusState, now, duration, multiplier)
    self:_syncPlayer(player)
    return true
end

-- snapshot() reads the stored stamina as of the last periodic advance (up
-- to ~0.1s stale, see PlayerCombatService._step), while restoreStamina
-- advances fresh before mutating. A caller that gates on snapshot()'s
-- value and only later calls restoreStamina can see stamina go from
-- "not full" to "full" in that gap — this advances (without persisting)
-- so a precondition check sees exactly what restoreStamina is about to see.
function PlayerCombatService.peekStamina(self: PlayerCombatService, player: Player): number?
    local state = self._states[player]
    if state == nil then
        return nil
    end
    local now = workspace:GetServerTimeNow()
    local advanced = self._combatState.advance(
        state,
        now,
        self._survivalService:canAct(player),
        self:_staminaRegenMultiplier(player)
    )
    return self._combatState.snapshot(advanced, now).stamina
end

function PlayerCombatService.restoreStamina(
    self: PlayerCombatService,
    player: Player,
    amount: number
): any
    local state = self._states[player]
    if state == nil then
        return {
            applied = false,
            reason = "player_loading",
        }
    end
    local now = workspace:GetServerTimeNow()
    local nextState, result = self._combatState.restoreStamina(
        state,
        now,
        amount,
        self._survivalService:canAct(player),
        self:_staminaRegenMultiplier(player)
    )
    self._states[player] = nextState
    self:_syncPlayer(player)
    self:_markPublished(player, now)
    if result.applied then
        self:_notify(player, nil)
    end
    return result
end

-- Independent of ProfessionService.mitigateIncomingDamage (Warden's guard):
-- the two are checked separately at each damage call site so an item-granted
-- shield stacks with a profession's own mitigation instead of overriding it.
function PlayerCombatService.mitigateShieldedDamage(
    self: PlayerCombatService,
    player: Player,
    amount: number,
    now: number
): (number, boolean)
    local statusState = self._statusStates[player]
    if statusState == nil then
        return amount, false
    end
    local status = self._statusEffectState.snapshot(statusState, now)
    if not status.shielded then
        return amount, false
    end
    return math.max(1, math.ceil(amount * status.damageMultiplier)), true
end

function PlayerCombatService.setSprint(
    self: PlayerCombatService,
    player: Player,
    enabled: boolean
): any
    if not self._featureFlags:isEnabled("combat_mobility_enabled") then
        return {
            applied = false,
            reason = "combat_mobility_disabled",
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
    local nextState, result = self._combatState.setSprint(
        state,
        enabled,
        now,
        self._survivalService:canAct(player),
        self:_staminaRegenMultiplier(player)
    )
    self._states[player] = nextState
    self:_syncPlayer(player)
    self:_markPublished(player, now)
    self._analyticsService:combatAction(
        player,
        "sprint",
        result.applied,
        result.reason,
        result.stamina
    )
    if result.applied then
        self:_notify(player, nil)
    elseif enabled and result.reason == "insufficient_stamina" then
        self:_notify(player, "STAMINA LOW — RELEASE RUN TO RECOVER")
    end
    return result
end

function PlayerCombatService.dodge(self: PlayerCombatService, player: Player): any
    if not self._featureFlags:isEnabled("combat_mobility_enabled") then
        return {
            applied = false,
            reason = "combat_mobility_disabled",
        }
    end
    local state = self._states[player]
    local activeHumanoid = humanoid(player)
    local root = rootPart(player)
    if state == nil then
        return {
            applied = false,
            reason = "player_loading",
        }
    end
    if activeHumanoid == nil or root == nil or activeHumanoid.Health <= 0 then
        return {
            applied = false,
            reason = "character_unavailable",
        }
    end

    local now = workspace:GetServerTimeNow()
    local nextState, result = self._combatState.dodge(
        state,
        now,
        self._survivalService:canAct(player),
        self:_staminaRegenMultiplier(player)
    )
    self._states[player] = nextState
    if result.applied then
        local direction = activeHumanoid.MoveDirection
        if direction.Magnitude < 0.1 then
            direction = root.CFrame.LookVector
        end
        direction = Vector3.new(direction.X, 0, direction.Z)
        if direction.Magnitude > 0.01 then
            direction = direction.Unit
            local velocity = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(
                direction.X * self._config.DodgeSpeed,
                velocity.Y,
                direction.Z * self._config.DodgeSpeed
            )
        end
    end
    self:_syncPlayer(player)
    self:_markPublished(player, now)
    local reportResult = result.applied
        or now - (self._lastRejectionAt[player] or -math.huge) >= 0.75
    if reportResult then
        self._analyticsService:combatAction(
            player,
            "dodge",
            result.applied,
            result.reason,
            result.stamina
        )
    end
    if result.applied then
        self:_notify(player, nil)
    elseif reportResult then
        self._lastRejectionAt[player] = now
        if result.reason == "insufficient_stamina" then
            self:_notify(player, "STAMINA LOW — DODGE NEEDS 35")
        elseif result.reason == "dodge_cooldown" then
            self:_notify(player, "DODGE RECHARGING")
        end
    end
    return result
end

function PlayerCombatService.avoidsDamage(
    self: PlayerCombatService,
    player: Player,
    now: number
): boolean
    local state = self._states[player]
    return self._featureFlags:isEnabled("combat_mobility_enabled")
        and state ~= nil
        and self._combatState.avoidsDamage(state, now)
end

function PlayerCombatService.snapshot(self: PlayerCombatService, player: Player): any
    local now = workspace:GetServerTimeNow()
    local state = self._states[player]
    local snapshot = if state == nil
        then self._combatState.snapshot(self._combatState.create(now), now)
        else self._combatState.snapshot(state, now)
    local statusState = self._statusStates[player] or self._statusEffectState.create()
    local status = self._statusEffectState.snapshot(statusState, now)
    snapshot.enabled = self._featureFlags:isEnabled("combat_mobility_enabled")
    if not snapshot.enabled then
        snapshot.dodgeActive = false
    end
    snapshot.drowsy = status.drowsy
    snapshot.drowsyUntil = status.drowsyUntil
    snapshot.rooted = status.rooted
    snapshot.rootedUntil = status.rootedUntil
    snapshot.movementMultiplier = status.movementMultiplier
    snapshot.shielded = status.shielded
    snapshot.shieldUntil = status.shieldUntil
    return snapshot
end

return table.freeze(PlayerCombatService)
