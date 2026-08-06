--!strict

--[[
    Who lives in Emberhollow, and who is going to.

    Three residents shipped with chapter I and have been named in half a
    dozen places since -- ResidentLife's job table, the dialogue module,
    the world's placement code. Milestone 7 adds eight more, drawn from
    the two new regions, and eight more hand-maintained lists is how a
    roster drifts out of agreement with itself. So the roster lives here
    once: identity, home region, when they arrive, the job they take, and
    the quest they carry.

    Arrival is the important field. A resident is not in town because a
    module exists; they arrive when their chapter does. Chapter I's three
    are present from the first dawn, the Delve's four arrive with chapter
    II, and the Fen's four with chapter III -- so a fresh save still meets
    exactly the three people it always met, and the town fills as the
    story does.

    Nobody here is a job title with a name attached. Each one wanted
    something in their own region, failed or half-succeeded at it, and
    brought that with them.
]]

local ResidentRoster = {}

export type Job = {
    residentId: string,
    buildingId: string,
    title: string,
    boon: string,
    boonLabel: string,
}

export type Resident = {
    id: string,
    displayName: string,
    fullName: string,
    homeRegion: string,
    arrivesInChapter: number,
    questId: string,
    job: Job,
    -- One line about who they are, for the world sign and the Field Book.
    introduction: string,
}

local function resident(definition: Resident): Resident
    return table.freeze({
        id = definition.id,
        displayName = definition.displayName,
        fullName = definition.fullName,
        homeRegion = definition.homeRegion,
        arrivesInChapter = definition.arrivesInChapter,
        questId = definition.questId,
        introduction = definition.introduction,
        job = table.freeze(definition.job),
    })
end

--[[
    Chapter I's three keep their exact ids, jobs, titles and boons -- this
    module inherits those definitions rather than restating them, so
    nothing about the town that exists today changes.
]]
local ORDER = table.freeze({
    "npc_tomas_reed",
    "npc_pip_wren",
    "npc_ena_moss",
    -- Ironroot Delve, chapter II
    "npc_hesper_vane",
    "npc_odell_crane",
    "npc_junie_falk",
    "npc_bartram_hoke",
    -- Mireglass Fen, chapter III
    "npc_saoirse_quill",
    "npc_wren_dabbler",
    "npc_marek_still",
    "npc_lissen_ford",
})

