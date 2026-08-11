--!strict

--[[
    The Delve's catalog and its builder have to agree, and nothing else in
    the suite can check that: the builder is a server module full of
    Instance.new, so Lune cannot run it. What Lune can do is read it, and
    the one fact worth reading is which visual keys have a case.

    This is deliberately a text check rather than a mock. A mock would
    prove the builder answers for a key; only the catalog's own list
    proves it answers for every key a run can actually place, and that is
    the failure that matters -- a module drawn into a manifest with no
    geometry behind it is an empty cell a player walks into.
]]

local fs = require("@lune/fs")
local Cinderfall = require("../../src/shared/Content/Definitions/CinderfallExpedition")
local Frostmere = require("../../src/shared/Content/Definitions/FrostmereExpedition")
local Ironroot = require("../../src/shared/Content/Definitions/IronrootExpedition")
local Mireglass = require("../../src/shared/Content/Definitions/MireglassExpedition")
local Tempest = require("../../src/shared/Content/Definitions/TempestExpedition")
local TestRunner = require("../TestRunner")

local REGIONS = {
    { catalog = Ironroot, builder = "src/server/World/IronrootBuilder.luau" },
    { catalog = Mireglass, builder = "src/server/World/MireglassBuilder.luau" },
    { catalog = Tempest, builder = "src/server/World/TempestBuilder.luau" },
    { catalog = Frostmere, builder = "src/server/World/FrostmereBuilder.luau" },
    { catalog = Cinderfall, builder = "src/server/World/CinderfallBuilder.luau" },
}

local function builderSource(path: string): string
    assert(fs.isFile(path), path .. " is missing")
    return fs.readFile(path)
end

