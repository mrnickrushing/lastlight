--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedRoot = ReplicatedStorage:WaitForChild("LastLight")
local Consumables = require(sharedRoot.Consumables)
local Equipment = require(sharedRoot.Equipment)

-- How many consumables the column shows at once. There are more than a
-- phone screen has room for, so the HUD shows what a player is actually
-- carrying, in catalog order, and stops at four.
local MAX_USE_BUTTONS = 4

local HUDController = {}
HUDController.__index = HUDController

local function createItemIcon(parent: Instance, itemId: string, size: number): ViewportFrame
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "ItemIcon"
    viewport.Size = UDim2.fromOffset(size, size)
    viewport.Position = UDim2.fromOffset(6, 5)
    viewport.BackgroundColor3 = Color3.fromRGB(20, 31, 29)
    viewport.BackgroundTransparency = 0.12
    viewport.BorderSizePixel = 0
    viewport.Ambient = Color3.fromRGB(210, 220, 210)
    viewport.LightColor = Color3.fromRGB(255, 220, 160)
    viewport.ZIndex = parent:IsA("GuiObject") and parent.ZIndex + 1 or 1
    viewport.Parent = parent

    local world = Instance.new("WorldModel")
    world.Parent = viewport
    local camera = Instance.new("Camera")
    camera.CFrame = CFrame.new(0, 0.4, 6) * CFrame.Angles(0, math.rad(18), 0)
    camera.FieldOfView = 28
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local function shape(name: string, dimensions: Vector3, position: Vector3, color: Color3)
        local object = Instance.new("Part")
        object.Name = name
        object.Anchored = true
        object.CanCollide = false
        object.Size = dimensions
        object.Position = position
        object.Color = color
        object.Material = Enum.Material.SmoothPlastic
        object.Parent = world
        return object
    end

    if itemId == "gear_meadow_satchel" then
        shape(
            "Bag",
            Vector3.new(2.5, 1.8, 1.2),
            Vector3.new(0, 0, 0),
            Color3.fromRGB(133, 176, 108)
        )
        shape(
            "Flap",
            Vector3.new(2.1, 0.25, 1.25),
            Vector3.new(0, 0.95, -0.05),
            Color3.fromRGB(94, 128, 78)
        )
        shape(
            "Strap",
            Vector3.new(0.25, 2.6, 0.25),
            Vector3.new(0, 0.15, 0.7),
            Color3.fromRGB(73, 48, 36)
        )
    elseif itemId == "gear_amber_charm" then
        local gem = shape(
            "Amber",
            Vector3.new(1.4, 1.4, 1.4),
            Vector3.new(0, 0, 0),
            Color3.fromRGB(255, 181, 76)
        )
        gem.Shape = Enum.PartType.Ball
        local ring = shape(
            "Ring",
            Vector3.new(0.28, 2.2, 2.2),
            Vector3.new(0, 0, 0),
            Color3.fromRGB(94, 206, 176)
        )
        ring.Shape = Enum.PartType.Cylinder
        ring.Orientation = Vector3.new(0, 0, 90)
    elseif Consumables.get(itemId) ~= nil and itemId ~= "gear_amber_charm" then
        --[[
            Every consumable after the first two draws from its own entry
            rather than from a branch here: a flask in the catalog's own
            colour, banded so the three kinds read apart at icon size.
        ]]
        local definition = Consumables.get(itemId) :: any
        local accent =
            Color3.fromRGB(definition.accent[1], definition.accent[2], definition.accent[3])
        shape("Flask", Vector3.new(1.5, 1.9, 1.5), Vector3.new(0, -0.1, 0), accent)
        shape(
            "Neck",
            Vector3.new(0.6, 0.7, 0.6),
            Vector3.new(0, 1.1, 0),
            Color3.fromRGB(73, 48, 36)
        )
        local band = shape(
            "Band",
            Vector3.new(1.62, 0.34, 1.62),
            Vector3.new(0, if definition.effect.kind == "shield" then 0.35 else -0.45, 0),
            Color3.fromRGB(236, 232, 220)
        )
        band.Transparency = 0.1
    elseif itemId == "gear_thornwood_bow" then
        shape(
            "Stave",
            Vector3.new(0.35, 2.6, 0.5),
            Vector3.new(0.2, 0, 0),
            Color3.fromRGB(112, 84, 52)
        )
        shape(
            "String",
            Vector3.new(0.12, 2.4, 0.12),
            Vector3.new(-0.45, 0, 0),
            Color3.fromRGB(214, 205, 186)
        )
    elseif itemId == "gear_heartwood_maul" then
        shape(
            "Haft",
            Vector3.new(0.35, 2.8, 0.35),
            Vector3.new(-0.2, -0.2, 0),
            Color3.fromRGB(96, 68, 44)
        )
        shape(
            "Head",
            Vector3.new(1.6, 0.95, 0.95),
            Vector3.new(0.15, 1.15, 0),
            Color3.fromRGB(139, 98, 54)
        )
    elseif itemId == "gear_briar_lance" then
        shape(
            "Shaft",
            Vector3.new(0.28, 3.2, 0.28),
            Vector3.new(0, -0.2, 0),
            Color3.fromRGB(104, 128, 68)
        )
        shape("Tip", Vector3.new(0.5, 0.8, 0.5), Vector3.new(0, 1.7, 0), Color3.fromRGB(74, 96, 46))
    elseif itemId == "gear_foxfire_sling" then
        shape(
            "Strap",
            Vector3.new(0.22, 2.4, 0.22),
            Vector3.new(0.25, 0.2, 0),
            Color3.fromRGB(78, 58, 41)
        )
        local pouch = shape(
            "Pouch",
            Vector3.new(1, 1, 1),
            Vector3.new(-0.45, -0.85, 0),
            Color3.fromRGB(94, 206, 176)
        )
        pouch.Shape = Enum.PartType.Ball
    elseif itemId == "gear_amber_edge" then
        shape(
            "Grip",
            Vector3.new(0.35, 1, 0.35),
            Vector3.new(0, -1.15, 0),
            Color3.fromRGB(73, 54, 38)
        )
        shape(
            "Blade",
            Vector3.new(0.3, 2.3, 0.75),
            Vector3.new(0, 0.55, 0),
            Color3.fromRGB(255, 197, 106)
        )
    elseif itemId == "gear_warden_cudgel" then
        shape(
            "Shaft",
            Vector3.new(0.4, 2.5, 0.4),
            Vector3.new(0, -0.4, 0),
            Color3.fromRGB(91, 62, 40)
        )
        local head = shape(
            "Head",
            Vector3.new(1.05, 1.05, 1.05),
            Vector3.new(0.1, 1.25, 0),
            Color3.fromRGB(112, 151, 119)
        )
        head.Shape = Enum.PartType.Ball
    elseif itemId == "gear_ironroot_hood" then
        shape(
            "Hood",
            Vector3.new(2.4, 1.8, 1.8),
            Vector3.new(0, 0.1, 0),
            Color3.fromRGB(76, 101, 88)
        )
        shape(
            "Rim",
            Vector3.new(2.6, 0.25, 1.9),
            Vector3.new(0, -0.82, -0.1),
            Color3.fromRGB(44, 62, 54)
        )
    else
        shape(
            "BootLeft",
            Vector3.new(0.9, 1.7, 1.8),
            Vector3.new(-0.65, -0.05, 0),
            Color3.fromRGB(142, 112, 84)
        )
        shape(
            "BootRight",
            Vector3.new(0.9, 1.7, 1.8),
            Vector3.new(0.65, -0.05, 0),
            Color3.fromRGB(116, 86, 63)
        )
    end
    return viewport
end

local COLORS = {
    ink = Color3.fromRGB(14, 22, 21),
    panel = Color3.fromRGB(20, 31, 29),
    panelSoft = Color3.fromRGB(28, 43, 39),
    cream = Color3.fromRGB(244, 230, 197),
    muted = Color3.fromRGB(178, 194, 183),
    amber = Color3.fromRGB(255, 181, 76),
    green = Color3.fromRGB(91, 166, 116),
    danger = Color3.fromRGB(220, 86, 71),
    blue = Color3.fromRGB(104, 177, 190),
}

local function corner(parent: Instance, radius: number)
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, radius)
    uiCorner.Parent = parent
end

local function stroke(parent: Instance, color: Color3, transparency: number)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = color
    uiStroke.Transparency = transparency
    uiStroke.Thickness = 1.5
    uiStroke.Parent = parent
end

local function textLabel(
    parent: Instance,
    name: string,
    text: string,
    size: UDim2,
    position: UDim2,
    textSize: number,
    color: Color3,
    alignment: Enum.TextXAlignment?
): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = position
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = color
    label.TextSize = textSize
    label.TextWrapped = true
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function actionButton(
    parent: Instance,
    name: string,
    text: string,
    size: number,
    position: UDim2,
    anchor: Vector2
): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.AnchorPoint = anchor
    button.Position = position
    button.Size = UDim2.fromOffset(size, size)
    button.AutoButtonColor = true
    button.BackgroundColor3 = COLORS.panel
    button.BackgroundTransparency = 0.04
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = COLORS.cream
    button.TextSize = 18
    button.TextWrapped = true
    button.ZIndex = 10
    button.Parent = parent
    corner(button, math.floor(size / 2))
    stroke(button, COLORS.amber, 0.1)
    return button
end

--[[
    The canvas is a 720-point-tall design surface stretched over the real
    viewport, and it is WIDER than the screen by exactly 1/scale -- so what a
    hardcoded offset has to fit inside is the canvas's width in points, not
    the viewport's in pixels. On the owner's portrait phone that width is
    about 500 points, which is a third of what the desktop clusters in here
    were written against. Both the scale rule and the width it implies live
    in one place so no caller can measure against a different screen.
]]
local function canvasMetrics(): (Vector2, number, number, number)
    local camera = workspace.CurrentCamera
    local viewport = if camera == nil then Vector2.new(1280, 720) else camera.ViewportSize
    local scale = math.clamp(math.min(viewport.X, viewport.Y) / 720, 0.78, 1)
    return viewport, scale, viewport.X / scale, viewport.Y / scale
end

-- Tall enough for the largest button in the run (the 116-point primary) plus
-- a gap, so a wrapped row can never be drawn through the row below it.
local ACTION_ROW_PITCH = 128

export type HUDController = typeof(setmetatable(
    {} :: {
        _gui: ScreenGui,
        _actionFrame: Frame,
        _actionLabel: TextLabel,
        _actionFill: Frame,
        _canvas: Frame,
        _scale: UIScale,
        _phaseFrame: Frame,
        _phase: TextLabel,
        _objectiveFrame: Frame,
        _objective: TextLabel,
        _detail: TextLabel,
        _progress: TextLabel,
        _mara: TextLabel,
        _resource: TextLabel,
        _health: TextLabel,
        _staminaFrame: Frame,
        _staminaFill: Frame,
        _staminaText: TextLabel,
        _toast: TextLabel,
        _lanternFrame: Frame,
        _lanternFill: Frame,
        _lanternText: TextLabel,
        _blackoutFrame: Frame,
        _blackoutFill: Frame,
        _blackoutTitle: TextLabel,
        _blackoutDetail: TextLabel,
        _eliteFrame: Frame,
        _eliteFill: Frame,
        _eliteTitle: TextLabel,
        _eliteDetail: TextLabel,
        _allyFrame: Frame,
        _allyTitle: TextLabel,
        _allyDetail: TextLabel,
        _threatFrame: Frame,
        _threatTitle: TextLabel,
        _threatDetail: TextLabel,
        _downedFrame: Frame,
        _downedFill: Frame,
        _downedTimer: TextLabel,
        _downedDetail: TextLabel,
        _downedAlly: TextLabel,
        _primary: TextButton,
        _tool: TextButton,
        _sprint: TextButton,
        _dodge: TextButton,
        _ability: TextButton,
        _companion: TextButton,
        _companionMode: string,
        _onCompanionCommand: ((string) -> ())?,
        _compact: TextButton,
        _professionButton: TextButton,
        _lobbyFrame: Frame,
        _lobbyTitle: TextLabel,
        _lobbyDetail: TextLabel,
        _lobbySizes: Frame,
        _lobbySizeButtons: { TextButton },
        _contractButtons: { [string]: TextButton },
        _selectedContractId: string,
        _onLobbyDepart: ((number) -> ())?,
        _selectedPartySize: number?,
        _partyLine: TextLabel,
        _partyButtons: { [string]: TextButton },
        _progressButton: TextButton,
        _useButtons: { TextButton },
        _professionOverlay: Frame,
        _professionPanel: Frame,
        _professionCards: { [string]: TextButton },
        _professionOrder: { string },
        _professionClose: TextButton,
        _progressOverlay: Frame,
        _progressPanel: Frame,
        _progressScroll: ScrollingFrame,
        _progressClose: TextButton,
        _progressText: TextLabel,
        _equipmentButtons: { [string]: TextButton },
        _loadoutButtons: { [string]: TextButton },
        _whetButton: TextButton,
        _whetItemId: string?,
        _onWhet: ((string) -> ())?,
        _currentState: any,
        _interactionLabel: string?,
        _interactionAvailable: boolean,
        _inputMode: string,
        _maraText: string,
        _maraShownAt: number,
        _compactEnabled: boolean,
        _playerDowned: boolean,
        _combatContext: boolean,
        _professionMenuOpen: boolean,
        _professionSwitchable: boolean,
        _lastToastRevision: number,
        _lastPhase: string?,
        _onCompact: ((boolean) -> ())?,
        _onProfessionSelected: ((string) -> ())?,
        _onEquip: ((string) -> ())?,
    },
    HUDController
))

