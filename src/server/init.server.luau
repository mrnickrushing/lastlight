--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "Last Light shared root did not replicate before bootstrap timeout")

local Config = require(root.Config)
local BramblewakeExpedition = require(root.Content.Definitions.BramblewakeExpedition)
local CraftingCatalog = require(root.CraftingCatalog)
local DefenseLanes = require(root.DefenseLanes)
local Equipment = require(root.Equipment)
local GearVisualPlan = require(root.GearVisualPlan)
local BramblewakeEnemies = require(root.BramblewakeEnemies)
local CombatState = require(root.CombatState)
local EnemyAttackFlow = require(root.EnemyAttackFlow)
local EnemyCombatRules = require(root.EnemyCombatRules)
local EnemyMotion = require(root.EnemyMotion)
local EngineerBrace = require(root.EngineerBrace)
local Environment = require(root.Environment)
local ExpeditionEventFlow = require(root.ExpeditionEventFlow)
local ExpeditionContracts = require(root.ExpeditionContracts)
local ExpeditionGenerator = require(root.ExpeditionGenerator)
local ExpeditionRewardLedger = require(root.ExpeditionRewardLedger)
local ExtractionPayoff = require(root.ExtractionPayoff)
local NightSchedule = require(root.NightSchedule)
local OldGrowthEncounter = require(root.OldGrowthEncounter)
local WardenStagEncounter = require(root.WardenStagEncounter)
local BramblewakeBlackout = require(root.BramblewakeBlackout)
local ProfessionCatalog = require(root.ProfessionCatalog)
local ProfessionAbilityVisuals = require(root.ProfessionAbilityVisuals)
local ProfessionMastery = require(root.ProfessionMastery)
local ProfessionRescue = require(root.ProfessionRescue)
local ProfessionState = require(root.ProfessionState)
local RateLimiter = require(root.RateLimiter)
local ResidentDialogue = require(root.ResidentDialogue)
local ReviveFlow = require(root.ReviveFlow)
local RuntimeIds = require(root.RuntimeIds)
local SaveSchema = require(root.SaveSchema)
local StatusEffectState = require(root.StatusEffectState)
local SurvivalState = require(root.SurvivalState)
local TownNightSchedule = require(root.TownNightSchedule)
local TownNightIncident = require(root.TownNightIncident)
local TownCondition = require(root.TownCondition)
local TownGuardLastStand = require(root.TownGuardLastStand)
local LobbyDeparture = require(root.LobbyDeparture)
local ActionProgress = require(root.ActionProgress)
local ToolCatalog = require(root.ToolCatalog)
local GearWear = require(root.GearWear)
local GearTraits = require(root.GearTraits)
local CompanionMotion = require(root.CompanionMotion)
local ActionPayloadContract = require(root.ActionPayloadContract)
local AdminInspectionReport = require(root.AdminInspectionReport)
local PerformanceBudget = require(root.PerformanceBudget)
local ProfilePersistence = require(root.ProfilePersistence)
local ProfileBackup = require(root.ProfileBackup)
local TownPermissions = require(root.TownPermissions)
local RunHandoff = require(root.RunHandoff)
local AdminRoster = require(root.AdminRoster)
local TownDecorations = require(root.TownDecorations)
local TownProgression = require(root.TownProgression)
local MemoryFragments = require(root.MemoryFragments)
local TownConstruction = require(root.TownConstruction)
local TutorialFlow = require(root.TutorialFlow)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)

