--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WorldMotionController = {}
WorldMotionController.__index = WorldMotionController

type MotionState = {
    basePivot: CFrame,
    position: Vector3,
    phaseOffset: number,
    speed: number,
    active: boolean,
}

type LightState = {
    baseSize: Vector3,
    baseTransparency: number,
    baseBrightness: number?,
    baseRange: number?,
    phaseOffset: number,
    active: boolean,
}

type SwayState = {
    baseCFrame: CFrame,
    phaseOffset: number,
    position: Vector3,
    active: boolean,
}

export type WorldMotionController = typeof(setmetatable(
    {} :: {
        _motionTag: string,
        _lightTag: string,
        _swayTag: string,
        _ambientMotion: any,
        _motions: { [Model]: MotionState },
        _lights: { [BasePart]: LightState },
        _sways: { [BasePart]: SwayState },
        _phase: string,
        _elapsed: number,
        _connection: RBXScriptConnection?,
    },
    WorldMotionController
))

local ACTIVE_DISTANCE = 190
local SWAY_DISTANCE = 125
local UPDATE_INTERVAL = 1 / 20

local function phaseOffsetFor(instance: Instance): number
    local pivot = if instance:IsA("Model")
        then instance:GetPivot()
        else (instance :: BasePart).CFrame
    local position = pivot.Position
    return math.abs(position.X * 0.053 + position.Y * 0.127 + position.Z * 0.079) % (math.pi * 2)
end

function WorldMotionController.new(
    motionTag: string,
    lightTag: string,
    swayTag: string,
    ambientMotion: any
): WorldMotionController
    local self = setmetatable({
        _motionTag = motionTag,
        _lightTag = lightTag,
        _swayTag = swayTag,
        _ambientMotion = ambientMotion,
        _motions = {},
        _lights = {},
        _sways = {},
        _phase = "day",
        _elapsed = 0,
        _connection = nil,
    }, WorldMotionController)

    local function registerMotion(instance: Instance)
        if not instance:IsA("Model") or self._motions[instance] ~= nil then
            return
        end
        local pivot = instance:GetPivot()
        self._motions[instance] = {
            basePivot = pivot,
            position = pivot.Position,
            phaseOffset = phaseOffsetFor(instance),
            speed = math.max(0, tonumber(instance:GetAttribute("MotionSpeed")) or 0.34),
            active = false,
        }
    end
    local function unregisterMotion(instance: Instance)
        if instance:IsA("Model") then
            self._motions[instance] = nil
        end
    end
    local function registerLight(instance: Instance)
        if not instance:IsA("BasePart") or self._lights[instance] ~= nil then
            return
        end
        local pointLight = instance:FindFirstChildOfClass("PointLight")
        self._lights[instance] = {
            baseSize = instance.Size,
            baseTransparency = instance.Transparency,
            baseBrightness = if pointLight == nil then nil else pointLight.Brightness,
            baseRange = if pointLight == nil then nil else pointLight.Range,
            phaseOffset = phaseOffsetFor(instance),
            active = false,
        }
    end
    local function unregisterLight(instance: Instance)
        if instance:IsA("BasePart") then
            self._lights[instance] = nil
        end
    end
    local function registerSway(instance: Instance)
        if not instance:IsA("BasePart") or self._sways[instance] ~= nil then
            return
        end
        self._sways[instance] = {
            baseCFrame = instance.CFrame,
            phaseOffset = phaseOffsetFor(instance),
            position = instance.Position,
            active = false,
        }
    end
    local function unregisterSway(instance: Instance)
        if instance:IsA("BasePart") then
            self._sways[instance] = nil
        end
    end

    for _, instance in CollectionService:GetTagged(motionTag) do
        registerMotion(instance)
    end
    for _, instance in CollectionService:GetTagged(lightTag) do
        registerLight(instance)
    end
    for _, instance in CollectionService:GetTagged(swayTag) do
        registerSway(instance)
    end
    CollectionService:GetInstanceAddedSignal(motionTag):Connect(registerMotion)
    CollectionService:GetInstanceRemovedSignal(motionTag):Connect(unregisterMotion)
    CollectionService:GetInstanceAddedSignal(lightTag):Connect(registerLight)
    CollectionService:GetInstanceRemovedSignal(lightTag):Connect(unregisterLight)
    CollectionService:GetInstanceAddedSignal(swayTag):Connect(registerSway)
    CollectionService:GetInstanceRemovedSignal(swayTag):Connect(unregisterSway)

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

function WorldMotionController.setPhase(self: WorldMotionController, phase: string)
    self._phase = string.lower(phase)
end

function WorldMotionController._step(self: WorldMotionController, deltaTime: number)
    self._elapsed += deltaTime
    local camera = Workspace.CurrentCamera
    if camera == nil then
        return
    end
    local cameraPosition = camera.CFrame.Position

    for model, state in self._motions do
        if model.Parent == nil then
            self._motions[model] = nil
            continue
        end
        local active = (state.position - cameraPosition).Magnitude <= ACTIVE_DISTANCE
        if active then
            local angle =
                self._ambientMotion.rotorAngle(self._elapsed, state.speed, state.phaseOffset)
            model:PivotTo(state.basePivot * CFrame.Angles(0, 0, angle))
            state.active = true
        elseif state.active then
            model:PivotTo(state.basePivot)
            state.active = false
        end
    end

    for glow, state in self._lights do
        if glow.Parent == nil then
            self._lights[glow] = nil
            continue
        end
        local active = (glow.Position - cameraPosition).Magnitude <= ACTIVE_DISTANCE
        local pointLight = glow:FindFirstChildOfClass("PointLight")
        if active then
            local level =
                self._ambientMotion.lightLevel(self._elapsed, state.phaseOffset, self._phase)
            local sizeScale = 0.94 + level * 0.08
            glow.Size = state.baseSize * sizeScale
            glow.Transparency = math.clamp(state.baseTransparency + (1 - level) * 0.18, 0.02, 0.55)
            if pointLight ~= nil and state.baseBrightness ~= nil and state.baseRange ~= nil then
                pointLight.Brightness = state.baseBrightness * (0.72 + level * 0.3)
                pointLight.Range = state.baseRange * (0.94 + level * 0.05)
            end
            state.active = true
        elseif state.active then
            glow.Size = state.baseSize
            glow.Transparency = state.baseTransparency
            if pointLight ~= nil and state.baseBrightness ~= nil and state.baseRange ~= nil then
                pointLight.Brightness = state.baseBrightness
                pointLight.Range = state.baseRange
            end
            state.active = false
        end
    end

    for foliage, state in self._sways do
        if foliage.Parent == nil then
            self._sways[foliage] = nil
            continue
        end
        local active = (state.position - cameraPosition).Magnitude <= SWAY_DISTANCE
        if active then
            local wind = math.sin(self._elapsed * 1.18 + state.phaseOffset)
            local gust = math.sin(self._elapsed * 0.31 + state.phaseOffset * 0.47)
            local angle = math.rad(1.8 + if self._phase == "night" then 1.1 else 0.4)
            foliage.CFrame = state.baseCFrame
                * CFrame.Angles(wind * angle * 0.22, 0, (wind + gust * 0.35) * angle)
            state.active = true
        elseif state.active then
            foliage.CFrame = state.baseCFrame
            state.active = false
        end
    end
end

return WorldMotionController