function HUDController.new(
    playerGui: PlayerGui,
    professions: { any },
    contracts: { any }?
): HUDController
    local existing = playerGui:FindFirstChild("LastLightHUD")
    if existing ~= nil then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LastLightHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 20
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function()
        gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
        gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
    end)
    gui.Parent = playerGui

    --[[
        The canvas is sized in _layout to compensate for its own UIScale.

        A UIScale shrinks its subtree toward the top-left corner, so at 0.78 a
        full-screen canvas only paints the top-left 78% of the screen. Every
        bottom-anchored control -- run, dodge, strike, the primary action --
        was therefore floating roughly a fifth of the way up the screen on a
        phone, over the play area and the player's own character, while
        Roblox's jump button stayed at the true bottom edge. Growing the canvas
        by the inverse of the scale puts its edges back on the screen edges.
    ]]
    local canvas = Instance.new("Frame")
    canvas.Name = "SafeCanvas"
    canvas.BackgroundTransparency = 1
    canvas.Size = UDim2.fromScale(1, 1)
    canvas.Parent = gui

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = canvas

    local phaseFrame = Instance.new("Frame")
    phaseFrame.Name = "PhaseCapsule"
    phaseFrame.AnchorPoint = Vector2.new(0.5, 0)
    phaseFrame.Position = UDim2.new(0.5, 0, 0, 12)
    phaseFrame.Size = UDim2.fromOffset(206, 46)
    phaseFrame.BackgroundColor3 = COLORS.panel
    phaseFrame.BackgroundTransparency = 0.08
    phaseFrame.Parent = canvas
    corner(phaseFrame, 23)
    stroke(phaseFrame, COLORS.amber, 0.28)
    local phase = textLabel(
        phaseFrame,
        "Phase",
        "DAY · MORNING",
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0),
        17,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    phase.Font = Enum.Font.GothamBold

    local objectiveFrame = Instance.new("Frame")
    objectiveFrame.Name = "ObjectiveCard"
    objectiveFrame.Position = UDim2.fromOffset(18, 18)
    objectiveFrame.Size = UDim2.fromOffset(326, 132)
    objectiveFrame.BackgroundColor3 = COLORS.panel
    objectiveFrame.BackgroundTransparency = 0.1
    objectiveFrame.Parent = canvas
    corner(objectiveFrame, 16)
    stroke(objectiveFrame, COLORS.cream, 0.72)

    local progress = textLabel(
        objectiveFrame,
        "Progress",
        "FIRST LIGHT · 1 / 8",
        UDim2.new(1, -28, 0, 24),
        UDim2.fromOffset(14, 8),
        12,
        COLORS.amber
    )
    progress.Font = Enum.Font.GothamBold
    local objective = textLabel(
        objectiveFrame,
        "Objective",
        "FREE MARA",
        UDim2.new(1, -28, 0, 44),
        UDim2.fromOffset(14, 28),
        26,
        COLORS.cream
    )
    objective.Font = Enum.Font.GothamBold
    -- Long objectives were being clipped rather than fitted: the card gave
    -- this line 34 pixels, which holds exactly one line even at the 16-pixel
    -- floor (two 16-pixel lines need ~38 with line spacing), so "TAKE
    -- ROOTFIRE FROM THE BLACKOUT LANTERN" rendered as "TAKE ROOTFIRE FROM
    -- THE". 44 pixels holds two floor-size lines, keeping short objectives at
    -- full size and letting a long one wrap instead of disappearing.
    objective.TextScaled = true
    local objectiveFit = Instance.new("UITextSizeConstraint")
    objectiveFit.MaxTextSize = 26
    objectiveFit.MinTextSize = 16
    objectiveFit.Parent = objective
    local detail = textLabel(
        objectiveFrame,
        "Detail",
        "Follow the lantern path.",
        UDim2.new(1, -28, 0, 42),
        UDim2.fromOffset(14, 76),
        18,
        COLORS.muted
    )
    detail.TextYAlignment = Enum.TextYAlignment.Top

    local mara = textLabel(
        canvas,
        "MaraGuide",
        "Mara: Follow the light.",
        UDim2.fromOffset(430, 48),
        UDim2.new(0.5, 0, 1, -164),
        15,
        COLORS.cream
    )
    mara.BackgroundColor3 = COLORS.ink
    mara.BackgroundTransparency = 0.24
    mara.TextXAlignment = Enum.TextXAlignment.Center
    mara.AnchorPoint = Vector2.new(0.5, 1)
    corner(mara, 12)
    stroke(mara, COLORS.amber, 0.55)

    local resource = textLabel(
        canvas,
        "ResourcePill",
        "HEARTWOOD · 0",
        UDim2.fromOffset(176, 40),
        UDim2.fromOffset(18, 164),
        14,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    resource.BackgroundColor3 = COLORS.panel
    resource.BackgroundTransparency = 0.08
    corner(resource, 20)
    stroke(resource, COLORS.amber, 0.42)

    local health = textLabel(
        canvas,
        "HealthPill",
        "HEALTH · 100 / 100",
        UDim2.fromOffset(150, 40),
        UDim2.new(0, 18, 1, -100),
        13,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    health.AnchorPoint = Vector2.new(0, 1)
    health.BackgroundColor3 = COLORS.panel
    health.BackgroundTransparency = 0.08
    health.Font = Enum.Font.GothamBold
    health.Visible = false
    corner(health, 20)
    stroke(health, COLORS.green, 0.34)

    local staminaFrame = Instance.new("Frame")
    staminaFrame.Name = "StaminaRail"
    staminaFrame.AnchorPoint = Vector2.new(0, 1)
    staminaFrame.Position = UDim2.new(0, 18, 1, -148)
    staminaFrame.Size = UDim2.fromOffset(220, 34)
    staminaFrame.BackgroundColor3 = COLORS.ink
    staminaFrame.BackgroundTransparency = 0.08
    staminaFrame.Visible = false
    staminaFrame.Parent = canvas
    corner(staminaFrame, 17)
    stroke(staminaFrame, COLORS.blue, 0.36)

    local staminaFill = Instance.new("Frame")
    staminaFill.Name = "Fill"
    staminaFill.Position = UDim2.fromOffset(4, 4)
    staminaFill.Size = UDim2.new(1, -8, 1, -8)
    staminaFill.BackgroundColor3 = COLORS.blue
    staminaFill.BorderSizePixel = 0
    staminaFill.Parent = staminaFrame
    corner(staminaFill, 13)
    local staminaText = textLabel(
        staminaFrame,
        "Text",
        "STAMINA · 100",
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0),
        13,
        COLORS.ink,
        Enum.TextXAlignment.Center
    )
    staminaText.Font = Enum.Font.GothamBold
    staminaText.ZIndex = 2

    local toast = textLabel(
        canvas,
        "Toast",
        "",
        UDim2.fromOffset(420, 48),
        UDim2.new(0.5, 0, 1, -222),
        15,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    toast.AnchorPoint = Vector2.new(0.5, 1)
    toast.BackgroundColor3 = COLORS.ink
    toast.BackgroundTransparency = 0.08
    toast.Visible = false
    toast.ZIndex = 12
    corner(toast, 14)
    stroke(toast, COLORS.amber, 0.4)

    local lanternFrame = Instance.new("Frame")
    lanternFrame.Name = "LanternStatus"
    lanternFrame.AnchorPoint = Vector2.new(0.5, 0)
    lanternFrame.Position = UDim2.new(0.5, 0, 0, 66)
    lanternFrame.Size = UDim2.fromOffset(260, 34)
    lanternFrame.BackgroundColor3 = COLORS.ink
    lanternFrame.BackgroundTransparency = 0.08
    lanternFrame.Visible = false
    lanternFrame.Parent = canvas
    corner(lanternFrame, 17)
    stroke(lanternFrame, COLORS.amber, 0.36)

    local lanternFill = Instance.new("Frame")
    lanternFill.Name = "Fill"
    lanternFill.Position = UDim2.fromOffset(4, 4)
    lanternFill.Size = UDim2.new(1, -8, 1, -8)
    lanternFill.BackgroundColor3 = COLORS.amber
    lanternFill.BorderSizePixel = 0
    lanternFill.Parent = lanternFrame
    corner(lanternFill, 13)
    local lanternText = textLabel(
        lanternFrame,
        "Text",
        "LIGHT · 100%",
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0),
        13,
        COLORS.ink,
        Enum.TextXAlignment.Center
    )
    lanternText.Font = Enum.Font.GothamBold
    lanternText.ZIndex = 2

    local blackoutFrame = Instance.new("Frame")
    blackoutFrame.Name = "BlackoutStatus"
    blackoutFrame.AnchorPoint = Vector2.new(0.5, 0)
    blackoutFrame.Position = UDim2.new(0.5, 0, 0, 66)
    blackoutFrame.Size = UDim2.fromOffset(420, 64)
    blackoutFrame.BackgroundColor3 = Color3.fromRGB(11, 24, 25)
    blackoutFrame.BackgroundTransparency = 0.02
    blackoutFrame.Visible = false
    blackoutFrame.ZIndex = 11
    blackoutFrame.Parent = canvas
    corner(blackoutFrame, 14)
    stroke(blackoutFrame, COLORS.blue, 0.08)

    local blackoutTrack = Instance.new("Frame")
    blackoutTrack.Name = "TimeTrack"
    blackoutTrack.Position = UDim2.fromOffset(10, 48)
    blackoutTrack.Size = UDim2.new(1, -20, 0, 7)
    blackoutTrack.BackgroundColor3 = Color3.fromRGB(48, 61, 58)
    blackoutTrack.BorderSizePixel = 0
    blackoutTrack.ZIndex = 12
    blackoutTrack.Parent = blackoutFrame
    corner(blackoutTrack, 4)

    local blackoutFill = Instance.new("Frame")
    blackoutFill.Name = "Fill"
    blackoutFill.Size = UDim2.fromScale(0, 1)
    blackoutFill.BackgroundColor3 = COLORS.blue
    blackoutFill.BorderSizePixel = 0
    blackoutFill.ZIndex = 13
    blackoutFill.Parent = blackoutTrack
    corner(blackoutFill, 4)

    local blackoutTitle = textLabel(
        blackoutFrame,
        "Title",
        "BRAMBLEWAKE BLACKOUT · STAGE 1/4",
        UDim2.new(1, -20, 0, 24),
        UDim2.fromOffset(10, 4),
        14,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    blackoutTitle.Font = Enum.Font.GothamBold
    blackoutTitle.ZIndex = 12
    local blackoutDetail = textLabel(
        blackoutFrame,
        "Detail",
        "ROOTFIRE RELAY · 0/3",
        UDim2.new(1, -20, 0, 20),
        UDim2.fromOffset(10, 27),
        11,
        COLORS.blue,
        Enum.TextXAlignment.Center
    )
    blackoutDetail.Font = Enum.Font.GothamBold
    blackoutDetail.ZIndex = 12

    local eliteFrame = Instance.new("Frame")
    eliteFrame.Name = "EliteStatus"
    eliteFrame.AnchorPoint = Vector2.new(0.5, 0)
    eliteFrame.Position = UDim2.new(0.5, 0, 0, 66)
    eliteFrame.Size = UDim2.fromOffset(420, 70)
    eliteFrame.BackgroundColor3 = COLORS.ink
    eliteFrame.BackgroundTransparency = 0.04
    eliteFrame.Visible = false
    eliteFrame.ZIndex = 11
    eliteFrame.Parent = canvas
    corner(eliteFrame, 14)
    stroke(eliteFrame, COLORS.amber, 0.14)

    local eliteTrack = Instance.new("Frame")
    eliteTrack.Name = "HealthTrack"
    eliteTrack.Position = UDim2.fromOffset(10, 34)
    eliteTrack.Size = UDim2.new(1, -20, 0, 9)
    eliteTrack.BackgroundColor3 = Color3.fromRGB(58, 67, 57)
    eliteTrack.BorderSizePixel = 0
    eliteTrack.ZIndex = 12
    eliteTrack.Parent = eliteFrame
    corner(eliteTrack, 5)

    local eliteFill = Instance.new("Frame")
    eliteFill.Name = "Fill"
    eliteFill.Size = UDim2.fromScale(1, 1)
    eliteFill.BackgroundColor3 = COLORS.amber
    eliteFill.BorderSizePixel = 0
    eliteFill.ZIndex = 13
    eliteFill.Parent = eliteTrack
    corner(eliteFill, 5)

    local eliteTitle = textLabel(
        eliteFrame,
        "Title",
        "OLD GROWTH · PHASE 1/3",
        UDim2.new(1, -20, 0, 26),
        UDim2.fromOffset(10, 5),
        15,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    eliteTitle.Font = Enum.Font.GothamBold
    eliteTitle.ZIndex = 12
    local eliteDetail = textLabel(
        eliteFrame,
        "Detail",
        "EXPOSED · STRIKE THE AMBER HEART",
        UDim2.new(1, -20, 0, 21),
        UDim2.fromOffset(10, 45),
        12,
        COLORS.amber,
        Enum.TextXAlignment.Center
    )
    eliteDetail.Font = Enum.Font.GothamBold
    eliteDetail.ZIndex = 12

    local allyFrame = Instance.new("Frame")
    allyFrame.Name = "AllyDownAlert"
    allyFrame.AnchorPoint = Vector2.new(0.5, 0)
    allyFrame.Position = UDim2.new(0.5, 0, 0, 108)
    allyFrame.Size = UDim2.fromOffset(330, 64)
    allyFrame.BackgroundColor3 = Color3.fromRGB(47, 20, 18)
    allyFrame.BackgroundTransparency = 0.05
    allyFrame.Visible = false
    allyFrame.ZIndex = 11
    allyFrame.Parent = canvas
    corner(allyFrame, 14)
    stroke(allyFrame, COLORS.amber, 0.08)
    local allyTitle = textLabel(
        allyFrame,
        "Title",
        "✚ ALLY DOWN",
        UDim2.new(1, -24, 0, 27),
        UDim2.fromOffset(12, 6),
        15,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    allyTitle.Font = Enum.Font.GothamBold
    allyTitle.ZIndex = 12
    local allyDetail = textLabel(
        allyFrame,
        "Detail",
        "AHEAD · 14m · 23s",
        UDim2.new(1, -24, 0, 24),
        UDim2.fromOffset(12, 33),
        13,
        COLORS.amber,
        Enum.TextXAlignment.Center
    )
    allyDetail.Font = Enum.Font.GothamBold
    allyDetail.ZIndex = 12

    local threatFrame = Instance.new("Frame")
    threatFrame.Name = "ThreatWarning"
    threatFrame.AnchorPoint = Vector2.new(0.5, 0)
    threatFrame.Position = UDim2.fromScale(0.5, 0.32)
    threatFrame.Size = UDim2.fromOffset(330, 66)
    threatFrame.BackgroundColor3 = Color3.fromRGB(47, 20, 18)
    threatFrame.BackgroundTransparency = 0.04
    threatFrame.Visible = false
    threatFrame.ZIndex = 14
    threatFrame.Parent = canvas
    corner(threatFrame, 14)
    stroke(threatFrame, COLORS.danger, 0.04)
    local threatTitle = textLabel(
        threatFrame,
        "Title",
        "!! ROOTLING SWIPE",
        UDim2.new(1, -24, 0, 30),
        UDim2.fromOffset(12, 5),
        17,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    threatTitle.Font = Enum.Font.GothamBold
    threatTitle.ZIndex = 15
    local threatDetail = textLabel(
        threatFrame,
        "Detail",
        "DODGE OUT OF THE RING · 0.9s",
        UDim2.new(1, -24, 0, 25),
        UDim2.fromOffset(12, 34),
        13,
        COLORS.amber,
        Enum.TextXAlignment.Center
    )
    threatDetail.Font = Enum.Font.GothamBold
    threatDetail.ZIndex = 15

    local downedFrame = Instance.new("Frame")
    downedFrame.Name = "SelfDownedRail"
    downedFrame.AnchorPoint = Vector2.new(0.5, 1)
    downedFrame.Position = UDim2.new(0.5, 0, 1, -156)
    downedFrame.Size = UDim2.fromOffset(540, 90)
    downedFrame.BackgroundColor3 = Color3.fromRGB(35, 24, 22)
    downedFrame.BackgroundTransparency = 0.03
    downedFrame.Visible = false
    downedFrame.ZIndex = 11
    downedFrame.Parent = canvas
    corner(downedFrame, 14)
    stroke(downedFrame, COLORS.amber, 0.06)

    local downedTrack = Instance.new("Frame")
    downedTrack.Name = "BleedoutTrack"
    downedTrack.Position = UDim2.fromOffset(4, 4)
    downedTrack.Size = UDim2.new(1, -8, 0, 7)
    downedTrack.BackgroundColor3 = Color3.fromRGB(66, 48, 43)
    downedTrack.BorderSizePixel = 0
    downedTrack.ZIndex = 12
    downedTrack.Parent = downedFrame
    corner(downedTrack, 4)
    local downedFill = Instance.new("Frame")
    downedFill.Name = "Fill"
    downedFill.Size = UDim2.fromScale(1, 1)
    downedFill.BackgroundColor3 = COLORS.amber
    downedFill.BorderSizePixel = 0
    downedFill.ZIndex = 13
    downedFill.Parent = downedTrack
    corner(downedFill, 4)

    local downedTimer = textLabel(
        downedFrame,
        "Timer",
        "00:30",
        UDim2.fromOffset(124, 68),
        UDim2.fromOffset(12, 15),
        30,
        COLORS.cream,
        Enum.TextXAlignment.Center
    )
    downedTimer.Font = Enum.Font.GothamBold
    downedTimer.ZIndex = 12
    local downedDetail = textLabel(
        downedFrame,
        "Detail",
        "DOWNED · CRAWL TOWARD LIGHT",
        UDim2.new(1, -168, 0, 30),
        UDim2.fromOffset(146, 18),
        15,
        COLORS.cream
    )
    downedDetail.Font = Enum.Font.GothamBold
    downedDetail.ZIndex = 12
    local downedAlly = textLabel(
        downedFrame,
        "NearestAlly",
        "HELP SIGNAL ACTIVE · NO ALLY NEARBY",
        UDim2.new(1, -168, 0, 28),
        UDim2.fromOffset(146, 48),
        13,
        COLORS.amber
    )
    downedAlly.Font = Enum.Font.GothamBold
    downedAlly.ZIndex = 12

    local primary = actionButton(
        canvas,
        "PrimaryAction",
        "FIND",
        116,
        UDim2.new(1, -28, 1, -30),
        Vector2.new(1, 1)
    )
    local tool =
        actionButton(canvas, "UseTool", "STRIKE", 84, UDim2.new(1, -158, 1, -40), Vector2.new(1, 1))
    tool.Visible = false
    stroke(tool, COLORS.danger, 0.2)
    local sprint =
        actionButton(canvas, "Sprint", "RUN", 80, UDim2.new(0, 166, 1, -34), Vector2.new(0, 1))
    sprint.Visible = UserInputService.TouchEnabled
    stroke(sprint, COLORS.blue, 0.2)
    local dodge =
        actionButton(canvas, "Dodge", "DODGE", 84, UDim2.new(1, -252, 1, -40), Vector2.new(1, 1))
    dodge.Visible = false
    stroke(dodge, COLORS.amber, 0.12)
    local ability = actionButton(
        canvas,
        "ProfessionAbility",
        "ABILITY",
        84,
        UDim2.new(1, -346, 1, -40),
        Vector2.new(1, 1)
    )
    ability.Visible = false
    stroke(ability, COLORS.green, 0.12)
    --[[
        The hound's order button. CompanionCommand has existed server-side
        with a full payload contract since companions shipped, and nothing
        on the client ever sent it -- the hound could be summoned but never
        told to stay, which made half that feature unreachable in the
        shipped game. Found by playing it.
    ]]
    local companion = actionButton(
        canvas,
        "CompanionCommand",
        "HOUND",
        84,
        UDim2.new(1, -440, 1, -40),
        Vector2.new(1, 1)
    )
    companion.Visible = false
    stroke(companion, COLORS.amber, 0.12)

    local compact = Instance.new("TextButton")
    compact.Name = "CompactToggle"
    compact.AnchorPoint = Vector2.new(1, 0)
    compact.Position = UDim2.new(1, -18, 0, 18)
    compact.Size = UDim2.fromOffset(118, 38)
    compact.BackgroundColor3 = COLORS.panel
    compact.BackgroundTransparency = 0.1
    compact.Font = Enum.Font.GothamBold
    compact.Text = "COMPACT"
    compact.TextColor3 = COLORS.muted
    compact.TextSize = 12
    compact.Parent = canvas
    corner(compact, 12)
    stroke(compact, COLORS.cream, 0.7)

    local professionButton = Instance.new("TextButton")
    professionButton.Name = "ProfessionMenu"
    professionButton.AnchorPoint = Vector2.new(1, 0)
    professionButton.Position = UDim2.new(1, -18, 0, 64)
    professionButton.Size = UDim2.fromOffset(118, 42)
    professionButton.BackgroundColor3 = COLORS.panel
    professionButton.BackgroundTransparency = 0.08
    professionButton.Font = Enum.Font.GothamBold
    professionButton.Text = "PROFESSION"
    professionButton.TextColor3 = COLORS.amber
    professionButton.TextSize = 12
    professionButton.Visible = false
    professionButton.ZIndex = 10
    professionButton.Parent = canvas
    corner(professionButton, 12)
    stroke(professionButton, COLORS.amber, 0.42)

    local progressButton = Instance.new("TextButton")
    progressButton.Name = "ProgressBook"
    progressButton.AnchorPoint = Vector2.new(1, 0)
    progressButton.Position = UDim2.new(1, -18, 0, 202)
    progressButton.Size = UDim2.fromOffset(118, 42)
    progressButton.BackgroundColor3 = COLORS.panel
    progressButton.BackgroundTransparency = 0.08
    progressButton.Font = Enum.Font.GothamBold
    progressButton.Text = "FIELD BOOK"
    progressButton.TextColor3 = COLORS.cream
    progressButton.TextSize = 12
    progressButton.Visible = false
    progressButton.ZIndex = 10
    progressButton.Parent = canvas
    corner(progressButton, 12)
    stroke(progressButton, COLORS.cream, 0.42)

    --[[
        The use buttons are built from the consumable catalog rather than
        one per item name. There are more consumables than a phone screen
        has room for, so this draws a fixed short column and _updateGear
        fills it with whichever ones a player is actually carrying, in
        catalog order. A new consumable needs no change here at all.
    ]]
    local useButtons: { TextButton } = {}
    for index = 1, MAX_USE_BUTTONS do
        local button = Instance.new("TextButton")
        button.Name = string.format("UseConsumable%d", index)
        button.AnchorPoint = Vector2.new(1, 0)
        button.Position = UDim2.new(1, -18, 0, 110 + (index - 1) * 46)
        button.Size = UDim2.fromOffset(118, 42)
        button.BackgroundColor3 = COLORS.panel
        button.BackgroundTransparency = 0.08
        button.Font = Enum.Font.GothamBold
        button.Text = ""
        button.TextColor3 = COLORS.amber
        button.TextSize = 12
        button.TextXAlignment = Enum.TextXAlignment.Right
        button.Visible = false
        button.ZIndex = 10
        button:SetAttribute("ItemId", "")
        button.Parent = canvas
        corner(button, 12)
        stroke(button, COLORS.amber, 0.42)
        table.insert(useButtons, button)
    end

    local professionOverlay = Instance.new("Frame")
    professionOverlay.Name = "ProfessionOverlay"
    professionOverlay.Size = UDim2.fromScale(1, 1)
    professionOverlay.BackgroundColor3 = COLORS.ink
    professionOverlay.BackgroundTransparency = 0.18
    professionOverlay.Active = true
    professionOverlay.Visible = false
    professionOverlay.ZIndex = 40
    professionOverlay.Parent = canvas

    local professionPanel = Instance.new("Frame")
    professionPanel.Name = "ProfessionPanel"
    professionPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    professionPanel.Position = UDim2.fromScale(0.5, 0.5)
    professionPanel.Size = UDim2.fromOffset(640, 440)
    professionPanel.BackgroundColor3 = COLORS.panel
    professionPanel.BackgroundTransparency = 0.02
    professionPanel.ZIndex = 41
    professionPanel.Parent = professionOverlay
    corner(professionPanel, 20)
    stroke(professionPanel, COLORS.amber, 0.18)

    local professionTitle = textLabel(
        professionPanel,
        "Title",
        "CHOOSE YOUR PROFESSION",
        UDim2.new(1, -100, 0, 34),
        UDim2.fromOffset(24, 18),
        22,
        COLORS.cream
    )
    professionTitle.Font = Enum.Font.GothamBold
    professionTitle.ZIndex = 42
    local professionDetail = textLabel(
        professionPanel,
        "Detail",
        "Switch freely in Emberhollow. Every traveler keeps core combat, building, and rescue.",
        UDim2.new(1, -48, 0, 42),
        UDim2.fromOffset(24, 52),
        13,
        COLORS.muted
    )
    professionDetail.TextYAlignment = Enum.TextYAlignment.Top
    professionDetail.ZIndex = 42

    local professionClose = Instance.new("TextButton")
    professionClose.Name = "Close"
    professionClose.AnchorPoint = Vector2.new(1, 0)
    professionClose.Position = UDim2.new(1, -18, 0, 18)
    professionClose.Size = UDim2.fromOffset(72, 64)
    professionClose.BackgroundColor3 = COLORS.panelSoft
    professionClose.Font = Enum.Font.GothamBold
    professionClose.Text = "CLOSE"
    professionClose.TextColor3 = COLORS.cream
    professionClose.TextSize = 11
    professionClose.ZIndex = 43
    professionClose.Parent = professionPanel
    corner(professionClose, 12)
    stroke(professionClose, COLORS.cream, 0.58)

    local progressOverlay = Instance.new("Frame")
    progressOverlay.Name = "ProgressOverlay"
    progressOverlay.Size = UDim2.fromScale(1, 1)
    progressOverlay.BackgroundColor3 = COLORS.ink
    progressOverlay.BackgroundTransparency = 0.18
    progressOverlay.Active = true
    progressOverlay.Visible = false
    progressOverlay.ZIndex = 50
    progressOverlay.Parent = canvas

    local progressPanel = Instance.new("Frame")
    progressPanel.Name = "ProgressPanel"
    progressPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    progressPanel.Position = UDim2.fromScale(0.5, 0.5)
    -- A starting size only. _layoutLoadout narrows the panel to whatever the
    -- canvas actually holds, because 620 points is wider than a portrait
    -- phone's entire canvas and the panel hung off both edges of it.
    progressPanel.Size = UDim2.fromOffset(620, 500)
    progressPanel.BackgroundColor3 = COLORS.panel
    progressPanel.ZIndex = 51
    progressPanel.Parent = progressOverlay
    corner(progressPanel, 20)
    stroke(progressPanel, COLORS.cream, 0.2)
    local progressTitle = textLabel(
        progressPanel,
        "Title",
        "FIELD BOOK · RECIPES · QUESTS · MASTERY",
        UDim2.new(1, -120, 0, 34),
        UDim2.fromOffset(20, 18),
        16,
        COLORS.amber
    )
    progressTitle.Font = Enum.Font.GothamBold
    progressTitle.ZIndex = 52
    --[[
        The notes live in a scrolling window now. One label holding 130
        recipes plus quests, archive, residents and mastery ran to several
        screens of text: it painted straight through the loadout buttons,
        past the panel's bottom edge and off the monitor, and nothing
        could reach the sections underneath. The label keeps growing to
        whatever the book holds; the window is what stays put.
    ]]
    local progressScroll = Instance.new("ScrollingFrame")
    progressScroll.Name = "DetailsScroll"
    progressScroll.Position = UDim2.fromOffset(20, 132)
    progressScroll.Size = UDim2.new(1, -40, 1, -152)
    progressScroll.BackgroundTransparency = 1
    progressScroll.BorderSizePixel = 0
    progressScroll.ScrollBarThickness = 6
    progressScroll.ScrollBarImageColor3 = COLORS.amber
    progressScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    progressScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    progressScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    --[[
        Selectable because nothing inside a text window is: the notes are one
        label, so a controller had no target anywhere in the book and could
        neither read past the first screen nor reach the recipes at all.
        Selecting the window hands the D-pad and thumbstick to its canvas.
    ]]
    progressScroll.Selectable = true
    progressScroll.ZIndex = 52
    progressScroll.Parent = progressPanel
    local progressText = textLabel(
        progressScroll,
        "Details",
        "Loading field notes…",
        UDim2.new(1, -10, 0, 0),
        UDim2.fromOffset(0, 0),
        13,
        COLORS.cream
    )
    progressText.AutomaticSize = Enum.AutomaticSize.Y
    progressText.TextWrapped = true
    progressText.RichText = true
    progressText.TextYAlignment = Enum.TextYAlignment.Top
    progressText.ZIndex = 52
    local equipmentButtons: { [string]: TextButton } = {}
    --[[
        One equip button per equipment definition, from the catalog rather
        than a list kept here. The original list named eight items, which
        was every equippable in the game when it was written and less than
        a tenth of them by the time anyone noticed -- ninety items could
        be crafted and never worn, and nothing failed, because a missing
        button is not an error anywhere.

        Buttons are created hidden and positioned at update time from the
        set a player actually owns, so a fresh save still sees an empty
        margin rather than a wall. Their grid comes from _layoutLoadout;
        the size here is a placeholder it overwrites.
    ]]
    for _, entry in Equipment.list() do
        local definition = Equipment.get(entry.itemId) :: any
        local button = Instance.new("TextButton")
        button.Name = entry.itemId
        button.Position = UDim2.new(0, 20, 1, -58)
        button.Size = UDim2.fromOffset(176, 38)
        button.BackgroundColor3 = COLORS.panelSoft
        button.Font = Enum.Font.GothamBold
        button.Text = definition.displayName
        button:SetAttribute("BaseLabel", definition.displayName)
        button.TextColor3 = COLORS.cream
        button.TextSize = 11
        button.TextWrapped = true
        button.Visible = false
        button.ZIndex = 53
        button.Parent = progressOverlay
        corner(button, 10)
        stroke(button, COLORS.amber, 0.5)
        equipmentButtons[entry.itemId] = button
    end
    -- Kit rows: three saved loadouts, save on the left, apply on the right,
    -- stacked above the equipment buttons' rows.
    local loadoutButtons: { [string]: TextButton } = {}
    for slot = 1, 3 do
        for _, kind in { "save", "apply" } do
            local button = Instance.new("TextButton")
            button.Name = string.format("Loadout_%s_%d", kind, slot)
            -- Above the scrolling notes, not over them: the rows sit
            -- between the title and the DetailsScroll window. The pitch is
            -- measured in _layoutLoadout; these are placeholders.
            button.Position = UDim2.fromOffset(20, 58)
            button.Size = UDim2.fromOffset(if kind == "apply" then 84 else 88, 30)
            button.BackgroundColor3 = COLORS.panelSoft
            button.Font = Enum.Font.GothamBold
            button.Text = if kind == "save"
                then string.format("SAVE %d", slot)
                else string.format("KIT %d", slot)
            button.TextColor3 = if kind == "apply" then COLORS.amber else COLORS.muted
            button.TextSize = 11
            button.ZIndex = 52
            button.Parent = progressPanel
            corner(button, 8)
            stroke(button, if kind == "apply" then COLORS.amber else COLORS.cream, 0.6)
            loadoutButtons[kind .. "_" .. slot] = button
        end
    end

    -- The whetstone: one button, aimed by the server at whichever piece
    -- most needs it. Hidden while everything is sound.
    local whetButton = Instance.new("TextButton")
    whetButton.Name = "Whet"
    whetButton.Position = UDim2.fromOffset(20, 94)
    -- Narrowed with the panel by _layoutLoadout when the canvas is small.
    whetButton.Size = UDim2.fromOffset(220, 30)
    whetButton.BackgroundColor3 = COLORS.panelSoft
    whetButton.Font = Enum.Font.GothamBold
    whetButton.Text = "WHET"
    whetButton.TextColor3 = COLORS.amber
    whetButton.TextSize = 11
    whetButton.Visible = false
    whetButton.ZIndex = 52
    whetButton.Parent = progressPanel
    corner(whetButton, 8)
    stroke(whetButton, COLORS.amber, 0.45)

    local progressClose = Instance.new("TextButton")
    progressClose.Name = "Close"
    progressClose.AnchorPoint = Vector2.new(1, 0)
    progressClose.Position = UDim2.new(1, -18, 0, 18)
    progressClose.Size = UDim2.fromOffset(72, 42)
    progressClose.BackgroundColor3 = COLORS.panelSoft
    progressClose.Font = Enum.Font.GothamBold
    progressClose.Text = "CLOSE"
    progressClose.TextColor3 = COLORS.cream
    progressClose.TextSize = 11
    progressClose.ZIndex = 52
    progressClose.Parent = progressPanel
    corner(progressClose, 12)
    stroke(progressClose, COLORS.cream, 0.58)

    local professionGrid = Instance.new("Frame")
    professionGrid.Name = "ProfessionGrid"
    professionGrid.BackgroundTransparency = 1
    professionGrid.Position = UDim2.fromOffset(20, 106)
    professionGrid.Size = UDim2.new(1, -40, 1, -130)
    professionGrid.ZIndex = 42
    professionGrid.Parent = professionPanel
    -- Three columns, not the original two-by-two: the roster is seven kits
    -- now, and 3 x 3 keeps every card on one page of the same panel rather
    -- than growing the panel taller than a landscape phone viewport.
    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.fromOffset(10, 10)
    grid.CellSize = UDim2.new(1 / 3, -7, 1 / 3, -7)
    grid.FillDirectionMaxCells = 3
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = professionGrid

    local professionCards: { [string]: TextButton } = {}
    local professionOrder = {}
    for index, definition in professions do
        local card = Instance.new("TextButton")
        card.Name = tostring(definition.displayName or definition.id)
        card.LayoutOrder = index
        card.BackgroundColor3 = COLORS.panelSoft
        card.BackgroundTransparency = 0.04
        card.AutoButtonColor = true
        card.Font = Enum.Font.GothamMedium
        card.Text = string.format(
            "%s\n%s\n%s\n%s",
            tostring(definition.displayName),
            tostring(definition.role),
            tostring(definition.abilityName),
            tostring(definition.abilityDescription)
        )
        card.TextColor3 = COLORS.cream
        -- 12, not 14: seven cards share the panel three abreast now, and the
        -- four-line card text has to wrap inside a third of the width.
        card.TextSize = 12
        card.TextWrapped = true
        card.TextYAlignment = Enum.TextYAlignment.Center
        card.Selectable = true
        card.ZIndex = 42
        card:SetAttribute("ProfessionId", definition.id)
        card:SetAttribute("BaseText", card.Text)
        card.Parent = professionGrid
        corner(card, 14)
        stroke(card, COLORS.cream, 0.7)
        professionCards[definition.id] = card
        table.insert(professionOrder, definition.id)
    end
    if professionOrder[1] ~= nil then
        professionClose.NextSelectionDown = professionCards[professionOrder[1]]
        professionCards[professionOrder[1]].NextSelectionUp = professionClose
    end
    if professionOrder[2] ~= nil then
        professionCards[professionOrder[2]].NextSelectionUp = professionClose
    end

    -- Departure panel. Visible only while a player is still in the staging
    -- yard, so it never competes with the survival HUD once the run starts.
    local lobbyFrame = Instance.new("Frame")
    lobbyFrame.Name = "LobbyPanel"
    lobbyFrame.AnchorPoint = Vector2.new(0.5, 1)
    lobbyFrame.Position = UDim2.new(0.5, 0, 1, -104)
    lobbyFrame.Size = UDim2.fromOffset(420, 246)
    lobbyFrame.BackgroundColor3 = Color3.fromRGB(16, 22, 26)
    lobbyFrame.BackgroundTransparency = 0.12
    lobbyFrame.BorderSizePixel = 0
    lobbyFrame.Visible = false
    lobbyFrame.ZIndex = 40
    -- Bottom-anchored, so it belongs on the canvas for the same reason every
    -- other bottom-anchored control does: the canvas carries the UIScale and
    -- is grown by its inverse so its edges land on the screen edges. Parented
    -- straight to the ScreenGui it was the one panel that never scaled down on
    -- a phone, and it sits directly above the touch action buttons.
    lobbyFrame.Parent = canvas
    local lobbyCorner = Instance.new("UICorner")
    lobbyCorner.CornerRadius = UDim.new(0, 12)
    lobbyCorner.Parent = lobbyFrame
    local lobbyStroke = Instance.new("UIStroke")
    lobbyStroke.Color = Color3.fromRGB(255, 181, 76)
    lobbyStroke.Thickness = 1.5
    lobbyStroke.Transparency = 0.45
    lobbyStroke.Parent = lobbyFrame

    local lobbyTitle = Instance.new("TextLabel")
    lobbyTitle.Name = "LobbyTitle"
    lobbyTitle.BackgroundTransparency = 1
    lobbyTitle.Position = UDim2.fromOffset(14, 8)
    lobbyTitle.Size = UDim2.new(1, -28, 0, 18)
    lobbyTitle.Font = Enum.Font.GothamBold
    lobbyTitle.Text = "DEPARTURE"
    lobbyTitle.TextColor3 = Color3.fromRGB(255, 181, 76)
    lobbyTitle.TextSize = 20
    lobbyTitle.TextXAlignment = Enum.TextXAlignment.Left
    lobbyTitle.ZIndex = 41
    lobbyTitle.Parent = lobbyFrame

    local lobbyDetail = Instance.new("TextLabel")
    lobbyDetail.Name = "LobbyDetail"
    lobbyDetail.BackgroundTransparency = 1
    lobbyDetail.Position = UDim2.fromOffset(14, 34)
    lobbyDetail.Size = UDim2.new(1, -28, 0, 18)
    lobbyDetail.Font = Enum.Font.Gotham
    lobbyDetail.Text = "STAND ON THE PLATFORM TO DEPART"
    lobbyDetail.TextColor3 = Color3.fromRGB(178, 194, 183)
    lobbyDetail.TextSize = 16
    lobbyDetail.TextXAlignment = Enum.TextXAlignment.Left
    lobbyDetail.ZIndex = 41
    lobbyDetail.Parent = lobbyFrame

    local lobbySizes = Instance.new("Frame")
    lobbySizes.Name = "LobbySizes"
    lobbySizes.BackgroundTransparency = 1
    lobbySizes.Position = UDim2.fromOffset(14, 66)
    lobbySizes.Size = UDim2.new(1, -28, 0, 44)
    lobbySizes.ZIndex = 41
    lobbySizes.Parent = lobbyFrame
    local lobbyLayout = Instance.new("UIListLayout")
    lobbyLayout.FillDirection = Enum.FillDirection.Horizontal
    lobbyLayout.Padding = UDim.new(0, 6)
    lobbyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lobbyLayout.Parent = lobbySizes

    local lobbySizeButtons: { TextButton } = {}
    for size = 1, 8 do
        local sizeButton = Instance.new("TextButton")
        sizeButton.Name = "PartySize_" .. size
        sizeButton.LayoutOrder = size
        sizeButton.Size = UDim2.new(0, 44, 1, 0)
        sizeButton.BackgroundColor3 = Color3.fromRGB(31, 40, 44)
        sizeButton.AutoButtonColor = true
        sizeButton.Font = Enum.Font.GothamBold
        sizeButton.Text = tostring(size)
        sizeButton.TextColor3 = Color3.fromRGB(244, 230, 197)
        sizeButton.TextSize = 19
        sizeButton.Selectable = true
        sizeButton.ZIndex = 42
        sizeButton.Parent = lobbySizes
        local sizeCorner = Instance.new("UICorner")
        sizeCorner.CornerRadius = UDim.new(0, 8)
        sizeCorner.Parent = sizeButton
        table.insert(lobbySizeButtons, sizeButton)
    end

    --[[
        The contract row: the party names its risk beside its size. One
        selected at a time; the selection rides the depart payload and the
        server resolves it (junk falls back to the standard sweep).
    ]]
    local contractRow = Instance.new("Frame")
    contractRow.Name = "LobbyContracts"
    contractRow.BackgroundTransparency = 1
    contractRow.Position = UDim2.fromOffset(14, 116)
    contractRow.Size = UDim2.new(1, -28, 0, 58)
    contractRow.ZIndex = 41
    contractRow.Parent = lobbyFrame
    local contractLayout = Instance.new("UIListLayout")
    contractLayout.FillDirection = Enum.FillDirection.Horizontal
    contractLayout.Padding = UDim.new(0, 6)
    contractLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contractLayout.Parent = contractRow
    local contractButtons: { [string]: TextButton } = {}
    for order, contract in contracts or {} do
        local contractButton = Instance.new("TextButton")
        contractButton.Name = "Contract_" .. contract.id
        contractButton.LayoutOrder = order
        contractButton.Size = UDim2.new(0.25, -6, 1, 0)
        contractButton.BackgroundColor3 = if order == 1
            then Color3.fromRGB(37, 68, 55)
            else Color3.fromRGB(31, 40, 44)
        contractButton.AutoButtonColor = true
        contractButton.Font = Enum.Font.GothamBold
        contractButton.TextWrapped = true
        contractButton.Text = contract.title
        contractButton.TextColor3 = Color3.fromRGB(244, 230, 197)
        contractButton.TextSize = 11
        contractButton.ZIndex = 42
        contractButton.Parent = contractRow
        local contractCorner = Instance.new("UICorner")
        contractCorner.CornerRadius = UDim.new(0, 8)
        contractCorner.Parent = contractButton
        contractButtons[contract.id] = contractButton
    end

    --[[
        The party row: who is travelling with you, and the way back to them.

        It lives in the departure panel because that is where the decision is
        made -- you gather at the platform, ask the people standing on it, and
        leave together. The rejoin offer is here for the same reason: a player
        who dropped out of a run comes back to the lodge, and the platform is
        the thing they are looking at.
    ]]
    local partyLine = Instance.new("TextLabel")
    partyLine.Name = "LobbyPartyLine"
    partyLine.BackgroundTransparency = 1
    partyLine.Position = UDim2.fromOffset(14, 180)
    partyLine.Size = UDim2.new(1, -28, 0, 16)
    partyLine.Font = Enum.Font.Gotham
    partyLine.Text = "TRAVELLING ALONE"
    partyLine.TextColor3 = Color3.fromRGB(178, 194, 183)
    partyLine.TextSize = 14
    partyLine.TextXAlignment = Enum.TextXAlignment.Left
    partyLine.ZIndex = 41
    partyLine.Parent = lobbyFrame

    local partyRow = Instance.new("Frame")
    partyRow.Name = "LobbyParty"
    partyRow.BackgroundTransparency = 1
    partyRow.Position = UDim2.fromOffset(14, 200)
    partyRow.Size = UDim2.new(1, -28, 0, 36)
    partyRow.ZIndex = 41
    partyRow.Parent = lobbyFrame
    local partyLayout = Instance.new("UIListLayout")
    partyLayout.FillDirection = Enum.FillDirection.Horizontal
    partyLayout.Padding = UDim.new(0, 6)
    partyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    partyLayout.Parent = partyRow

    local partyButtons: { [string]: TextButton } = {}
    for order, entry in
        {
            { key = "rejoin", label = "REJOIN" },
            { key = "accept", label = "JOIN" },
            { key = "decline", label = "DECLINE" },
            { key = "invite", label = "INVITE" },
            { key = "leave", label = "LEAVE" },
        }
    do
        local partyButton = Instance.new("TextButton")
        partyButton.Name = "Party_" .. entry.key
        partyButton.LayoutOrder = order
        partyButton.Size = UDim2.new(0, 92, 1, 0)
        partyButton.BackgroundColor3 = Color3.fromRGB(31, 40, 44)
        partyButton.AutoButtonColor = true
        partyButton.Font = Enum.Font.GothamBold
        partyButton.Text = entry.label
        partyButton.TextColor3 = Color3.fromRGB(244, 230, 197)
        partyButton.TextSize = 13
        partyButton.Selectable = true
        partyButton.Visible = false
        partyButton.ZIndex = 42
        partyButton.Parent = partyRow
        local partyCorner = Instance.new("UICorner")
        partyCorner.CornerRadius = UDim.new(0, 8)
        partyCorner.Parent = partyButton
        partyButtons[entry.key] = partyButton
    end

    -- Action progress: what a timed gather or build looks like while it runs.
    local actionFrame = Instance.new("Frame")
    actionFrame.Name = "ActionProgress"
    actionFrame.AnchorPoint = Vector2.new(0.5, 1)
    actionFrame.Position = UDim2.new(0.5, 0, 1, -210)
    actionFrame.Size = UDim2.fromOffset(320, 76)
    actionFrame.BackgroundColor3 = COLORS.panel
    actionFrame.BackgroundTransparency = 0.1
    actionFrame.BorderSizePixel = 0
    actionFrame.Visible = false
    actionFrame.ZIndex = 44
    actionFrame.Parent = canvas
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 12)
    actionCorner.Parent = actionFrame

    local actionLabel = Instance.new("TextLabel")
    actionLabel.Name = "ActionLabel"
    actionLabel.BackgroundTransparency = 1
    actionLabel.Position = UDim2.fromOffset(16, 10)
    actionLabel.Size = UDim2.new(1, -32, 0, 26)
    actionLabel.Font = Enum.Font.GothamBold
    actionLabel.Text = "GATHERING..."
    actionLabel.TextColor3 = COLORS.amber
    actionLabel.TextSize = 17
    actionLabel.TextXAlignment = Enum.TextXAlignment.Left
    actionLabel.ZIndex = 45
    actionLabel.Parent = actionFrame

    local actionTrack = Instance.new("Frame")
    actionTrack.Name = "ActionTrack"
    actionTrack.Position = UDim2.fromOffset(16, 48)
    actionTrack.Size = UDim2.new(1, -32, 0, 14)
    actionTrack.BackgroundColor3 = Color3.fromRGB(23, 30, 34)
    actionTrack.BorderSizePixel = 0
    actionTrack.ZIndex = 45
    actionTrack.Parent = actionFrame
    local actionTrackCorner = Instance.new("UICorner")
    actionTrackCorner.CornerRadius = UDim.new(0, 5)
    actionTrackCorner.Parent = actionTrack

    local actionFill = Instance.new("Frame")
    actionFill.Name = "ActionFill"
    actionFill.Size = UDim2.fromScale(0, 1)
    actionFill.BackgroundColor3 = COLORS.amber
    actionFill.BorderSizePixel = 0
    actionFill.ZIndex = 46
    actionFill.Parent = actionTrack
    local actionFillCorner = Instance.new("UICorner")
    actionFillCorner.CornerRadius = UDim.new(0, 5)
    actionFillCorner.Parent = actionFill

    local self = setmetatable({
        _gui = gui,
        _actionFrame = actionFrame,
        _actionLabel = actionLabel,
        _actionFill = actionFill,
        _lobbyFrame = lobbyFrame,
        _lobbyTitle = lobbyTitle,
        _lobbyDetail = lobbyDetail,
        _lobbySizes = lobbySizes,
        _lobbySizeButtons = lobbySizeButtons,
        _partyLine = partyLine,
        _partyButtons = partyButtons,
        _contractButtons = contractButtons,
        _selectedContractId = "contract_standard",
        _departurePlatformPart = nil,
        _departurePlatformPosition = nil,
        _onLobbyDepart = nil,
        _selectedPartySize = nil,
        _canvas = canvas,
        _scale = scale,
        _phaseFrame = phaseFrame,
        _phase = phase,
        _objectiveFrame = objectiveFrame,
        _objective = objective,
        _detail = detail,
        _progress = progress,
        _mara = mara,
        _resource = resource,
        _health = health,
        _staminaFrame = staminaFrame,
        _staminaFill = staminaFill,
        _staminaText = staminaText,
        _toast = toast,
        _lanternFrame = lanternFrame,
        _lanternFill = lanternFill,
        _lanternText = lanternText,
        _blackoutFrame = blackoutFrame,
        _blackoutFill = blackoutFill,
        _blackoutTitle = blackoutTitle,
        _blackoutDetail = blackoutDetail,
        _eliteFrame = eliteFrame,
        _eliteFill = eliteFill,
        _eliteTitle = eliteTitle,
        _eliteDetail = eliteDetail,
        _allyFrame = allyFrame,
        _allyTitle = allyTitle,
        _allyDetail = allyDetail,
        _threatFrame = threatFrame,
        _threatTitle = threatTitle,
        _threatDetail = threatDetail,
        _downedFrame = downedFrame,
        _downedFill = downedFill,
        _downedTimer = downedTimer,
        _downedDetail = downedDetail,
        _downedAlly = downedAlly,
        _primary = primary,
        _tool = tool,
        _sprint = sprint,
        _dodge = dodge,
        _ability = ability,
        _companion = companion,
        _companionMode = "follow",
        _onCompanionCommand = nil,
        _compact = compact,
        _professionButton = professionButton,
        _progressButton = progressButton,
        _useButtons = useButtons,
        _professionOverlay = professionOverlay,
        _professionPanel = professionPanel,
        _professionCards = professionCards,
        _professionOrder = professionOrder,
        _professionClose = professionClose,
        _progressOverlay = progressOverlay,
        _progressPanel = progressPanel,
        _progressScroll = progressScroll,
        _progressClose = progressClose,
        _progressText = progressText,
        _equipmentButtons = equipmentButtons,
        _whetButton = whetButton,
        _whetItemId = nil,
        _onWhet = nil,
        _loadoutButtons = loadoutButtons,
        _currentState = nil,
        _interactionLabel = nil,
        _interactionAvailable = false,
        _inputMode = "keyboard",
        _maraText = "",
        _maraShownAt = 0,
        _compactEnabled = false,
        _playerDowned = false,
        _combatContext = false,
        _professionMenuOpen = false,
        _professionSwitchable = false,
        _lastToastRevision = 0,
        _lastPhase = nil,
        _onCompact = nil,
        _onProfessionSelected = nil,
        _onEquip = nil,
    }, HUDController)

    compact.Activated:Connect(function()
        self._compactEnabled = not self._compactEnabled
        self:_applyCompact()
        local callback = self._onCompact
        if callback ~= nil then
            callback(self._compactEnabled)
        end
    end)
    professionClose.Activated:Connect(function()
        self:setProfessionMenuOpen(false)
    end)
    progressButton.Activated:Connect(function()
        self:setProgressOpen(not self._progressOverlay.Visible)
    end)
    progressClose.Activated:Connect(function()
        self:setProgressOpen(false)
    end)
    for itemId, button in equipmentButtons do
        button.Activated:Connect(function()
            local callback = self._onEquip
            if callback ~= nil then
                callback(itemId)
            end
        end)
    end
    whetButton.Activated:Connect(function()
        local callback = self._onWhet
        local itemId = self._whetItemId
        if callback ~= nil and itemId ~= nil then
            callback(itemId)
        end
    end)
    local function bindProfessionCard(professionId: string, card: TextButton)
        card.Activated:Connect(function()
            if not self._professionSwitchable then
                return
            end
            local callback = self._onProfessionSelected
            if callback ~= nil then
                callback(professionId)
            end
            self:setProfessionMenuOpen(false)
        end)
    end
    for professionId, card in professionCards do
        bindProfessionCard(professionId, card)
    end

    local viewportConnection: RBXScriptConnection? = nil
    local function bindCamera()
        if viewportConnection ~= nil then
            viewportConnection:Disconnect()
            viewportConnection = nil
        end

        local camera = workspace.CurrentCamera
        if camera ~= nil then
            viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                self:_layout()
            end)
        end
        self:_layout()
    end
    bindCamera()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)

    local clockAccumulator = 0
    RunService.RenderStepped:Connect(function(deltaTime: number)
        clockAccumulator += deltaTime
        if clockAccumulator < 0.1 then
            return
        end
        clockAccumulator = 0
        self:_updateClock()
        -- Mara's line expires on a timer rather than on the next state push,
        -- which may not arrive for minutes.
        if self._mara.Visible and not self:_maraLineIsFresh() then
            self._mara.Visible = false
        end
        -- The departure panel's distance gate re-evaluates on the same
        -- local clock, for the same reason: the gate reads the player's
        -- position, which changes constantly between pushes, so a panel
        -- opened at the platform used to follow the player across town
        -- until the server happened to say something.
        if self._currentState ~= nil then
            self:_updateLobby(self._currentState)
        end
    end)

    return self
end

function HUDController.gui(self: HUDController): ScreenGui
    return self._gui
end

function HUDController.primaryButton(self: HUDController): TextButton
    return self._primary
end

function HUDController.toolButton(self: HUDController): TextButton
    return self._tool
end

function HUDController.sprintButton(self: HUDController): TextButton
    return self._sprint
end

function HUDController.dodgeButton(self: HUDController): TextButton
    return self._dodge
end

function HUDController.setCompanionHandler(self: HUDController, callback: (string) -> ())
    self._onCompanionCommand = callback
    self._companion.Activated:Connect(function()
        local handler = self._onCompanionCommand
        if handler == nil then
            return
        end
        -- The button names what it will do next, so the press is the answer
        -- to the word on it.
        handler(if self._companionMode == "follow" then "stay" else "follow")
    end)
end

function HUDController.abilityButton(self: HUDController): TextButton
    return self._ability
end

function HUDController.professionButton(self: HUDController): TextButton
    return self._professionButton
end

function HUDController.setProgressOpen(self: HUDController, open: boolean)
    local shouldOpen = open and not self._playerDowned
    self._progressOverlay.Visible = shouldOpen
    self._progressButton.AutoButtonColor = not shouldOpen
    --[[
        The equip buttons position themselves from the owned set inside
        the state-driven update, and their visibility keys off this
        overlay -- so opening the book on a quiet server showed an empty
        page until the next push happened to arrive. The book fills
        itself the moment it is opened.
    ]]
    if shouldOpen and self._currentState ~= nil then
        self:_updateProgress()
    end
    self:_focusProgressBook(shouldOpen)
end

--[[
    Controller focus for the field book.

    The recipes moved into a ScrollingFrame when 130 of them stopped fitting on
    one page, and a scrolling text window is the one HUD surface a gamepad
    cannot reach by accident -- the notes are a single label, so there was no
    selectable target anywhere inside the book and a controller player could
    neither scroll it nor read past the first screen.

    Waiting for a real AbsoluteSize is the lesson the loading screen already
    paid for: assigning SelectedObject to a GuiObject the layout has not
    measured yet logs "Setting GuiService.SelectedObject to invalid GuiObject"
    and the focus silently does not take.
]]
function HUDController._focusProgressBook(self: HUDController, open: boolean)
    if not open then
        local selected = GuiService.SelectedObject
        if selected ~= nil and selected:IsDescendantOf(self._progressOverlay) then
            GuiService.SelectedObject = nil
        end
        return
    end

    local scroll = self._progressScroll
    -- A way back out, so the D-pad is not a one-way trip into the notes.
    scroll.NextSelectionUp = self._progressClose
    scroll.NextSelectionDown = self._loadoutButtons["apply_1"]
    self._progressClose.NextSelectionDown = scroll
    task.spawn(function()
        for _ = 1, 30 do
            if not self._progressOverlay.Visible then
                return
            end
            if scroll.AbsoluteSize.X >= 1 and scroll.AbsoluteSize.Y >= 1 then
                pcall(function()
                    GuiService.SelectedObject = scroll
                end)
                return
            end
            task.wait()
        end
    end)
end

function HUDController.setEquipHandler(self: HUDController, callback: (string) -> ())
    self._onEquip = callback
end

function HUDController.setWhetHandler(self: HUDController, callback: (string) -> ())
    self._onWhet = callback
end

function HUDController.progressButton(self: HUDController): TextButton
    return self._progressButton
end

--[[
    The consumable buttons, in the order they are drawn. Each carries the
    item it is currently standing for in an `ItemId` attribute, because
    which consumable a button means changes with what a player is
    carrying -- so a caller sends the button's own id rather than one it
    was told at startup.
]]
function HUDController.useButtons(self: HUDController): { TextButton }
    return self._useButtons
end

function HUDController.setCompactHandler(self: HUDController, callback: (boolean) -> ())
    self._onCompact = callback
end

function HUDController._setSelectedPartySize(self: HUDController, size: number?)
    self._selectedPartySize = size
    for index, button in self._lobbySizeButtons do
        local chosen = index == size
        button.BackgroundColor3 = if chosen
            then Color3.fromRGB(37, 68, 55)
            else Color3.fromRGB(31, 40, 44)
        button.TextColor3 = if chosen then COLORS.amber else COLORS.cream
    end
end

function HUDController.setLobbyDepartHandler(self: HUDController, callback: (number, string) -> ())
    self._onLobbyDepart = callback
    for size, button in self._lobbySizeButtons do
        button.Activated:Connect(function()
            --[[
                The press is two things at once, and it used to be only one.
                Sending the departure request was always here; showing that a
                number was chosen was not, so a press made off the platform --
                which the server correctly refuses -- left the panel looking
                exactly as it had before it. That is the "nothing happens, no
                number is selected" the owner reported twice. The contract row
                one line below has always marked its choice; the size row now
                speaks the same language.
            ]]
            self:_setSelectedPartySize(size)
            local handler = self._onLobbyDepart
            if handler ~= nil then
                handler(size, self._selectedContractId)
            end
        end)
    end
    for contractId, button in self._contractButtons do
        button.Activated:Connect(function()
            self._selectedContractId = contractId
            for otherId, otherButton in self._contractButtons do
                otherButton.BackgroundColor3 = if otherId == contractId
                    then Color3.fromRGB(37, 68, 55)
                    else Color3.fromRGB(31, 40, 44)
            end
        end)
    end
end

--[[
    The five party presses, wired in one call.

    Each button sends one thing and nothing else: INVITE asks whoever is
    standing on the platform, JOIN and DECLINE answer the one invitation a
    player can be holding, LEAVE steps out, REJOIN spends the ticket back to a
    run. None of them carries a name, and the reply carries only yes or no,
    which is what keeps every one of them inside the payload contract's single
    extra field.
]]
function HUDController.setPartyHandlers(
    self: HUDController,
    onInvite: () -> (),
    onReply: (boolean) -> (),
    onLeave: () -> (),
    onRejoin: () -> ()
)
    self._partyButtons.invite.Activated:Connect(onInvite)
    self._partyButtons.leave.Activated:Connect(onLeave)
    self._partyButtons.rejoin.Activated:Connect(onRejoin)
    self._partyButtons.accept.Activated:Connect(function()
        onReply(true)
    end)
    self._partyButtons.decline.Activated:Connect(function()
        onReply(false)
    end)
end

--[[
    What the party row says, and which of its buttons exist right now.

    Everything here comes off the snapshot rather than from local memory: the
    party is server state, and a client that remembered its own idea of who
    was in it would be a second answer to a question with one authority. An
    absent `party` block means the server has no party service, and the whole
    row goes away rather than showing an empty one.
]]
function HUDController._updateParty(self: HUDController, state: any)
    local party = state.party
    local buttons = self._partyButtons
    if type(party) ~= "table" then
        self._partyLine.Visible = false
        for _, button in buttons do
            button.Visible = false
        end
        return
    end

    local rejoin = party.rejoin
    local hasRejoin = type(rejoin) == "table" and rejoin.available == true
    local invitedBy = if type(party.inviteFrom) == "string" then party.inviteFrom else nil
    local size = if type(party.size) == "number" then party.size else 0
    -- Guarded like every other field this reads, and for a sharper reason:
    -- `string.format` with %d raises on a nil, and this runs off the render
    -- loop, so one bad field would break the panel on every frame rather
    -- than once.
    local rejoinSize = if hasRejoin and type(rejoin.partySize) == "number"
        then rejoin.partySize
        else 0

    self._partyLine.Visible = true
    self._partyLine.Text = if hasRejoin
        then string.format("YOUR PARTY OF %d IS STILL OUT THERE", rejoinSize)
        elseif invitedBy ~= nil then string.format(
            "%s ASKS YOU TO TRAVEL WITH THEM",
            invitedBy
        )
        elseif party.inParty == true and party.leader == true then string.format(
            "PARTY OF %d · YOU LEAD",
            size
        )
        elseif party.inParty == true then string.format(
            "PARTY OF %d · LED BY %s",
            size,
            tostring(party.leaderName or "SOMEONE")
        )
        else "TRAVELLING ALONE"

    buttons.rejoin.Visible = hasRejoin
    buttons.accept.Visible = invitedBy ~= nil
    buttons.decline.Visible = invitedBy ~= nil
    -- An invitation is answered before another is offered: three choices in a
    -- row where two of them are about different parties is a way to press the
    -- wrong one.
    buttons.invite.Visible = invitedBy == nil
    buttons.leave.Visible = invitedBy == nil and party.inParty == true
end

-- Mara's last line stays up for a few seconds. Long enough to read at a
-- glance, short enough that it never becomes furniture.
local MARA_LINE_SECONDS = 7

--[[
    Dodge has no button on touch.

    Visibility was being decided in three separate places -- the input-mode
    handler, the combat-state branch, and the main update -- and each one
    re-enabled it, so removing it from any single site never stuck. They all
    ask here now. Dodge itself is untouched and still LeftAlt or gamepad B;
    only the on-screen button is gone, because on a phone it was one more
    thing to find mid-telegraph.
]]
function HUDController._dodgeButtonVisible(self: HUDController): boolean
    if self._inputMode == "touch" then
        return false
    end
    return not self._playerDowned and self._combatContext == true
end

function HUDController._maraLineIsFresh(self: HUDController): boolean
    return self._maraShownAt > 0 and (os.clock() - self._maraShownAt) < MARA_LINE_SECONDS
end

function HUDController._updateLobby(self: HUDController, state: any)
    local lobby = state.lobby
    if type(lobby) ~= "table" or state.departed == true then
        self._lobbyFrame.Visible = false
        return
    end
    -- The departure panel is a control for the platform in front of you, not
    -- a HUD fixture. `departed` only flips for players who leave through the
    -- platform, so anyone who walks out of the yard another way carried this
    -- panel through the tutorial, the night defense, and the entire
    -- expedition. Show it only within sight of the platform it operates.
    local platform = self._departurePlatformPart
    if platform == nil or platform.Parent == nil then
        platform = workspace:FindFirstChild("DeparturePlatform", true)
        self._departurePlatformPart = platform
    end
    --[[
        The distance gate works from the platform's POSITION, not the
        instance: under streaming, walking far enough from the lodge
        unloads the platform on this client, and a nil instance used to
        fail the gate open -- the panel followed the player across the
        whole town once the lodge streamed out, which is the exact
        carried-panel bug the gate was added to end. A position survives
        streaming; it is cached the first time the platform is seen and
        the platform never moves.
    ]]
    if platform ~= nil and platform:IsA("BasePart") then
        self._departurePlatformPosition = platform.Position
    end
    local platformPosition = self._departurePlatformPosition
    local character = game:GetService("Players").LocalPlayer.Character
    local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
    if platformPosition ~= nil and root ~= nil and root:IsA("BasePart") then
        local offset = root.Position - platformPosition
        if Vector3.new(offset.X, 0, offset.Z).Magnitude > 46 then
            self._lobbyFrame.Visible = false
            return
        end
    end
    self._lobbyFrame.Visible = true
    self:_updateParty(state)
    if lobby.counting then
        self._lobbyTitle.Text = string.format("DEPARTING IN %d", lobby.secondsRemaining)
        self._lobbyDetail.Text =
            string.format("%d ON THE PLATFORM * PARTY OF %d", lobby.readyCount, lobby.partySize)
        self._lobbySizes.Visible = false
    else
        self._lobbyTitle.Text = "DEPARTURE"
        local chosen = self._selectedPartySize
        self._lobbyDetail.Text = if chosen ~= nil and lobby.readyCount <= 0
            then string.format("PARTY OF %d * STAND ON THE PLATFORM", chosen)
            elseif chosen ~= nil then string.format(
                "%d ON THE PLATFORM * PARTY OF %d",
                lobby.readyCount,
                chosen
            )
            elseif lobby.readyCount > 0 then string.format(
                "%d ON THE PLATFORM * CHOOSE PARTY SIZE",
                lobby.readyCount
            )
            else "STAND ON THE PLATFORM TO DEPART"
        self._lobbySizes.Visible = true
        local maximum = if type(lobby.maxPartySize) == "number" then lobby.maxPartySize else 8
        for size, button in self._lobbySizeButtons do
            button.Visible = size <= maximum
        end
    end
end

function HUDController.setLoadoutHandlers(
    self: HUDController,
    onSave: (number) -> (),
    onApply: (number) -> ()
)
    for slot = 1, 3 do
        self._loadoutButtons["save_" .. slot].Activated:Connect(function()
            onSave(slot)
        end)
        self._loadoutButtons["apply_" .. slot].Activated:Connect(function()
            onApply(slot)
        end)
    end
end

function HUDController.setProfessionHandler(self: HUDController, callback: (string) -> ())
    self._onProfessionSelected = callback
end

function HUDController.setProfessionMenuOpen(self: HUDController, open: boolean)
    local shouldOpen = open and self._professionSwitchable and not self._playerDowned
    self._professionMenuOpen = shouldOpen
    self._professionOverlay.Visible = shouldOpen
    if shouldOpen then
        local profession = if self._currentState == nil then nil else self._currentState.profession
        local selectedId = if type(profession) == "table" then profession.selectedId else nil
        local selectedCard = if type(selectedId) == "string"
            then self._professionCards[selectedId]
            else nil
        if selectedCard == nil then
            local firstId = self._professionOrder[1]
            selectedCard = if firstId == nil then nil else self._professionCards[firstId]
        end
        if selectedCard ~= nil then
            GuiService.SelectedObject = selectedCard
        end
    elseif
        GuiService.SelectedObject ~= nil
        and GuiService.SelectedObject:IsDescendantOf(self._professionPanel)
    then
        GuiService.SelectedObject = nil
    end
end

function HUDController.toggleProfessionMenu(self: HUDController)
    self:setProfessionMenuOpen(not self._professionMenuOpen)
end

function HUDController.isProfessionMenuOpen(self: HUDController): boolean
    return self._professionMenuOpen
end

function HUDController.setInputMode(self: HUDController, mode: string)
    self._inputMode = mode
    self._sprint.Visible = mode == "touch" and not self._playerDowned
    self._dodge.Visible = self:_dodgeButtonVisible()
    self:setInteraction(self._interactionLabel, self._interactionAvailable)
    self._tool.Text = if mode == "keyboard"
        then "CLICK\nSTRIKE"
        elseif mode == "gamepad" then "RT\nSTRIKE"
        else "STRIKE"
    self:_updateCombatClock()
    self:_updateProfessionClock()
end

function HUDController._updateCombatClock(self: HUDController)
    local state = self._currentState
    if state == nil then
        return
    end
    local combat = state.combat
    if type(combat) ~= "table" then
        self._staminaFrame.Visible = false
        self._dodge.Visible = self:_dodgeButtonVisible()
        return
    end

    local now = workspace:GetServerTimeNow()
    local stamina = math.max(0, tonumber(combat.stamina) or 0)
    local maxStamina = math.max(1, tonumber(combat.maxStamina) or 100)
    local dodgeCost = math.max(1, tonumber(combat.dodgeCost) or 35)
    local dodgeReadyAt = tonumber(combat.dodgeReadyAt) or 0
    local dodgeActiveUntil = tonumber(combat.dodgeActiveUntil) or 0
    local drowsyUntil = tonumber(combat.drowsyUntil) or 0
    local rootedUntil = tonumber(combat.rootedUntil) or 0
    local cooldownRemaining = math.max(0, dodgeReadyAt - now)
    local drowsyRemaining = math.max(0, drowsyUntil - now)
    local drowsy = combat.drowsy == true and drowsyRemaining > 0
    local rootedRemaining = math.max(0, rootedUntil - now)
    local rooted = combat.rooted == true and rootedRemaining > 0
    local combatEnabled = combat.enabled ~= false
    local dodgeActive = combatEnabled and now < dodgeActiveUntil
    local ready = combatEnabled
        and not self._playerDowned
        and cooldownRemaining <= 0
        and stamina >= dodgeCost

    self._staminaFill.Size = UDim2.new(math.clamp(stamina / maxStamina, 0, 1), -8, 1, -8)
    self._staminaFill.BackgroundColor3 = if rooted
        then COLORS.amber
        elseif drowsy then COLORS.amber
        elseif stamina < dodgeCost then COLORS.danger
        elseif stamina < maxStamina * 0.55 then COLORS.amber
        else COLORS.blue
    self._staminaText.Text = if rooted
        then string.format("ROOTED %.1fs · STAMINA %d", rootedRemaining, stamina)
        elseif drowsy then string.format(
            "DROWSY %.1fs · STAMINA %d",
            drowsyRemaining,
            stamina
        )
        elseif stamina < dodgeCost then string.format("LOW STAMINA · %d", stamina)
        else string.format("STAMINA · %d", stamina)
    self._staminaText.TextColor3 = if rooted
            or drowsy
            or stamina < maxStamina * 0.45
        then COLORS.cream
        else COLORS.ink
    self._staminaFrame.Visible = not self._playerDowned
        and (
            self._combatContext
            or rooted
            or drowsy
            or stamina < maxStamina
            or cooldownRemaining > 0
        )

    self._dodge.Active = ready
    self._dodge.AutoButtonColor = ready
    self._dodge.BackgroundColor3 = if dodgeActive
        then COLORS.green
        elseif ready then COLORS.panel
        else Color3.fromRGB(42, 48, 45)
    self._dodge.TextColor3 = if ready or dodgeActive then COLORS.cream else COLORS.muted
    local prefix = if self._inputMode == "keyboard"
        then "ALT\n"
        elseif self._inputMode == "gamepad" then "B\n"
        else ""
    self._dodge.Text = if dodgeActive
        then "DODGE\nACTIVE"
        elseif not combatEnabled then "DODGE\nOFF"
        elseif cooldownRemaining > 0 then string.format("DODGE\n%.1fs", cooldownRemaining)
        elseif stamina < dodgeCost then "DODGE\nLOW"
        else prefix .. "DODGE"
end

function HUDController._updateProfessionClock(self: HUDController)
    local state = self._currentState
    if state == nil then
        return
    end
    --[[
        The hound's order button follows the hound, not the profession: a
        keeper standing in town has one, a keeper mid-expedition does not,
        and the server is the one that knows which.
    ]]
    local companion = state.companion
    local hasCompanion = type(companion) == "table" and companion.present == true
    self._companion.Visible = hasCompanion
    if hasCompanion then
        self._companionMode = if companion.mode == "stay" then "stay" else "follow"
        -- the button names the order it will give, not the state it is in
        self._companion.Text = if self._companionMode == "follow" then "STAY" else "FOLLOW"
    end

    local profession = state.profession
    if type(profession) ~= "table" or profession.enabled == false then
        self._professionButton.Visible = false
        self._ability.Visible = false
        self:setProfessionMenuOpen(false)
        return
    end

    local selectedId = if type(profession.selectedId) == "string"
        then profession.selectedId
        else nil
    local displayName = if type(profession.displayName) == "string"
        then profession.displayName
        else nil
    self._professionSwitchable = profession.switchable == true
    self._professionButton.Visible = state.tutorialComplete == true
    self._professionButton.Active = self._professionSwitchable
    self._professionButton.AutoButtonColor = self._professionSwitchable
    self._professionButton.BackgroundColor3 = if self._professionSwitchable
        then COLORS.panel
        else Color3.fromRGB(42, 48, 45)
    self._professionButton.TextColor3 = if self._professionSwitchable
        then COLORS.amber
        else COLORS.muted
    -- "Profession", not "kit": kit is reserved for the purchasable
    -- character kits (docs/CHARACTER_KITS_SPEC.md), and selling one word
    -- while the HUD uses it for a free system would be a bait.
    self._professionButton.Text = if displayName == nil
        then "PROFESSION"
        else "ROLE · " .. displayName

    for professionId, card in self._professionCards do
        local selected = professionId == selectedId
        local baseText = tostring(card:GetAttribute("BaseText") or "")
        card.Text = if selected then "✓ EQUIPPED\n" .. baseText else baseText
        card.BackgroundColor3 = if selected then Color3.fromRGB(37, 68, 55) else COLORS.panelSoft
        card.TextColor3 = if selected then COLORS.cream else COLORS.muted
        local cardStroke = card:FindFirstChildOfClass("UIStroke")
        if cardStroke ~= nil then
            cardStroke.Color = if selected then COLORS.amber else COLORS.cream
            cardStroke.Transparency = if selected then 0.08 else 0.7
            cardStroke.Thickness = if selected then 2.5 else 1.5
        end
    end

    if not self._professionSwitchable and self._professionMenuOpen then
        self:setProfessionMenuOpen(false)
    end
    if selectedId == nil then
        self._ability.Visible = false
        return
    end

    local now = workspace:GetServerTimeNow()
    local readyAt = tonumber(profession.cooldownReadyAt) or 0
    local activeUntil = tonumber(profession.activeUntil) or 0
    local remaining = math.max(0, readyAt - now)
    local active = now < activeUntil
    local ready = profession.enabled ~= false and not self._playerDowned and remaining <= 0
    local abilityName = string.upper(tostring(profession.abilityName or "ABILITY"))
    local compactAbilityName = string.gsub(abilityName, " ", "\n", 1)
    local prefix = if self._inputMode == "keyboard"
        then "Q\n"
        elseif self._inputMode == "gamepad" then "L1\n"
        else ""

    self._ability.Visible = not self._playerDowned
    self._ability.Active = ready
    self._ability.AutoButtonColor = ready
    self._ability.BackgroundColor3 = if active
        then COLORS.green
        elseif ready then COLORS.panel
        else Color3.fromRGB(42, 48, 45)
    self._ability.TextColor3 = if ready or active then COLORS.cream else COLORS.muted
    self._ability.Text = if active
        then string.format("%s\n%.1fs", compactAbilityName, math.max(0, activeUntil - now))
        elseif remaining > 0 then string.format("%s\n%.1fs", compactAbilityName, remaining)
        else prefix .. compactAbilityName
end

-- Each craftable item gets its own fixed button rather than a picker, the
-- same one-button-one-outcome choice the crafting benches themselves use;
-- a button simply disappears once its item count reaches zero.
function HUDController._updateGear(self: HUDController)
    local state = self._currentState
    local gear = if type(state) == "table" and type(state.gear) == "table" then state.gear else nil
    local tutorialComplete = type(state) == "table" and state.tutorialComplete == true
    local usable = tutorialComplete and not self._playerDowned

    local slot = 0
    for _, definition in Consumables.list() do
        local count = if gear ~= nil then tonumber(gear[definition.id]) or 0 else 0
        if count > 0 and slot < MAX_USE_BUTTONS then
            slot += 1
            local button = self._useButtons[slot]
            local accent =
                Color3.fromRGB(definition.accent[1], definition.accent[2], definition.accent[3])
            button:SetAttribute("ItemId", definition.id)
            button.Text = string.format("%s ×%d", definition.shortLabel, count)
            button.TextColor3 = accent
            button.Visible = usable
            local outline = button:FindFirstChildOfClass("UIStroke")
            if outline ~= nil then
                outline.Color = accent
            end
            local icon = button:FindFirstChild("ItemIcon")
            if icon == nil or icon:GetAttribute("ItemId") ~= definition.id then
                if icon ~= nil then
                    icon:Destroy()
                end
                createItemIcon(button, definition.id, 30)
                local made = button:FindFirstChild("ItemIcon")
                if made ~= nil then
                    made:SetAttribute("ItemId", definition.id)
                end
            end
        end
    end
    for index = slot + 1, MAX_USE_BUTTONS do
        local button = self._useButtons[index]
        button:SetAttribute("ItemId", "")
        button.Visible = false
    end
end

function HUDController._updateProgress(self: HUDController)
    local state = self._currentState
    if type(state) ~= "table" then
        self._progressButton.Visible = false
        return
    end
    local complete = state.tutorialComplete == true
    self._progressButton.Visible = complete and not self._playerDowned
    --[[
        The Field Book reads like a book now, not a debug dump: amber section
        headers with rules under them, muted secondary detail, and empty
        sections that say something human. Everything stays one RichText
        label, so the change is presentation only. escape() guards the angle
        brackets because entry text flows into markup.
    ]]
    local function escape(text: string): string
        return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
    end
    local function header(title: string): string
        return string.format(
            '<font color="#FFBA5C"><b>%s</b></font>\n<font color="#8A7A62">━━━━━━━━━━━━━━━━━━</font>',
            escape(title)
        )
    end
    local function muted(text: string): string
        return string.format('<font color="#B8A88F">%s</font>', escape(text))
    end
    local lines = { header("RECIPES") }
    if #(state.recipes or {}) == 0 then
        table.insert(lines, muted("Nothing learned yet — find a workbench."))
    end
    for _, recipe in state.recipes or {} do
        local materials = {}
        for materialId, amount in recipe.materials do
            table.insert(
                materials,
                string.format("%s ×%d", string.gsub(materialId, "material_", ""), amount)
            )
        end
        table.insert(
            lines,
            string.format(
                "• %s  %s",
                escape(recipe.displayName),
                muted(table.concat(materials, ", "))
            )
        )
    end
    table.insert(lines, "")
    table.insert(lines, header("QUESTS"))
    if #(state.quests or {}) == 0 then
        table.insert(lines, muted("No open quests."))
    end
    for _, quest in state.quests or {} do
        local status = if quest.claimed
            then "CLAIMED"
            else string.format("%d/%d", quest.progress, quest.threshold)
        table.insert(lines, string.format("• %s  ·  %s", escape(quest.displayName), status))
    end
    --[[
        The Memory Archive.

        Missing fragments are listed by the place that holds them rather than
        hidden behind a blank, because the pull this system is for is "there
        is more to know and I know where to look" -- not a checklist with the
        labels torn off. Recovered ones show their text, so the archive is
        where the chapter can actually be read back.
    ]]
    local archive = state.memoryArchive
    if type(archive) == "table" then
        table.insert(lines, "")
        table.insert(
            lines,
            header(
                string.format(
                    "MEMORY ARCHIVE · %d / %d RECOVERED",
                    tonumber(archive.found) or 0,
                    tonumber(archive.total) or 0
                )
            )
        )
        for _, entry in archive.entries or {} do
            if entry.recovered then
                table.insert(lines, string.format("• <b>%s</b>", escape(tostring(entry.title))))
                table.insert(lines, muted("    " .. tostring(entry.body)))
            else
                table.insert(
                    lines,
                    muted(string.format("• unfound · %s", string.upper(tostring(entry.foundAt))))
                )
            end
        end
    end
    local residentLife = state.residentLife
    if type(residentLife) == "table" and type(residentLife.residents) == "table" then
        table.insert(lines, "")
        table.insert(lines, header("RESIDENTS"))
        local townHost = state.townHost
        if type(townHost) == "table" and townHost.role == "visitor" then
            table.insert(
                lines,
                muted(
                    string.format(
                        "You are a guest in %s's Emberhollow — your help carries, your damage doesn't.",
                        tostring(townHost.hostName or "a founder")
                    )
                )
            )
        end
        if type(residentLife.crisis) == "table" then
            table.insert(
                lines,
                string.format(
                    '<font color="#FF8A5C"><b>%s</b></font>  ·  %s',
                    escape(tostring(residentLife.crisis.title)),
                    muted(tostring(residentLife.crisis.detail))
                )
            )
        end
        for _, resident in residentLife.residents do
            if resident.present then
                local name = string.upper(
                    (string.gsub(string.gsub(tostring(resident.residentId), "npc_", ""), "_", " "))
                )
                local status = if resident.injured then "RESTING — check on them" else "working"
                table.insert(
                    lines,
                    string.format(
                        "• %s  ·  %s  ·  %s  ·  %s",
                        escape(name),
                        escape(tostring(resident.title)),
                        muted(status),
                        muted(
                            string.format("%s · %d", tostring(resident.bondTitle), resident.bond)
                        )
                    )
                )
            end
        end
    end
    local decorations = state.decorations
    if type(decorations) == "table" and (tonumber(decorations.cap) or 0) > 0 then
        table.insert(
            lines,
            muted(
                string.format(
                    "Decorations placed · %d / %d — marked spots around town take materials.",
                    tonumber(decorations.count) or 0,
                    tonumber(decorations.cap) or 0
                )
            )
        )
    end
    table.insert(lines, "")
    table.insert(lines, header("PROFESSION MASTERY"))
    for professionId, mastery in state.mastery or {} do
        table.insert(
            lines,
            string.format(
                "• %s  ·  RANK %d  ·  %s",
                string.upper(string.gsub(professionId, "profession_", "")),
                mastery.level,
                muted(string.format("%d XP", mastery.xp))
            )
        )
    end
    local equipped = state.equipped or {}
    table.insert(lines, "")
    table.insert(lines, header("LOADOUT"))
    if equipped.head == nil and equipped.feet == nil then
        table.insert(lines, muted("Nothing equipped yet — craft gear at the workbenches."))
    else
        table.insert(
            lines,
            string.format(
                "• HEAD  ·  %s\n• FEET  ·  %s",
                escape(tostring(equipped.head or "empty")),
                escape(tostring(equipped.feet or "empty"))
            )
        )
    end
    self._progressText.Text = table.concat(lines, "\n")
    local gear = state.gear or {}
    local care = if type(state.gearCare) == "table" then state.gearCare else {}
    -- What a player owns decides which buttons exist; the canvas decides
    -- where they go, so the grid is laid out afterwards by _layoutLoadout
    -- rather than counted out here against an assumed screen width.
    for _, entry in Equipment.list() do
        local itemId = entry.itemId
        local button = self._equipmentButtons[itemId]
        local count = tonumber(gear[itemId]) or 0
        button.Visible = self._progressOverlay.Visible and count > 0
        local label =
            string.format("%s ×%d", tostring(button:GetAttribute("BaseLabel") or "EQUIP"), count)
        local note = care[itemId]
        if type(note) == "table" then
            if type(note.trait) == "string" then
                label ..= " · " .. note.trait
            end
            if note.condition == "worn" then
                label ..= " · WORN"
            elseif note.condition == "failing" then
                label ..= " · FAILING"
            end
        end
        button.Text = label
    end
    local whetTarget = state.whetTarget
    if type(whetTarget) == "table" and type(whetTarget.itemId) == "string" then
        self._whetItemId = whetTarget.itemId
        self._whetButton.Text = tostring(whetTarget.label or "WHET")
        self._whetButton.Visible = self._progressOverlay.Visible
    else
        self._whetItemId = nil
        self._whetButton.Visible = false
    end
    self:_layoutLoadout()
end

--[[
    The field book's panel and everything pinned inside it or to the screen's
    bottom-left corner, measured against the canvas rather than written down.

    The loadout row was three buttons 176 wide at a 190-point pitch starting
    at 20, which needs about 590 points of width. A portrait phone gives the
    canvas roughly 500, so the third button hung off the screen -- and the
    panel the kit rows live in was itself wider than the whole canvas. Rows,
    pitch, button width and the panel all come from the measurement now, so
    one layout fills a desktop and fits a phone.
]]
function HUDController._layoutLoadout(self: HUDController)
    local _viewport, _scale, canvasWidth, canvasHeight = canvasMetrics()
    local margin = 20
    local gap = 14

    local panelWidth = math.min(620, math.max(280, canvasWidth - margin * 2))
    local panelHeight = math.min(500, math.max(300, canvasHeight - 40))
    self._progressPanel.Size = UDim2.fromOffset(panelWidth, panelHeight)

    -- One save/apply pair per kit, three kits across the panel's inner width.
    -- The pair keeps its authored 88/4/84 split at full width.
    local pairWidth =
        math.max(72, math.min(176, math.floor((panelWidth - margin * 2 - gap * 2) / 3)))
    local saveWidth = math.floor(pairWidth / 2)
    for slot = 1, 3 do
        local left = margin + (slot - 1) * (pairWidth + gap)
        local save = self._loadoutButtons["save_" .. slot]
        local apply = self._loadoutButtons["apply_" .. slot]
        save.Position = UDim2.fromOffset(left, 58)
        save.Size = UDim2.fromOffset(saveWidth, 30)
        apply.Position = UDim2.fromOffset(left + saveWidth + 4, 58)
        apply.Size = UDim2.fromOffset(pairWidth - saveWidth - 4, 30)
    end
    self._whetButton.Size = UDim2.fromOffset(math.min(220, panelWidth - margin * 2), 30)

    --[[
        Equip buttons stack upward from the bottom-left of the SCREEN, not the
        panel, so the canvas bounds their grid. Columns come from the width
        that is really there; a player who owns more gear than that grid holds
        without running off the top gets narrower buttons instead, because a
        button nobody can reach is how ninety craftable items once went
        unwearable with every spec green.
    ]]
    local owned = 0
    for _, entry in Equipment.list() do
        if self._equipmentButtons[entry.itemId].Visible then
            owned += 1
        end
    end
    local rowPitch = 46
    local available = math.max(120, canvasWidth - margin * 2)
    local maxRows = math.max(1, math.floor((canvasHeight - 58) / rowPitch))
    local columns = math.clamp(math.floor((available + gap) / (176 + gap)), 1, 3)
    if owned > columns * maxRows then
        columns = math.min(
            math.ceil(owned / maxRows),
            math.max(columns, math.floor((available + gap) / (88 + gap)))
        )
    end
    local buttonWidth = math.min(176, math.floor((available - gap * (columns - 1)) / columns))
    local visibleIndex = 0
    for _, entry in Equipment.list() do
        local button = self._equipmentButtons[entry.itemId]
        if button.Visible then
            button.Size = UDim2.fromOffset(buttonWidth, 38)
            button.Position = UDim2.new(
                0,
                margin + (visibleIndex % columns) * (buttonWidth + gap),
                1,
                -58 - math.floor(visibleIndex / columns) * rowPitch
            )
            visibleIndex += 1
        end
    end
end

function HUDController.setInteraction(self: HUDController, label: string?, available: boolean)
    self._interactionLabel = label
    self._interactionAvailable = available
    if self._playerDowned then
        self._primary.Active = false
        self._primary.AutoButtonColor = false
        self._primary.BackgroundColor3 = Color3.fromRGB(42, 48, 45)
        self._primary.TextColor3 = COLORS.muted
        self._primary.Text = "DOWNED"
        return
    end
    self._primary.Active = available
    self._primary.AutoButtonColor = available
    self._primary.BackgroundColor3 = if available then COLORS.panel else Color3.fromRGB(42, 48, 45)
    self._primary.TextColor3 = if available then COLORS.cream else COLORS.muted
    local prefix = if self._inputMode == "keyboard"
        then "E · "
        elseif self._inputMode == "gamepad" then "X · "
        else ""
    self._primary.Text = if available and label ~= nil then prefix .. label else "FIND"
end

function HUDController.canInteractAction(self: HUDController, actionId: string): boolean
    local state = self._currentState
    if type(state) ~= "table" then
        return false
    end
    local stage = state.stage
    if stage == "complete" then
        return true
    end
    if stage == "arrive" then
        return actionId == "rescue"
    elseif stage == "gather" then
        return actionId == "gather"
    elseif stage == "choose_tool" then
        return actionId == "choose_tool"
    elseif stage == "build" then
        return actionId == "build"
    elseif stage == "prepare" then
        return actionId == "prepare"
    elseif stage == "reveal" then
        return actionId == "reveal"
    end
    -- During defense, revive and encounter interactions remain valid while
    -- the tutorial is advanced by the server's phase system.
    return actionId ~= "rescue"
        and actionId ~= "gather"
        and actionId ~= "choose_tool"
        and actionId ~= "build"
        and actionId ~= "prepare"
        and actionId ~= "reveal"
end

function HUDController._applyCompact(self: HUDController)
    self._detail.Visible = not self._compactEnabled
    self._mara.Visible = self:_maraLineIsFresh()
        and not self._compactEnabled
        and not self._playerDowned
    self._objective.Position = if self._compactEnabled
        then UDim2.fromOffset(14, 31)
        else UDim2.fromOffset(14, 32)
    self._compact.TextColor3 = if self._compactEnabled then COLORS.amber else COLORS.muted
    self:_layout()
end

function HUDController._layout(self: HUDController)
    local viewport, scale, canvasWidth, _canvasHeight = canvasMetrics()
    --[[
        Treat any touch device, and any short viewport, as the touch layout.

        Deciding on width alone put a landscape phone -- wide but only ~430
        points tall -- on the desktop layout, which tucks the objective panel
        into the top-left corner that Roblox's own menu, chat, and microphone
        buttons already occupy.
    ]]
    local narrow = viewport.X < 700 or viewport.Y < 560 or UserInputService.TouchEnabled
    self._scale.Scale = scale
    self._canvas.Size = UDim2.fromScale(1 / scale, 1 / scale)
    -- The departure panel is centred, so its own width is the only thing that
    -- can push it off a narrow screen.
    self._lobbyFrame.Size = UDim2.fromOffset(math.min(420, canvasWidth - 24), 246)

    if narrow then
        -- 470 is a tablet's card, not a phone's: capped to the canvas so the
        -- objective text cannot run past the right edge on a small screen.
        local cardWidth = math.min(470, canvasWidth - 36)
        self._objectiveFrame.Position = UDim2.fromOffset(18, 70)
        self._objectiveFrame.Size =
            UDim2.fromOffset(cardWidth, if self._compactEnabled then 78 else 112)
        self._resource.Position = UDim2.fromOffset(18, if self._compactEnabled then 158 else 218)
        self._compact.Size = UDim2.fromOffset(44, 38)
        self._compact.Text = if self._compactEnabled then "+" else "−"
        --[[
            Keep the middle of a phone screen clear.

            These rails used to start at 212 and chain down to 434, which on a
            ~640-point phone viewport is the exact band the creature you are
            trying to tap stands in -- the owner's report was that the fight
            UI hid the monsters. They now begin just under the objective card
            and stay in the top third, so the play area below them belongs to
            the world.
        ]]
        self._lanternFrame.Position = UDim2.new(0.5, 0, 0, 150)
        -- Tucked under the objective panel on the left rather than spanning
        -- the screen at eye level. At full width it sat straight across the
        -- middle of the view for the whole nine minutes of a Blackout.
        self._blackoutFrame.Position = UDim2.fromOffset(18, 196)
        self._blackoutFrame.Size = UDim2.fromOffset(cardWidth, 70)
        self._blackoutFrame.AnchorPoint = Vector2.new(0, 0)
        self._eliteFrame.Position =
            UDim2.new(0.5, 0, 0, if self._blackoutFrame.Visible then 222 else 150)
        self._eliteFrame.Size = UDim2.new(1, -36, 0, 64)
        self._allyFrame.Position = UDim2.new(
            0.5,
            0,
            0,
            if self._eliteFrame.Visible
                then (if self._blackoutFrame.Visible then 292 else 220)
                elseif self._blackoutFrame.Visible then 222
                elseif self._lanternFrame.Visible then 192
                else 150
        )
        self._allyFrame.Size = UDim2.new(1, -36, 0, 58)
        --[[
            Bottom-anchored on touch, not stacked under the objective rails:
            with the Blackout and elite rails both up, the old chain pushed
            the red telegraph banner to y=292+, which on a tablet is the
            middle of the fight -- the owner's screenshot had it lying
            across the Old Growth's trunk. The band above the action row is
            dead space on touch, and a warning about your feet belongs near
            them. Its height is settled below, once the cluster has been
            measured and there is something to sit above.
        ]]
        self._threatFrame.AnchorPoint = Vector2.new(0.5, 1)
        self._threatFrame.Size = UDim2.new(1, -36, 0, 60)
        self._downedFrame.Size = UDim2.new(1, -36, 0, 90)
        local professionY = if self._compactEnabled then 158 else 218
        self._professionButton.Position = UDim2.new(1, -18, 0, professionY)
        for index, button in self._useButtons do
            button.Position = UDim2.new(1, -18, 0, professionY + index * 46)
        end
        self._professionPanel.Size = UDim2.new(1, -24, 0, 440)
        --[[
            The thumb cluster is measured, not written down.

            Roblox owns both bottom corners on touch -- the jump button on the
            right, the thumbstick on the left -- and the five action buttons
            that have to sit between them need about 500 points of row. The
            offsets that used to be here (-300 through -630) were picked on a
            canvas over a thousand points wide; a portrait phone's canvas is
            about 500 points in total, so FIND sat with its left half off the
            screen, STRIKE and DODGE were entirely off it, and HOUND -- which
            nothing ever repositioned for touch at all -- was drawn straight on
            top of FIND. The run now starts inboard of jump and steps left by
            each button's own width, wrapping up a row when the next one would
            reach the thumbstick, and both insets scale with the canvas because
            Roblox's own controls do.

            The primary action leads the run, so it is the one that keeps the
            corner nearest the thumb on every screen, and RUN follows it -- the
            thumb that jumps is the thumb that sprints, which is where the
            owner asked for it. RUN is inside the run rather than on a line of
            its own because a line of its own is a fixed offset again, and on a
            wrapped cluster a fixed offset lands on another button.
        ]]
        local jumpInset = math.clamp(canvasWidth * 0.28, 150, 300)
        local stickInset = math.clamp(canvasWidth * 0.34, 120, 190)
        local cursor = jumpInset
        local actionRow = 0
        -- RUN is built anchored to the left edge for the desktop layout; the
        -- run measures from the right, so it joins on the same terms.
        self._sprint.AnchorPoint = Vector2.new(1, 1)
        for _, entry in
            {
                { button = self._primary, width = 116 },
                { button = self._sprint, width = 80 },
                { button = self._tool, width = 84 },
                { button = self._ability, width = 84 },
                { button = self._companion, width = 84 },
                { button = self._dodge, width = 84 },
            }
        do
            -- Only the bottom row has to clear the thumbstick; the band above
            -- it is dead space on touch.
            local leftLimit = if actionRow == 0 then stickInset else 24
            if cursor > jumpInset and cursor + entry.width > canvasWidth - leftLimit then
                actionRow += 1
                cursor = jumpInset
            end
            entry.button.Position = UDim2.new(1, -cursor, 1, -34 - actionRow * ACTION_ROW_PITCH)
            cursor += entry.width + 12
        end
        -- Above the cluster's topmost row rather than at a fixed 206, which on
        -- a portrait phone lands across the upper half of STRIKE and ABILITY.
        -- A cluster that fits one row keeps the 206 the tablet pass settled on.
        self._threatFrame.Position =
            UDim2.new(0.5, 0, 1, -math.max(206, 34 + actionRow * ACTION_ROW_PITCH + 84 + 10))
    else
        self._objectiveFrame.Position = UDim2.fromOffset(18, 18)
        self._objectiveFrame.Size = if self._compactEnabled
            then UDim2.fromOffset(284, 76)
            else UDim2.fromOffset(326, 132)
        self._resource.Position = UDim2.fromOffset(18, 164)
        self._compact.Size = UDim2.fromOffset(118, 38)
        self._compact.Text = if self._compactEnabled then "EXPAND" else "COMPACT"
        self._lanternFrame.Position = UDim2.new(0.5, 0, 0, 66)
        self._blackoutFrame.Position = UDim2.new(0.5, 0, 0, 66)
        self._blackoutFrame.Size = UDim2.fromOffset(420, 64)
        self._eliteFrame.Position =
            UDim2.new(0.5, 0, 0, if self._blackoutFrame.Visible then 138 else 66)
        self._eliteFrame.Size = UDim2.fromOffset(420, 70)
        self._allyFrame.Position = UDim2.new(
            0.5,
            0,
            0,
            if self._eliteFrame.Visible
                then (if self._blackoutFrame.Visible then 216 else 144)
                elseif self._blackoutFrame.Visible then 138
                elseif self._lanternFrame.Visible then 108
                else 66
        )
        self._allyFrame.Size = UDim2.fromOffset(330, 64)
        self._threatFrame.AnchorPoint = Vector2.new(0.5, 0)
        self._threatFrame.Position = UDim2.fromScale(0.5, 0.32)
        self._threatFrame.Size = UDim2.fromOffset(330, 66)
        self._downedFrame.Size = UDim2.fromOffset(540, 90)
        self._professionButton.Position = UDim2.new(1, -18, 0, 64)
        for index, button in self._useButtons do
            button.Position = UDim2.new(1, -18, 0, 110 + (index - 1) * 46)
        end
        self._professionPanel.Size = UDim2.fromOffset(640, 440)
        --[[
            The desktop run, restated rather than left to the values the
            buttons were created with: a window dragged narrow and back wide
            again has to undo the wrapped cluster, and four of these five used
            to be positioned nowhere but at construction.
        ]]
        self._primary.Position = UDim2.new(1, -28, 1, -30)
        self._tool.Position = UDim2.new(1, -158, 1, -40)
        self._dodge.Position = UDim2.new(1, -252, 1, -40)
        self._ability.Position = UDim2.new(1, -346, 1, -40)
        self._companion.Position = UDim2.new(1, -440, 1, -40)
        -- RUN stays where it was built on a desktop: left of the row, clear of
        -- the mouse-driven cluster on the right.
        self._sprint.Position = UDim2.new(0, 166, 1, -34)
        self._sprint.AnchorPoint = Vector2.new(0, 1)
    end
    self:_layoutLoadout()
end

function HUDController._presentPhase(self: HUDController, phase: string)
    local accent = if phase == "DUSK"
        then Color3.fromRGB(255, 164, 91)
        elseif phase == "NIGHT" then Color3.fromRGB(174, 211, 255)
        elseif phase == "REVEAL" then Color3.fromRGB(172, 255, 205)
        else COLORS.amber

    self._phase.TextColor3 = accent
    local phaseStroke = self._phaseFrame:FindFirstChildOfClass("UIStroke")
    if phaseStroke ~= nil then
        phaseStroke.Color = accent
    end

    local scale = self._phaseFrame:FindFirstChild("PhasePulse")
    if scale == nil then
        scale = Instance.new("UIScale")
        scale.Name = "PhasePulse"
        scale.Parent = self._phaseFrame
    end
    if scale:IsA("UIScale") then
        scale.Scale = 1.06
        TweenService:Create(
            scale,
            TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Scale = 1 }
        ):Play()
    end
    self._phase.TextTransparency = 0.22
    TweenService:Create(
        self._phase,
        TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { TextTransparency = 0 }
    ):Play()
end

function HUDController._updateClock(self: HUDController)
    local state = self._currentState
    if state == nil then
        return
    end

    local phase = string.upper(tostring(state.phase or "day"))
    if phase ~= self._lastPhase then
        self._lastPhase = phase
        self:_presentPhase(phase)
    end
    local phaseEndsAt = tonumber(state.phaseEndsAt) or 0
    local blackout = state.blackout
    local blackoutVisible = type(blackout) == "table"
        and blackout.status ~= "dormant"
        and blackout.status ~= "disabled"
        and not self._playerDowned
    local clockText: string
    if blackoutVisible and blackout.status ~= "complete" then
        local targetEndsAt = tonumber(blackout.targetEndsAt) or 0
        local remaining = math.max(0, math.ceil(targetEndsAt - workspace:GetServerTimeNow()))
        clockText = if remaining > 0
            then string.format("BLACKOUT · %02d:%02d", math.floor(remaining / 60), remaining % 60)
            else "BLACKOUT · OVERTIME"
    elseif blackoutVisible then
        clockText = "DAWN · CHAPTER I"
    elseif phaseEndsAt > 0 then
        local remaining = math.max(0, math.ceil(phaseEndsAt - workspace:GetServerTimeNow()))
        -- "LEFT" because "DAY · 02:58" reads as three in the morning, not as
        -- a countdown. Two glyphs of clarity beat two glyphs of mystery.
        clockText =
            string.format("%s · %02d:%02d LEFT", phase, math.floor(remaining / 60), remaining % 60)
    else
        clockText = if phase == "REVEAL" then "DAWN · FIRST LIGHT" else phase .. " · MORNING"
    end
    if self._phase.Text ~= clockText then
        self._phase.Text = clockText
    end
    self:_updateCombatClock()
    self:_updateProfessionClock()

    if blackoutVisible then
        local duration = math.max(1, tonumber(blackout.duration) or 1)
        local targetEndsAt = tonumber(blackout.targetEndsAt) or 0
        local startedAt = targetEndsAt - duration
        local elapsed = if targetEndsAt <= 0
            then tonumber(blackout.elapsed) or 0
            else math.max(0, workspace:GetServerTimeNow() - startedAt)
        self._blackoutFill.Size = UDim2.fromScale(math.clamp(elapsed / duration, 0, 1), 1)
        self._blackoutFill.BackgroundColor3 = if blackout.status == "complete"
            then COLORS.green
            elseif blackout.overtime then COLORS.danger
            else COLORS.blue
        self._blackoutTitle.Text = string.format(
            "BRAMBLEWAKE BLACKOUT · %s · %d/%d",
            tostring(blackout.stageLabel or "STAGE"),
            tonumber(blackout.stage) or 0,
            tonumber(blackout.stageCount) or 4
        )
        if blackout.status == "relay" then
            if blackout.carryingFire then
                local fireRemaining = math.max(
                    0,
                    (tonumber(blackout.fireExpiresAt) or 0) - workspace:GetServerTimeNow()
                )
                self._blackoutDetail.Text = string.format(
                    "CARRY ROOTFIRE %.1fs → %s · %d/%d",
                    fireRemaining,
                    tostring(blackout.nextNodeLabel or "NEXT ROOT"),
                    tonumber(blackout.deliveredNodes) or 0,
                    tonumber(blackout.relayRequired) or 3
                )
            else
                self._blackoutDetail.Text = string.format(
                    "TAKE ROOTFIRE → %s · %d/%d",
                    tostring(blackout.nextNodeLabel or "NEXT ROOT"),
                    tonumber(blackout.deliveredNodes) or 0,
                    tonumber(blackout.relayRequired) or 3
                )
            end
        elseif blackout.status == "old_growth" then
            self._blackoutDetail.Text = "ROOTED WALLS · CLEANSE OLD GROWTH"
        elseif blackout.status == "warden" then
            self._blackoutDetail.Text = "WARDEN'S SEAL · CLEANSE OR BREAK ANTLERS"
        elseif blackout.status == "resolution" then
            self._blackoutDetail.Text = if blackout.vote == nil
                then "VOTE: FARMLAND · WILD · SHARED AGROFOREST"
                else "VOTE RECORDED · WAITING FOR ACTIVE TRAVELERS"
        else
            local decision = string.upper(
                (string.gsub(tostring(blackout.decision or "chapter resolved"), "_", " "))
            )
            local outcome = string.upper(tostring(blackout.wardenOutcome or "remembered"))
            self._blackoutDetail.Text = decision .. " · FOREST " .. outcome
        end
        self._blackoutDetail.TextColor3 = if blackout.status == "complete"
            then COLORS.green
            elseif blackout.overtime then COLORS.danger
            else COLORS.blue
    end
    self._blackoutFrame.Visible = blackoutVisible

    local boss = state.boss
    local elite = state.elite
    local apex = if type(boss) == "table"
            and (boss.active == true or boss.complete == true)
        then boss
        else elite
    local bossView = apex == boss and type(boss) == "table"
    if type(apex) == "table" and not self._playerDowned then
        local health = math.max(0, tonumber(apex.health) or 0)
        local maxHealth = math.max(1, tonumber(apex.maxHealth) or 1)
        local apexPhase = math.clamp(tonumber(apex.phase) or 1, 1, 3)
        self._eliteTitle.Text = string.format(
            "%s · PHASE %d/3 · %d/%d",
            if bossView then "WARDEN STAG" else "OLD GROWTH",
            apexPhase,
            health,
            maxHealth
        )
        self._eliteFill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
        self._eliteFill.BackgroundColor3 = if apex.complete
            then COLORS.green
            elseif bossView and apex.exposed ~= true then COLORS.blue
            elseif apex.shielded then COLORS.danger
            else COLORS.amber
        if apex.complete then
            self._eliteDetail.Text = if bossView
                then if apex.outcome == "preserved"
                    then "CALMED · FOREST ALLY PRESERVED · +5 AMBER SAP"
                    elseif apex.outcome == "harmed" then "DEFEATED · FOREST HARMED · +5 AMBER SAP"
                    else "DEFEATED · FOREST SCARRED · +5 AMBER SAP"
                elseif apex.rewardEligible then "CLEANSED · +3 AMBER SAP UNBANKED"
                else "CLEANSED · CONTINUE TO WAYHOME"
            self._eliteDetail.TextColor3 = COLORS.green
        elseif bossView and apex.exposed then
            self._eliteDetail.Text = "HEART EXPOSED · STRIKE THE MEMORY SEAL"
            self._eliteDetail.TextColor3 = COLORS.amber
        elseif bossView then
            self._eliteDetail.Text = string.format(
                "ROOTS %d/%d · PRESERVE: CLEANSE · ANTLERS %d/2",
                tonumber(apex.cleansedNodes) or 0,
                tonumber(apex.rootNodesRequired) or 0,
                tonumber(apex.antlersBroken) or 0
            )
            self._eliteDetail.TextColor3 = if (tonumber(apex.antlersBroken) or 0) > 0
                then COLORS.danger
                else COLORS.blue
        elseif apex.carryingFire then
            local fireRemaining =
                math.max(0, (tonumber(apex.fireExpiresAt) or 0) - workspace:GetServerTimeNow())
            self._eliteDetail.Text =
                string.format("FIRE %.1fs · REACH THE ROOT HEART", fireRemaining)
            self._eliteDetail.TextColor3 = COLORS.amber
        elseif apex.shielded then
            self._eliteDetail.Text = "SHIELDED · TAKE LANTERN FIRE"
            self._eliteDetail.TextColor3 = COLORS.danger
        else
            self._eliteDetail.Text = "EXPOSED · STRIKE THE AMBER HEART"
            self._eliteDetail.TextColor3 = COLORS.amber
        end
        self._eliteFrame.Visible = apex.active == true or apex.complete == true
    else
        self._eliteFrame.Visible = false
    end
    self._lanternFrame.Visible = state.nightActive == true
        and not self._eliteFrame.Visible
        and not blackoutVisible

    local threat = state.threat
    if type(threat) == "table" and not self._playerDowned then
        local remaining =
            math.max(0, (tonumber(threat.resolvesAt) or 0) - workspace:GetServerTimeNow())
        local enemyName = tostring(threat.enemyName or "THREAT")
        local attackName = tostring(threat.displayName or "ATTACK")
        local title = if string.find(attackName, enemyName, 1, true) ~= nil
            then attackName
            else enemyName .. " · " .. attackName
        local shape = if threat.shape == "lane" then "LANE" else "RING"
        self._threatTitle.Text = "!! " .. title
        self._threatDetail.Text = string.format(
            "%s · %s · %.1fs",
            shape,
            tostring(threat.instruction or "MOVE"),
            remaining
        )
        self._threatFrame.Visible = remaining > 0
    else
        self._threatFrame.Visible = false
    end

    local survival = state.survival
    if type(survival) ~= "table" then
        return
    end
    local selfState = survival.self
    if type(selfState) == "table" and selfState.downed == true then
        local bleedoutAt = tonumber(selfState.bleedoutAt) or 0
        local remaining = math.max(0, math.ceil(bleedoutAt - workspace:GetServerTimeNow()))
        local downedDuration = math.max(1, tonumber(selfState.downedDuration) or remaining)
        self._downedTimer.Text =
            string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
        self._downedFill.Size = UDim2.fromScale(math.clamp(remaining / downedDuration, 0, 1), 1)
        local nearest = selfState.nearestAlly
        self._downedAlly.Text = if type(nearest) == "table"
            then string.format(
                "HELP ACTIVE · %s %dm · %s",
                tostring(nearest.direction or "UNKNOWN"),
                tonumber(nearest.distance) or 0,
                string.upper(tostring(nearest.displayName or "ALLY"))
            )
            else "HELP SIGNAL ACTIVE · NO ALLY NEARBY"
    end
    local ally = survival.ally
    if type(ally) == "table" and not self._playerDowned then
        local bleedoutAt = tonumber(ally.bleedoutAt) or 0
        local remaining = math.max(0, math.ceil(bleedoutAt - workspace:GetServerTimeNow()))
        self._allyTitle.Text = "✚ ALLY DOWN · "
            .. string.upper(tostring(ally.displayName or "ALLY"))
        self._allyDetail.Text = string.format(
            "%s · %dm · %02ds%s",
            tostring(ally.direction or "UNKNOWN"),
            tonumber(ally.distance) or 0,
            remaining,
            if ally.reviveEndsAt ~= nil then " · REVIVING" else ""
        )
    end
end

function HUDController.update(self: HUDController, state: any)
    if type(state) ~= "table" or state.status ~= "ready" then
        return
    end
    self._currentState = state
    self:_updateLobby(state)
    local action = state.action
    if type(action) == "table" and action.active == true then
        self._actionFrame.Visible = true
        self._actionLabel.Text = tostring(action.label) .. "..."
        self._actionFill.Size = UDim2.fromScale(math.clamp(tonumber(action.alpha) or 0, 0, 1), 1)
    else
        self._actionFrame.Visible = false
    end
    -- Sprint is a toggle, not a hold, so the button has to show which it is.
    local combat = state.combat
    local running = type(combat) == "table" and combat.sprinting == true
    self._sprint.Text = if running then "RUNNING" else "RUN"
    self._sprint.BackgroundColor3 = if running then COLORS.blue else COLORS.panel
    local survival = state.survival
    local selfSurvival = if type(survival) == "table" then survival.self else nil
    self._playerDowned = type(selfSurvival) == "table" and selfSurvival.downed == true
    local elite = state.elite
    local boss = state.boss
    local blackout = state.blackout
    local eliteActive = type(elite) == "table" and elite.active == true
    local bossActive = type(boss) == "table" and boss.active == true
    local blackoutActive = type(blackout) == "table" and blackout.active == true
    self._combatContext = state.nightActive == true
        or state.expeditionActive == true
        or eliteActive
        or bossActive
        or blackoutActive
    local ally = if type(survival) == "table" then survival.ally else nil
    self._downedFrame.Visible = self._playerDowned
    self._allyFrame.Visible = type(ally) == "table" and not self._playerDowned
    self._toast.Position = if self._playerDowned
        then UDim2.new(0.5, 0, 1, -264)
        else UDim2.new(0.5, 0, 1, -222)
    -- In the lobby the story has not started: the objective card was
    -- already reading "FREE MARA" over the departure panel, pointing at a
    -- woman in a town the player had not left for. The card and the guide
    -- line belong to the world past the platform.
    local departedWorld = state.departed == true
    self._objectiveFrame.Visible = departedWorld
    self._mara.Visible = departedWorld
    self._objective.Text = tostring(state.objective or "")
    self._detail.Text = tostring(state.detail or "")
    self._progress.Text = string.format(
        "%s · %d / %d",
        tostring(state.trailName or "FIRST LIGHT"),
        tonumber(state.progress) or 0,
        tonumber(state.progressTotal) or 8
    )
    --[[
        Mara speaks and then stops.

        Her line used to sit on screen permanently, which turned a character
        remark into a permanent HUD element and left it contradicting whatever
        the player was doing minutes later. It now appears when she has
        something new to say and fades a few seconds afterwards; walking back
        to her produces a fresh line, which shows it again.
    ]]
    -- The guide line has a speaker now: Mara in town, the traveler's own
    -- inner voice out in the expedition, where she is not. An empty line
    -- stays silent even when the speaker changes -- otherwise crossing the
    -- gate would flash a bare "You:" with nothing after it.
    local guideText = tostring(state.mara or "")
    local maraLine = tostring(state.guideSpeaker or "Mara") .. ": " .. guideText
    if maraLine ~= self._maraText and guideText ~= "" then
        self._maraText = maraLine
        self._maraShownAt = os.clock()
        self._mara.Text = maraLine
        self._mara.TextTransparency = 0
    end
    --[[
        The held pill: what is in your hand right now. A weapon in the
        equipment slot outranks the starter tool, matching the visual on the
        character and the strike numbers on the server.
    ]]
    local equipped = state.equipped
    local heldWeapon = if type(equipped) == "table" and equipped.weapon ~= nil then "BOW" else nil
    self._resource.Text = string.format(
        "HEARTWOOD · %d%s",
        tonumber(state.resources) or 0,
        if heldWeapon ~= nil
            then "  ·  🏹 " .. heldWeapon
            elseif state.selectedTool ~= nil then "  ·  " .. string.upper(
                tostring(state.selectedTool)
            )
            else ""
    )
    local nightActive = state.nightActive == true
    local health = if type(selfSurvival) == "table"
        then tonumber(selfSurvival.health) or 100
        else 100
    local maxHealth = if type(selfSurvival) == "table"
        then tonumber(selfSurvival.maxHealth) or 100
        else 100
    self._health.Text = string.format("HEALTH · %d / %d", health, maxHealth)
    self._health.TextColor3 = if health <= 35 then COLORS.danger else COLORS.cream
    self._health.Visible = not self._playerDowned and (nightActive or health < maxHealth)
    self._resource.Visible = not nightActive
        and not blackoutActive
        and ((tonumber(state.resources) or 0) > 0 or state.selectedTool ~= nil)
    -- FIND and STRIKE now live on the world objects: tap the stump, tap the
    -- creature. Dead buttons cost the thing a phone screen has least of, so
    -- they stay hidden. Run, dodge, and ability remain because they have no
    -- target to tap.
    self._primary.Visible = false
    self._tool.Visible = false
        and (nightActive or eliteActive or bossActive or blackoutActive)
        and not self._playerDowned
    self._sprint.Visible = self._inputMode == "touch" and not self._playerDowned
    self._dodge.Visible = self:_dodgeButtonVisible()
    self:_updateProfessionClock()
    self:_updateGear()
    self:_updateProgress()
    local eliteVisible = (type(boss) == "table" and (boss.active == true or boss.complete == true))
        or (type(elite) == "table" and (elite.active == true or elite.complete == true))
    eliteVisible = eliteVisible and not self._playerDowned
    self._eliteFrame.Visible = eliteVisible
    local blackoutVisible = type(blackout) == "table"
        and blackout.status ~= "dormant"
        and blackout.status ~= "disabled"
        and not self._playerDowned
    self._blackoutFrame.Visible = blackoutVisible
    self._lanternFrame.Visible = nightActive and not eliteVisible and not blackoutVisible
    local lanternHealth = math.clamp(tonumber(state.lanternHealth) or 100, 0, 100)
    self._lanternFill.Size = UDim2.new(lanternHealth / 100, -8, 1, -8)
    self._lanternFill.BackgroundColor3 = if lanternHealth <= 35 then COLORS.danger else COLORS.amber
    self._lanternText.Text = string.format("LIGHT · %d%%", lanternHealth)
    self._lanternText.TextColor3 = if lanternHealth <= 55 then COLORS.cream else COLORS.ink

    if state.compactHud ~= nil and state.compactHud ~= self._compactEnabled then
        self._compactEnabled = state.compactHud == true
        self:_applyCompact()
    end
    self._mara.Visible = self:_maraLineIsFresh()
        and not self._compactEnabled
        and not self._playerDowned
    self:setInteraction(self._interactionLabel, self._interactionAvailable)
    self:_layout()
    self:_updateCombatClock()

    local revision = tonumber(state.toastRevision) or 0
    if revision > self._lastToastRevision and state.toast ~= nil then
        self._lastToastRevision = revision
        self._toast.Text = tostring(state.toast)
        self._toast.Visible = true
        local captured = revision
        task.delay(3.2, function()
            if self._lastToastRevision == captured then
                self._toast.Visible = false
            end
        end)
    end

    self:_updateClock()
end

return HUDController
