--!strict

--[[
    Last Light title and loading screen.

    Runs from ReplicatedFirst, before the world exists, so it owns nothing but
    its own ScreenGui and builds every element from primitives -- no asset can
    fail to load here and leave a player staring at a blank screen.

    Two rules shape the whole file:

      * The PLAY button must always become reachable. Every wait below is
        bounded, and when a stage times out the screen says so and lets the
        player in anyway. A player must never be trapped behind this screen.
      * Progress is reported, not invented. The bar advances on real
        milestones (runtime replicated, client content loaded, world ready)
        and only creeps within the stage it has actually reached, so it stays
        honest while still never appearing frozen.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

-- Same palette the world is built from, so the title screen and the first
-- thing the player sees when it lifts belong to one game.
local NIGHT_HIGH = Color3.fromRGB(24, 33, 46)
local NIGHT_LOW = Color3.fromRGB(7, 10, 16)
local HORIZON = Color3.fromRGB(46, 62, 68)
local TREE_FAR = Color3.fromRGB(21, 31, 38)
local TREE_MID = Color3.fromRGB(13, 20, 26)
local TREE_NEAR = Color3.fromRGB(7, 11, 15)
local GROUND = Color3.fromRGB(9, 13, 16)
local AMBER = Color3.fromRGB(255, 181, 76)
local AMBER_PALE = Color3.fromRGB(255, 221, 154)
local AMBER_DEEP = Color3.fromRGB(198, 118, 40)
local FOXFIRE = Color3.fromRGB(94, 206, 176)
local CREAM = Color3.fromRGB(244, 230, 197)
local MUTED = Color3.fromRGB(139, 158, 150)
local IRON = Color3.fromRGB(38, 42, 46)

local STAGE_CONNECT = "REACHING EMBERHOLLOW"
local STAGE_CONTENT = "GATHERING THE DARK"
local STAGE_WORLD = "RAISING THE FIRST LANTERN"
local STAGE_READY = "THE LANTERN IS LIT"
local STAGE_SLOW = "THE FOREST IS SLOW TONIGHT"

-- Bounded because a stall must degrade into a playable game, never a lock.
local RUNTIME_TIMEOUT = 10
local TOTAL_TIMEOUT = 22

local reducedMotion = (GuiService :: any).ReducedMotionEnabled == true

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if playerGui == nil then
    return
end

local gui = Instance.new("ScreenGui")
gui.Name = "LastLightLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = playerGui

local function newFrame(parent: Instance, name: string, zIndex: number): Frame
    local instance = Instance.new("Frame")
    instance.Name = name
    instance.BackgroundColor3 = NIGHT_LOW
    instance.BorderSizePixel = 0
    instance.ZIndex = zIndex
    instance.Parent = parent
    return instance
end

local function round(instance: GuiObject, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function newText(
    parent: Instance,
    name: string,
    font: Enum.Font,
    color: Color3,
    zIndex: number
): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Font = font
    label.TextColor3 = color
    label.ZIndex = zIndex
    label.Parent = parent
    return label
end

local backdrop = newFrame(gui, "Backdrop", 1)
backdrop.Size = UDim2.fromScale(1, 1)
local skyGradient = Instance.new("UIGradient")
skyGradient.Rotation = 90
skyGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, NIGHT_HIGH),
    ColorSequenceKeypoint.new(0.62, NIGHT_LOW),
    ColorSequenceKeypoint.new(1, NIGHT_LOW),
})
skyGradient.Parent = backdrop

-- A low warm bloom on the horizon: the town the player is about to reach.
local horizonGlow = newFrame(backdrop, "HorizonGlow", 2)
horizonGlow.AnchorPoint = Vector2.new(0.5, 1)
horizonGlow.Position = UDim2.fromScale(0.5, 0.72)
horizonGlow.Size = UDim2.new(1.4, 0, 0, 260)
horizonGlow.BackgroundColor3 = HORIZON
horizonGlow.BackgroundTransparency = 0.55
local horizonGradient = Instance.new("UIGradient")
horizonGradient.Rotation = 90
horizonGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(1, 0.25),
})
horizonGradient.Parent = horizonGlow

