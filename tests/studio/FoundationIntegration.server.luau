--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "shared root unavailable in Studio integration test")

local serverRoot = ServerScriptService:WaitForChild("LastLightServer", 8)
assert(serverRoot ~= nil, "server root unavailable in Studio integration test")

local Config = require(root.Config)
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

print("[Last Light] PASS FoundationIntegration")