local AnalyticsService = require(script.Services.AnalyticsService)
local EnemyService = require(script.Services.EnemyService)
local ExpeditionService = require(script.Services.ExpeditionService)
local Logger = require(script.Services.Logger)
local FeatureFlagService = require(script.Services.FeatureFlagService)
local GearVisualService = require(script.Services.GearVisualService)
local NetworkService = require(script.Services.NetworkService)
local PerformanceService = require(script.Services.PerformanceService)
local OldGrowthService = require(script.Services.OldGrowthService)
local WardenStagService = require(script.Services.WardenStagService)
local BramblewakeBlackoutService = require(script.Services.BramblewakeBlackoutService)
local PhaseService = require(script.Services.PhaseService)
local ProfileService = require(script.Services.ProfileService)
local TownNightService = require(script.Services.TownNightService)
local LobbyService = require(script.Services.LobbyService)
local AdminService = require(script.Services.AdminService)
local CompanionService = require(script.Services.CompanionService)
local DefenseService = require(script.Services.DefenseService)
local PlayerSurvivalService = require(script.Services.PlayerSurvivalService)
local PlayerCombatService = require(script.Services.PlayerCombatService)
local ProfessionService = require(script.Services.ProfessionService)
local TutorialService = require(script.Services.TutorialService)
local WorldService = require(script.Services.WorldService)
local ServiceRegistry = require(script.ServiceRegistry)
local BramblewakeEnemyBuilder = require(script.World.BramblewakeEnemyBuilder)
local OldGrowthBuilder = require(script.World.OldGrowthBuilder)
local WardenStagBuilder = require(script.World.WardenStagBuilder)

local environment, environmentError = Environment.resolve({
    isStudio = RunService:IsStudio(),
    placeId = game.PlaceId,
    requested = game:GetAttribute("LastLightEnvironment"),
    productionPlaceIds = Config.ProductionPlaceIds,
})
assert(environment ~= nil, environmentError)

local environmentConfig = Config.Environments[environment]
local logger = Logger.new(environment, environmentConfig.LogLevel)
local featureFlags =
    FeatureFlagService.new(Config.FeatureFlags, environmentConfig.AllowFlagOverrides, logger)
local content = Registry.new(Regions)
local networkService = NetworkService.new(logger)
local profileService = ProfileService.new(logger, environmentConfig.UsePersistentData)
local gearVisualService = GearVisualService.new(logger, profileService, GearVisualPlan)
local analyticsService = AnalyticsService.new(logger)
local worldService = WorldService.new(
    logger,
    ExtractionPayoff,
    TownProgression,
    ProfessionAbilityVisuals,
    TownConstruction,
    MemoryFragments,
    TownDecorations
)
local expeditionService = ExpeditionService.new(
    logger,
    worldService,
    ExpeditionGenerator,
    BramblewakeExpedition,
    featureFlags,
    ExpeditionEventFlow,
    ExpeditionRewardLedger,
    ExtractionPayoff,
    profileService,
    analyticsService,
    Config.BramblewakePreviewSeed,
    ExpeditionContracts
)
local survivalService = PlayerSurvivalService.new(
    logger,
    Config,
    RuntimeIds,
    ReviveFlow,
    SurvivalState,
    featureFlags,
    worldService,
    analyticsService
)
survivalService:setExpeditionFailureHandler(function(player: Player): any
    return expeditionService:failExpedition(player)
end)
local combatService = PlayerCombatService.new(
    logger,
    Config,
    CombatState,
    StatusEffectState,
    featureFlags,
    survivalService,
    analyticsService
)
local function equipmentStats(player: Player): any
    return profileService:equipmentStats(player)
end
survivalService:setEquipmentStatsProvider(equipmentStats)
combatService:setEquipmentStatsProvider(equipmentStats)
local professionService = ProfessionService.new(
    logger,
    ProfessionCatalog,
    ProfessionState,
    ProfessionMastery,
    ProfessionRescue,
    featureFlags,
    profileService,
    worldService,
    survivalService,
    analyticsService
)
survivalService:setReviveTuningProvider(function(player: Player): any
    return professionService:rescueTuning(
        player,
        Config.ReviveChannelSeconds,
        Config.ReviveHealth,
        Config.ReviveInvulnerabilitySeconds
    )
end)
local enemyService = EnemyService.new(
    logger,
    Config,
    worldService,
    survivalService,
    combatService,
    EnemyAttackFlow,
    BramblewakeEnemies,
    EnemyCombatRules,
    EnemyMotion,
    EngineerBrace,
    BramblewakeEnemyBuilder,
    analyticsService
)
professionService:setEnemyService(enemyService)
professionService:setCombatService(combatService)
expeditionService:bindEnemyService(enemyService)
enemyService:setProfessionService(professionService)
local companionService = CompanionService.new(logger, CompanionMotion)
local defenseService =
    DefenseService.new(logger, DefenseLanes, worldService, enemyService, profileService)
