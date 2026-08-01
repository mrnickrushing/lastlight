--!strict

local Catalog = require("./Content/Definitions/BramblewakeExpedition")
local ExpeditionEventFlow = require("./ExpeditionEventFlow")

local ExpeditionGenerator = {}

local RANDOM_MODULUS = 2147483647
local RANDOM_MULTIPLIER = 16807
local HASH_MULTIPLIER = 33

local ROUTES = {
    { 0, 0, 1, 1, 0, 0, 3, 3, 0, 0, 0 },
    { 0, 0, 3, 3, 0, 0, 1, 1, 0, 0, 0 },
    { 1, 1, 0, 0, 0, 3, 3, 0, 0, 1, 1 },
    { 0, 1, 1, 0, 0, 0, 3, 3, 3, 0, 0 },
}

local DIRECTION_X = { 0, 1, 0, -1 }
local DIRECTION_Z = { -1, 0, 1, 0 }

local function normalizeSeed(seed: number): number
    local normalized = math.floor(math.abs(seed)) % RANDOM_MODULUS
    return if normalized == 0 then 1 else normalized
end

local function randomSource(seed: number): (number) -> number
    local state = normalizeSeed(seed)
    return function(maximum: number): number
        state = (state * RANDOM_MULTIPLIER) % RANDOM_MODULUS
        return (state % maximum) + 1
    end
end

local function shuffled(values: { any }, random: (number) -> number): { any }
    local result = table.clone(values)
    for index = #result, 2, -1 do
        local other = random(index)
        result[index], result[other] = result[other], result[index]
    end
    return result
end

local function indexDefinitions(definitions: { any }): { [string]: any }
    local byId: { [string]: any } = {}
    for _, definition in definitions do
        byId[definition.id] = definition
    end
    return byId
end

local MODULES_BY_ID = indexDefinitions(Catalog.Modules)
local POIS_BY_ID = indexDefinitions(Catalog.PointsOfInterest)
local EVENTS_BY_ID = indexDefinitions(Catalog.Events)

local function hashText(hash: number, value: string): number
    local result = hash
    for index = 1, #value do
        result = (result * HASH_MULTIPLIER + string.byte(value, index)) % RANDOM_MODULUS
    end
    return result
end

function ExpeditionGenerator.computeHash(manifest: any): string
    local hash = hashText(5381, tostring(manifest.regionId))
    hash = hashText(hash, ":" .. tostring(manifest.version))
    for _, placement in manifest.modules do
        local fields = string.format(
            "|%s:%d:%d:%d:%s:%s",
            placement.moduleId,
            placement.cellX,
            placement.cellZ,
            placement.rotation,
            placement.poiId or "-",
            placement.eventId or "-"
        )
        hash = hashText(hash, fields)
    end
    return string.format("%08x", hash)
end

local function placeContent(manifest: any, random: (number) -> number)
    local poiDefinitions = shuffled(Catalog.PointsOfInterest, random)
    local eventDefinitions = shuffled(Catalog.Events, random)
    local occupied: { [number]: boolean } = {}

    local poiPlacements = shuffled(manifest.modules, random)
    local poiIndex = 1
    for _, placement in poiPlacements do
        local moduleDefinition = MODULES_BY_ID[placement.moduleId]
        if moduleDefinition.poiSocket and not occupied[placement.index] then
            placement.poiId = poiDefinitions[poiIndex].id
            occupied[placement.index] = true
            poiIndex += 1
            if poiIndex > #poiDefinitions then
                break
            end
        end
    end

    local eventPlacements = shuffled(manifest.modules, random)
    local eventIndex = 1
    for _, placement in eventPlacements do
        local moduleDefinition = MODULES_BY_ID[placement.moduleId]
        -- POI and event sockets occupy opposite authored corners of a module,
        -- so representative modules can host both without overlapping the
        -- critical path or each other. This is required to place all eight
        -- regional events while retaining all four POIs in twelve modules.
        if moduleDefinition.eventSocket then
            placement.eventId = eventDefinitions[eventIndex].id
            eventIndex += 1
            if eventIndex > #eventDefinitions then
                break
            end
        end
    end
end

