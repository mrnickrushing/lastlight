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

--[[
    The events a release gate is read from.

    RELEASE_GATES.md is the document a promotion decision is made against, and
    every threshold in it names a rate: transaction success, crash-free
    sessions, join failure, first-night completion, receipts that reached a
    grant. A rate needs a numerator and a denominator, and until this block
    existed most of them had neither -- which is the failure mode the gate
    document is least able to detect, because a dashboard reading zero and a
    dashboard reading nothing look identical to the person approving a
    release. A gate nobody measures is a gate nobody can fail.

    Each function below is the emitter one row of that document names, and the
    document names it back. `GateMetrics.spec` holds the two lists against each
    other in both directions, so a threshold added without an emitter fails on
    the day it is written down and an emitter that stops being called fails on
    the day its call site goes.

    Two rules the shape follows. **Every one of these is a server event**: the
    document says operational rates use authoritative server events and that
    client telemetry cannot hide a server failure, so nothing here is a client
    reporting its own success. And **every one carries the dimensions its
    per-segment threshold is read on**, because a gate that can only be read
    across the whole population is exactly the gate a phone-only failure hides
    behind.
]]

--[[
    One profile read or write, and whether it landed.

    The denominator of "profile load/save transaction success at least 99.9%".
    Both directions are the same event with a `kind`, because the gate is one
    number over both and splitting it into two events would let a build pass by
    counting only the easy half.
]]
function AnalyticsService.profileTransaction(
    self: AnalyticsService,
    userId: number,
    kind: string,
    ok: boolean,
    reason: string?
)
    self._logger:info("profile_transaction", {
        kind = string.sub(kind, 1, 24),
        ok = ok,
        reason = string.sub(reason or "ok", 1, 48),
        user = userId,
    })
end

--[[
    A save that is gone, or a stored profile that could not be understood.

    Zero-tolerance. This is deliberately not the same event as a failed
    transaction: a failed write that the next write repairs costs a player
    nothing, and folding the two together would bury the six-a-day event that
    stops a release under the thousand-a-day one that does not.
]]
function AnalyticsService.saveLoss(
    self: AnalyticsService,
    userId: number,
    kind: string,
    reason: string
)
    self._logger:warn("save_loss", {
        kind = string.sub(kind, 1, 24),
        reason = string.sub(reason, 1, 64),
        user = userId,
    })
end

--[[
    A session that reached play, with the two labels it is sliced by.

    "An interactive session begins when the player can move and act in
    Emberhollow, not when the client process starts" -- so this fires when the
    profile is loaded and the world will answer, not at PlayerAdded. It is the
    denominator of the crash-free gate, the sample it carries is the join p95
    gate, and `daysSinceFirstSession` is what D1 and D7 return are counted from.
]]
function AnalyticsService.sessionStarted(
    self: AnalyticsService,
    player: Player,
    joinSeconds: number,
    platform: string,
    daysSinceFirstSession: number
)
    self._logger:info("interactive_session", {
        daysSinceFirstSession = daysSinceFirstSession,
        joinSeconds = math.floor(joinSeconds * 100 + 0.5) / 100,
        -- Their first day, which is what "eligible new players" means in the
        -- gate document's denominators.
        newPlayer = daysSinceFirstSession <= 0,
        platform = platform,
        player = player.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "InteractiveSession", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = platform,
            })
        end)
    end
end

--[[
    Somebody who joined and never got to play.

    The numerator of the join failure gate. Its denominator is this plus
    `interactive_session`, which is why both live in the same service and are
    emitted from the same place: counting failures against a denominator
    gathered somewhere else is how a rate quietly becomes a count.
]]
function AnalyticsService.joinFailed(
    self: AnalyticsService,
    player: Player,
    reason: string,
    waitedSeconds: number,
    platform: string
)
    self._logger:warn("join_failed", {
        platform = platform,
        player = player.UserId,
        reason = string.sub(reason, 1, 32),
        waitedSeconds = math.floor(waitedSeconds * 100 + 0.5) / 100,
    })
end

