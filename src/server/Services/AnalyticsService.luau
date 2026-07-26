--!strict

local RobloxAnalytics = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

local AnalyticsService = {}
AnalyticsService.__index = AnalyticsService
AnalyticsService.Name = "AnalyticsService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type AnalyticsService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _startedAt: { [Player]: number },
        _expeditionStarted: { [Player]: boolean },
    },
    AnalyticsService
))

function AnalyticsService.new(logger: Logger): AnalyticsService
    return setmetatable({
        Name = AnalyticsService.Name,
        _logger = logger,
        _startedAt = {},
        _expeditionStarted = {},
    }, AnalyticsService)
end

function AnalyticsService.Init(_self: AnalyticsService, _context: any) end

function AnalyticsService.Start(_self: AnalyticsService) end

function AnalyticsService.stage(self: AnalyticsService, player: Player, step: number, stage: string)
    if self._startedAt[player] == nil then
        self._startedAt[player] = os.clock()
    end

    self._logger:info("tutorial_funnel_step", {
        player = player.UserId,
        stage = stage,
        step = step,
    })

    if not RunService:IsStudio() then
        local ok, message = pcall(function()
            RobloxAnalytics:LogOnboardingFunnelStepEvent(player, step, stage, {})
        end)
        if not ok then
            self._logger:warn("analytics_funnel_failed", {
                player = player.UserId,
                reason = tostring(message),
                stage = stage,
            })
        end
    end
end

function AnalyticsService.complete(self: AnalyticsService, player: Player)
    local startedAt = self._startedAt[player]
    local elapsed = if startedAt == nil then 0 else math.floor(os.clock() - startedAt)
    self._logger:info("tutorial_completed", {
        durationSeconds = elapsed,
        player = player.UserId,
    })

    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "FirstLightCompleted", math.max(1, elapsed), {})
        end)
    end
end

function AnalyticsService.expeditionStarted(self: AnalyticsService, player: Player, snapshot: any)
    if self._expeditionStarted[player] then
        return
    end
    self._expeditionStarted[player] = true

    self._logger:info("expedition_started", {
        hash = snapshot.manifestHash,
        player = player.UserId,
        region = "region_bramblewake",
        seed = snapshot.seed,
        source = snapshot.source,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "BramblewakeExpeditionStarted", 1, {})
        end)
    end
end

function AnalyticsService.expeditionEventStarted(
    self: AnalyticsService,
    player: Player,
    definition: any,
    manifestHash: string
)
    self._logger:info("expedition_event_started", {
        event = definition.id,
        hash = manifestHash,
        player = player.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, definition.analyticsId .. "Started", 1, {})
        end)
    end
end

function AnalyticsService.expeditionEventCompleted(
    self: AnalyticsService,
    player: Player,
    definition: any,
    manifestHash: string,
    transactionId: string,
    participantCount: number
)
    self._logger:info("expedition_event_completed", {
        event = definition.id,
        hash = manifestHash,
        participantCount = participantCount,
        player = player.UserId,
        transaction = transactionId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(
                player,
                definition.analyticsId .. "Completed",
                math.max(1, participantCount),
                {}
            )
        end)
    end
end

function AnalyticsService.expeditionEventFailed(
    self: AnalyticsService,
    eventId: string,
    manifestHash: string,
    participantCount: number
)
    self._logger:info("expedition_event_failed", {
        event = eventId,
        hash = manifestHash,
        participantCount = participantCount,
        reason = "expired",
    })
end

function AnalyticsService.expeditionExtracted(
    self: AnalyticsService,
    player: Player,
    manifestHash: string,
    settlementId: string?,
    bankedAmount: number
)
    self._logger:info("expedition_extracted", {
        bankedAmount = bankedAmount,
        hash = manifestHash,
        player = player.UserId,
        settlement = settlementId or "empty",
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(
                player,
                "BramblewakeExtracted",
                math.max(1, bankedAmount),
                {}
            )
        end)
    end
end

function AnalyticsService.expeditionExtractionFailed(
    self: AnalyticsService,
    player: Player,
    manifestHash: string,
    reason: string?
)
    self._logger:warn("expedition_extraction_failed", {
        hash = manifestHash,
        player = player.UserId,
        reason = reason or "unknown",
    })
end

function AnalyticsService.playerDowned(self: AnalyticsService, player: Player, source: string)
    self._logger:info("player_downed", {
        player = player.UserId,
        source = source,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "PlayerDowned", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = source,
            })
        end)
    end
end

function AnalyticsService.playerRevived(
    self: AnalyticsService,
    player: Player,
    reviver: Player,
    duration: number
)
    self._logger:info("player_revived", {
        duration = duration,
        player = player.UserId,
        reviver = reviver.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "PlayerRevived", 1, {})
        end)
    end
end

function AnalyticsService.playerRecovered(self: AnalyticsService, player: Player, reason: string)
    self._logger:info("player_recovered", {
        player = player.UserId,
        reason = reason,
    })
end

function AnalyticsService.combatAction(
    self: AnalyticsService,
    player: Player,
    action: string,
    applied: boolean,
    reason: string?,
    stamina: number
)
    self._logger:info("combat_action", {
        action = action,
        applied = applied,
        player = player.UserId,
        reason = reason or "accepted",
        stamina = math.floor(stamina + 0.5),
    })
    if applied and action == "dodge" and not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "CombatDodgeUsed", 1, {})
        end)
    end