enemyService:setDefenseLanes(DefenseLanes)
local oldGrowthService = OldGrowthService.new(
    logger,
    worldService,
    expeditionService,
    survivalService,
    combatService,
    professionService,
    OldGrowthEncounter,
    EnemyAttackFlow,
    EnemyCombatRules,
    OldGrowthBuilder,
    analyticsService,
    featureFlags
)
enemyService:setEliteService(oldGrowthService)
local wardenStagService = WardenStagService.new(
    logger,
    worldService,
    expeditionService,
    survivalService,
    combatService,
    professionService,
    oldGrowthService,
    WardenStagEncounter,
    EnemyAttackFlow,
    EnemyCombatRules,
    WardenStagBuilder,
    analyticsService,
    featureFlags
)
enemyService:setBossService(wardenStagService)
local blackoutService = BramblewakeBlackoutService.new(
    logger,
    Config,
    worldService,
    expeditionService,
    profileService,
    survivalService,
    oldGrowthService,
    wardenStagService,
    BramblewakeBlackout,
    analyticsService,
    featureFlags
)
oldGrowthService:setActivationGate(function(): boolean
    return blackoutService:allowsOldGrowth()
end)
wardenStagService:setUnlockGate(function(): boolean
    return blackoutService:allowsWarden()
end)
local phaseService = PhaseService.new(
    logger,
    worldService,
    enemyService,
    NightSchedule,
    Config.FirstNightDuskSeconds,
    Config.FirstNightSeconds
)
local lobbyService = LobbyService.new(
    logger,
    Config,
    LobbyDeparture,
    RunHandoff,
    featureFlags,
    worldService,
    analyticsService
)
local performanceService = PerformanceService.new(logger, Config, PerformanceBudget)
local adminService = AdminService.new(
    logger,
    AdminRoster,
    featureFlags,
    profileService,
    survivalService,
    combatService,
    worldService,
    expeditionService,
    performanceService
)
local townNightService = TownNightService.new(
    logger,
    Config,
    worldService,
    enemyService,
    TownNightSchedule,
    TownNightIncident,
    TownCondition,
    TownPermissions,
    TownGuardLastStand,
    analyticsService,
    featureFlags
)
townNightService:setDefense(defenseService, DefenseLanes)
survivalService:setPartyRecoveryProvider(
    function(eligiblePlayers: number, downedPlayers: number): any
        return townNightService:attemptLastStand(eligiblePlayers, downedPlayers)
    end
)
professionService:setSwitchProvider(function(player: Player): (boolean, string?)
    local profile = profileService:get(player)
    if profile == nil or profile.tutorial.complete ~= true then
        return false, "COMPLETE FIRST LIGHT TO CHOOSE A PROFESSION"
    end
    if phaseService:snapshot().nightActive or townNightService:isNightActive() then
        return false, "RETURN TO DAYLIGHT BEFORE SWITCHING PROFESSION"
    end
    if expeditionService:snapshot(player).active then
        return false, "RETURN THROUGH THE WAYHOME GATE BEFORE SWITCHING"
    end
    return true, nil
end)
local tutorialService = TutorialService.new(
    logger,
    Config,
    RuntimeIds,
    TutorialFlow,
    RateLimiter,
    featureFlags,
    networkService,
    profileService,
    worldService,
    enemyService,
    survivalService,
    combatService,
    professionService,
    phaseService,
    townNightService,
    lobbyService,
    expeditionService,
    oldGrowthService,
    wardenStagService,
    blackoutService,
    analyticsService,
    CraftingCatalog,
    Equipment,
    ResidentDialogue,
    ActionProgress,
    ToolCatalog,
    GearWear,
    GearTraits
)

