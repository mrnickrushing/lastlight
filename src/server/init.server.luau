--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "Last Light shared root did not replicate before bootstrap timeout")

local Config = require(root.Config)
local BramblewakeExpedition = require(root.Content.Definitions.BramblewakeExpedition)
local CraftingCatalog = require(root.CraftingCatalog)
local Equipment = require(root.Equipment)
local BramblewakeEnemies = require(root.BramblewakeEnemies)
local CombatState = require(root.CombatState)
local EnemyAttackFlow = require(root.EnemyAttackFlow)
local EnemyCombatRules = require(root.EnemyCombatRules)
local EnemyMotion = require(root.EnemyMotion)
local Environment = require(root.Environment)
local ExpeditionEventFlow = require(root.ExpeditionEventFlow)
local ExpeditionGenerator = require(root.ExpeditionGenerator)
local ExpeditionRewardLedger = require(root.ExpeditionRewardLedger)
local ExtractionPayoff = require(root.ExtractionPayoff)
local NightSchedule = require(root.NightSchedule)
local OldGrowthEncounter = require(root.OldGrowthEncounter)
local WardenStagEncounter = require(root.WardenStagEncounter)
local BramblewakeBlackout = require(root.BramblewakeBlackout)
local ProfessionCatalog = require(root.ProfessionCatalog)
local ProfessionState = require(root.ProfessionState)
local RateLimiter = require(root.RateLimiter)
local ReviveFlow = require(root.ReviveFlow)
local RuntimeIds = require(root.RuntimeIds)
local SaveSchema = require(root.SaveSchema)
local StatusEffectState = require(root.StatusEffectState)
local SurvivalState = require(root.SurvivalState)
local TownNightSchedule = require(root.TownNightSchedule)
local TutorialFlow = require(root.TutorialFlow)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)

local AnalyticsService = require(script.Services.AnalyticsService)
local EnemyService = require(script.Services.EnemyService)
local ExpeditionService = require(script.Services.ExpeditionService)
local Logger = require(script.Services.Logger)
local FeatureFlagService = require(script.Services.FeatureFlagService)
local NetworkService = require(script.Services.NetworkService)
local OldGrowthService = require(script.Services.OldGrowthService)
local WardenStagService = require(script.Services.WardenStagService)
local BramblewakeBlackoutService = require(script.Services.BramblewakeBlackoutService)
local PhaseService = require(script.Services.PhaseService)
local ProfileService = require(script.Services.ProfileService)
local TownNightService = require(script.Services.TownNightService)
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
local analyticsService = AnalyticsService.new(logger)
local worldService = WorldService.new(logger, ExtractionPayoff)
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
    Config.BramblewakePreviewSeed
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
    featureFlags,
    profileService,
    survivalService,
    analyticsService
)
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
    BramblewakeEnemyBuilder,
    analyticsService
)
professionService:setEnemyService(enemyService)
enemyService:setProfessionService(professionService)
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
local townNightService = TownNightService.new(
    logger,
    Config,
    worldService,
    enemyService,
    TownNightSchedule,
    featureFlags
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
    networkService,
    profileService,
    worldService,
    enemyService,
    survivalService,
    combatService,
    professionService,
    phaseService,
    townNightService,
    expeditionService,
    oldGrowthService,
    wardenStagService,
    blackoutService,
    analyticsService,
    CraftingCatalog,
    Equipment
)

local services = ServiceRegistry.new({
    environment = environment,
    logger = logger,
    featureFlags = featureFlags,
    content = content,
    runtimeIds = RuntimeIds,
    saveSchema = SaveSchema,
})
services:register(featureFlags)
services:register(networkService)
services:register(profileService)
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
services:register(townNightService)
services:register(tutorialService)
services:initialize()
services:start()

logger:info("server_boot_complete", {
    build = Config.BuildVersion,
    contentDefinitions = content:count(),
    environment = environment,
    services = services:count(),
})
