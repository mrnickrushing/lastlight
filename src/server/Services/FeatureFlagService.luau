--!strict

--[[
    The switches, and who each one has reached.

    Two questions live here and they are not the same one. "Is this feature
    built and turned on" is global and has been since Milestone 1. "Has this
    feature reached this player" is Milestone 13's staged rollout, and it has
    no global answer at all -- which is why a cohort-scoped flag read without
    a player throws rather than defaulting. `RolloutCohorts` explains why both
    defaults are wrong; the short version is that one of them ships an
    unreleased feature to everybody and the other hides it from the only
    people it was turned on for, and neither says anything on the way past.

    A local override still wins over both, because an override is a developer
    holding the switch by hand in an environment where that is allowed, and it
    is refused outright in production.
]]

local FeatureFlagService = {}
FeatureFlagService.__index = FeatureFlagService
FeatureFlagService.Name = "FeatureFlagService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type FeatureFlagService = typeof(setmetatable(
    {} :: {
        Name: string,
        _defaults: { [string]: boolean },
        _overrides: { [string]: boolean },
        _allowOverrides: boolean,
        _logger: Logger,
        _rollouts: { [string]: any },
        _roster: any,
        _cohorts: any,
    },
    FeatureFlagService
))

function FeatureFlagService.new(
    defaults: { [string]: boolean },
    allowOverrides: boolean,
    logger: Logger,
    rolloutCohorts: any,
    rollouts: { [string]: any },
    roster: any
): FeatureFlagService
    return setmetatable({
        Name = FeatureFlagService.Name,
        _defaults = table.clone(defaults),
        _overrides = {},
        _allowOverrides = allowOverrides,
        _logger = logger,
        _cohorts = rolloutCohorts,
        _rollouts = rollouts,
        _roster = roster,
    }, FeatureFlagService)
end

function FeatureFlagService.Init(self: FeatureFlagService, _context: any)
    self._logger:info("feature_flags_initialized", {
        count = self:count(),
        overridesAllowed = self._allowOverrides,
        scoped = self:scopedCount(),
    })
end

function FeatureFlagService.Start(self: FeatureFlagService)
    self._logger:info("feature_flags_started")
end

function FeatureFlagService.rollout(self: FeatureFlagService, flag: string): any
    local rollout = self._rollouts[flag]
    assert(rollout ~= nil, string.format("feature flag %q has no rollout stage", flag))
    return rollout
end

--[[
    Whether this player has the flag.

    `userId` is optional in the signature and required in fact for every flag
    that is mid-rollout, which is the only shape that lets the twenty-odd
    existing global call sites go on asking globally and still fails the one
    that asks about a flag which has since acquired a cohort.
]]
function FeatureFlagService.isEnabled(
    self: FeatureFlagService,
    flag: string,
    userId: number?
): boolean
    local override = self._overrides[flag]
    if override ~= nil then
        return override
    end

    local value = self._defaults[flag]
    assert(value ~= nil, string.format("unknown feature flag %q", flag))

    local rollout = self:rollout(flag)
    if not self._cohorts.isScoped(rollout.stage) then
        return value
    end

    assert(
        userId ~= nil,
        string.format(
            "feature flag %q is at rollout stage %q and was read without a player",
            flag,
            tostring(rollout.stage)
        )
    )

    local admitted = self._cohorts.admits(flag, rollout, self._roster, userId)
    return admitted
end

--[[
    Why a flag read the way it did for this player.

    A staged rollout generates exactly one support question -- "why can I not
    see it" -- and the answer is a rung name, so it is worth returning rather
    than reconstructing from the table by hand.
]]
function FeatureFlagService.explain(
    self: FeatureFlagService,
    flag: string,
    userId: number?
): (boolean, string)
    local override = self._overrides[flag]
    if override ~= nil then
        return override, "override"
    end

    local value = self._defaults[flag]
    assert(value ~= nil, string.format("unknown feature flag %q", flag))

    local rollout = self:rollout(flag)
    if not self._cohorts.isScoped(rollout.stage) then
        return value, if value then "everyone" else "stage_off"
    end

    if userId == nil then
        return false, "no_subject"
    end

    return self._cohorts.admits(flag, rollout, self._roster, userId)
end

function FeatureFlagService.setOverride(
    self: FeatureFlagService,
    flag: string,
    enabled: boolean
): (boolean, string?)
    if not self._allowOverrides then
        self._logger:warn("feature_flag_override_rejected", { flag = flag })
        return false, "overrides are disabled in this environment"
    end

    if self._defaults[flag] == nil then
        return false, "unknown feature flag"
    end

    self._overrides[flag] = enabled
    self._logger:info("feature_flag_overridden", { flag = flag, enabled = enabled })
    return true, nil
end

function FeatureFlagService.clearOverride(self: FeatureFlagService, flag: string)
    self._overrides[flag] = nil
end

function FeatureFlagService.count(self: FeatureFlagService): number
    local count = 0
    for _ in self._defaults do
        count += 1
    end
    return count
end

-- How many flags are mid-ladder. Logged at boot because a server that is
-- running a rollout and a server that is not are different things to read a
-- session's telemetry against.
function FeatureFlagService.scopedCount(self: FeatureFlagService): number
    local count = 0
    for flag in self._defaults do
        local rollout = self._rollouts[flag]
        if rollout ~= nil and self._cohorts.isScoped(rollout.stage) then
            count += 1
        end
    end
    return count
end

--[[
    Every flag as it stands for one player.

    Takes a user ID for the same reason `isEnabled` does: a snapshot that
    reported a cohort-scoped flag as its global default would be a report
    that is wrong about exactly the flags anybody is watching.
]]
function FeatureFlagService.snapshot(
    self: FeatureFlagService,
    userId: number?
): { [string]: boolean }
    local snapshot: { [string]: boolean } = {}
    for flag in self._defaults do
        snapshot[flag] = self:isEnabled(flag, userId)
    end
    for flag, value in self._overrides do
        snapshot[flag] = value
    end
    return snapshot
end

return table.freeze(FeatureFlagService)