return {
    name = "RegionBuilderCoverage",
    cases = {
        {
            name = "every module a new region can place has geometry behind it",
            run = function()
                for _, region in REGIONS do
                    local source = builderSource(region.builder)
                    local missing: { string } = {}
                    for _, definition in region.catalog.Modules do
                        local needle = string.format("visual == %q", definition.visual)
                        if string.find(source, needle, 1, true) == nil then
                            table.insert(missing, definition.visual)
                        end
                    end
                    TestRunner.truthy(
                        #missing == 0,
                        region.catalog.RegionId
                            .. " visuals with no case in its builder: "
                            .. table.concat(missing, ", ")
                    )
                end
            end,
        },
        {
            --[[
                Bramblewake has its own builder and is not in REGIONS
                above, so nothing else checks it -- and its points of
                interest dispatch on `definition.visual ==` exactly the way
                module visuals do in the newer builders. A POI added to its
                catalog without a case here still gets an anchor and a
                memory lantern, so it does not fail; it just stands in the
                world as a floating name over empty ground, which is worse.
            ]]
            name = "every Bramblewake point of interest has geometry behind it",
            run = function()
                local Bramblewake =
                    require("../../src/shared/Content/Definitions/BramblewakeExpedition")
                local source = builderSource("src/server/World/BramblewakeBuilder.luau")
                local missing: { string } = {}
                for _, definition in Bramblewake.PointsOfInterest do
                    local needle = string.format("visual == %q", definition.visual)
                    if string.find(source, needle, 1, true) == nil then
                        table.insert(missing, definition.visual)
                    end
                end
                TestRunner.truthy(
                    #missing == 0,
                    "Bramblewake POI visuals with no case in its builder: "
                        .. table.concat(missing, ", ")
                )
                --[[
                    And no catch-all: the root chapel spent its first year
                    as the chain's `else`, which meant any unknown visual
                    silently drew a chapel. Every branch must name its
                    visual so an unknown one draws nothing and the check
                    above is the thing that catches it.
                ]]
                local poiChunk =
                    string.match(source, "local function buildPointOfInterest(.-)\nlocal function")
                TestRunner.truthy(poiChunk ~= nil, "buildPointOfInterest went missing")
                TestRunner.equal(
                    string.find(poiChunk :: string, "\n    else\n", 1, true),
                    nil,
                    "buildPointOfInterest has a catch-all branch again"
                )
            end,
        },
        {
            -- The region must not open until it is whole. This pins the
            -- other half of that promise: the builder answering for every
            -- key is what earns the enabled flag, not the reverse.
            name = "a region opens only after its live walk, and the rest stay closed",
            run = function()
                local Regions = require("../../src/shared/Content/Definitions/Regions")
                local byId: { [string]: any } = {}
                for _, region in Regions do
                    byId[region.id] = region
                end
                --[[
                    Ironroot opened with the assembly seam: departure
                    board, arrival, nodes, POI, event, fragment, both
                    elites, the Maw, extraction, all walked live in the
                    session that flipped it. The others stay shut until
                    each earns the same walk.
                ]]
                TestRunner.equal(byId.region_ironroot.enabled, true)
                TestRunner.equal(byId.region_mireglass.enabled, true)
                TestRunner.equal(byId.region_tempest.enabled, true)
                TestRunner.equal(byId.region_frostmere.enabled, true)
                TestRunner.equal(byId.region_cinderfall.enabled, false)
                TestRunner.equal(byId.region_hollow.enabled, false)
            end,
        },
        {
            name = "keeps Bramblewake route and interaction clearance fixes wired",
            run = function()
                local source = builderSource("src/server/World/BramblewakeBuilder.luau")
                TestRunner.truthy(
                    string.find(source, "clearRouteCorridor(expedition", 1, true) ~= nil,
                    "Bramblewake no longer clears tall collision from connected route seams"
                )
                TestRunner.truthy(
                    string.find(source, "moduleIndex == 3 and slot == 1", 1, true) ~= nil,
                    "the first farm relay overlaps its harvest interaction again"
                )
                TestRunner.truthy(
                    string.find(source, 'SetAttribute("ClearedRouteObstacleCount"', 1, true) ~= nil,
                    "route clearance is no longer measurable in Studio"
                )
                TestRunner.truthy(
                    string.find(source, "ORCHARD_TREE_OFFSETS", 1, true) ~= nil
                        and string.find(source, "Vector3.new(-27, 0, 21)", 1, true) ~= nil
                        and string.find(source, "Vector3.new(29, 0, 3)", 1, true) ~= nil,
                    "the orchard no longer reserves the road and encounter sockets"
                )
                TestRunner.truthy(
                    string.find(source, "LanternGateRootArchFallback", 1, true) ~= nil
                        and string.find(source, "fallbackInstance = fallbackInstance", 1, true)
                            ~= nil,
                    "the arrival gate again layers visible procedural and authored structures"
                )
                TestRunner.equal(
                    string.find(source, 'dress(extra, "mesh_hollow_lantern_shrine_a"', 1, true),
                    nil,
                    "the root chapel again stacks a second full shrine in the same footprint"
                )
                TestRunner.truthy(
                    string.find(
                        source,
                        "if placement.index > 1 and placement.index % 2 == 1 then",
                        1,
                        true
                    ) ~= nil,
                    "the arrival cell again duplicates its landmark with a nearby route sign"
                )
            end,
        },
        {
            name = "keeps Bramblewake authored placement replacements uncluttered",
            run = function()
                local source = builderSource("src/server/World/BramblewakeBuilder.luau")
                local worldService = builderSource("src/server/Services/WorldService.luau")
                TestRunner.truthy(
                    string.find(source, "local function blocksRoute(angle: number)", 1, true) ~= nil
                        and string.find(source, "exitFacing", 1, true) ~= nil,
                    "the briar ring no longer reserves both its entrance and exit gaps"
                )
                TestRunner.truthy(
                    string.find(source, "spine.Transparency = 1", 1, true) ~= nil
                        and string.find(source, "spine.CanQuery = false", 1, true) ~= nil,
                    "primitive briar collision again reads as visible authored clutter"
                )
                local briarRingChunk =
                    string.match(source, 'visual == "briar_ring"(.-)elseif visual == "sapfall"')
                TestRunner.truthy(briarRingChunk ~= nil, "the briar ring visual went missing")
                TestRunner.equal(
                    string.find(briarRingChunk :: string, '"mesh_deadfall_a"', 1, true),
                    nil,
                    "oversized deadfall dressing again clutters the briar ring"
                )
                TestRunner.truthy(
                    string.find(source, "HungryHomesteadFallbackShell", 1, true) ~= nil
                        and string.find(source, "HungryHomesteadLanternFallback", 1, true)
                            ~= nil,
                    "the homestead lost its replaceable shell or restrained practical light"
                )
                TestRunner.equal(
                    string.find(source, '"HomesteadSupplyCrate"', 1, true),
                    nil,
                    "the homestead again stacks primitive supply blocks over authored props"
                )
                TestRunner.truthy(
                    string.find(worldService, "local isInteractionTarget", 1, true) ~= nil
                        and string.find(worldService, "instance.Transparency = 1", 1, true)
                            ~= nil,
                    "authored interaction props no longer hide their visible primitive targets"
                )
            end,
        },
        {
            --[[
                A region a player can reach has to generate, every time.

                The generator answers three failed assemble attempts with
                the known-good fallback, and that fallback is valid by
                construction -- so nothing fails, nothing logs, and the
                region quietly serves one fixed layout to whoever drew the
                unlucky seed. The Crown did it on 132 seeds in 2,000 while
                its own validity sweep was green, because a check that asks
                "is this manifest valid" cannot see a substitution.

                Per-region sweeps live in each region's own spec; this one
                is here because the rule is about the *open set*: whatever
                joins it next has to arrive generating, and a region shut
                behind its flag is allowed to be unfinished.
            ]]
            name = "every open region generates rather than falling back",
            run = function()
                local ExpeditionGenerator = require("../../src/shared/ExpeditionGenerator")
                local Regions = require("../../src/shared/Content/Definitions/Regions")
                for _, region in Regions do
                    if region.enabled == true then
                        for seed = 1, 200 do
                            local manifest =
                                ExpeditionGenerator.generate(seed, false, nil, region.id)
                            TestRunner.equal(
                                manifest.source,
                                "generated",
                                string.format(
                                    "%s fell back to its known-good walk on seed %d",
                                    region.id,
                                    seed
                                )
                            )
                        end
                    end
                end
            end,
        },
        {
            --[[
                Every material a region's nodes pay must be one the ledger
                already accepts. This is the #212 lesson applied one layer
                earlier: there, a reward shape the ledger refused meant a
                node that paid nothing, silently, for weeks. A node made of
                a material nobody registered is the same bug with a longer
                fuse, and it is cheap to refuse here.
            ]]
            name = "every region's nodes are made of materials the ledger knows",
            run = function()
                local ExpeditionInventory = require("../../src/shared/ExpeditionInventory")
                local registrySource = fs.readFile("src/server/World/RegionBuilders.luau")
                for _, region in REGIONS do
                    local regionId = region.catalog.RegionId
                    --[[
                        The node material list lives beside the builders
                        (it is a fact about the region's world, not its
                        economy), and RegionBuilders cannot be required
                        here -- it reaches for `script` like every server
                        module. So the ids are read out of its source, from
                        the region's own slice of the table.
                    ]]
                    -- take everything from this region's key to the next
                    -- region key (or the end of the table), which is its slice
                    local afterKey = string.match(registrySource, regionId .. " = table(.*)$")
                    local slice = if afterKey == nil
                        then nil
                        else string.match(afterKey, "^(.-)\n    region_") or afterKey
                    TestRunner.truthy(
                        slice ~= nil,
                        regionId .. " has no node material list beside the builders"
                    )
                    local seen = 0
                    for materialId in string.gmatch(slice or "", 'id = "(material_[a-z_]+)"') do
                        seen += 1
                        local _, result = ExpeditionInventory.addUnbanked(
                            ExpeditionInventory.default(),
                            "spec:" .. materialId,
                            "spechash",
                            { materialId = materialId, amount = 1 },
                            1000
                        )
                        TestRunner.truthy(
                            result.applied,
                            regionId .. " plants a node the ledger refuses: " .. materialId
                        )
                    end
                    TestRunner.truthy(seen >= 3, regionId .. " has too few node materials")
                end
            end,
        },
        {
            --[[
                An event's steps are the event. "Turn the three latches"
                is three places a player has to stand, and a step with no
                offset has nowhere to happen -- the prompt would sit on
                top of the socket, or nowhere at all. The assembly reads
                these offsets straight from the catalog, so the catalog is
                where they have to be right.
            ]]
            name = "every event step names a place it happens",
            run = function()
                for _, region in REGIONS do
                    for _, event in region.catalog.Events do
                        TestRunner.truthy(
                            #event.steps >= 2,
                            event.id .. " asks for nothing the player can stand at"
                        )
                        local seen: { [string]: boolean } = {}
                        for _, step in event.steps do
                            TestRunner.equal(
                                seen[step.id],
                                nil,
                                event.id .. " repeats step id " .. tostring(step.id)
                            )
                            seen[step.id] = true
                            TestRunner.truthy(
                                type(step.offset) == "table",
                                event.id .. "/" .. tostring(step.id) .. " has no offset"
                            )
                            local x = tonumber(step.offset.x) or 0
                            local z = tonumber(step.offset.z) or 0
                            TestRunner.truthy(
                                math.abs(x) + math.abs(z) > 0,
                                event.id
                                    .. "/"
                                    .. tostring(step.id)
                                    .. " sits on top of its own socket"
                            )
                            -- and inside the module it belongs to, or the
                            -- prompt lands in the next module's ground
                            TestRunner.truthy(
                                math.abs(x) <= 30 and math.abs(z) <= 30,
                                event.id .. "/" .. tostring(step.id) .. " falls outside its module"
                            )
                        end
                    end
                end
            end,
        },
        {
            --[[
                Every new encounter needs somewhere to happen, and the
                arena has to belong to the region whose catalog can
                actually place it. An arena filed under the wrong region
                is a fight that never loads; an encounter with no arena is
                a fight with nowhere to stand.
            ]]
            name = "every new encounter has an arena in its own region",
            run = function()
                local registrySource = fs.readFile("src/server/World/RegionBuilders.luau")
                local expected = {
                    { id = "elite_foreman_echo", regionId = "region_ironroot" },
                    { id = "elite_iron_widow", regionId = "region_ironroot" },
                    { id = "boss_bellows_maw", regionId = "region_ironroot" },
                    { id = "elite_many_face", regionId = "region_mireglass" },
                    { id = "elite_drowned_caller", regionId = "region_mireglass" },
                    { id = "boss_lantern_witch", regionId = "region_mireglass" },
                    { id = "elite_lighthouse_eater", regionId = "region_tempest" },
                    { id = "elite_admiral_wreck", regionId = "region_tempest" },
                    { id = "boss_tidebound_titan", regionId = "region_tempest" },
                    { id = "elite_abbey_silence", regionId = "region_frostmere" },
                    { id = "elite_aurora_hart", regionId = "region_frostmere" },
                    { id = "boss_white_howler", regionId = "region_frostmere" },
                    { id = "elite_lead_actor", regionId = "region_cinderfall" },
                    { id = "elite_glass_bailiff", regionId = "region_cinderfall" },
                    { id = "boss_ash_regent", regionId = "region_cinderfall" },
                }
                for _, entry in expected do
                    local slice =
                        string.match(registrySource, entry.id .. " = table%.freeze%({(.-)%}%)")
                    TestRunner.truthy(slice ~= nil, entry.id .. " has no arena")
                    TestRunner.truthy(
                        string.find(slice or "", entry.regionId, 1, true) ~= nil,
                        entry.id .. " has an arena in the wrong region"
                    )
                    local radius = tonumber(string.match(slice or "", "radius = (%d+)"))
                    -- big enough that a fight can be walked, small enough
                    -- that a telegraph still reaches the far side
                    TestRunner.truthy(
                        radius ~= nil and radius >= 24 and radius <= 44,
                        entry.id .. " has an unusable arena radius"
                    )
                end
            end,
        },
        {
            --[[
                The arena builds its interaction anchors from the
                encounter's own id list, so those lists are what keep the
                world and the fight in agreement. Each must be non-empty
                and free of duplicates, or two of a fight's steps land on
                the same anchor and one of them can never be done.
            ]]
            name = "each encounter's interaction ids can each get their own anchor",
            run = function()
                local ForemanEcho = require("../../src/shared/ForemanEchoEncounter")
                local IronWidow = require("../../src/shared/IronWidowEncounter")
                local BellowsMaw = require("../../src/shared/BellowsMawEncounter")
                local ManyFace = require("../../src/shared/ManyFaceEncounter")
                local DrownedCaller = require("../../src/shared/DrownedCallerEncounter")
                local LanternWitch = require("../../src/shared/LanternWitchEncounter")

                local lists = {
                    { label = "foreman levers", ids = ForemanEcho.LeverIds },
                    { label = "widow anchors", ids = IronWidow.AnchorIds },
                    { label = "caller pools", ids = DrownedCaller.PoolIds },
                    { label = "witch copies", ids = LanternWitch.CopyIds },
                }
                for _, entry in lists do
                    local seen: { [string]: boolean } = {}
                    local count = 0
                    for _, id in entry.ids do
                        TestRunner.equal(seen[id], nil, entry.label .. " repeats " .. tostring(id))
                        seen[id] = true
                        count += 1
                    end
                    TestRunner.truthy(count >= 3, entry.label .. " has too few to space out")
                end

                -- keyed sets rather than arrays, counted the same way
                for _, entry in
                    {
                        { label = "maw lines", ids = BellowsMaw.LineIds },
                        { label = "maw vents", ids = BellowsMaw.VentIds },
                        { label = "many-face mirrors", ids = ManyFace.MirrorIds },
                    }
                do
                    local count = 0
                    for _ in entry.ids do
                        count += 1
                    end
                    TestRunner.truthy(count >= 2, entry.label .. " has too few to space out")
                end
            end,
        },
    },
}
