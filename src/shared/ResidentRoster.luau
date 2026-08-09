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

local Strings = require("./Strings")

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
    --[[
        Postgame only. A resident with this arrives with chapter seven and
        only for the endings named -- which is how the town can be
        different afterwards without the roster growing a second copy of
        itself for each ending.
    ]]
    requiresEnding: { string }?,
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
        requiresEnding = if definition.requiresEnding ~= nil
            then table.freeze(table.clone(definition.requiresEnding))
            else nil,
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
    -- Tempest Reach, chapter IV
    "npc_isolde_maren",
    "npc_cass_pell",
    "npc_alder_kine",
    "npc_nell_barrow",
    -- Frostmere Vale, chapter V
    "npc_anselm_rill",
    "npc_ivy_thorn",
    "npc_halvard_sunn",
    "npc_maud_ferrow",
    -- Cinderfall Crown, chapter VI
    "npc_sabine_ash",
    "npc_theo_marl",
    "npc_delia_kass",
    "npc_bran_holt",
    -- After the Hollow, chapter VII
    "npc_orin_vale",
    "npc_signe_marr",
    "npc_ruth_calder",
    "npc_edda_pyne",
})

local DEFINITIONS: { [string]: Resident } = {
    npc_tomas_reed = resident({
        id = "npc_tomas_reed",
        displayName = Strings.get("resident.tomas"),
        fullName = "Tomas Reed",
        homeRegion = "region_bramblewake",
        arrivesInChapter = 1,
        questId = "quest_first_craft",
        introduction = Strings.get("resident.keeps_the_inn_and_the_tool"),
        job = {
            residentId = "npc_tomas_reed",
            buildingId = "building_inn",
            title = Strings.get("world.quartermaster"),
            boon = "dawn_repair",
            boonLabel = Strings.get("resident.tomas_patches_the_worst_hit_building"),
        },
    }),
    npc_pip_wren = resident({
        id = "npc_pip_wren",
        displayName = "PIP",
        fullName = "Pip Wren",
        homeRegion = "region_bramblewake",
        arrivesInChapter = 1,
        questId = "quest_survive_three_nights",
        introduction = Strings.get("resident.runs_the_roads_and_posts_what"),
        job = {
            residentId = "npc_pip_wren",
            buildingId = "building_town_board",
            title = Strings.get("world.courier"),
            boon = "night_forewarning",
            boonLabel = Strings.get("resident.pip_posts_word_of_the_coming"),
        },
    }),
    npc_ena_moss = resident({
        id = "npc_ena_moss",
        displayName = "ENA",
        fullName = "Ena Moss",
        homeRegion = "region_bramblewake",
        arrivesInChapter = 1,
        questId = "quest_bramblewake_veteran",
        introduction = Strings.get("resident.keeps_seed_and_spark_and_decides"),
        job = {
            residentId = "npc_ena_moss",
            buildingId = "building_workbench",
            title = Strings.get("world.seedkeeper"),
            boon = "lantern_reserve",
            boonLabel = Strings.get("resident.ena_banks_a_spark_reserve_for"),
        },
    }),

    -- Ironroot Delve. Four people who worked a mine that stopped being a
    -- mine, and who each kept a different piece of it.
    npc_hesper_vane = resident({
        id = "npc_hesper_vane",
        displayName = Strings.get("resident.hesper"),
        fullName = "Hesper Vane",
        homeRegion = "region_ironroot",
        arrivesInChapter = 2,
        questId = "quest_delve_smith",
        introduction = Strings.get("resident.shift_smith_came_up_with_her"),
        job = {
            residentId = "npc_hesper_vane",
            buildingId = "building_forge",
            title = Strings.get("world.shift_smith"),
            boon = "dawn_whetstone",
            boonLabel = Strings.get("resident.hesper_whets_the_worst_worn_gear"),
        },
    }),
    npc_odell_crane = resident({
        id = "npc_odell_crane",
        displayName = Strings.get("resident.odell"),
        fullName = "Odell Crane",
        homeRegion = "region_ironroot",
        arrivesInChapter = 2,
        questId = "quest_rail_keeper",
        introduction = Strings.get("resident.ran_the_cart_lines_still_flinches"),
        job = {
            residentId = "npc_odell_crane",
            buildingId = "building_market",
            title = Strings.get("world.rail_keeper"),
            boon = "dawn_haulage",
            boonLabel = Strings.get("resident.odell_hauls_an_extra_bundle_in"),
        },
    }),
    npc_junie_falk = resident({
        id = "npc_junie_falk",
        displayName = Strings.get("resident.junie"),
        fullName = "Junie Falk",
        homeRegion = "region_ironroot",
        arrivesInChapter = 2,
        questId = "quest_lamp_trimmer",
        introduction = Strings.get("resident.trimmed_lamps_below_will_not_sit"),
        job = {
            residentId = "npc_junie_falk",
            buildingId = "building_first_lantern",
            title = Strings.get("world.lamp_trimmer"),
            boon = "lantern_trim",
            boonLabel = Strings.get("resident.junie_trims_the_first_lantern_before"),
        },
    }),
    npc_bartram_hoke = resident({
        id = "npc_bartram_hoke",
        displayName = Strings.get("resident.bartram"),
        fullName = "Bartram Hoke",
        homeRegion = "region_ironroot",
        arrivesInChapter = 2,
        questId = "quest_deep_cook",
        introduction = Strings.get("resident.fed_a_hundred_miners_on_nothing"),
        job = {
            residentId = "npc_bartram_hoke",
            buildingId = "building_kitchen",
            title = Strings.get("world.pit_cook"),
            boon = "dawn_ration",
            boonLabel = Strings.get("resident.bartram_sets_out_a_hot_ration"),
        },
    }),

    -- Mireglass Fen. Four people from a country that drowned slowly
    -- enough for everyone to argue about whether it was drowning.
    npc_saoirse_quill = resident({
        id = "npc_saoirse_quill",
        displayName = Strings.get("resident.saoirse"),
        fullName = Strings.get("resident.saoirse_quill"),
        homeRegion = "region_mireglass",
        arrivesInChapter = 3,
        questId = "quest_ferry_ledger",
        introduction = Strings.get("resident.kept_the_ferry_ledger_knows_exactly"),
        job = {
            residentId = "npc_saoirse_quill",
            buildingId = "building_archive",
            title = Strings.get("world.ledger_keeper"),
            boon = "dawn_accounting",
            boonLabel = Strings.get("resident.saoirse_finds_a_misfiled_bundle_in"),
        },
    }),
    npc_wren_dabbler = resident({
        id = "npc_wren_dabbler",
        displayName = Strings.get("resident.dabbler"),
        fullName = "Wren Dabbler",
        homeRegion = "region_mireglass",
        arrivesInChapter = 3,
        questId = "quest_reed_weaver",
        introduction = Strings.get("resident.weaves_reed_into_everything_left_a"),
        job = {
            residentId = "npc_wren_dabbler",
            buildingId = "building_celebration_stage",
            title = Strings.get("world.reed_weaver"),
            boon = "dawn_decoration",
            boonLabel = Strings.get("resident.dabbler_leaves_a_woven_charm_on"),
        },
    }),
    npc_marek_still = resident({
        id = "npc_marek_still",
        displayName = Strings.get("resident.marek"),
        fullName = "Marek Still",
        homeRegion = "region_mireglass",
        arrivesInChapter = 3,
        questId = "quest_glass_reader",
        introduction = Strings.get("resident.read_mireglass_for_a_living_warns"),
        job = {
            residentId = "npc_marek_still",
            buildingId = "building_watchtower",
            title = Strings.get("world.glass_reader"),
            boon = "night_tell",
            boonLabel = Strings.get("resident.marek_names_a_tell_before_the"),
        },
    }),
    npc_lissen_ford = resident({
        id = "npc_lissen_ford",
        displayName = Strings.get("resident.lissen"),
        fullName = "Lissen Ford",
        homeRegion = "region_mireglass",
        arrivesInChapter = 3,
        questId = "quest_fen_healer",
        introduction = Strings.get("resident.pulled_people_out_of_the_water"),
        job = {
            residentId = "npc_lissen_ford",
            buildingId = "building_guardhouse",
            title = Strings.get("world.fen_healer"),
            boon = "dawn_recovery",
            boonLabel = Strings.get("resident.lissen_gets_one_injured_resident_back"),
        },
    }),
    npc_isolde_maren = resident({
        id = "npc_isolde_maren",
        displayName = Strings.get("resident.isolde"),
        fullName = "Isolde Maren",
        homeRegion = "region_tempest",
        arrivesInChapter = 4,
        questId = "quest_signal_watch",
        introduction = Strings.get("resident.kept_a_light_burning_for_ships"),
        job = {
            residentId = "npc_isolde_maren",
            buildingId = "building_signal_house",
            title = Strings.get("world.signal_keeper"),
            boon = "night_signal",
            boonLabel = Strings.get("resident.isolde_signals_the_hour_before_the"),
        },
    }),
    npc_cass_pell = resident({
        id = "npc_cass_pell",
        displayName = Strings.get("resident.cass"),
        fullName = "Cass Pell",
        homeRegion = "region_tempest",
        arrivesInChapter = 4,
        questId = "quest_ropewalk_hands",
        introduction = Strings.get("resident.laid_rope_for_a_fleet_that"),
        job = {
            residentId = "npc_cass_pell",
            buildingId = "building_ropewalk",
            title = Strings.get("world.ropemaker"),
            boon = "dawn_rigging",
            boonLabel = Strings.get("resident.cass_re_rigs_what_the_night"),
        },
    }),
    npc_alder_kine = resident({
        id = "npc_alder_kine",
        displayName = Strings.get("resident.alder"),
        fullName = "Alder Kine",
        homeRegion = "region_tempest",
        arrivesInChapter = 4,
        questId = "quest_harbour_ledger",
        introduction = Strings.get("resident.ran_a_harbour_s_books_until"),
        job = {
            residentId = "npc_alder_kine",
            buildingId = "building_trade_post",
            title = Strings.get("world.harbourmaster"),
            boon = "dawn_tally",
            boonLabel = Strings.get("resident.alder_finds_one_more_of_something"),
        },
    }),
    npc_nell_barrow = resident({
        id = "npc_nell_barrow",
        displayName = Strings.get("resident.nell"),
        fullName = "Nell Barrow",
        homeRegion = "region_tempest",
        arrivesInChapter = 4,
        questId = "quest_salvage_runs",
        introduction = Strings.get("resident.dives_wrecks_counts_trips_out_and"),
        job = {
            residentId = "npc_nell_barrow",
            buildingId = "building_waterworks",
            title = Strings.get("world.salvage_diver"),
            boon = "dawn_salvage",
            boonLabel = Strings.get("resident.nell_brings_up_something_the_night"),
        },
    }),
    npc_anselm_rill = resident({
        id = "npc_anselm_rill",
        displayName = Strings.get("resident.anselm"),
        fullName = "Anselm Rill",
        homeRegion = "region_frostmere",
        arrivesInChapter = 5,
        questId = "quest_bell_keeping",
        introduction = Strings.get("resident.rang_for_a_valley_that_had"),
        job = {
            residentId = "npc_anselm_rill",
            buildingId = "building_bell_tower",
            title = Strings.get("world.bellkeeper"),
            boon = "night_warning_bell",
            boonLabel = Strings.get("resident.anselm_rings_the_hour_and_nothing"),
        },
    }),
    npc_ivy_thorn = resident({
        id = "npc_ivy_thorn",
        displayName = "IVY",
        fullName = "Ivy Thorn",
        homeRegion = "region_frostmere",
        arrivesInChapter = 5,
        questId = "quest_vale_nursing",
        introduction = Strings.get("resident.nursed_an_abbey_through_a_winter"),
        job = {
            residentId = "npc_ivy_thorn",
            buildingId = "building_infirmary",
            title = Strings.get("world.infirmarian"),
            boon = "dawn_convalescence",
            boonLabel = Strings.get("resident.ivy_gets_two_injured_residents_back"),
        },
    }),
    npc_halvard_sunn = resident({
        id = "npc_halvard_sunn",
        displayName = Strings.get("resident.halvard"),
        fullName = "Halvard Sunn",
        homeRegion = "region_frostmere",
        arrivesInChapter = 5,
        questId = "quest_cold_stores",
        introduction = Strings.get("resident.held_a_cold_store_shut_through"),
        job = {
            residentId = "npc_halvard_sunn",
            buildingId = "building_cold_store",
            title = Strings.get("world.storekeeper"),
            boon = "storage_headroom",
            boonLabel = Strings.get("resident.halvard_finds_room_for_what_would"),
        },
    }),
    npc_maud_ferrow = resident({
        id = "npc_maud_ferrow",
        displayName = Strings.get("resident.maud"),
        fullName = "Maud Ferrow",
        homeRegion = "region_frostmere",
        arrivesInChapter = 5,
        questId = "quest_almshouse_doors",
        introduction = Strings.get("resident.gave_her_own_door_away_for"),
        job = {
            residentId = "npc_maud_ferrow",
            buildingId = "building_almshouse",
            title = Strings.get("world.almoner"),
            boon = "dawn_shelter",
            boonLabel = Strings.get("resident.maud_finds_a_bed_for_whoever"),
        },
    }),
    npc_sabine_ash = resident({
        id = "npc_sabine_ash",
        displayName = Strings.get("resident.sabine"),
        fullName = "Sabine Ash",
        homeRegion = "region_cinderfall",
        arrivesInChapter = 6,
        questId = "quest_glass_hands",
        introduction = Strings.get("resident.made_casts_for_the_crown_s"),
        job = {
            residentId = "npc_sabine_ash",
            buildingId = "building_glassworks",
            title = Strings.get("world.glasswright"),
            boon = "dawn_glazing",
            boonLabel = Strings.get("resident.sabine_reglazes_what_the_night_put"),
        },
    }),
    npc_theo_marl = resident({
        id = "npc_theo_marl",
        displayName = Strings.get("resident.theo"),
        fullName = "Theo Marl",
        homeRegion = "region_cinderfall",
        arrivesInChapter = 6,
        questId = "quest_kept_record",
        introduction = Strings.get("resident.copied_the_official_names_for_thirty"),
        job = {
            residentId = "npc_theo_marl",
            buildingId = "building_records_office",
            title = Strings.get("world.recordkeeper"),
            boon = "dawn_ledger",
            boonLabel = Strings.get("resident.theo_finds_something_in_the_record"),
        },
    }),
    npc_delia_kass = resident({
        id = "npc_delia_kass",
        displayName = Strings.get("resident.delia"),
        fullName = "Delia Kass",
        homeRegion = "region_cinderfall",
        arrivesInChapter = 6,
        questId = "quest_named_stones",
        introduction = Strings.get("resident.knows_which_of_the_crown_s"),
        job = {
            residentId = "npc_delia_kass",
            buildingId = "building_memorial_hall",
            title = Strings.get("world.memorialist"),
            boon = "dawn_remembrance",
            boonLabel = Strings.get("resident.delia_puts_a_name_on_something"),
        },
    }),
    npc_bran_holt = resident({
        id = "npc_bran_holt",
        displayName = Strings.get("resident.bran"),
        fullName = "Bran Holt",
        homeRegion = "region_cinderfall",
        arrivesInChapter = 6,
        questId = "quest_long_timber",
        introduction = Strings.get("resident.cut_beams_for_a_city_that"),
        job = {
            residentId = "npc_bran_holt",
            buildingId = "building_sawmill",
            title = Strings.get("world.timberwright"),
            boon = "dawn_framing",
            boonLabel = Strings.get("resident.bran_frames_up_a_building_a"),
        },
    }),
    --[[
        Orin Vale, who has been the answer to the archive's question since
        the first ten fragments shipped. He comes up only if the light was
        put out or broken up -- if it was kept, somebody has to be down
        there tending it, and it is him. That is the postgame the endings
        earn, and it is one field rather than three copies of the roster.
    ]]
    npc_orin_vale = resident({
        id = "npc_orin_vale",
        displayName = Strings.get("resident.orin"),
        fullName = "Orin Vale",
        homeRegion = "region_hollow",
        arrivesInChapter = 7,
        questId = "quest_keepers_return",
        introduction = Strings.get("resident.the_keeper_whose_trail_runs_through"),
        requiresEnding = { "ending_ended", "ending_shared" },
        job = {
            residentId = "npc_orin_vale",
            buildingId = "building_lamp_house",
            title = Strings.get("world.lantern_keeper"),
            boon = "night_keepers_watch",
            boonLabel = Strings.get("resident.orin_keeps_the_watch_he_kept"),
        },
    }),
    npc_signe_marr = resident({
        id = "npc_signe_marr",
        displayName = Strings.get("resident.signe"),
        fullName = "Signe Marr",
        homeRegion = "region_hollow",
        arrivesInChapter = 7,
        questId = "quest_deep_water",
        introduction = Strings.get("resident.walked_out_of_the_hollow_behind"),
        job = {
            residentId = "npc_signe_marr",
            buildingId = "building_deep_well",
            title = Strings.get("world.wellkeeper"),
            boon = "dawn_draught",
            boonLabel = Strings.get("resident.signe_draws_something_clean_up_out"),
        },
    }),
    npc_ruth_calder = resident({
        id = "npc_ruth_calder",
        displayName = Strings.get("resident.ruth"),
        fullName = "Ruth Calder",
        homeRegion = "region_hollow",
        arrivesInChapter = 7,
        questId = "quest_full_house",
        introduction = Strings.get("resident.ran_the_town_meetings_before_there"),
        job = {
            residentId = "npc_ruth_calder",
            buildingId = "building_meeting_hall",
            title = Strings.get("world.speaker"),
            boon = "dawn_assembly",
            boonLabel = Strings.get("resident.ruth_gets_the_whole_town_pointed"),
        },
    }),
    npc_edda_pyne = resident({
        id = "npc_edda_pyne",
        displayName = Strings.get("resident.edda"),
        fullName = "Edda Pyne",
        homeRegion = "region_hollow",
        arrivesInChapter = 7,
        questId = "quest_last_ward",
        introduction = Strings.get("resident.built_traps_for_a_road_that"),
        job = {
            residentId = "npc_edda_pyne",
            buildingId = "building_trapworks",
            title = Strings.get("world.trapwright"),
            boon = "night_ward",
            boonLabel = Strings.get("resident.edda_s_wards_take_the_first"),
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
--[[
    Who is in town at a given point in the story. `ending` is the finale's
    own id and only matters to the postgame residents: one of them is in
    town or is not depending on what a party did with the light, and a
    caller that does not know the ending gets the town without them, which
    is the correct answer for every save that has not finished.
]]
function ResidentRoster.idsForChapter(chapter: number?, ending: string?): { string }
    local reached = math.max(1, math.floor(tonumber(chapter) or 1))
    local ids: { string } = {}
    for _, residentId in ORDER do
        local definition = DEFINITIONS[residentId]
        local allowed = true
        if definition.requiresEnding ~= nil then
            allowed = false
            for _, endingId in definition.requiresEnding do
                if endingId == ending then
                    allowed = true
                    break
                end
            end
        end
        if allowed and definition.arrivesInChapter <= reached then
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