--[[
    A conifer built from three stacked diamonds. Roblox UI has no triangle, but
    a square rotated 45 degrees is one, and three of them overlapping in
    decreasing size give the layered pine silhouette the world's treeline uses.
    Their lower halves are covered by the ground band, so they read as trees
    standing on the horizon rather than as floating shapes.
]]
local function conifer(
    parent: Instance,
    positionX: number,
    baseY: number,
    width: number,
    color: Color3,
    zIndex: number
)
    local tiers = 3
    for tier = 1, tiers do
        local scale = 1 - (tier - 1) * 0.24
        local side = width * scale
        local diamond = newFrame(parent, "Conifer", zIndex)
        diamond.AnchorPoint = Vector2.new(0.5, 0.5)
        diamond.Position = UDim2.new(positionX, 0, baseY, -(tier - 1) * width * 0.46)
        diamond.Size = UDim2.fromOffset(side, side)
        diamond.BackgroundColor3 = color
        diamond.Rotation = 45
    end
    local trunk = newFrame(parent, "ConiferTrunk", zIndex)
    trunk.AnchorPoint = Vector2.new(0.5, 0)
    trunk.Position = UDim2.fromScale(positionX, baseY)
    trunk.Size = UDim2.fromOffset(math.max(3, width * 0.1), width * 0.5)
    trunk.BackgroundColor3 = color
end

-- Three depth layers. Far trees are smaller, lighter and lower-contrast; near
-- trees are large and nearly black, which is what sells the distance.
local farLine = newFrame(backdrop, "TreelineFar", 3)
farLine.BackgroundTransparency = 1
farLine.Size = UDim2.fromScale(1, 1)
for index = 0, 15 do
    local seedX = -0.02 + index * 0.069
    local jitter = ((index * 37) % 11) / 11
    conifer(farLine, seedX, 0.7, 54 + jitter * 26, TREE_FAR, 3)
end

local midLine = newFrame(backdrop, "TreelineMid", 4)
midLine.BackgroundTransparency = 1
midLine.Size = UDim2.fromScale(1, 1)
for index = 0, 11 do
    local seedX = -0.04 + index * 0.095
    local jitter = ((index * 53) % 13) / 13
    conifer(midLine, seedX, 0.79, 84 + jitter * 40, TREE_MID, 4)
end

local nearLine = newFrame(backdrop, "TreelineNear", 5)
nearLine.BackgroundTransparency = 1
nearLine.Size = UDim2.fromScale(1, 1)
for index = 0, 7 do
    local seedX = -0.06 + index * 0.16
    local jitter = ((index * 29) % 7) / 7
    conifer(nearLine, seedX, 0.93, 128 + jitter * 62, TREE_NEAR, 5)
end

local ground = newFrame(backdrop, "Ground", 6)
ground.AnchorPoint = Vector2.new(0.5, 0)
ground.Position = UDim2.fromScale(0.5, 0.86)
ground.Size = UDim2.fromScale(1, 0.2)
ground.BackgroundColor3 = GROUND

-- Drifting foxfire and embers. Motion is the only thing telling the player the
-- screen is alive during a long load, so it keeps running even when progress
-- does not -- unless the player has asked for reduced motion.
type Mote = {
    frame: Frame,
    x: number,
    y: number,
    rise: number,
    drift: number,
    phase: number,
}

local motes: { Mote } = {}
if not reducedMotion then
    for index = 1, 26 do
        local ember = index % 3 == 0
        local size = if ember then 3 else 2 + (index % 3)
        local dot = newFrame(backdrop, "Mote", 7)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Size = UDim2.fromOffset(size, size)
        dot.BackgroundColor3 = if ember then AMBER else FOXFIRE
        dot.BackgroundTransparency = 0.3 + (index % 5) * 0.1
        round(dot, size)
        table.insert(motes, {
            frame = dot,
            x = ((index * 73) % 100) / 100,
            y = ((index * 41) % 100) / 100,
            rise = 0.012 + ((index * 17) % 10) / 800,
            drift = 0.006 + ((index * 23) % 8) / 1200,
            phase = ((index * 31) % 100) / 100 * math.pi * 2,
        })
    end
