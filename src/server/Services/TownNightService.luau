--!strict

local Players = game:GetService("Players")

local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)

local TownNightService = {}
TownNightService.__index = TownNightService
TownNightService.Name = "TownNightService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type TownNightService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _worldService: any,
        _enemyService: any,
        _defenseService: any,
        _defenseLanes: any,
        _townNightSchedule: any,
        _townNightIncident: any,
        _townCondition: any,
        _townPermissions: any,
        _townVisitPolicy: any,
        _hostUserId: number?,
        --[[
            The host's policy, read once when the host is established and kept
            for the life of the server. Deliberately not re-read from the
            host's profile on demand: a host who disconnects mid-session leaves
            their town standing, and a town that opened the moment its founder
            dropped would be a policy that stops meaning anything exactly when
            nobody is there to notice.
        ]]
        _hostPolicy: string,
        --[[
            What each arriving player is to the host -- friend, invited,
            stranger -- resolved once and kept. The role is derived from this
            plus the policy rather than stored, so a host cycling the gate
            re-decides everyone in the server on the same press.
        ]]
        _relations: { [number]: string },
        _pendingContributions: { [number]: any },
        _townGuardLastStand: any,
        _analyticsService: any,
        _condition: any,
        _lastStandState: any,
        _daySeconds: number,
        _duskSeconds: number,
        _nightSeconds: number,
        _blackoutInterval: number,
        _featureFlags: any,
        _started: boolean,
        _nightNumber: number,
        _activeNightNumber: number,
        _phase: string,
        _phaseEndsAt: number,
        _onChanged: ((string?) -> ())?,
        _visitPolicyProvider: ((number) -> string)?,
        _relationResolver: ((number, number, (string) -> ()) -> ())?,
        _onNightCompleted: ((number, number, any) -> ())?,
        _onCycle: ((number, string) -> ())?,
        _incident: any,
        _hold: boolean,
        _skip: boolean,
        _heldSeconds: number,
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
    townVisitPolicy: any,
    townGuardLastStand: any,
    analyticsService: any,
    featureFlags: any
): TownNightService
    return setmetatable({
        Name = TownNightService.Name,
        _logger = logger,
        _worldService = worldService,
        _enemyService = enemyService,
        _defenseService = nil,
        _defenseLanes = nil,
        _townNightSchedule = townNightSchedule,
        _townNightIncident = townNightIncident,
        _townCondition = townCondition,
        _townPermissions = townPermissions,
        _townVisitPolicy = townVisitPolicy,
        _hostUserId = nil,
        _hostPolicy = townVisitPolicy.Default,
        _relations = {},
        _pendingContributions = {},
        _townGuardLastStand = townGuardLastStand,
        _analyticsService = analyticsService,
        _condition = townCondition.default(),
        _lastStandState = townGuardLastStand.default(),
        _daySeconds = config.NormalDaySeconds,
        _duskSeconds = config.DuskSeconds,
        _nightSeconds = config.NormalNightSeconds,
        _blackoutInterval = config.BlackoutInterval,
        _featureFlags = featureFlags,
        _started = false,
        _nightNumber = 1,
        _activeNightNumber = 0,
        _phase = "dormant",
        _phaseEndsAt = 0,
        _onChanged = nil,
        _visitPolicyProvider = nil,
        _relationResolver = nil,
        _onNightCompleted = nil,
        _onCycle = nil,
        _incident = nil,
        _hold = false,
        _skip = false,
        _heldSeconds = 0,
    }, TownNightService)
end

function TownNightService.Init(_self: TownNightService, _context: any) end

function TownNightService.Start(_self: TownNightService) end

function TownNightService.setDefense(self: TownNightService, defenseService: any, defenseLanes: any)
    self._defenseService = defenseService
    self._defenseLanes = defenseLanes
end

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

--[[
    Fires once at the top of each day, before anything about the new cycle
    is built, with the cycle number. Its own slot rather than a second use
    of the night-completed handler, because those are different moments: a
    night completing is a fact about the night that just ended, and a soak
    sample has to be taken at the same point in every cycle including the
    first one, which no night has ended before.
]]
function TownNightService.setCycleObserver(
    self: TownNightService,
    callback: ((number, string) -> ())?
)
    self._onCycle = callback
end

