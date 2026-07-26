--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "shared root unavailable in Studio integration test")

local serverRoot = ServerScriptService:WaitForChild("LastLightServer", 8)
assert(serverRoot ~= nil, "server root unavailable in Studio integration test")

local Config = require(root.Config)
local BramblewakeExpedition = require(root.Content.Definitions.BramblewakeExpedition)
local ExpeditionGenerator = require(root.ExpeditionGenerator)
local RuntimeIds = require(root.RuntimeIds)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)
local ServiceRegistry = require(serverRoot.ServiceRegistry)

local content = Registry.new(Regions)
assert(Config.SaveSchemaVersion == 1, "unexpected save schema version")
assert(content:count() == 7, "all launch region definitions must load")
assert(content:has("region_bramblewake"), "starter region is missing")

local calls = 0
local service = {
    Name = "StudioIntegrationService",
    Init = function()
        calls += 1
    end,
    Start = function()
        calls += 1
    end,
}

local services = ServiceRegistry.new({ integration = true })
services:register(service)
services:initialize()
services:start()

assert(calls == 2, "service lifecycle did not initialize and start")
assert(services:state() == "started", "service registry did not reach started state")

local runtime = ReplicatedStorage:WaitForChild(RuntimeIds.FolderName, 8)
assert(runtime ~= nil, "runtime networking folder did not initialize")
assert(runtime:GetAttribute("SchemaVersion") == 1, "unexpected network schema")
assert(runtime:GetAttribute("WorldReady") == true, "world never became ready")
local actionRequest = runtime:FindFirstChild(RuntimeIds.Remotes.ActionRequest)
local stateChanged = runtime:FindFirstChild(RuntimeIds.Remotes.StateChanged)
local getState = runtime:FindFirstChild(RuntimeIds.Remotes.GetState)
assert(actionRequest ~= nil and actionRequest:IsA("RemoteEvent"), "missing action remote")
assert(stateChanged ~= nil and stateChanged:IsA("RemoteEvent"), "missing state remote")
assert(getState ~= nil and getState:IsA("RemoteFunction"), "missing state function")

local world = workspace:WaitForChild(RuntimeIds.WorldName, 8)
assert(world ~= nil and world:IsA("Model"), "first-ten-minutes world did not build")
assert(world:GetAttribute("Ready") == true, "world model is not marked ready")
assert(world:FindFirstChild("ArrivalSpawn", true) ~= nil, "arrival spawn is missing")
assert(world:FindFirstChild("Mara", true) ~= nil, "Mara is missing")
assert(world:FindFirstChild("HeartwoodStump", true) ~= nil, "gather node is missing")
assert(world:FindFirstChild("ConstructionPlot", true) ~= nil, "construction plot is missing")
assert(world:FindFirstChild("FirstLantern", true) ~= nil, "First Lantern is missing")

local expedition = world:FindFirstChild("BramblewakeExpedition")
assert(expedition ~= nil and expedition:IsA("Model"), "Bramblewake expedition is missing")
assert(expedition:GetAttribute("Ready") == true, "Bramblewake expedition is not ready")
assert(
    expedition:GetAttribute("ModuleCount") == BramblewakeExpedition.ModuleCount,
    "Bramblewake module count is incorrect"
)
assert(
    expedition:GetAttribute("PointOfInterestCount") == BramblewakeExpedition.PointOfInterestCount,
    "Bramblewake POI count is incorrect"
)
assert(
    expedition:GetAttribute("EventCount") == BramblewakeExpedition.EventCount,
    "Bramblewake event count is incorrect"
)
local expectedManifest = ExpeditionGenerator.generate(Config.BramblewakePreviewSeed)
assert(
    expedition:GetAttribute("ManifestHash") == expectedManifest.hash,
    "Bramblewake manifest does not replay deterministically"
)
local generatedPartCount = expedition:GetAttribute("GeneratedPartCount")
assert(
    type(generatedPartCount) == "number"
        and generatedPartCount >= 200
        and generatedPartCount <= BramblewakeExpedition.PartBudget,
    "Bramblewake preview is outside its detailed mobile part budget"
)

local tagged = CollectionService:GetTagged(RuntimeIds.InteractionTag)
assert(#tagged == 8, "expected eight tutorial interaction prompts")
local expeditionModules = CollectionService:GetTagged(RuntimeIds.ExpeditionModuleTag)
assert(
    #expeditionModules == BramblewakeExpedition.ModuleCount,
    "expected twelve streamed expedition modules"
)
for _, module in expeditionModules do
    assert(module:IsA("Model"), "expedition module tag must only target models")
    assert(
        module.ModelStreamingMode == Enum.ModelStreamingMode.Atomic,
        "expedition modules must stream atomically"
    )
    assert(
        module:FindFirstChild("StreamingCellCollision") ~= nil,
        "expedition module is missing collision"
    )
    assert(
        module:FindFirstChild("CriticalPath") ~= nil,
        "expedition module is missing its connected critical path"
    )
end
assert(
    #CollectionService:GetTagged(RuntimeIds.ExpeditionPointOfInterestTag)
        == BramblewakeExpedition.PointOfInterestCount,
    "expected four Bramblewake points of interest"
)
assert(
    #CollectionService:GetTagged(RuntimeIds.ExpeditionEventTag) == BramblewakeExpedition.EventCount,
    "expected four Bramblewake event sockets"
)
assert(
    workspace.PlayerScriptsUseInputActionSystem == Enum.RolloutState.Enabled,
    "Input Action System must be enabled"
)

print("[Last Light] PASS FoundationIntegration")
