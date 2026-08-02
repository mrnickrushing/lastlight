--!strict

local MusicCatalog = {}

export type Track = {
    id: string,
    assetId: number,
    name: string,
    creator: string,
    duration: number,
    volume: number,
    intensity: number,
}

export type RegionScore = {
    day: Track,
    dusk: Track,
    night: Track,
}

local function track(
    id: string,
    assetId: number,
    name: string,
    creator: string,
    duration: number,
    volume: number,
    intensity: number
): Track
    return table.freeze({
        id = id,
        assetId = assetId,
        name = name,
        creator = creator,
        duration = duration,
        volume = volume,
        intensity = intensity,
    })
end

local REGIONS: { [string]: RegionScore } = {
    region_emberhollow = table.freeze({
        day = track(
            "music_emberhollow_day",
            110126070795458,
            "Light On The Meadow",
            "Epic Fantasy Music",
            235,
            0.18,
            0.22
        ),
        dusk = track(
            "music_emberhollow_dusk",
            101993543714380,
            "Dusk in the Glade",
            "Epic Fantasy Music",
            228,
            0.18,
            0.52
        ),
        night = track(
            "music_emberhollow_night",
            111317209034361,
            "The Night's Serenade",
            "Epic Fantasy Music",
            218,
            0.18,
            0.76
        ),
    }),
    region_bramblewake = table.freeze({
        day = track(
            "music_bramblewake_day",
            117417781820406,
            "Moss Gate",
            "Epic Fantasy Music",
            145,
            0.2,
            0.3
        ),
        dusk = track(
            "music_bramblewake_dusk",
            100440206824362,
            "Dark Forest Whisperings",
            "Sonatara",
            68,
            0.14,
            0.62
        ),
        night = track(
            "music_bramblewake_night",
            1848132434,
            "Dark Forest A",
            "Mark Stephen Cousins",
            140,
            0.2,
            0.88
        ),
    }),
    region_ironroot = table.freeze({
        day = track(
            "music_ironroot_day",
            1843033808,
            "Machine Echoes",
            "Liquid Cinema",
            65,
            0.16,
            0.34
        ),
        dusk = track(
            "music_ironroot_dusk",
            1843781882,
            "Tension Repeat Drones 5",
            "Tom Antonius R G Habes",
            132,
            0.19,
            0.64
        ),
        night = track(
            "music_ironroot_night",
            9038335527,
            "Alien Venom",
            "Epic Score",
            116,
            0.14,
            0.92
        ),
    }),
    region_mireglass = table.freeze({
        day = track(
            "music_mireglass_day",
            89192635799608,
            "Mystic Swamp",
            "Terra Fantasy",
            172,
            0.16,
            0.28
        ),
        dusk = track(
            "music_mireglass_dusk",
            1837021963,
            "Nocturne",
            "Thomas Balmforth",
            143,
            0.26,
            0.58
        ),
        night = track(
            "music_mireglass_night",
            1840777445,
            "Worlds Of Darkness",
            "Dave Hewson",
            177,
            0.26,
            0.9
        ),
    }),
    region_tempest = table.freeze({
        day = track(
            "music_tempest_day",
            84787113230396,
            "Lighthouse in the Storm",
            "PAPERWIZ",
            218,
            0.16,
            0.38
        ),
        dusk = track(
            "music_tempest_dusk",
            71987344991492,
            "Arcane Storm",
            "Dragonspire",
            188,
            0.17,
            0.68
        ),
        night = track(
            "music_tempest_night",
            1836768154,
            "Dark Storm",
            "Hossam Ramzy",
            164,
            0.16,
            0.94
        ),
    }),
    region_frostmere = table.freeze({
        day = track(
            "music_frostmere_day",
            103006284758182,
            "Arctic Oscillation",
            "The Multiverse Ensemble",
            289,
            0.32,
            0.2
        ),
        dusk = track(
            "music_frostmere_dusk",
            125256568468294,
            "Cold Strings in the Chapel Ruins",
            "Runaway Audio",
            176,
            0.22,
            0.55
        ),
        night = track(
            "music_frostmere_night",
            71207032544256,
            "Catacombs",
            "Astronaut Remains",
            144,
            0.3,
            0.84
        ),
    }),
    region_cinderfall = table.freeze({
        day = track(
            "music_cinderfall_day",
            77719566372748,
            "Magmatic Pressure",
            "Denis Jean Levaillant",
            132,
            0.2,
            0.4
        ),
        dusk = track(
            "music_cinderfall_dusk",
            131701319079131,
            "Ruins of the Silent Academy",
            "Silas Vane Nocturnal",
            179,
            0.12,
            0.69
        ),
        night = track(
            "music_cinderfall_night",
            1845714245,
            "Seance Mystery",
            "Commercial Non-Stop",
            62,
            0.18,
            0.91
        ),
    }),
    region_hollow = table.freeze({
        day = track(
            "music_hollow_day",
            83957123998450,
            "The Fallen Scholar's Study",
            "Silas Vane Nocturnal",
            183,
            0.12,
            0.48
        ),
        dusk = track(
            "music_hollow_dusk",
            137422342530077,
            "The Wanderer's Abyssal Path",
            "Silas Vane Nocturnal",
            205,
            0.14,
            0.72
        ),
        night = track(
            "music_hollow_night",
            106591893537345,
            "Shadow Cult's Inner Sanctum",
            "Silas Vane Nocturnal",
            199,
            0.12,
            0.96
        ),
    }),
}

local BLACKOUT = track(
    "music_blackout_pulse",
    126401983585086,
    "Dark Assessment Underscore Pulse Only",
    "Pierce Loeb",
    136,
    0.28,
    1
)

local function phaseKey(phase: string): string
    local normalized = string.lower(phase)
    if normalized == "night" then
        return "night"
    elseif normalized == "dusk" then
        return "dusk"
    end
    return "day"
end

function MusicCatalog.resolve(regionId: string, phase: string, blackoutActive: boolean): Track
    if blackoutActive then
        return BLACKOUT
    end
    local score = REGIONS[regionId] or REGIONS.region_emberhollow
    local key = phaseKey(phase)
    return if key == "night" then score.night elseif key == "dusk" then score.dusk else score.day
end

function MusicCatalog.isBlackoutActive(snapshot: any): boolean
    local blackout = if type(snapshot) == "table" then snapshot.blackout else nil
    if type(blackout) ~= "table" then
        return false
    end
    local status = tostring(blackout.status or "dormant")
    return status == "relay"
        or status == "old_growth"
        or status == "warden"
        or status == "resolution"
end

function MusicCatalog.resolveSnapshot(snapshot: any): Track
    local safeSnapshot = if type(snapshot) == "table" then snapshot else {}
    local regionId = if type(safeSnapshot.regionId) == "string"
        then safeSnapshot.regionId
        elseif safeSnapshot.expeditionActive == true then "region_bramblewake"
        else "region_emberhollow"
    return MusicCatalog.resolve(
        regionId,
        tostring(safeSnapshot.phase or "day"),
        MusicCatalog.isBlackoutActive(safeSnapshot)
    )
end

function MusicCatalog.regionIds(): { string }
    local ids = {}
    for regionId in REGIONS do
        table.insert(ids, regionId)
    end
    table.sort(ids)
    return ids
end

function MusicCatalog.tracks(): { Track }
    local result = { BLACKOUT }
    for _, regionId in MusicCatalog.regionIds() do
        local score = REGIONS[regionId]
        table.insert(result, score.day)
        table.insert(result, score.dusk)
        table.insert(result, score.night)
    end
    return result
end

return table.freeze(MusicCatalog)
