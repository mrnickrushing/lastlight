--!strict

local UserInputService = game:GetService("UserInputService")

local InputController = {}
InputController.__index = InputController

export type InputController = typeof(setmetatable(
    {} :: {
        _hud: any,
        _context: Instance?,
        _connections: { RBXScriptConnection },
    },
    InputController
))

local function addKeyBinding(action: Instance, name: string, keyCode: Enum.KeyCode)
    local binding = Instance.new("InputBinding")
    binding.Name = name
    binding.KeyCode = keyCode
    binding.DisplayName = keyCode.Name
    binding.Parent = action
end

local function addTouchBinding(action: Instance, name: string, button: GuiButton)
    local binding = Instance.new("InputBinding")
    binding.Name = name
    binding.UIButton = button
    binding.DisplayName = name
    binding.Parent = action
end

local function createBoolAction(
    context: Instance,
    name: string,
    keys: { { name: string, key: Enum.KeyCode } },
    button: GuiButton
): Instance
    local action = Instance.new("InputAction")
    action.Name = name
    action.Type = Enum.InputActionType.Bool
    action.Parent = context
    for _, binding in keys do
        addKeyBinding(action, binding.name, binding.key)
    end
    addTouchBinding(action, "Touch", button)
    return action
end

function InputController.new(
    hud: any,
    onInteract: () -> (),
    onUseTool: () -> (),
    onSprint: (boolean) -> ()
): InputController
    local self = setmetatable({
        _hud = hud,
        _context = nil,
        _connections = {},
    }, InputController)

    local ok = pcall(function()
        local context = Instance.new("InputContext")
        context.Name = "LastLightPlayContext"
        context.Priority = 2000
        context.Sink = false
        context.Enabled = true
        context.Parent = hud:gui()
        self._context = context

        local interact = createBoolAction(context, "Interact", {
            { name = "Keyboard", key = Enum.KeyCode.E },
            { name = "Gamepad", key = Enum.KeyCode.ButtonX },
        }, hud:primaryButton())
        local tool = createBoolAction(context, "UseTool", {
            { name = "Mouse", key = Enum.KeyCode.MouseLeftButton },
            { name = "Gamepad", key = Enum.KeyCode.ButtonR2 },
        }, hud:toolButton())
        local sprint = createBoolAction(context, "Sprint", {
            { name = "Keyboard", key = Enum.KeyCode.LeftShift },
            { name = "Gamepad", key = Enum.KeyCode.ButtonL3 },
        }, hud:sprintButton())

        table.insert(self._connections, (interact :: any).Pressed:Connect(onInteract))
        table.insert(self._connections, (tool :: any).Pressed:Connect(onUseTool))
        table.insert(
            self._connections,
            (sprint :: any).Pressed:Connect(function()
                onSprint(true)
            end)
        )
        table.insert(
            self._connections,
            (sprint :: any).Released:Connect(function()
                onSprint(false)
            end)
        )
    end)

    if not ok then
        for _, connection in self._connections do
            connection:Disconnect()
        end
        table.clear(self._connections)
        if self._context ~= nil then
            self._context:Destroy()
            self._context = nil
        end
        self:_installFallback(onInteract, onUseTool, onSprint)
    end

    local function updateInputMode()
        local preferred = UserInputService.PreferredInput
        local mode = if preferred == Enum.PreferredInput.Touch
            then "touch"
            elseif preferred == Enum.PreferredInput.Gamepad then "gamepad"
            else "keyboard"
        hud:setInputMode(mode)
    end
    updateInputMode()
    table.insert(
        self._connections,
        UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updateInputMode)
    )

    return self
end

function InputController._installFallback(
    self: InputController,
    onInteract: () -> (),
    onUseTool: () -> (),
    onSprint: (boolean) -> ()
)
    table.insert(self._connections, self._hud:primaryButton().Activated:Connect(onInteract))
    table.insert(self._connections, self._hud:toolButton().Activated:Connect(onUseTool))
    table.insert(
        self._connections,
        self._hud:sprintButton().MouseButton1Down:Connect(function()
            onSprint(true)
        end)
    )
    table.insert(
        self._connections,
        self._hud:sprintButton().MouseButton1Up:Connect(function()
            onSprint(false)
        end)
    )
    table.insert(
        self._connections,
        UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
            if processed then
                return
            end
            if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
                onInteract()
            elseif
                input.KeyCode == Enum.KeyCode.LeftShift
                or input.KeyCode == Enum.KeyCode.ButtonL3
            then
                onSprint(true)
            elseif
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.KeyCode == Enum.KeyCode.ButtonR2
            then
                onUseTool()
            end
        end)
    )
    table.insert(
        self._connections,
        UserInputService.InputEnded:Connect(function(input: InputObject)
            if
                input.KeyCode == Enum.KeyCode.LeftShift
                or input.KeyCode == Enum.KeyCode.ButtonL3
            then
                onSprint(false)
            end
        end)
    )
end

return InputController
