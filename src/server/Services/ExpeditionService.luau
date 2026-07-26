--!strict

local ExpeditionService = {}
ExpeditionService.__index = ExpeditionService
ExpeditionService.Name = "ExpeditionService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type ExpeditionService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _worldService: any,
        _generator: any,
        _catalog: any,
        _seed: number,
        _manifest: any,
        _partCount: number,
    },
    ExpeditionService
))

function ExpeditionService.new(
    logger: Logger,
    worldService: any,
    generator: any,
    catalog: any,
    seed: number
): ExpeditionService
    return setmetatable({
        Name = ExpeditionService.Name,
        _logger = logger,
        _worldService = worldService,
        _generator = generator,
        _catalog = catalog,
        _seed = seed,
        _manifest = nil,
        _partCount = 0,
    }, ExpeditionService)
end

function ExpeditionService.Init(self: ExpeditionService, _context: any)
    local requestedSeed = game:GetAttribute("LastLightExpeditionSeed")
    local seed = if type(requestedSeed) == "number" then requestedSeed else self._seed
    local manifest = self._generator.generate(seed)
    local valid, issues = self._generator.validate(manifest)
    assert(valid, "Bramblewake expedition manifest is invalid: " .. table.concat(issues, "; "))

    local result = self._worldService:buildBramblewake(manifest, self._generator, self._catalog)
    self._manifest = manifest
    self._partCount = result.partCount
end

function ExpeditionService.Start(self: ExpeditionService)
    local manifest = assert(self._manifest, "expedition manifest was not initialized")
    self._logger:info("expedition_ready", {
        events = self._catalog.EventCount,
        hash = manifest.hash,
        modules = #manifest.modules,
        parts = self._partCount,
        pois = self._catalog.PointOfInterestCount,
        seed = manifest.seed,
        source = manifest.source,
    })
end

function ExpeditionService.enter(self: ExpeditionService, player: Player): boolean
    return self._worldService:enterBramblewake(player)
end

function ExpeditionService.snapshot(self: ExpeditionService, player: Player): any
    local snapshot = self._worldService:expeditionSnapshot(player)
    if not snapshot.active then
        return snapshot
    end

    local moduleDefinition = self._generator.moduleDefinition(snapshot.moduleId)
    local poiDefinition = if snapshot.poiId == nil
        then nil
        else self._generator.pointOfInterestDefinition(snapshot.poiId)
    local eventDefinition = if snapshot.eventId == nil
        then nil
        else self._generator.eventDefinition(snapshot.eventId)
    snapshot.moduleName = moduleDefinition.displayName
    snapshot.pointOfInterestName = if poiDefinition == nil then nil else poiDefinition.displayName
    snapshot.eventName = if eventDefinition == nil then nil else eventDefinition.displayName
    return snapshot
end

function ExpeditionService.manifest(self: ExpeditionService): any
    return self._manifest
end

return table.freeze(ExpeditionService)
