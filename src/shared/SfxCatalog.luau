--!strict
--[[
    Every sound effect in the game, and the rules for when state changes make
    one play.

    The game shipped with music and nothing else: a silent axe, silent
    gathering, a silent night falling. Feedback sound is half of what makes
    tapping feel like hitting, so this catalog exists — but the decisions
    about WHEN a cue fires live here as pure data-in data-out, so a spec can
    hold them still, and the controller that owns actual Sound instances
    stays too thin to break.

    Every cue uses an engine-bundled rbxasset sound. Bundled files ship with
    the client: no moderation queue, no asset permissions, no CDN fetch —
    exactly the failure modes that already bit the authored meshes. The trade
    is a small palette, so distinct cues reuse a file at different playback
    speeds.
]]

local SfxCatalog = {}

export type Cue = {
    id: string,
    soundId: string,
    volume: number,
    minSpeed: number,
    maxSpeed: number,
    cooldown: number,
}

local function cue(
    id: string,
    soundId: string,
    volume: number,
    minSpeed: number,
    maxSpeed: number,
    cooldown: number
): Cue
    return table.freeze({
        id = id,
        soundId = soundId,
        volume = volume,
        minSpeed = minSpeed,
        maxSpeed = maxSpeed,
        cooldown = cooldown,
    })
end

local SLASH = "rbxasset://sounds/swordslash.wav"
local PING = "rbxasset://sounds/electronicpingshort.wav"
local BUTTON = "rbxasset://sounds/button.wav"
local SNAP = "rbxasset://sounds/snap.mp3"
local BASS = "rbxasset://sounds/bass.wav"

local CUES: { [string]: Cue } = {
    -- Input feedback: played directly by input handlers, not by the resolver,
    -- because a swing must sound on the tap, not a snapshot later.
    swing = cue("swing", SLASH, 0.35, 0.92, 1.08, 0.12),
    tap = cue("tap", BUTTON, 0.4, 0.95, 1.1, 0.1),

    -- Snapshot-driven cues.
    gather = cue("gather", PING, 0.32, 1.1, 1.3, 0.15),
    bank = cue("bank", PING, 0.4, 0.72, 0.82, 0.3),
    objective = cue("objective", SNAP, 0.45, 0.98, 1.05, 0.8),
    night = cue("night", BASS, 0.6, 0.7, 0.78, 2),
    encounter = cue("encounter", BASS, 0.65, 0.55, 0.62, 2),
    downed = cue("downed", BASS, 0.55, 0.42, 0.48, 2),
    revived = cue("revived", PING, 0.4, 1.35, 1.5, 1),
}

SfxCatalog.Cues = table.freeze(CUES)

function SfxCatalog.get(id: string): Cue?
    return CUES[id]
end

--[[
    What the previous snapshot's relevant corners looked like, extracted so
    the comparison never holds a reference to a whole snapshot.
]]
export type Signature = {
    resources: number,
    banked: number,
    objective: string,
    nightActive: boolean,
    blackoutStatus: string,
    encounterActive: boolean,
    downed: boolean,
}

local function bankedTotal(bankedMaterials: any): number
    if type(bankedMaterials) == "number" then
        return bankedMaterials
    end
    if type(bankedMaterials) ~= "table" then
        return 0
    end
    local total = 0
    for _, amount in bankedMaterials do
        if type(amount) == "number" then
            total += amount
        end
    end
    return total
end

function SfxCatalog.signature(snapshot: any): Signature
    local elite = if type(snapshot.elite) == "table" then snapshot.elite else nil
    local boss = if type(snapshot.boss) == "table" then snapshot.boss else nil
    local blackout = if type(snapshot.blackout) == "table" then snapshot.blackout else nil
    local survival = if type(snapshot.survival) == "table" then snapshot.survival else nil
    return {
        resources = tonumber(snapshot.resources) or 0,
        banked = bankedTotal(snapshot.bankedMaterials),
        objective = tostring(snapshot.objective or ""),
        nightActive = snapshot.nightActive == true,
        blackoutStatus = if blackout ~= nil then tostring(blackout.status or "") else "",
        encounterActive = (elite ~= nil and elite.active == true)
            or (boss ~= nil and boss.active == true),
        downed = survival ~= nil and survival.downed == true,
    }
end

--[[
    The cues a state change earns. Pure: previous signature + new snapshot in,
    cue ids out. The first snapshot of a session passes previous = nil and
    earns nothing — a reconnect mid-night is not a night falling.
]]
function SfxCatalog.resolveTransitions(previous: Signature?, snapshot: any): ({ string }, Signature)
    local nextSignature = SfxCatalog.signature(snapshot)
    if previous == nil then
        return {}, nextSignature
    end
    local cues: { string } = {}
    if nextSignature.resources > previous.resources then
        table.insert(cues, "gather")
    end
    if nextSignature.banked > previous.banked then
        table.insert(cues, "bank")
    end
    if nextSignature.objective ~= previous.objective and nextSignature.objective ~= "" then
        table.insert(cues, "objective")
    end
    if nextSignature.nightActive and not previous.nightActive then
        table.insert(cues, "night")
    end
    if nextSignature.blackoutStatus == "relay" and previous.blackoutStatus ~= "relay" then
        table.insert(cues, "encounter")
    end
    if nextSignature.encounterActive and not previous.encounterActive then
        table.insert(cues, "encounter")
    end
    if nextSignature.downed and not previous.downed then
        table.insert(cues, "downed")
    elseif previous.downed and not nextSignature.downed then
        table.insert(cues, "revived")
    end
    return cues, nextSignature
end

return table.freeze(SfxCatalog)