function TownNightService._observeCycle(self: TownNightService, cycle: number, phase: string)
    local callback = self._onCycle
    if callback == nil then
        return
    end
    -- A soak observer that throws must not take the town's clock with it.
    local ok, err = pcall(callback, cycle, phase)
    if not ok then
        self._logger:warn("town_cycle_observer_failed", { cycle = cycle, error = tostring(err) })
    end
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
            Strings.get("toast.n_failed_n_siten_lost_first"),
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
            message = Strings.get("toast.that_night_incident_is_no_longer"),
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
                then Strings.get("toast.that_site_is_already_secure")
                else Strings.get("toast.the_incident_window_has_closed"),
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
            Strings.get("toast.n_secured_n_siten_remain"),
            string.upper(tostring(result.siteId)),
            result.remaining,
            if result.remaining == 1 then "" else "S"
        ),
        reason = "site_resolved",
    }
end

--[[
    A held clock stops rather than stretches.

    Every wait in the cycle pushes its own deadline forward by exactly the time
    that passed while the hold was on, so releasing it leaves the phase with
    the seconds it had left rather than with a number somebody guessed. The
    same push lands on the night's beat offsets through `_heldSeconds`, because
    a night whose clock stopped and whose waves did not would spend its hold
    quietly emptying the schedule.

    Both of these only exist in a practice server -- `PrivateServerService` is
    the only caller and it has already latched the profile writes off by the
    time it calls either.
]]
local function pushHold(self: TownNightService, since: number)
    local delta = workspace:GetServerTimeNow() - since
    self._phaseEndsAt += delta
    self._heldSeconds += delta
end

function TownNightService._waitForPhaseEnd(self: TownNightService)
    while true do
        if self._skip then
            self._skip = false
            return
        end
        local now = workspace:GetServerTimeNow()
        if not self._hold and now >= self._phaseEndsAt then
            return
        end
        task.wait(0.15)
        if self._hold then
            pushHold(self, now)
        end
    end
end

-- Returns whether the phase was called on rather than the beat arriving. The
-- flag is peeked rather than consumed, because the loop that breaks on it is
-- not the wait that ends the phase.
function TownNightService._waitForBeat(self: TownNightService, target: number): boolean
    while not self._skip do
        local now = workspace:GetServerTimeNow()
        if not self._hold and now >= target + self._heldSeconds then
            return false
        end
        task.wait(0.15)
        if self._hold then
            pushHold(self, now)
        end
    end
    return true
end

function TownNightService.setHold(self: TownNightService, held: boolean)
    self._hold = held == true
end

function TownNightService.isHeld(self: TownNightService): boolean
    return self._hold
end

