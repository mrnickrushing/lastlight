--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "Last Light shared root did not replicate before client bootstrap timeout")

local Config = require(root.Config)
local RuntimeIds = require(root.RuntimeIds)
local HUDController = require(script.Controllers.HUDController)
local InputController = require(script.Controllers.InputController)
local InteractionController = require(script.Controllers.InteractionController)

local runtime =
    ReplicatedStorage:WaitForChild(RuntimeIds.FolderName, Config.BootstrapTimeoutSeconds)
assert(runtime ~= nil, "Last Light runtime did not replicate before client bootstrap timeout")

local actionRequest =
    runtime:WaitForChild(RuntimeIds.Remotes.ActionRequest, Config.BootstrapTimeoutSeconds)
local stateChanged =
    runtime:WaitForChild(RuntimeIds.Remotes.StateChanged, Config.BootstrapTimeoutSeconds)
local getState = runtime:WaitForChild(RuntimeIds.Remotes.GetState, Config.BootstrapTimeoutSeconds)
assert(actionRequest ~= nil and actionRequest:IsA("RemoteEvent"), "missing ActionRequest")
assert(stateChanged ~= nil and stateChanged:IsA("RemoteEvent"), "missing StateChanged")
assert(getState ~= nil and getState:IsA("RemoteFunction"), "missing GetState")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", Config.BootstrapTimeoutSeconds)
assert(playerGui ~= nil and playerGui:IsA("PlayerGui"), "PlayerGui unavailable")

local hud = HUDController.new(playerGui)
local interaction = InteractionController.new(RuntimeIds.InteractionTag, hud)

local function send(kind: string, fields: { [string]: any }?)
    local payload = fields or {}
    payload.schemaVersion = 1
    payload.kind = kind
    actionRequest:FireServer(payload)
end

InputController.new(hud, function()
    local interactionId = interaction:currentInteractionId()
    if interactionId ~= nil then
        send(RuntimeIds.Actions.Interact, { interactionId = interactionId })
    end
end, function()
    send(RuntimeIds.Actions.UseTool)
end, function(enabled: boolean)
    send(RuntimeIds.Actions.Sprint, { enabled = enabled })
end, function()
    send(RuntimeIds.Actions.Dodge)
end)

hud:setCompactHandler(function(enabled: boolean)
    send(RuntimeIds.Actions.CompactHud, { enabled = enabled })
end)

stateChanged.OnClientEvent:Connect(function(snapshot: any)
    hud:update(snapshot)
end)

task.spawn(function()
    local ok, snapshot = pcall(function()
        return getState:InvokeServer()
    end)
    if ok and snapshot ~= nil then
        hud:update(snapshot)
    end
end)

print(string.format("[Last Light] Client boot %s", Config.BuildVersion))
