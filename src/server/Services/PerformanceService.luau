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

    It also owns the **session lifecycle** the release gates are read from, and
    that is not a second job: join-to-interactive was already measured here,
    and a session's start, its end and the fact that it never started are the
    same clock read at three moments. Splitting them across services is how a
    join failure rate ends up counted against a denominator gathered somewhere
    else.
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
        _sessionSegment: any,
        _analyticsService: any,
        _samples: { [string]: { number } },
        _joinedAt: { [Player]: number },
        _interactive: { [Player]: boolean },
        _actionCounts: { [Player]: number },
        _lastReportAt: { [Player]: number },
        _lastHeardAt: { [Player]: number },
        _lastIntroductionAt: { [Player]: number },
        _platform: { [Player]: string },
        _lastFps: { [Player]: number },
        _frames: number,
        _windowStartedAt: number,
        _heartbeat: RBXScriptConnection?,
        _startedAt: number,
        _lastBreachLogAt: { [string]: number },
        _shuttingDown: boolean,
        _soakProbe: any,
        _soakRun: any,
        _soakCounters: { [string]: () -> number? },
    },
    PerformanceService
))

function PerformanceService.new(
    logger: Logger,
    config: any,
    performanceBudget: any,
    sessionSegment: any,
    analyticsService: any,
    soakProbe: any
): PerformanceService
    return setmetatable({
        Name = PerformanceService.Name,
        _logger = logger,
        _config = config,
        _performanceBudget = performanceBudget,
        _sessionSegment = sessionSegment,
        _analyticsService = analyticsService,
        _samples = {},
        _joinedAt = {},
        _interactive = {},
        _actionCounts = {},
        _lastReportAt = {},
        _lastHeardAt = {},
        _lastIntroductionAt = {},
        _platform = {},
        _lastFps = {},
        _frames = 0,
        _windowStartedAt = 0,
        _heartbeat = nil,
        _startedAt = 0,
        _lastBreachLogAt = {},
        _shuttingDown = false,
        _soakProbe = soakProbe,
        _soakRun = nil,
        _soakCounters = {},
    }, PerformanceService)
end

--[[
    The soak half, which asks a different question from everything above.

    The budgets judge whether a run felt good. A soak asks whether the
    server is holding on to things, and that only shows up over cycles --
    so this samples once per town cycle at one fixed phase and hands the
    series to SoakProbe, which owns every rule about what a series means.

    The counters are injected rather than reached for. This service has no
    business knowing how many creatures EnemyService believes in or how
    large a profile encodes to, and a soak that reached across the whole
    server for its own numbers would be a second copy of every service's
    internals, going stale on its own schedule.

    It is off unless something turns it on. Reading instance counts costs a
    full descendant walk, which is affordable once a cycle and not
    affordable as a thing that happens on every server forever for a
    measurement nobody is reading.
]]
function PerformanceService.setSoakCounters(
    self: PerformanceService,
    counters: { [string]: () -> number? }
)
    self._soakCounters = counters
end

function PerformanceService.beginSoak(self: PerformanceService, phase: string): boolean
    if self._soakProbe == nil then
        return false
    end
    self._soakRun = self._soakProbe.begin(phase)
    self._logger:info("soak_started", { phase = phase })
    return true
end

function PerformanceService.isSoaking(self: PerformanceService): boolean
    return self._soakRun ~= nil
end

--[[
    One cycle's reading. A counter that errors or answers with something
    that is not a number is left out of the sample entirely rather than
    filled in with a zero -- a zero is a reading, and an absent metric is
    what SoakProbe's `missing` list exists to report.
]]
function PerformanceService.sampleSoak(self: PerformanceService, cycle: number, phase: string): any
    local run = self._soakRun
    if run == nil then
        return nil
    end

    local counts: { [string]: number } = {}
    for metricId, counter in self._soakCounters do
        local ok, value = pcall(counter)
        if ok and type(value) == "number" then
            counts[metricId] = value
        else
            self._logger:warn("soak_counter_failed", { metric = metricId })
        end
    end

    local nextRun, result = self._soakProbe.record(run, cycle, phase, counts)
    if not result.accepted then
        -- Loudly, because a refused sample is a sampler wired to the wrong
        -- hook, and a soak quietly collecting nothing is the exact shape of
        -- a gate that passes because nobody measured it.
        self._logger:warn("soak_sample_refused", { cycle = cycle, reason = result.reason })
        return nil
    end
    self._soakRun = nextRun

    local report = self._soakProbe.report(nextRun)
    self._logger:info("soak_sample", {
        cycle = cycle,
        verdict = report.verdict,
        cycles = report.cycles,
        instances = counts.instances,
        enemies = counts.tracked_enemies,
        residue = counts.player_residue,
        profileBytes = counts.profile_bytes,
    })
    return report
end

function PerformanceService.soakReport(self: PerformanceService): any
    local run = self._soakRun
    if run == nil then
        return nil
    end
    return self._soakProbe.report(run)
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