--[[
    How a session finished, which is the only way a crash is ever counted.

    Roblox has no crash signal. What a server can see is that a client stopped
    talking to it before it disappeared: telemetry arrives on a fixed interval,
    so a session whose last report is several intervals stale at the moment the
    player leaves did not close, it stopped. That is an approximation and the
    gate document says so; it is also the same approximation every crash-free
    metric on this platform is built on, and it is strictly better than a
    number nobody collects.
]]
function AnalyticsService.sessionEnded(
    self: AnalyticsService,
    userId: number,
    reason: string,
    durationSeconds: number,
    interactive: boolean,
    platform: string,
    segment: string
)
    self._logger:info("session_ended", {
        durationSeconds = math.floor(durationSeconds + 0.5),
        interactive = interactive,
        platform = platform,
        reason = string.sub(reason, 1, 24),
        segment = segment,
        user = userId,
    })
end

--[[
    A seed whose generated manifest could not be validated, so the known-good
    walk was handed out instead.

    Two gates read this. The fallback rate is a reliability threshold; a
    fallback on a *critical path* is zero-tolerance, because an impossible seed
    on the road to a chapter is a player who cannot finish the game. The event
    carries the region and the seed so the second can be reproduced rather than
    described.
]]
function AnalyticsService.generatorFallback(
    self: AnalyticsService,
    regionId: string,
    seed: number,
    reason: string
)
    self._logger:warn("generator_fallback", {
        reason = string.sub(reason, 1, 48),
        region = string.sub(regionId, 1, 48),
        seed = seed,
    })
end

--[[
    One player through their first night.

    "First-night completion after onboarding" is a ratio against players who
    finished onboarding, so it is emitted per player at the moment their own
    tutorial advances past the night, rather than once per server when the
    night resolves. A server-wide event would count a night, not a person, and
    the gate is about people.
]]
function AnalyticsService.firstNightCompleted(self: AnalyticsService, player: Player)
    self._logger:info("first_night_completed", { player = player.UserId })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "FirstNightCompleted", 1, {})
        end)
    end
end

--[[
    A request that tried to change something it had no right to change.

    Zero-tolerance covers "unauthorized economy, entitlement, admin, or
    progression mutation", and the honest reading is that the gate is about
    attempts that *succeeded*. Nothing here can emit that, because a mutation
    this game let through is by definition one it did not notice. What it can
    emit is every attempt it refused, which is the signal that says whether
    anybody is trying -- and the rate at which a refusal fires is the first
    place a hole shows up, since an exploit found is an exploit probed for
    first.
]]
function AnalyticsService.unauthorizedMutation(
    self: AnalyticsService,
    userId: number,
    surface: string,
    reason: string
)
    self._logger:warn("unauthorized_mutation", {
        reason = string.sub(reason, 1, 48),
        surface = string.sub(surface, 1, 32),
        user = userId,
    })
end

--[[
    Money taken and nothing handed over.

    The other zero-tolerance commerce event, and the one that costs a real
    person real currency: a receipt this build cannot resolve to a product, or
    a grant whose durable write did not land. Both leave the platform holding a
    completed purchase with no entitlement behind it. Neither is a retry --
    `receipt_result` carries those -- because a retry is the system working.
]]
function AnalyticsService.purchaseLoss(
    self: AnalyticsService,
    userId: number,
    productId: string,
    reason: string
)
    self._logger:warn("purchase_loss", {
        product = string.sub(productId, 1, 48),
        reason = string.sub(reason, 1, 48),
        user = userId,
    })
end

--[[
    What the platform's purchase prompt came back as.

    "Canceled prompts produce no receipt and no grant" is a gate about
    something *not* happening, and the only way to check that a cancel produced
    nothing is to know a cancel happened. Without this the metric is the
    absence of an event, which is indistinguishable from the store being shut.
]]
function AnalyticsService.purchasePromptFinished(
    self: AnalyticsService,
    userId: number,
    productId: string,
    purchased: boolean
)
    self._logger:info("purchase_prompt_finished", {
        product = string.sub(productId, 1, 48),
        purchased = purchased,
        user = userId,
    })
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