end

function AnalyticsService.enemyAttackResult(
    self: AnalyticsService,
    player: Player,
    result: string,
    enemyId: string?
)
    local resolvedEnemyId = string.sub(enemyId or "enemy_unknown", 1, 48)
    self._logger:info("enemy_attack_result", {
        enemy = resolvedEnemyId,
        player = player.UserId,
        result = result,
    })
    if result == "dodged" and not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "EnemyAttackDodged", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = resolvedEnemyId,
            })
        end)
    end
end

function AnalyticsService.professionSelected(
    self: AnalyticsService,
    player: Player,
    professionId: string,
    accepted: boolean,
    reason: string?
)
    self._logger:info("profession_selected", {
        accepted = accepted,
        player = player.UserId,
        profession = string.sub(professionId, 1, 32),
        reason = reason or "accepted",
    })
    if accepted and not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "ProfessionSelected", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = professionId,
            })
        end)
    end
end

function AnalyticsService.professionAbility(
    self: AnalyticsService,
    player: Player,
    professionId: string,
    accepted: boolean,
    reason: string?,
    affected: number
)
    self._logger:info("profession_ability", {
        accepted = accepted,
        affected = affected,
        player = player.UserId,
        profession = string.sub(professionId, 1, 32),
        reason = reason or "accepted",
    })
    if accepted and not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "ProfessionAbilityUsed", math.max(1, affected), {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = professionId,
            })
        end)
    end
end

function AnalyticsService.eliteStarted(
    self: AnalyticsService,
    player: Player,
    eliteId: string,
    manifestHash: string
)
    self._logger:info("elite_started", {
        elite = string.sub(eliteId, 1, 48),
        hash = manifestHash,
        player = player.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "EliteEncounterStarted", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = eliteId,
            })
        end)
    end
end

function AnalyticsService.eliteAttackTelegraphed(
    self: AnalyticsService,
    player: Player,
    eliteId: string,
    attackId: string,
    shape: string,
    windup: number
)
    self._logger:info("elite_attack_telegraphed", {
        attack = string.sub(attackId, 1, 48),
        elite = string.sub(eliteId, 1, 48),
        player = player.UserId,
        shape = shape,
        windup = windup,
    })
end

function AnalyticsService.eliteAttackResult(
    self: AnalyticsService,
    player: Player,
    eliteId: string,
    attackId: string,
    result: string
)
    self._logger:info("elite_attack_result", {
        attack = string.sub(attackId, 1, 48),
        elite = string.sub(eliteId, 1, 48),
        player = player.UserId,
        result = string.sub(result, 1, 32),
    })
end

function AnalyticsService.elitePhase(
    self: AnalyticsService,
    player: Player,
    eliteId: string,
    phase: number,
    result: string
)
    self._logger:info("elite_phase", {
        elite = string.sub(eliteId, 1, 48),
        phase = phase,
        player = player.UserId,
        result = string.sub(result, 1, 32),
    })
end

function AnalyticsService.eliteCompleted(
    self: AnalyticsService,
    player: Player,
    eliteId: string,
    manifestHash: string,
    shieldsBurned: number,
    participantCount: number
)
    self._logger:info("elite_completed", {
        elite = string.sub(eliteId, 1, 48),
        hash = manifestHash,
        participantCount = participantCount,
        player = player.UserId,
        shieldsBurned = shieldsBurned,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(
                player,
                "EliteEncounterCompleted",
                math.max(1, participantCount),
                {
                    [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = eliteId,
                }
            )
        end)
    end
end

function AnalyticsService.clear(self: AnalyticsService, player: Player)
    self._startedAt[player] = nil
    self._expeditionStarted[player] = nil
end

return table.freeze(AnalyticsService)