end

-- The First Lantern: the game's own icon, and the object the whole opening
-- sequence is about. Built in layers -- halo, cage, glass, flame -- so it reads
-- as a made object rather than a glowing circle.
local lantern = newFrame(backdrop, "FirstLantern", 8)
lantern.BackgroundTransparency = 1
lantern.AnchorPoint = Vector2.new(0.5, 0.5)
lantern.Position = UDim2.fromScale(0.5, 0.3)
lantern.Size = UDim2.fromOffset(260, 260)

local halo = newFrame(lantern, "Halo", 8)
halo.AnchorPoint = Vector2.new(0.5, 0.5)
halo.Position = UDim2.fromScale(0.5, 0.5)
halo.Size = UDim2.fromOffset(230, 230)
halo.BackgroundColor3 = AMBER
halo.BackgroundTransparency = 0.9
round(halo, 999)

local haloInner = newFrame(lantern, "HaloInner", 9)
haloInner.AnchorPoint = Vector2.new(0.5, 0.5)
haloInner.Position = UDim2.fromScale(0.5, 0.5)
haloInner.Size = UDim2.fromOffset(140, 140)
haloInner.BackgroundColor3 = AMBER
haloInner.BackgroundTransparency = 0.82
round(haloInner, 999)

local hook = newFrame(lantern, "LanternHook", 10)
hook.AnchorPoint = Vector2.new(0.5, 0.5)
hook.Position = UDim2.new(0.5, 0, 0.5, -74)
hook.Size = UDim2.fromOffset(22, 22)
hook.BackgroundTransparency = 1
round(hook, 999)
local hookStroke = Instance.new("UIStroke")
hookStroke.Color = IRON
hookStroke.Thickness = 4
hookStroke.Parent = hook

local cap = newFrame(lantern, "LanternCap", 11)
cap.AnchorPoint = Vector2.new(0.5, 0.5)
cap.Position = UDim2.new(0.5, 0, 0.5, -54)
cap.Size = UDim2.fromOffset(78, 16)
cap.BackgroundColor3 = IRON
round(cap, 4)

local glass = newFrame(lantern, "LanternGlass", 10)
glass.AnchorPoint = Vector2.new(0.5, 0.5)
glass.Position = UDim2.fromScale(0.5, 0.5)
glass.Size = UDim2.fromOffset(58, 84)
glass.BackgroundColor3 = AMBER_PALE
glass.BackgroundTransparency = 0.45
round(glass, 6)
local glassGradient = Instance.new("UIGradient")
glassGradient.Rotation = 90
glassGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.55),
    NumberSequenceKeypoint.new(1, 0),
})
glassGradient.Parent = glass

for postSide = -1, 1, 2 do
    local post = newFrame(lantern, "LanternPost", 12)
    post.AnchorPoint = Vector2.new(0.5, 0.5)
    post.Position = UDim2.new(0.5, postSide * 29, 0.5, 0)
    post.Size = UDim2.fromOffset(7, 92)
    post.BackgroundColor3 = IRON
    round(post, 2)
end

local flame = newFrame(lantern, "LanternFlame", 13)
flame.AnchorPoint = Vector2.new(0.5, 1)
flame.Position = UDim2.new(0.5, 0, 0.5, 26)
flame.Size = UDim2.fromOffset(18, 34)
flame.BackgroundColor3 = AMBER_PALE
round(flame, 999)

local base = newFrame(lantern, "LanternBase", 12)
base.AnchorPoint = Vector2.new(0.5, 0.5)
base.Position = UDim2.new(0.5, 0, 0.5, 50)
base.Size = UDim2.fromOffset(86, 14)
base.BackgroundColor3 = IRON
round(base, 4)

local title = newText(backdrop, "Title", Enum.Font.GothamBlack, CREAM, 14)
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.52)
title.Size = UDim2.new(0.9, 0, 0, 72)
title.Text = "LAST LIGHT"
title.TextScaled = true
local titleSize = Instance.new("UITextSizeConstraint")
titleSize.MinTextSize = 30
titleSize.MaxTextSize = 66
titleSize.Parent = title
local titleGradient = Instance.new("UIGradient")
titleGradient.Rotation = 90
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, CREAM),
    ColorSequenceKeypoint.new(1, AMBER),
})
titleGradient.Parent = title

