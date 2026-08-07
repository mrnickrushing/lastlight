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
local pointsOfInterest = {
    frozen({
        id = "poi_hb_the_last_street",
        displayName = "The Last Street",
        visual = "last_street",
        scene = 1,
        tags = { "story", "arrival" },
        detail = "Emberhollow, exactly, down to the crack in the board "
            .. "outside the inn. Nobody has ever lived here and every "
            .. "lamp is lit.",
    }),
    frozen({
        id = "poi_hb_three_posts",
        displayName = "The Three Posts",
        visual = "three_posts",
        scene = 1,
        tags = { "combat", "choice" },
        detail = "Gate, road and hearth, and not enough of you to stand "
            .. "at all three. Whichever one is empty is the one it comes "
            .. "through.",
    }),
    frozen({
        id = "poi_hb_the_way_down",
        displayName = "The Way Down",
        visual = "way_down",
        scene = 2,
        tags = { "traversal", "risk" },
        detail = "Not a stair and not a shaft. The road simply keeps "
            .. "going after the ground has stopped, and the lamps go with "
            .. "it.",
    }),
    frozen({
        id = "poi_hb_the_held_light",
        displayName = "The Held Light",
        visual = "held_light",
        scene = 3,
        tags = { "story", "rescue" },
        detail = "Two people down here and light enough to bring out "
            .. "one. Both of them have worked out the arithmetic already.",
    }),
    frozen({
        id = "poi_hb_the_first_lantern",
        displayName = "The First Lantern",
        visual = "first_lantern_true",
        scene = 4,
        tags = { "story", "mystery" },
        detail = "The one every other lantern was lit from, still "
            .. "burning, with nothing feeding it that anyone can see.",
    }),
    frozen({
        id = "poi_hb_the_long_record",
        displayName = "The Long Record",
        visual = "long_record",
        scene = 4,
        tags = { "story", "codex" },
        detail = "Names, in one hand, going back further than the town "
            .. "does. The last page is this year and it is not finished.",
    }),
    frozen({
        id = "poi_hb_the_seat",
        displayName = "The Seat",
        visual = "the_seat",
        scene = 5,
        tags = { "landmark", "boss", "story" },
        detail = "A chair at the bottom of the light, facing up the way "
            .. "you came. Whatever has been sitting in it stands when you "
            .. "arrive.",
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
        displayName = "THE LAST STREET",
        verb = "defend",
        instruction = "HOLD TWO POSTS — THE THIRD IS GOING TO FALL",
        detail = "It is walking into a copy of your town, and you cannot "
            .. "stand everywhere at once.",
    }),
    frozen({
        id = "scene_pursue",
        number = 2,
        displayName = "THE WAY DOWN",
        verb = "pursue",
        instruction = "FOLLOW IT DOWN — EVERY MARK COSTS LIGHT",
        detail = "It does not run. It withdraws, at exactly the speed "
            .. "you are willing to spend light following it.",
    }),
    frozen({
        id = "scene_rescue",
        number = 3,
        displayName = "THE HELD LIGHT",
        verb = "rescue",
        instruction = "THERE IS LIGHT FOR ONE OF THEM",
        detail = "Neither of them will ask you to pick them. That is the " .. "worst part of it.",
    }),
    frozen({
        id = "scene_witness",
        number = 4,
        displayName = "THE FIRST LANTERN",
        verb = "witness",
        instruction = "LOOK AT ALL OF IT BEFORE YOU DECIDE ANYTHING",
        detail = "Nothing here attacks. This is the game explaining "
            .. "itself, and it takes as long as a player wants it to.",
    }),
    frozen({
        id = "scene_choose",
        number = 5,
        displayName = "THE SEAT",
        verb = "choose",
        instruction = "DECIDE WHAT HAPPENS TO THE LIGHT",
        detail = "Three things can be done and none of them undoes what " .. "is already gone.",
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
        displayName = "THE LANTERN KEPT",
        detail = "The light stays where it is and keeps being fed. "
            .. "Emberhollow survives every night it has left, and "
            .. "somebody is always down here.",
    }),
    frozen({
        id = "ending_ended",
        displayName = "THE LANTERN PUT OUT",
        detail = "The light goes out and the nights stop being hunted. "
            .. "So does every lantern above it, and the town has to learn "
            .. "the dark.",
    }),
    frozen({
        id = "ending_shared",
        displayName = "THE LANTERN SHARED",
        detail = "The light is broken up and carried out a piece at a "
            .. "time. No lantern town any more, and no single thing left "
            .. "to sit at the bottom of it.",
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