function AnalyticsService.lobbyDeparture(
    self: AnalyticsService,
    player: Player?,
    action: string,
    accepted: boolean,
    reason: string?,
    value: any
)
    self._logger:info("lobby_departure", {
        action = action,
        accepted = accepted,
        reason = reason,
        value = value,
        player = if player ~= nil then player.UserId else nil,
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

function AnalyticsService.professionMasteryRank(
    self: AnalyticsService,
    player: Player,
    professionId: string,
    level: number,
    rankName: string
)
    self._logger:info("profession_mastery_rank", {
        level = level,
        player = player.UserId,
        profession = string.sub(professionId, 1, 32),
        rank = string.sub(rankName, 1, 24),
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "ProfessionMasteryRank", level, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = professionId,
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = rankName,
            })
        end)
    end
end

function AnalyticsService.professionSpecializationSelected(
    self: AnalyticsService,
    player: Player,
    professionId: string,
    specializationId: string,
    accepted: boolean,
    reason: string?
)
    self._logger:info("profession_specialization_selected", {
        accepted = accepted,
        player = player.UserId,
        profession = professionId,
        reason = reason,
        specialization = specializationId,
    })
end

function AnalyticsService.engineerBraceDeployed(
    self: AnalyticsService,
    player: Player,
    capacity: number,
    duration: number,
    revision: number
)
    self._logger:info("engineer_brace_deployed", {
        capacity = capacity,
        duration = duration,
        player = player.UserId,
        revision = revision,
    })
end

function AnalyticsService.engineerBraceAbsorbed(
    self: AnalyticsService,
    ownerUserId: number,
    source: string,
    absorbed: number,
    remaining: number,
    capacity: number
)
    self._logger:info("engineer_brace_absorbed", {
        absorbed = absorbed,
        capacity = capacity,
        owner = ownerUserId,
        remaining = remaining,
        source = string.sub(source, 1, 48),
    })
end

function AnalyticsService.townNightConsequence(
    self: AnalyticsService,
    nightNumber: number,
    endingLanternHealth: number,
    integrity: number,
    damageLevel: number
)
    self._logger:info("town_night_consequence", {
        damageLevel = damageLevel,
        endingLanternHealth = endingLanternHealth,
        integrity = integrity,
        night = nightNumber,
    })
end

function AnalyticsService.townGuardLastStand(
    self: AnalyticsService,
    accepted: boolean,
    reason: string,
    partySize: number,
    nightNumber: number,
    lanternHealth: number
)
    self._logger:info("town_guard_last_stand_attempt", {
        accepted = accepted,
        lanternHealth = lanternHealth,
        night = nightNumber,
        partySize = partySize,
        reason = reason,
    })
end

function AnalyticsService.townRepaired(
    self: AnalyticsService,
    player: Player,
    integrity: number,
    repairsRemaining: number
)
    self._logger:info("town_repaired", {
        integrity = integrity,
        player = player.UserId,
        repairsRemaining = repairsRemaining,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "TownRepaired", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tostring(integrity),
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = tostring(repairsRemaining),
            })
        end)
    end
end

function AnalyticsService.crafted(
    self: AnalyticsService,
    player: Player,
    recipeId: string,
    accepted: boolean,
    reason: string?
)
    self._logger:info("item_crafted", {
        accepted = accepted,
        player = player.UserId,
        reason = reason or "accepted",
        recipe = string.sub(recipeId, 1, 32),
    })
    if accepted and not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "ItemCrafted", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = recipeId,
            })
        end)
    end
end

function AnalyticsService.usedGear(
    self: AnalyticsService,
    player: Player,
    itemId: string,
    accepted: boolean,
    reason: string?
)
    self._logger:info("gear_used", {
        accepted = accepted,
        item = string.sub(itemId, 1, 32),
        player = player.UserId,
        reason = reason or "accepted",
    })
    if accepted and not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "GearUsed", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = itemId,
            })
        end)
    end
end

function AnalyticsService.memoryFragmentRecovered(
    self: AnalyticsService,
    player: Player,
    fragmentId: string
)
    self._logger:info("memory_fragment_recovered", {
        player = player.UserId,
        fragment = string.sub(fragmentId, 1, 48),
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "MemoryFragmentRecovered", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = fragmentId,
            })
        end)
    end
end

function AnalyticsService.questClaimed(self: AnalyticsService, player: Player, questId: string)
    self._logger:info("quest_claimed", {
        player = player.UserId,
        quest = string.sub(questId, 1, 48),
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "QuestClaimed", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = questId,
            })
        end)
    end