local rule = newFrame(backdrop, "TitleRule", 14)
rule.AnchorPoint = Vector2.new(0.5, 0.5)
rule.Position = UDim2.fromScale(0.5, 0.585)
rule.Size = UDim2.new(0.42, 0, 0, 1)
rule.BackgroundColor3 = AMBER
rule.BackgroundTransparency = 0.35
local ruleGradient = Instance.new("UIGradient")
ruleGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1),
})
ruleGradient.Parent = rule

local tagline = newText(backdrop, "Tagline", Enum.Font.GothamMedium, MUTED, 14)
tagline.AnchorPoint = Vector2.new(0.5, 0.5)
tagline.Position = UDim2.fromScale(0.5, 0.632)
tagline.Size = UDim2.new(0.86, 0, 0, 22)
tagline.Text = "BUILD BY DAY · SURVIVE BY NIGHT · BRING EVERYONE HOME"
tagline.TextScaled = true
local taglineSize = Instance.new("UITextSizeConstraint")
taglineSize.MinTextSize = 9
taglineSize.MaxTextSize = 15
taglineSize.Parent = tagline

-- Progress and PLAY share one slot: the bar fills, then hands the space over to
-- the button. Nothing jumps around and the eye stays in one place.
local progressPanel = newFrame(backdrop, "ProgressPanel", 15)
progressPanel.BackgroundTransparency = 1
progressPanel.AnchorPoint = Vector2.new(0.5, 0.5)
progressPanel.Position = UDim2.fromScale(0.5, 0.77)
progressPanel.Size = UDim2.new(0.62, 0, 0, 64)
local panelWidth = Instance.new("UISizeConstraint")
panelWidth.MaxSize = Vector2.new(460, math.huge)
panelWidth.MinSize = Vector2.new(220, 0)
panelWidth.Parent = progressPanel

local stageLabel = newText(progressPanel, "Stage", Enum.Font.GothamBold, MUTED, 16)
stageLabel.AnchorPoint = Vector2.new(0, 1)
stageLabel.Position = UDim2.fromOffset(0, 22)
stageLabel.Size = UDim2.new(0.74, 0, 0, 16)
stageLabel.Text = STAGE_CONNECT
stageLabel.TextXAlignment = Enum.TextXAlignment.Left
stageLabel.TextSize = 12

local percentLabel = newText(progressPanel, "Percent", Enum.Font.GothamBold, AMBER, 16)
percentLabel.AnchorPoint = Vector2.new(1, 1)
percentLabel.Position = UDim2.new(1, 0, 0, 22)
percentLabel.Size = UDim2.new(0.24, 0, 0, 16)
percentLabel.Text = "0%"
percentLabel.TextXAlignment = Enum.TextXAlignment.Right
percentLabel.TextSize = 12

local track = newFrame(progressPanel, "Track", 16)
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.new(0.5, 0, 0, 30)
track.Size = UDim2.new(1, 0, 0, 8)
track.BackgroundColor3 = Color3.fromRGB(23, 30, 34)
round(track, 4)
local trackStroke = Instance.new("UIStroke")
trackStroke.Color = Color3.fromRGB(46, 58, 62)
trackStroke.Thickness = 1
trackStroke.Transparency = 0.35
trackStroke.Parent = track

local fill = newFrame(track, "Fill", 17)
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = AMBER
round(fill, 4)
local fillGradient = Instance.new("UIGradient")
fillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, AMBER_DEEP),
    ColorSequenceKeypoint.new(1, AMBER_PALE),
})
fillGradient.Parent = fill

local fillHead = newFrame(track, "FillHead", 18)
fillHead.AnchorPoint = Vector2.new(0.5, 0.5)
fillHead.Position = UDim2.fromScale(0, 0.5)
fillHead.Size = UDim2.fromOffset(3, 14)
fillHead.BackgroundColor3 = AMBER_PALE
fillHead.BackgroundTransparency = 1
round(fillHead, 2)

