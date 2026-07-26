--!strict

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local function loadPlace(path: string)
    assert(fs.isFile(path), "missing built place " .. path)
    return roblox.deserializePlace(fs.readFile(path))
end

local gamePlace = loadPlace("build/LastLight.rbxlx")
local replicatedStorage = gamePlace:GetService("ReplicatedStorage")
local serverScriptService = gamePlace:GetService("ServerScriptService")

local sharedRoot = replicatedStorage:FindFirstChild("LastLight")
assert(sharedRoot ~= nil, "game build is missing ReplicatedStorage.LastLight")
assert(sharedRoot:FindFirstChild("Config") ~= nil, "game build is missing Config")
assert(sharedRoot:FindFirstChild("Content") ~= nil, "game build is missing Content")
assert(sharedRoot:FindFirstChild("TutorialFlow") ~= nil, "game build is missing TutorialFlow")
assert(sharedRoot:FindFirstChild("SaveSchema") ~= nil, "game build is missing SaveSchema")
assert(sharedRoot:FindFirstChild("RuntimeIds") ~= nil, "game build is missing RuntimeIds")
assert(sharedRoot:FindFirstChild("ReviveFlow") ~= nil, "game build is missing ReviveFlow")
assert(sharedRoot:FindFirstChild("SurvivalState") ~= nil, "game build is missing SurvivalState")
assert(
    sharedRoot:FindFirstChild("ExpeditionGenerator") ~= nil,
    "game build is missing ExpeditionGenerator"
)
assert(
    sharedRoot:FindFirstChild("ExpeditionEventFlow") ~= nil,
    "game build is missing ExpeditionEventFlow"
)
assert(
    sharedRoot:FindFirstChild("ExpeditionRewardLedger") ~= nil,
    "game build is missing ExpeditionRewardLedger"
)
assert(
    sharedRoot:FindFirstChild("ExpeditionInventory") ~= nil,
    "game build is missing ExpeditionInventory"
)
local contentDefinitions = assert(
    sharedRoot:FindFirstChild("Content"),
    "game build is missing Content"
):FindFirstChild("Definitions")
assert(contentDefinitions ~= nil, "game build is missing content definitions")
assert(
    contentDefinitions:FindFirstChild("BramblewakeExpedition") ~= nil,
    "game build is missing the Bramblewake expedition catalog"
)
assert(
    serverScriptService:FindFirstChild("LastLightServer") ~= nil,
    "game build is missing LastLightServer"
)
local serverRoot =
    assert(serverScriptService:FindFirstChild("LastLightServer"), "server root unavailable")
local services = serverRoot:FindFirstChild("Services")
assert(services ~= nil, "game build is missing server services")
for _, serviceName in
    {
        "AnalyticsService",
        "EnemyService",
        "ExpeditionService",
        "FeatureFlagService",
        "Logger",
        "NetworkService",
        "PhaseService",
        "PlayerSurvivalService",
        "ProfileService",
        "TutorialService",
        "WorldService",
    }
do
    assert(
        services:FindFirstChild(serviceName) ~= nil,
        "game build is missing service " .. serviceName
    )
end
local worldBuilders = serverRoot:FindFirstChild("World")
assert(worldBuilders ~= nil, "game build is missing world builders")
assert(
    worldBuilders:FindFirstChild("BramblewakeBuilder") ~= nil,
    "game build is missing BramblewakeBuilder"
)
assert(gamePlace:GetService("Workspace").StreamingEnabled, "streaming must remain enabled")
local inputActionRollout =
    tostring(gamePlace:GetService("Workspace").PlayerScriptsUseInputActionSystem)
assert(
    inputActionRollout == "Enabled" or inputActionRollout == "Enum.RolloutState.Enabled",
    "Input Action System must be enabled"
)
assert(
    gamePlace:GetService("ReplicatedFirst"):FindFirstChild("LoadingController") ~= nil,
    "game build is missing the bounded loading controller"
)
local clientRoot =
    gamePlace:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("LastLightClient")
assert(clientRoot ~= nil, "game build is missing LastLightClient")
local controllers = clientRoot:FindFirstChild("Controllers")
assert(controllers ~= nil, "game build is missing client controllers")
for _, controllerName in { "HUDController", "InputController", "InteractionController" } do
    assert(
        controllers:FindFirstChild(controllerName) ~= nil,
        "game build is missing controller " .. controllerName
    )
end

local testPlace = loadPlace("build/LastLightTest.rbxlx")
local integrationScript =
    testPlace:GetService("ServerScriptService"):FindFirstChild("FoundationIntegration", true)
assert(integrationScript ~= nil, "test build is missing FoundationIntegration")
assert(
    testPlace:GetService("ReplicatedFirst"):FindFirstChild("LoadingController") ~= nil,
    "test build is missing the bounded loading controller"
)

print("[Last Light] Built DataModel verification passed")
