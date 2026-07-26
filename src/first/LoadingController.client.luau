--!strict

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local gui = Instance.new("ScreenGui")
gui.Name = "LastLightLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(10, 20, 24)
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local glow = Instance.new("Frame")
glow.Name = "LanternGlow"
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.42)
glow.Size = UDim2.fromOffset(118, 118)
glow.BackgroundColor3 = Color3.fromRGB(255, 181, 76)
glow.BackgroundTransparency = 0.12
glow.BorderSizePixel = 0
glow.Parent = backdrop
local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(1, 0)
glowCorner.Parent = glow
local glowStroke = Instance.new("UIStroke")
glowStroke.Color = Color3.fromRGB(255, 221, 154)
glowStroke.Thickness = 4
glowStroke.Transparency = 0.2
glowStroke.Parent = glow

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.56)
title.Size = UDim2.new(0.86, 0, 0, 64)
title.Font = Enum.Font.GothamBold
title.Text = "LAST LIGHT"
title.TextColor3 = Color3.fromRGB(244, 230, 197)
title.TextScaled = true
title.Parent = backdrop
local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MinTextSize = 28
titleConstraint.MaxTextSize = 48
titleConstraint.Parent = title

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.67)
status.Size = UDim2.new(0.84, 0, 0, 58)
status.Font = Enum.Font.GothamMedium
status.Text = "CONNECTING TO EMBERHOLLOW"
status.TextColor3 = Color3.fromRGB(178, 194, 183)
status.TextSize = 17
status.TextWrapped = true
status.Parent = backdrop

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -36)
hint.Size = UDim2.new(0.86, 0, 0, 54)
hint.Font = Enum.Font.Gotham
hint.Text = "Only the nearby clearing loads first. The wider forest streams in as you travel."
hint.TextColor3 = Color3.fromRGB(123, 145, 135)
hint.TextSize = 14
hint.TextWrapped = true
hint.Parent = backdrop

ReplicatedFirst:RemoveDefaultLoadingScreen()

local startedAt = os.clock()
local runtime: Instance? = nil
while runtime == nil and os.clock() - startedAt < 8 do
    runtime = ReplicatedStorage:FindFirstChild("LastLightRuntime")
    if runtime == nil then
        status.Text = if os.clock() - startedAt < 2
            then "CONNECTING TO EMBERHOLLOW"
            else "LOADING YOUR FIRST LIGHT"
        task.wait(0.1)
    end
end

if runtime ~= nil then
    status.Text = "PREPARING THE NEARBY CLEARING"
    while runtime:GetAttribute("WorldReady") ~= true and os.clock() - startedAt < 12 do
        task.wait(0.1)
    end
end

if runtime == nil or runtime:GetAttribute("WorldReady") ~= true then
    status.Text = "THE FOREST IS TAKING LONGER — SAFE PLAY WILL CONTINUE"
    task.wait(2)
else
    status.Text = "THE FIRST LIGHT IS READY"
    task.wait(0.45)
end

local fade = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
for _, descendant in gui:GetDescendants() do
    if descendant:IsA("TextLabel") then
        TweenService:Create(descendant, fade, {
            TextTransparency = 1,
            BackgroundTransparency = 1,
        }):Play()
    elseif descendant:IsA("Frame") then
        TweenService:Create(descendant, fade, { BackgroundTransparency = 1 }):Play()
    elseif descendant:IsA("UIStroke") then
        TweenService:Create(descendant, fade, { Transparency = 1 }):Play()
    end
end
task.wait(0.5)
gui:Destroy()
