--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WeatherController = {}
WeatherController.__index = WeatherController

type Streak = {
    drift: number,
    offset: Vector3,
    part: Part,
    speed: number,
}

export type WeatherController = typeof(setmetatable(
    {} :: {
        _profile: any,
        _folder: Folder,
        _streaks: { Streak },
        _active: boolean,
        _phase: string,
        _weather: any,
        _elapsed: number,
        _connection: RBXScriptConnection?,
    },
    WeatherController
))

local MAX_STREAKS = 18
local UPDATE_INTERVAL = 1 / 24
local FLOOR = -12
local CEILING = 28

function WeatherController.new(profile: any): WeatherController
    local folder = Instance.new("Folder")
    folder.Name = "LastLightLocalWeather"
    folder.Parent = Workspace

    local random = Random.new(1847)
    local streaks: { Streak } = {}
    for _ = 1, MAX_STREAKS do
        local streak = Instance.new("Part")
        streak.Name = "BramblewakeRain"
        streak.Anchored = true
        streak.CanCollide = false
        streak.CanQuery = false
        streak.CanTouch = false
        streak.CastShadow = false
        streak.Color = Color3.fromRGB(163, 193, 201)
        streak.Material = Enum.Material.Glass
        streak.Size = Vector3.new(0.045, random:NextNumber(3.8, 6.2), 0.045)
        streak.Transparency = 1
        streak.Parent = folder
        table.insert(streaks, {
            drift = random:NextNumber(-1.8, -0.7),
            offset = Vector3.new(
                random:NextNumber(-28, 28),
                random:NextNumber(FLOOR, CEILING),
                random:NextNumber(-34, 18)
            ),
            part = streak,
            speed = random:NextNumber(44, 62),
        })
    end

    local self = setmetatable({
        _profile = profile,
        _folder = folder,
        _streaks = streaks,
        _active = false,
        _phase = "day",
        _weather = profile.contractWeather(nil),
        _elapsed = 0,
        _connection = nil,
    }, WeatherController)

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

function WeatherController.setContext(
    self: WeatherController,
    expeditionActive: boolean,
    phase: string,
    weatherKind: string?
)
    self._active = expeditionActive
    self._phase = string.lower(phase)
    self._weather = self._profile.contractWeather(weatherKind)
    if not expeditionActive then
        for _, streak in self._streaks do
            streak.part.Transparency = 1
        end
    end
end

function WeatherController._step(self: WeatherController, deltaTime: number)
    if not self._active then
        return
    end
    self._elapsed += deltaTime
    local camera = Workspace.CurrentCamera
    if camera == nil then
        return
    end
    local cameraPosition = camera.CFrame.Position
    local weather = self._weather
    local visibleCount = math.min(
        MAX_STREAKS,
        math.floor(self._profile.streakCount(self._phase) * weather.countScale)
    )
    local weatherColor = Color3.fromRGB(weather.color[1], weather.color[2], weather.color[3])
    for index, streak in self._streaks do
        local nextY = self._profile.wrapHeight(
            streak.offset.Y - streak.speed * weather.speedScale * deltaTime,
            FLOOR,
            CEILING
        )
        streak.offset = Vector3.new(streak.offset.X, nextY, streak.offset.Z)
        local wind = math.sin(self._elapsed * 0.43 + index) * 0.55
        local fallDrift = (CEILING - nextY) * 0.22 * streak.drift
        local position = cameraPosition + streak.offset + Vector3.new(fallDrift + wind, 0, 0)
        streak.part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(-7))
        streak.part.Color = weatherColor
        streak.part.Transparency = if index <= visibleCount then weather.transparency else 1
    end
end

return WeatherController
