--!strict

--[[
    Reports this client's own frame and memory numbers to the server.

    Frame rate, stalls, and memory are the three budgets in
    docs/TECHNICAL_ARCHITECTURE.md that only the client can see, and they are
    the ones the exit gate cares most about, since "target device meets frame,
    memory, join, and network budgets" is a statement about the phone in
    someone's hand rather than about the server.

    What it sends, once per interval:

      * the mean frame rate over the interval, not the instantaneous one, so a
        single lucky frame cannot flatter the sample;
      * the worst single frame in the interval, in milliseconds, which is the
        stutter a player actually felt;
      * total client memory, which the server turns into headroom against the
        baseline device ceiling.

    The interval matters: sampling every frame and sending it would itself be
    the network problem this is supposed to measure.
]]

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local PerformanceController = {}
PerformanceController.__index = PerformanceController

export type PerformanceController = typeof(setmetatable(
    {} :: {
        _remote: RemoteEvent,
        _interval: number,
        _frames: number,
        _elapsed: number,
        _worstFrameMs: number,
        _connection: RBXScriptConnection?,
    },
    PerformanceController
))

function PerformanceController.new(remote: RemoteEvent, interval: number): PerformanceController
    local self = setmetatable({
        _remote = remote,
        _interval = math.max(1, interval),
        _frames = 0,
        _elapsed = 0,
        _worstFrameMs = 0,
        _connection = nil,
    }, PerformanceController)

    self._connection = RunService.RenderStepped:Connect(function(deltaTime: number)
        self:_step(deltaTime)
    end)
    return self
end

function PerformanceController._step(self: PerformanceController, deltaTime: number)
    self._frames += 1
    self._elapsed += deltaTime
    self._worstFrameMs = math.max(self._worstFrameMs, deltaTime * 1000)

    if self._elapsed < self._interval then
        return
    end

    local fps = self._frames / self._elapsed
    local worstFrameMs = self._worstFrameMs
    self._frames = 0
    self._elapsed = 0
    self._worstFrameMs = 0

    -- A pcall because a failed telemetry send must never be the thing that
    -- breaks someone's session.
    pcall(function()
        self._remote:FireServer({
            schemaVersion = 1,
            fps = fps,
            spikeMs = worstFrameMs,
            memoryMb = Stats:GetTotalMemoryUsageMb(),
        })
    end)
end

function PerformanceController.destroy(self: PerformanceController)
    local connection = self._connection
    if connection ~= nil then
        connection:Disconnect()
        self._connection = nil
    end
end

return table.freeze(PerformanceController)