local playButton = Instance.new("TextButton")
playButton.Name = "Play"
playButton.AnchorPoint = Vector2.new(0.5, 0.5)
playButton.Position = UDim2.fromScale(0.5, 0.5)
playButton.Size = UDim2.fromScale(0, 0)
playButton.BackgroundColor3 = AMBER
playButton.AutoButtonColor = false
playButton.Font = Enum.Font.GothamBlack
playButton.Text = "PLAY"
playButton.TextColor3 = Color3.fromRGB(24, 18, 8)
playButton.TextSize = 22
playButton.Visible = false
playButton.Selectable = true
playButton.ZIndex = 20
playButton.Parent = progressPanel
round(playButton, 10)
local playGradient = Instance.new("UIGradient")
playGradient.Rotation = 90
playGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, AMBER_PALE),
    ColorSequenceKeypoint.new(1, AMBER_DEEP),
})
playGradient.Parent = playButton
local playStroke = Instance.new("UIStroke")
playStroke.Color = AMBER_PALE
playStroke.Thickness = 2
playStroke.Transparency = 0.4
playStroke.Parent = playButton

local playHint = newText(backdrop, "PlayHint", Enum.Font.Gotham, MUTED, 15)
playHint.AnchorPoint = Vector2.new(0.5, 0.5)
playHint.Position = UDim2.fromScale(0.5, 0.855)
playHint.Size = UDim2.new(0.8, 0, 0, 16)
playHint.Text = ""
playHint.TextSize = 12

local hint = newText(backdrop, "Hint", Enum.Font.Gotham, Color3.fromRGB(97, 114, 107), 15)
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -26)
hint.Size = UDim2.new(0.84, 0, 0, 34)
hint.Text = "Only the nearby clearing loads first. The wider forest streams in as you travel."
hint.TextWrapped = true
hint.TextSize = 12

-- Progress model: `reached` is what completed milestones guarantee, `ceiling`
-- is the milestone being worked toward. The bar creeps toward the ceiling but
-- can never cross it until that milestone actually lands.
local MILESTONES = { 0.34, 0.62, 0.92, 1 }
local milestoneIndex = 1
local reached = 0
local ceiling = MILESTONES[1]
local displayed = 0
local target = 0
local readyToPlay = false
local finished = false
local elapsed = 0

