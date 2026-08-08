--!strict

local UserInputService = game:GetService("UserInputService")

local InputController = {}
InputController.__index = InputController

export type InputController = typeof(setmetatable(
    {} :: {
        _hud: any,
        _context: Instance?,
        _connections: { RBXScriptConnection },
        _running: boolean,
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
    onSprint: (boolean) -> (),
    onDodge: () -> (),
    onProfessionAbility: () -> (),
    onProfessionMenu: () -> (),
    onUseConsumable: (itemId: string) -> ()
): InputController
    local self = setmetatable({
        _hud = hud,
        _context = nil,
        _connections = {},
        _running = false,
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
        --[[
            No mouse binding here on purpose. TapController owns what a
            mouse click means: a click that lands on a creature or an
            interactable is delivered once by the engine's ClickDetector,
            and a click on nothing resolves to a swing there. Binding
            MouseLeftButton here as well made every click on an object
            also swing the tool, so each success toast was immediately
            stomped by "The tool is calm in daylight."
        ]]
        local tool = createBoolAction(context, "UseTool", {
            { name = "Gamepad", key = Enum.KeyCode.ButtonR2 },
        }, hud:toolButton())
        local sprint = createBoolAction(context, "Sprint", {
            { name = "Keyboard", key = Enum.KeyCode.LeftShift },
            { name = "Gamepad", key = Enum.KeyCode.ButtonL3 },
        }, hud:sprintButton())
        local dodge = createBoolAction(context, "Dodge", {
            { name = "Keyboard", key = Enum.KeyCode.LeftAlt },
            { name = "Gamepad", key = Enum.KeyCode.ButtonB },
        }, hud:dodgeButton())
        local professionAbility = createBoolAction(context, "ProfessionAbility", {
            { name = "Keyboard", key = Enum.KeyCode.Q },
            { name = "Gamepad", key = Enum.KeyCode.ButtonL1 },
        }, hud:abilityButton())
        local professionMenu = createBoolAction(context, "ProfessionMenu", {
            { name = "Keyboard", key = Enum.KeyCode.P },
            { name = "Gamepad", key = Enum.KeyCode.DPadUp },
        }, hud:professionButton())
        --[[
            C and V keep the first and second consumable the player is
            carrying rather than two named items. The HUD decides which
            those are and stamps each button with its id, so a key press
            asks the button rather than a constant -- which is the whole
            reason a third consumable no longer needs a code change.
        ]]
        local useButtons = hud:useButtons()
        local useFirst = createBoolAction(context, "UseConsumableOne", {
            { name = "Keyboard", key = Enum.KeyCode.C },
            { name = "Gamepad", key = Enum.KeyCode.ButtonY },
        }, useButtons[1])
        local useSecond = createBoolAction(context, "UseConsumableTwo", {
            { name = "Keyboard", key = Enum.KeyCode.V },
            { name = "Gamepad", key = Enum.KeyCode.DPadDown },
        }, useButtons[2])

        table.insert(
            self._connections,
            (interact :: any).Pressed:Connect(function()
                if not hud:isProfessionMenuOpen() then
                    onInteract()
                end
            end)
        )
        table.insert(
            self._connections,
            (tool :: any).Pressed:Connect(function()
                if not hud:isProfessionMenuOpen() then
                    onUseTool()
                end
            end)
        )
        table.insert(
            self._connections,
            (sprint :: any).Pressed:Connect(function()
                if not hud:isProfessionMenuOpen() then
                    self._running = not self._running
                    onSprint(self._running)
                end
            end)
        )
        table.insert(
            self._connections,
            (dodge :: any).Pressed:Connect(function()
                if hud:isProfessionMenuOpen() then
                    hud:setProfessionMenuOpen(false)
                else
                    onDodge()
                end
            end)
        )
        table.insert(
            self._connections,
            (professionAbility :: any).Pressed:Connect(function()
                if not hud:isProfessionMenuOpen() then
                    onProfessionAbility()
                end
            end)
        )
        table.insert(self._connections, (professionMenu :: any).Pressed:Connect(onProfessionMenu))
        for index, action in { useFirst, useSecond } do
            local button = useButtons[index]
            table.insert(
                self._connections,
                (action :: any).Pressed:Connect(function()
                    local itemId = button:GetAttribute("ItemId")
                    if
                        not hud:isProfessionMenuOpen()
                        and type(itemId) == "string"
                        and itemId ~= ""
                    then
                        onUseConsumable(itemId)
                    end
                end)
            )
        end
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
        self:_installFallback(
            onInteract,
            onUseTool,
            onSprint,
            onDodge,
            onProfessionAbility,
            onProfessionMenu,
            onUseConsumable
        )
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
    table.insert(
        self._connections,
        UserInputService.InputBegan:Connect(function(input: InputObject, _processed: boolean)
            if input.KeyCode == Enum.KeyCode.Escape and hud:isProfessionMenuOpen() then
                hud:setProfessionMenuOpen(false)
            end
        end)
    )

    return self
end

function InputController._installFallback(
    self: InputController,
    onInteract: () -> (),
    onUseTool: () -> (),
    onSprint: (boolean) -> (),
    onDodge: () -> (),
    onProfessionAbility: () -> (),
    onProfessionMenu: () -> (),
    onUseConsumable: (itemId: string) -> ()
)
    table.insert(self._connections, self._hud:primaryButton().Activated:Connect(onInteract))
    table.insert(self._connections, self._hud:toolButton().Activated:Connect(onUseTool))
    table.insert(self._connections, self._hud:dodgeButton().Activated:Connect(onDodge))
    table.insert(
        self._connections,
        self._hud:abilityButton().Activated:Connect(onProfessionAbility)
    )
    table.insert(
        self._connections,
        self._hud:professionButton().Activated:Connect(onProfessionMenu)
    )
    for _, button in self._hud:useButtons() do
        table.insert(
            self._connections,
            button.Activated:Connect(function()
                local itemId = button:GetAttribute("ItemId")
                if type(itemId) == "string" and itemId ~= "" then
                    onUseConsumable(itemId)
                end
            end)
        )
    end
    table.insert(
        self._connections,
        self._hud:sprintButton().MouseButton1Down:Connect(function()
            self._running = not self._running
            onSprint(self._running)
        end)
    )
    table.insert(
        self._connections,
        UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
            if processed then
                return
            end
            if
                self._hud:isProfessionMenuOpen()
                and (input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape)
            then
                self._hud:setProfessionMenuOpen(false)
            elseif self._hud:isProfessionMenuOpen() then
                return
            elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
                onInteract()
            elseif
                input.KeyCode == Enum.KeyCode.LeftShift
                or input.KeyCode == Enum.KeyCode.ButtonL3
            then
                self._running = not self._running
                onSprint(self._running)
            elseif
                input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.ButtonB
            then
                onDodge()
            elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
                -- Mouse clicks are resolved by TapController; see the
                -- action binding above for why M1 must not live here too.
                onUseTool()
            elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1 then
                onProfessionAbility()
            elseif input.KeyCode == Enum.KeyCode.P or input.KeyCode == Enum.KeyCode.DPadUp then
                onProfessionMenu()
            elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.ButtonY then
                self:_useSlot(1, onUseConsumable)
            elseif input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.DPadDown then
                self:_useSlot(2, onUseConsumable)
            end
        end)
    )
end

--[[
    Use whichever consumable is sitting in a HUD slot. The slot decides
    the item rather than the key, so the fallback path and the action
    bindings agree without either of them knowing an item name.
]]
function InputController._useSlot(
    self: InputController,
    slot: number,
    onUseConsumable: (itemId: string) -> ()
)
    local button = self._hud:useButtons()[slot]
    if button == nil then
        return
    end
    local itemId = button:GetAttribute("ItemId")
    if type(itemId) == "string" and itemId ~= "" then
        onUseConsumable(itemId)
    end
end

return InputController