--[[
    How a session finished, decided from what a server can actually see.

    Roblox does not tell a server that a client crashed; PlayerRemoving fires
    the same way for a player who quit and a player whose phone died. What
    differs is the telemetry: a client reports on a fixed interval right up to
    the moment it closes, so a session whose last report is several intervals
    stale at the moment the player disappears stopped rather than left.

    Three intervals of slack, deliberately generous. A client that missed one
    report to a stall is not a crash, and calling it one would fail the
    crash-free gate on the devices the gate exists to protect. A shutdown is
    named separately because a server closing is not a player's session ending
    badly, and counting a scheduled restart as fifty crashes is how a gate
    gets ignored.
]]
function PerformanceService._sessionEndReason(self: PerformanceService, player: Player): string
    if self._shuttingDown then
        return "shutdown"
    end
    -- Anything the client said, not only a sample. A player who becomes
    -- interactive and quits inside the first reporting interval has sent an
    -- introduction and no sample, and reading only samples would file that
    -- perfectly ordinary exit as a crash.
    local lastAt = self._lastHeardAt[player]
    if lastAt == nil then
        -- Never said anything at all. If they never became interactive this is
        -- a join that did not finish; if they did, it is a client that went
        -- quiet immediately, which is the same shape as a crash.
        return if self._interactive[player] then "dropped" else "left"
    end
    if os.clock() - lastAt > self._config.PerformanceReportIntervalSeconds * 3 then
        return "dropped"
    end
    return "left"
end

function PerformanceService._closeSession(self: PerformanceService, player: Player)
    local joinedAt = self._joinedAt[player]
    if joinedAt == nil then
        return
    end
    local interactive = self._interactive[player] == true
    local duration = os.clock() - joinedAt
    local platform = self._platform[player] or "unknown"
    local reason = self:_sessionEndReason(player)

    -- A player who left before the world would answer them never had a
    -- session, and counting them as one that ended cleanly hides the join
    -- failure rate inside the crash-free rate.
    -- GATE-METRIC: join_failed
    if not interactive and reason ~= "shutdown" then
        self._analyticsService:joinFailed(player, "left_before_interactive", duration, platform)
    end

    -- GATE-METRIC: session_ended
    self._analyticsService:sessionEnded(
        player.UserId,
        reason,
        duration,
        interactive,
        platform,
        self._sessionSegment.id(platform, self._sessionSegment.tier(self._lastFps[player]))
    )
end

function PerformanceService.Init(self: PerformanceService, _context: any)
    Players.PlayerAdded:Connect(function(player: Player)
        self._joinedAt[player] = os.clock()
        self._actionCounts[player] = 0
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        self:_closeSession(player)
        self._joinedAt[player] = nil
        self._interactive[player] = nil
        self._actionCounts[player] = nil
        self._lastReportAt[player] = nil
        self._lastHeardAt[player] = nil
        self._lastIntroductionAt[player] = nil
        self._platform[player] = nil
        self._lastFps[player] = nil
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

    -- A server closing is not fifty players crashing, and the only moment that
    -- distinction can be drawn is before the PlayerRemoving storm that follows.
    game:BindToClose(function()
        self._shuttingDown = true
    end)

    self._logger:info("performance_service_started", {
        memoryCeilingMb = self._config.BaselinePhoneMemoryCeilingMb,
    })
end

--[[
    Called when a player reaches interactive play. Only the first call counts:
    the budget is join-to-interactive, not every later state load.

    `createdAt` is the profile's own first-seen stamp and turns into the number
    D1 and D7 return are counted from. It is passed in rather than looked up
    because this service has no business holding a profile; the caller is
    already inside the load that produced one.
]]
function PerformanceService.markInteractive(
    self: PerformanceService,
    player: Player,
    createdAt: number?
)
    if self._interactive[player] then
        return
    end
    local joinedAt = self._joinedAt[player]
    if joinedAt == nil then
        return
    end
    self._interactive[player] = true
    local joinSeconds = os.clock() - joinedAt
    self:_record("join_seconds", joinSeconds)

    local elapsedDays = if createdAt == nil or createdAt <= 0
        then 0
        else math.max(0, math.floor((os.time() - createdAt) / 86400))
    -- GATE-METRIC: interactive_session
    self._analyticsService:sessionStarted(
        player,
        joinSeconds,
        self._platform[player] or "unknown",
        elapsedDays
    )
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
    local interval = self._config.PerformanceReportIntervalSeconds

    --[[
        A client saying what it is, which arrives on its own message with no
        frame data in it -- it is sent on the first frame and there is nothing
        to sample for another whole interval.

        It gets its own limit rather than skipping the sample one. Returning
        early past a rate limit is how a bounded remote becomes an unbounded
        one, and the shape a client would reach for is exactly this: a payload
        the handler answers before it has counted it. Accepted rather than
        rejected so a legitimate introduction does not print the warning that
        means "a client is sending nonsense", which is the line somebody
        hunting a real problem would be reading.
    ]]
    local platform = self._sessionSegment.platformOf(payload)
    if self._sessionSegment.isIntroduction(payload) then
        local lastIntroductionAt = self._lastIntroductionAt[player]
        if lastIntroductionAt ~= nil and now - lastIntroductionAt < interval then
            return false
        end
        self._lastIntroductionAt[player] = now
        self._lastHeardAt[player] = now
        self._platform[player] = platform
        return true
    end
    if platform ~= nil then
        self._platform[player] = platform
    end

    local lastAt = self._lastReportAt[player]
    if lastAt ~= nil and now - lastAt < interval * 0.5 then
        return false
    end

    local sample = self._performanceBudget.sanitizeClientReport(payload)
    if sample == nil then
        self._logger:warn("performance_report_rejected", { player = player.UserId })
        return false
    end
    self._lastReportAt[player] = now
    self._lastHeardAt[player] = now
    self._lastFps[player] = sample.fps

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