local DEFINITIONS: { [string]: Resident } = {
    npc_tomas_reed = resident({
        id = "npc_tomas_reed",
        displayName = "TOMAS",
        fullName = "Tomas Reed",
        homeRegion = "region_bramblewake",
        arrivesInChapter = 1,
        questId = "quest_first_craft",
        introduction = "Keeps the inn and the tool bench, and patches what the night breaks.",
        job = {
            residentId = "npc_tomas_reed",
            buildingId = "building_inn",
            title = "QUARTERMASTER",
            boon = "dawn_repair",
            boonLabel = "TOMAS PATCHES THE WORST-HIT BUILDING",
        },
    }),
    npc_pip_wren = resident({
        id = "npc_pip_wren",
        displayName = "PIP",
        fullName = "Pip Wren",
        homeRegion = "region_bramblewake",
        arrivesInChapter = 1,
        questId = "quest_survive_three_nights",
        introduction = "Runs the roads and posts what is coming before it arrives.",
        job = {
            residentId = "npc_pip_wren",
            buildingId = "building_town_board",
            title = "COURIER",
            boon = "night_forewarning",
            boonLabel = "PIP POSTS WORD OF THE COMING NIGHT",
        },
    }),
    npc_ena_moss = resident({
        id = "npc_ena_moss",
        displayName = "ENA",
        fullName = "Ena Moss",
        homeRegion = "region_bramblewake",
        arrivesInChapter = 1,
        questId = "quest_bramblewake_veteran",
        introduction = "Keeps seed and spark, and decides what the town plants next.",
        job = {
            residentId = "npc_ena_moss",
            buildingId = "building_workbench",
            title = "SEEDKEEPER",
            boon = "lantern_reserve",
            boonLabel = "ENA BANKS A SPARK RESERVE FOR THE LANTERN",
        },
    }),

    -- Ironroot Delve. Four people who worked a mine that stopped being a
    -- mine, and who each kept a different piece of it.
    npc_hesper_vane = resident({
        id = "npc_hesper_vane",
        displayName = "HESPER",
        fullName = "Hesper Vane",
        homeRegion = "region_ironroot",
        arrivesInChapter = 2,
        questId = "quest_delve_smith",
        introduction = "Shift smith. Came up with her tools and somebody else's tally book.",
        job = {
            residentId = "npc_hesper_vane",
            buildingId = "building_forge",
            title = "SHIFT SMITH",
            boon = "dawn_whetstone",
            boonLabel = "HESPER WHETS THE WORST-WORN GEAR IN TOWN",
        },
    }),
    npc_odell_crane = resident({
        id = "npc_odell_crane",
        displayName = "ODELL",
        fullName = "Odell Crane",
        homeRegion = "region_ironroot",
        arrivesInChapter = 2,
        questId = "quest_rail_keeper",
        introduction = "Ran the cart lines. Still flinches when a bell rings twice.",
        job = {
            residentId = "npc_odell_crane",
            buildingId = "building_market",
            title = "RAIL KEEPER",
            boon = "dawn_haulage",
            boonLabel = "ODELL HAULS AN EXTRA BUNDLE IN BEFORE DAWN",
        },
    }),
    npc_junie_falk = resident({
        id = "npc_junie_falk",
        displayName = "JUNIE",
        fullName = "Junie Falk",
        homeRegion = "region_ironroot",
        arrivesInChapter = 2,
        questId = "quest_lamp_trimmer",
        introduction = "Trimmed lamps below. Will not sit with her back to a dark doorway.",
        job = {
            residentId = "npc_junie_falk",
            buildingId = "building_first_lantern",
            title = "LAMP TRIMMER",
            boon = "lantern_trim",
            boonLabel = "JUNIE TRIMS THE FIRST LANTERN BEFORE NIGHTFALL",
        },
    }),
    npc_bartram_hoke = resident({
        id = "npc_bartram_hoke",
        displayName = "BARTRAM",
        fullName = "Bartram Hoke",
        homeRegion = "region_ironroot",
        arrivesInChapter = 2,
        questId = "quest_deep_cook",
        introduction = "Fed a hundred miners on nothing. Cooks like the pantry is still short.",
        job = {
            residentId = "npc_bartram_hoke",
            buildingId = "building_kitchen",
            title = "PIT COOK",
            boon = "dawn_ration",
            boonLabel = "BARTRAM SETS OUT A HOT RATION AT DAWN",
        },
    }),

    -- Mireglass Fen. Four people from a country that drowned slowly
    -- enough for everyone to argue about whether it was drowning.
    npc_saoirse_quill = resident({
        id = "npc_saoirse_quill",
        displayName = "SAOIRSE",
        fullName = "Saoirse Quill",
        homeRegion = "region_mireglass",
        arrivesInChapter = 3,
        questId = "quest_ferry_ledger",
        introduction = "Kept the ferry ledger. Knows exactly how many did not come back.",
        job = {
            residentId = "npc_saoirse_quill",
            buildingId = "building_archive",
            title = "LEDGER KEEPER",
            boon = "dawn_accounting",
            boonLabel = "SAOIRSE FINDS A MISFILED BUNDLE IN THE STORES",
        },
    }),
    npc_wren_dabbler = resident({
        id = "npc_wren_dabbler",
        displayName = "DABBLER",
        fullName = "Wren Dabbler",
        homeRegion = "region_mireglass",
        arrivesInChapter = 3,
        questId = "quest_reed_weaver",
        introduction = "Weaves reed into everything. Left a figure for every house the water took.",
        job = {
            residentId = "npc_wren_dabbler",
            buildingId = "building_celebration_stage",
            title = "REED WEAVER",
            boon = "dawn_decoration",
            boonLabel = "DABBLER LEAVES A WOVEN CHARM ON A TOWN DOOR",
        },
    }),
    npc_marek_still = resident({
        id = "npc_marek_still",
        displayName = "MAREK",
        fullName = "Marek Still",
        homeRegion = "region_mireglass",
        arrivesInChapter = 3,
        questId = "quest_glass_reader",
        introduction = "Read mireglass for a living. Warns people about their own reflections.",
        job = {
            residentId = "npc_marek_still",
            buildingId = "building_watchtower",
            title = "GLASS READER",
            boon = "night_tell",
            boonLabel = "MAREK NAMES A TELL BEFORE THE NIGHT USES IT",
        },
    }),
    npc_lissen_ford = resident({
        id = "npc_lissen_ford",
        displayName = "LISSEN",
        fullName = "Lissen Ford",
        homeRegion = "region_mireglass",
        arrivesInChapter = 3,
        questId = "quest_fen_healer",
        introduction = "Pulled people out of the water for years. Still counts heads at dusk.",
        job = {
            residentId = "npc_lissen_ford",
            buildingId = "building_guardhouse",
            title = "FEN HEALER",
            boon = "dawn_recovery",
            boonLabel = "LISSEN GETS ONE INJURED RESIDENT BACK ON THEIR FEET",
        },
    }),
}

ResidentRoster.Order = ORDER

function ResidentRoster.get(residentId: any): Resident?
    return if type(residentId) == "string" then DEFINITIONS[residentId] else nil
end

function ResidentRoster.require(residentId: string): Resident
    local definition = DEFINITIONS[residentId]
    assert(definition ~= nil, string.format("unknown resident ID %q", residentId))
    return definition
end

function ResidentRoster.list(): { Resident }
    local result: { Resident } = {}
    for _, residentId in ORDER do
        table.insert(result, DEFINITIONS[residentId])
    end
    return result
end

--[[
    Who is in town at a given chapter. Chapter defaults to one, which is
    what every caller that predates the roster means, so nothing changes
    for a save that has not left Bramblewake.
]]
function ResidentRoster.idsForChapter(chapter: number?): { string }
    local reached = math.max(1, math.floor(tonumber(chapter) or 1))
    local ids: { string } = {}
    for _, residentId in ORDER do
        if DEFINITIONS[residentId].arrivesInChapter <= reached then
            table.insert(ids, residentId)
        end
    end
    return ids
end

function ResidentRoster.jobs(): { [string]: Job }
    local jobs: { [string]: Job } = {}
    for _, residentId in ORDER do
        jobs[residentId] = DEFINITIONS[residentId].job
    end
    return jobs
end

function ResidentRoster.questIdFor(residentId: any): string?
    local definition = ResidentRoster.get(residentId)
    return if definition == nil then nil else definition.questId
end

return table.freeze(ResidentRoster)