-- End the phase now. Refused while the cycle is dormant, because there is no
-- phase to end and a skip banked against a clock that has not started would
-- fire at whatever the first wait turned out to be.
function TownNightService.stepPhase(self: TownNightService): boolean
    if self._phase == "dormant" then
        return false
    end
    self._skip = true
    return true
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
        local provider = self._visitPolicyProvider
        if provider ~= nil then
            self._hostPolicy = self._townVisitPolicy.normalize(provider(actorUserId))
        end
        self._logger:info("town_host_established", {
            host = actorUserId,
            policy = self._hostPolicy,
        })
    end

    if condition ~= nil and actorUserId ~= nil then
        self:_considerContribution(actorUserId, condition)
    end
    --[[
        Read here rather than kept from construction.

        This is the town cycle's kill switch, and a kill switch you have to
        restart every server to use is not one you would reach for during an
        incident -- which is the only moment it exists for. Read at the door a
        new cycle comes through, turning it off stops the next night on every
        server that is already running, and leaves the one in progress alone.
        That is the correct half to stop: a night that vanishes underneath the
        people fighting it is a worse outage than the one being rolled back.

        The soak wave paid for the same lesson from the other side (#344): a
        switch read once at boot could never be turned on in the only place
        anybody drives it, and nothing failed while it could not.
    ]]
    if not self._featureFlags:isEnabled("town_night_cycle_enabled") or self._started then
        return
    end
    self._started = true
    task.spawn(function()
        self:_runCycle()
    end)
end

--[[
    Take an arriving player's town record, or do not.

    The host's own record is applied immediately -- it is their town, and their
    nights are what damaged it. Everyone else has to be decided, and deciding
    needs an answer the platform gives asynchronously (friendship), so the
    record is held until the answer lands rather than applied on a guess.

    Holding rather than guessing is the whole point. A guess in the admitting
    direction is a closed town adopting one stranger's record before the gate
    can speak, which is exactly the bypass this wave exists to make impossible;
    a guess in the refusing direction would drop a legitimate visitor's
    contribution for good. A record that is never decided is simply never
    applied, and an unapplied upward-only contribution costs a town nothing.
]]
function TownNightService._considerContribution(
    self: TownNightService,
    actorUserId: number,
    condition: any
)
    if actorUserId == self._hostUserId then
        self:_applyContribution(actorUserId, condition)
        return
    end
    if self._relations[actorUserId] ~= nil then
        self:_applyContribution(actorUserId, condition)
        return
    end
    self._pendingContributions[actorUserId] = condition
    local resolver = self._relationResolver
    if resolver == nil then
        -- No resolver wired: every arrival is the plain visitor the town has
        -- always had, which is upward-only and cannot hurt anything. The
        -- policy is a narrowing of that, never a widening of it.
        self._relations[actorUserId] = "stranger"
        self._hostPolicy = "open"
        self:_applyContribution(actorUserId, condition)
        return
    end
    resolver(actorUserId, self._hostUserId or actorUserId, function(relation: string)
        self._relations[actorUserId] = relation
        local held = self._pendingContributions[actorUserId]
        if held ~= nil then
            self:_applyContribution(actorUserId, held)
        end
    end)
end

-- SAFETY-CHANNEL: town_visit_adoption -- the only path by which one player's
-- saved town can reach another player's town, and the only place a visit
-- policy can refuse it.
function TownNightService._applyContribution(
    self: TownNightService,
    actorUserId: number,
    condition: any
)
    self._pendingContributions[actorUserId] = nil
    local role = self:roleFor(actorUserId)
    if role == "outsider" then
        self._logger:info("town_visit_refused", {
            actor = actorUserId,
            host = self._hostUserId,
            policy = self._hostPolicy,
            relation = self._relations[actorUserId],
        })
        return
    end
    self._condition = self._townPermissions.resolveCondition(
        self._condition,
        condition,
        -- An outsider never reaches here, so TownPermissions still sees the
        -- two roles it was written for and its invariant is unchanged.
        if role == "host" then "host" else "visitor",
        self._townCondition.merge,
        self._townCondition.averageIntegrity
    )
    self._worldService:setTownCondition(self:conditionSnapshot())
end

--[[
    What a player is in this town: host, visitor, outsider, or pending.

    Pending is a real answer rather than a placeholder. Until the platform has
    said whether these two people are friends, the honest thing to report is
    that it does not know yet -- and because the showcase is attached to the
    role, pending shows nothing, so an unresolved arrival cannot read a closed
    town's record in the window before the gate speaks.
]]
function TownNightService.roleFor(self: TownNightService, actorUserId: number?): string
    local hostUserId = self._hostUserId
    if hostUserId == nil or actorUserId == nil then
        return "pending"
    end
    if actorUserId == hostUserId then
        return "host"
    end
    local relation = self._relations[actorUserId]
    if relation == nil then
        return "pending"
    end
    return self._townVisitPolicy.roleFor(self._hostPolicy, relation)
end

function TownNightService.setVisitPolicyProvider(
    self: TownNightService,
    provider: (number) -> string
)
    self._visitPolicyProvider = provider
end

function TownNightService.setRelationResolver(
    self: TownNightService,
    resolver: (number, number, (string) -> ()) -> ()
)
    self._relationResolver = resolver
end

--[[
    The host changed their mind at the gate.

    Every already-resolved relation is re-decided by the next `roleFor`, so a
    town that closes stops showing its record to the people standing in it
    immediately rather than at their next join. Contributions already adopted
    stay adopted: closing a gate is not a way to take back what somebody
    already helped build.
]]
function TownNightService.setHostPolicy(self: TownNightService, actorUserId: number, policy: string)
    if self._hostUserId == nil or actorUserId ~= self._hostUserId then
        return false
    end
    self._hostPolicy = self._townVisitPolicy.normalize(policy)
    return true
end

function TownNightService.hostPolicy(self: TownNightService): string
    return self._hostPolicy
end

-- Which night this town is on, for the showcase. The active night when one is
-- running, so a visitor reading the record mid-night sees the night they are
-- standing in rather than the one after it.
function TownNightService.nightNumber(self: TownNightService): number
    return if self._activeNightNumber > 0 then self._activeNightNumber else self._nightNumber
end

function TownNightService._runCycle(self: TownNightService)
    local cycle = 0
    while true do
        cycle += 1
        self._phase = "day"
        self._activeNightNumber = 0
        self._phaseEndsAt = workspace:GetServerTimeNow() + self._daySeconds
        self._heldSeconds = 0
        self._worldService:setDusk(false)
        self._worldService:setTownRepairEnabled(true)
        self:_notify(nil)
        self._logger:info("town_day_started", { night = self._nightNumber })
        -- Sampled here, at the top of the day, because a soak reading is
        -- only comparable to one taken at the same point in every cycle
        -- and this is the only moment the world is quiet in all of them.
        self:_observeCycle(cycle, "day")
        self:_waitForPhaseEnd()

        self._phase = "dusk"
        self._phaseEndsAt = workspace:GetServerTimeNow() + self._duskSeconds
        self._heldSeconds = 0
        self._worldService:setDusk(true)
        self._worldService:setTownRepairEnabled(false)
        self:_notify(
            string.format(
                Strings.get("toast.dusk_falls_n_night_n_approaches"),
                self._townNightSchedule.displayName(
                    self._townNightSchedule.theme(self._nightNumber)
                ),
                self._nightNumber
            )
        )
        self:_waitForPhaseEnd()

        self._phase = "night"
        self._incident = nil
        local nightStartedAt = workspace:GetServerTimeNow()
        self._phaseEndsAt = nightStartedAt + self._nightSeconds
        self._heldSeconds = 0
        -- Frozen for the rest of this night: a higher number from a veteran
        -- who joins mid-night (ensureStarted always raises self._nightNumber
        -- to the max seen) must not retroactively change the wave schedule,
        -- toasts, or completion bookkeeping already committed to for this
        -- specific night — only self._nightNumber (read again below, after
        -- this night ends) picks it up, for the *next* night onward.
        local activeNight = self._nightNumber
        self._activeNightNumber = activeNight
        local blackoutDue = self:_isBlackoutDue(activeNight)
        -- The id goes to the world, which builds this night's dressing from
        -- it; the name goes into the sentence. They were one string until this
        -- wave, and that string could only ever be right in one language.
        local theme = self._townNightSchedule.theme(activeNight)
        local themeName = self._townNightSchedule.displayName(theme)
        local themeProfile = self._townNightSchedule.profile(activeNight)
        self._worldService:setNight(true, theme)
        self._enemyService:startNight(themeProfile)
        self:_notify(
            if blackoutDue
                then string.format(
                    Strings.get("toast.n_night_n_the_blackout_looms"),
                    themeName,
                    activeNight
                )
                else string.format(
                    Strings.get("toast.n_night_n_n"),
                    themeName,
                    activeNight,
                    themeProfile.instruction
                )
        )
        --[[
            The director's census: defenders who are actually in this fight
            -- past First Light's survival gate and standing in the town, not
            off in Bramblewake. Counted once at nightfall so the night's
            layout stays deterministic even as players come and go; a defender
            who leaves mid-night thins the line, not the schedule.
        ]]
        local partySize = 0
        for _, player in Players:GetPlayers() do
            if
                player:GetAttribute("LastLightTutorialSurvivalReady") == true
                and player:GetAttribute("LastLightInExpedition") ~= true
            then
                partySize += 1
            end
        end
        partySize = math.max(partySize, 1)
        self._logger:info("town_night_started", {
            blackoutDue = blackoutDue,
            night = activeNight,
            partySize = partySize,
            waves = self._townNightSchedule.waveCount(activeNight, partySize),
        })
        if self._defenseService ~= nil then
            self._defenseService:onNightStarted(partySize)
        end

        for _, beat in self._townNightSchedule.beats(self._nightSeconds, activeNight, partySize) do
            if self:_waitForBeat(nightStartedAt + beat.at) then
                -- The phase was called on early. The beats left in this night
                -- are dropped rather than run at once: a skip that fired six
                -- queued waves the instant it was pressed would be a control
                -- that made the night harder, and every control here is
                -- supposed to make it optional.
                break
            end
            if beat.kind == "spawn" then
                self._worldService:signalNightWave(beat.enemyId, beat.wave, theme)
                local laneId = if self._defenseLanes ~= nil
                    then self._defenseLanes.laneForWave(activeNight, beat.wave).id
                    else nil
                self._enemyService:spawn(beat.enemyId, laneId)
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
                self:_notify(Strings.get("toast.the_forest_goes_quiet"))
            end
        end

        self:_waitForPhaseEnd()
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
        if self._defenseService ~= nil then
            self._defenseService:onNightEnded()
        end
        self._activeNightNumber = 0
        self._worldService:setTownBreach(false, theme)
        self._worldService:setNight(false)
        local conditionSnapshot = self:conditionSnapshot()
        self._worldService:setTownCondition(conditionSnapshot)
        local damage = tonumber(damageResult.damage) or 0
        local dawnToast = if damage > 0
            then string.format(
                Strings.get("toast.dawn_breaks_town_integrity_n_n"),
                conditionSnapshot.integrity,
                conditionSnapshot.repairsRemaining,
                if conditionSnapshot.repairsRemaining == 1 then "" else "S"
            )
            elseif conditionSnapshot.repairsRemaining > 0 then string.format(
                Strings.get("toast.dawn_breaks_night_n_held_clean"),
                activeNight,
                conditionSnapshot.integrity
            )
            else string.format(
                Strings.get("toast.dawn_breaks_night_n_held_clean_2"),
                activeNight
            )
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

--[[
    Whose town this server is, and what the asking player is in it. The
    deliberate half of the visit flow: the role has always been enforced,
    but nobody was ever told which side of it they stood on.
]]
function TownNightService.hostInfo(self: TownNightService, actorUserId: number?): any
    local hostUserId = self._hostUserId
    if hostUserId == nil then
        return nil
    end
    return {
        hostUserId = hostUserId,
        role = self:roleFor(actorUserId),
        policy = self._hostPolicy,
    }
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

-- Its name, because every caller of this puts it in a sentence.
function TownNightService.themeForNight(self: TownNightService, nightNumber: number): string
    return self._townNightSchedule.displayName(self._townNightSchedule.theme(nightNumber))
end

function TownNightService.repairTown(self: TownNightService, buildingId: any): any
    if self._phase ~= "day" then
        return {
            accepted = false,
            message = Strings.get("toast.town_repairs_wait_for_daylight"),
            reason = "not_day",
        }
    end
    local nextCondition, result = self._townCondition.repair(self._condition, buildingId)
    if not result.applied then
        local message = if result.reason == "unknown_building"
            then Strings.get("toast.there_is_nothing_to_repair_here")
            else Strings.get("toast.this_building_is_already_repaired")
        return { accepted = false, message = message, reason = result.reason }
    end
    self._condition = nextCondition
    self._worldService:setTownCondition(self:conditionSnapshot())
    local snapshot = self:conditionSnapshot()
    return {
        accepted = true,
        condition = snapshot,
        message = string.format(
            Strings.get("toast.repaired_n_n_n_left_in"),
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

--[[
    Whether this clock is the one that is running.

    "dormant" is the phase before ensureStarted, and it is also what the
    service reports when the kill switch is off, so a caller choosing between
    the tutorial's clock and this one can tell whether there is a town cycle to
    read at all rather than guessing from the player's stage.
]]
function TownNightService.isRunning(self: TownNightService): boolean
    return self._phase ~= "dormant"
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
        theme = self._townNightSchedule.displayName(
            self._townNightSchedule.theme(self._nightNumber)
        ),
        phase = self._phase,
        phaseEndsAt = self._phaseEndsAt,
        --[[
            A held clock needs both of these, and the live pass is why.

            The HUD counts down locally between pushes -- ten times a second,
            off its own copy of `phaseEndsAt` -- so a hold that only moves the
            deadline on the server leaves the pill running on through a clock
            that has stopped. Pressed once and watched: the server sat at
            543.8 seconds left for six seconds while the pill went 08:38 to
            08:32. Every spec passed. The seconds are therefore measured here,
            where the clock actually is, and the flag tells the client to show
            that number rather than derive one.
        ]]
        phaseHeld = self._hold,
        phaseRemaining = math.max(0, self._phaseEndsAt - workspace:GetServerTimeNow()),
        incident = self._townNightIncident.snapshot(self._incident),
    }
end

return table.freeze(TownNightService)
