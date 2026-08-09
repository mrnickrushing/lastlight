--!strict

local Strings = require("./Strings")

local TownNightIncident = {}

local SITE_IDS = table.freeze({ "archive", "workshop", "inn" })

local DEFINITIONS = table.freeze({
    emberfall = table.freeze({
        table.freeze({
            id = "incident_emberfall_cinders",
            title = Strings.get("town.rooftop_cinders"),
            instruction = Strings.get("town.smother_three_cinder_nests_before_they"),
            actionText = Strings.get("town.smother"),
            objectText = "Cinder Nest",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
        table.freeze({
            id = "incident_emberfall_flues",
            title = Strings.get("town.sparking_flues"),
            instruction = Strings.get("town.cap_three_sparking_flues_before_the"),
            actionText = "CAP",
            objectText = Strings.get("town.sparking_flue"),
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
    }),
    miretide = table.freeze({
        table.freeze({
            id = "incident_miretide_clogs",
            title = Strings.get("town.choked_drains"),
            instruction = Strings.get("town.pull_three_root_clogs_before_the"),
            actionText = Strings.get("town.clear"),
            objectText = "Root Clog",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
        table.freeze({
            id = "incident_miretide_seeps",
            title = Strings.get("town.mire_seeps"),
            instruction = Strings.get("town.seal_three_mire_seeps_before_the"),
            actionText = Strings.get("town.seal"),
            objectText = "Mire Seep",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
    }),
    rootmoon = table.freeze({
        table.freeze({
            id = "incident_rootmoon_anchors",
            title = Strings.get("town.root_anchors"),
            instruction = Strings.get("town.sever_three_anchors_feeding_the_night"),
            actionText = Strings.get("town.sever"),
            objectText = "Root Anchor",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
        table.freeze({
            id = "incident_rootmoon_snares",
            title = Strings.get("town.snare_pods"),
            instruction = Strings.get("town.break_three_snare_pods_before_they"),
            actionText = Strings.get("town.break"),
            objectText = "Snare Pod",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
    }),
    ashen_veil = table.freeze({
        table.freeze({
            id = "incident_ashen_watchfires",
            title = Strings.get("town.dark_watchfires"),
            instruction = Strings.get("town.relight_three_watchfires_before_the_veil"),
            actionText = Strings.get("town.relight"),
            objectText = "Watchfire",
            duration = 42,
            lanternPenalty = 12,
            sites = SITE_IDS,
        }),
        table.freeze({
            id = "incident_ashen_bells",
            title = Strings.get("town.silenced_bells"),
            instruction = Strings.get("town.ring_three_ward_bells_before_the"),
            actionText = Strings.get("hud.ring"),
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
