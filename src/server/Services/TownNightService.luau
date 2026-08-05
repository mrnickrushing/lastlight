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
        _townNightIncident: any,
        _townCondition: any,
        _townPermissions: any,
        _hostUserId: number?,
        _townGuardLastStand: any,
        _analyticsService: any,
        _condition: any,
        _lastStandState: any,
        _daySeconds: number,
        _duskSeconds: number,
        _nightSeconds: number,
        _blackoutInterval: number,
        _enabled: boolean,
        _started: boolean,
        _nightNumber: number,
        _activeNightNumber: number,
        _phase: string,
        _phaseEndsAt: number,
        _onChanged: ((string?) -> ())?,
        _onNightCompleted: ((number, number, any) -> ())?,
        _incident: any,
    },
    TownNightService
))

function TownNightService.new(
    logger: Logger,
    config: any,
    worldService: any,
    enemyService: any,
    townNightSchedule: any,
    townNightIncident: any,
    townCondition: any,
    townPermissions: any,
    townGuardLastStand: any,
    analyticsService: any,
    featureFlags: any
): TownNightService
    return setmetatable({
        Name = TownNightService.Name,
        _logger = logger,
        _worldService = worldService,
        _enemyService = enemyService,
        _townNightSchedule = townNightSchedule,
        _townNightIncident = townNightIncident,
        _townCondition = townCondition,
        _townPermissions = townPermissions,
        _hostUserId = nil,
        _townGuardLastStand = townGuardLastStand,
        _analyticsService = analyticsService,
        _condition = townCondition.default(),
        _lastStandState = townGuardLastStand.default(),
        _daySeconds = config.NormalDaySeconds,
        _duskSeconds = config.DuskSeconds,
        _nightSeconds = config.NormalNightSeconds,
        _blackoutInterval = config.BlackoutInterval,
        _enabled = featureFlags:isEnabled("town_night_cycle_enabled"),
        _started = false,
        _nightNumber = 1,
        _activeNightNumber = 0,
        _phase = "dormant",
        _phaseEndsAt = 0,
        _onChanged = nil,
        _onNightCompleted = nil,
        _incident = nil,
    }, TownNightService)
end

function TownNightService.Init(_self: TownNightService, _context: any) end

function TownNightService.Start(_self: TownNightService) end

function TownNightService.setChangedHandler(self: TownNightService, callback: (string?) -> ())
    self._onChanged = callback
end

-- Fires once per completed night with the next night number every connected
-- profile should record, the ending lantern health, and the reconciled town
-- condition. Persistence stays owned by whoever is holding each profile.
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

function TownNightService._expireIncident(
    self: TownNightService,
    nightNumber: number,
    incidentId: string
)
    local incident = self._incident
    if
        incident == nil
        or incident.nightNumber ~= nightNumber
        or incident.definition.id ~= incidentId
        or incident.status ~= "active"
    then
        return
    end
    local nextIncident, result =
        self._townNightIncident.expire(incident, workspace:GetServerTimeNow())
    if not result.applied then
        return
    end
    self._incident = nextIncident
    self._worldService:clearTownIncident()
    local pressure =
        self._enemyService:applyLanternPressure(result.lanternPenalty, incident.definition.id)
    self:_notify(
        string.format(
            "%s FAILED — %d SITE%s LOST · FIRST LANTERN -%d",
            incident.definition.title,
            result.unresolved,
            if result.unresolved == 1 then "" else "S",
            pressure.damage or 0
        )
    )
    self._logger:info("town_incident_failed", {
        damage = pressure.damage or 0,
        incident = incident.definition.id,
        night = nightNumber,
        unresolved = result.unresolved,
    })
end

function TownNightService._startIncident(self: TownNightService, nightNumber: number, theme: string)
    self._worldService:clearTownIncident()
    local now = workspace:GetServerTimeNow()
    local incident = self._townNightIncident.create(theme, nightNumber, now)
    self._incident = incident
    self._worldService:startTownIncident(incident.definition, incident.endsAt)
    self:_notify(incident.definition.title .. " — " .. incident.definition.instruction)
    self._logger:info("town_incident_started", {
        incident = incident.definition.id,
        night = nightNumber,
        required = #incident.definition.sites,
    })
    task.delay(incident.definition.duration + 0.05, function()
        self:_expireIncident(nightNumber, incident.definition.id)
    end)
