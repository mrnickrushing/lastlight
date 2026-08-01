--!strict

local Players = game:GetService("Players")

local ProfessionService = {}
ProfessionService.__index = ProfessionService
ProfessionService.Name = "ProfessionService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type ProfessionService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _catalog: any,
        _professionState: any,
        _professionMastery: any,
        _featureFlags: any,
        _profileService: any,
        _survivalService: any,
        _analyticsService: any,
        _states: { [Player]: any },
        _enemyService: any,
        _switchProvider: ((Player) -> (boolean, string?))?,
        _onChanged: ((Player, string?) -> ())?,
    },
    ProfessionService
))

function ProfessionService.new(
    logger: Logger,
    catalog: any,
    professionState: any,
    professionMastery: any,
    featureFlags: any,
    profileService: any,
    survivalService: any,
    analyticsService: any
): ProfessionService
    return setmetatable({
        Name = ProfessionService.Name,
        _logger = logger,
        _catalog = catalog,
        _professionState = professionState,
        _professionMastery = professionMastery,
        _featureFlags = featureFlags,
        _profileService = profileService,
        _survivalService = survivalService,
        _analyticsService = analyticsService,
        _states = {},
        _enemyService = nil,
        _switchProvider = nil,
        _onChanged = nil,
    }, ProfessionService)
end

function ProfessionService.Init(self: ProfessionService, _context: any)
    self._profileService:onLoaded(function(player: Player, profile: any)
        self:_profileLoaded(player, profile)
    end)
end

function ProfessionService.Start(self: ProfessionService)
    Players.PlayerRemoving:Connect(function(player: Player)
        self._states[player] = nil
    end)

    for _, player in Players:GetPlayers() do
        local profile = self._profileService:get(player)
        if profile ~= nil then
            self:_profileLoaded(player, profile)
        end
    end
end

function ProfessionService.setEnemyService(self: ProfessionService, enemyService: any)
    self._enemyService = enemyService
end

function ProfessionService.setSwitchProvider(
    self: ProfessionService,
    provider: (Player) -> (boolean, string?)
)
    self._switchProvider = provider
end

function ProfessionService.setChangedHandler(
    self: ProfessionService,
    callback: (Player, string?) -> ()
)
    self._onChanged = callback
end

