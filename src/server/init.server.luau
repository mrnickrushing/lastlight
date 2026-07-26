--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "Last Light shared root did not replicate before bootstrap timeout")

local Config = require(root.Config)
local BramblewakeExpedition = require(root.Content.Definitions.BramblewakeExpedition)
local CombatState = require(root.CombatState)
local EnemyAttackFlow = require(root.EnemyAttackFlow)
local Environment = require(root.Environment)
local ExpeditionEventFlow = require(root.ExpeditionEventFlow)
local ExpeditionGenerator = require(root.ExpeditionGenerator)
local ExpeditionRewardLedger = require(root.ExpeditionRewardLedger)
local NightSchedule = require(root.NightSchedule)
local ProfessionCatalog = require(root.ProfessionCatalog)
local ProfessionState = require(root.ProfessionState)
local RateLimiter = require(root.RateLimiter)
local ReviveFlow = require(root.ReviveFlow)
local RuntimeIds = require(root.RuntimeIds)
local SaveSchema = require(root.SaveSchema)
local SurvivalState = require(root.SurvivalState)
local TutorialFlow = require(root.TutorialFlow)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)

local AnalyticsService = require(script.Services.AnalyticsService)
local EnemyService = require(script.Services.EnemyService)
local ExpeditionService = require(script.Services.ExpeditionService)
local Logger = require(script.Services.Logger)
local FeatureFlagService = require(script.Services.FeatureFlagService)
local NetworkService = require(script.Services.NetworkService)
local PhaseService = require(script.Services.PhaseService)
local ProfileService = require(script.Services.ProfileService)
local PlayerSurvivalService = require(script.Services.PlayerSurvivalService)
local PlayerCombatService = require(script.Services.PlayerCombatService)
local ProfessionService = require(script.Services.ProfessionService)
local TutorialService = require(script.Services.TutorialService)
local WorldService = require(script.Services.WorldService)
local ServiceRegistry = require(script.ServiceRegistry)

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
local worldService = WorldService.new(logger)
local expeditionService = ExpeditionService.new(
    logger,
    worldService,
    ExpeditionGenerator,
    BramblewakeExpedition,
    featureFlags,
    ExpeditionEventFlow,
    ExpeditionRewardLedger,
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
    featureFlags,
    survivalService,
    analyticsService
)
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
    analyticsService
)
professionService:setEnemyService(enemyService)
enemyService:setProfessionService(professionService)
local phaseService = PhaseService.new(
    logger,
    worldService,
    enemyService,
    NightSchedule,
    Config.FirstNightDuskSeconds,
    Config.FirstNightSeconds
)
professionService:setSwitchProvider(function(player: Player): (boolean, string?)
    local profile = profileService:get(player)
    if profile == nil or profile.tutorial.complete ~= true then
        return false, "COMPLETE FIRST LIGHT TO CHOOSE A PROFESSION"
    end
    if phaseService:snapshot().nightActive then
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
    expeditionService,
    analyticsService
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
services:register(phaseService)
services:register(tutorialService)
services:initialize()
services:start()

logger:info("server_boot_complete", {
    build = Config.BuildVersion,
    contentDefinitions = content:count(),
    environment = environment,
    services = services:count(),
})
