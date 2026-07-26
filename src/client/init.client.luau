--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "Last Light shared root did not replicate before client bootstrap timeout")

local Config = require(root.Config)
print(string.format("[Last Light] Client boot %s", Config.BuildVersion))