function ProfessionService._notify(self: ProfessionService, player: Player, message: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(player, message)
    end
end

function ProfessionService._syncPlayer(self: ProfessionService, player: Player)
    local state = self._states[player]
    if state == nil then
        return
    end
    local snapshot = self._professionState.snapshot(state, workspace:GetServerTimeNow())
    player:SetAttribute("LastLightProfessionId", snapshot.selectedId)
    player:SetAttribute("LastLightProfessionReadyAt", snapshot.cooldownReadyAt)
    player:SetAttribute("LastLightProfessionActiveUntil", snapshot.activeUntil)
end

function ProfessionService._profileLoaded(self: ProfessionService, player: Player, profile: any)
    if self._states[player] ~= nil then
        return
    end
    local selectedId = if type(profile.profession) == "table"
        then profile.profession.selectedId
        else nil
    self._states[player] = self._professionState.create(selectedId, workspace:GetServerTimeNow())
    self:_syncPlayer(player)
end

function ProfessionService._switchAvailability(
    self: ProfessionService,
    player: Player
): (boolean, string?)
    if not self._survivalService:canAct(player) then
        return false, "YOU CANNOT SWITCH PROFESSION WHILE DOWNED"
    end
    local provider = self._switchProvider
    if provider == nil then
        return false, "PROFESSION SWITCHING IS STILL LOADING"
    end
    return provider(player)
end

function ProfessionService.select(
    self: ProfessionService,
    player: Player,
    professionId: string
): any
    if not self._featureFlags:isEnabled("profession_kits_enabled") then
        return {
            accepted = false,
            message = "PROFESSIONS ARE TEMPORARILY UNAVAILABLE",
            reason = "feature_disabled",
        }
    end
    local state = self._states[player]
    if state == nil then
        return {
            accepted = false,
            message = "YOUR PROFESSION LOADOUT IS STILL LOADING",
            reason = "player_loading",
        }
    end

    local canSwitch, unavailableMessage = self:_switchAvailability(player)
    local now = workspace:GetServerTimeNow()
    local nextState, result = self._professionState.select(state, professionId, now, canSwitch)
    if not result.accepted then
        local message = unavailableMessage
        if result.reason == "unknown_profession" then
            message = "THAT PROFESSION DOES NOT EXIST"
        end
        self._analyticsService:professionSelected(player, professionId, false, result.reason)
        return {
            accepted = false,
            message = message or "PROFESSION SWITCHING IS UNAVAILABLE",
            reason = result.reason,
        }
    end

    self._states[player] = nextState
    self:_syncPlayer(player)
    local definition = self._catalog.get(professionId)
    if result.changed then
        self._profileService:setProfession(player, professionId)
        self._analyticsService:professionSelected(player, professionId, true, nil)
        self._logger:info("profession_selected", {
            player = player.UserId,
            profession = professionId,
        })
    end
    local message = if result.changed
        then string.format("%s READY — %s", definition.displayName, definition.abilityName)
        else string.format("%s IS ALREADY EQUIPPED", definition.displayName)
    self:_notify(player, message)
    return {
        accepted = true,
        changed = result.changed,
        message = message,
        reason = result.reason,
    }
end

function ProfessionService._abilityPreflight(
    self: ProfessionService,
    player: Player,
    definition: any,
    tuning: any
): (boolean, string)
    local effectRadius = definition.effectRadius + tuning.effectRadiusBonus
    local enemyService = self._enemyService
    if definition.id == self._catalog.Ids.Scout then
        if enemyService == nil then
            return false, "THREAT TRACKING IS STILL LOADING"
        end
        return enemyService:canMarkNearest(player, effectRadius)
    elseif definition.id == self._catalog.Ids.Warden then
        if enemyService == nil or not enemyService:combatActive() then
            return false, "LANTERN GUARD NEEDS AN ACTIVE THREAT"
        end
        return true, "LANTERN GUARD READY"
    elseif definition.id == self._catalog.Ids.Engineer then
        if enemyService == nil then
            return false, "LANTERN REPAIRS ARE STILL LOADING"
        end
        return enemyService:canRepairLantern(player, effectRadius)
    elseif definition.id == self._catalog.Ids.Medic then
        return self._survivalService:canHealInRadius(player, effectRadius)
    end
    return true, "LANTERN GUARD READY"
end

function ProfessionService._applyAbility(
    self: ProfessionService,
    player: Player,
    definition: any,
    tuning: any
): (string, number)
    local effectAmount = definition.effectAmount + tuning.effectAmountBonus
    local effectRadius = definition.effectRadius + tuning.effectRadiusBonus
    local activeSeconds = if definition.id == self._catalog.Ids.Scout
            or definition.id == self._catalog.Ids.Warden
        then definition.activeSeconds + tuning.activeSecondsBonus
        else definition.activeSeconds
    if definition.id == self._catalog.Ids.Scout then
        local _, message = self._enemyService:markNearest(player, effectRadius, activeSeconds)
        return message, 1
    elseif definition.id == self._catalog.Ids.Warden then
        return "LANTERN GUARD ACTIVE — ENEMY DAMAGE REDUCED", 1
    elseif definition.id == self._catalog.Ids.Engineer then
        local _, message = self._enemyService:repairLantern(player, effectRadius, effectAmount)
        return message, 1
    end

    local healResult = self._survivalService:healInRadius(player, effectAmount, effectRadius)
    return string.format(
        "GUIDING PULSE — %d TRAVELER%s RESTORED",
        healResult.affected,
        if healResult.affected == 1 then "" else "S"
    ),
        healResult.affected
end

function ProfessionService.useAbility(self: ProfessionService, player: Player): any
    if not self._featureFlags:isEnabled("profession_kits_enabled") then
        return {
            accepted = false,
            message = "PROFESSION ABILITIES ARE TEMPORARILY UNAVAILABLE",
            reason = "feature_disabled",
        }
    end
    local state = self._states[player]
    if state == nil then
        return {
            accepted = false,
            message = "YOUR PROFESSION LOADOUT IS STILL LOADING",
            reason = "player_loading",
        }
    end

    local now = workspace:GetServerTimeNow()
    local decision = self._professionState.canUse(state, now, self._survivalService:canAct(player))
    if not decision.accepted then
        local message = if decision.reason == "profession_required"
            then "CHOOSE A PROFESSION IN EMBERHOLLOW"
            elseif decision.reason == "cooldown" then string.format(
                "ABILITY RECHARGING — %.1fs",
                decision.remaining or 0
            )
            else "YOU CANNOT USE AN ABILITY RIGHT NOW"
        self._analyticsService:professionAbility(
            player,
            state.selectedId or "none",
            false,
            decision.reason,
            0
        )
        return {
            accepted = false,
            message = message,
            reason = decision.reason,
        }
    end

    local definition = decision.definition
    local masteryState = self._profileService:masterySnapshot(player)
    local tuning = self._professionMastery.tuning(masteryState, definition.id)
    local validTarget, preflightMessage = self:_abilityPreflight(player, definition, tuning)
    if not validTarget then
        self._analyticsService:professionAbility(player, definition.id, false, "invalid_target", 0)
        return {
            accepted = false,
            message = preflightMessage,
            reason = "invalid_target",
        }
    end

    local cooldownSeconds = math.max(1, definition.cooldownSeconds - tuning.cooldownReduction)
    local activeSeconds = if definition.id == self._catalog.Ids.Scout
            or definition.id == self._catalog.Ids.Warden
        then definition.activeSeconds + tuning.activeSecondsBonus
        else definition.activeSeconds
    local nextState =
        self._professionState.commitAbility(state, now, cooldownSeconds, activeSeconds)
    self._states[player] = nextState
    self:_syncPlayer(player)
    local message, affected = self:_applyAbility(player, definition, tuning)
    local masteryResult = self._profileService:awardMastery(player, definition.id, 10)
    if masteryResult.leveledUp then
        message = string.format(
            "%s · %s RANK %d — %s",
            message,
            definition.displayName,
            masteryResult.level,
            masteryResult.rankName
        )
        if masteryResult.specializationUnlocked then
            message ..= " · SPECIALIZATIONS UNLOCKED"
        end
        self._analyticsService:professionMasteryRank(
            player,
            definition.id,
            masteryResult.level,
            masteryResult.rankName
        )
    end
    self._analyticsService:professionAbility(player, definition.id, true, nil, affected)
    self:_notify(player, message)
    return {
        accepted = true,
        affected = affected,
        message = message,
        reason = "used",
    }
end

function ProfessionService.mitigateIncomingDamage(
    self: ProfessionService,
    player: Player,
    amount: number,
    now: number
): (number, boolean)
    local state = self._states[player]
    if state == nil or not self._professionState.mitigatesDamage(state, now) then
        return amount, false
    end
    local masteryState = self._profileService:masterySnapshot(player)
    local tuning = self._professionMastery.tuning(masteryState, self._catalog.Ids.Warden)
    local definition = self._catalog.get(self._catalog.Ids.Warden)
    local damageReduction =
        math.clamp((definition.effectAmount + tuning.effectAmountBonus) / 100, 0, 0.8)
    return math.max(1, math.ceil(amount * (1 - damageReduction))), true
end

function ProfessionService.snapshot(self: ProfessionService, player: Player): any
    local now = workspace:GetServerTimeNow()
    local state = self._states[player]
    local snapshot = if state == nil
        then self._professionState.snapshot(self._professionState.create(nil, now), now)
        else self._professionState.snapshot(state, now)
    local switchable, unavailableMessage = self:_switchAvailability(player)
    snapshot.enabled = self._featureFlags:isEnabled("profession_kits_enabled")
    snapshot.switchable = switchable
    snapshot.switchUnavailableMessage = unavailableMessage
    snapshot.mastery = self._professionMastery.tuning(
        self._profileService:masterySnapshot(player),
        snapshot.selectedId
    )
    return snapshot
end

return table.freeze(ProfessionService)
