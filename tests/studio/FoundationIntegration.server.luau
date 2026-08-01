--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "shared root unavailable in Studio integration test")

local serverRoot = ServerScriptService:WaitForChild("LastLightServer", 8)
assert(serverRoot ~= nil, "server root unavailable in Studio integration test")

local Config = require(root.Config)
local BramblewakeExpedition = require(root.Content.Definitions.BramblewakeExpedition)
local BramblewakeEnemies = require(root.BramblewakeEnemies)
local CombatState = require(root.CombatState)
local EnemyAttackFlow = require(root.EnemyAttackFlow)
local EnemyCombatRules = require(root.EnemyCombatRules)
local EngineerBrace = require(root.EngineerBrace)
local ExpeditionEventFlow = require(root.ExpeditionEventFlow)
local ExpeditionGenerator = require(root.ExpeditionGenerator)
local OldGrowthEncounter = require(root.OldGrowthEncounter)
local WardenStagEncounter = require(root.WardenStagEncounter)
local BramblewakeBlackout = require(root.BramblewakeBlackout)
local ProfessionCatalog = require(root.ProfessionCatalog)
local ProfessionAbilityVisuals = require(root.ProfessionAbilityVisuals)
local ProfessionRescue = require(root.ProfessionRescue)
local ProfessionState = require(root.ProfessionState)
local ReviveFlow = require(root.ReviveFlow)
local RuntimeIds = require(root.RuntimeIds)
local SurvivalState = require(root.SurvivalState)
local StatusEffectState = require(root.StatusEffectState)
local TownNightIncident = require(root.TownNightIncident)
local TownGuardLastStand = require(root.TownGuardLastStand)
local SaveSchema = require(root.SaveSchema)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)
local ServiceRegistry = require(serverRoot.ServiceRegistry)
local OldGrowthBuilder = require(serverRoot.World.OldGrowthBuilder)
local WardenStagBuilder = require(serverRoot.World.WardenStagBuilder)

