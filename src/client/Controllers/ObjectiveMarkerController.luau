--!strict
--[[
    Show the player where the current objective is.

    The objective card has always named the task and never the place. "Choose
    a starter tool" says nothing about where the tools are; "gather heartwood"
    says nothing about where the stump is. A new player reads it, looks up at
    a dark valley, and wanders.

    Two things fix that, and this controller owns both:

      - A marker standing over the objective itself, visible through terrain,
        with the distance on it. That is the "something above the objective"
        half.
      - A pointer at the screen edge when the objective is behind or beside
        the player, so there is always a direction to walk. That is the half
        that works when the marker is off-screen entirely, which for an
        objective in a forest is most of the time.

    Both are presentation, driven entirely by the server snapshot: the client
    is told where the objective is, never what counts as done.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ObjectiveMarkerController = {}
ObjectiveMarkerController.__index = ObjectiveMarkerController

export type ObjectiveMarkerController = typeof(setmetatable(
    {} :: {
        _folder: Folder,
        _gui: ScreenGui,
        _pointer: Frame,
        _pointerLabel: TextLabel,
        _markers: { [string]: BillboardGui },
        _anchors: { [string]: Part },
        _targets: { any },
        _connection: RBXScriptConnection?,
    },
    ObjectiveMarkerController
))

local AMBER = Color3.fromRGB(255, 186, 92)
local INK = Color3.fromRGB(18, 14, 11)

function ObjectiveMarkerController.new(playerGui: PlayerGui): ObjectiveMarkerController
    local folder = Instance.new("Folder")
    folder.Name = "LastLightObjectiveMarkers"
    folder.Parent = workspace

    local gui = Instance.new("ScreenGui")
    gui.Name = "LastLightObjectivePointer"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 12
    gui.Parent = playerGui

    local pointer = Instance.new("Frame")
    pointer.Name = "EdgePointer"
    pointer.AnchorPoint = Vector2.new(0.5, 0.5)
    pointer.Size = UDim2.fromOffset(168, 40)
    pointer.BackgroundColor3 = INK
    pointer.BackgroundTransparency = 0.12
    pointer.BorderSizePixel = 0
    pointer.Visible = false
    pointer.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = pointer
    local stroke = Instance.new("UIStroke")
    stroke.Color = AMBER
    stroke.Transparency = 0.35
    stroke.Thickness = 1.5
    stroke.Parent = pointer

    local label = Instance.new("TextLabel")
    label.Name = "PointerLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 15
    label.TextColor3 = AMBER
    label.Text = ""
    label.Parent = pointer

    local self = setmetatable({
        _folder = folder,
        _gui = gui,
        _pointer = pointer,
        _pointerLabel = label,
        _markers = {},
        _anchors = {},
        _targets = {},
        _connection = nil,
    }, ObjectiveMarkerController)

    self._connection = RunService.RenderStepped:Connect(function()
        self:_step()
    end)
    return self
end

function ObjectiveMarkerController._clear(self: ObjectiveMarkerController)
    for _, anchor in self._anchors do
        anchor:Destroy()
    end
    self._anchors = {}
    self._markers = {}
end

--[[
    Take the server's list of objective positions.

    Rebuilt only when the set of interaction IDs actually changes, so the
    markers do not flicker on every snapshot -- the snapshot arrives on any
    state change, several times a second during a night.
]]
function ObjectiveMarkerController.setTargets(self: ObjectiveMarkerController, targets: { any }?)
    local incoming = if type(targets) == "table" then targets else {}
    local changed = #incoming ~= #self._targets
    if not changed then
        for index, target in incoming do
            if
                self._targets[index] == nil
                or self._targets[index].interactionId ~= target.interactionId
            then
                changed = true
                break
            end
        end
    end
    self._targets = incoming
    if not changed then
        -- Positions can still move (Mara walks), so keep anchors in sync.
        for _, target in incoming do
            local anchor = self._anchors[target.interactionId]
            if anchor ~= nil then
                anchor.Position = Vector3.new(target.x, target.y, target.z)
            end
        end
        return
    end

    self:_clear()
    for _, target in incoming do
        local anchor = Instance.new("Part")
        anchor.Name = "ObjectiveAnchor_" .. tostring(target.interactionId)
        anchor.Size = Vector3.new(0.2, 0.2, 0.2)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanQuery = false
        anchor.CanTouch = false
        anchor.CastShadow = false
        anchor.Position = Vector3.new(target.x, target.y, target.z)
        anchor.Parent = self._folder

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ObjectiveMarker"
        billboard.Adornee = anchor
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.Size = UDim2.fromOffset(184, 46)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
        billboard.MaxDistance = 600
        billboard.Parent = anchor

        local card = Instance.new("Frame")
        card.BackgroundColor3 = INK
        card.BackgroundTransparency = 0.14
        card.BorderSizePixel = 0
        card.Size = UDim2.fromScale(1, 1)
        card.Parent = billboard
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = AMBER
        cardStroke.Transparency = 0.3
        cardStroke.Thickness = 1.5
        cardStroke.Parent = card

        local text = Instance.new("TextLabel")
        text.Name = "MarkerText"
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 15
        text.TextColor3 = AMBER
        text.Text = "▼ " .. tostring(target.label or "OBJECTIVE")
        text.Parent = card

        self._anchors[target.interactionId] = anchor
        self._markers[target.interactionId] = billboard
    end
end

function ObjectiveMarkerController._step(self: ObjectiveMarkerController)
    local camera = workspace.CurrentCamera
    local character = Players.LocalPlayer.Character
    local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
    if camera == nil or root == nil or not root:IsA("BasePart") or #self._targets == 0 then
        self._pointer.Visible = false
        return
    end

    -- Point at the nearest objective: with three tool pedestals the useful
    -- direction is the closest one, not an average of them.
    local nearest, nearestDistance = nil, math.huge
    for _, target in self._targets do
        local position = Vector3.new(target.x, target.y, target.z)
        local distance = (position - root.Position).Magnitude
        if distance < nearestDistance then
            nearest = position
            nearestDistance = distance
        end
        local billboard = self._markers[target.interactionId]
        if billboard ~= nil then
            local label = billboard:FindFirstChild("MarkerText", true)
            if label ~= nil and label:IsA("TextLabel") then
                label.Text = string.format(
                    "▼ %s · %dm",
                    tostring(target.label or "OBJECTIVE"),
                    math.floor(distance + 0.5)
                )
            end
        end
    end
    if nearest == nil then
        self._pointer.Visible = false
        return
    end

    local screenPoint, onScreen = camera:WorldToViewportPoint(nearest)
    local viewport = camera.ViewportSize
    if onScreen and screenPoint.Z > 0 then
        -- The world marker is doing the job; an edge pointer as well would be
        -- two things saying the same thing.
        self._pointer.Visible = false
        return
    end

    -- Behind or off to the side: pin a pointer to the screen edge in the
    -- objective's direction, so there is always a way to face.
    local centre = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local direction = Vector2.new(screenPoint.X, screenPoint.Y) - centre
    if screenPoint.Z <= 0 then
        direction = -direction
    end
    if direction.Magnitude < 0.001 then
        direction = Vector2.new(0, -1)
    end
    direction = direction.Unit
    local margin = 74
    local halfX = math.max(1, viewport.X * 0.5 - margin)
    local halfY = math.max(1, viewport.Y * 0.5 - margin)
    local scale = math.min(
        halfX / math.abs(direction.X == 0 and 0.0001 or direction.X),
        halfY / math.abs(direction.Y == 0 and 0.0001 or direction.Y)
    )
    local edge = centre + direction * scale
    self._pointer.Position = UDim2.fromOffset(edge.X, edge.Y)
    self._pointerLabel.Text = string.format("◄ %dm", math.floor(nearestDistance + 0.5))
    self._pointer.Visible = true
end

return table.freeze(ObjectiveMarkerController)