local services = ServiceRegistry.new({
    environment = environment,
    logger = logger,
    featureFlags = featureFlags,
    content = content,
    runtimeIds = RuntimeIds,
    saveSchema = SaveSchema,
    actionPayloadContract = ActionPayloadContract,
    adminInspectionReport = AdminInspectionReport,
    profilePersistence = ProfilePersistence,
    profileBackup = ProfileBackup,
    config = Config,
})
services:register(featureFlags)
services:register(performanceService)
services:register(networkService)
services:register(profileService)
services:register(gearVisualService)
services:register(analyticsService)
services:register(worldService)
services:register(expeditionService)
services:register(survivalService)
services:register(combatService)
services:register(professionService)
services:register(enemyService)
services:register(oldGrowthService)
services:register(wardenStagService)
services:register(blackoutService)
services:register(phaseService)
services:register(lobbyService)
services:register(townNightService)
services:register(companionService)
services:register(defenseService)
-- Without this the departure countdown never reached a client: LobbyService
-- published every whole second into a handler nobody had set, so the panel
-- froze at "DEPARTING IN 10" while the server counted down and launched.
lobbyService:setChangedHandler(function(toast: string?)
    tutorialService:broadcastLobby(toast)
end)
worldService:setClickHandler(function(clicker: Player, interactionId: string)
    tutorialService:interactFromClick(clicker, interactionId)
end)
tutorialService:setCompanionService(companionService)
--[[
    Passive gear wears from the blows it softens: one point per mitigated
    hit, against the weapon's two per landed strike -- you strike more
    often than you are struck. Toasts only on a condition change, so the
    Field Book nags exactly twice per piece: once worn, once failing.
]]
survivalService:setGearWearAccruer(function(player: Player)
    for slot, itemId in profileService:equippedSnapshot(player) do
        if slot ~= "weapon" and type(itemId) == "string" then
            local wearResult = profileService:accrueGearWear(player, itemId, 1)
            if
                wearResult.applied
                and wearResult.conditionAfter ~= wearResult.conditionBefore
                and wearResult.conditionAfter ~= "sound"
            then
                local name =
                    string.upper((string.gsub((string.gsub(itemId, "^gear_", "")), "_", " ")))
                tutorialService:toastPlayer(
                    player,
                    if wearResult.conditionAfter == "failing"
                        then "YOUR " .. name .. " HAS FAILED — IT SHIELDS NOTHING NOW"
                        else "YOUR " .. name .. " IS WORN — IT PROTECTS LESS"
                )
            end
        end
    end
end)
defenseService:setToastHandler(function(player: Player?, message: string)
    if player ~= nil then
        tutorialService:toastPlayer(player, message)
    else
        tutorialService:toastEveryone(message)
    end
end)
enemyService:setStrikeHandler(function(clicker: Player)
    tutorialService:strikeFromClick(clicker)
end)
oldGrowthService:setStrikeHandler(function(clicker: Player)
    tutorialService:strikeFromClick(clicker)
end)
wardenStagService:setStrikeHandler(function(clicker: Player)
    tutorialService:strikeFromClick(clicker)
end)
-- The three sample sources the server owns. Join time is measured to the
-- moment a profile is loaded, which is the first moment a player can actually
-- do anything, rather than to the moment their character appeared.
networkService:setPerformanceHandler(function(player: Player, payload: any)
    performanceService:acceptClientReport(player, payload)
end)
profileService:onLoaded(function(player: Player, _profile: any)
    performanceService:markInteractive(player)
end)
networkService:setActionObserver(function(player: Player)
    performanceService:noteAction(player)
end)
adminService:setTutorialService(tutorialService)
services:register(adminService)
services:register(tutorialService)
services:initialize()
services:start()

logger:info("server_boot_complete", {
    build = Config.BuildVersion,
    contentDefinitions = content:count(),
    environment = environment,
    services = services:count(),
})
