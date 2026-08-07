--!strict

local Bramblewake = require("./Content/Definitions/BramblewakeExpedition")
local Ironroot = require("./Content/Definitions/IronrootExpedition")
local Mireglass = require("./Content/Definitions/MireglassExpedition")
local Tempest = require("./Content/Definitions/TempestExpedition")
local ExpeditionEventFlow = require("./ExpeditionEventFlow")

--[[
    The generator is region-agnostic: everything it needs about a region --
    module pool, socket counts, budgets, required tags, the known-good
    fallback walk -- arrives from that region's catalog, which all declare
    the same shape. Adding a region is adding a catalog and a line in
    CATALOGS; no rule below knows a region by name.

    Bramblewake remains the default so every existing caller and every
    prior manifest hash is untouched, and the specs pin that.
]]
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

-- Catalogs are structurally alike but not identical (Bramblewake carries a
-- measured BuiltPartBudget the Delve cannot have until its builder ships),
-- so the list is typed by what the generator actually reads from it.
local CATALOGS: { any } =
    table.freeze({ Bramblewake :: any, Ironroot :: any, Mireglass :: any, Tempest :: any })
local DEFAULT_REGION_ID = Bramblewake.RegionId

type Region = {
    catalog: any,
    modulesById: { [string]: any },
    poisById: { [string]: any },
    eventsById: { [string]: any },
}

local REGIONS: { [string]: Region } = {}
for _, catalog in CATALOGS do
    REGIONS[catalog.RegionId] = {
        catalog = catalog,
        modulesById = indexDefinitions(catalog.Modules),
        poisById = indexDefinitions(catalog.PointsOfInterest),
        eventsById = indexDefinitions(catalog.Events),
    }
end

local function regionFor(regionId: any): Region
    local region = REGIONS[if type(regionId) == "string" then regionId else DEFAULT_REGION_ID]
    return region or REGIONS[DEFAULT_REGION_ID]
end

-- Definition lookups are region-wide: content ids carry their region's
-- prefix, so a single id never means two things.
local function findDefinition(field: string, id: any): any
    if type(id) ~= "string" then
        return nil
    end
    for _, region in REGIONS do
        local found = (region :: any)[field][id]
        if found ~= nil then
            return found
        end
    end
    return nil
end

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

