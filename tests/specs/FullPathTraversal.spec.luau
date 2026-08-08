--!strict

--[[
    One profile, walked from the first dawn to the epilogue.

    Every other content spec asks whether a thing exists. `ContentCensus`
    counts the catalog, `ChapterProgress` checks a chapter against the
    chapter beside it, `Quests` drives one arc, `MemoryFragments` checks
    that a fragment is anchored somewhere. All of those are true and none
    of them walks. Counting is not looking, and a catalog whose entries
    are each individually reachable can still have a path through it that
    stops -- the two facts this codebase has now paid for four times are
    exactly that shape.

    So this spec makes one profile and takes it the whole way. It starts
    at `SaveSchema.default`, resolves seven chapters through the real
    mutators in order, checks at every step that the region ahead is shut
    and the region underfoot is open, and ends by reading the epilogue out
    of the save it just wrote. Nothing here is a fixture: every state it
    asserts against is a state the previous assertion produced.

    Four things the walk then measures, each of which is a way the path
    could be unbroken for a reader and broken for a player:

      * **the chapters are the only order there is** -- at every step,
        every chapter ahead refuses, so the walk is not merely a walk that
        works but the only one;
      * **the quest catalog empties on it** -- claimed in arc order,
        nothing orphaned behind a stage that can never claim, and the
        whole catalog gone by the end;
      * **every recipe is craftable out of one region's ground** -- a
        material is obtainable at the chapter that hosts the region paying
        it, and no recipe reaches across regions, so the crafting tree is
        exactly as deep as the story and never deeper;
      * **every memory is readable by the end** -- the act-three fragments
        are sealed behind chapter one, which means the walk unseals them,
        and a fragment nothing unseals is a body of text no player reads.

    The honest gap is written as a case rather than as prose: six of the
    seven regions have `enabled = false`, and the walk cannot flip them.
    What the walk *can* say is that the flag is the only thing left --
    every one of them refuses with `region_not_built` on a fully resolved
    story rather than with a missing dependency or an unreached chapter.
]]

local fs = require("@lune/fs")

local ChapterCatalog = require("../../src/shared/ChapterCatalog")
local CraftingCatalog = require("../../src/shared/CraftingCatalog")
local Epilogue = require("../../src/shared/Epilogue")
local ExtractionPayoff = require("../../src/shared/ExtractionPayoff")
local MemoryFragments = require("../../src/shared/MemoryFragments")
local ProfessionCatalog = require("../../src/shared/ProfessionCatalog")
local QuestCatalog = require("../../src/shared/QuestCatalog")
local Quests = require("../../src/shared/Quests")
local RegionAccess = require("../../src/shared/RegionAccess")
local Regions = require("../../src/shared/Content/Definitions/Regions")
local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

--[[
    The walk's own script: what each chapter is resolved with. The decision
    and the outcome are read back out of the catalog rather than written
    here, so this table names only the choice a player would make and the
    catalog stays the authority on what a chapter can record.
]]
local WALK = table.freeze({
    table.freeze({ chapterId = "chapter_one", decisionIndex = 3, outcomeIndex = 1 }),
    table.freeze({ chapterId = "chapter_two", decisionIndex = 1, outcomeIndex = 1 }),
    table.freeze({ chapterId = "chapter_three", decisionIndex = 1, outcomeIndex = 1 }),
    table.freeze({ chapterId = "chapter_four", decisionIndex = 1, outcomeIndex = 1 }),
    table.freeze({ chapterId = "chapter_five", decisionIndex = 1, outcomeIndex = 1 }),
    table.freeze({ chapterId = "chapter_six", decisionIndex = 1, outcomeIndex = 1 }),
})

local FINALE = table.freeze({
    abandonedPost = "post_hearth",
    ending = "ending_shared",
    leftBehind = "npc_ivy_thorn",
    light = 2,
    rescued = "npc_pip_wren",
})

-- Where each region's own five materials are written down. A material is a
-- fact about a place, so the two files that describe a place are the two
-- that may pay one out: the expedition definition (its events) and the
-- builder's node table (its ground).
local NODE_FILES = table.freeze({
    "src/server/World/RegionBuilders.luau",
    "src/server/World/BramblewakeBuilder.luau",
})

