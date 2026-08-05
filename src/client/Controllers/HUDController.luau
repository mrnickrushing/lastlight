--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

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
        _progressButton: TextButton,
        _useCharm: TextButton,
        _useSatchel: TextButton,
        _professionOverlay: Frame,
        _professionPanel: Frame,
        _professionCards: { [string]: TextButton },
        _professionOrder: { string },
        _professionClose: TextButton,
        _progressOverlay: Frame,
        _progressText: TextLabel,
        _equipmentButtons: { [string]: TextButton },
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

    local useCharm = Instance.new("TextButton")
    useCharm.Name = "UseAmberCharm"
    useCharm.AnchorPoint = Vector2.new(1, 0)
    useCharm.Position = UDim2.new(1, -18, 0, 110)
    useCharm.Size = UDim2.fromOffset(118, 42)
    useCharm.BackgroundColor3 = COLORS.panel
    useCharm.BackgroundTransparency = 0.08
    useCharm.Font = Enum.Font.GothamBold
    useCharm.Text = "CHARM"
    useCharm.TextColor3 = COLORS.amber
    useCharm.TextSize = 12
    useCharm.Visible = false
    useCharm.ZIndex = 10
    useCharm.Parent = canvas
    corner(useCharm, 12)
    stroke(useCharm, COLORS.amber, 0.42)
    createItemIcon(useCharm, "gear_amber_charm", 30)
    useCharm.TextXAlignment = Enum.TextXAlignment.Right

    local useSatchel = Instance.new("TextButton")
    useSatchel.Name = "UseMeadowSatchel"
    useSatchel.AnchorPoint = Vector2.new(1, 0)
    useSatchel.Position = UDim2.new(1, -18, 0, 156)
    useSatchel.Size = UDim2.fromOffset(118, 42)
    useSatchel.BackgroundColor3 = COLORS.panel
    useSatchel.BackgroundTransparency = 0.08
    useSatchel.Font = Enum.Font.GothamBold
    useSatchel.Text = "SATCHEL"
    useSatchel.TextColor3 = Color3.fromRGB(133, 176, 108)
    useSatchel.TextSize = 12
    useSatchel.Visible = false
    useSatchel.ZIndex = 10
    useSatchel.Parent = canvas
    corner(useSatchel, 12)
    stroke(useSatchel, Color3.fromRGB(133, 176, 108), 0.42)
    createItemIcon(useSatchel, "gear_meadow_satchel", 30)
    useSatchel.TextXAlignment = Enum.TextXAlignment.Right

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
    local progressText = textLabel(
        progressPanel,
        "Details",
        "Loading field notes…",
        UDim2.new(1, -40, 1, -78),
        UDim2.fromOffset(20, 66),
        13,
        COLORS.cream
    )
    progressText.TextWrapped = true
    progressText.RichText = true
    progressText.TextYAlignment = Enum.TextYAlignment.Top
    progressText.ZIndex = 52
    local equipmentButtons: { [string]: TextButton } = {}
    -- Three per row, newest row stacking upward: eight equippables no longer
    -- fit the single strip the first three shipped on. Buttons stay hidden
    -- until owned, so a fresh save still sees an empty margin, not a wall.
    for index, item in
        {
            { id = "gear_ironroot_hood", label = "EQUIP HOOD" },
            { id = "gear_bramble_boots", label = "EQUIP BOOTS" },
            { id = "gear_thornwood_bow", label = "EQUIP BOW" },
            { id = "gear_heartwood_maul", label = "EQUIP MAUL" },
            { id = "gear_briar_lance", label = "EQUIP LANCE" },
            { id = "gear_foxfire_sling", label = "EQUIP SLING" },
            { id = "gear_amber_edge", label = "EQUIP EDGE" },
            { id = "gear_warden_cudgel", label = "EQUIP CUDGEL" },
        }
    do
        local button = Instance.new("TextButton")
        button.Name = item.id
        local buttonRow = math.floor((index - 1) / 3)
        local buttonColumn = (index - 1) % 3
        button.Position = UDim2.new(0, 20 + buttonColumn * 190, 1, -58 - buttonRow * 46)
        button.Size = UDim2.fromOffset(176, 38)
        button.BackgroundColor3 = COLORS.panelSoft
        button.Font = Enum.Font.GothamBold
        button.Text = item.label
        button.TextColor3 = COLORS.cream
        button.TextSize = 11
        button.Visible = false
        button.ZIndex = 52
        button.Parent = progressPanel
        corner(button, 10)
        stroke(button, COLORS.amber, 0.45)
        createItemIcon(button, item.id, 28)
        button.TextXAlignment = Enum.TextXAlignment.Right
        equipmentButtons[item.id] = button
    end
    -- Kit rows: three saved loadouts, save on the left, apply on the right,
    -- stacked above the equipment buttons' rows.
    local loadoutButtons: { [string]: TextButton } = {}
    for slot = 1, 3 do
        for _, kind in { "save", "apply" } do
            local button = Instance.new("TextButton")
            button.Name = string.format("Loadout_%s_%d", kind, slot)
            button.Position =
                UDim2.fromOffset(20 + (slot - 1) * 190 + (if kind == "apply" then 92 else 0), 104)
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
    lobbyFrame.Size = UDim2.fromOffset(420, 186)
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
        _contractButtons = contractButtons,
        _selectedContractId = "contract_standard",
        _departurePlatformPart = nil,
        _departurePlatformPosition = nil,
        _onLobbyDepart = nil,
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
        _compact = compact,
        _professionButton = professionButton,
        _progressButton = progressButton,
        _useCharm = useCharm,
        _useSatchel = useSatchel,
        _professionOverlay = professionOverlay,
        _professionPanel = professionPanel,
        _professionCards = professionCards,
        _professionOrder = professionOrder,
        _professionClose = professionClose,
        _progressOverlay = progressOverlay,
        _progressText = progressText,
        _equipmentButtons = equipmentButtons,
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
end