end

function TownNightService.resolveIncident(
    self: TownNightService,
    player: Player,
    prompt: ProximityPrompt
): any
    local incident = self._incident
    if self._phase ~= "night" or incident == nil or incident.status ~= "active" then
        return {
            accepted = false,
            message = "THAT NIGHT INCIDENT IS NO LONGER ACTIVE",
            reason = "incident_inactive",
        }
    end
    local siteId = prompt:GetAttribute("Payload")
    local nextIncident, result =
        self._townNightIncident.interact(incident, siteId, workspace:GetServerTimeNow())
    if not result.accepted then
        if result.reason == "incident_expired" then
            self:_expireIncident(incident.nightNumber, incident.definition.id)
        end
        return {
            accepted = false,
            message = if result.reason == "site_resolved"
                then "THAT SITE IS ALREADY SECURE"
                else "THE INCIDENT WINDOW HAS CLOSED",
            reason = result.reason,
        }
    end

    self._incident = nextIncident
    self._worldService:resolveTownIncidentSite(result.siteId, nextIncident.resolvedCount)
    self._logger:info("town_incident_site_resolved", {
        incident = incident.definition.id,
        player = player.UserId,
        remaining = result.remaining,
        site = result.siteId,
    })
    if result.completed then
        self:_notify(incident.definition.title .. " SECURED — THE WATCH HOLDS")
        task.delay(1.5, function()
            if self._incident == nextIncident then
                self._worldService:clearTownIncident()
            end
        end)
        return {
            accepted = true,
            completed = true,
            message = incident.definition.title .. " SECURED",
            reason = "incident_complete",
        }
    end
    return {
        accepted = true,
        completed = false,
        message = string.format(
            "%s SECURED — %d SITE%s REMAIN",
            string.upper(tostring(result.siteId)),
            result.remaining,
            if result.remaining == 1 then "" else "S"
        ),
        reason = "site_resolved",
    }
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
    condition: any?,
    actorUserId: number?
)
    self._nightNumber = math.max(self._nightNumber, math.floor(nightNumber))

    -- The first player to establish this server's town owns it. Everyone after
    -- them is visiting, and a visit may improve the town or leave it alone --
    -- never break it. Without this a player arriving from a later, wrecked town
    -- replaced an intact one outright, because condition resolves on night
    -- number before it looks at integrity.
    if self._hostUserId == nil and actorUserId ~= nil then
        self._hostUserId = actorUserId
    end

    if condition ~= nil then
        local role = self._townPermissions.roleFor(actorUserId, self._hostUserId)
        self._condition = self._townPermissions.resolveCondition(
            self._condition,
            condition,
            role,
            self._townCondition.merge,
            self._townCondition.averageIntegrity
        )
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
        self._activeNightNumber = 0
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
        self._incident = nil
        local nightStartedAt = workspace:GetServerTimeNow()
        self._phaseEndsAt = nightStartedAt + self._nightSeconds
        -- Frozen for the rest of this night: a higher number from a veteran
        -- who joins mid-night (ensureStarted always raises self._nightNumber
        -- to the max seen) must not retroactively change the wave schedule,
        -- toasts, or completion bookkeeping already committed to for this
        -- specific night — only self._nightNumber (read again below, after
        -- this night ends) picks it up, for the *next* night onward.
        local activeNight = self._nightNumber
        self._activeNightNumber = activeNight
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
            elseif beat.kind == "incident" then
                self:_startIncident(activeNight, theme)
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
        local endingIncident = self._incident
        if endingIncident ~= nil and endingIncident.status == "active" then
            self:_expireIncident(activeNight, endingIncident.definition.id)
        end
        self._worldService:clearTownIncident()
        local endingLanternHealth = self._enemyService:lanternHealth()
        -- What physically stands to be broken. A building still at stage zero
        -- is a construction site, and damaging one would mean repairing
        -- something nobody has built yet.
        local damageable = self._worldService:damageableBuildingIds()
        local nextCondition, damageResult = self._townCondition.afterNight(
            self._condition,
            endingLanternHealth,
            activeNight,
            damageable
        )
        self._condition = nextCondition
        self._enemyService:stopNight()
        self._activeNightNumber = 0
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
            elseif conditionSnapshot.repairsRemaining > 0 then string.format(
                "DAWN BREAKS — NIGHT %d HELD CLEAN · TOWN INTEGRITY %d%%",
                activeNight,
                conditionSnapshot.integrity
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
    -- Scoped to what physically stands, so a migrated profile that marks every
    -- building damaged cannot present repair work on an empty construction lot.
    return self._townCondition.snapshot(self._condition, self._worldService:damageableBuildingIds())
end

function TownNightService.attemptLastStand(
    self: TownNightService,
    eligiblePlayers: number,
    downedPlayers: number
): any
    local activeNight = if self._activeNightNumber > 0
        then self._activeNightNumber
        else self._nightNumber
    local nextState, result = self._townGuardLastStand.attempt(self._lastStandState, {
        phase = self._phase,
        nightNumber = activeNight,
        lanternHealth = self._enemyService:lanternHealth(),
        eligiblePlayers = eligiblePlayers,
        downedPlayers = downedPlayers,
    })
    self._lastStandState = nextState
    if not result.accepted then
        self._analyticsService:townGuardLastStand(
            false,
            result.reason,
            eligiblePlayers,
            activeNight,
            self._enemyService:lanternHealth()
        )
        return result
    end

    local lantern =
        self._enemyService:spendLanternStrength(result.lanternCost, "town_guard_last_stand")
    result.lanternHealth = lantern.health
    result.lanternSpent = lantern.spent
    self._analyticsService:townGuardLastStand(
        true,
        result.reason,
        eligiblePlayers,
        activeNight,
        lantern.health
    )
    self._logger:info("town_guard_last_stand", {
        lanternHealth = lantern.health,
        night = activeNight,
        partySize = eligiblePlayers,
    })
    return result
end

--[[
    Repair one named building.

    `buildingId` comes from the repair prompt's own Payload attribute, baked in
    at world build time -- the same one-object-one-outcome route the crafting
    benches use. The client sends the generic interaction ID and never names a
    building, so a forged payload cannot repair something that was not there.
]]
--[[
    Tomas's dawn boon: one free repair point on the worst-hit standing
    building. Reuses the same condition transaction as a player repair, so
    it can never restore more than a hammer swing would.
]]
function TownNightService.residentRepair(self: TownNightService): any?
    local snapshot = self:conditionSnapshot()
    local worst = nil
    for _, entry in snapshot.damaged or {} do
        if worst == nil or entry.integrity < worst.integrity then
            worst = entry
        end
    end
    if worst == nil then
        return nil
    end
    local nextCondition, result = self._townCondition.repair(self._condition, worst.buildingId)
    if not result.applied then
        return nil
    end
    self._condition = nextCondition
    self._worldService:setTownCondition(self:conditionSnapshot())
    return { buildingId = worst.buildingId, restored = result.restored }
end

function TownNightService.themeForNight(self: TownNightService, nightNumber: number): string
    return tostring(self._townNightSchedule.theme(nightNumber))
end

function TownNightService.repairTown(self: TownNightService, buildingId: any): any
    if self._phase ~= "day" then
        return { accepted = false, message = "TOWN REPAIRS WAIT FOR DAYLIGHT", reason = "not_day" }
    end
    local nextCondition, result = self._townCondition.repair(self._condition, buildingId)
    if not result.applied then
        local message = if result.reason == "unknown_building"
            then "THERE IS NOTHING TO REPAIR HERE"
            else "THIS BUILDING IS ALREADY REPAIRED"
        return { accepted = false, message = message, reason = result.reason }
    end
    self._condition = nextCondition
    self._worldService:setTownCondition(self:conditionSnapshot())
    local snapshot = self:conditionSnapshot()
    return {
        accepted = true,
        condition = snapshot,
        message = string.format(
            "REPAIRED +%d · %d%% · %d LEFT IN TOWN",
            result.restored,
            result.buildingIntegrity,
            snapshot.repairsRemaining
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
        incident = self._townNightIncident.snapshot(self._incident),
    }
end

return table.freeze(TownNightService)
