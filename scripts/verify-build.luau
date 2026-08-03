--!strict

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local function loadPlace(path: string)
    assert(fs.isFile(path), "missing built place " .. path)
    return roblox.deserializePlace(fs.readFile(path))
end

local gamePlace = loadPlace("build/LastLight.rbxlx")
assert(
    gamePlace:GetService("AssetService").AllowInsertFreeAssets,
    "Creator Store runtime assets must be enabled in the built place"
)
local replicatedStorage = gamePlace:GetService("ReplicatedStorage")
local serverScriptService = gamePlace:GetService("ServerScriptService")

local sharedRoot = replicatedStorage:FindFirstChild("LastLight")
assert(sharedRoot ~= nil, "game build is missing ReplicatedStorage.LastLight")
assert(sharedRoot:FindFirstChild("Config") ~= nil, "game build is missing Config")
assert(sharedRoot:FindFirstChild("Content") ~= nil, "game build is missing Content")
assert(sharedRoot:FindFirstChild("TutorialFlow") ~= nil, "game build is missing TutorialFlow")
assert(sharedRoot:FindFirstChild("SaveSchema") ~= nil, "game build is missing SaveSchema")
assert(sharedRoot:FindFirstChild("RuntimeIds") ~= nil, "game build is missing RuntimeIds")
assert(sharedRoot:FindFirstChild("AmbientMotion") ~= nil, "game build is missing AmbientMotion")
assert(sharedRoot:FindFirstChild("WeatherProfile") ~= nil, "game build is missing WeatherProfile")
assert(sharedRoot:FindFirstChild("ReviveFlow") ~= nil, "game build is missing ReviveFlow")
assert(sharedRoot:FindFirstChild("SurvivalState") ~= nil, "game build is missing SurvivalState")
assert(sharedRoot:FindFirstChild("CombatState") ~= nil, "game build is missing CombatState")
assert(
    sharedRoot:FindFirstChild("ProfessionCatalog") ~= nil,
    "game build is missing ProfessionCatalog"
)
assert(sharedRoot:FindFirstChild("ProfessionState") ~= nil, "game build is missing ProfessionState")
assert(sharedRoot:FindFirstChild("EnemyAttackFlow") ~= nil, "game build is missing EnemyAttackFlow")
assert(sharedRoot:FindFirstChild("EnemyMotion") ~= nil, "game build is missing EnemyMotion")
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
    sharedRoot:FindFirstChild("ExtractionPayoff") ~= nil,
    "game build is missing ExtractionPayoff"
)
assert(
    sharedRoot:FindFirstChild("ExpeditionInventory") ~= nil,
    "game build is missing ExpeditionInventory"
)
assert(
    sharedRoot:FindFirstChild("WardenStagEncounter") ~= nil,
    "game build is missing WardenStagEncounter"
)
assert(
    sharedRoot:FindFirstChild("BramblewakeBlackout") ~= nil,
    "game build is missing BramblewakeBlackout"
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
        "BramblewakeBlackoutService",
        "EnemyService",
        "ExpeditionService",
        "FeatureFlagService",
        "AdminService",
        "LobbyService",
        "Logger",
        "NetworkService",
        "PhaseService",
        "PlayerCombatService",
        "PlayerSurvivalService",
        "ProfessionService",
        "ProfileService",
        "TutorialService",
        "WardenStagService",
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
assert(
    worldBuilders:FindFirstChild("WardenStagBuilder") ~= nil,
    "game build is missing WardenStagBuilder"
)
assert(
    worldBuilders:FindFirstChild("MeshAssetRegistry") ~= nil,
    "game build is missing the measured mesh registry"
)
assert(
    worldBuilders:FindFirstChild("MeshTemplateLoader") ~= nil,
    "game build is missing the cached mesh loader"
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
for _, controllerName in
    {
        "AmbientController",
        "HUDController",
        "InputController",
        "InteractionController",
        "WeatherController",
        "WorldMotionController",
    }
do
    assert(
        controllers:FindFirstChild(controllerName) ~= nil,
        "game build is missing controller " .. controllerName
    )
end

local testPlace = loadPlace("build/LastLightTest.rbxlx")
assert(
    testPlace:GetService("AssetService").AllowInsertFreeAssets,
    "Creator Store runtime assets must be enabled in the test place"
)
local integrationScript =
    testPlace:GetService("ServerScriptService"):FindFirstChild("FoundationIntegration", true)
assert(integrationScript ~= nil, "test build is missing FoundationIntegration")

-- The Studio integration place only runs when a human presses Play, so a
-- version bump that forgets the literals in FoundationIntegration fails in the
-- owner's hands instead of in CI. Compare the asserted literals against Config
-- here, where every npm test runs.
local configSource = fs.readFile("src/shared/Config.luau")
local integrationSource = fs.readFile("tests/studio/FoundationIntegration.server.luau")
local configBuildVersion = assert(
    string.match(configSource, 'BuildVersion%s*=%s*"([^"]+)"'),
    "Config.luau no longer declares BuildVersion"
)
local configSchemaVersion = assert(
    string.match(configSource, "SaveSchemaVersion%s*=%s*(%d+)"),
    "Config.luau no longer declares SaveSchemaVersion"
)
local assertedBuildVersion = assert(
    string.match(integrationSource, 'Config%.BuildVersion%s*==%s*"([^"]+)"'),
    "FoundationIntegration no longer asserts Config.BuildVersion"
)
local assertedSchemaVersion = assert(
    string.match(integrationSource, "Config%.SaveSchemaVersion%s*==%s*(%d+)"),
    "FoundationIntegration no longer asserts Config.SaveSchemaVersion"
)
assert(
    assertedBuildVersion == configBuildVersion,
    string.format(
        "FoundationIntegration asserts build %s but Config declares %s -- update the Studio test",
        assertedBuildVersion,
        configBuildVersion
    )
)
assert(
    assertedSchemaVersion == configSchemaVersion,
    string.format(
        "FoundationIntegration asserts save schema %s but Config declares %s -- update the Studio test",
        assertedSchemaVersion,
        configSchemaVersion
    )
)
assert(
    testPlace:GetService("ReplicatedFirst"):FindFirstChild("LoadingController") ~= nil,
    "test build is missing the bounded loading controller"
)

print("[Last Light] Built DataModel verification passed")