function HUDController.setEquipHandler(self: HUDController, callback: (string) -> ())
    self._onEquip = callback
end

function HUDController.progressButton(self: HUDController): TextButton
    return self._progressButton
end

function HUDController.useCharmButton(self: HUDController): TextButton
    return self._useCharm
end

function HUDController.useSatchelButton(self: HUDController): TextButton
    return self._useSatchel
end

function HUDController.setCompactHandler(self: HUDController, callback: (boolean) -> ())
    self._onCompact = callback
end

function HUDController.setLobbyDepartHandler(self: HUDController, callback: (number, string) -> ())
    self._onLobbyDepart = callback
    for size, button in self._lobbySizeButtons do
        button.Activated:Connect(function()
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
    if lobby.counting then
        self._lobbyTitle.Text = string.format("DEPARTING IN %d", lobby.secondsRemaining)
        self._lobbyDetail.Text =
            string.format("%d ON THE PLATFORM * PARTY OF %d", lobby.readyCount, lobby.partySize)
        self._lobbySizes.Visible = false
    else
        self._lobbyTitle.Text = "DEPARTURE"
        self._lobbyDetail.Text = if lobby.readyCount > 0
            then string.format("%d ON THE PLATFORM * CHOOSE PARTY SIZE", lobby.readyCount)
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
    local charmCount = if gear ~= nil then tonumber(gear.gear_amber_charm) or 0 else 0
    local satchelCount = if gear ~= nil then tonumber(gear.gear_meadow_satchel) or 0 else 0

    self._useCharm.Visible = tutorialComplete and not self._playerDowned and charmCount > 0
    self._useCharm.Text = string.format("CHARM ×%d", charmCount)
    self._useSatchel.Visible = tutorialComplete and not self._playerDowned and satchelCount > 0
    self._useSatchel.Text = string.format("SATCHEL ×%d", satchelCount)
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
    for itemId, button in self._equipmentButtons do
        local count = tonumber(gear[itemId]) or 0
        button.Visible = self._progressOverlay.Visible and count > 0
        button.Text = if itemId == "gear_ironroot_hood"
            then string.format("EQUIP HOOD ×%d", count)
            else string.format("EQUIP BOOTS ×%d", count)
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
    local camera = workspace.CurrentCamera
    local viewport = if camera == nil then Vector2.new(1280, 720) else camera.ViewportSize
    --[[
        Treat any touch device, and any short viewport, as the touch layout.

        Deciding on width alone put a landscape phone -- wide but only ~430
        points tall -- on the desktop layout, which tucks the objective panel
        into the top-left corner that Roblox's own menu, chat, and microphone
        buttons already occupy.
    ]]
    local narrow = viewport.X < 700 or viewport.Y < 560 or UserInputService.TouchEnabled
    local scale = math.clamp(math.min(viewport.X, viewport.Y) / 720, 0.78, 1)
    self._scale.Scale = scale
    self._canvas.Size = UDim2.fromScale(1 / scale, 1 / scale)

    if narrow then
        self._objectiveFrame.Position = UDim2.fromOffset(18, 70)
        self._objectiveFrame.Size = UDim2.fromOffset(470, if self._compactEnabled then 78 else 112)
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
        self._blackoutFrame.Size = UDim2.fromOffset(470, 70)
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
        self._threatFrame.Position = UDim2.new(
            0.5,
            0,
            0,
            if self._allyFrame.Visible
                then (if self._blackoutFrame.Visible and self._eliteFrame.Visible then 356 else 284)
                elseif self._blackoutFrame.Visible and self._eliteFrame.Visible then 292
                elseif self._blackoutFrame.Visible then 222
                elseif self._eliteFrame.Visible then 220
                else 192
        )
        self._threatFrame.Size = UDim2.new(1, -36, 0, 60)
        self._downedFrame.Size = UDim2.new(1, -36, 0, 90)
        local professionY = if self._compactEnabled then 158 else 218
        self._professionButton.Position = UDim2.new(1, -18, 0, professionY)
        self._useCharm.Position = UDim2.new(1, -18, 0, professionY + 46)
        self._useSatchel.Position = UDim2.new(1, -18, 0, professionY + 92)
        self._professionPanel.Size = UDim2.new(1, -24, 0, 440)
        --[[
            Thumb cluster, bottom-right, stacked in two rows.

            Laid out in one row these ran far enough across the screen to sit
            over the character and the ground the player is aiming at. The
            primary action keeps the corner; strike, dodge, and ability sit
            inboard and one row up, which keeps every control inside a right
            thumb's reach without any of them covering the play area. Run stays
            on the left, clear of Roblox's own thumbstick.
        ]]
        --[[
            One bottom row, inset from BOTH corners.

            Roblox owns the bottom corners on touch: the thumbstick sits
            bottom-left and the jump button bottom-right. Putting the primary
            action in the bottom-right corner stacked it directly on top of
            jump. The row starts well inboard of jump and ends well inboard of
            the thumbstick, so every control is thumb-reachable without
            fighting a Roblox one, and none of them sit over the character.
        ]]
        -- Run sits immediately left of Roblox's jump button, where a right
        -- thumb already is. Ability keeps the next slot along. Dodge is gone
        -- on touch: it is still LeftAlt on a keyboard, but as a button it was
        -- one more thing to find mid-telegraph on a small screen.
        -- Clear of Roblox's jump button, which owns roughly the rightmost 200
        -- points. The canvas is scaled by 0.78, so these offsets shrink by
        -- that much on screen -- -170 looked clear here and landed on top of
        -- jump on the device.
        -- Run sits hard against Roblox's jump button on the right, where the
        -- owner asked for it: the thumb that jumps is the thumb that sprints.
        -- Everything else steps further inboard from there.
        self._sprint.Position = UDim2.new(1, -212, 1, -150)
        self._ability.Position = UDim2.new(1, -300, 1, -34)
        self._primary.Position = UDim2.new(1, -410, 1, -34)
        self._tool.Position = UDim2.new(1, -520, 1, -34)
        self._dodge.Position = UDim2.new(1, -630, 1, -34)
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
        self._threatFrame.Position = UDim2.fromScale(0.5, 0.32)
        self._threatFrame.Size = UDim2.fromOffset(330, 66)
        self._downedFrame.Size = UDim2.fromOffset(540, 90)
        self._professionButton.Position = UDim2.new(1, -18, 0, 64)
        self._useCharm.Position = UDim2.new(1, -18, 0, 110)
        self._useSatchel.Position = UDim2.new(1, -18, 0, 156)
        self._professionPanel.Size = UDim2.fromOffset(640, 440)
        self._ability.Position = UDim2.new(1, -346, 1, -40)
    end
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
