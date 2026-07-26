--!strict

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
    },
    FeatureFlagService
))

function FeatureFlagService.new(
    defaults: { [string]: boolean },
    allowOverrides: boolean,
    logger: Logger
): FeatureFlagService
    return setmetatable({
        Name = FeatureFlagService.Name,
        _defaults = table.clone(defaults),
        _overrides = {},
        _allowOverrides = allowOverrides,
        _logger = logger,
    }, FeatureFlagService)
end

function FeatureFlagService.Init(self: FeatureFlagService, _context: any)
    self._logger:info("feature_flags_initialized", {
        count = self:count(),
        overridesAllowed = self._allowOverrides,
    })
end

function FeatureFlagService.Start(self: FeatureFlagService)
    self._logger:info("feature_flags_started")
end

function FeatureFlagService.isEnabled(self: FeatureFlagService, flag: string): boolean
    local override = self._overrides[flag]
    if override ~= nil then
        return override
    end

    local value = self._defaults[flag]
    assert(value ~= nil, string.format("unknown feature flag %q", flag))
    return value
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

function FeatureFlagService.snapshot(self: FeatureFlagService): { [string]: boolean }
    local snapshot = table.clone(self._defaults)
    for flag, value in self._overrides do
        snapshot[flag] = value
    end
    return snapshot
end

return table.freeze(FeatureFlagService)
