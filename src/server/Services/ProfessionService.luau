--!strict

local Players = game:GetService("Players")

local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)

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
        _professionRescue: any,
        _featureFlags: any,
        _profileService: any,
        _worldService: any,
        _survivalService: any,
        _analyticsService: any,
        _states: { [Player]: any },
        _enemyService: any,
        _combatService: any,
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
    professionRescue: any,
    featureFlags: any,
    profileService: any,
    worldService: any,
    survivalService: any,
    analyticsService: any
): ProfessionService
    return setmetatable({
        Name = ProfessionService.Name,
        _logger = logger,
        _catalog = catalog,
        _professionState = professionState,
        _professionMastery = professionMastery,
        _professionRescue = professionRescue,
        _featureFlags = featureFlags,
        _profileService = profileService,
        _worldService = worldService,
        _survivalService = survivalService,
        _analyticsService = analyticsService,
        _states = {},
        _enemyService = nil,
        _combatService = nil,
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

-- Late-bound like the enemy service: the combat service exists before this
-- one in the bootstrap, but taking it here rather than in the constructor
-- keeps the constructor signature stable and mirrors how every other
-- cross-service edge in this file is wired.
function ProfessionService.setCombatService(self: ProfessionService, combatService: any)
    self._combatService = combatService
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
        return false, Strings.get("toast.you_cannot_switch_profession_while_downed")
    end
    local provider = self._switchProvider
    if provider == nil then
        return false, Strings.get("toast.profession_switching_is_still_loading")
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
            message = Strings.get("toast.professions_are_temporarily_unavailable"),
            reason = "feature_disabled",
        }
    end
    local state = self._states[player]
    if state == nil then
        return {
            accepted = false,
            message = Strings.get("toast.your_profession_loadout_is_still_loading"),
            reason = "player_loading",
        }
    end

    local canSwitch, unavailableMessage = self:_switchAvailability(player)
    local now = workspace:GetServerTimeNow()
    local nextState, result = self._professionState.select(state, professionId, now, canSwitch)
    if not result.accepted then
        local message = unavailableMessage
        if result.reason == "unknown_profession" then
            message = Strings.get("toast.that_profession_does_not_exist")
        end
        self._analyticsService:professionSelected(player, professionId, false, result.reason)
        return {
            accepted = false,
            message = message or Strings.get("toast.profession_switching_is_unavailable"),
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
        then string.format(
            Strings.get("toast.n_ready_n"),
            definition.displayName,
            definition.abilityName
        )
        else string.format(Strings.get("toast.n_is_already_equipped"), definition.displayName)
    self:_notify(player, message)
    return {
        accepted = true,
        changed = result.changed,
        message = message,
        reason = result.reason,
    }
end

function ProfessionService.selectSpecialization(
    self: ProfessionService,
    player: Player,
    specializationId: string
): any
    local professionId = self._professionMastery.specializationProfession(specializationId)
    local analyticsProfessionId = professionId or "unknown_profession"
    local function reject(message: string, reason: string): any
        self._analyticsService:professionSpecializationSelected(
            player,
            analyticsProfessionId,
            specializationId,
            false,
            reason
        )
        return {
            accepted = false,
            message = message,
            reason = reason,
        }
    end

    if not self._featureFlags:isEnabled("profession_kits_enabled") then
        return reject(
            Strings.get("toast.professions_are_temporarily_unavailable"),
            "feature_disabled"
        )
    end
    local state = self._states[player]
    if state == nil then
        return reject(
            Strings.get("toast.your_profession_mastery_is_still_loading"),
            "player_loading"
        )
    end
    local snapshot = self._professionState.snapshot(state, workspace:GetServerTimeNow())
    if professionId == nil then
        return reject(
            Strings.get("toast.that_mastery_path_does_not_exist"),
            "invalid_specialization"
        )
    end
    if snapshot.selectedId ~= professionId then
        return reject(
            Strings.get("toast.equip_the_matching_profession_before_choosin"),
            "profession_mismatch"
        )
    end
    local canSwitch, unavailableMessage = self:_switchAvailability(player)
    if not canSwitch then
        return reject(
            unavailableMessage or Strings.get("toast.mastery_paths_can_only_change_in"),
            "switch_unavailable"
        )
    end
    local result =
        self._profileService:selectProfessionSpecialization(player, professionId, specializationId)
    local definition = self._professionMastery.specializationDefinition(specializationId)
    if not result.applied then
        local message = if result.duplicate
            then string.format(Strings.get("toast.n_is_already_your_mastery_path"), definition.name)
            elseif result.reason == "specialization_locked" then Strings.get(
                "toast.reach_mastery_rank_10_first"
            )
            elseif result.reason == "profile_unavailable" then Strings.get(
                "toast.your_profile_is_still_loading_or"
            )
            else Strings.get("toast.that_mastery_path_cannot_be_chosen")
        local accepted = result.duplicate == true
        self._analyticsService:professionSpecializationSelected(
            player,
            professionId,
            specializationId,
            accepted,
            result.reason
        )
        return {
            accepted = accepted,
            changed = false,
            message = message,
            reason = result.reason,
        }
    end
    self._analyticsService:professionSpecializationSelected(
        player,
        professionId,
        specializationId,
        true,
        nil
    )
    self._logger:info("profession_specialization_selected", {
        player = player.UserId,
        profession = professionId,
        specialization = specializationId,
    })
    local message =
        string.format(Strings.get("toast.n_path_chosen_n"), definition.name, definition.description)
    self:_notify(player, message)
    return {
        accepted = true,
        changed = true,
        message = message,
        reason = "selected",
    }
end

--[[
    Every ally the tonic can reach, by the same measure the pour will use.

    Counted from the caster's root the way canHealInRadius counts, so the
    preflight and the application cannot disagree about who is close enough.
    Includes the caster: an Alchemist alone at low stamina is a valid pour.
]]
function ProfessionService._staminaNeedInRadius(
    self: ProfessionService,
    player: Player,
    radius: number
): { Player }
    local needing = {}
    local combatService = self._combatService
    local character = player.Character
    local sourceRoot = if character == nil
        then nil
        else character:FindFirstChild("HumanoidRootPart")
    if combatService == nil or sourceRoot == nil or not sourceRoot:IsA("BasePart") then
        return needing
    end
    for _, other in Players:GetPlayers() do
        local otherCharacter = other.Character
        local otherRoot = if otherCharacter == nil
            then nil
            else otherCharacter:FindFirstChild("HumanoidRootPart")
        if
            otherRoot ~= nil
            and otherRoot:IsA("BasePart")
            and self._survivalService:canAct(other)
            and (otherRoot.Position - sourceRoot.Position).Magnitude <= radius
        then
            local snapshot = combatService:snapshot(other)
            if snapshot ~= nil and snapshot.stamina < snapshot.maxStamina then
                table.insert(needing, other)
            end
        end
    end
    return needing
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
            return false, Strings.get("toast.threat_tracking_is_still_loading")
        end
        return enemyService:canMarkNearest(player, effectRadius)
    elseif definition.id == self._catalog.Ids.Warden then
        if enemyService == nil or not enemyService:combatActive() then
            return false, Strings.get("toast.lantern_guard_needs_an_active_threat")
        end
        return true, Strings.get("toast.lantern_guard_ready")
    elseif definition.id == self._catalog.Ids.Engineer then
        if enemyService == nil then
            return false, Strings.get("toast.lantern_repairs_are_still_loading")
        end
        return enemyService:canRepairLantern(player, effectRadius)
    elseif definition.id == self._catalog.Ids.Medic then
        return self._survivalService:canHealInRadius(player, effectRadius)
    elseif definition.id == self._catalog.Ids.Alchemist then
        -- The tonic serves either need. Refusing only when nobody in reach
        -- wants health OR stamina keeps the no-op-cast protection the other
        -- kits have without making the brew fussier than the pulse.
        local canHeal = self._survivalService:canHealInRadius(player, effectRadius)
        if canHeal or #self:_staminaNeedInRadius(player, effectRadius) > 0 then
            return true, Strings.get("toast.sporebright_tonic_ready")
        end
        return false, Strings.get("toast.everyone_in_reach_is_already_hale")
    elseif definition.id == self._catalog.Ids.Beastkeeper then
        if enemyService == nil then
            return false, Strings.get("toast.your_hound_is_still_waking")
        end
        return enemyService:canLureThreat(player, effectRadius)
    elseif definition.id == self._catalog.Ids.Runebinder then
        if enemyService == nil then
            return false, Strings.get("toast.the_runes_are_still_settling")
        end
        return enemyService:canStillThreat(player, effectRadius)
    end
    return true, Strings.get("toast.lantern_guard_ready")
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
            or definition.id == self._catalog.Ids.Beastkeeper
            or definition.id == self._catalog.Ids.Runebinder
        then definition.activeSeconds + tuning.activeSecondsBonus
        else definition.activeSeconds
    if definition.id == self._catalog.Ids.Scout then
        local _, message = self._enemyService:markNearest(player, effectRadius, activeSeconds)
        return message, 1
    elseif definition.id == self._catalog.Ids.Warden then
        return Strings.get("toast.lantern_guard_active_enemy_damage_reduced"), 1
    elseif definition.id == self._catalog.Ids.Engineer then
        local _, message = self._enemyService:repairLantern(player, effectRadius, effectAmount)
        return message, 1
    elseif definition.id == self._catalog.Ids.Alchemist then
        -- One effectAmount, two effects: the full number is stamina, half of
        -- it is the mend, so the Brewer specialization deepens both at once
        -- and neither half competes with the Medic's dedicated heal.
        local healResult =
            self._survivalService:healInRadius(player, math.floor(effectAmount / 2), effectRadius)
        local restored = 0
        for _, other in self:_staminaNeedInRadius(player, effectRadius) do
            local result = self._combatService:restoreStamina(other, effectAmount)
            if result.applied then
                restored += 1
            end
        end
        local affected = math.max(healResult.affected, restored)
        return string.format(
            Strings.get("toast.sporebright_tonic_n_travelern_restored"),
            affected,
            if affected == 1 then "" else "S"
        ),
            affected
    elseif definition.id == self._catalog.Ids.Beastkeeper then
        local _, message = self._enemyService:lureThreat(player, effectRadius, activeSeconds)
        return message, 1
    elseif definition.id == self._catalog.Ids.Runebinder then
        local _, message = self._enemyService:stillThreat(player, effectRadius, activeSeconds)
        return message, 1
    end

    local healResult = self._survivalService:healInRadius(player, effectAmount, effectRadius)
    return string.format(
        Strings.get("toast.guiding_pulse_n_travelern_restored"),
        healResult.affected,
        if healResult.affected == 1 then "" else "S"
    ),
        healResult.affected
end

function ProfessionService.useAbility(self: ProfessionService, player: Player): any
    if not self._featureFlags:isEnabled("profession_kits_enabled") then
        return {
            accepted = false,
            message = Strings.get("toast.profession_abilities_are_temporarily_unavail"),
            reason = "feature_disabled",
        }
    end
    local state = self._states[player]
    if state == nil then
        return {
            accepted = false,
            message = Strings.get("toast.your_profession_loadout_is_still_loading"),
            reason = "player_loading",
        }
    end

    local now = workspace:GetServerTimeNow()
    local decision = self._professionState.canUse(state, now, self._survivalService:canAct(player))
    if not decision.accepted then
        local message = if decision.reason == "profession_required"
            then Strings.get("toast.choose_a_profession_in_emberhollow")
            elseif decision.reason == "cooldown" then string.format(
                Strings.get("toast.ability_recharging_ns"),
                decision.remaining or 0
            )
            else Strings.get("toast.you_cannot_use_an_ability_right")
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
            or definition.id == self._catalog.Ids.Beastkeeper
            or definition.id == self._catalog.Ids.Runebinder
        then definition.activeSeconds + tuning.activeSecondsBonus
        else definition.activeSeconds
    local nextState =
        self._professionState.commitAbility(state, now, cooldownSeconds, activeSeconds)
    self._states[player] = nextState
    self:_syncPlayer(player)
    local message, affected = self:_applyAbility(player, definition, tuning)
    self._worldService:showProfessionAbility(
        player,
        definition.id,
        definition.effectRadius + tuning.effectRadiusBonus,
        activeSeconds
    )
    local masteryResult = self._profileService:awardMastery(player, definition.id, 10)
    if masteryResult.leveledUp then
        message = string.format(
            Strings.get("toast.n_n_rank_n_n"),
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

function ProfessionService.rescueTuning(
    self: ProfessionService,
    player: Player,
    baseDuration: number,
    baseHealth: number,
    baseWardSeconds: number
): any
    local state = self._states[player]
    local now = workspace:GetServerTimeNow()
    local profession = if state == nil
        then self._professionState.snapshot(self._professionState.create(nil, now), now)
        else self._professionState.snapshot(state, now)
    local mastery = self._professionMastery.tuning(
        self._profileService:masterySnapshot(player),
        profession.selectedId
    )
    return self._professionRescue.resolve(
        profession.selectedId,
        mastery.level,
        baseDuration,
        baseHealth,
        baseWardSeconds,
        mastery
    )
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
