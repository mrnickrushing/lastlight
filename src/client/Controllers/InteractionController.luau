--!strict

local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local InteractionController = {}
InteractionController.__index = InteractionController

export type InteractionController = typeof(setmetatable(
    {} :: {
        _tag: string,
        _hud: any,
        _shown: { [ProximityPrompt]: boolean },
        _current: ProximityPrompt?,
        _heartbeat: RBXScriptConnection?,
    },
    InteractionController
))

function InteractionController.new(tag: string, hud: any): InteractionController
    local self = setmetatable({
        _tag = tag,
        _hud = hud,
        _shown = {},
        _current = nil,
        _heartbeat = nil,
    }, InteractionController)

    ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
        if CollectionService:HasTag(prompt, tag) then
            self._shown[prompt] = true
            self:_select()
        end
    end)
    ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
        self._shown[prompt] = nil
        if self._current == prompt then
            self._current = nil
        end
        self:_select()
    end)

    local accumulator = 0
    self._heartbeat = RunService.RenderStepped:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator >= 0.2 then
            accumulator = 0
            self:_select()
        end
    end)

    return self
end

function InteractionController._select(self: InteractionController)
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    local closest: ProximityPrompt? = nil
    local closestDistance = math.huge

    if root ~= nil and root:IsA("BasePart") then
        for prompt in self._shown do
            local target = prompt.Parent
            if prompt.Enabled and target ~= nil and target:IsA("BasePart") then
                local distance = (root.Position - target.Position).Magnitude
                if distance < closestDistance then
                    closest = prompt
                    closestDistance = distance
                end
            end
        end
    end

    self._current = closest
    if closest == nil then
        self._hud:setInteraction(nil, false)
    else
        self._hud:setInteraction(string.upper(closest.ActionText), true)
    end
end

function InteractionController.currentInteractionId(self: InteractionController): string?
    local prompt = self._current
    if prompt == nil then
        return nil
    end
    local interactionId = prompt:GetAttribute("InteractionId")
    return if type(interactionId) == "string" then interactionId else nil
end

return InteractionController
