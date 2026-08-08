--!strict

--[[
    One spec that says what this game contains.

    Every other content spec checks one catalog against its own rules.
    This checks the whole inventory against the number written in
    CONTENT_CATALOG.md, which is the document a person reads to find out
    what the game is. Those two drifting apart is not a bug a player ever
    sees directly -- it is worse than that, because it is how a roadmap
    stops being true and nobody notices for a milestone.

    The recipe count in particular was moved down from 180 to 122 on
    purpose, and this is the thing that makes that an honest decision
    rather than a quiet one: the number is asserted, so raising it again
    means adding recipes, and padding to a number would have to be done in
    the open.
]]

local ChapterCatalog = require("../../src/shared/ChapterCatalog")
local Consumables = require("../../src/shared/Consumables")
local CraftingCatalog = require("../../src/shared/CraftingCatalog")
local EnemyCatalog = require("../../src/shared/EnemyCatalog")
local Equipment = require("../../src/shared/Equipment")
local ExpeditionGenerator = require("../../src/shared/ExpeditionGenerator")
local HollowFinale = require("../../src/shared/Content/Definitions/HollowFinale")
local Regions = require("../../src/shared/Content/Definitions/Regions")
local ResidentRoster = require("../../src/shared/ResidentRoster")
local TownProgression = require("../../src/shared/TownProgression")
local TestRunner = require("../TestRunner")

local SURFACE_REGIONS = table.freeze({
    "region_bramblewake",
    "region_ironroot",
    "region_mireglass",
    "region_tempest",
    "region_frostmere",
    "region_cinderfall",
})

