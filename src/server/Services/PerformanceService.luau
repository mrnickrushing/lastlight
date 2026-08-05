--!strict

--[[
    Samples a live session against the performance budgets.

    Milestone 3's exit gate wants a 30-minute run on a target device to meet
    frame, memory, join, and network budgets. This is the thing that makes that
    sentence produce numbers: it collects samples while people play and hands
    them to PerformanceBudget, which decides whether the run passed.

    Split of responsibility, because it decides what is trustworthy:

      * The server measures what it owns -- its own heartbeat, how long each
        player waited to become interactive, and how much remote traffic each
        client actually sent. None of it can be influenced by a client.
      * The client reports what only it can see -- its frame rate, its worst
        stall, its memory. That arrives over a separate telemetry remote,
        bounded and rate limited, and grants nothing.

    Samples are capped so a server left running overnight cannot grow this into
    a leak. The cap drops the oldest, which keeps the recent run intact -- the
    30 minutes anyone is actually reporting on.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PerformanceService = {}
PerformanceService.__index = PerformanceService
PerformanceService.Name = "PerformanceService"

local MAX_SAMPLES = 5000

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type PerformanceService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _performanceBudget: any,
        _samples: { [string]: { number } },
        _joinedAt: { [Player]: number },
        _interactive: { [Player]: boolean },
        _actionCounts: { [Player]: number },
        _lastReportAt: { [Player]: number },
        _frames: number,
        _windowStartedAt: number,
        _heartbeat: RBXScriptConnection?,
        _startedAt: number,
        _lastBreachLogAt: { [string]: number },
    },
    PerformanceService
))

function PerformanceService.new(
    logger: Logger,
    config: any,
    performanceBudget: any
): PerformanceService
    return setmetatable({
        Name = PerformanceService.Name,
        _logger = logger,
        _config = config,
        _performanceBudget = performanceBudget,
        _samples = {},
        _joinedAt = {},
        _interactive = {},
        _actionCounts = {},
        _lastReportAt = {},
        _frames = 0,
        _windowStartedAt = 0,
        _heartbeat = nil,
        _startedAt = 0,
        _lastBreachLogAt = {},
    }, PerformanceService)
end

function PerformanceService._record(self: PerformanceService, metricId: string, value: number)
    if not self._performanceBudget.isValidMetric(metricId) then
        return
    end
    local samples = self._samples[metricId]
    if samples == nil then
        samples = {}
        self._samples[metricId] = samples
    end
    table.insert(samples, value)
    if #samples > MAX_SAMPLES then
        table.remove(samples, 1)
    end

    -- A breach is worth saying out loud while the run is still happening, so
    -- whoever is holding the phone knows which minute to look at later. Once
    -- per metric per two minutes: a machine that sits at 15 fps otherwise
    -- prints the same warning every second and buries every real error in
    -- the log (observed: hundreds per session drowning a rejection that was
    -- actually being hunted).
    if self._performanceBudget.classify(metricId, value) == "breach" then
        local now = os.clock()
        local lastAt = self._lastBreachLogAt[metricId]
        if lastAt == nil or now - lastAt >= 120 then
            self._lastBreachLogAt[metricId] = now
            self._logger:warn("performance_budget_breach", {
                metric = metricId,
                value = value,
            })
        end
    end
end

function PerformanceService.Init(self: PerformanceService, _context: any)
    Players.PlayerAdded:Connect(function(player: Player)
        self._joinedAt[player] = os.clock()
        self._actionCounts[player] = 0
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        self._joinedAt[player] = nil
        self._interactive[player] = nil
        self._actionCounts[player] = nil
        self._lastReportAt[player] = nil
    end)
end

function PerformanceService.Start(self: PerformanceService)
    self._startedAt = os.clock()
    self._windowStartedAt = os.clock()

    -- Heartbeat rate is counted over a one-second window rather than taken
    -- from a single delta. One long frame is a spike, which the client already
    -- reports; what the budget asks about the server is the sustained rate.
    self._heartbeat = RunService.Heartbeat:Connect(function()
        self._frames += 1
        local now = os.clock()
        local elapsed = now - self._windowStartedAt
        if elapsed < 1 then
            return
        end

        self:_record("server_heartbeat_hz", self._frames / elapsed)

        for player, count in self._actionCounts do
            if count > 0 then
                self:_record("remote_actions_per_second", count / elapsed)
                self._actionCounts[player] = 0
            end
        end

        self._frames = 0
        self._windowStartedAt = now
    end)

    self._logger:info("performance_service_started", {
        memoryCeilingMb = self._config.BaselinePhoneMemoryCeilingMb,
    })
end

-- Called when a player reaches interactive play. Only the first call counts:
-- the budget is join-to-interactive, not every later state load.
function PerformanceService.markInteractive(self: PerformanceService, player: Player)
    if self._interactive[player] then
        return
    end
    local joinedAt = self._joinedAt[player]
    if joinedAt == nil then
        return
    end
    self._interactive[player] = true
    self:_record("join_seconds", os.clock() - joinedAt)
end

function PerformanceService.noteAction(self: PerformanceService, player: Player)
    local count = self._actionCounts[player]
    if count ~= nil then
        self._actionCounts[player] = count + 1
    end
end

--[[
    Take a client's frame and memory sample.

    Rate limited on the server's clock rather than trusting the client to keep
    to the interval, and every field is bounded before it reaches the report.
    A refused report is counted in the log, not silently dropped, because a
    client that cannot report is itself a symptom worth seeing.
]]
function PerformanceService.acceptClientReport(
    self: PerformanceService,
    player: Player,
    payload: any
): boolean
    local now = os.clock()
    local lastAt = self._lastReportAt[player]
    local interval = self._config.PerformanceReportIntervalSeconds
    if lastAt ~= nil and now - lastAt < interval * 0.5 then
        return false
    end

    local sample = self._performanceBudget.sanitizeClientReport(payload)
    if sample == nil then
        self._logger:warn("performance_report_rejected", { player = player.UserId })
        return false
    end
    self._lastReportAt[player] = now

    self:_record("client_fps", sample.fps)
    self:_record("frame_spike_ms", sample.spikeMs)
    self:_record(
        "client_memory_headroom",
        self._performanceBudget.memoryHeadroom(
            sample.memoryMb,
            self._config.BaselinePhoneMemoryCeilingMb
        )
    )
    return true
end

function PerformanceService.report(self: PerformanceService): any
    return self._performanceBudget.report(self._samples)
end

function PerformanceService.formattedReport(self: PerformanceService): { string }
    local report = self:report()
    local lines = self._performanceBudget.format(report)
    table.insert(
        lines,
        1,
        string.format(
            "%s after %.0f min, %d players",
            string.upper(report.verdict),
            (os.clock() - self._startedAt) / 60,
            #Players:GetPlayers()
        )
    )
    return lines
end

function PerformanceService.Stop(self: PerformanceService)
    local heartbeat = self._heartbeat
    if heartbeat ~= nil then
        heartbeat:Disconnect()
        self._heartbeat = nil
    end
end

return table.freeze(PerformanceService)
