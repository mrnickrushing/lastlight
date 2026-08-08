--!strict
--[[
    Tapping the world, handled on the client so it works on a phone.

    Tapping objects is this game's interaction model, and it was implemented
    entirely with server-side ClickDetectors. That is reliable for a mouse and
    unreliable for a finger: on touch, Roblox only turns a press into a click
    when its own heuristics decide the gesture was a tap rather than the start
    of a camera drag, and the right-hand side of a phone screen -- where the
    creature you are trying to hit usually is -- is exactly the camera-drag
    region. The owner's report was precise about it: hitting monsters worked
    on a laptop and never on mobile or tablet.

    So the tap is resolved here instead. A press that ends near where it began
    is a tap; anything else was a camera drag and is ignored. The tap is
    raycast into the world, and what it lands on decides which request to
    send. That is all a tap ever does -- the server still decides range,
    damage, validity, and every outcome, exactly as before.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local TapController = {}
TapController.__index = TapController

export type TapController = typeof(setmetatable(
    {} :: {
        _onStrike: () -> (),
        _onInteract: (string) -> (),
        _origins: { [number]: Vector2 },
        _connections: { RBXScriptConnection },
    },
    TapController
))

-- A finger moves a little even on a deliberate tap; a camera drag moves a
-- lot. 14 points separates them without demanding a perfectly still thumb.
local TAP_SLOP_PIXELS = 14
local MAX_TAP_DISTANCE = 220

local function inputKey(input: InputObject): number
    return if input.UserInputType == Enum.UserInputType.Touch then input.KeyCode.Value + 1 else 0
end

--[[
    What did this tap mean?

    Walks up from whatever the ray hit, because the thing under a finger is
    usually a click volume or a mesh part rather than the model that owns the
    meaning. An enemy answers with a strike; anything carrying an interaction
    ID answers with that interaction.
]]
local function resolveTarget(instance: Instance): (string?, string?)
    local node: Instance? = instance
    while node ~= nil and node ~= workspace do
        if node:IsA("Model") and node:FindFirstChild("StrikeClick") ~= nil then
            return "strike", nil
        end
        local name = node.Name
        local interactionId = string.match(name, "^(.+)_ClickVolume$")
        if interactionId ~= nil then
            return "interact", interactionId
        end
        local attribute = node:GetAttribute("InteractionId")
        if type(attribute) == "string" then
            return "interact", attribute
        end
        node = node.Parent
    end
    return nil, nil
end

function TapController.new(onStrike: () -> (), onInteract: (string) -> ()): TapController
    local self = setmetatable({
        _onStrike = onStrike,
        _onInteract = onInteract,
        _origins = {},
        _connections = {},
    }, TapController)

    table.insert(
        self._connections,
        UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
            if processed then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1
            then
                self._origins[inputKey(input)] = Vector2.new(input.Position.X, input.Position.Y)
            end
        end)
    )

    table.insert(
        self._connections,
        UserInputService.InputEnded:Connect(function(input: InputObject, processed: boolean)
            if
                input.UserInputType ~= Enum.UserInputType.Touch
                and input.UserInputType ~= Enum.UserInputType.MouseButton1
            then
                return
            end
            local key = inputKey(input)
            local origin = self._origins[key]
            self._origins[key] = nil
            -- A press that started on a HUD button belongs to that button.
            if processed or origin == nil then
                return
            end
            local ended = Vector2.new(input.Position.X, input.Position.Y)
            if (ended - origin).Magnitude > TAP_SLOP_PIXELS then
                return
            end
            self:_resolve(ended, input.UserInputType == Enum.UserInputType.MouseButton1)
        end)
    )
    return self
end

--[[
    Will the engine's own ClickDetector answer this mouse click?

    On a mouse, every click volume and every creature already carries a
    detector wired to the same server handler this controller would call,
    and the engine fires it for any click inside its activation distance.
    Sending our own request on top of that is how one physical click became
    two interactions: the first consumed the step and the second bounced
    off the freshly disabled prompt, overwriting every success toast with
    MOVE CLOSER TO THE MARKED OBJECT. So a mouse tap defers to a detector
    that is going to fire, and only speaks up when the engine will stay
    silent -- a target beyond detector range, where the server's own
    rejection is the feedback a player should get.
]]
local function engineWillHandle(hit: RaycastResult, character: Model): boolean
    local root = character:FindFirstChild("HumanoidRootPart")
    if root == nil or not root:IsA("BasePart") then
        return false
    end
    local node: Instance? = hit.Instance
    while node ~= nil and node ~= workspace do
        for _, child in node:GetChildren() do
            if child:IsA("ClickDetector") then
                return (root.Position - hit.Position).Magnitude <= child.MaxActivationDistance + 2
            end
        end
        node = node.Parent
    end
    return false
end

function TapController._resolve(self: TapController, position: Vector2, isMouse: boolean)
    local camera = workspace.CurrentCamera
    local player = Players.LocalPlayer
    local character = player.Character
    if camera == nil or character == nil then
        return
    end
    local ray = camera:ViewportPointToRay(position.X, position.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    local hit = workspace:Raycast(ray.Origin, ray.Direction * MAX_TAP_DISTANCE, params)
    if hit == nil then
        -- A mouse tap at open sky still means "swing": the blind M1 swing
        -- used to live in InputController, and combat expects a click near
        -- a creature to try, with the server deciding what is in reach.
        if isMouse then
            self._onStrike()
        end
        return
    end
    local kind, interactionId = resolveTarget(hit.Instance)
    if isMouse and engineWillHandle(hit, character) then
        return
    end
    if kind == "interact" and interactionId ~= nil then
        self._onInteract(interactionId)
    elseif kind == "strike" or isMouse then
        -- A mouse tap on plain scenery still swings; only touch demands a
        -- real target, since a stray thumb is not a combat intent.
        self._onStrike()
    end
end

function TapController.destroy(self: TapController)
    for _, connection in self._connections do
        connection:Disconnect()
    end
    self._connections = {}
    self._origins = {}
end

return table.freeze(TapController)
