--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
        _toast: TextLabel,
        _lanternFrame: Frame,
        _lanternFill: Frame,
        _lanternText: TextLabel,
        _primary: TextButton,
        _tool: TextButton,
        _sprint: TextButton,
        _compact: TextButton,
        _currentState: any,
        _interactionLabel: string?,
        _interactionAvailable: boolean,
        _inputMode: string,
        _compactEnabled: boolean,
        _lastToastRevision: number,
        _onCompact: ((boolean) -> ())?,
    },
    HUDController
))

function HUDController.new(playerGui: PlayerGui): HUDController
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
        _toast = toast,
        _lanternFrame = lanternFrame,
        _lanternFill = lanternFill,
        _lanternText = lanternText,
        _primary = primary,
        _tool = tool,
        _sprint = sprint,
        _compact = compact,
        _currentState = nil,
        _interactionLabel = nil,
        _interactionAvailable = false,
        _inputMode = "keyboard",
        _compactEnabled = false,
        _lastToastRevision = 0,
        _onCompact = nil,
    }, HUDController)

    compact.Activated:Connect(function()
        self._compactEnabled = not self._compactEnabled
        self:_applyCompact()
        local callback = self._onCompact
        if callback ~= nil then
            callback(self._compactEnabled)
        end
    end)

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
        if clockAccumulator < 1 then
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

function HUDController.setCompactHandler(self: HUDController, callback: (boolean) -> ())
    self._onCompact = callback
end

function HUDController.setInputMode(self: HUDController, mode: string)
    self._inputMode = mode
    self._sprint.Visible = mode == "touch"
    self:setInteraction(self._interactionLabel, self._interactionAvailable)
    self._tool.Text = if mode == "keyboard"
        then "CLICK\nSTRIKE"
        elseif mode == "gamepad" then "RT\nSTRIKE"
        else "STRIKE"
end

function HUDController.setInteraction(self: HUDController, label: string?, available: boolean)
    self._interactionLabel = label
    self._interactionAvailable = available
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
    self._mara.Visible = not self._compactEnabled
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
    else
        self._objectiveFrame.Position = UDim2.fromOffset(18, 18)
        self._objectiveFrame.Size = if self._compactEnabled
            then UDim2.fromOffset(284, 76)
            else UDim2.fromOffset(326, 132)
        self._resource.Position = UDim2.fromOffset(18, 164)
        self._compact.Size = UDim2.fromOffset(118, 38)
        self._compact.Text = if self._compactEnabled then "EXPAND" else "COMPACT"
        self._lanternFrame.Position = UDim2.new(0.5, 0, 0, 66)
    end
end

function HUDController._updateClock(self: HUDController)
    local state = self._currentState
    if state == nil then
        return
    end

    local phase = string.upper(tostring(state.phase or "day"))
    local phaseEndsAt = tonumber(state.phaseEndsAt) or 0
    local clockText: string
    if phaseEndsAt > 0 then
        local remaining = math.max(0, math.ceil(phaseEndsAt - workspace:GetServerTimeNow()))
        clockText =
            string.format("%s · %02d:%02d", phase, math.floor(remaining / 60), remaining % 60)
    else
        clockText = if phase == "REVEAL" then "DAWN · FIRST LIGHT" else phase .. " · MORNING"
    end
    if self._phase.Text ~= clockText then
        self._phase.Text = clockText
    end
end

function HUDController.update(self: HUDController, state: any)
    if type(state) ~= "table" or state.status ~= "ready" then
        return
    end
    self._currentState = state
    self._objective.Text = tostring(state.objective or "")
    self._detail.Text = tostring(state.detail or "")
    self._progress.Text = string.format(
        "FIRST LIGHT · %d / %d",
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
    self._resource.Visible = not nightActive
        and ((tonumber(state.resources) or 0) > 0 or state.selectedTool ~= nil)
    self._tool.Visible = nightActive
    self._lanternFrame.Visible = nightActive
    local lanternHealth = math.clamp(tonumber(state.lanternHealth) or 100, 0, 100)
    self._lanternFill.Size = UDim2.new(lanternHealth / 100, -8, 1, -8)
    self._lanternFill.BackgroundColor3 = if lanternHealth <= 35 then COLORS.danger else COLORS.amber
    self._lanternText.Text = string.format("LIGHT · %d%%", lanternHealth)
    self._lanternText.TextColor3 = if lanternHealth <= 55 then COLORS.cream else COLORS.ink

    if state.compactHud ~= nil and state.compactHud ~= self._compactEnabled then
        self._compactEnabled = state.compactHud == true
        self:_applyCompact()
    end
    self:_layout()

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
