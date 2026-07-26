--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "shared root unavailable in Studio integration test")

local serverRoot = ServerScriptService:WaitForChild("LastLightServer", 8)
assert(serverRoot ~= nil, "server root unavailable in Studio integration test")

local Config = require(root.Config)
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
assert(runtime:FindFirstChild(RuntimeIds.Remotes.ActionRequest) ~= nil, "missing action remote")
assert(runtime:FindFirstChild(RuntimeIds.Remotes.StateChanged) ~= nil, "missing state remote")
assert(runtime:FindFirstChild(RuntimeIds.Remotes.GetState) ~= nil, "missing state function")

local world = workspace:WaitForChild(RuntimeIds.WorldName, 8)
assert(world ~= nil and world:IsA("Model"), "first-ten-minutes world did not build")
assert(world:GetAttribute("Ready") == true, "world model is not marked ready")
assert(world:FindFirstChild("ArrivalSpawn", true) ~= nil, "arrival spawn is missing")
assert(world:FindFirstChild("Mara", true) ~= nil, "Mara is missing")
assert(world:FindFirstChild("HeartwoodStump", true) ~= nil, "gather node is missing")
assert(world:FindFirstChild("ConstructionPlot", true) ~= nil, "construction plot is missing")
assert(world:FindFirstChild("FirstLantern", true) ~= nil, "First Lantern is missing")

local tagged = game:GetService("CollectionService"):GetTagged(RuntimeIds.InteractionTag)
assert(#tagged == 8, "expected eight tutorial interaction prompts")
assert(
    workspace.PlayerScriptsUseInputActionSystem == Enum.RolloutState.Enabled,
    "Input Action System must be enabled"
)

print("[Last Light] PASS FoundationIntegration")