local EXPEDITION_DIR = "src/shared/Content/Definitions"

-- Everything the town can spend a material on. A material nothing consumes
-- is a drop a player banks and can never use, which reads as a bug in the
-- crafting screen rather than as an unfinished economy.
local CONSUMER_FILES = table.freeze({
    "src/shared/CraftingCatalog.luau",
    "src/shared/TownConstructionCatalog.luau",
    "src/shared/TownDecorations.luau",
    "src/shared/DefenseLanes.luau",
    "src/shared/ToolCatalog.luau",
})

local REGION_CHAPTER: { [string]: number } = {}
for _, definition in ChapterCatalog.list() do
    REGION_CHAPTER[definition.regionId] = definition.number
end

local function walkOneStep(profile: any, step: any, now: number): (any, any)
    local definition = ChapterCatalog.require(step.chapterId)
    local decision = definition.decisions[step.decisionIndex]
    local outcome = definition.outcomes[step.outcomeIndex]
    local transactionId = string.format("%s:walk:%d", step.chapterId, now)
    if step.chapterId == "chapter_one" then
        return SaveSchema.withChapterOneResolution(profile, transactionId, decision, outcome, now)
    end
    return SaveSchema.withChapterResolution(
        profile,
        step.chapterId,
        transactionId,
        decision,
        outcome,
        now
    )
end

-- The whole walk, as one profile. Anything that wants the finished save
-- takes it from here rather than assembling its own, because a fixture
-- built beside the walk is the thing this spec exists to stop being.
local function walkToEpilogue(): any
    local profile = SaveSchema.default(1000)
    for index, step in WALK do
        profile = (walkOneStep(profile, step, 1000 + index))
    end
    return (SaveSchema.withFinaleResolution(profile, "finale:walk", FINALE, 2000))
end

--[[
    Saturated quest signals. Every counter is far past the largest
    threshold in the catalog, which is the point: this asks whether the
    catalog can be emptied at all, not whether a particular number empties
    it. A quest that stays unclaimed against saturation is unclaimable.
]]
local function saturatedSignals(): Quests.Signals
    local fragmentsByRegion: { [string]: number } = {}
    for _, region in Regions do
        fragmentsByRegion[region.id] = 999
    end
    local masteryByProfession: { [string]: number } = {}
    for _, profession in ProfessionCatalog.list() do
        masteryByProfession[profession.id] = 999
    end
    return {
        nightsSurvived = 999,
        craftedItems = 999,
        bramblewakeSettlements = 999,
        buildingsRaised = 999,
        decorationsPlaced = 999,
        gearTraits = 999,
        materialsBanked = 999,
        residentsBonded = 999,
        chaptersResolved = 999,
        fragmentsRecovered = 999,
        fragmentsByRegion = fragmentsByRegion,
        masteryByProfession = masteryByProfession,
    }
end

local function readFile(path: string): string
    return fs.readFile(path)
end

--[[
    A producer writes a material id as a **string** -- `materialId =
    "material_heartwood"`, or an `id` field on a node -- and a consumer
    writes it as a **key**: `material_heartwood = 8`. That is not a
    convention this spec invented to make a regex work; it is the
    difference between naming a thing and counting it, and it holds in
    every file on both lists.
]]
local function producedIn(source: string): { [string]: boolean }
    local found: { [string]: boolean } = {}
    for id in string.gmatch(source, "[\"'](material_[%a_]+)[\"']") do
        found[id] = true
    end
    return found
end

local function consumedIn(source: string): { [string]: boolean }
    local found: { [string]: boolean } = {}
    for id in string.gmatch(source, "(material_[%a_]+)%s*=%s*%d") do
        found[id] = true
    end
    for id in string.gmatch(source, "(material_[%a_]+)%s*=%s*true") do
        found[id] = true
    end
    return found
end