local content = Registry.new(Regions)
assert(Config.SaveSchemaVersion == 11, "unexpected save schema version")
assert(Config.BuildVersion == "0.36.0", "unexpected build version")
assert(content:count() == 7, "all launch region definitions must load")
assert(content:has("region_bramblewake"), "starter region is missing")
assert(#ProfessionAbilityVisuals.list() == 4, "profession ability visual catalog is incomplete")
local studioBrace = EngineerBrace.deploy(EngineerBrace.default(), 10, 12, 14, 42)
local studioBraceAfterHit, studioBraceHit = EngineerBrace.absorb(studioBrace, 9, 11)
assert(
    studioBraceHit.absorbed == 9 and studioBraceAfterHit.capacity == 5,
    "Engineer Rootline Brace contract is missing"
)
local _, studioLastStand = TownGuardLastStand.attempt(TownGuardLastStand.default(), {
    phase = "night",
    nightNumber = 2,
    lanternHealth = 60,
    eligiblePlayers = 3,
    downedPlayers = 3,
})
assert(
    studioLastStand.accepted
        and studioLastStand.lanternCost == 12
        and studioLastStand.recoveryHealth == 50,
    "Town Guard Last Stand contract is missing"
)

local calls = 0
local service = {
    Name = "StudioIntegrationService",
    Init = function()
        calls += 1
    end,
    Start = function()
        calls += 1
    end,
}

local services = ServiceRegistry.new({ integration = true })
services:register(service)
services:initialize()
services:start()

assert(calls == 2, "service lifecycle did not initialize and start")
assert(services:state() == "started", "service registry did not reach started state")

local survival = SurvivalState.create(100)
local downed = SurvivalState.damage(survival, 100, 101)
assert(downed.status == "downed", "survival contract did not enter downed state")
assert(downed.bleedoutAt == 131, "survival contract uses the wrong bleedout window")
local reviveChannel = ReviveFlow.create(10, 20, downed.revision, 102, 2.5)
local reviveDecision = ReviveFlow.evaluate(reviveChannel, 104.5, {
    reachable = true,
    reviverCanAct = true,
    reviverPresent = true,
    reviverRevision = downed.revision,
    targetDowned = true,
    targetPresent = true,
})
assert(reviveDecision.status == "complete", "revive contract did not complete")
local revived = SurvivalState.revive(downed, 104.5)
assert(revived.health == 35 and revived.status == "active", "revive health contract failed")
assert(RuntimeIds.Actions.Revive == "revive", "revive action ID changed")
assert(RuntimeIds.Actions.Dodge == "dodge", "dodge action ID changed")
assert(
    RuntimeIds.Actions.ProfessionAbility == "profession_ability",
    "profession ability action ID changed"
)
assert(
    RuntimeIds.Actions.SelectProfession == "select_profession",
    "profession selection action ID changed"
)
assert(RuntimeIds.Actions.RepairTown == "repair_town", "town repair action ID changed")
assert(
    RuntimeIds.Actions.ResolveTownIncident == "resolve_town_incident",
    "town incident action ID changed"
)
assert(
    RuntimeIds.Actions.RecoverExpeditionCache == "recover_expedition_cache",
    "recovery-cache action ID changed"
)
assert(
    RuntimeIds.Actions.SelectProfessionSpecialization == "select_profession_specialization",
    "profession specialization action ID changed"
)
assert(
    #RuntimeIds.ProfessionSpecializationInteractionIds == 12,
    "profession specialization interaction catalog is incomplete"
)
assert(
    TownNightIncident.forTheme("EMBERFALL").id == "incident_emberfall_cinders",
    "town incident catalog is missing"
)
assert(
    TownNightIncident.forTheme("EMBERFALL", 5).id == "incident_emberfall_flues",
    "alternate town incident catalog is missing"
)
local medicRescue = ProfessionRescue.resolve("profession_medic", 1, 2.5, 35, 3)
assert(medicRescue.duration < 2.5 and medicRescue.health == 45, "Medic rescue tuning is missing")
assert(RuntimeIds.Actions.OldGrowthFire == "old_growth_fire", "Old Growth action ID changed")
assert(RuntimeIds.Actions.WardenStagChoice == "warden_stag_choice", "Warden Stag action ID changed")
assert(
    RuntimeIds.Actions.BramblewakeBlackout == "bramblewake_blackout",
    "Blackout action ID changed"
)

local combat = CombatState.create(200)
local sprinting = CombatState.setSprint(combat, true, 200, true)
local drained = CombatState.advance(sprinting, 201, true)
assert(drained.stamina == 82 and drained.sprinting, "server sprint stamina contract failed")
local dodging = CombatState.dodge(drained, 201, true)
assert(dodging.stamina == 47, "server dodge cost contract failed")
assert(CombatState.avoidsDamage(dodging, 201.2), "dodge protection window is missing")
local attack = EnemyAttackFlow.create(10, 201, Config.RootlingAttackWindupSeconds)
local attackDecision = EnemyAttackFlow.evaluate(attack, attack.endsAt, {
    clearPath = true,
    inImpactArea = true,
    targetCanAct = true,
    targetPresent = true,
})
assert(attackDecision.status == "resolve", "Rootling telegraph contract did not resolve")
local enemyOrder = BramblewakeEnemies.order()
assert(#enemyOrder == 6, "Bramblewake runtime roster must contain six enemies")
assert(enemyOrder[1] == "enemy_rootling", "Bramblewake runtime roster changed order")
assert(enemyOrder[6] == "enemy_bark_ram", "Bark Ram is missing from the runtime roster")
assert(
    EnemyCombatRules.contains("lane", 0, 4, nil, 6, 12),
    "lane attack geometry did not include its readable center"
)
local briarback = BramblewakeEnemies.require("enemy_briarback")
local shieldDamage, shieldResult = EnemyCombatRules.strikeDamage(briarback, 0.8)
assert(shieldDamage == 8 and shieldResult == "shielded", "Briarback shield contract failed")
local drowsy = StatusEffectState.applyDrowsy(StatusEffectState.create(), 300, 3, 0.65)
assert(
    StatusEffectState.snapshot(drowsy, 301).movementMultiplier == 0.65,
    "Pollen Wisp drowsy contract failed"
)
local rooted = StatusEffectState.applyRooted(StatusEffectState.create(), 300, 1.6, 0.35)
assert(
    StatusEffectState.snapshot(rooted, 301).movementMultiplier == 0.35,
    "Old Growth rooted contract failed"
)

local oldGrowth = OldGrowthEncounter.create("studio_run", "studio_manifest", true)
oldGrowth = OldGrowthEncounter.activate(oldGrowth, 10)
for _ = 1, 4 do
    oldGrowth = OldGrowthEncounter.strike(oldGrowth, 10, 34)
end
assert(
    oldGrowth.status == "shielded" and oldGrowth.health == 240,
    "Old Growth first shield contract failed"
)
oldGrowth = OldGrowthEncounter.takeFire(oldGrowth, 10, 400)
oldGrowth = OldGrowthEncounter.burnHeart(oldGrowth, 10, 401)
assert(oldGrowth.status == "vulnerable", "Old Growth fire break did not expose the heart")
for _ = 1, 4 do
    oldGrowth = OldGrowthEncounter.strike(oldGrowth, 10, 34)
end
assert(
    oldGrowth.status == "shielded" and oldGrowth.health == 120,
    "Old Growth second shield contract failed"
)
oldGrowth = OldGrowthEncounter.takeFire(oldGrowth, 10, 410)
oldGrowth = OldGrowthEncounter.burnHeart(oldGrowth, 10, 411)
for _ = 1, 4 do
    oldGrowth = OldGrowthEncounter.strike(oldGrowth, 10, 34)
end
local oldGrowthWinner = OldGrowthEncounter.snapshot(oldGrowth, 10, 412)
local oldGrowthLateArrival = OldGrowthEncounter.snapshot(oldGrowth, 20, 412)
assert(oldGrowth.status == "complete", "Old Growth completion contract failed")
assert(oldGrowthWinner.rewardEligible, "Old Growth participant lost reward eligibility")
assert(not oldGrowthLateArrival.rewardEligible, "late arrival received false reward eligibility")
assert(
    OldGrowthEncounter.rewardTransactionId(oldGrowth, 10)
        == "elite_old_growth:studio_run:studio_manifest:10",
    "Old Growth reward transaction is not stable"
)
local oldGrowthModel = OldGrowthBuilder.build(Vector3.new(0, 0, 0), Vector3.new(0, 0, -10), 360)
assert(oldGrowthModel.PrimaryPart ~= nil, "Old Growth model has no primary part")
assert(
    oldGrowthModel:GetAttribute("EliteId") == "elite_old_growth",
    "Old Growth model is missing its stable ID"
)
oldGrowthModel:Destroy()

local wardenStag = WardenStagEncounter.create("studio_run", "studio_manifest", true)
wardenStag = WardenStagEncounter.unlock(wardenStag)
wardenStag = WardenStagEncounter.activate(wardenStag, 10)
for _, nodeId in { "root_node_north", "root_node_east" } do
    wardenStag = WardenStagEncounter.cleanseRoot(wardenStag, 10, nodeId)
end
assert(wardenStag.status == "vulnerable", "Warden Stag roots did not expose phase one")
for _ = 1, 4 do
    wardenStag = WardenStagEncounter.strike(wardenStag, 10, 40)
end
for _, nodeId in { "root_node_north", "root_node_east", "root_node_south" } do
    wardenStag = WardenStagEncounter.cleanseRoot(wardenStag, 10, nodeId)
end
for _ = 1, 4 do
    wardenStag = WardenStagEncounter.strike(wardenStag, 10, 40)
end
for _, nodeId in
    {
        "root_node_north",
        "root_node_east",
        "root_node_south",
        "root_node_west",
    }
do
    wardenStag = WardenStagEncounter.cleanseRoot(wardenStag, 10, nodeId)
end
for _ = 1, 4 do
    wardenStag = WardenStagEncounter.strike(wardenStag, 10, 40)
end
assert(wardenStag.status == "complete", "Warden Stag completion contract failed")
assert(wardenStag.outcome == "preserved", "clean Warden Stag route did not preserve the forest")
assert(
    WardenStagEncounter.rewardTransactionId(wardenStag, 10)
        == "boss_warden_stag:studio_run:studio_manifest:10",
    "Warden Stag reward transaction is not stable"
)
local wardenModel = WardenStagBuilder.build(Vector3.new(0, 0, 0), Vector3.new(0, 0, -10), 480)
assert(wardenModel.PrimaryPart ~= nil, "Warden Stag model has no primary part")
assert(
    wardenModel:GetAttribute("BossId") == "boss_warden_stag",
    "Warden Stag model is missing its stable ID"
)
wardenModel:Destroy()

local blackout = BramblewakeBlackout.create("studio_run", "studio_manifest", true, 540)
blackout = BramblewakeBlackout.start(blackout, 10, 500)
for _, nodeId in
    {
        "blackout_root_farm",
        "blackout_root_mill",
        "blackout_root_cathedral",
    }
do
    blackout = BramblewakeBlackout.takeFire(blackout, 10, 501)
    blackout = BramblewakeBlackout.deliverFire(blackout, 10, nodeId, 502)
end
assert(blackout.status == "old_growth", "Blackout relay did not unlock Old Growth")
blackout = BramblewakeBlackout.completeOldGrowth(blackout)
assert(blackout.status == "warden", "Blackout did not advance to the Warden")
blackout = BramblewakeBlackout.completeWarden(blackout, "preserved")
blackout = BramblewakeBlackout.vote(blackout, 10, "shared_agroforest", { 10 })
assert(blackout.status == "complete", "Blackout chapter vote did not resolve")
assert(
    BramblewakeBlackout.chapterTransactionId(blackout, 10)
        == "chapter_1:studio_run:studio_manifest:10",
    "Blackout chapter transaction is not stable"
)
local profile = SaveSchema.default(500)
local resolvedProfile, chapterResult = SaveSchema.withChapterOneResolution(
    profile,
    BramblewakeBlackout.chapterTransactionId(blackout, 10),
    blackout.decision,
    blackout.wardenOutcome,
    600
)
assert(chapterResult.applied, "chapter one result did not persist")
assert(
    resolvedProfile.story.chapterOne.decision == "shared_agroforest",
    "chapter one decision changed during persistence"
)

local profession =
    ProfessionState.create(ProfessionCatalog.Ids.Warden, workspace:GetServerTimeNow())
local professionDecision = ProfessionState.canUse(profession, workspace:GetServerTimeNow(), true)
assert(professionDecision.accepted, "Warden profession ability should begin ready")
local guarding = ProfessionState.commitAbility(profession, workspace:GetServerTimeNow())
assert(
    ProfessionState.mitigatesDamage(guarding, workspace:GetServerTimeNow()),
    "Warden profession guard window is missing"
)

local runtime = ReplicatedStorage:WaitForChild(RuntimeIds.FolderName, 8)
assert(runtime ~= nil, "runtime networking folder did not initialize")
assert(runtime:GetAttribute("SchemaVersion") == 1, "unexpected network schema")
assert(runtime:GetAttribute("WorldReady") == true, "world never became ready")
local actionRequest = runtime:FindFirstChild(RuntimeIds.Remotes.ActionRequest)
local stateChanged = runtime:FindFirstChild(RuntimeIds.Remotes.StateChanged)
local getState = runtime:FindFirstChild(RuntimeIds.Remotes.GetState)
assert(actionRequest ~= nil and actionRequest:IsA("RemoteEvent"), "missing action remote")
assert(stateChanged ~= nil and stateChanged:IsA("RemoteEvent"), "missing state remote")
assert(getState ~= nil and getState:IsA("RemoteFunction"), "missing state function")

local world = workspace:WaitForChild(RuntimeIds.WorldName, 8)
assert(world ~= nil and world:IsA("Model"), "first-ten-minutes world did not build")
assert(
    world:FindFirstChild("EngineerRootlineBrace") == nil,
    "Engineer Rootline Brace must not exist before Emergency Patch"
)
assert(
    world:FindFirstChild("TownGuardLastStand") == nil,
    "Town Guard Last Stand must not exist before a whole-party recovery"
)
assert(world:GetAttribute("Ready") == true, "world model is not marked ready")
assert(
    world:GetAttribute("WorldVersion") == "bramblewake-blackout-v17",
    "world model version does not match the current build"
)
assert(world:FindFirstChild("ArrivalSpawn", true) ~= nil, "arrival spawn is missing")
assert(world:FindFirstChild("Mara", true) ~= nil, "Mara is missing")
local mara = world:FindFirstChild("Mara", true)
assert(mara ~= nil and mara:IsA("Model"), "Mara must be a physical resident model")
assert(mara:FindFirstChild("CoatShoulder") ~= nil, "Mara needs a layered clothing silhouette")
assert(mara:FindFirstChild("Nose") ~= nil, "Mara needs a readable face")
assert(mara:FindFirstChild("FieldSatchel") ~= nil, "Mara needs her role-specific field prop")
assert(world:FindFirstChild("HeartwoodStump", true) ~= nil, "gather node is missing")
assert(world:FindFirstChild("ConstructionPlot", true) ~= nil, "construction plot is missing")
assert(world:FindFirstChild("FirstLantern", true) ~= nil, "First Lantern is missing")
local heroDetailCounts = {
    HeartwoodRoot = 0,
    HeartwoodShard = 0,
    BarricadeWorkPost = 0,
    FirstLanternCagePost = 0,
    ArchiveNotice = 0,
}
for _, descendant in world:GetDescendants() do
    if heroDetailCounts[descendant.Name] ~= nil then
        heroDetailCounts[descendant.Name] += 1
    end
end
assert(heroDetailCounts.HeartwoodRoot == 6, "Heartwood needs a rooted physical silhouette")
assert(heroDetailCounts.HeartwoodShard == 3, "Heartwood needs faceted gathered material")
assert(heroDetailCounts.BarricadeWorkPost == 5, "construction plot needs visible work in progress")
assert(heroDetailCounts.FirstLanternCagePost == 4, "First Lantern needs a physical metal cage")
assert(heroDetailCounts.ArchiveNotice == 5, "archive needs readable physical field notices")
local roadSegments = 0
local roadEdgeStones = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "EmberhollowRoad" then
        roadSegments += 1
    elseif descendant.Name == "RoadEdgeStone" then
        roadEdgeStones += 1
    end
end
assert(roadSegments == 6, "arrival road must connect every authored route segment")
assert(roadEdgeStones >= 40, "arrival road needs a repeated visible stone edge")
local cabinRafters = 0
local cabinHearths = 0
local cabinFirewood = 0
local cabinRugs = 0
local campCommons = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "CabinInteriorRafter" then
        cabinRafters += 1
    elseif descendant.Name == "CabinHearthFire" then
        cabinHearths += 1
    elseif descendant.Name == "SplitFirewood" then
        cabinFirewood += 1
    elseif descendant.Name == "CabinWovenRug" then
        cabinRugs += 1
    elseif descendant.Name == "EmberhollowCampCommons" then
        campCommons += 1
    end
end
assert(cabinRafters == 6, "both cabins need three visible interior rafters")
assert(cabinHearths == 2, "both cabins need a practical stone hearth")
assert(cabinFirewood == 10, "both cabin exteriors need stocked firewood")
assert(cabinRugs == 2, "both cabins need an inhabited interior floor layer")
assert(campCommons == 1, "Emberhollow needs one physical communal gathering area")
local toolDisplays = 0
local craftingDisplays = 0
for _, descendant in world:GetDescendants() do
    if descendant:IsA("Model") and string.sub(descendant.Name, 1, 12) == "ToolDisplay_" then
        toolDisplays += 1
        assert(
            descendant:FindFirstChild("ToolDisplayCrate") ~= nil
                and descendant:FindFirstChild("ToolDisplayOpenLid") ~= nil,
            "starter tools need physical open supply displays"
        )
    elseif descendant:IsA("Model") and string.sub(descendant.Name, 1, 16) == "CraftingDisplay_" then
        craftingDisplays += 1
        assert(
            descendant:FindFirstChild("CraftingTableTop") ~= nil and #descendant:GetChildren() >= 10,
            "crafting recipes need supported worktables and physical samples"
        )
    end
end
assert(toolDisplays == 3, "all three starter tools need physical displays")
assert(craftingDisplays == 4, "all four starter recipes need physical displays")
local builderMaterialSets = 0
local completedBuildingFrames = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "BuilderMaterials" then
        builderMaterialSets += 1
    elseif descendant.Name == "BuildingCornerPost" then
        completedBuildingFrames += 1
    end
end
assert(builderMaterialSets >= 2, "fresh town construction sites need visible material stacks")
assert(completedBuildingFrames >= 4, "completed town buildings need structural corner framing")
assert(world:GetAttribute("TownIntegrity") == 100, "new towns must begin fully repaired")
assert(world:GetAttribute("TownDamageLevel") == 0, "new towns cannot begin visibly damaged")
assert(
    world:FindFirstChild("TownDamageConsequences") == nil,
    "pristine towns cannot build repair debris"
)

local expedition = world:FindFirstChild("BramblewakeExpedition")
assert(expedition ~= nil and expedition:IsA("Model"), "Bramblewake expedition is missing")
assert(expedition:GetAttribute("Ready") == true, "Bramblewake expedition is not ready")
assert(
    expedition:FindFirstChild("ProceduralCrookedFarmhouseShell", true) ~= nil,
    "Crooked Farm needs its collision-safe procedural shell"
)
assert(
    expedition:FindFirstChild("ProceduralFoxfireMillTowerShell", true) ~= nil,
    "Foxfire Mill needs its collision-safe procedural shell"
)
assert(
    expedition:FindFirstChild("WindmillRotor", true) ~= nil,
    "Foxfire Mill must retain its independently animated rotor"
)
local meshDeadline = os.clock() + 12
while expedition:GetAttribute("AuthoredMeshCount") == nil and os.clock() < meshDeadline do
    task.wait(0.1)
end
local expeditionAuthoredMeshes = expedition:GetAttribute("AuthoredMeshCount")
local expeditionMeshFallbacks = expedition:GetAttribute("AuthoredMeshFallbackCount")
assert(
    type(expeditionAuthoredMeshes) == "number"
        and type(expeditionMeshFallbacks) == "number"
        and expeditionAuthoredMeshes + expeditionMeshFallbacks == 2,
    "Bramblewake must resolve both curated landmark mesh placements"
)
assert(
    expedition:GetAttribute("ModuleCount") == BramblewakeExpedition.ModuleCount,
    "Bramblewake module count is incorrect"
)
assert(
    expedition:GetAttribute("PointOfInterestCount") == BramblewakeExpedition.PointOfInterestCount,
    "Bramblewake POI count is incorrect"
)
assert(
    expedition:GetAttribute("EventCount") == BramblewakeExpedition.EventCount,
    "Bramblewake event count is incorrect"
)
local expectedStoryLandmarks = 0
local expectedStoryLandmarkParts = 0
for _, definition in BramblewakeExpedition.Modules do
    if definition.storyLandmark ~= nil then
        expectedStoryLandmarks += 1
        expectedStoryLandmarkParts += definition.storyPartCount
    end
end
assert(
    expedition:GetAttribute("StoryLandmarkCount") == expectedStoryLandmarks,
    "Bramblewake must build every authored environmental story landmark"
)
assert(
    expedition:GetAttribute("StoryLandmarkPartCount") == expectedStoryLandmarkParts,
    "Bramblewake story landmark part count must match its authored budget"
)
assert(expedition:GetAttribute("BossArenaReady") == true, "Warden Stag arena is not ready")
assert(expedition:GetAttribute("BlackoutLayerReady") == true, "Blackout layer is not ready")
local expectedManifest = ExpeditionGenerator.generate(Config.BramblewakePreviewSeed)
assert(
    expedition:GetAttribute("ManifestHash") == expectedManifest.hash,
    "Bramblewake manifest does not replay deterministically"
)
local generatedPartCount = expedition:GetAttribute("GeneratedPartCount")
assert(
    type(generatedPartCount) == "number"
        and generatedPartCount >= 200
        and generatedPartCount
            <= BramblewakeExpedition.PartBudget + BramblewakeExpedition.BossArenaPartBudget + BramblewakeExpedition.BlackoutPartBudget,
    "Bramblewake preview is outside its detailed mobile part budget"
)
local criticalPaths = 0
local trailWear = 0
local trailEdges = 0
local roadMarkers = 0
local roadSigns = 0
for _, descendant in expedition:GetDescendants() do
    if descendant.Name == "CriticalPath" then
        criticalPaths += 1
    elseif descendant.Name == "EvacuationTrailWear" then
        trailWear += 1
    elseif descendant.Name == "EvacuationTrailEdge" then
        trailEdges += 1
    elseif descendant.Name == "EvacuationRoadMarker" then
        roadMarkers += 1
    elseif descendant.Name == "EvacuationRoadSign" then
        roadSigns += 1
    end
end
assert(criticalPaths == 22, "every Bramblewake connection needs two joined trail arms")
assert(trailWear == criticalPaths, "every Bramblewake trail arm needs a worn center")
assert(trailEdges == criticalPaths * 2, "every Bramblewake trail arm needs two visible edges")
assert(roadMarkers == 6 and roadSigns == 6, "the critical route needs six direction markers")

local tagged = CollectionService:GetTagged(RuntimeIds.InteractionTag)
assert(
    #tagged
        == 26
            + BramblewakeExpedition.EventInteractionCount
            + #RuntimeIds.ProfessionSpecializationInteractionIds,
    "expected tutorial, event, elite, boss, extraction, crafting, and mastery prompts"
)
local taggedByInteractionId = {}
for _, prompt in tagged do
    local interactionId = prompt:GetAttribute("InteractionId")
    if type(interactionId) == "string" then
        assert(taggedByInteractionId[interactionId] == nil, "duplicate interaction prompt ID")
        taggedByInteractionId[interactionId] = prompt
    end
end
for specializationId, interactionId in
    RuntimeIds.ProfessionSpecializationInteractionIdBySpecialization
do
    local prompt = taggedByInteractionId[interactionId]
    assert(prompt ~= nil, "generated mastery prompt is missing: " .. interactionId)
    assert(
        prompt:GetAttribute("ActionId") == RuntimeIds.Actions.SelectProfessionSpecialization,
        "generated mastery prompt routes to the wrong action"
    )
    assert(
        prompt:GetAttribute("Payload") == specializationId,
        "generated mastery prompt has the wrong specialization payload"
    )
end
assert(
    #CollectionService:GetTagged(RuntimeIds.PlayerDownedTag) == 0,
    "players must not begin the test downed"
)
local expeditionModules = CollectionService:GetTagged(RuntimeIds.ExpeditionModuleTag)
assert(
    #expeditionModules == BramblewakeExpedition.ModuleCount,
    "expected twelve streamed expedition modules"
)
for _, module in expeditionModules do
    assert(module:IsA("Model"), "expedition module tag must only target models")
    assert(
        module.ModelStreamingMode == Enum.ModelStreamingMode.Atomic,
        "expedition modules must stream atomically"
    )
    assert(
        module:FindFirstChild("StreamingCellCollision") ~= nil,
        "expedition module is missing collision"
    )
    assert(
        module:FindFirstChild("CriticalPath") ~= nil,
        "expedition module is missing its connected critical path"
    )
end
local ambientMotionTargets = CollectionService:GetTagged(RuntimeIds.AmbientMotionTag)
assert(#ambientMotionTargets >= 1, "expected at least one living-world motion target")
local foundResidentMotion = false
local foundRotorMotion = false
for _, target in ambientMotionTargets do
    assert(target:IsA("Model"), "ambient motion tags must target models")
    assert(target.PrimaryPart ~= nil, "ambient motion model is missing its pivot")
    local motionKind = target:GetAttribute("MotionKind")
    assert(motionKind == "rotor" or motionKind == "resident", "ambient motion kind is unsupported")
    foundResidentMotion = foundResidentMotion or motionKind == "resident"
    foundRotorMotion = foundRotorMotion or motionKind == "rotor"
    assert(
        (tonumber(target:GetAttribute("MotionSpeed")) or 0) > 0,
        "ambient motion target must declare a positive speed"
    )
end
assert(foundResidentMotion, "Mara is missing resident motion")
assert(foundRotorMotion, "Windmill Copse is missing rotor motion")
local ambientLightTargets = CollectionService:GetTagged(RuntimeIds.AmbientLightTag)
assert(#ambientLightTargets >= 6, "expected practical town and expedition lights to animate")
for _, target in ambientLightTargets do
    assert(target:IsA("BasePart"), "ambient light tags must target BaseParts")
    assert(not target.CanCollide, "ambient light motion cannot own collision")
end
local ambientSwayTargets = CollectionService:GetTagged(RuntimeIds.AmbientSwayTag)
assert(#ambientSwayTargets >= 120, "expected authored foliage sway coverage")
for _, target in ambientSwayTargets do
    assert(target:IsA("BasePart"), "ambient sway tags must target BaseParts")
    assert(not target.CanCollide, "ambient foliage motion cannot own collision")
    assert(not target.CanQuery, "ambient foliage motion cannot affect targeting")
end
local blackoutLayer = expedition:FindFirstChild("BramblewakeBlackoutLayer")
assert(blackoutLayer ~= nil and blackoutLayer:IsA("Model"), "Bramblewake Blackout layer is missing")
assert(
    blackoutLayer.ModelStreamingMode == Enum.ModelStreamingMode.Atomic,
    "Bramblewake Blackout layer must stream atomically"
)
local blackoutTargets = CollectionService:GetTagged(RuntimeIds.ExpeditionBlackoutTag)
assert(#blackoutTargets == 7, "expected four relay and three decision targets")
for _, target in blackoutTargets do
    assert(target:IsA("BasePart"), "Blackout tags must target BaseParts")
    local prompt = target:FindFirstChildOfClass("ProximityPrompt")
    assert(prompt ~= nil and not prompt.Enabled, "Blackout prompts must begin dormant")
    assert(
        prompt:GetAttribute("ActionId") == RuntimeIds.Actions.BramblewakeBlackout,
        "Blackout prompt does not route to its server action"
    )
end
local poiTargets = CollectionService:GetTagged(RuntimeIds.ExpeditionPointOfInterestTag)
assert(#poiTargets == BramblewakeExpedition.PointOfInterestCount, "expected four Bramblewake POIs")
local poiVisuals = {}
for _, target in poiTargets do
    assert(target:IsA("BasePart"), "POI tags must target stable anchor parts")
    local landmark = target.Parent
    assert(landmark ~= nil and landmark:IsA("Model"), "POI anchor needs a physical landmark model")
    local visualKind = landmark:GetAttribute("VisualKind")
    local physicalPartCount = landmark:GetAttribute("PhysicalPartCount")
    assert(type(visualKind) == "string", "physical POI is missing its visual kind")
    assert(not poiVisuals[visualKind], "physical POI visual kinds must remain distinct")
    assert(
        type(physicalPartCount) == "number" and physicalPartCount >= 10,
        "every POI needs enough physical geometry to read without its label"
    )
    poiVisuals[visualKind] = true
end
assert(
    poiVisuals.ruined_homestead
        and poiVisuals.moth_well
        and poiVisuals.sap_grove
        and poiVisuals.root_chapel,
    "Bramblewake needs four distinct physical POI silhouettes"
)
assert(
    #CollectionService:GetTagged(RuntimeIds.ExpeditionEventTag) == BramblewakeExpedition.EventCount,
    "expected eight Bramblewake event sockets"
)
local eventSteps = CollectionService:GetTagged(RuntimeIds.ExpeditionEventStepTag)
assert(
    #eventSteps == BramblewakeExpedition.EventInteractionCount,
    string.format(
        "expected every Bramblewake event interaction step: actual=%d expected=%d",
        #eventSteps,
        BramblewakeExpedition.EventInteractionCount
    )
)
for _, target in eventSteps do
    assert(target:IsA("BasePart"), "event step tags must target BaseParts")
    local eventId = target:GetAttribute("EventId")
    local stepId = target:GetAttribute("EventStepId")
    assert(
        type(eventId) == "string" and type(stepId) == "string",
        "event step is missing stable IDs"
    )
    local prompt = target:FindFirstChildOfClass("ProximityPrompt")
    assert(prompt ~= nil and prompt.Enabled, "event step must have an enabled interaction")
    assert(
        prompt:GetAttribute("InteractionId") == ExpeditionEventFlow.interactionId(eventId, stepId),
        "event interaction ID does not match its contract"
    )
    assert(
        prompt:GetAttribute("ActionId") == RuntimeIds.Actions.ExpeditionEvent,
        "event prompt does not route to the server event action"
    )
end
for _, socket in CollectionService:GetTagged(RuntimeIds.ExpeditionEventTag) do
    assert(socket:GetAttribute("Status") == "dormant", "event must begin dormant")
    assert(socket:GetAttribute("Progress") == 0, "event must begin without progress")
    assert(
        socket:GetAttribute("ProgressTotal") >= 2,
        "event must require multiple readable interactions"
    )
    assert(socket.Transparency == 1 and not socket.CanCollide, "event anchors must stay invisible")
    local scene = socket.Parent
        and socket.Parent:FindFirstChild(
            "EventScene_" .. tostring(socket:GetAttribute("ContentId"))
        )
    assert(scene ~= nil and scene:IsA("Model"), "event needs a dedicated physical scene")
    assert(
        type(scene:GetAttribute("VisualKind")) == "string"
            and (tonumber(scene:GetAttribute("PhysicalPartCount")) or 0) >= 4,
        "event scene needs a distinct visual kind and enough physical construction"
    )
end
local eliteTargets = CollectionService:GetTagged(RuntimeIds.ExpeditionEliteTag)
assert(#eliteTargets == 2, "expected Old Growth fire and root-heart targets")
for _, target in eliteTargets do
    assert(target:GetAttribute("EliteId") == "elite_old_growth", "elite target ID changed")
    local prompt = target:FindFirstChildOfClass("ProximityPrompt")
    assert(prompt ~= nil and not prompt.Enabled, "Old Growth prompts must begin dormant")
    assert(
        prompt:GetAttribute("ActionId") == RuntimeIds.Actions.OldGrowthFire,
        "Old Growth prompt does not route to its server action"
    )
end
local bossArena = expedition:FindFirstChild("WardenSealAnnex")
assert(bossArena ~= nil and bossArena:IsA("Model"), "Warden Stag arena model is missing")
assert(
    bossArena.ModelStreamingMode == Enum.ModelStreamingMode.Atomic,
    "Warden Stag arena must stream atomically"
)
local bossTargets = CollectionService:GetTagged(RuntimeIds.ExpeditionBossTag)
assert(#bossTargets == 6, "expected four Warden roots and two antler choices")
for _, target in bossTargets do
    assert(target:GetAttribute("BossId") == "boss_warden_stag", "boss target ID changed")
    local prompt = target:FindFirstChildOfClass("ProximityPrompt")
    assert(prompt ~= nil and not prompt.Enabled, "Warden Stag prompts must begin locked")
    assert(
        prompt:GetAttribute("ActionId") == RuntimeIds.Actions.WardenStagChoice,
        "Warden Stag prompt does not route to its server action"
    )
end
local extractionTargets = CollectionService:GetTagged(RuntimeIds.ExpeditionExtractionTag)
assert(#extractionTargets == 1, "expected one Wayhome extraction target")
local extractionTarget = extractionTargets[1]
assert(
    extractionTarget:GetAttribute("ExtractionId") == "extraction_bw_wayhome",
    "Wayhome target is missing its stable extraction ID"
)
local extractionPrompt = extractionTarget:FindFirstChildOfClass("ProximityPrompt")
assert(extractionPrompt ~= nil and extractionPrompt.Enabled, "Wayhome extraction prompt is missing")
assert(
    extractionPrompt:GetAttribute("InteractionId") == RuntimeIds.InteractionIds.Wayhome,
    "Wayhome prompt uses the wrong interaction ID"
)
assert(
    extractionPrompt:GetAttribute("ActionId") == RuntimeIds.Actions.Extract,
    "Wayhome prompt does not route to server extraction"
)
assert(
    workspace.PlayerScriptsUseInputActionSystem == Enum.RolloutState.Enabled,
    "Input Action System must be enabled"
)

print("[Last Light] PASS FoundationIntegration")