return {
    name = "ContentCensus",
    cases = {
        {
            -- Six surface regions of thirty modules, twelve POIs and eight
            -- events, plus an authored finale that is none of those things.
            name = "the surface regions carry the launch inventory",
            run = function()
                local modules, pois, events = 0, 0, 0
                for _, regionId in SURFACE_REGIONS do
                    local catalog = ExpeditionGenerator.catalogFor(regionId)
                    TestRunner.truthy(catalog ~= nil, regionId .. " has no catalog")
                    TestRunner.equal(#catalog.Modules, 30, regionId .. " is short of modules")
                    TestRunner.equal(#catalog.Events, 8, regionId .. " is short of events")
                    modules += #catalog.Modules
                    pois += #catalog.PointsOfInterest
                    events += #catalog.Events
                end
                TestRunner.equal(modules, 180)
                TestRunner.equal(events, 48)

                --[[
                    Twelve per region including Bramblewake, whose gap this
                    census originally recorded: the starting region carried
                    four POIs where every later region had twelve, because
                    it predated the pool-outgrows-the-run shape. Closed by
                    the wave that added its eight rotating POIs; the four
                    fragment anchors stay pinned into every run.
                ]]
                for _, regionId in SURFACE_REGIONS do
                    TestRunner.equal(
                        #ExpeditionGenerator.catalogFor(regionId).PointsOfInterest,
                        12,
                        regionId .. " is short of POIs"
                    )
                end
                TestRunner.equal(pois, 72)

                -- the finale is authored, so it has POIs and no event pool
                TestRunner.equal(#HollowFinale.PointsOfInterest, 7)
                TestRunner.equal((HollowFinale :: any).Events, nil)
                TestRunner.equal(pois + #HollowFinale.PointsOfInterest, 79)

                -- seven regions in the registry, and every one of them named
                -- by a chapter
                TestRunner.equal(#Regions, 7)
                for _, region in Regions do
                    TestRunner.truthy(
                        ChapterCatalog.forRegion(region.id) ~= nil,
                        region.id .. " belongs to no chapter"
                    )
                end
            end,
        },
        {
            --[[
                122, not 180. The original target assumed categories that
                turned out not to exist -- craftable tools, town project
                components, trap devices, companion utilities -- and
                reaching it inside the categories that do exist would have
                meant a second copy of every item with different numbers.
                This asserts what was built instead.
            ]]
            name = "the crafting inventory is 130 recipes, and each group is what the doc says",
            run = function()
                local recipes = CraftingCatalog.list()
                TestRunner.equal(#recipes, 130)

                local weapons, armour, used = 0, 0, 0
                for _, recipe in recipes do
                    local worn = Equipment.get(recipe.outputItemId)
                    if worn ~= nil then
                        if worn.slot == "weapon" then
                            weapons += 1
                        else
                            armour += 1
                        end
                    elseif Consumables.get(recipe.outputItemId) ~= nil then
                        used += 1
                    end
                end
                -- 60 armour: five slots × two lines × six regions,
                -- Bramblewake included since its gap closed.
                TestRunner.equal(weapons, 36)
                TestRunner.equal(armour, 60)
                TestRunner.equal(used, 34)
                TestRunner.equal(weapons + armour + used, #recipes, "a recipe makes an orphan")
                TestRunner.equal(#Consumables.list(), 34)
                TestRunner.equal(#Consumables.EffectKinds, 6)
            end,
        },
        {
            -- The town and the story, which are the two things a player
            -- keeps between runs.
            name = "the town and the story are whole",
            run = function()
                TestRunner.equal(#TownProgression.buildingIds(), 28)
                TestRunner.equal(#ResidentRoster.list(), 27)
                TestRunner.equal(#ChapterCatalog.list(), 7)
                TestRunner.equal(#HollowFinale.Scenes, 5)
                -- the archive: Bramblewake's ten, plus two per later region
                local MemoryFragments = require("../../src/shared/MemoryFragments")
                TestRunner.equal(MemoryFragments.Count, 20)
                TestRunner.equal(#HollowFinale.Endings, 3)

                -- six enemies per surface region, and none for the finale,
                -- whose fight is authored rather than rostered
                TestRunner.equal(#EnemyCatalog.order(), 36)
                for _, regionId in SURFACE_REGIONS do
                    TestRunner.equal(
                        #EnemyCatalog.orderFor(regionId),
                        6,
                        regionId .. " is short of enemies"
                    )
                end

                -- every chapter still names outcomes its own boss reaches,
                -- which is the join between the story and the fights
                for _, definition in ChapterCatalog.list() do
                    TestRunner.equal(#definition.outcomes, 3, definition.id)
                    TestRunner.truthy(#definition.decisions >= 3, definition.id)
                end
            end,
        },
        {
            --[[
                Quests, counted the same way as everything else. The
                interesting assertion is not the total: it is that every
                resident has an arc that starts where the roster says it
                does and runs forward without a cycle, because a stage
                that requires itself -- or two stages that require each
                other -- would lock silently rather than fail.
            ]]
            name = "every resident's arc starts where the roster says and goes somewhere",
            run = function()
                local QuestCatalog = require("../../src/shared/QuestCatalog")
                local byId: { [string]: any } = {}
                for _, quest in QuestCatalog.list() do
                    byId[quest.id] = quest
                end
                TestRunner.equal(#QuestCatalog.list(), 46)

                local stagesFor: { [string]: number } = {}
                local standing = 0
                for _, quest in QuestCatalog.list() do
                    --[[
                        Two families belong to nobody: the mastery trials
                        and the region mysteries are the town's own
                        standing questions rather than a person's. They are
                        counted separately and may not be arc stages;
                        everything else has to name a resident who exists.
                    ]]
                    if quest.residentId == nil then
                        standing += 1
                        TestRunner.equal(quest.requires, nil, quest.id .. " is a stage of nothing")
                        continue
                    end
                    TestRunner.truthy(
                        ResidentRoster.get(quest.residentId) ~= nil,
                        quest.id .. " belongs to somebody who does not exist"
                    )
                    stagesFor[quest.residentId] = (stagesFor[quest.residentId] or 0) + 1
                    -- walk the chain back to its start, refusing a cycle
                    local seen: { [string]: boolean } = { [quest.id] = true }
                    local cursor = quest
                    local guard = 0
                    while cursor.requires ~= nil and guard < 12 do
                        guard += 1
                        local previous = byId[cursor.requires]
                        TestRunner.truthy(
                            previous ~= nil,
                            quest.id .. " requires a quest that does not exist"
                        )
                        TestRunner.equal(
                            seen[(previous :: any).id],
                            nil,
                            "quest arc loops at " .. (previous :: any).id
                        )
                        seen[(previous :: any).id] = true
                        cursor = previous :: any
                    end
                    TestRunner.equal(
                        cursor.requires,
                        nil,
                        quest.id .. " never reaches the start of its arc"
                    )
                    -- and the arc's first stage is the one the roster names
                    TestRunner.equal(
                        cursor.id,
                        (ResidentRoster.require(quest.residentId) :: any).questId,
                        quest.residentId .. "'s arc starts somewhere the roster does not"
                    )
                end

                -- seven mastery trials and six region mysteries
                TestRunner.equal(standing, 13)
                -- seven mastery trials and six region mysteries
                TestRunner.equal(standing, 13)
                for _, definition in ResidentRoster.list() do
                    TestRunner.truthy(
                        (stagesFor[definition.id] or 0) >= 1,
                        definition.id .. " has nothing to ask for"
                    )
                end
                -- chapter one's three are the ones with runway for an arc
                for _, residentId in { "npc_tomas_reed", "npc_pip_wren", "npc_ena_moss" } do
                    TestRunner.equal(stagesFor[residentId], 3, residentId .. " lost an arc stage")
                end
            end,
        },
        {
            --[[
                Reachability, which is the thing every other count in this
                file quietly assumes.

                A recipe exists when it is in the catalog. A recipe is
                *craftable* when something in the world offers it, and for
                one milestone those were different numbers: the benches
                were a hardcoded list of ten, written when there were ten
                recipes, and 120 shipped that nobody could make. Every
                spec passed. Only walking to the workshop found it.

                Deriving a bench per recipe closed that gap and broke
                something worse: thirteen columns by ten rows landed from
                z -128 to -11 across a plaza spanning -136 to -24, so a
                player spawned into a maze of colliding furniture whose
                click volumes ate the taps meant for the tutorial's first
                interaction. It was "verified" by counting benches in a
                console, which is exactly why nobody saw it.

                So this asserts the true state -- ten benched, a hundred
                and twenty not -- and refuses the derivation, because a
                hundred and thirty pieces of furniture is the wrong shape
                for the problem wherever they are put. The fix is a bench
                that lists what a player can make.
            ]]
            name = "the crafting benches are the authored ten, and the gap is open",
            run = function()
                local fs = require("@lune/fs")
                local world = fs.readFile("src/server/Services/WorldService.luau")
                local benched: { [string]: boolean } = {}
                local count = 0
                for recipeId in string.gmatch(world, 'recipeId = "(recipe_[a-z_]+)"') do
                    if not benched[recipeId] then
                        benched[recipeId] = true
                        count += 1
                    end
                end
                TestRunner.equal(count, 10, "the bench list changed size")

                local unreachable = 0
                for _, recipe in CraftingCatalog.list() do
                    if not benched[recipe.id] then
                        unreachable += 1
                    end
                end
                TestRunner.equal(
                    unreachable,
                    120,
                    "the count of recipes with no bench moved -- if a crafting menu "
                        .. "shipped this should be zero and this case should check that"
                )
                TestRunner.equal(
                    string.find(world, 'id = "craft:" .. recipe.id', 1, true),
                    nil,
                    "benches are being derived per recipe again -- that put 130 of "
                        .. "them across the plaza once already"
                )
            end,
        },
        {
            --[[
                The same question the benches failed, asked of people, and
                answered the same way.

                Three residents had authored bodies and the roster names
                twenty-seven, so twenty-four arrived with a chapter, a
                job, a quest and a full set of dialogue and had nothing
                standing in the town to say it to. Nothing failed, because
                a resident nobody built is a resident nobody misses.

                An unauthored resident now derives a body from the roster
                rather than being skipped -- name, job title, a palette
                from the region they walked out of, and a spot worked out
                from their arrival order. This reads the source and
                refuses a return to the skip, because the skip is what
                made the gap invisible.

                The derivation is a floor and stays one; the count that
                moves is how far above it the authoring has got. Nineteen
                now, chapters I through V, and the assertion is here so
                that number can only go up on purpose.
            ]]
            name = "a resident with no authored body derives one rather than being skipped",
            run = function()
                local fs = require("@lune/fs")
                local world = fs.readFile("src/server/Services/WorldService.luau")
                TestRunner.truthy(
                    string.find(world, "local entry = residentRoster.get(residentId)", 1, true)
                        ~= nil,
                    "unauthored residents no longer derive a body from the roster"
                )
                TestRunner.truthy(
                    string.find(world, "REGION_RESIDENT_PALETTES", 1, true) ~= nil,
                    "derived residents no longer wear their own region"
                )
                -- every region a resident can come from has a palette, or
                -- somebody arrives in the fallback's clothes
                local palettes: { [string]: boolean } = {}
                for regionId in string.gmatch(world, "(region_[a-z]+) = {\n%s+accent") do
                    palettes[regionId] = true
                end
                for _, definition in ResidentRoster.list() do
                    TestRunner.truthy(
                        palettes[definition.homeRegion],
                        definition.homeRegion .. " has no resident palette"
                    )
                end

                -- the authored ones keep their authored bodies: chapter
                -- one's three, then the Delve's four, the Fen's four, the
                -- Reach's four and the Vale's four
                local built = 0
                for _, residentId in
                    {
                        "npc_tomas_reed",
                        "npc_pip_wren",
                        "npc_ena_moss",
                        "npc_hesper_vane",
                        "npc_odell_crane",
                        "npc_junie_falk",
                        "npc_bartram_hoke",
                        "npc_saoirse_quill",
                        "npc_wren_dabbler",
                        "npc_marek_still",
                        "npc_lissen_ford",
                        "npc_isolde_maren",
                        "npc_cass_pell",
                        "npc_alder_kine",
                        "npc_nell_barrow",
                        "npc_anselm_rill",
                        "npc_ivy_thorn",
                        "npc_halvard_sunn",
                        "npc_maud_ferrow",
                    }
                do
                    if string.find(world, residentId .. " = {", 1, true) ~= nil then
                        built += 1
                    end
                end
                TestRunner.equal(built, 19, "an authored resident lost their body")
            end,
        },
        {
            --[[
                The census is only worth anything if it matches the
                document, so it reads the document. A count changed in one
                place and not the other is exactly the drift this exists to
                catch.
            ]]
            name = "the numbers in this spec are the numbers in the content catalog",
            run = function()
                local fs = require("@lune/fs")
                local doc = fs.readFile("docs/CONTENT_CATALOG.md")
                for _, claim in
                    {
                        "The 130 launch recipes",
                        "180 reusable surface modules",
                        "| recipe_group_weapons | Weapons | 36 |",
                        "| recipe_group_wearables | Armour | 60 |",
                        "| recipe_group_consumables | Things that are used | 34 |",
                        "| quest_group_resident | Resident arcs | 33 |",
                        "| quest_group_mastery | Profession mastery tracks | 7 |",
                        "| quest_group_mystery | Region mystery groups | 6 |",
                    }
                do
                    TestRunner.truthy(
                        string.find(doc, claim, 1, true) ~= nil,
                        "the content catalog no longer says: " .. claim
                    )
                end
                -- and the old target is gone rather than sitting beside the
                -- new one, because two targets is no target
                TestRunner.equal(
                    string.find(doc, "The 180 launch recipes", 1, true),
                    nil,
                    "the content catalog still claims 180 recipes"
                )
            end,
        },
    },
}
