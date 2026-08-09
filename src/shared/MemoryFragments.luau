--!strict
--[[
    Memory fragments -- Bramblewake's chapter-one story, told in the world.

    The world bible's premise has never reached the player: light is memory
    made shareable, the Long Night is the accumulated remainder of memories a
    machine took because nobody could carry them, and the missing keeper Orin
    Vale pulled seven seals deliberately. The player has been carrying the
    eighth since the prologue without ever being told what it is.

    A fragment is a remembered moment held by a place. Recovering one is a
    single interaction on an object that is already standing there -- the four
    authored story vignettes and the four points of interest -- so this adds
    meaning to built content rather than new clutter to walk past.

    The arc is three acts:

      I.  What the forest kept -- the evacuation, told by the people who
          failed it. Each one lands on a resident who is standing in
          Emberhollow right now (Ena's orchard, Pip's grandfather's mill,
          Tomas's bridge), so the town stops being scenery.
      II. The keeper's trail -- Orin came through here, and what he was
          actually doing was neither theft nor madness.
      III. Your part in it -- why the eighth seal is yours, and where the
          trail goes next. Gated behind chapter one, because it is the
          answer, and because the last fragment sits at the exit gate: the
          player learns what Chapter II is on their way home from finishing
          Chapter I.

    Everything here is content and pure logic. The server owns the collected
    set on the profile; a client never decides what it has found.
]]

local Strings = require("./Strings")

local MemoryFragments = {}

export type Fragment = {
    id: string,
    title: string,
    foundAt: string,
    -- Where the shard physically sits. The builder resolves these against the
    -- world it just built, so content owns placement and the builder owns
    -- geometry: "story:<landmark>", "poi:<poi id>", or a named site.
    anchorKey: string,
    --[[
        Which region holds it. Bramblewake's ten predate this field and
        are stamped by the helper below, because for a year there was only
        one region with a story in it. The archive reads this to group
        what it shows; the builder reads it so a run only places the
        fragments belonging to the region it just built.
    ]]
    regionId: string?,
    act: number,
    body: string,
    -- Fragments that only exist once the chapter is resolved. They are the
    -- payoff and the hook, and both would be nonsense read early.
    requiresChapterOne: boolean,
}

export type CollectResult = {
    accepted: boolean,
    reason: string?,
    fragment: Fragment?,
}

local function fragment(definition: Fragment): Fragment
    local copy = table.clone(definition)
    if copy.regionId == nil then
        copy.regionId = "region_bramblewake"
    end
    return table.freeze(copy)
end

local LIST: { Fragment } = table.freeze({
    -- ACT I -- What the forest kept
    fragment({
        id = "fragment_last_harvest",
        anchorKey = "story:last_harvest",
        title = Strings.get("story.the_last_harvest"),
        foundAt = Strings.get("story.sunken_orchard"),
        act = 1,
        requiresChapterOne = false,
        body = Strings.get("story.they_brought_it_in_anyway_every"),
    }),
    fragment({
        id = "fragment_road_they_left",
        anchorKey = "story:evacuation_cart",
        title = Strings.get("story.the_road_they_left"),
        foundAt = "Hollow Farm",
        act = 1,
        requiresChapterOne = false,
        body = Strings.get("story.someone_counted_children_at_this_bend"),
    }),
    fragment({
        id = "fragment_last_repair",
        anchorKey = "story:last_repair",
        title = Strings.get("story.the_last_repair"),
        foundAt = Strings.get("story.windmill_copse"),
        act = 1,
        requiresChapterOne = false,
        body = Strings.get("story.the_mill_was_still_turning_when"),
    }),
    fragment({
        id = "fragment_lost_crossing",
        anchorKey = "story:lost_crossing",
        title = Strings.get("story.the_lost_crossing"),
        foundAt = Strings.get("story.tangle_bridge"),
        act = 1,
        requiresChapterOne = false,
        body = Strings.get("story.the_bridge_went_down_under_the"),
    }),

    -- ACT II -- The keeper's trail
    fragment({
        id = "fragment_house_that_answered",
        anchorKey = "poi:poi_bw_reedstead_ruin",
        title = Strings.get("story.the_house_that_answered"),
        foundAt = Strings.get("story.reedstead_ruin"),
        act = 2,
        requiresChapterOne = false,
        body = Strings.get("story.this_house_kept_answering_its_door"),
    }),
    fragment({
        id = "fragment_what_moths_carry",
        anchorKey = "poi:poi_bw_mothwell",
        title = Strings.get("story.what_the_moths_carry"),
        foundAt = "Mothwell",
        act = 2,
        requiresChapterOne = false,
        body = Strings.get("story.light_moths_carry_a_little_of"),
    }),
    fragment({
        id = "fragment_keeper_came_through",
        anchorKey = "poi:poi_bw_sapglass_grove",
        title = Strings.get("story.the_keeper_came_through"),
        foundAt = Strings.get("story.sapglass_grove"),
        act = 2,
        requiresChapterOne = false,
        body = Strings.get("story.he_tapped_these_trees_and_left"),
    }),
    fragment({
        id = "fragment_what_orin_said",
        anchorKey = "poi:poi_bw_root_chapel",
        title = Strings.get("story.what_orin_said_at_the_seal"),
        foundAt = "Root Chapel",
        act = 2,
        requiresChapterOne = false,
        body = Strings.get("story.i_am_not_stealing_them_he"),
    }),

    -- ACT III -- Your part in it
    fragment({
        id = "fragment_eighth_seal",
        anchorKey = "site:warden_seal",
        title = Strings.get("story.the_eighth_seal"),
        foundAt = Strings.get("story.the_warden_s_seal"),
        act = 3,
        requiresChapterOne = true,
        body = Strings.get("story.he_woke_the_stag_on_purpose"),
    }),
    fragment({
        id = "fragment_bell_beneath_iron",
        anchorKey = "site:wayhome",
        title = Strings.get("story.a_bell_far_under"),
        foundAt = "Wayhome Gate",
        act = 3,
        requiresChapterOne = true,
        body = Strings.get("story.there_is_a_bell_ringing_under"),
    }),

    --[[
        ACT IV -- the regions after the forest.

        Bramblewake's ten tell one story in three acts and were the whole
        archive for a year. These are shorter on purpose: two per region,
        found at points of interest that already exist, each saying one
        thing about what happened to a place rather than retelling a
        chapter a player is already walking through. They are the archive
        proving the world is bigger than the wood, which is the same job
        the Wayhome fragment does at the end of act three.
    ]]
    fragment({
        id = "fragment_delve_shift_book",
        anchorKey = "poi:poi_ir_tally_wall",
        regionId = "region_ironroot",
        title = Strings.get("story.the_last_shift"),
        foundAt = "Tally Wall",
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.the_wall_still_shows_a_shift"),
    }),
    fragment({
        id = "fragment_delve_air",
        anchorKey = "poi:poi_ir_crushed_cage",
        regionId = "region_ironroot",
        title = Strings.get("story.what_the_air_took"),
        foundAt = "Crushed Cage",
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.they_kept_birds_because_a_bird"),
    }),
    fragment({
        id = "fragment_fen_ferry",
        anchorKey = "poi:poi_mg_ferry_ledger",
        regionId = "region_mireglass",
        title = Strings.get("story.the_last_crossing"),
        foundAt = "Ferry Ledger",
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.the_ferryman_s_tally_runs_to"),
    }),
    fragment({
        id = "fragment_fen_reflection",
        anchorKey = "poi:poi_mg_still_pool",
        regionId = "region_mireglass",
        title = Strings.get("story.what_looked_back"),
        foundAt = Strings.get("story.the_still_pool"),
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.every_account_of_this_water_agrees"),
    }),
    fragment({
        id = "fragment_reach_signal",
        anchorKey = "poi:poi_tr_lighthouse_stump",
        regionId = "region_tempest",
        title = Strings.get("story.the_signal_book"),
        foundAt = Strings.get("story.lighthouse_stump"),
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.the_tower_is_a_stump_and"),
    }),
    fragment({
        id = "fragment_reach_harbour",
        anchorKey = "poi:poi_tr_anchor_field",
        regionId = "region_tempest",
        title = Strings.get("story.where_the_big_boats_went"),
        foundAt = "Anchor Field",
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.anchors_from_boats_too_big_for"),
    }),
    fragment({
        id = "fragment_vale_bell_rope",
        anchorKey = "poi:poi_fv_bell_without_rope",
        regionId = "region_frostmere",
        title = Strings.get("story.who_cut_the_rope"),
        foundAt = Strings.get("story.bell_without_a_rope"),
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.the_abbey_rang_for_anyone_still"),
    }),
    fragment({
        id = "fragment_vale_cold_hearth",
        anchorKey = "poi:poi_fv_cold_hearth",
        regionId = "region_frostmere",
        title = Strings.get("story.the_fire_they_kept"),
        foundAt = Strings.get("story.the_cold_hearth"),
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.the_great_fire_was_tended_in"),
    }),
    fragment({
        id = "fragment_crown_ovation",
        anchorKey = "poi:poi_cc_last_ovation",
        regionId = "region_cinderfall",
        title = Strings.get("story.the_last_ovation"),
        foundAt = Strings.get("story.the_last_ovation_2"),
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.they_were_watching_something_right_up"),
    }),
    fragment({
        id = "fragment_crown_name_wall",
        anchorKey = "poi:poi_cc_name_wall",
        regionId = "region_cinderfall",
        title = Strings.get("quest.the_other_names"),
        foundAt = Strings.get("story.the_name_wall"),
        act = 4,
        requiresChapterOne = true,
        body = Strings.get("story.official_names_cut_deep_and_formal"),
    }),
})

local BY_ID: { [string]: Fragment } = {}
for _, entry in LIST do
    BY_ID[entry.id] = entry
end
table.freeze(BY_ID)

MemoryFragments.List = LIST
MemoryFragments.Count = #LIST

function MemoryFragments.byId(id: string): Fragment?
    return BY_ID[id]
end

function MemoryFragments.isKnown(id: string): boolean
    return BY_ID[id] ~= nil
end

--[[
    Normalize a stored collected set.

    Anything not in the current catalog is dropped, exactly the way gear and
    quest state already drop unknown IDs, so a retired fragment cannot keep
    occupying a player's archive count forever.
]]
function MemoryFragments.normalize(value: any): { [string]: boolean }
    local result: { [string]: boolean } = {}
    if type(value) ~= "table" then
        return result
    end
    for id, collected in value do
        if type(id) == "string" and collected == true and BY_ID[id] ~= nil then
            result[id] = true
        end
    end
    return result
end

--[[
    Recover one fragment.

    Pure and idempotent: recovering the same fragment twice is accepted once
    and reports the repeat, so a duplicated remote or a second tap can never
    double-count the archive.
]]
function MemoryFragments.collect(
    collected: { [string]: boolean },
    id: string,
    chapterResolved: boolean
): ({ [string]: boolean }, CollectResult)
    local entry = BY_ID[id]
    if entry == nil then
        return collected, { accepted = false, reason = "unknown_fragment" }
    end
    if entry.requiresChapterOne and not chapterResolved then
        return collected, { accepted = false, reason = "chapter_unresolved" }
    end
    if collected[id] == true then
        return collected, { accepted = false, reason = "already_recovered", fragment = entry }
    end
    local nextCollected = table.clone(collected)
    nextCollected[id] = true
    return nextCollected, { accepted = true, fragment = entry }
end

--[[
    What the Memory Archive shows.

    Recovered fragments read in authored order so the story assembles rather
    than arriving as a shuffled list. Missing ones are named by where they
    are, never hidden behind a question mark: the pull is "there is more to
    know and I know where to look", not a checklist with the labels torn off.
]]
function MemoryFragments.snapshot(
    collected: { [string]: boolean },
    chapterResolved: boolean
): {
    total: number,
    found: number,
    entries: { any },
    nextHint: string?,
}
    local entries = {}
    local found = 0
    local total = 0
    local nextHint: string? = nil
    for _, entry in LIST do
        local locked = entry.requiresChapterOne and not chapterResolved
        if not locked then
            total += 1
            local recovered = collected[entry.id] == true
            if recovered then
                found += 1
            elseif nextHint == nil then
                nextHint = entry.foundAt
            end
            table.insert(entries, {
                id = entry.id,
                title = entry.title,
                foundAt = entry.foundAt,
                act = entry.act,
                recovered = recovered,
                body = if recovered then entry.body else nil,
            })
        end
    end
    return { total = total, found = found, entries = entries, nextHint = nextHint }
end

return table.freeze(MemoryFragments)