-- Which region pays each material, read out of the region's own two files.
local function materialsByRegion(): { [string]: { [string]: boolean } }
    local byRegion: { [string]: { [string]: boolean } } = {}
    for _, region in Regions do
        byRegion[region.id] = {}
    end

    for _, entry in fs.readDir(EXPEDITION_DIR) do
        if string.find(entry, "Expedition.luau", 1, true) ~= nil then
            local source = readFile(EXPEDITION_DIR .. "/" .. entry)
            local regionId = string.match(source, 'RegionId%s*=%s*"([%a_]+)"')
            TestRunner.truthy(regionId, string.format("%s names no region", entry))
            for id in producedIn(source) do
                byRegion[regionId :: string][id] = true
            end
        end
    end

    --[[
        The builders' node tables are keyed by region in the same file, so
        each region's block is taken between its own key and the next
        one. Bramblewake's nodes are built inline by its own builder and
        that whole file belongs to Bramblewake, which is why the two are
        read differently rather than by one clever pattern.
    ]]
    for _, path in NODE_FILES do
        local source = readFile(path)
        local currentRegion: string? = if string.find(path, "Bramblewake", 1, true) ~= nil
            then "region_bramblewake"
            else nil
        for line in string.gmatch(source, "[^\n]+") do
            local named = string.match(line, "(region_[%a]+)%s*=%s*table%.freeze")
            if named ~= nil and byRegion[named] ~= nil then
                currentRegion = named
            end
            if currentRegion ~= nil then
                for id in producedIn(line) do
                    byRegion[currentRegion :: string][id] = true
                end
            end
        end
    end

    return byRegion
end

