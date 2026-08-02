--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local paths = process.args
assert(#paths > 0, "usage: lune run scripts/sanitize_creator_store_model <model.rbxm> [...]")

local function unsafe(instance: Instance): boolean
    return instance:IsA("LuaSourceContainer")
        or instance:IsA("ProximityPrompt")
        or instance:IsA("ClickDetector")
        or instance:IsA("DragDetector")
        or instance:IsA("LayerCollector")
        or instance:IsA("GuiObject")
        or instance:IsA("Camera")
        or instance:IsA("ValueBase")
        or instance:IsA("Constraint")
        or instance:IsA("JointInstance")
        or instance:IsA("Humanoid")
        or instance:IsA("AnimationController")
        or instance:IsA("Sound")
        or instance:IsA("PostEffect")
        or instance:IsA("BodyMover")
end

for _, path in paths do
    assert(fs.isFile(path), "missing Creator Store model " .. path)
    local roots = roblox.deserializeModel(fs.readFile(path))
    local removed = 0
    for _, root in roots do
        local descendants = root:GetDescendants()
        for index = #descendants, 1, -1 do
            local descendant = descendants[index]
            if unsafe(descendant) then
                descendant:Destroy()
                removed += 1
            end
        end
    end
    fs.writeFile(path, roblox.serializeModel(roots))
    print(string.format("%s removed=%d", path, removed))
end