end

function AnalyticsService.residentTalked(
    self: AnalyticsService,
    player: Player,
    residentId: string,
    questId: string,
    state: string
)
    self._logger:info("resident_talked", {
        player = player.UserId,
        quest = string.sub(questId, 1, 48),
        resident = string.sub(residentId, 1, 48),
        state = string.sub(state, 1, 24),
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "ResidentTalked", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = residentId,
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = questId,
                [Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = state,
            })
        end)
    end
end

--[[
    One phrase said. The phrase id and its category, never a composed string,
    because there is no composed string to log -- which is the same fact the
    safety review reads and worth having in the telemetry as well as in the
    code. `marked` says whether it left a ping, which is how a tuning pass
    tells a party that is coordinating from one that is only talking.
]]
function AnalyticsService.quickChatSent(
    self: AnalyticsService,
    player: Player,
    phrase: any,
    marked: boolean
)
    self._logger:info("quick_chat_sent", {
        category = string.sub(tostring(phrase.category), 1, 24),
        marked = marked,
        phrase = string.sub(tostring(phrase.id), 1, 48),
        player = player.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "QuickChatSent", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = phrase.id,
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = phrase.category,
            })
        end)
    end
end

--[[
    The commerce events the monetization taxonomy names. Nothing here carries a
    price or a receipt id: the taxonomy asks what happened, and what happened is
    a product id and an outcome.
]]
function AnalyticsService.storeView(self: AnalyticsService, player: Player, cardCount: number)
    self._logger:info("store_view", { cards = cardCount, player = player.UserId })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "StoreView", math.max(1, cardCount), {})
        end)
    end
end

function AnalyticsService.productDetailView(
    self: AnalyticsService,
    player: Player,
    productId: string
)
    self._logger:info("product_detail_view", {
        player = player.UserId,
        product = string.sub(productId, 1, 48),
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "ProductDetailView", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = productId,
            })
        end)
    end
end

function AnalyticsService.purchasePrompt(
    self: AnalyticsService,
    player: Player,
    productId: string,
    shown: boolean
)
    self._logger:info("purchase_prompt", {
        player = player.UserId,
        product = string.sub(productId, 1, 48),
        shown = shown,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "PurchasePrompt", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = productId,
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = tostring(shown),
            })
        end)
    end
end

--[[
    How one receipt settled, and how long it took.

    The seconds are a release gate rather than a curiosity: "at least 99.5% of
    completed receipts reach the durable grant within 60 seconds". Measured
    from the moment the platform handed the receipt over, so a purchase that
    waited in the mailbox while its buyer was in another server carries the
    whole wait rather than the instant it was finally applied -- which is the
    only version of the number a player would recognise.
]]
function AnalyticsService.receiptResult(
    self: AnalyticsService,
    player: Player,
    productId: string,
    outcome: string,
    elapsedSeconds: number
)
    self._logger:info("receipt_result", {
        elapsedSeconds = math.max(0, math.floor(elapsedSeconds + 0.5)),
        outcome = string.sub(outcome, 1, 24),
        player = player.UserId,
        product = string.sub(productId, 1, 48),
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "ReceiptResult", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = productId,
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = outcome,
            })
        end)
    end
end

