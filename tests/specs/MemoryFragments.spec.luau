--!strict

local MemoryFragments = require("../../src/shared/MemoryFragments")
local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

local function collectedSet(...: string): { [string]: boolean }
    local result: { [string]: boolean } = {}
    for _, id in { ... } do
        result[id] = true
    end
    return result
end

return {
    name = "MemoryFragments",
    cases = {
        {
            name = "every fragment has a unique id, an anchor, and a body worth reading",
            run = function()
                local seenIds: { [string]: boolean } = {}
                local seenAnchors: { [string]: boolean } = {}
                for _, fragment in MemoryFragments.List do
                    TestRunner.equal(seenIds[fragment.id], nil)
                    TestRunner.equal(seenAnchors[fragment.anchorKey], nil)
                    seenIds[fragment.id] = true
                    seenAnchors[fragment.anchorKey] = true
                    TestRunner.equal(#fragment.title > 0, true)
                    TestRunner.equal(#fragment.foundAt > 0, true)
                    TestRunner.equal(#fragment.body > 80, true)
                    TestRunner.equal(fragment.act >= 1 and fragment.act <= 3, true)
                end
                TestRunner.equal(MemoryFragments.Count, #MemoryFragments.List)
            end,
        },
        {
            name = "recovers a fragment exactly once",
            run = function()
                local collected = MemoryFragments.normalize(nil)
                local next1, result1 =
                    MemoryFragments.collect(collected, "fragment_last_harvest", false)
                TestRunner.equal(result1.accepted, true)
                TestRunner.equal(next1.fragment_last_harvest, true)

                local next2, result2 =
                    MemoryFragments.collect(next1, "fragment_last_harvest", false)
                TestRunner.equal(result2.accepted, false)
                TestRunner.equal(result2.reason, "already_recovered")
                -- The repeat still reports which fragment it was, so the
                -- player can re-read it instead of being told nothing.
                TestRunner.equal(result2.fragment ~= nil, true)
                TestRunner.equal(next2.fragment_last_harvest, true)
            end,
        },
        {
            name = "an unknown fragment id is refused",
            run = function()
                local _, result =
                    MemoryFragments.collect(MemoryFragments.normalize(nil), "fragment_nope", true)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "unknown_fragment")
            end,
        },
        {
            name = "act three stays sealed until chapter one resolves",
            run = function()
                local collected = MemoryFragments.normalize(nil)
                local _, blocked =
                    MemoryFragments.collect(collected, "fragment_bell_beneath_iron", false)
                TestRunner.equal(blocked.accepted, false)
                TestRunner.equal(blocked.reason, "chapter_unresolved")

                local nextCollected, allowed =
                    MemoryFragments.collect(collected, "fragment_bell_beneath_iron", true)
                TestRunner.equal(allowed.accepted, true)
                TestRunner.equal(nextCollected.fragment_bell_beneath_iron, true)
            end,
        },
        {
            name = "the archive counts only what is currently readable",
            run = function()
                local collected = collectedSet("fragment_last_harvest", "fragment_what_orin_said")
                local unresolved = MemoryFragments.snapshot(collected, false)
                local resolved = MemoryFragments.snapshot(collected, true)
                -- Sealed fragments are not in the denominator before the
                -- chapter resolves, so the archive can never read "2 / 10"
                -- against entries the player cannot yet reach.
                TestRunner.equal(unresolved.total < resolved.total, true)
                TestRunner.equal(unresolved.found, 2)
                TestRunner.equal(resolved.found, 2)
                for _, entry in unresolved.entries do
                    TestRunner.equal(entry.act < 3, true)
                end
            end,
        },
        {
            name = "the archive names where the next missing memory is",
            run = function()
                local snapshot = MemoryFragments.snapshot(MemoryFragments.normalize(nil), false)
                TestRunner.equal(snapshot.found, 0)
                TestRunner.equal(snapshot.nextHint, MemoryFragments.List[1].foundAt)
                for _, entry in snapshot.entries do
                    TestRunner.equal(entry.recovered, false)
                    -- An unrecovered entry never leaks its text.
                    TestRunner.equal(entry.body, nil)
                end
            end,
        },
        {
            name = "normalization drops fragments that are no longer in the catalog",
            run = function()
                local stored = {
                    fragment_last_harvest = true,
                    fragment_retired_thing = true,
                    fragment_road_they_left = false,
                }
                local normalized = MemoryFragments.normalize(stored)
                TestRunner.equal(normalized.fragment_last_harvest, true)
                TestRunner.equal(normalized.fragment_retired_thing, nil)
                TestRunner.equal(normalized.fragment_road_they_left, nil)
                TestRunner.equal(next(MemoryFragments.normalize("not a table")), nil)
            end,
        },
        {
            name = "a schema-13 profile migrates with an empty archive",
            run = function()
                local legacy = {
                    schemaVersion = 13,
                    story = { chapterOne = { status = "unresolved" } },
                }
                local profile = SaveSchema.normalize(legacy, 1000)
                TestRunner.equal(profile.schemaVersion, 18)
                TestRunner.equal(next(profile.story.fragments), nil)
            end,
        },
        {
            name = "the profile transaction recovers once and bumps the revision once",
            run = function()
                local profile = SaveSchema.normalize(nil, 1000)
                local startRevision = profile.revision
                local recovered, result =
                    SaveSchema.withMemoryFragment(profile, "fragment_last_harvest", 1001)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(recovered.revision, startRevision + 1)
                TestRunner.equal(recovered.story.fragments.fragment_last_harvest, true)
                -- The original profile is untouched: the transaction is pure.
                TestRunner.equal(next(profile.story.fragments), nil)

                local again, repeated =
                    SaveSchema.withMemoryFragment(recovered, "fragment_last_harvest", 1002)
                TestRunner.equal(repeated.accepted, false)
                TestRunner.equal(again.revision, recovered.revision)
            end,
        },
        {
            name = "recovered fragments survive normalization round-trip",
            run = function()
                local profile = SaveSchema.normalize(nil, 1000)
                local recovered =
                    SaveSchema.withMemoryFragment(profile, "fragment_what_moths_carry", 1001)
                local reloaded = SaveSchema.normalize(recovered, 1002)
                TestRunner.equal(reloaded.story.fragments.fragment_what_moths_carry, true)
            end,
        },
    },
}