return {
    name = "FullPathTraversal",
    cases = {
        {
            --[[
                The headline. One profile, seven chapters, an epilogue read
                out of the save at the end -- and at every step, the region
                the story has reached is open and the one after it is not.
            ]]
            name = "a fresh profile walks from the first dawn to the epilogue",
            run = function()
                local profile = SaveSchema.default(1000)

                -- A save that has resolved nothing still reads as something,
                -- because a player can reach the Hollow's mouth without
                -- closing a chapter behind them.
                local opening = Epilogue.resolve(profile.story)
                TestRunner.equal(opening.ending, nil)
                TestRunner.equal(opening.title, "THE STORY SO FAR")
                TestRunner.equal(#opening.lines, 1)
                TestRunner.equal(SaveSchema.chapterProgress(profile), 1)

                local chapters = ChapterCatalog.list()
                for index, step in WALK do
                    local definition = chapters[index]
                    TestRunner.equal(definition.id, step.chapterId)

                    -- The region this chapter is played in is reachable,
                    -- because the chapter before it is closed.
                    TestRunner.truthy(
                        RegionAccess.chapterReached(profile.story, definition.regionId),
                        string.format("%s is unreachable at its own step", definition.regionId)
                    )
                    -- and the one after it is not.
                    local next = chapters[index + 1]
                    TestRunner.equal(
                        RegionAccess.chapterReached(profile.story, next.regionId),
                        false,
                        string.format("%s opened a chapter early", next.regionId)
                    )

                    local revision = profile.revision
                    local resolved, result = walkOneStep(profile, step, 1000 + index)
                    TestRunner.equal(
                        result.applied,
                        true,
                        string.format("%s did not resolve on the walk", step.chapterId)
                    )
                    TestRunner.equal(resolved.revision, revision + 1)
                    TestRunner.truthy(SaveSchema.isChapterComplete(resolved, step.chapterId))
                    TestRunner.equal(SaveSchema.chapterProgress(resolved), index + 1)
                    profile = resolved
                end

                -- The Hollow, which is chapter seven and writes two records.
                local finished, result =
                    SaveSchema.withFinaleResolution(profile, "finale:walk", FINALE, 2000)
                TestRunner.equal(result.applied, true)
                TestRunner.truthy(SaveSchema.isChapterComplete(finished, "chapter_seven"))
                TestRunner.equal(finished.story.finale.status, "complete")

                --[[
                    And the epilogue, read out of the save the walk wrote. One
                    line per chapter, plus the post and the person: seven
                    chapters resolved is seven outcome lines, and a story that
                    forgot one of them would be short here rather than wrong
                    anywhere a player could see.
                ]]
                local resolution = Epilogue.resolve(finished.story)
                TestRunner.equal(resolution.ending, "ending_shared")
                TestRunner.equal(resolution.title, "THE LANTERN SHARED")
                TestRunner.equal(resolution.townState, "emberhollow_scattered")
                TestRunner.equal(#resolution.lines, #chapters + 2)
                for _, line in resolution.lines do
                    TestRunner.truthy(#line > 0, "the epilogue has an empty line in it")
                end
            end,
        },
        {
            --[[
                The walk works; this asks whether it is the only one. At
                every step, every chapter still ahead refuses -- so a party
                cannot reach the Crown by resolving it, and the order the
                story is told in is enforced rather than merely intended.
            ]]
            name = "every chapter ahead of the walk refuses until its own step",
            run = function()
                local profile = SaveSchema.default(1000)
                for index, step in WALK do
                    for ahead = index + 1, #WALK do
                        local later = WALK[ahead]
                        local _, refused = walkOneStep(profile, later, 5000 + ahead)
                        TestRunner.equal(
                            refused.applied,
                            false,
                            string.format("%s resolved before its turn", later.chapterId)
                        )
                        TestRunner.equal(refused.reason, "chapter_locked")
                    end

                    -- The finale is ahead of every step but the last.
                    local _, finaleRefused =
                        SaveSchema.withFinaleResolution(profile, "finale:early", FINALE, 5500)
                    TestRunner.equal(finaleRefused.applied, false)
                    TestRunner.equal(finaleRefused.reason, "chapter_locked")

                    profile = (walkOneStep(profile, step, 1000 + index))
                end
            end,
        },
        {
            --[[
                Two orderings exist -- the chapters' `requires` chain and the
                region registry's `dependencies` -- and nothing has ever held
                them against each other. They agree today; a seventh region
                inserted into one and not the other would give a player a
                region the story cannot open, or a chapter with no ground
                under it.
            ]]
            name = "a region's registry dependency is the chapter that opens it",
            run = function()
                local byId: { [string]: any } = {}
                for _, region in Regions do
                    byId[region.id] = region
                end

                local chapters = ChapterCatalog.list()
                TestRunner.equal(#chapters, #Regions)
                for index, definition in chapters do
                    local region = byId[definition.regionId]
                    TestRunner.truthy(region, string.format("%s has no region", definition.id))
                    if index == 1 then
                        TestRunner.equal(definition.requires, nil)
                        TestRunner.equal(#region.dependencies, 0)
                    else
                        local previous = chapters[index - 1]
                        TestRunner.equal(definition.requires, previous.id)
                        TestRunner.equal(#region.dependencies, 1)
                        TestRunner.equal(region.dependencies[1], previous.regionId)
                    end
                end
            end,
        },
        {
            --[[
                The one thing this spec cannot walk, recorded as a check
                rather than as a sentence in a document. Six regions are
                `enabled = false` and flipping one is the owner's call, made
                after a live session walks it end to end. What is checkable
                is that the flag is the *only* thing left: a fully resolved
                story refuses each of them with `region_not_built`, never
                with a missing dependency and never with an unreached
                chapter, so nothing but the switch is in the way.
            ]]
            name = "the flag is the only thing between the walk and a live region",
            run = function()
                local finished = walkToEpilogue()
                local enabled = 0
                for _, region in Regions do
                    local verdict = RegionAccess.evaluate(region.id, finished.story)
                    if region.enabled == true then
                        enabled += 1
                        TestRunner.equal(verdict.allowed, true, region.id)
                        TestRunner.equal(verdict.reason, "open")
                    else
                        TestRunner.equal(verdict.allowed, false, region.id)
                        TestRunner.equal(
                            verdict.reason,
                            "region_not_built",
                            string.format(
                                "%s is held back by more than its flag: %s",
                                region.id,
                                verdict.reason
                            )
                        )
                    end
                    -- The story half is open regardless, which is what makes
                    -- the flag the whole of the remaining distance.
                    TestRunner.truthy(
                        RegionAccess.chapterReached(finished.story, region.id),
                        string.format("%s is still chapter-locked after the walk", region.id)
                    )
                end
                TestRunner.equal(enabled, 1)
                TestRunner.equal(RegionAccess.available(finished.story)[1], "region_bramblewake")
            end,
        },
        {
            --[[
                The quest catalog, emptied. Saturated signals answer "can
                this be claimed at all", and the pass count answers the
                sequencing question: a stage claims only after the stage it
                requires, one per arc per pass, so the number of passes it
                takes to empty the catalog is the depth of its deepest arc
                and nothing else.
            ]]
            name = "every quest claims on the walk, and no stage claims before the one it requires",
            run = function()
                local signals = saturatedSignals()
                local claimed: { [string]: boolean } = {}
                local materials: { [string]: number } = {}
                local claimedAtPass: { [string]: number } = {}

                local passes = 0
                while true do
                    local nextClaimed, nextMaterials, results =
                        Quests.checkAndClaim(claimed, materials, signals)
                    if #results == 0 then
                        break
                    end
                    passes += 1
                    TestRunner.truthy(passes <= 16, "the quest catalog does not settle")
                    for _, entry in results do
                        claimedAtPass[entry.questId] = passes
                    end
                    claimed = nextClaimed
                    materials = nextMaterials
                end

                local quests = QuestCatalog.list()
                local deepest = 0
                for _, quest in quests do
                    local pass = claimedAtPass[quest.id]
                    TestRunner.truthy(pass, string.format("%s is never claimable", quest.id))
                    deepest = math.max(deepest, pass :: number)

                    local requires = quest.requires
                    if requires ~= nil then
                        local required = claimedAtPass[requires]
                        TestRunner.truthy(
                            required,
                            string.format("%s requires %s, which never claims", quest.id, requires)
                        )
                        TestRunner.truthy(
                            (required :: number) < (pass :: number),
                            string.format("%s claimed no later than what it requires", quest.id)
                        )
                    end
                end
                TestRunner.equal(passes, deepest)

                -- Every reward landed, and landed once: the catalog's own
                -- totals, summed independently of the claiming loop.
                local expected: { [string]: number } = {}
                for _, quest in quests do
                    expected[quest.reward.materialId] = (expected[quest.reward.materialId] or 0)
                        + quest.reward.amount
                end
                for materialId, amount in expected do
                    TestRunner.equal(materials[materialId], amount, materialId)
                end
                for materialId in materials do
                    TestRunner.truthy(expected[materialId], materialId)
                end
            end,
        },
        {
            --[[
                Every recipe is craftable out of one region's ground.

                The reachability question a crafting tree actually has is not
                whether a material exists -- they all do -- but *when* it can
                be had, and that is the chapter that opens the region paying
                it. Two things hold here and both are worth pinning: each
                region pays exactly five materials and no two regions pay the
                same one, so a material names its chapter unambiguously; and
                no recipe mixes regions, so the crafting tree is exactly as
                deep as the story rather than reaching past it.
            ]]
            name = "every recipe is craftable out of one region's ground",
            run = function()
                local byRegion = materialsByRegion()
                local chapterOf: { [string]: number } = {}
                local paying = 0
                for regionId, materials in byRegion do
                    local count = 0
                    for id in materials do
                        count += 1
                        TestRunner.equal(
                            chapterOf[id],
                            nil,
                            string.format("%s is paid by two regions", id)
                        )
                        chapterOf[id] = REGION_CHAPTER[regionId]
                    end
                    --[[
                        The Hollow pays nothing, deliberately. It is the
                        finale rather than a place a party works: it has no
                        expedition definition and no node table, and a
                        material dropping there would make the last chapter
                        somewhere to farm. Every other region pays exactly
                        five.
                    ]]
                    if regionId == "region_hollow" then
                        TestRunner.equal(count, 0, "the finale pays out materials")
                    else
                        paying += 1
                        TestRunner.equal(
                            count,
                            5,
                            string.format("%s pays %d materials, not five", regionId, count)
                        )
                    end
                end
                TestRunner.equal(paying, 6)

                local perChapter: { [number]: number } = {}
                for _, recipe in CraftingCatalog.list() do
                    local earliest = 0
                    local latest = 0
                    local inputs = 0
                    for materialId in recipe.materials do
                        local chapter = chapterOf[materialId]
                        TestRunner.truthy(
                            chapter,
                            string.format(
                                "%s asks for %s, which no region pays out",
                                recipe.id,
                                materialId
                            )
                        )
                        inputs += 1
                        earliest = if earliest == 0
                            then chapter :: number
                            else math.min(earliest, chapter :: number)
                        latest = math.max(latest, chapter :: number)
                    end
                    TestRunner.truthy(inputs > 0, string.format("%s costs nothing", recipe.id))
                    TestRunner.equal(
                        earliest,
                        latest,
                        string.format(
                            "%s reaches across regions, so it is craftable later than the "
                                .. "region it belongs to",
                            recipe.id
                        )
                    )
                    perChapter[latest] = (perChapter[latest] or 0) + 1
                end

                -- and every chapter that pays materials brings recipes with
                -- it, so no region is walked for materials that craft
                -- nothing.
                for _, definition in ChapterCatalog.list() do
                    if definition.regionId ~= "region_hollow" then
                        TestRunner.truthy(
                            (perChapter[definition.number] or 0) > 0,
                            string.format("%s unlocks no recipe", definition.id)
                        )
                    end
                end
            end,
        },
        {
            --[[
                Both directions of the material economy. A recipe input
                nothing pays out is a recipe nobody can craft; a payout
                nothing consumes is a number that climbs in a player's pouch
                and never buys anything, which reads as a broken crafting
                screen rather than as an unfinished economy. And anything
                either side names has to be a material the extraction screen
                can actually put a word to, or a player banks something the
                payoff cannot name.
            ]]
            name = "everything the world pays out is something the town can spend",
            run = function()
                local produced: { [string]: boolean } = {}
                for _, materials in materialsByRegion() do
                    for id in materials do
                        produced[id] = true
                    end
                end

                local consumed: { [string]: boolean } = {}
                for _, path in CONSUMER_FILES do
                    for id in consumedIn(readFile(path)) do
                        consumed[id] = true
                    end
                end

                local presented: { [string]: boolean } = {}
                for id in produced do
                    presented[id] = true
                end
                for id in consumed do
                    presented[id] = true
                end
                for id in presented do
                    local entries = ExtractionPayoff.summarize({ [id] = 1 })
                    TestRunner.equal(
                        #entries,
                        1,
                        string.format("%s is not a material the payoff screen can name", id)
                    )
                    TestRunner.truthy(
                        produced[id],
                        string.format("%s is spent but nothing pays it out", id)
                    )
                    TestRunner.truthy(
                        consumed[id],
                        string.format("%s is paid out but nothing spends it", id)
                    )
                end

                -- The count is pinned for the reason every count in this
                -- project is: six regions paying five each is a shape, and a
                -- thirty-first material belongs to a seventh region or to a
                -- mistake.
                local total = 0
                for _ in presented do
                    total += 1
                end
                TestRunner.equal(total, 30)
            end,
        },
        {
            --[[
                Every memory is readable by the end of the walk. Act three is
                sealed behind chapter one, which is the walk's first step, so
                a fragment sealed behind something the walk never does would
                be a body of authored text no player ever reads -- and the
                archive would not report it missing, because a locked
                fragment is not counted as missing.
            ]]
            name = "every memory the game holds is readable by the end of the walk",
            run = function()
                local sealed = MemoryFragments.snapshot({}, false)
                local opened = MemoryFragments.snapshot({}, true)
                TestRunner.truthy(
                    opened.total > sealed.total,
                    "nothing is sealed behind chapter one, so the walk unseals nothing"
                )

                local finished = walkToEpilogue()
                local chapterOneDone = SaveSchema.isChapterComplete(finished, "chapter_one")
                TestRunner.equal(chapterOneDone, true)

                local collected: { [string]: boolean } = {}
                local recovered = 0
                for _, entry in MemoryFragments.snapshot({}, chapterOneDone).entries do
                    local next, result =
                        MemoryFragments.collect(collected, entry.id, chapterOneDone)
                    TestRunner.equal(
                        result.accepted,
                        true,
                        string.format("%s cannot be recovered on the walk", entry.id)
                    )
                    collected = next
                    recovered += 1
                end

                local final = MemoryFragments.snapshot(collected, chapterOneDone)
                TestRunner.equal(final.found, final.total)
                TestRunner.equal(final.found, recovered)
                TestRunner.equal(final.nextHint, nil)
                -- and the archive is the whole catalog, not the part of it the
                -- walk happened to pass.
                TestRunner.equal(final.total, opened.total)
            end,
        },
    },
}