function AnalyticsService.cosmeticEquipped(
    self: AnalyticsService,
    player: Player,
    cosmeticId: string,
    slot: string
)
    self._logger:info("cosmetic_equipped", {
        cosmetic = string.sub(cosmeticId, 1, 48),
        player = player.UserId,
        slot = string.sub(slot, 1, 24),
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "CosmeticEquipped", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = cosmeticId,
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = slot,
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

function AnalyticsService.bossStarted(
    self: AnalyticsService,
    player: Player,
    bossId: string,
    manifestHash: string
)
    self._logger:info("boss_started", {
        boss = string.sub(bossId, 1, 48),
        hash = manifestHash,
        player = player.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "BossEncounterStarted", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = bossId,
            })
        end)
    end
end

function AnalyticsService.bossAttackTelegraphed(
    self: AnalyticsService,
    player: Player,
    bossId: string,
    attackId: string,
    shape: string,
    windup: number
)
    self._logger:info("boss_attack_telegraphed", {
        attack = string.sub(attackId, 1, 48),
        boss = string.sub(bossId, 1, 48),
        player = player.UserId,
        shape = shape,
        windup = windup,
    })
end

function AnalyticsService.bossAttackResult(
    self: AnalyticsService,
    player: Player,
    bossId: string,
    attackId: string,
    result: string
)
    self._logger:info("boss_attack_result", {
        attack = string.sub(attackId, 1, 48),
        boss = string.sub(bossId, 1, 48),
        player = player.UserId,
        result = string.sub(result, 1, 32),
    })
end

function AnalyticsService.bossPhase(
    self: AnalyticsService,
    player: Player,
    bossId: string,
    phase: number,
    result: string,
    antlersBroken: number
)
    self._logger:info("boss_phase", {
        antlersBroken = antlersBroken,
        boss = string.sub(bossId, 1, 48),
        phase = phase,
        player = player.UserId,
        result = string.sub(result, 1, 32),
    })
end

function AnalyticsService.bossResult(
    self: AnalyticsService,
    player: Player,
    bossId: string,
    manifestHash: string,
    outcome: string?,
    antlersBroken: number,
    participantCount: number
)
    self._logger:info("boss_result", {
        antlersBroken = antlersBroken,
        boss = string.sub(bossId, 1, 48),
        hash = manifestHash,
        outcome = string.sub(outcome or "unknown", 1, 32),
        participantCount = participantCount,
        player = player.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(
                player,
                "BossEncounterCompleted",
                math.max(1, participantCount),
                {
                    [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = bossId,
                    [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = outcome or "unknown",
                }
            )
        end)
    end
end

function AnalyticsService.blackoutStarted(
    self: AnalyticsService,
    player: Player,
    blackoutId: string,
    manifestHash: string,
    duration: number
)
    self._logger:info("blackout_started", {
        blackout = string.sub(blackoutId, 1, 48),
        duration = duration,
        hash = manifestHash,
        player = player.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "BramblewakeBlackoutStarted", 1, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = blackoutId,
            })
        end)
    end
end

function AnalyticsService.blackoutStage(
    self: AnalyticsService,
    player: Player,
    blackoutId: string,
    stage: string,
    reason: string,
    revision: number
)
    self._logger:info("blackout_stage", {
        blackout = string.sub(blackoutId, 1, 48),
        player = player.UserId,
        reason = string.sub(reason, 1, 48),
        revision = revision,
        stage = string.sub(stage, 1, 32),
    })
end

function AnalyticsService.blackoutResult(
    self: AnalyticsService,
    player: Player,
    blackoutId: string,
    manifestHash: string,
    decision: string?,
    wardenOutcome: string?,
    startedAt: number?,
    completedAt: number
)
    local duration = if startedAt == nil then 0 else math.max(0, completedAt - startedAt)
    self._logger:info("blackout_result", {
        blackout = string.sub(blackoutId, 1, 48),
        decision = string.sub(decision or "unknown", 1, 32),
        duration = math.floor(duration + 0.5),
        hash = manifestHash,
        outcome = string.sub(wardenOutcome or "unknown", 1, 32),
        player = player.UserId,
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(
                player,
                "BramblewakeBlackoutCompleted",
                math.max(1, math.floor(duration + 0.5)),
                {
                    [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = decision or "unknown",
                    [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = wardenOutcome or "unknown",
                }
            )
        end)
    end
end

function AnalyticsService.chapterCompleted(
    self: AnalyticsService,
    player: Player,
    chapter: number,
    decision: string,
    wardenOutcome: string,
    transactionId: string
)
    self._logger:info("chapter_completed", {
        chapter = chapter,
        decision = string.sub(decision, 1, 32),
        outcome = string.sub(wardenOutcome, 1, 32),
        player = player.UserId,
        transaction = string.sub(transactionId, 1, 160),
    })
    if not RunService:IsStudio() then
        pcall(function()
            RobloxAnalytics:LogCustomEvent(player, "ChapterCompleted", chapter, {
                [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = decision,
                [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = wardenOutcome,
            })
        end)
    end
end

function AnalyticsService.clear(self: AnalyticsService, player: Player)
    self._startedAt[player] = nil
    self._expeditionStarted[player] = nil
end

return table.freeze(AnalyticsService)
