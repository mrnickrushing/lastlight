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
        _townNightSchedule: any,
        _townCondition: any,
        _condition: any,
        _daySeconds: number,
        _duskSeconds: number,
        _nightSeconds: number,
        _blackoutInterval: number,
        _enabled: boolean,
        _started: boolean,
        _nightNumber: number,
        _phase: string,
        _phaseEndsAt: number,
        _onChanged: ((string?) -> ())?,
        _onNightCompleted: ((number, number, any) -> ())?,
    },
    TownNightService
))

function TownNightService.new(
    logger: Logger,
    config: any,
    worldService: any,
    enemyService: any,
    townNightSchedule: any,
    townCondition: any,
    featureFlags: any
): TownNightService
    return setmetatable({
        Name = TownNightService.Name,
        _logger = logger,
        _worldService = worldService,
        _enemyService = enemyService,
        _townNightSchedule = townNightSchedule,
        _townCondition = townCondition,
        _condition = townCondition.default(),
        _daySeconds = config.NormalDaySeconds,
        _duskSeconds = config.DuskSeconds,
        _nightSeconds = config.NormalNightSeconds,
        _blackoutInterval = config.BlackoutInterval,
        _enabled = featureFlags:isEnabled("town_night_cycle_enabled"),
        _started = false,
        _nightNumber = 1,
        _phase = "dormant",
        _phaseEndsAt = 0,
        _onChanged = nil,
        _onNightCompleted = nil,
    }, TownNightService)
end

function TownNightService.Init(_self: TownNightService, _context: any) end

function TownNightService.Start(_self: TownNightService) end

function TownNightService.setChangedHandler(self: TownNightService, callback: (string?) -> ())
    self._onChanged = callback
end

