--!strict
--[[
    Short, local, skippable arrival vignettes.

    When a threat arrives -- the night, the Blackout, an awakening elite or
    boss -- the camera spends a moment on it: a slow push toward the threat
    under letterbox bars with a title card, then control returns. The moment
    is presentation only, and every rule here exists to keep it that way:

    - Camera-only and local. The server never waits, other players never
      pause, and the character keeps its position and physics. Movement input
      still works during the shot; pressing anything also skips it.
    - Short and bounded. No vignette runs past a few seconds, and the arrival
      beats that trigger them all carry more quiet time than that before any
      attack pressure begins.
    - Never while downed, never in compact HUD mode (the documented
      low-effects/accessibility preset), and never twice for one arrival.
    - Restores exactly: the camera returns to the player follow-cam it took
      over from, whatever happened mid-shot.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local VignetteController = {}
VignetteController.__index = VignetteController

export type Shot = {
    title: string,
    subtitle: string,
    focus: Vector3,
    duration: number,
}

export type VignetteController = typeof(setmetatable(
    {} :: {
        _gui: ScreenGui,
        _topBar: Frame,
        _bottomBar: Frame,
        _title: TextLabel,
        _subtitle: TextLabel,
        _playing: boolean,
        _compact: boolean,
        _skipConnection: RBXScriptConnection?,
    },
    VignetteController
))

local BAR_HEIGHT = 0.14
local EASE = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function VignetteController.new(playerGui: PlayerGui): VignetteController
    local gui = Instance.new("ScreenGui")
    gui.Name = "LastLightVignette"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 40
    gui.Enabled = false
    gui.Parent = playerGui

    local function bar(name: string, anchor: number): Frame
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.BackgroundColor3 = Color3.fromRGB(4, 5, 7)
        frame.BorderSizePixel = 0
        frame.AnchorPoint = Vector2.new(0.5, anchor)
        frame.Position = UDim2.fromScale(0.5, anchor)
        frame.Size = UDim2.fromScale(1, 0)
        frame.Parent = gui
        return frame
    end
    local topBar = bar("TopBar", 0)
    local bottomBar = bar("BottomBar", 1)

    local title = Instance.new("TextLabel")
    title.Name = "VignetteTitle"
    title.BackgroundTransparency = 1
    title.AnchorPoint = Vector2.new(0.5, 1)
    title.Position = UDim2.new(0.5, 0, 1, -8)
    title.Size = UDim2.new(0.9, 0, 0, 40)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 30
    title.TextColor3 = Color3.fromRGB(244, 236, 214)
    title.TextTransparency = 1
    title.Text = ""
    title.Parent = bottomBar

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "VignetteSubtitle"
    subtitle.BackgroundTransparency = 1
    subtitle.AnchorPoint = Vector2.new(0.5, 0)
    subtitle.Position = UDim2.new(0.5, 0, 1, 6)
    subtitle.Size = UDim2.new(0.9, 0, 0, 22)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 15
    subtitle.TextColor3 = Color3.fromRGB(214, 182, 118)
    subtitle.TextTransparency = 1
    subtitle.Text = ""
    subtitle.Parent = bottomBar

    return setmetatable({
        _gui = gui,
        _topBar = topBar,
        _bottomBar = bottomBar,
        _title = title,
        _subtitle = subtitle,
        _playing = false,
        _compact = false,
        _skipConnection = nil,
    }, VignetteController)
end

function VignetteController.setCompact(self: VignetteController, compact: boolean)
    self._compact = compact
end

function VignetteController._restore(self: VignetteController, camera: Camera)
    if self._skipConnection ~= nil then
        self._skipConnection:Disconnect()
        self._skipConnection = nil
    end
    local player = Players.LocalPlayer
    local character = player.Character
    local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
    camera.CameraType = Enum.CameraType.Custom
    if humanoid ~= nil then
        camera.CameraSubject = humanoid
    end
    self._gui.Enabled = false
    self._playing = false
end

function VignetteController.play(self: VignetteController, shot: Shot)
    if self._playing or self._compact then
        return
    end
    local player = Players.LocalPlayer
    if player:GetAttribute("LastLightDowned") == true then
        return
    end
    local character = player.Character
    local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
    local camera = workspace.CurrentCamera
    if root == nil or not root:IsA("BasePart") or camera == nil then
        return
    end
    self._playing = true

    -- Frame the threat from the player's side of it, high enough to clear
    -- ground clutter, and push in slowly. All offsets are derived, so the
    -- same shot works in the town square and the expedition.
    local focus = shot.focus
    local toPlayer = root.Position - focus
    local flat = Vector3.new(toPlayer.X, 0, toPlayer.Z)
    local direction = if flat.Magnitude > 1 then flat.Unit else Vector3.new(0, 0, 1)
    local startFrame =
        CFrame.lookAt(focus + direction * 34 + Vector3.new(0, 14, 0), focus + Vector3.new(0, 3, 0))
    local endFrame =
        CFrame.lookAt(focus + direction * 22 + Vector3.new(0, 9, 0), focus + Vector3.new(0, 3, 0))

    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = startFrame

    self._gui.Enabled = true
    self._topBar.Size = UDim2.fromScale(1, 0)
    self._bottomBar.Size = UDim2.fromScale(1, 0)
    self._title.Text = shot.title
    self._subtitle.Text = shot.subtitle
    self._title.TextTransparency = 1
    self._subtitle.TextTransparency = 1

    TweenService:Create(self._topBar, EASE, { Size = UDim2.fromScale(1, BAR_HEIGHT) }):Play()
    TweenService:Create(self._bottomBar, EASE, { Size = UDim2.fromScale(1, BAR_HEIGHT) }):Play()
    TweenService:Create(self._title, EASE, { TextTransparency = 0 }):Play()
    TweenService:Create(self._subtitle, EASE, { TextTransparency = 0.15 }):Play()
    TweenService:Create(
        camera,
        TweenInfo.new(shot.duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { CFrame = endFrame }
    ):Play()

    local finished = false
    local function finish()
        if finished then
            return
        end
        finished = true
        self:_restore(camera)
    end
    -- Any input returns the camera immediately: the vignette must never cost
    -- a player who wants their hands back more than a keypress.
    self._skipConnection = UserInputService.InputBegan:Connect(function(_input, processed)
        if not processed then
            finish()
        end
    end)
    task.delay(shot.duration, finish)
end

return table.freeze(VignetteController)