local function placeContent(manifest: any, random: (number) -> number, region: Region)
    local poiDefinitions = shuffled(region.catalog.PointsOfInterest, random)
    local eventDefinitions = shuffled(region.catalog.Events, random)
    local occupied: { [number]: boolean } = {}

    --[[
        A region's catalog holds more content than any one run shows: the
        Delve declares twelve points of interest and shows four. Placement
        therefore stops at the run's count, not at the pool's end. For
        Bramblewake, whose pool is exactly its run count, this is the same
        walk it always took.
    ]]
    local poiLimit = math.min(#poiDefinitions, region.catalog.PointOfInterestCount)
    local eventLimit = math.min(#eventDefinitions, region.catalog.EventCount)

    local poiPlacements = shuffled(manifest.modules, random)
    local poiIndex = 1
    for _, placement in poiPlacements do
        local moduleDefinition = region.modulesById[placement.moduleId]
        if moduleDefinition.poiSocket and not occupied[placement.index] then
            placement.poiId = poiDefinitions[poiIndex].id
            occupied[placement.index] = true
            poiIndex += 1
            if poiIndex > poiLimit then
                break
            end
        end
    end

    local eventPlacements = shuffled(manifest.modules, random)
    local eventIndex = 1
    for _, placement in eventPlacements do
        local moduleDefinition = region.modulesById[placement.moduleId]
        -- POI and event sockets occupy opposite authored corners of a module,
        -- so representative modules can host both without overlapping the
        -- critical path or each other. This is required to place all eight
        -- regional events while retaining all four POIs in twelve modules.
        if moduleDefinition.eventSocket then
            placement.eventId = eventDefinitions[eventIndex].id
            eventIndex += 1
            if eventIndex > eventLimit then
                break
            end
        end
    end
end

local function moduleByRole(region: Region, role: string): any
    for _, definition in region.catalog.Modules do
        if definition.role == role then
            return definition
        end
    end
    error(region.catalog.RegionId .. " catalog has no module with role " .. role)
end

--[[
    Choose the run's middle from the full pool.

    Every run still walks ModuleCount modules; the pool is what grew. The
    selection is constrained, not blind: required module ids come first,
    then each required tag's deficit is filled from the shuffled pool, then
    the remaining slots take whatever the shuffle offers. Attempts and the
    validator catch the rare shuffle this greedy pass cannot rescue.
]]
local function selectMiddle(
    region: Region,
    arrival: any,
    extraction: any,
    random: (number) -> number
): { any }
    local target = region.catalog.ModuleCount - 2
    local pool = {}
    for _, definition in region.catalog.Modules do
        if definition.role ~= "arrival" and definition.role ~= "extraction" then
            table.insert(pool, definition)
        end
    end
    pool = shuffled(pool, random)

    local chosen: { any } = {}
    local chosenIds: { [string]: boolean } = {}
    local tagCounts: { [string]: number } = {}
    local function countTags(definition: any)
        for _, tag in definition.tags do
            tagCounts[tag] = (tagCounts[tag] or 0) + 1
        end
    end
    countTags(arrival)
    countTags(extraction)
    local function take(definition: any)
        if chosenIds[definition.id] then
            return
        end
        chosenIds[definition.id] = true
        table.insert(chosen, definition)
        countTags(definition)
    end

    for _, moduleId in region.catalog.RequiredModuleIds do
        for _, definition in pool do
            if definition.id == moduleId then
                take(definition)
                break
            end
        end
    end
    for tag, minimum in region.catalog.RequiredTags :: { [string]: number } do
        while (tagCounts[tag] or 0) < minimum and #chosen < target do
            local found = false
            for _, definition in pool do
                if not chosenIds[definition.id] then
                    for _, candidateTag in definition.tags do
                        if candidateTag == tag then
                            take(definition)
                            found = true
                            break
                        end
                    end
                end
                if found then
                    break
                end
            end
            if not found then
                break
            end
        end
    end
    for _, definition in pool do
        if #chosen >= target then
            break
        end
        take(definition)
    end
    -- Selection order carries shuffle bias toward required content at the
    -- front; one more shuffle makes the walk order its own surprise.
    return shuffled(chosen, random)
end

local function assemble(
    seed: number,
    attempt: number,
    source: string,
    fixed: boolean,
    region: Region
): any
    local random = randomSource(seed + attempt * 7919)
    local arrival = moduleByRole(region, "arrival")
    local extraction = moduleByRole(region, "extraction")
    local middle
    if fixed then
        middle = {}
        for _, moduleId in region.catalog.FixedMiddleIds do
            table.insert(middle, region.modulesById[moduleId])
        end
    else
        middle = selectMiddle(region, arrival, extraction, random)
    end

    local sequence = { arrival }
    for _, definition in middle do
        table.insert(sequence, definition)
    end
    table.insert(sequence, extraction)

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
        version = region.catalog.Version,
        regionId = region.catalog.RegionId,
        seed = normalizeSeed(seed),
        source = source,
        attempts = attempt,
        modules = modules,
    }
    placeContent(manifest, random, region)
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
    if REGIONS[manifest.regionId] == nil then
        return false, { "manifest names no known region" }
    end
    local region = regionFor(manifest.regionId)
    local catalog = region.catalog
    if manifest.version ~= catalog.Version then
        issue("manifest version does not match the " .. catalog.RegionId .. " catalog")
    end
    if type(manifest.modules) ~= "table" or #manifest.modules ~= catalog.ModuleCount then
        issue(string.format("manifest must contain %d modules", catalog.ModuleCount))
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
        local definition = region.modulesById[placement.moduleId]
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
            if region.poisById[placement.poiId] == nil then
                issue("manifest references an unknown point of interest")
            elseif region.poisById[placement.poiId].enabled ~= true then
                issue("manifest contains a disabled point of interest")
            elseif seenPois[placement.poiId] then
                issue("point of interest repeats in one expedition")
            elseif definition ~= nil and not definition.poiSocket then
                issue("point of interest occupies an incompatible module")
            end
            seenPois[placement.poiId] = true
        end
        if placement.eventId ~= nil then
            local eventDefinition = region.eventsById[placement.eventId]
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
                if eventDefinition.minimumRouteSpace > catalog.CellSize - 24 then
                    issue("event route-space requirement exceeds its module clearing")
                end
            end
            seenEvents[placement.eventId] = true
        end
    end

    local firstDefinition = region.modulesById[manifest.modules[1].moduleId]
    local lastDefinition = region.modulesById[manifest.modules[#manifest.modules].moduleId]
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
    if poiCount ~= catalog.PointOfInterestCount then
        issue(
            string.format("manifest must place %d points of interest", catalog.PointOfInterestCount)
        )
    end
    if eventCount ~= catalog.EventCount then
        issue(string.format("manifest must place %d events", catalog.EventCount))
    end

    local requiredTags = catalog.RequiredTags :: { [string]: number }
    for tag, minimum in requiredTags do
        if (tagCounts[tag] or 0) < minimum then
            issue(string.format("manifest does not meet the %s module minimum", tag))
        end
    end
    for _, moduleId in catalog.RequiredModuleIds do
        if not seenModules[moduleId] then
            issue("manifest is missing required module " .. moduleId)
        end
    end
    if totalParts > catalog.PartBudget then
        issue("manifest exceeds the regional part budget")
    end
    if totalLights > catalog.LightBudget then
        issue("manifest exceeds the regional light budget")
    end
    if totalEffects > catalog.EffectBudget then
        issue("manifest exceeds the regional effect budget")
    end
    if manifest.hash ~= ExpeditionGenerator.computeHash(manifest) then
        issue("manifest hash does not match its content")
    end

    return #issues == 0, issues
end

function ExpeditionGenerator.generate(
    seed: number,
    forceFallback: boolean?,
    avoidHashes: { [string]: boolean }?,
    regionId: string?
): any
    local region = regionFor(regionId)
    local normalizedSeed = normalizeSeed(seed)
    if not forceFallback then
        -- Repetition control: a caller that remembers recent manifests can
        -- ask for something it has not walked lately. A repeat is a
        -- preference, validity is a requirement — if every attempt lands on
        -- an avoided hash, the last valid manifest wins anyway.
        local lastValid = nil
        for attempt = 1, if avoidHashes ~= nil then 5 else 3 do
            local manifest = assemble(normalizedSeed, attempt, "generated", false, region)
            local valid = ExpeditionGenerator.validate(manifest)
            if valid then
                if avoidHashes == nil or avoidHashes[manifest.hash] ~= true then
                    return manifest
                end
                lastValid = manifest
            end
        end
        if lastValid ~= nil then
            return lastValid
        end
    end

    local fallback = assemble(normalizedSeed, 3, "known_good_fallback", true, region)
    local valid, issues = ExpeditionGenerator.validate(fallback)
    assert(
        valid,
        "known-good "
            .. region.catalog.RegionId
            .. " fallback is invalid: "
            .. table.concat(issues, "; ")
    )
    return fallback
end

function ExpeditionGenerator.moduleDefinition(moduleId: string): any
    return findDefinition("modulesById", moduleId)
end

function ExpeditionGenerator.pointOfInterestDefinition(poiId: string): any
    return findDefinition("poisById", poiId)
end

function ExpeditionGenerator.eventDefinition(eventId: string): any
    return findDefinition("eventsById", eventId)
end

-- The region catalogs the generator can compose, in declaration order.
function ExpeditionGenerator.regionIds(): { string }
    local ids: { string } = {}
    for _, catalog in CATALOGS do
        table.insert(ids, catalog.RegionId)
    end
    return ids
end

function ExpeditionGenerator.catalogFor(regionId: string?): any
    return regionFor(regionId).catalog
end

return table.freeze(ExpeditionGenerator)