-- Fires once per completed night with the night number that just finished
-- (i.e. the value every connected player's profile should now record), so
-- persistence stays owned by whoever is holding the profile, not this loop.
function TownNightService.setNightCompletedHandler(
    self: TownNightService,
    callback: (number, number, any) -> ()
)
    self._onNightCompleted = callback
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

-- Called once for every player in this server session known to be past
-- First Light — either a fresh player who just finished it, or a returning
-- player whose saved profile already had it complete. `nightNumber` is that
-- player's own persisted record; the town resumes from the highest one seen
-- rather than always restarting at night one, so nobody's progress from a
-- prior session is understated. Safe to call repeatedly and from either
-- path: only the first call actually starts the loop, but every call still
-- raises the count if the caller's record is higher (this only affects
-- nights that haven't started their wave schedule yet — see _runCycle).
-- Disabling the kill switch leaves the tutorial's authored First Night,
-- Bramblewake expeditions, and manual Blackout entry untouched — only this
-- repeating town day/dusk/night loop stops advancing.
function TownNightService.ensureStarted(
    self: TownNightService,
    nightNumber: number,
    condition: any?
)
    self._nightNumber = math.max(self._nightNumber, math.floor(nightNumber))
    if condition ~= nil then
        self._condition = self._townCondition.merge(self._condition, condition)
        self._worldService:setTownCondition(self:conditionSnapshot())
    end
    if not self._enabled or self._started then
        return
    end
    self._started = true
    task.spawn(function()
        self:_runCycle()
    end)
end

function TownNightService._runCycle(self: TownNightService)
    while true do
        self._phase = "day"
        self._phaseEndsAt = workspace:GetServerTimeNow() + self._daySeconds
        self._worldService:setDusk(false)
        self._worldService:setTownRepairEnabled(true)
        self:_notify(nil)
        self._logger:info("town_day_started", { night = self._nightNumber })
        waitUntilTime(self._phaseEndsAt)

        self._phase = "dusk"
        self._phaseEndsAt = workspace:GetServerTimeNow() + self._duskSeconds
        self._worldService:setDusk(true)
        self._worldService:setTownRepairEnabled(false)
        self:_notify(
            string.format(
                "DUSK FALLS — %s NIGHT %d APPROACHES",
                self._townNightSchedule.theme(self._nightNumber),
                self._nightNumber
            )
        )
        waitUntilTime(self._phaseEndsAt)

        self._phase = "night"
        local nightStartedAt = workspace:GetServerTimeNow()
        self._phaseEndsAt = nightStartedAt + self._nightSeconds
        -- Frozen for the rest of this night: a higher number from a veteran
        -- who joins mid-night (ensureStarted always raises self._nightNumber
        -- to the max seen) must not retroactively change the wave schedule,
        -- toasts, or completion bookkeeping already committed to for this
        -- specific night — only self._nightNumber (read again below, after
        -- this night ends) picks it up, for the *next* night onward.
        local activeNight = self._nightNumber
        local blackoutDue = self:_isBlackoutDue(activeNight)
        local theme = self._townNightSchedule.theme(activeNight)
        local themeProfile = self._townNightSchedule.profile(activeNight)
        self._worldService:setNight(true, theme)
        self._enemyService:startNight(themeProfile)
        self:_notify(
            if blackoutDue
                then string.format(
                    "%s NIGHT %d — THE BLACKOUT LOOMS IN BRAMBLEWAKE",
                    theme,
                    activeNight
                )
                else string.format(
                    "%s NIGHT %d — %s",
                    theme,
                    activeNight,
                    themeProfile.instruction
                )
        )
        self._logger:info("town_night_started", {
            blackoutDue = blackoutDue,
            night = activeNight,
        })

        for _, beat in self._townNightSchedule.beats(self._nightSeconds, activeNight) do
            waitUntilTime(nightStartedAt + beat.at)
            if beat.kind == "spawn" then
                self._worldService:signalNightWave(beat.enemyId, beat.wave, theme)
                self._enemyService:spawn(beat.enemyId)
            elseif beat.kind == "breach" then
                self._worldService:setTownBreach(true, theme)
                self._enemyService:setBreach()
            elseif beat.kind == "warning" and beat.at > 0 then
                -- The schedule's opening warning beat always lands at at=0,
                -- immediately after the arrival toast above (which already
                -- carries the seventh-night Blackout telegraph on the nights
                -- that matter) — publishing it too would replace that toast
                -- before a player could read it.
                self:_notify("THE FOREST GOES QUIET")
            end
        end

        waitUntilTime(self._phaseEndsAt)
        local endingLanternHealth = self._enemyService:lanternHealth()
        local nextCondition, damageResult =
            self._townCondition.afterNight(self._condition, endingLanternHealth, activeNight)
        self._condition = nextCondition
        self._enemyService:stopNight()
        self._worldService:setTownBreach(false, theme)
        self._worldService:setNight(false)
        local conditionSnapshot = self:conditionSnapshot()
        self._worldService:setTownCondition(conditionSnapshot)
        local damage = tonumber(damageResult.damage) or 0
        local dawnToast = if damage > 0
            then string.format(
                "DAWN BREAKS — TOWN INTEGRITY %d%% · %d REPAIR%s NEEDED",
                conditionSnapshot.integrity,
                conditionSnapshot.repairsRemaining,
                if conditionSnapshot.repairsRemaining == 1 then "" else "S"
            )
            else string.format("DAWN BREAKS — NIGHT %d HELD CLEAN", activeNight)
        self:_notify(dawnToast)
        self._logger:info("town_night_completed", {
            damage = damage,
            endingLanternHealth = endingLanternHealth,
            integrity = conditionSnapshot.integrity,
            night = activeNight,
        })
        -- Adopt whichever is higher: the honest next night after the one
        -- that just actually ran, or a veteran's still-pending higher seed
        -- from ensureStarted. Either way this can only advance.
        self._nightNumber = math.max(self._nightNumber, activeNight + 1)
        local onNightCompleted = self._onNightCompleted
        if onNightCompleted ~= nil then
            onNightCompleted(activeNight + 1, endingLanternHealth, self:conditionSnapshot())
        end
        task.wait(0)
    end
end

function TownNightService.conditionSnapshot(self: TownNightService): any
    return self._townCondition.snapshot(self._condition)
end

function TownNightService.repairTown(self: TownNightService): any
    if self._phase ~= "day" then
        return { accepted = false, message = "TOWN REPAIRS WAIT FOR DAYLIGHT", reason = "not_day" }
    end
    local nextCondition, result = self._townCondition.repair(self._condition)
    if not result.applied then
        return {
            accepted = false,
            message = "EMBERHOLLOW IS ALREADY FULLY REPAIRED",
            reason = result.reason,
        }
    end
    self._condition = nextCondition
    self._worldService:setTownCondition(self:conditionSnapshot())
    local snapshot = self:conditionSnapshot()
    return {
        accepted = true,
        condition = snapshot,
        message = string.format(
            "TOWN REPAIR +%d · INTEGRITY %d%%",
            result.restored,
            snapshot.integrity
        ),
        reason = result.reason,
    }
end

function TownNightService._isBlackoutDue(self: TownNightService, nightNumber: number?): boolean
    return (nightNumber or self._nightNumber) % self._blackoutInterval == 0
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
        townCondition = self:conditionSnapshot(),
        nightActive = self:isNightActive(),
        nightNumber = self._nightNumber,
        theme = self._townNightSchedule.theme(self._nightNumber),
        phase = self._phase,
        phaseEndsAt = self._phaseEndsAt,
    }
end

return table.freeze(TownNightService)
