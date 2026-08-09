--!strict

local QuestCatalog = require("./QuestCatalog")
local ResidentRoster = require("./ResidentRoster")
local Strings = require("./Strings")

local ResidentDialogue = {}

export type Response = {
    message: string,
    questId: string,
    state: string,
}

--[[
    Names and quests come from the roster now; the two tables that used to
    hold them here were the first place the roster drifted, which is why
    it exists.
]]
--[[
    A resident's arc, in order, taken from the quest catalog rather than
    from a list here -- the roster names where an arc starts and the
    catalog's `requires` chain says what follows, so the two cannot drift
    into disagreeing about what somebody is asking for.
]]
local RESIDENT_ARCS: { [string]: { string } } = {}
local RESIDENT_NAMES: { [string]: string } = {}
for _, definition in ResidentRoster.list() do
    RESIDENT_ARCS[definition.id] = { definition.questId }
    RESIDENT_NAMES[definition.id] = definition.displayName
end
for _, quest in QuestCatalog.list() do
    local residentId = quest.residentId
    if residentId ~= nil and quest.requires ~= nil and RESIDENT_ARCS[residentId] ~= nil then
        table.insert(RESIDENT_ARCS[residentId], quest.id)
    end
end
table.freeze(RESIDENT_NAMES)

--[[
    What the residents brought back from their own regions say once their
    work is done. Chapter I's three answer to the town's decisions, which
    is handled below; these four-and-four answer to the places they came
    from, and each one is a person rather than a job title.
]]
--[[
    What each resident asks for, in their own words.

    The four asks built on `bramblewake_settlements` name the pouch on purpose.
    That signal counts settled Wayhome deliveries -- a trip that banks nothing
    records no settlement, because there is nothing to settle -- and every one
    of these lines used to describe it as a trip or a return, which promises
    credit for walking out and back empty-handed and never pays it. A player
    who does exactly what the words say and still reads 0/3 has been told the
    quest is broken by the quest itself.
]]
local GUIDANCE = table.freeze({
    npc_tomas_reed = Strings.get("resident.craft_one_useful_item_at_the"),
    npc_pip_wren = Strings.get("resident.help_the_lantern_road_survive_three"),
    npc_ena_moss = Strings.get("resident.bank_a_pouch_from_bramblewake_three"),
    npc_hesper_vane = Strings.get("resident.bring_me_gear_that_has_found"),
    npc_odell_crane = Strings.get("resident.fill_the_stores_sixty_of_anything"),
    npc_junie_falk = Strings.get("resident.keep_the_light_lit_for_seven"),
    npc_bartram_hoke = Strings.get("resident.raise_four_buildings_so_there_is"),
    npc_saoirse_quill = Strings.get("resident.bank_eight_pouches_from_bramblewake_and"),
    npc_wren_dabbler = Strings.get("resident.put_up_three_decorations_this_town"),
    npc_marek_still = Strings.get("resident.craft_six_things_and_look_twice"),
    npc_lissen_ford = Strings.get("resident.be_trusted_by_three_residents_check"),
    npc_isolde_maren = Strings.get("resident.keep_the_light_lit_fourteen_nights"),
    npc_cass_pell = Strings.get("resident.make_twenty_things_with_your_hands"),
    npc_alder_kine = Strings.get("resident.two_hundred_in_the_stores_i"),
    npc_nell_barrow = Strings.get("resident.fourteen_loads_banked_from_bramblewake_the"),
    npc_anselm_rill = Strings.get("resident.find_four_of_what_this_place"),
    npc_ivy_thorn = Strings.get("resident.be_trusted_by_eight_of_us"),
    npc_halvard_sunn = Strings.get("resident.close_every_chapter_a_store_is"),
    npc_maud_ferrow = Strings.get("resident.raise_twelve_buildings_twelve_doors_is"),
    npc_sabine_ash = Strings.get("resident.make_forty_things_not_one_of"),
    npc_theo_marl = Strings.get("resident.find_eight_of_what_this_world"),
    npc_delia_kass = Strings.get("resident.be_trusted_by_fourteen_of_us"),
    npc_bran_holt = Strings.get("resident.twenty_buildings_standing_i_will_cut"),
    npc_orin_vale = Strings.get("resident.close_all_seven_i_have_been"),
    npc_signe_marr = Strings.get("resident.four_hundred_in_the_stores_a"),
    npc_ruth_calder = Strings.get("resident.put_up_eight_decorations_nobody_meets"),
    npc_edda_pyne = Strings.get("resident.thirty_nights_i_will_have_the"),
})

