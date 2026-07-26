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
assert(
    serverScriptService:FindFirstChild("LastLightServer") ~= nil,
    "game build is missing LastLightServer"
)
assert(gamePlace:GetService("Workspace").StreamingEnabled, "streaming must remain enabled")

local testPlace = loadPlace("build/LastLightTest.rbxlx")
local integrationScript =
    testPlace:GetService("ServerScriptService"):FindFirstChild("FoundationIntegration", true)
assert(integrationScript ~= nil, "test build is missing FoundationIntegration")

print("[Last Light] Built DataModel verification passed")
