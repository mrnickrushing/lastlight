--!strict

local TownNightIncident = {}

local SITE_IDS = table.freeze({ "archive", "workshop", "inn" })

local DEFINITIONS = table.freeze({
    EMBERFALL = table.freeze({
        table.freeze({
            id = "incident_emberfall_cinders",
            title = "ROOFTOP CINDERS",
            instruction = "SMOTHER THREE CINDER NESTS BEFORE THEY CATCH",
            actionText = "SMOTHER",
            objectText = "Cinder Nest",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
        table.freeze({
            id = "incident_emberfall_flues",
            title = "SPARKING FLUES",
            instruction = "CAP THREE SPARKING FLUES BEFORE THE ROOFS IGNITE",
            actionText = "CAP",
            objectText = "Sparking Flue",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
    }),
    MIRETIDE = table.freeze({
        table.freeze({
            id = "incident_miretide_clogs",
            title = "CHOKED DRAINS",
            instruction = "PULL THREE ROOT CLOGS BEFORE THE SQUARE FLOODS",
            actionText = "CLEAR",
            objectText = "Root Clog",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
        table.freeze({
            id = "incident_miretide_seeps",
            title = "MIRE SEEPS",
            instruction = "SEAL THREE MIRE SEEPS BEFORE THE FOUNDATIONS SINK",
            actionText = "SEAL",
            objectText = "Mire Seep",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
    }),
    ROOTMOON = table.freeze({
        table.freeze({
            id = "incident_rootmoon_anchors",
            title = "ROOT ANCHORS",
            instruction = "SEVER THREE ANCHORS FEEDING THE NIGHT ASSAULT",
            actionText = "SEVER",
            objectText = "Root Anchor",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
        table.freeze({
            id = "incident_rootmoon_snares",
            title = "SNARE PODS",
            instruction = "BREAK THREE SNARE PODS BEFORE THEY BLOOM",
            actionText = "BREAK",
            objectText = "Snare Pod",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
    }),
    ["ASHEN VEIL"] = table.freeze({
        table.freeze({
            id = "incident_ashen_watchfires",
            title = "DARK WATCHFIRES",
            instruction = "RELIGHT THREE WATCHFIRES BEFORE THE VEIL CLOSES",
            actionText = "RELIGHT",
            objectText = "Watchfire",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
        table.freeze({
            id = "incident_ashen_bells",
            title = "SILENCED BELLS",
            instruction = "RING THREE WARD BELLS BEFORE THE VEIL SETTLES",
            actionText = "RING",
            objectText = "Ward Bell",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
    }),
})

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function TownNightIncident.forTheme(theme: any, nightNumber: number?): any
    local variants = if type(theme) == "string" then DEFINITIONS[theme] else nil
    if variants == nil then
        return nil
    end
    local cycle = if type(nightNumber) == "number" and nightNumber >= 1
        then math.floor((nightNumber - 1) / 4)
        else 0
    return variants[cycle % #variants + 1]
end

function TownNightIncident.create(theme: string, nightNumber: number, now: number): any
    assert(nightNumber >= 1 and nightNumber == math.floor(nightNumber), "night number is invalid")
    local definition = TownNightIncident.forTheme(theme, nightNumber)
    assert(definition ~= nil, "town-night incident theme is unknown")
    assert(finite(now), "incident start time is invalid")
    return {
        definition = definition,
        endsAt = now + definition.duration,
        nightNumber = nightNumber,
        resolved = {},
        resolvedCount = 0,
        startedAt = now,
        status = "active",
    }
end

local function knownSite(definition: any, siteId: any): boolean
    if type(siteId) ~= "string" then
        return false
    end
    for _, known in definition.sites do
        if known == siteId then
            return true
        end
    end
    return false
end

function TownNightIncident.interact(state: any, siteId: any, now: number): (any, any)
    assert(finite(now), "incident interaction time is invalid")
    if state.status ~= "active" then
        return state, { accepted = false, reason = "incident_inactive" }
    end
    if now >= state.endsAt then
        local expired: any = table.clone(state)
        expired.status = "failed"
        return expired, { accepted = false, reason = "incident_expired" }
    end
    if not knownSite(state.definition, siteId) then
        return state, { accepted = false, reason = "unknown_site" }
    end
    if state.resolved[siteId] == true then
        return state, { accepted = false, reason = "site_resolved" }
    end

    local nextState: any = table.clone(state)
    nextState.resolved = table.clone(state.resolved)
    nextState.resolved[siteId] = true
    nextState.resolvedCount += 1
    local completed = nextState.resolvedCount >= #state.definition.sites
    nextState.status = if completed then "complete" else "active"
    return nextState,
        {
            accepted = true,
            completed = completed,
            remaining = math.max(0, #state.definition.sites - nextState.resolvedCount),
            siteId = siteId,
        }
end

function TownNightIncident.expire(state: any, now: number): (any, any)
    assert(finite(now), "incident expiry time is invalid")
    if state.status ~= "active" then
        return state, { applied = false, reason = "incident_inactive" }
    end
    if now < state.endsAt then
        return state, { applied = false, reason = "incident_active" }
    end
    local nextState: any = table.clone(state)
    nextState.status = "failed"
    return nextState,
        {
            applied = true,
            lanternPenalty = state.definition.lanternPenalty,
            unresolved = #state.definition.sites - state.resolvedCount,
        }
end

function TownNightIncident.snapshot(state: any?): any
    if state == nil then
        return nil
    end
    return {
        endsAt = state.endsAt,
        id = state.definition.id,
        instruction = state.definition.instruction,
        resolved = state.resolvedCount,
        required = #state.definition.sites,
        status = state.status,
        title = state.definition.title,
    }
end

return table.freeze(TownNightIncident)
