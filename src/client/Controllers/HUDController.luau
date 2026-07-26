--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local HUDController = {}
HUDController.__index = HUDController

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
        _scale: UIScale,
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
        _useCharm: TextButton,
        _useSatchel: TextButton,
        _professionOverlay: Frame,
        _professionPanel: Frame,
        _professionCards: { [string]: TextButton },
        _professionOrder: { string },
        _professionClose: TextButton,
        _currentState: any,
        _interactionLabel: string?,
        _interactionAvailable: boolean,
        _inputMode: string,
        _compactEnabled: boolean,
        _playerDowned: boolean,
        _combatContext: boolean,
        _professionMenuOpen: boolean,
        _professionSwitchable: boolean,
        _lastToastRevision: number,
        _onCompact: ((boolean) -> ())?,
        _onProfessionSelected: ((string) -> ())?,
    },
    HUDController
))

function HUDController.new(playerGui: PlayerGui, professions: { any }): HUDController
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
        UDim2.new(1, -28, 0, 34),
        UDim2.fromOffset(14, 32),
        20,
        COLORS.cream
    )
    objective.Font = Enum.Font.GothamBold
    local detail = textLabel(
        objectiveFrame,
        "Detail",
        "Follow the lantern path.",
        UDim2.new(1, -28, 0, 48),
        UDim2.fromOffset(14, 70),
        14,
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
    local sprint = actionButton(
        canvas,
        "Sprint",
        "HOLD\nRUN",
        80,
        UDim2.new(0, 166, 1, -34),
        Vector2.new(0, 1)
    )
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
    professionButton.Text = "CHOOSE KIT"
    professionButton.TextColor3 = COLORS.amber
    professionButton.TextSize = 12
    professionButton.Visible = false
    professionButton.ZIndex = 10
    professionButton.Parent = canvas
    corner(professionButton, 12)
    stroke(professionButton, COLORS.amber, 0.42)

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

    local professionGrid = Instance.new("Frame")
    professionGrid.Name = "ProfessionGrid"
    professionGrid.BackgroundTransparency = 1
    professionGrid.Position = UDim2.fromOffset(20, 106)
    professionGrid.Size = UDim2.new(1, -40, 1, -130)
    professionGrid.ZIndex = 42
    professionGrid.Parent = professionPanel
    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.fromOffset(12, 12)
    grid.CellSize = UDim2.new(0.5, -6, 0.5, -6)
    grid.FillDirectionMaxCells = 2
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
        card.TextSize = 14
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

    local self = setmetatable({
        _gui = gui,
        _scale = scale,
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
        _useCharm = useCharm,
        _useSatchel = useSatchel,
        _professionOverlay = professionOverlay,
        _professionPanel = professionPanel,
        _professionCards = professionCards,
        _professionOrder = professionOrder,
        _professionClose = professionClose,
        _currentState = nil,
        _interactionLabel = nil,
        _interactionAvailable = false,
        _inputMode = "keyboard",
        _compactEnabled = false,
        _playerDowned = false,
        _combatContext = false,
        _professionMenuOpen = false,
        _professionSwitchable = false,
        _lastToastRevision = 0,
        _onCompact = nil,
        _onProfessionSelected = nil,
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

function HUDController.useCharmButton(self: HUDController): TextButton
    return self._useCharm
end

function HUDController.useSatchelButton(self: HUDController): TextButton
    return self._useSatchel
end

function HUDController.setCompactHandler(self: HUDController, callback: (boolean) -> ())
    self._onCompact = callback
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
    self._dodge.Visible = not self._playerDowned and (mode == "touch" or self._combatContext)
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
        self._dodge.Visible = false
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
    self._professionButton.Text = if displayName == nil
        then "CHOOSE KIT"
        else "KIT · " .. displayName

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

function HUDController._applyCompact(self: HUDController)
    self._detail.Visible = not self._compactEnabled
    self._mara.Visible = not self._compactEnabled and not self._playerDowned
    self._objective.Position = if self._compactEnabled
        then UDim2.fromOffset(14, 31)
        else UDim2.fromOffset(14, 32)
    self._compact.TextColor3 = if self._compactEnabled then COLORS.amber else COLORS.muted
    self:_layout()
end

function HUDController._layout(self: HUDController)
    local camera = workspace.CurrentCamera
    local viewport = if camera == nil then Vector2.new(1280, 720) else camera.ViewportSize
    local narrow = viewport.X < 700
    self._scale.Scale = math.clamp(math.min(viewport.X, viewport.Y) / 720, 0.78, 1)

    if narrow then
        self._objectiveFrame.Position = UDim2.fromOffset(18, 70)
        self._objectiveFrame.Size = UDim2.new(1, -36, 0, if self._compactEnabled then 76 else 132)
        self._resource.Position = UDim2.fromOffset(18, if self._compactEnabled then 158 else 218)
        self._compact.Size = UDim2.fromOffset(44, 38)
        self._compact.Text = if self._compactEnabled then "+" else "−"
        self._lanternFrame.Position = UDim2.new(0.5, 0, 0, 212)
        self._blackoutFrame.Position = UDim2.new(0.5, 0, 0, 212)
        self._blackoutFrame.Size = UDim2.new(1, -36, 0, 64)
        self._eliteFrame.Position =
            UDim2.new(0.5, 0, 0, if self._blackoutFrame.Visible then 284 else 212)
        self._eliteFrame.Size = UDim2.new(1, -36, 0, 70)
        self._allyFrame.Position = UDim2.new(
            0.5,
            0,
            0,
            if self._eliteFrame.Visible
                then (if self._blackoutFrame.Visible then 362 else 290)
                elseif self._blackoutFrame.Visible then 284
                elseif self._lanternFrame.Visible then 254
                else 212
        )
        self._allyFrame.Size = UDim2.new(1, -36, 0, 64)
        self._threatFrame.Position = UDim2.new(
            0.5,
            0,
            0,
            if self._allyFrame.Visible
                then (if self._blackoutFrame.Visible and self._eliteFrame.Visible then 434 else 362)
                elseif self._blackoutFrame.Visible and self._eliteFrame.Visible then 362
                elseif self._blackoutFrame.Visible then 284
                elseif self._eliteFrame.Visible then 290
                else 254
        )
        self._threatFrame.Size = UDim2.new(1, -36, 0, 66)
        self._downedFrame.Size = UDim2.new(1, -36, 0, 90)
        local professionY = if self._compactEnabled then 158 else 218
        self._professionButton.Position = UDim2.new(1, -18, 0, professionY)
        self._useCharm.Position = UDim2.new(1, -18, 0, professionY + 46)
        self._useSatchel.Position = UDim2.new(1, -18, 0, professionY + 92)
        self._professionPanel.Size = UDim2.new(1, -24, 0, 440)
        self._ability.Position = UDim2.new(1, -158, 1, -138)
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

function HUDController._updateClock(self: HUDController)
    local state = self._currentState
    if state == nil then
        return
    end

    local phase = string.upper(tostring(state.phase or "day"))
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
        clockText =
            string.format("%s · %02d:%02d", phase, math.floor(remaining / 60), remaining % 60)
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
                    "CARRYING ROOTFIRE %.1fs · LIVING ROOTS %d/%d",
                    fireRemaining,
                    tonumber(blackout.deliveredNodes) or 0,
                    tonumber(blackout.relayRequired) or 3
                )
            else
                self._blackoutDetail.Text = string.format(
                    "TAKE ROOTFIRE · LIVING ROOTS %d/%d",
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
                string.gsub(tostring(blackout.decision or "chapter resolved"), "_", " ")
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
    self._objective.Text = tostring(state.objective or "")
    self._detail.Text = tostring(state.detail or "")
    self._progress.Text = string.format(
        "%s · %d / %d",
        tostring(state.trailName or "FIRST LIGHT"),
        tonumber(state.progress) or 0,
        tonumber(state.progressTotal) or 8
    )
    self._mara.Text = "Mara: " .. tostring(state.mara or "")
    self._resource.Text = string.format(
        "HEARTWOOD · %d%s",
        tonumber(state.resources) or 0,
        if state.selectedTool ~= nil
            then "  ·  " .. string.upper(tostring(state.selectedTool))
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
    self._tool.Visible = (nightActive or eliteActive or bossActive or blackoutActive)
        and not self._playerDowned
    self._sprint.Visible = self._inputMode == "touch" and not self._playerDowned
    self._dodge.Visible = not self._playerDowned
        and (self._inputMode == "touch" or self._combatContext)
    self:_updateProfessionClock()
    self:_updateGear()
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
    self._mara.Visible = not self._compactEnabled and not self._playerDowned
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