local function advance()
    if milestoneIndex > #MILESTONES then
        return
    end
    reached = MILESTONES[milestoneIndex]
    milestoneIndex += 1
    ceiling = MILESTONES[math.min(milestoneIndex, #MILESTONES)]
    target = math.max(target, reached)
end

local connections: { RBXScriptConnection } = {}

local function teardown()
    for _, connection in connections do
        connection:Disconnect()
    end
    table.clear(connections)
end

local function enablePlay(message: string)
    if readyToPlay then
        return
    end
    readyToPlay = true
    stageLabel.Text = message
    playHint.Text = if UserInputService.TouchEnabled
        then "TAP PLAY TO ENTER"
        else "PRESS ENTER OR CLICK PLAY"

    local hide = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(track, hide, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(trackStroke, hide, { Transparency = 1 }):Play()
    TweenService:Create(fill, hide, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(fillHead, hide, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(percentLabel, hide, { TextTransparency = 1 }):Play()

    playButton.Visible = true
    local grow = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local growTween = TweenService:Create(playButton, grow, { Size = UDim2.fromScale(1, 0.78) })
    -- Wait for the button to have a size before handing it controller focus.
    -- Selecting it while it is still scaled to zero logs "Setting
    -- GuiService.SelectedObject to invalid GuiObject" and the focus does not
    -- take, which would leave a gamepad player unable to reach PLAY.
    growTween.Completed:Connect(function()
        if playButton.Parent ~= nil and playButton.Visible then
            pcall(function()
                GuiService.SelectedObject = playButton
            end)
        end
    end)
    growTween:Play()
end

local function dismiss()
    if finished then
        return
    end
    finished = true
    teardown()
    pcall(function()
        if GuiService.SelectedObject == playButton then
            GuiService.SelectedObject = nil
        end
    end)

    local fade = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, descendant in gui:GetDescendants() do
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
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
    task.delay(0.55, function()
        gui:Destroy()
    end)
end

table.insert(connections, playButton.Activated:Connect(dismiss))
table.insert(
    connections,
    playButton.MouseEnter:Connect(function()
        if readyToPlay then
            playStroke.Transparency = 0
        end
    end)
)
table.insert(
    connections,
    playButton.MouseLeave:Connect(function()
        playStroke.Transparency = 0.4
    end)
)
table.insert(
    connections,
    UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
        if processed or not readyToPlay then
            return
        end
        if
            input.KeyCode == Enum.KeyCode.Return
            or input.KeyCode == Enum.KeyCode.Space
            or input.KeyCode == Enum.KeyCode.ButtonA
        then
            dismiss()
        end
    end)
)

table.insert(
    connections,
    RunService.RenderStepped:Connect(function(deltaTime: number)
        elapsed += deltaTime

        -- Creep toward, but never across, the milestone actually being awaited.
        if not readyToPlay then
            target = math.max(reached, math.min(ceiling - 0.03, target + deltaTime * 0.05))
        end
        displayed += (target - displayed) * math.min(1, deltaTime * 4)
        fill.Size = UDim2.fromScale(math.clamp(displayed, 0, 1), 1)
        fillHead.Position = UDim2.fromScale(math.clamp(displayed, 0, 1), 0.5)
        fillHead.BackgroundTransparency = if displayed > 0.01 and not readyToPlay then 0.25 else 1
        percentLabel.Text = string.format("%d%%", math.floor(math.clamp(displayed, 0, 1) * 100))

        if reducedMotion then
            return
        end

        local breath = math.sin(elapsed * 1.6) * 0.5 + 0.5
        local flicker = math.sin(elapsed * 9.1) * 0.5 + 0.5
        halo.BackgroundTransparency = 0.9 - breath * 0.06
        halo.Size = UDim2.fromOffset(226 + breath * 14, 226 + breath * 14)
        haloInner.BackgroundTransparency = 0.84 - breath * 0.08
        flame.Size = UDim2.fromOffset(17 + flicker * 3, 31 + flicker * 6)
        glass.BackgroundTransparency = 0.47 - breath * 0.06

        for _, mote in motes do
            mote.y -= mote.rise * deltaTime
            if mote.y < -0.05 then
                mote.y = 1.05
            end
            local sway = math.sin(elapsed * 0.6 + mote.phase) * mote.drift
            mote.frame.Position = UDim2.fromScale(mote.x + sway, mote.y)
        end
    end)
)

-- Stage 1: the runtime folder replicating means the server is answering.
local runtime: Instance? = nil
local startedAt = os.clock()
while runtime == nil and os.clock() - startedAt < RUNTIME_TIMEOUT do
    runtime = ReplicatedStorage:FindFirstChild("LastLightRuntime")
    if runtime == nil then
        task.wait(0.1)
    end
end
if runtime ~= nil then
    advance()
end

-- Stage 2: the client's own content finished streaming in.
stageLabel.Text = STAGE_CONTENT
while not game:IsLoaded() and os.clock() - startedAt < TOTAL_TIMEOUT do
    task.wait(0.1)
end
if game:IsLoaded() then
    advance()
end

-- Stage 3: the server says the arrival clearing is built and safe to stand in.
stageLabel.Text = STAGE_WORLD
if runtime ~= nil then
    while runtime:GetAttribute("WorldReady") ~= true and os.clock() - startedAt < TOTAL_TIMEOUT do
        task.wait(0.1)
    end
    if runtime:GetAttribute("WorldReady") == true then
        advance()
    end
end

-- However the stages went, the player gets in. A timed-out load says so rather
-- than pretending, but it still hands over a working PLAY button.
local worldReady = runtime ~= nil and runtime:GetAttribute("WorldReady") == true
reached = 1
ceiling = 1
target = 1
advance()
task.wait(0.35)
enablePlay(if worldReady then STAGE_READY else STAGE_SLOW)
if not worldReady then
    hint.Text = "The forest is still settling. You can enter now; it will finish around you."
end
