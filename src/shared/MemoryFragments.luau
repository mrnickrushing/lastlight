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

local MemoryFragments = {}

export type Fragment = {
    id: string,
    title: string,
    foundAt: string,
    -- Where the shard physically sits. The builder resolves these against the
    -- world it just built, so content owns placement and the builder owns
    -- geometry: "story:<landmark>", "poi:<poi id>", or a named site.
    anchorKey: string,
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
    return table.freeze(definition)
end

local LIST: { Fragment } = table.freeze({
    -- ACT I -- What the forest kept
    fragment({
        id = "fragment_last_harvest",
        anchorKey = "story:last_harvest",
        title = "THE LAST HARVEST",
        foundAt = "Sunken Orchard",
        act = 1,
        requiresChapterOne = false,
        body = "They brought it in anyway. Every apple, every root, knowing the "
            .. "carts left at dawn and the cellar stayed behind. Ena Moss's "
            .. "grandmother wrote the count in the ledger, and underneath it "
            .. "she wrote: we did not waste it, we only failed to carry it. "
            .. "The orchard has been holding that harvest ever since.",
    }),
    fragment({
        id = "fragment_road_they_left",
        anchorKey = "story:evacuation_cart",
        title = "THE ROAD THEY LEFT",
        foundAt = "Hollow Farm",
        act = 1,
        requiresChapterOne = false,
        body = "Someone counted children at this bend. Counted twice, because "
            .. "the first count came up one short and the second came up "
            .. "right, and nobody afterward could agree which had been the "
            .. "mistake. The road remembers the counting. It does not "
            .. "remember the name it could not find.",
    }),
    fragment({
        id = "fragment_last_repair",
        anchorKey = "story:last_repair",
        title = "THE LAST REPAIR",
        foundAt = "Windmill Copse",
        act = 1,
        requiresChapterOne = false,
        body = "The mill was still turning when the last cart left. That was "
            .. "deliberate. A man named Ol' Wren stayed behind to keep it "
            .. "turning, so anyone still walking would have something to "
            .. "steer by. He is not in the arrival rolls at Emberhollow. The "
            .. "sails turned eleven more days. Pip has never been told.",
    }),
    fragment({
        id = "fragment_lost_crossing",
        anchorKey = "story:lost_crossing",
        title = "THE LOST CROSSING",
        foundAt = "Tangle Bridge",
        act = 1,
        requiresChapterOne = false,
        body = "The bridge went down under the third cart, not the first. "
            .. "Tomas Reed was quartermaster that night, and he had loaded "
            .. "the heavy stores last so the families could cross first. He "
            .. "has never once told that story as a thing he got right.",
    }),

    -- ACT II -- The keeper's trail
    fragment({
        id = "fragment_house_that_answered",
        anchorKey = "poi:poi_bw_reedstead_ruin",
        title = "THE HOUSE THAT ANSWERED",
        foundAt = "Reedstead Ruin",
        act = 2,
        requiresChapterOne = false,
        body = "This house kept answering its door for two winters after "
            .. "nobody lived in it. Not haunted -- remembered. The Long Night "
            .. "does not only take. Sometimes it holds a habit so tightly "
            .. "that the habit goes on without the person.",
    }),
    fragment({
        id = "fragment_what_moths_carry",
        anchorKey = "poi:poi_bw_mothwell",
        title = "WHAT THE MOTHS CARRY",
        foundAt = "Mothwell",
        act = 2,
        requiresChapterOne = false,
        body = "Light-moths carry a little of whatever light they hatched "
            .. "from. These hatched from evacuation lanterns. Follow enough "
            .. "of them and you are walking the road as it was walked, at the "
            .. "pace it was walked, behind people who are no longer there.",
    }),
    fragment({
        id = "fragment_keeper_came_through",
        anchorKey = "poi:poi_bw_sapglass_grove",
        title = "THE KEEPER CAME THROUGH",
        foundAt = "Sapglass Grove",
        act = 2,
        requiresChapterOne = false,
        body = "He tapped these trees and left the vials full, which is not "
            .. "what a thief does. The sap in them has gone to glass, and "
            .. "inside the glass is light that does not flicker. Orin Vale "
            .. "was testing whether a memory could be held outside a lantern. "
            .. "It can. That is the frightening part.",
    }),
    fragment({
        id = "fragment_what_orin_said",
        anchorKey = "poi:poi_bw_root_chapel",
        title = "WHAT ORIN SAID AT THE SEAL",
        foundAt = "Root Chapel",
        act = 2,
        requiresChapterOne = false,
        body = "I am not stealing them, he said. I am letting them out. The "
            .. "chapel heard it and kept it, the way roots keep everything. "
            .. "The machine has been eating what people could not carry -- "
            .. "seven towns' worth of grief, filed where nobody has to feel "
            .. "it. I have felt it, he said. Somebody had to.",
    }),

    -- ACT III -- Your part in it
    fragment({
        id = "fragment_eighth_seal",
        anchorKey = "site:warden_seal",
        title = "THE EIGHTH SEAL",
        foundAt = "The Warden's Seal",
        act = 3,
        requiresChapterOne = true,
        body = "He woke the Stag on purpose -- not to guard the seal against "
            .. "you, but to guard it for you, until someone arrived who would "
            .. "open it slowly. The eighth was never his to take. It answers "
            .. "to whoever chooses to carry it. You picked it up on the first "
            .. "morning without being asked, and it has been answering ever "
            .. "since.",
    }),
    fragment({
        id = "fragment_bell_beneath_iron",
        anchorKey = "site:wayhome",
        title = "A BELL, FAR UNDER",
        foundAt = "Wayhome Gate",
        act = 3,
        requiresChapterOne = true,
        body = "There is a bell ringing under Ironroot Delve. Nobody is "
            .. "pulling it. The shift-bell rang three times a day for forty "
            .. "years, and the crews who answered it were owed wages "
            .. "Emberhollow never paid; now it rings on time in an empty "
            .. "shaft. Orin went that way. He is walking one town's debt at a "
            .. "time, and the next question waiting for you is what a town "
            .. "owes the people whose labour built it. Bring an answer.",
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
