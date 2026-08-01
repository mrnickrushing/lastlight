--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AmbientController = {}
AmbientController.__index = AmbientController

type MoteState = {
    basePosition: Vector3,
    baseTransparency: number,
    phaseOffset: number,
    visible: boolean,
}

export type AmbientController = typeof(setmetatable(
    {} :: {
        _tag: string,
        _motes: { [BasePart]: MoteState },
        _phase: string,
        _elapsed: number,
        _connection: RBXScriptConnection?,
    },
    AmbientController
))

local ACTIVE_DISTANCE = 125
local UPDATE_INTERVAL = 1 / 24

local function phaseOffsetFor(instance: Instance): number
    local position = if instance:IsA("BasePart") then instance.Position else Vector3.zero
    return math.abs(position.X * 0.071 + position.Y * 0.137 + position.Z * 0.043) % (math.pi * 2)
end

function AmbientController.new(tag: string): AmbientController
    local self = setmetatable({
        _tag = tag,
        _motes = {},
        _phase = "day",
        _elapsed = 0,
        _connection = nil,
    }, AmbientController)

    local function register(instance: Instance)
        if not instance:IsA("BasePart") or self._motes[instance] ~= nil then
            return
        end
        self._motes[instance] = {
            basePosition = instance.Position,
            baseTransparency = instance.Transparency,
            phaseOffset = phaseOffsetFor(instance),
            visible = false,
        }
    end
    local function unregister(instance: Instance)
        if instance:IsA("BasePart") then
            self._motes[instance] = nil
        end
    end

    for _, instance in CollectionService:GetTagged(tag) do
        register(instance)
    end
    CollectionService:GetInstanceAddedSignal(tag):Connect(register)
    CollectionService:GetInstanceRemovedSignal(tag):Connect(unregister)

    local accumulator = 0
    self._connection = RunService.RenderStepped:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < UPDATE_INTERVAL then
            return
        end
        local elapsed = accumulator
        accumulator = 0
        self:_step(elapsed)
    end)
    return self
end

function AmbientController.setPhase(self: AmbientController, phase: string)
    self._phase = string.lower(phase)
end

function AmbientController._step(self: AmbientController, deltaTime: number)
    self._elapsed += deltaTime
    local camera = Workspace.CurrentCamera
    if camera == nil then
        return
    end
    local cameraPosition = camera.CFrame.Position
    local night = self._phase == "night"
    local dusk = self._phase == "dusk"
    local amplitude = if night then 0.92 elseif dusk then 0.68 else 0.42
    local transparencyBias = if night then -0.08 elseif dusk then -0.03 else 0.14

    for mote, state in self._motes do
        if mote.Parent == nil then
            self._motes[mote] = nil
            continue
        end
        local active = (state.basePosition - cameraPosition).Magnitude <= ACTIVE_DISTANCE
        if active then
            local wave = self._elapsed + state.phaseOffset
            mote.Position = state.basePosition
                + Vector3.new(
                    math.sin(wave * 0.83) * amplitude,
                    math.sin(wave * 1.17) * amplitude * 0.45,
                    math.cos(wave * 0.71) * amplitude
                )
            mote.Transparency = math.clamp(
                state.baseTransparency + transparencyBias + math.sin(wave * 1.7) * 0.08,
                0.04,
                0.72
            )
            state.visible = true
        elseif state.visible then
            mote.Position = state.basePosition
            mote.Transparency = math.clamp(state.baseTransparency + transparencyBias, 0.04, 0.72)
            state.visible = false
        end
    end
end

return AmbientController
