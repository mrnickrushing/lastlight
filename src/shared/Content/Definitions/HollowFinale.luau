--!strict

--[[
    The Hollow Below -- chapter VII, and the only place in the game that
    is not generated.

    Every other region is a catalog: modules, sockets, an event pool, and
    a seed that arranges them. That is right for places a player visits
    dozens of times and wrong for a place they visit once. A finale that
    could come out differently is a finale nobody can be told about, and
    the whole point of this one is that it is the same for everyone and
    only the endings differ.

    So there is no module list and no event pool here. There are seven
    places, in order, and five scenes that happen in them. The order is
    the story: the town, the way down, the place someone is trapped, the
    place it explains itself, and the seat at the bottom.

    What the Hollow is: the inside of the lantern road. Every lit thing in
    this game has been drawing from somewhere, and this is the somewhere.
    That is why it looks like Emberhollow does -- the same buildings, the
    same lamps, the same street -- and why nothing in it has ever been
    lived in.
]]

local function frozen(definition: any): any
    local copy = table.clone(definition)
    if copy.tags ~= nil then
        copy.tags = table.freeze(table.clone(copy.tags))
    end
    return table.freeze(copy)
end

--[[
    Seven places, in the order a party reaches them. Each one belongs to a
    scene, and the last two are the same room seen twice -- once while it
    is still explaining itself and once when there is nothing left to say.
]]
local Strings = require("../../Strings")

local pointsOfInterest = {
    frozen({
        id = "poi_hb_the_last_street",
        displayName = Strings.get("story.the_last_street"),
        visual = "last_street",
        scene = 1,
        tags = { "story", "arrival" },
        detail = Strings.get("story.emberhollow_exactly_down_to_the_crack"),
    }),
    frozen({
        id = "poi_hb_three_posts",
        displayName = Strings.get("story.the_three_posts"),
        visual = "three_posts",
        scene = 1,
        tags = { "combat", "choice" },
        detail = Strings.get("story.gate_road_and_hearth_and_not"),
    }),
    frozen({
        id = "poi_hb_the_way_down",
        displayName = "The Way Down",
        visual = "way_down",
        scene = 2,
        tags = { "traversal", "risk" },
        detail = Strings.get("story.not_a_stair_and_not_a"),
    }),
    frozen({
        id = "poi_hb_the_held_light",
        displayName = Strings.get("story.the_held_light"),
        visual = "held_light",
        scene = 3,
        tags = { "story", "rescue" },
        detail = Strings.get("story.two_people_down_here_and_light"),
    }),
    frozen({
        id = "poi_hb_the_first_lantern",
        displayName = Strings.get("story.the_first_lantern"),
        visual = "first_lantern_true",
        scene = 4,
        tags = { "story", "mystery" },
        detail = Strings.get("story.the_one_every_other_lantern_was"),
    }),
    frozen({
        id = "poi_hb_the_long_record",
        displayName = Strings.get("story.the_long_record"),
        visual = "long_record",
        scene = 4,
        tags = { "story", "codex" },
        detail = Strings.get("story.names_in_one_hand_going_back"),
    }),
    frozen({
        id = "poi_hb_the_seat",
        displayName = "The Seat",
        visual = "the_seat",
        scene = 5,
        tags = { "landmark", "boss", "story" },
        detail = Strings.get("story.a_chair_at_the_bottom_of"),
    }),
}

--[[
    The five scenes, in order, with what each one asks. The encounter owns
    the rules; this owns what a player is told, so the two cannot drift
    into describing different fights.
]]
local scenes = {
    frozen({
        id = "scene_defend",
        number = 1,
        displayName = Strings.get("story.the_last_street_2"),
        verb = "defend",
        instruction = Strings.get("story.hold_two_posts_the_third_is"),
        detail = Strings.get("story.it_is_walking_into_a_copy"),
    }),
    frozen({
        id = "scene_pursue",
        number = 2,
        displayName = Strings.get("story.the_way_down"),
        verb = "pursue",
        instruction = Strings.get("story.follow_it_down_every_mark_costs"),
        detail = Strings.get("story.it_does_not_run_it_withdraws"),
    }),
    frozen({
        id = "scene_rescue",
        number = 3,
        displayName = Strings.get("story.the_held_light_2"),
        verb = "rescue",
        instruction = Strings.get("encounter.there_is_light_for_one_of"),
        detail = Strings.get("story.neither_of_them_will_ask_you"),
    }),
    frozen({
        id = "scene_witness",
        number = 4,
        displayName = Strings.get("world.the_first_lantern"),
        verb = "witness",
        instruction = Strings.get("story.look_at_all_of_it_before"),
        detail = Strings.get("story.nothing_here_attacks_this_is_the"),
    }),
    frozen({
        id = "scene_choose",
        number = 5,
        displayName = Strings.get("story.the_seat"),
        verb = "choose",
        instruction = Strings.get("encounter.decide_what_happens_to_the_light"),
        detail = Strings.get("story.three_things_can_be_done_and"),
    }),
}

--[[
    The three endings. Deliberately not good, better and best: each one
    keeps something the others lose, and the epilogue reads the whole
    story rather than only this choice.
]]
local endings = {
    frozen({
        id = "ending_kept",
        displayName = Strings.get("story.the_lantern_kept"),
        detail = Strings.get("story.the_light_stays_where_it_is"),
    }),
    frozen({
        id = "ending_ended",
        displayName = Strings.get("story.the_lantern_put_out"),
        detail = Strings.get("story.the_light_goes_out_and_the"),
    }),
    frozen({
        id = "ending_shared",
        displayName = Strings.get("story.the_lantern_shared"),
        detail = Strings.get("story.the_light_is_broken_up_and"),
    }),
}

return table.freeze({
    RegionId = "region_hollow",
    Version = 1,
    Authored = true,
    ChapterId = "chapter_seven",
    BossId = "boss_nameless_night",
    SceneCount = #scenes,
    PointOfInterestCount = #pointsOfInterest,
    PointsOfInterest = table.freeze(pointsOfInterest),
    Scenes = table.freeze(scenes),
    Endings = table.freeze(endings),
})
