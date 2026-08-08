--!strict
--[[
	Every string a player reads, in one place.

	Milestone 13 asks for localization source coverage so that "finalize
	supported languages from localization QA capacity" is a capacity decision
	rather than an archaeology project. A capacity decision needs a number, and
	the number is the size of this table.

	Keys are lowercase and dotted, and the first segment names the surface the
	string is read on rather than the file it happens to live in, because a
	refactor moves a file and does not move a label off a screen.

	`get` throws on a key nobody defined, and that is the whole of its error
	handling on purpose. The alternative is returning the key, or returning an
	empty string, and both of those ship: a label reading `hud.close` looks like
	a bug somebody will file, and a label reading nothing looks like a design.
	This project has paid four times for a silent fallback hiding a gap, so a
	missing string fails where it is asked for.

	`scripts/validate_localization.py` holds this table and the source against
	each other in both directions: a key nothing reads is a string a translator
	is paid for and nobody sees, and a key nothing defines is a label wired to
	nothing.
]]

local Strings = {}

local SOURCE: { [string]: string } = {
    ["hud.day_morning"] = "DAY · MORNING",
    ["hud.first_light_1_8"] = "FIRST LIGHT · 1 / 8",
    ["hud.free_mara"] = "FREE MARA",
    ["hud.follow_the_lantern_path"] = "Follow the lantern path.",
    ["hud.mara_follow_the_light"] = "Mara: Follow the light.",
    ["hud.heartwood_0"] = "HEARTWOOD · 0",
    ["hud.health_100_100"] = "HEALTH · 100 / 100",
    ["hud.stamina_100"] = "STAMINA · 100",
    ["hud.light_100"] = "LIGHT · 100%",
    ["hud.bramblewake_blackout_stage_1_4"] = "BRAMBLEWAKE BLACKOUT · STAGE 1/4",
    ["hud.rootfire_relay_0_3"] = "ROOTFIRE RELAY · 0/3",
    ["hud.old_growth_phase_1_3"] = "OLD GROWTH · PHASE 1/3",
    ["hud.exposed_strike_the_amber_heart"] = "EXPOSED · STRIKE THE AMBER HEART",
    ["hud.ahead_14m_23s"] = "AHEAD · 14m · 23s",
    ["hud.dodge_out_of_the_ring_0"] = "DODGE OUT OF THE RING · 0.9s",
    ["hud.downed_crawl_toward_light"] = "DOWNED · CRAWL TOWARD LIGHT",
    ["hud.help_signal_active_no_ally_nearby"] = "HELP SIGNAL ACTIVE · NO ALLY NEARBY",
    ["hud.find"] = "FIND",
    ["hud.strike"] = "STRIKE",
    ["hud.dodge"] = "DODGE",
    ["hud.ability"] = "ABILITY",
    ["hud.hound"] = "HOUND",
    ["hud.call"] = "CALL",
    ["hud.close"] = "CLOSE",
    ["hud.compact"] = "COMPACT",
    ["hud.profession"] = "PROFESSION",
    ["hud.field_book"] = "FIELD BOOK",
    ["hud.choose_your_profession"] = "CHOOSE YOUR PROFESSION",
    ["hud.switch_freely_in_emberhollow_every_traveler"] = "Switch freely in Emberhollow. Every traveler keeps core combat, building, and rescue.",
    ["hud.field_book_recipes_quests_mastery"] = "FIELD BOOK · RECIPES · QUESTS · MASTERY",
    ["hud.loading_field_notes"] = "Loading field notes…",
    ["hud.whet"] = "WHET",
    ["hud.the_outfitter"] = "THE OUTFITTER",
    ["hud.cosmetic_only_abilities_are_earned_in"] = "COSMETIC ONLY — ABILITIES ARE EARNED IN PLAY",
    ["hud.nothing_is_on_the_rail_yet"] = "NOTHING IS ON THE RAIL YET.",
    ["hud.your_wardrobe"] = "YOUR WARDROBE",
    ["hud.wear"] = "WEAR",
    ["hud.departure"] = "DEPARTURE",
    ["hud.stand_on_the_platform_to_depart"] = "STAND ON THE PLATFORM TO DEPART",
    ["hud.travelling_alone"] = "TRAVELLING ALONE",
    ["hud.rejoin"] = "REJOIN",
    ["hud.join"] = "JOIN",
    ["hud.decline"] = "DECLINE",
    ["hud.invite"] = "INVITE",
    ["hud.leave"] = "LEAVE",
    ["hud.nothing_is_priced_yet_n_waiting"] = "NOTHING IS PRICED YET — %d WAITING ON THE TILL.",
    ["hud.your_party_of_n_is_still"] = "YOUR PARTY OF %d IS STILL OUT THERE",
    ["hud.party_of_n_you_lead"] = "PARTY OF %d · YOU LEAD",
    ["hud.party_of_n_led_by_n"] = "PARTY OF %d · LED BY %s",
    ["hud.someone"] = "SOMEONE",
    ["hud.departing_in_n"] = "DEPARTING IN %d",
    ["hud.party_of_n_stand_on_the"] = "PARTY OF %d * STAND ON THE PLATFORM",
    ["hud.rooted_ns_stamina_n"] = "ROOTED %.1fs · STAMINA %d",
    ["hud.drowsy_ns_stamina_n"] = "DROWSY %.1fs · STAMINA %d",
    ["hud.low_stamina_n"] = "LOW STAMINA · %d",
    ["hud.stay"] = "STAY",
    ["hud.follow"] = "FOLLOW",
    ["hud.role"] = "ROLE · ",
    ["hud.recipes"] = "RECIPES",
    ["hud.nothing_learned_yet_find_a_workbench"] = "Nothing learned yet — find a workbench.",
    ["hud.quests"] = "QUESTS",
    ["hud.no_open_quests"] = "No open quests.",
    ["hud.claimed"] = "CLAIMED",
    ["hud.memory_archive_n_n_recovered"] = "MEMORY ARCHIVE · %d / %d RECOVERED",
    ["hud.residents"] = "RESIDENTS",
    ["hud.you_are_a_guest_in_n"] = "You are a guest in %s's Emberhollow — your help carries, your damage doesn't.",
    ["hud.resting_check_on_them"] = "RESTING — check on them",
    ["hud.decorations_placed_n_n_marked_spots"] = "Decorations placed · %d / %d — marked spots around town take materials.",
    ["hud.profession_mastery"] = "PROFESSION MASTERY",
    ["hud.loadout"] = "LOADOUT",
    ["hud.nothing_equipped_yet_craft_gear_at"] = "Nothing equipped yet — craft gear at the workbenches.",
    ["hud.equip"] = "EQUIP",
    ["hud.downed"] = "DOWNED",
    ["hud.expand"] = "EXPAND",
    ["hud.dusk"] = "DUSK",
    ["hud.night"] = "NIGHT",
    ["hud.reveal"] = "REVEAL",
    ["hud.blackout_n_n"] = "BLACKOUT · %02d:%02d",
    ["hud.blackout_overtime"] = "BLACKOUT · OVERTIME",
    ["hud.dawn_chapter_i"] = "DAWN · CHAPTER I",
    ["hud.held"] = "HELD",
    ["hud.left"] = "LEFT",
    ["hud.dawn_first_light"] = "DAWN · FIRST LIGHT",
    ["hud.practice"] = "PRACTICE · ",
    ["hud.bramblewake_blackout_n_n_n"] = "BRAMBLEWAKE BLACKOUT · %s · %d/%d",
    ["hud.stage"] = "STAGE",
    ["hud.carry_rootfire_ns_n_n_n"] = "CARRY ROOTFIRE %.1fs → %s · %d/%d",
    ["hud.next_root"] = "NEXT ROOT",
    ["hud.take_rootfire_n_n_n"] = "TAKE ROOTFIRE → %s · %d/%d",
    ["hud.rooted_walls_cleanse_old_growth"] = "ROOTED WALLS · CLEANSE OLD GROWTH",
    ["hud.warden_s_seal_cleanse_or_break"] = "WARDEN'S SEAL · CLEANSE OR BREAK ANTLERS",
    ["hud.vote_farmland_wild_shared_agroforest"] = "VOTE: FARMLAND · WILD · SHARED AGROFOREST",
    ["hud.vote_recorded_waiting_for_active_travelers"] = "VOTE RECORDED · WAITING FOR ACTIVE TRAVELERS",
    ["hud.warden_stag"] = "WARDEN STAG",
    ["common.old_growth"] = "OLD GROWTH",
    ["hud.cleansed_continue_to_wayhome"] = "CLEANSED · CONTINUE TO WAYHOME",
    ["hud.heart_exposed_strike_the_memory_seal"] = "HEART EXPOSED · STRIKE THE MEMORY SEAL",
    ["hud.roots_n_n_preserve_cleanse_antlers"] = "ROOTS %d/%d · PRESERVE: CLEANSE · ANTLERS %d/2",
    ["hud.fire_ns_reach_the_root_heart"] = "FIRE %.1fs · REACH THE ROOT HEART",
    ["hud.shielded_take_lantern_fire"] = "SHIELDED · TAKE LANTERN FIRE",
    ["hud.threat"] = "THREAT",
    ["hud.attack"] = "ATTACK",
    ["hud.lane"] = "LANE",
    ["hud.ring"] = "RING",
    ["hud.move"] = "MOVE",
    ["hud.help_active_n_nm_n"] = "HELP ACTIVE · %s %dm · %s",
    ["hud.unknown"] = "UNKNOWN",
    ["hud.ally"] = "ALLY",
    ["hud.running"] = "RUNNING",
    ["hud.first_light"] = "FIRST LIGHT",
    ["hud.heartwood_nn"] = "HEARTWOOD · %d%s",
    ["hud.health_n_n"] = "HEALTH · %d / %d",
    ["client.the_first_night"] = "THE FIRST NIGHT",
    ["client.keep_the_light_alive"] = "KEEP THE LIGHT ALIVE",
    ["client.night_n_n"] = "NIGHT %d · %s",
    ["client.the_blackout"] = "THE BLACKOUT",
    ["client.carry_the_rootfire"] = "CARRY THE ROOTFIRE",
    ["client.strike_the_amber_heart"] = "STRIKE THE AMBER HEART",
    ["client.the_warden_stag"] = "THE WARDEN STAG",
    ["client.cleanse_the_living_roots"] = "CLEANSE THE LIVING ROOTS",
    ["objective.objective"] = "OBJECTIVE",
}

function Strings.get(key: string): string
    local value = SOURCE[key]
    if value == nil then
        error(`Strings.get: no source string for key "{key}"`, 2)
    end
    return value
end

-- The count a language decision is made on. Exposed rather than derived at the
-- call site so nothing has to walk the table to answer "how big is this".
function Strings.count(): number
    local total = 0
    for _ in SOURCE do
        total += 1
    end
    return total
end

function Strings.keys(): { string }
    local keys = {}
    for key in SOURCE do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

return Strings