local ARRIVAL_LINES = table.freeze({
    npc_hesper_vane = Strings.get("resident.a_tool_you_kept_sharp_is"),
    npc_odell_crane = Strings.get("resident.full_stores_and_a_quiet_bell"),
    npc_junie_falk = Strings.get("resident.seven_nights_lit_in_a_row"),
    npc_bartram_hoke = Strings.get("resident.a_real_kitchen_i_have_been"),
    npc_saoirse_quill = Strings.get("resident.names_out_and_names_back_and"),
    npc_wren_dabbler = Strings.get("resident.i_wove_one_for_every_house"),
    npc_marek_still = Strings.get("resident.look_twice_at_what_you_carry"),
    npc_lissen_ford = Strings.get("resident.every_head_counted_at_dusk_and"),
    npc_isolde_maren = Strings.get("resident.fourteen_nights_and_the_light_never"),
    npc_cass_pell = Strings.get("resident.good_rope_is_a_promise_you"),
    npc_alder_kine = Strings.get("resident.the_column_is_in_black_i"),
    npc_nell_barrow = Strings.get("resident.every_trip_out_came_back_that"),
    npc_anselm_rill = Strings.get("resident.four_things_this_place_remembers_and"),
    npc_ivy_thorn = Strings.get("resident.eight_names_all_of_them_answering"),
    npc_halvard_sunn = Strings.get("resident.nothing_left_open_and_the_store"),
    npc_maud_ferrow = Strings.get("resident.twelve_doors_and_not_one_of"),
    npc_sabine_ash = Strings.get("resident.forty_things_and_not_a_face"),
    npc_theo_marl = Strings.get("resident.eight_of_them_copied_out_properly"),
    npc_delia_kass = Strings.get("resident.fourteen_people_who_know_your_name"),
    npc_bran_holt = Strings.get("resident.twenty_standing_let_something_try_to"),
    npc_orin_vale = Strings.get("resident.all_seven_closed_and_i_am"),
    npc_signe_marr = Strings.get("resident.four_hundred_in_store_and_the"),
    npc_ruth_calder = Strings.get("resident.eight_things_somebody_chose_to_put"),
    npc_edda_pyne = Strings.get("resident.thirty_nights_and_the_wards_took"),
})

--[[
    Later stages of an arc speak for themselves rather than for the person
    -- the same resident is asking, so the name is already on the line,
    and what changes is what they want next. Stage one keeps GUIDANCE and
    ARRIVAL_LINES above, which players have already heard.
]]
local STAGE_GUIDANCE = table.freeze({
    quest_tomas_second_bench = Strings.get("resident.twelve_things_made_i_want_a"),
    quest_tomas_full_house = Strings.get("resident.ten_people_who_trust_you_then"),
    quest_pip_further_roads = Strings.get("resident.six_loads_banked_from_bramblewake_i"),
    quest_pip_every_night = Strings.get("resident.twenty_one_nights_posted_before_they"),
    quest_ena_first_growth = Strings.get("resident.five_things_planted_or_hung_this"),
    quest_ena_the_archive = Strings.get("resident.six_of_what_the_forest_kept"),
})

local STAGE_STORIES = table.freeze({
    quest_tomas_second_bench = Strings.get("resident.twelve_things_off_that_bench_and"),
    quest_tomas_full_house = Strings.get("resident.every_bed_full_and_i_know"),
    quest_pip_further_roads = Strings.get("resident.six_runs_out_and_six_back"),
    quest_pip_every_night = Strings.get("resident.twenty_one_nights_and_nobody_was"),
    quest_ena_first_growth = Strings.get("resident.five_things_planted_and_the_town"),
    quest_ena_the_archive = Strings.get("resident.six_of_them_in_order_it"),
})

local function questById(quests: any, questId: string): any
    if type(quests) ~= "table" then
        return nil
    end
    for _, quest in quests do
        if type(quest) == "table" and quest.id == questId then
            return quest
        end
    end
    return nil