local function assemble(seed: number, attempt: number, source: string, fixed: boolean): any
    local random = randomSource(seed + attempt * 7919)
    local middle = {}
    for index = 2, #Catalog.Modules - 1 do
        table.insert(middle, Catalog.Modules[index])
    end
    if not fixed then
        middle = shuffled(middle, random)
    end

    local sequence = { Catalog.Modules[1] }
    for _, definition in middle do
        table.insert(sequence, definition)
    end
    table.insert(sequence, Catalog.Modules[#Catalog.Modules])

    local route = if fixed then ROUTES[1] else ROUTES[random(#ROUTES)]
    local modules = {}
    local cellX = 0
    local cellZ = 0
    for index, definition in sequence do
        local direction = if index <= #route then route[index] else route[#route]
        table.insert(modules, {
            index = index,
            moduleId = definition.id,
            cellX = cellX,
            cellZ = cellZ,
            rotation = direction * 90,
        })
        if index <= #route then
            cellX += DIRECTION_X[direction + 1]
            cellZ += DIRECTION_Z[direction + 1]
        end
    end

    local manifest = {
        version = Catalog.Version,
        regionId = Catalog.RegionId,
        seed = normalizeSeed(seed),
        source = source,
        attempts = attempt,
        modules = modules,
    }
    placeContent(manifest, random)
    manifest.hash = ExpeditionGenerator.computeHash(manifest)
    return manifest
end

function ExpeditionGenerator.validate(manifest: any): (boolean, { string })
    local issues: { string } = {}
    local function issue(message: string)
        table.insert(issues, message)
    end

    if type(manifest) ~= "table" then
        return false, { "manifest must be a table" }
    end
    if manifest.version ~= Catalog.Version then
        issue("manifest version does not match the Bramblewake catalog")
    end
    if manifest.regionId ~= Catalog.RegionId then
        issue("manifest region is not Bramblewake")
    end
    if type(manifest.modules) ~= "table" or #manifest.modules ~= Catalog.ModuleCount then
        issue(string.format("manifest must contain %d modules", Catalog.ModuleCount))
        return false, issues
    end

    local seenModules: { [string]: boolean } = {}
    local seenCells: { [string]: boolean } = {}
    local seenPois: { [string]: boolean } = {}
    local seenEvents: { [string]: boolean } = {}
    local tagCounts: { [string]: number } = {}
    local totalParts = 0
    local totalLights = 0
    local totalEffects = 0

    for index, placement in manifest.modules do
        if placement.index ~= index then
            issue(string.format("module %d has an invalid sequence index", index))
        end
        local definition = MODULES_BY_ID[placement.moduleId]
        if definition == nil then
            issue(string.format("module %d references unknown content", index))
        else
            if definition.enabled ~= true then
                issue("manifest contains a disabled module")
            end
            if definition.defaultTraversal ~= true then
                issue("critical path requires a profession or premium traversal ability")
            end
            if seenModules[definition.id] then
                issue("module content repeats in the representative slice")
            end
            seenModules[definition.id] = true
            totalParts += definition.partBudget
            totalLights += definition.lightBudget
            totalEffects += definition.effectBudget
            for _, tag in definition.tags do
                tagCounts[tag] = (tagCounts[tag] or 0) + 1
            end
        end

        if type(placement.cellX) ~= "number" or type(placement.cellZ) ~= "number" then
            issue(string.format("module %d has invalid cell coordinates", index))
        else
            local cellKey = string.format("%d:%d", placement.cellX, placement.cellZ)
            if seenCells[cellKey] then
                issue("route overlaps a previously occupied streaming cell")
            end
            seenCells[cellKey] = true
            if index > 1 then
                local previous = manifest.modules[index - 1]
                local distance = math.abs(placement.cellX - previous.cellX)
                    + math.abs(placement.cellZ - previous.cellZ)
                if distance ~= 1 then
                    issue(string.format("module %d is disconnected from the critical path", index))
                end
            end
        end

        if placement.poiId ~= nil then
            if POIS_BY_ID[placement.poiId] == nil then
                issue("manifest references an unknown point of interest")
            elseif POIS_BY_ID[placement.poiId].enabled ~= true then
                issue("manifest contains a disabled point of interest")
            elseif seenPois[placement.poiId] then
                issue("point of interest repeats in one expedition")
            elseif definition ~= nil and not definition.poiSocket then
                issue("point of interest occupies an incompatible module")
            end
            seenPois[placement.poiId] = true
        end
        if placement.eventId ~= nil then
            local eventDefinition = EVENTS_BY_ID[placement.eventId]
            if eventDefinition == nil then
                issue("manifest references an unknown event")
            elseif eventDefinition.enabled ~= true then
                issue("manifest contains a disabled event")
            elseif seenEvents[placement.eventId] then
                issue("event repeats in one expedition")
            elseif definition ~= nil and not definition.eventSocket then
                issue("event occupies an incompatible module")
            else
                local contractValid, contractIssues =
                    ExpeditionEventFlow.validateDefinition(eventDefinition)
                if not contractValid then
                    issue("event contract is invalid: " .. table.concat(contractIssues, ", "))
                end
                if eventDefinition.minimumRouteSpace > Catalog.CellSize - 24 then
                    issue("event route-space requirement exceeds its module clearing")
                end
            end
            seenEvents[placement.eventId] = true
        end
    end

    local firstDefinition = MODULES_BY_ID[manifest.modules[1].moduleId]
    local lastDefinition = MODULES_BY_ID[manifest.modules[#manifest.modules].moduleId]
    if firstDefinition == nil or firstDefinition.role ~= "arrival" then
        issue("critical path does not begin at an arrival module")
    end
    if lastDefinition == nil or lastDefinition.role ~= "extraction" then
        issue("critical path does not end at an extraction module")
    end

    local poiCount = 0
    for _ in seenPois do
        poiCount += 1
    end
    local eventCount = 0
    for _ in seenEvents do
        eventCount += 1
    end
    if poiCount ~= Catalog.PointOfInterestCount then
        issue(
            string.format("manifest must place %d points of interest", Catalog.PointOfInterestCount)
        )
    end
    if eventCount ~= Catalog.EventCount then
        issue(string.format("manifest must place %d events", Catalog.EventCount))
    end

    local requiredTags = Catalog.RequiredTags :: { [string]: number }
    for tag, minimum in requiredTags do
        if (tagCounts[tag] or 0) < minimum then
            issue(string.format("manifest does not meet the %s module minimum", tag))
        end
    end
    for _, moduleId in Catalog.RequiredModuleIds do
        if not seenModules[moduleId] then
            issue("manifest is missing required module " .. moduleId)
        end
    end
    if totalParts > Catalog.PartBudget then
        issue("manifest exceeds the regional part budget")
    end
    if totalLights > Catalog.LightBudget then
        issue("manifest exceeds the regional light budget")
    end
    if totalEffects > Catalog.EffectBudget then
        issue("manifest exceeds the regional effect budget")
    end
    if manifest.hash ~= ExpeditionGenerator.computeHash(manifest) then
        issue("manifest hash does not match its content")
    end

    return #issues == 0, issues
end

function ExpeditionGenerator.generate(seed: number, forceFallback: boolean?): any
    local normalizedSeed = normalizeSeed(seed)
    if not forceFallback then
        for attempt = 1, 3 do
            local manifest = assemble(normalizedSeed, attempt, "generated", false)
            local valid = ExpeditionGenerator.validate(manifest)
            if valid then
                return manifest
            end
        end
    end

    local fallback = assemble(normalizedSeed, 3, "known_good_fallback", true)
    local valid, issues = ExpeditionGenerator.validate(fallback)
    assert(valid, "known-good Bramblewake fallback is invalid: " .. table.concat(issues, "; "))
    return fallback
end

function ExpeditionGenerator.moduleDefinition(moduleId: string): any
    return MODULES_BY_ID[moduleId]
end

function ExpeditionGenerator.pointOfInterestDefinition(poiId: string): any
    return POIS_BY_ID[poiId]
end

function ExpeditionGenerator.eventDefinition(eventId: string): any
    return EVENTS_BY_ID[eventId]
end

return table.freeze(ExpeditionGenerator)
