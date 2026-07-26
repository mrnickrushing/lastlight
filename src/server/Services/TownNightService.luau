--!strict

local TownNightService = {}
TownNightService.__index = TownNightService
TownNightService.Name = "TownNightService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type TownNightService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _worldService: any,
        _enemyService: any,
        _phaseService: any,
        _townNightSchedule: any,
        _daySeconds: number,
        _duskSeconds: number,
        _nightSeconds: number,
        _blackoutInterval: number,
        _enabled: boolean,
        _nightNumber: number,
        _phase: string,
        _phaseEndsAt: number,
        _onChanged: ((string?) -> ())?,
    },
    TownNightService
))

function TownNightService.new(
    logger: Logger,
    config: any,
    worldService: any,
    enemyService: any,
    townNightSchedule: any,
    phaseService: any,
    featureFlags: any
): TownNightService
    return setmetatable({
        Name = TownNightService.Name,
        _logger = logger,
        _worldService = worldService,
        _enemyService = enemyService,
        _phaseService = phaseService,
        _townNightSchedule = townNightSchedule,
        _daySeconds = config.NormalDaySeconds,
        _duskSeconds = config.DuskSeconds,
        _nightSeconds = config.NormalNightSeconds,
        _blackoutInterval = config.BlackoutInterval,
        _enabled = featureFlags:isEnabled("town_night_cycle_enabled"),
        _nightNumber = 1,
        _phase = "dormant",
        _phaseEndsAt = 0,
        _onChanged = nil,
    }, TownNightService)
end

function TownNightService.Init(_self: TownNightService, _context: any) end

function TownNightService.setChangedHandler(self: TownNightService, callback: (string?) -> ())
    self._onChanged = callback
end

function TownNightService._notify(self: TownNightService, toast: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(toast)
    end
end

local function waitUntilTime(target: number)
    while workspace:GetServerTimeNow() < target do
        task.wait(0.15)
    end
end

-- Disabling this leaves the tutorial's authored First Night, Bramblewake
-- expeditions, and manual Blackout entry untouched — only the repeating town
-- day/dusk/night loop that runs after First Light stops advancing.
function TownNightService.Start(self: TownNightService)
    if not self._enabled then
        self._logger:info("town_night_cycle_disabled")
        return
    end

    task.spawn(function()
        while not self._phaseService:hasCompletedFirstNight() do
            task.wait(0.5)
        end
        self:_runCycle()
    end)
end

function TownNightService._runCycle(self: TownNightService)
    while true do
        self._phase = "day"
        self._phaseEndsAt = workspace:GetServerTimeNow() + self._daySeconds
        self:_notify(nil)
        self._logger:info("town_day_started", { night = self._nightNumber })
        waitUntilTime(self._phaseEndsAt)

        self._phase = "dusk"
        self._phaseEndsAt = workspace:GetServerTimeNow() + self._duskSeconds
        self:_notify(string.format("DUSK FALLS — NIGHT %d APPROACHES", self._nightNumber))
        waitUntilTime(self._phaseEndsAt)

        self._phase = "night"
        local nightStartedAt = workspace:GetServerTimeNow()
        self._phaseEndsAt = nightStartedAt + self._nightSeconds
        self._worldService:setNight(true)
        self._enemyService:startNight()
        local blackoutDue = self:_isBlackoutDue()
        self:_notify(
            if blackoutDue
                then string.format(
                    "NIGHT %d — THE BLACKOUT LOOMS IN BRAMBLEWAKE",
                    self._nightNumber
                )
                else string.format("NIGHT %d HAS ARRIVED", self._nightNumber)
        )
        self._logger:info("town_night_started", {
            blackoutDue = blackoutDue,
            night = self._nightNumber,
        })

        for _, beat in self._townNightSchedule.beats(self._nightSeconds, self._nightNumber) do
            waitUntilTime(nightStartedAt + beat.at)
            if beat.kind == "spawn" then
                self._enemyService:spawn(beat.enemyId)
            elseif beat.kind == "breach" then
                self._enemyService:setBreach()
            elseif beat.kind == "warning" then
                self:_notify("THE FOREST GOES QUIET")
            end
        end

        waitUntilTime(self._phaseEndsAt)
        self._enemyService:stopNight()
        self._worldService:setNight(false)
        self:_notify(string.format("DAWN BREAKS — NIGHT %d SURVIVED", self._nightNumber))
        self._logger:info("town_night_completed", { night = self._nightNumber })
        self._nightNumber += 1
    end
end

function TownNightService._isBlackoutDue(self: TownNightService): boolean
    return self._nightNumber % self._blackoutInterval == 0
end

function TownNightService.isNightActive(self: TownNightService): boolean
    return self._phase == "night"
end

function TownNightService.snapshot(self: TownNightService): any
    return {
        blackoutDue = self:_isBlackoutDue(),
        blackoutInterval = self._blackoutInterval,
        enemyCount = self._enemyService:activeCount(),
        lanternHealth = self._enemyService:lanternHealth(),
        nightActive = self:isNightActive(),
        nightNumber = self._nightNumber,
        phase = self._phase,
        phaseEndsAt = self._phaseEndsAt,
    }
end

return table.freeze(TownNightService)