end

local function completedStory(residentId: string, consequence: any, questId: string?): string
    -- A later stage of an arc has its own answer; only stage one falls
    -- back to the resident's arrival line.
    local staged = if questId ~= nil then STAGE_STORIES[questId] else nil
    if staged ~= nil then
        return staged
    end
    local arrival = ARRIVAL_LINES[residentId]
    if arrival ~= nil then
        return arrival
    end
    local decision = if type(consequence) == "table" then consequence.decision else nil
    local wardenOutcome = if type(consequence) == "table" then consequence.wardenOutcome else nil
    if residentId == "npc_tomas_reed" then
        if decision == "restore_farmland" then
            return Strings.get("resident.the_renewed_fields_need_tools_as")
        elseif decision == "wild_regrowth" then
            return Strings.get("resident.the_wild_grove_gives_less_on")
        elseif decision == "shared_agroforest" then
            return Strings.get("resident.forest_and_field_are_sharing_one")
        end
        return Strings.get("resident.one_good_tool_can_turn_a")
    elseif residentId == "npc_pip_wren" then
        if wardenOutcome == "preserved" then
            return Strings.get("resident.the_warden_left_old_tracks_open")
        elseif wardenOutcome == "scarred" then
            return Strings.get("resident.the_scarred_trails_shift_after_rain")
        elseif wardenOutcome == "harmed" then
            return Strings.get("resident.the_forest_is_watching_the_road")
        end
        return Strings.get("resident.three_dawns_prove_a_road_can")
    elseif decision == "restore_farmland" then
        return Strings.get("resident.i_saved_bramblewake_seed_for_these")
    elseif decision == "wild_regrowth" then
        return Strings.get("resident.the_grove_is_choosing_its_own")
    elseif decision == "shared_agroforest" then
        return Strings.get("resident.root_crop_and_lantern_are_growing")
    end
    return Strings.get("resident.every_safe_return_teaches_the_greenward")
end

function ResidentDialogue.respond(residentId: any, quests: any, consequence: any): Response?
    if type(residentId) ~= "string" then
        return nil
    end
    local arc = RESIDENT_ARCS[residentId]
    local residentName = RESIDENT_NAMES[residentId]
    if arc == nil or residentName == nil then
        return nil
    end
    --[[
        Whichever stage of their arc they are on: the first one they have
        not finished. A stage the caller knows nothing about is not the
        answer -- an arc can run ahead of what a snapshot carries -- so an
        unknown stage falls back to the last one there is a record for,
        and a resident who has been answered talks about what happened
        rather than repeating a request.
    ]]
    local questId: string? = nil
    local lastKnown: string? = nil
    for _, candidate in arc do
        local record = questById(quests, candidate)
        if record ~= nil then
            lastKnown = candidate
            if record.claimed ~= true then
                questId = candidate
                break
            end
        end
    end
    -- arc[1] always exists: the roster's own questId seeded it.
    local currentQuestId: string = questId or lastKnown or arc[1]

    local quest = questById(quests, currentQuestId)
    if quest == nil then
        return {
            message = residentName .. ": CHECK BACK WHEN THE GREENWARD RECORDS ARE READY.",
            questId = currentQuestId,
            state = "loading",
        }
    end
    if quest.claimed == true then
        return {
            message = residentName
                .. ": "
                .. completedStory(residentId, consequence, currentQuestId),
            questId = currentQuestId,
            state = "story",
        }
    end

    local current = math.max(0, math.floor(tonumber(quest.progress) or 0))
    local threshold = math.max(1, math.floor(tonumber(quest.threshold) or 1))
    -- The default names nothing in particular, because a resident with no
    -- authored ask used to borrow Ena's and tell a player to go to Bramblewake
    -- for a quest that counts something else entirely.
    local guidance = STAGE_GUIDANCE[currentQuestId]
        or GUIDANCE[residentId]
        or Strings.get("resident.there_is_work_here_when_you")
    return {
        message = string.format(
            Strings.get("resident.n_n_n_n_i_will"),
            residentName,
            guidance,
            math.min(current, threshold),
            threshold
        ),
        questId = currentQuestId,
        state = if current >= threshold then "ready" else "active",
    }
end

return table.freeze(ResidentDialogue)
