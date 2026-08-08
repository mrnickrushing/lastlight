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

    It also says what kind of device it is, once on the first frame and then on
    every sample. RELEASE_GATES.md sets a per-segment threshold on five gates
    and names phone, tablet, desktop and console as the slices, and a server
    cannot see a screen. The introduction is sent on its own because the first
    *sample* is a whole interval away: a session that ends in four seconds is
    exactly the kind the join and crash gates are about, and one with no
    platform on it cannot be counted against the phone threshold it failed.
    Repeating the label on every sample is what heals an introduction that
    raced the server's handler into existence.

    Nothing in the game reads the label. It is a dimension on a metric.
]]

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SessionSegment = require(ReplicatedStorage:WaitForChild("LastLight").SessionSegment)

local PerformanceController = {}
PerformanceController.__index = PerformanceController

export type PerformanceController = typeof(setmetatable(
    {} :: {
        _remote: RemoteEvent,
        _interval: number,
        _frames: number,
        _elapsed: number,
        _worstFrameMs: number,
        _platform: string,
        _connection: RBXScriptConnection?,
    },
    PerformanceController
))

--[[
    The four words the gates are sliced by, decided once.

    Viewport comes from the camera rather than from the screen, because the
    camera's size is what every layout in this game is measured against and a
    label that disagrees with the layout would send a portrait bug to the
    tablet column.
]]
local function platformClass(): string
    local camera = Workspace.CurrentCamera
    local viewport = if camera ~= nil then camera.ViewportSize else Vector2.zero
    return SessionSegment.platformClass(
        GuiService:IsTenFootInterface(),
        UserInputService.TouchEnabled,
        UserInputService.KeyboardEnabled,
        viewport.X,
        viewport.Y
    )
end

function PerformanceController.new(remote: RemoteEvent, interval: number): PerformanceController
    local self = setmetatable({
        _remote = remote,
        _interval = math.max(1, interval),
        _frames = 0,
        _elapsed = 0,
        _worstFrameMs = 0,
        _platform = "unknown",
        _connection = nil,
    }, PerformanceController)

    local ok, resolved = pcall(platformClass)
    self._platform = if ok then resolved else "unknown"

    -- The introduction, before there is anything to sample. A report with no
    -- frame data is a client saying what it is, and the server treats it as
    -- exactly that.
    pcall(function()
        self._remote:FireServer({
            schemaVersion = 1,
            platform = self._platform,
        })
    end)

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
            platform = self._platform,
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
