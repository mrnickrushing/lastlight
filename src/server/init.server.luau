--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "Last Light shared root did not replicate before bootstrap timeout")

local Config = require(root.Config)
local Environment = require(root.Environment)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)

local Logger = require(script.Services.Logger)
local FeatureFlagService = require(script.Services.FeatureFlagService)
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

local services = ServiceRegistry.new({
    environment = environment,
    logger = logger,
    featureFlags = featureFlags,
    content = content,
})
services:register(featureFlags)
services:initialize()
services:start()

logger:info("server_boot_complete", {
    build = Config.BuildVersion,
    contentDefinitions = content:count(),
    environment = environment,
    services = 1,
})
