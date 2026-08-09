--!strict

local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)

local PhaseService = {}
PhaseService.__index = PhaseService
PhaseService.Name = "PhaseService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type PhaseService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _worldService: any,
        _enemyService: any,
        _nightSchedule: any,
        _duskSeconds: number,
        _nightSeconds: number,
        _phase: string,
        _phaseEndsAt: number,
        _active: boolean,
        _generation: number,
        _onChanged: ((string?) -> ())?,
        _onComplete: (() -> ())?,
    },
    PhaseService
))

function PhaseService.new(
    logger: Logger,
    worldService: any,
    enemyService: any,
    nightSchedule: any,
    duskSeconds: number,
    nightSeconds: number
): PhaseService
    return setmetatable({
        Name = PhaseService.Name,
        _logger = logger,
        _worldService = worldService,
        _enemyService = enemyService,
        _nightSchedule = nightSchedule,
        _duskSeconds = duskSeconds,
        _nightSeconds = nightSeconds,
        _phase = "day",
        _phaseEndsAt = 0,
        _active = false,
        _generation = 0,
        _onChanged = nil,
        _onComplete = nil,
    }, PhaseService)
end

function PhaseService.Init(_self: PhaseService, _context: any) end

function PhaseService.Start(_self: PhaseService) end

function PhaseService.setChangedHandler(self: PhaseService, callback: (string?) -> ())
    self._onChanged = callback
end

function PhaseService.setCompleteHandler(self: PhaseService, callback: () -> ())
    self._onComplete = callback
end

function PhaseService._notify(self: PhaseService, toast: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(toast)
    end
end

local function waitUntil(target: number, generation: number, service: PhaseService): boolean
    while workspace:GetServerTimeNow() < target do
        if service._generation ~= generation or not service._active then
            return false
        end
        task.wait(0.15)
    end
    return service._generation == generation and service._active
end

function PhaseService.startFirstNight(self: PhaseService): boolean
    if self._active then
        return false
    end

    self._active = true
    self._generation += 1
    local generation = self._generation
    self._phase = "dusk"
    self._phaseEndsAt = workspace:GetServerTimeNow() + self._duskSeconds
    self._worldService:setDusk(true)
    self:_notify(Strings.get("toast.dusk_falls_prepare_the_light"))
    self._logger:info("first_night_dusk_started", { duration = self._duskSeconds })

    task.spawn(function()
        if not waitUntil(self._phaseEndsAt, generation, self) then
            return
        end

        self._phase = "night"
        local nightStartedAt = workspace:GetServerTimeNow()
        self._phaseEndsAt = nightStartedAt + self._nightSeconds
        self._worldService:setNight(true)
        self._enemyService:startNight()
        self:_notify(Strings.get("toast.night_has_arrived"))
        self._logger:info("first_night_started", { duration = self._nightSeconds })

        for _, beat in self._nightSchedule.beats(self._nightSeconds) do
            if not waitUntil(nightStartedAt + beat.at, generation, self) then
                return
            end
            if beat.kind == "spawn" then
                self._enemyService:spawn(beat.enemyId)
            elseif beat.kind == "breach" then
                self._enemyService:setBreach()
            elseif beat.kind == "warning" then
                self:_notify(Strings.get("toast.the_forest_goes_quiet"))
            end
        end

        if not waitUntil(self._phaseEndsAt, generation, self) then
            return
        end
        self:_finishFirstNight()
    end)

    return true
end

function PhaseService.ensureFirstNight(self: PhaseService)
    if not self._active and self._phase ~= "reveal" then
        self:startFirstNight()
    end
end

function PhaseService._finishFirstNight(self: PhaseService)
    self._active = false
    self._phase = "reveal"
    self._phaseEndsAt = 0
    self._enemyService:stopNight()
    self._worldService:setNight(false)
    self._worldService:setBeaconVisible(true)
    self:_notify(Strings.get("toast.dawn_breaks_a_memory_calls"))
    -- The night resolving, which is a server fact. Each player's own crossing
    -- is `first_night_completed` from the tutorial, and the two are named
    -- apart on purpose: a gate that reads a completion rate per player must
    -- not be able to read this one by accident.
    self._logger:info("first_night_resolved")

    local callback = self._onComplete
    if callback ~= nil then
        callback()
    end
end

function PhaseService.snapshot(self: PhaseService): any
    return {
        phase = self._phase,
        phaseEndsAt = self._phaseEndsAt,
        nightActive = self._active and self._phase == "night",
        lanternHealth = self._enemyService:lanternHealth(),
        enemyCount = self._enemyService:activeCount(),
    }
end

function PhaseService.isNightActive(self: PhaseService): boolean
    return self._active and self._phase == "night"
end

function PhaseService.hasCompletedFirstNight(self: PhaseService): boolean
    return self._phase == "reveal"
end

return table.freeze(PhaseService)
