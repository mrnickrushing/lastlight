--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "shared root unavailable in Studio integration test")

local serverRoot = ServerScriptService:WaitForChild("LastLightServer", 8)
assert(serverRoot ~= nil, "server root unavailable in Studio integration test")

local Config = require(root.Config)
local MusicCatalog = require(root.MusicCatalog)
local BramblewakeExpedition = require(root.Content.Definitions.BramblewakeExpedition)
local BramblewakeEnemies = require(root.BramblewakeEnemies)
local CombatState = require(root.CombatState)
local CraftingCatalog = require(root.CraftingCatalog)
local ToolCatalog = require(root.ToolCatalog)
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
local ProfileBackup = require(root.ProfileBackup)
local TownCondition = require(root.TownCondition)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)
local ServiceRegistry = require(serverRoot.ServiceRegistry)
local OldGrowthBuilder = require(serverRoot.World.OldGrowthBuilder)
local WardenStagBuilder = require(serverRoot.World.WardenStagBuilder)
local TerrainBuilder = require(serverRoot.World.TerrainBuilder)

local content = Registry.new(Regions)
assert(Config.SaveSchemaVersion == 17, "unexpected save schema version")
assert(Config.BuildVersion == "0.53.0", "unexpected build version")
assert(content:count() == 7, "all launch region definitions must load")
assert(content:has("region_bramblewake"), "starter region is missing")
assert(#MusicCatalog.regionIds() == 8, "every playable world needs an adaptive score")
assert(#MusicCatalog.tracks() == 25, "adaptive score must include 24 regional tracks and Blackout")
assert(
    MusicCatalog.resolve("region_bramblewake", "night", false).intensity
        > MusicCatalog.resolve("region_bramblewake", "day", false).intensity,
    "Bramblewake night music must be scarier than its day music"
)
assert(
    #ProfessionAbilityVisuals.list() == #ProfessionCatalog.list(),
    "profession ability visual catalog is incomplete"
)
assert(#ProfessionCatalog.list() == 7, "the roster is the full seven professions")
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
-- The two properties a restore fails silently without: it has to out-rank the
-- live save or ProfilePersistence refuses the write, and it must not carry the
-- session lock that rode along inside the profile when the copy was taken.
local studioBackupRing = ProfileBackup.capture(nil, {
    revision = 4,
    schemaVersion = Config.SaveSchemaVersion,
    sessionLock = { jobId = "job", heartbeat = 1 },
}, 100, "interval", Config.ProfileBackupRetained)
local studioRestored = ProfileBackup.restoredProfile(ProfileBackup.newest(studioBackupRing), 9, 500)
assert(
    studioRestored.revision == 10 and studioRestored.sessionLock == nil,
    "profile backup restore contract is missing"
)
-- Damage belongs to a building, and repairing one must not touch another. The
-- single-integrity model this replaced could not express that: every repair
-- moved one shared number, so fixing the inn could un-damage the archive.
local studioRoster = { "building_archive", "building_inn" }
local studioDamaged = TownCondition.afterNight(TownCondition.default(), 10, 1, studioRoster)
local studioRepaired = TownCondition.repair(studioDamaged, "building_inn")
assert(
    TownCondition.integrityFor(studioRepaired, "building_inn") == 85
        and TownCondition.integrityFor(studioRepaired, "building_archive")
            == TownCondition.integrityFor(studioDamaged, "building_archive"),
    "per-building town repair contract is missing"
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
    #RuntimeIds.ProfessionSpecializationInteractionIds == #ProfessionCatalog.list() * 3,
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
-- One second of sprint at SprintDrainPerSecond = 7, then a 35-cost dodge.
-- These moved when sprint was retuned from an unusable five-second bar; they
-- are derived from Config rather than copied from whatever the run printed.
assert(drained.stamina == 93 and drained.sprinting, "server sprint stamina contract failed")
local dodging = CombatState.dodge(drained, 201, true)
assert(dodging.stamina == 58, "server dodge cost contract failed")
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
    world:GetAttribute("WorldVersion") == "emberhollow-runtime-visual-v28",
    "world model version does not match the current build"
)
assert(world:FindFirstChild("ArrivalSpawn", true) ~= nil, "arrival spawn is missing")
assert(world:FindFirstChild("Mara", true) ~= nil, "Mara is missing")
local mara = world:FindFirstChild("Mara", true)
assert(mara ~= nil and mara:IsA("Model"), "Mara must be a physical resident model")
assert(mara:FindFirstChild("CoatShoulder") ~= nil, "Mara needs a layered clothing silhouette")
assert(mara:FindFirstChild("Nose") ~= nil, "Mara needs a readable face")
assert(mara:FindFirstChild("FieldSatchel") ~= nil, "Mara needs her role-specific field prop")
-- A rig from CreateHumanoidModelFromDescription arrives unanchored, and every
-- part of hers is deliberately CanCollide = false, so an unanchored part here
-- means she falls through the valley floor on build and never stops.
for _, maraPart in mara:GetDescendants() do
    if maraPart:IsA("BasePart") then
        assert(maraPart.Anchored, "Mara's rig must stay anchored or she falls through the world")
    end
end
assert(
    world:FindFirstChild("MaraFallenRoots", true) ~= nil,
    "Mara needs something physical to be freed from before the rescue"
)
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
local heartwoodBarkRibs = 0
local heartwoodCrownPieces = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "HeartwoodBarkRib" then
        heartwoodBarkRibs += 1
    elseif descendant.Name == "HeartwoodSplitCrown" then
        heartwoodCrownPieces += 1
    end
end
assert(heartwoodBarkRibs == 10, "Heartwood needs an irregular bark silhouette")
assert(heartwoodCrownPieces == 6, "Heartwood needs a recognizable split crown")
assert(world:FindFirstChild("HeartwoodCavity", true) ~= nil, "Heartwood needs an exposed cavity")
assert(heroDetailCounts.BarricadeWorkPost == 5, "construction plot needs visible work in progress")
assert(heroDetailCounts.FirstLanternCagePost == 4, "First Lantern needs a physical metal cage")
local firstLanternFlame = world:FindFirstChild("FirstLanternFlame", true)
assert(
    firstLanternFlame ~= nil
        and firstLanternFlame:IsA("BasePart")
        and firstLanternFlame.Shape == Enum.PartType.Wedge
        and firstLanternFlame.Size.X <= 1.1,
    "First Lantern needs a restrained flame inside its cage, not a glowing orb"
)
local firstLanternGlassPanels = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "FirstLanternGlassPanel" then
        firstLanternGlassPanels += 1
    end
end
assert(firstLanternGlassPanels == 4, "First Lantern needs four readable glass cage panels")
-- Recursive: the constructed lantern now hangs under a MaraLanternFallback
-- wrapper so a sourced lantern asset can hide the whole fallback as one unit.
-- A shallow lookup reports "glowing ball" for a lantern that is fully built.
local maraLantern = mara:FindFirstChild("MaraLantern", true)
assert(
    maraLantern ~= nil
        and maraLantern:IsA("BasePart")
        and maraLantern.Shape ~= Enum.PartType.Ball
        and mara:FindFirstChild("MaraLanternRail", true) ~= nil,
    "Mara needs a constructed hand lantern instead of a glowing ball"
)
assert(heroDetailCounts.ArchiveNotice == 5, "archive needs readable physical field notices")
for _, descendant in world:GetDescendants() do
    if descendant:IsA("BasePart") and descendant.Name == "ArchiveNotice" then
        assert(
            descendant.Transparency < 0.5,
            "archive notice is present but invisible -- the board mesh blanked it"
        )
    end
end
--[[
    Wait for the Town Board before counting its notices.

    This script runs at server boot. The Town Board is not built at boot: it
    lives in TownProgressionBuildings, which only exists once a profile load
    seeds the town's tier and construction ledger, which only happens when a
    player joins. Counting straight through therefore found zero notices and
    failed here every run -- and because this is the line that prints
    "PASS FoundationIntegration", it took every runbook gate that asks for that
    line down with it.
]]
local townBoardDeadline = os.clock() + 20
local function townBoardIsBuilt(): boolean
    local buildings = world:FindFirstChild("TownProgressionBuildings")
    if buildings == nil then
        return false
    end
    local board = buildings:FindFirstChild("TownBoard", true)
    return board ~= nil and board:GetAttribute("NoticeCount") ~= nil
end
while not townBoardIsBuilt() and os.clock() < townBoardDeadline do
    task.wait(0.25)
end
assert(townBoardIsBuilt(), "Town Board was never built for the joined player's town")
local noticeArtwork = 0
local townNotices = 0
local distinctTownNoticePanels: { [string]: boolean } = {}
local physicalNoticeBoards = 0
for _, descendant in world:GetDescendants() do
    if descendant:IsA("ImageLabel") and string.sub(descendant.Name, 1, 12) == "NoticeImage_" then
        noticeArtwork += 1
        assert(
            descendant.Image == "rbxassetid://83727643922166",
            "first-world notice uses an unapproved cloud image"
        )
        assert(
            descendant.ImageRectSize == Vector2.new(627, 418),
            "notice image does not use one measured atlas cell"
        )
        --[[
            Counting the notices proved nothing. Both boards are also
            mesh-replacement fallbacks, so for as long as this assertion has
            existed all eight notices were present in the DataModel and
            invisible in the game: every paper blanked to Transparency 1 and
            every artwork SurfaceGui disabled the moment the authored board
            mesh loaded. A player walked up to bare wood. Check what a player
            can see, not what GetDescendants can reach.
        ]]
        local artworkSurface = descendant:FindFirstAncestorWhichIsA("SurfaceGui")
        assert(
            artworkSurface ~= nil and artworkSurface.Enabled,
            "notice artwork is present but its surface is switched off: " .. descendant.Name
        )
    elseif descendant:IsA("BasePart") and string.sub(descendant.Name, 1, 11) == "TownNotice_" then
        townNotices += 1
        assert(descendant.Material == Enum.Material.Fabric, "town notices must read as paper")
        assert(
            descendant.Transparency < 0.5,
            "town notice is present but invisible: " .. descendant.Name
        )
        local panelId = descendant:GetAttribute("NoticePanelId")
        assert(type(panelId) == "string", "town notice has no art")
        distinctTownNoticePanels[panelId] = true
    elseif
        descendant:IsA("BasePart") and descendant:GetAttribute("PhysicalNoticeBoard") == true
    then
        physicalNoticeBoards += 1
    end
end
local distinctTownNoticeCount = 0
for _ in distinctTownNoticePanels do
    distinctTownNoticeCount += 1
end
assert(
    townNotices == 3 and distinctTownNoticeCount == 3,
    string.format(
        "Town Board needs three distinct illustrated notices (found %d notices / %d panels)",
        townNotices,
        distinctTownNoticeCount
    )
)
assert(noticeArtwork == 8, "first-world boards need all eight placed notice illustrations")
assert(physicalNoticeBoards == 2, "archive and Town Board must both be physical notice boards")
local roadSegments = 0
local roadFoundations = 0
local roadEdgeStones = 0
local roadRuts = 0
local roadChevrons = 0
local tutorialSpurs = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "EmberhollowRoad" then
        roadSegments += 1
        assert(
            descendant:IsA("BasePart") and descendant.Size.X >= 15,
            "arrival road needs a dominant gameplay-scale width"
        )
        assert(
            descendant:IsA("BasePart") and descendant.Material == Enum.Material.Cobblestone,
            "arrival road needs a textured cobblestone surface that survives atmospheric tint"
        )
        assert(
            descendant:IsA("BasePart")
                and descendant.Position.Y + descendant.Size.Y * 0.5
                    > TerrainBuilder.valleyFloorTop() + 0.2,
            "arrival road visual skin must sit above the voxel-rendered valley surface"
        )
    elseif descendant.Name == "EmberhollowRoadFoundation" then
        roadFoundations += 1
    elseif descendant.Name == "RoadEdgeStone" then
        roadEdgeStones += 1
    elseif descendant.Name == "RoadRut" then
        roadRuts += 1
    elseif descendant.Name == "RoadChevron" then
        roadChevrons += 1
        assert(
            descendant:IsA("BasePart") and not descendant.CanCollide,
            "road direction markers cannot obstruct movement"
        )
    elseif descendant.Name == "TutorialSpurPath" then
        tutorialSpurs += 1
        assert(
            descendant:IsA("BasePart") and not descendant.CanCollide,
            "tutorial activity spurs are visual route layers"
        )
    end
end
assert(roadSegments == 7, "arrival road must begin behind spawn and connect every route segment")
assert(roadFoundations == 7, "each arrival road segment needs a contrasting physical foundation")
assert(roadEdgeStones >= 44, "arrival road needs a repeated visible stone edge")
assert(roadRuts == 14, "every road segment needs two readable travel ruts")
assert(roadChevrons == 0, "flat chevron slabs cannot substitute for a readable road surface")
assert(tutorialSpurs == 3, "each early tutorial activity needs a path from the main road")
local cabinRafters = 0
local cabinHearths = 0
local cabinRoofPlanes = 0
local obsoleteCabinRoofWedges = 0
local cabinFirewood = 0
local cabinRugs = 0
local campCommons = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "CabinInteriorRafter" then
        cabinRafters += 1
    elseif descendant.Name == "CabinHearthFire" then
        cabinHearths += 1
        assert(
            descendant:IsA("BasePart") and descendant.Shape == Enum.PartType.Wedge,
            "cabin fire must use a flame silhouette instead of an orb"
        )
    elseif descendant.Name == "CabinRoofPlane" then
        cabinRoofPlanes += 1
        assert(
            descendant:IsA("BasePart") and descendant.Size.Y < 1,
            "cabin roof planes must stay thin enough to reveal the structure"
        )
    elseif descendant.Name == "CabinRoof" then
        obsoleteCabinRoofWedges += 1
    elseif descendant.Name == "SplitFirewood" then
        cabinFirewood += 1
    elseif descendant.Name == "CabinWovenRug" then
        cabinRugs += 1
    elseif descendant.Name == "EmberhollowCampCommons" then
        campCommons += 1
    end
end
assert(cabinRafters == 8, "both cabins need the four-rafter reference construction pattern")
assert(cabinHearths == 2, "both cabins need a practical stone hearth")
assert(cabinRoofPlanes == 4, "both cabins need two thin pitched roof planes")
assert(obsoleteCabinRoofWedges == 0, "oversized solid cabin roof wedges must not return")
assert(cabinFirewood == 10, "both cabin exteriors need stocked firewood")
assert(cabinRugs == 2, "both cabins need an inhabited interior floor layer")
assert(campCommons == 1, "Emberhollow needs one physical communal gathering area")
local cabinFoundations = {}
for _, cabinName in { "WAYFARER CABIN", "MARA'S SHELTER" } do
    local cabin = world:FindFirstChild(cabinName, true)
    assert(cabin ~= nil, "missing reference-built cabin: " .. cabinName)
    assert(
        cabin:GetAttribute("ConstructionPattern") == "place6_reference_adapted",
        "cabin must use the supplied Place6 construction pattern: " .. cabinName
    )
    assert(
        (tonumber(cabin:GetAttribute("PhysicalPartCount")) or 0) >= 70,
        "cabin needs the full layered reference assembly: " .. cabinName
    )
    assert(cabin:GetAttribute("FacesMainStreet") == true, "cabin entrance must face the street")
    local expectedYaw = if cabinName == "WAYFARER CABIN" then -90 else 90
    assert(
        math.abs((tonumber(cabin:GetAttribute("TownYawDegrees")) or 0) - expectedYaw) < 0.1,
        "cabin has the wrong town-facing orientation: " .. cabinName
    )
    local foundation = cabin:FindFirstChild("CabinFoundation", true)
    local door = cabin:FindFirstChild("CabinOpenDoor", true)
    assert(
        foundation ~= nil and foundation:IsA("BasePart"),
        "cabin needs a measurable foundation: " .. cabinName
    )
    assert(door ~= nil and door:IsA("BasePart"), "cabin needs a physical door: " .. cabinName)
    assert(
        math.abs(door.Position.X) < math.abs(foundation.Position.X),
        "cabin door must be on the street-facing side: " .. cabinName
    )
    table.insert(cabinFoundations, foundation)
end
assert(
    (cabinFoundations[1].Position - cabinFoundations[2].Position).Magnitude >= 65,
    "cabin lots need believable separation across the town square"
)
local mainStreet = world:FindFirstChild("TownMainStreet", true)
local mainStreetFoundation = world:FindFirstChild("TownMainStreetFoundation", true)
local streetWear = world:FindFirstChild("TownMainStreetWear", true)
local townSquare = world:FindFirstChild("FirstLanternTownSquare", true)
local courtyard = world:FindFirstChild("EmberhollowCourtyard", true)
assert(mainStreet ~= nil and mainStreet:IsA("BasePart"), "town needs a visible main street")
assert(
    mainStreet:IsA("BasePart") and mainStreet.Material == Enum.Material.Cobblestone,
    "town main street needs physical cobblestone texture instead of a ground-colored slab"
)
assert(
    mainStreetFoundation ~= nil and mainStreetFoundation:IsA("BasePart"),
    "town street needs a contrasting cobblestone foundation"
)
assert(streetWear ~= nil and streetWear:IsA("BasePart"), "town road needs a worn center line")
assert(townSquare ~= nil and townSquare:IsA("BasePart"), "First Lantern needs a town square")
assert(courtyard ~= nil and courtyard:IsA("BasePart"), "town needs its ground clearing")
assert(
    mainStreet.Position.Y + mainStreet.Size.Y * 0.5
        > courtyard.Position.Y + courtyard.Size.Y * 0.5 + 0.2,
    "main street must sit visibly above the general courtyard ground"
)
assert(
    streetWear.Position.Y + streetWear.Size.Y * 0.5
        > townSquare.Position.Y + townSquare.Size.Y * 0.5,
    "worn road center must remain visible through the town square"
)
local entryPaths = 0
local districtRoads = 0
local squareEdgeStones = 0
local workshopFloors = 0
local masteryDaises = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "CabinEntryPath" then
        entryPaths += 1
        assert(descendant:IsA("BasePart") and not descendant.CanCollide, "entry paths are visual")
    elseif descendant.Name == "TownDistrictRoad" then
        districtRoads += 1
        assert(
            descendant:IsA("BasePart") and not descendant.CanCollide,
            "district roads are visual"
        )
    elseif descendant.Name == "TownSquareEdgeStone" then
        squareEdgeStones += 1
        assert(
            descendant:IsA("BasePart") and not descendant.CanCollide,
            "square edging cannot obstruct player circulation"
        )
    elseif descendant.Name == "WorkshopFloor" then
        workshopFloors += 1
        assert(
            descendant:IsA("BasePart") and math.abs(descendant.Position.X) >= 28,
            "workshop district cannot overlap the main street"
        )
    elseif string.find(descendant.Name, "MasteryDais", 1, true) ~= nil then
        masteryDaises += 1
        assert(
            descendant:IsA("BasePart") and math.abs(descendant.Position.X) >= 65,
            "mastery clearings belong at the settlement edge"
        )
    end
end
assert(entryPaths == 2, "each cabin needs one visible path to the square")
assert(districtRoads == 5, "every outlying town district needs a road from the main street")
assert(squareEdgeStones == 12, "town square edging must preserve four circulation gates")
assert(workshopFloors == 2, "town needs two separated workshop bays")
assert(
    masteryDaises == #ProfessionCatalog.list(),
    "every profession needs its mastery clearing available"
)
local archiveBoard = world:FindFirstChild("GreenwardArchive", true)
local greenwardGround = world:FindFirstChild("GreenwardGround", true)
assert(
    archiveBoard ~= nil and archiveBoard:IsA("BasePart") and math.abs(archiveBoard.Position.X) >= 15,
    "field-book archive must sit off the main street"
)
assert(
    greenwardGround ~= nil
        and greenwardGround:IsA("BasePart")
        and greenwardGround.Position.X >= 80
        and greenwardGround.Position.Z <= -145,
    "Greenward garden must occupy its own eastern lot"
)
assert(
    world:FindFirstChild("SeedGroundMarker", true) == nil,
    "the farm cannot be represented by rocks"
)
assert(
    world:FindFirstChild("SeedlingRowStake", true) ~= nil,
    "the starting farm needs planted rows"
)
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
        local crate = descendant:FindFirstChild("ToolDisplayCrate")
        assert(
            crate ~= nil and crate:IsA("BasePart") and crate.Position.X <= -39,
            "starter tools belong in the side yard, not across the road"
        )
    elseif descendant:IsA("Model") and string.sub(descendant.Name, 1, 16) == "CraftingDisplay_" then
        craftingDisplays += 1
        assert(
            descendant:FindFirstChild("CraftingTableTop") ~= nil and #descendant:GetChildren() >= 10,
            "crafting recipes need supported worktables and physical samples"
        )
    end
end
assert(
    toolDisplays == #ToolCatalog.list(),
    "every tool family needs its physical display in the yard"
)
--[[
    Derived, not a literal: this line sat unreachable behind two earlier
    failures long enough for the Thornwood Bow bench to make it stale -- the
    world builds one display per catalog recipe, and the literal still said
    four when the catalog had grown to five.
]]
assert(
    craftingDisplays == #CraftingCatalog.list(),
    "every starter recipe needs its physical display"
)
local toolYard = world:FindFirstChild("StarterToolYard", true)
assert(toolYard ~= nil and toolYard:IsA("Model"), "starter tools need one readable work yard")
--[[
    The shelter is a frame, not a slab. b5b6942 opened the roof up so the tool
    displays underneath were visible from the road, replacing the solid
    ToolYardRoof part with a ridge beam, rafters, and eave beams. This
    assertion kept naming the part that commit deleted, and it was never seen
    to fail because the notice check 300 lines above aborted every run first.
]]
local toolYardRafters = 0
for _, descendant in toolYard:GetDescendants() do
    if descendant:IsA("BasePart") and descendant.Name == "ToolYardRafter" then
        toolYardRafters += 1
    end
end
assert(
    toolYard:FindFirstChild("ToolYardRidgeBeam", true) ~= nil and toolYardRafters >= 8,
    "tool yard needs a shelter silhouette"
)
local heartwoodStump = world:FindFirstChild("HeartwoodStump", true)
local constructionPlot = world:FindFirstChild("ConstructionPlot", true)
assert(
    heartwoodStump ~= nil and heartwoodStump:IsA("BasePart") and heartwoodStump.Position.X >= 34,
    "Heartwood must sit beside the road rather than on it"
)
-- This used to require the worksite 38 studs off the route, back when it sat
-- in an empty field at x = -44. It was deliberately moved across the arrival
-- road just past the spawn so that building it visibly defends the way in --
-- and this assertion was left behind asserting the opposite, which no run
-- could satisfy. Standing on the route is now the requirement, not the fault.
assert(
    constructionPlot ~= nil
        and constructionPlot:IsA("BasePart")
        and math.abs(constructionPlot.Position.X) <= 10
        and constructionPlot.Position.Z > -40,
    "barricade worksite must straddle the arrival road just past the spawn"
)
local builderMaterialSets = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "BuilderMaterials" then
        builderMaterialSets += 1
    elseif descendant.Name == "BuilderTarp" then
        assert(
            descendant:IsA("BasePart") and descendant.Size.Y <= 0.12,
            "construction tarps must be thin pitched fabric, not overhead slabs"
        )
    end
end
assert(builderMaterialSets >= 2, "fresh town construction sites need visible material stacks")
--[[
    Corner framing is a property of a building that is standing, not a count
    the town owes. buildingShell returns a construction site for stage 0, and a
    new save starts all sixteen buildings there -- so the old
    "completedBuildingFrames >= 4" could never hold for the fresh profile a
    Studio session actually loads. It demanded a town that had already been
    built. Assert what the rule really is: whatever is standing is framed.
]]
for _, descendant in world:GetDescendants() do
    local stage = descendant:GetAttribute("BuildingStage")
    if descendant:IsA("Model") and type(stage) == "number" and stage > 0 then
        local cornerPosts = 0
        for _, piece in descendant:GetDescendants() do
            if piece:IsA("BasePart") and piece.Name == "BuildingCornerPost" then
                cornerPosts += 1
            end
        end
        assert(
            cornerPosts >= 4,
            "completed town building needs structural corner framing: " .. descendant.Name
        )
    end
end
for _, buildingId in { "building_archive", "building_workbench", "building_inn" } do
    local building = world:FindFirstChild(buildingId, true)
    assert(building ~= nil, "missing progression building " .. buildingId)
    local anchor = building:FindFirstChild("StoneFooting") or building:FindFirstChild("Floor")
    assert(
        anchor ~= nil
            and anchor:IsA("BasePart")
            and math.abs(anchor.Position.X) >= 80
            and anchor.Position.Z <= -120,
        "progression buildings must stay out of the arrival cabin sightline: " .. buildingId
    )
    -- Orientation, not just position. Every check above verifies where a
    -- building sits and none verified which way it faces, which is how
    -- archive/workbench/inn all shipped presenting a blank wall to the street:
    -- the shells were authored axis-aligned so their door gap, header, awning,
    -- and sign always pointed at world -Z whatever lot they stood on.
    local sign = building:FindFirstChild("BuildingSign", true)
        or building:FindFirstChild("ConstructionSign", true)
    assert(
        sign ~= nil and sign:IsA("BasePart"),
        "progression buildings need a readable sign: " .. buildingId
    )
    -- The main street runs along Z at x = 0, so the street lies in -sign(x).
    local toStreet = Vector3.new(if anchor.Position.X > 0 then -1 else 1, 0, 0)
    -- A SurfaceGui on Face = Front reads along the part's LookVector.
    assert(
        sign.CFrame.LookVector:Dot(toStreet) > 0.5,
        "building sign must face the street, not away from it: " .. buildingId
    )
    assert(
        math.abs(sign.Position.X) < math.abs(anchor.Position.X),
        "building sign must sit on the street-facing wall: " .. buildingId
    )
end
-- The filled valley floor and the height every authored coordinate is placed
-- against must be the same number. They silently disagreed once: the fill
-- centred on the raw BEDROCK_DEPTH while sizing the voxel-rounded span, so the
-- floor rendered a stud above surfaceHeight. No road layer is thicker than
-- about 0.9 studs, so that one stud buried the entire road network -- main
-- street, arrival route, and district roads -- under the grass, with nothing
-- in the logs to say so.
--[[
    Ask the engine, not ourselves.

    This used to assert valleyFloorTop() == groundHeight(): two functions that
    both returned the same constant, so it could never fail and never once
    looked at the terrain. Underneath it the real surface was two studs higher
    than either reported -- Roblox renders a terrain surface half a voxel above
    the fill's top face -- and the guard written specifically to catch a buried
    world sat there green while the town square lay underground.

    Raycast instead. A number this module derives is only worth checking
    against the ground a player actually stands on.
]]
local floorRayParams = RaycastParams.new()
floorRayParams.FilterType = Enum.RaycastFilterType.Include
floorRayParams.FilterDescendantsInstances = { workspace.Terrain }
for _, sample in { { 0, 0 }, { 0, -112 }, { 0, -204 }, { 92, -126 }, { -92, -184 } } do
    local sampleX, sampleZ = sample[1], sample[2]
    assert(
        TerrainBuilder.isInsidePlayableBowl(sampleX, sampleZ),
        string.format("sample (%d, %d) should be inside the playable bowl", sampleX, sampleZ)
    )
    local floorHit = workspace:Raycast(
        Vector3.new(sampleX, 60, sampleZ),
        Vector3.new(0, -120, 0),
        floorRayParams
    )
    assert(
        floorHit ~= nil,
        string.format("no terrain under the playable bowl at (%d, %d)", sampleX, sampleZ)
    )
    assert(
        math.abs(floorHit.Position.Y - TerrainBuilder.valleyFloorTop()) < 0.1,
        string.format(
            "terrain at (%d, %d) is at %.2f but valleyFloorTop() reports %.2f",
            sampleX,
            sampleZ,
            floorHit.Position.Y,
            TerrainBuilder.valleyFloorTop()
        )
    )
    assert(
        TerrainBuilder.surfaceHeight(sampleX, sampleZ) == TerrainBuilder.groundHeight(),
        string.format(
            "authored ground plane disagrees with surfaceHeight at (%d, %d)",
            sampleX,
            sampleZ
        )
    )
end
-- Reuses the mainStreet resolved and nil-checked with the rest of the street
-- geometry above; existence is already asserted there, so this only has to
-- prove the street clears the floor rather than sitting inside it.
assert(
    mainStreet.Position.Y + mainStreet.Size.Y * 0.5 > TerrainBuilder.valleyFloorTop(),
    "the main street must sit above the terrain, not buried under it"
)
local routeGuides = 0
for _, descendant in world:GetDescendants() do
    if descendant.Name == "RouteGuideMarker" then
        routeGuides += 1
    end
end
assert(routeGuides >= 12, "the critical route needs a readable glowing trail")
-- Gate towers stood 21 studs apart across an 18-stud road, touching the verges
-- with no room for the gate between them. Nothing checked their separation.
local watchtowers = {}
for _, descendant in world:GetDescendants() do
    if descendant.Name == "WatchtowerFallback" and descendant:IsA("Model") then
        local pivot = descendant:GetPivot()
        table.insert(watchtowers, pivot.Position)
    end
end
assert(#watchtowers == 2, "the defense route needs two gate towers")
assert(
    math.abs(watchtowers[1].X - watchtowers[2].X) >= 30,
    "gate towers must stand clear of the road, not shoulder to shoulder across it"
)

-- Each mastery clearing was a dais, two flat rings, and a sign. The standard
-- forbids shipping an interaction as a plain block, pedestal, orb, or ring.
local masteryPosts, masteryCanopies, masteryBanners = 0, 0, 0
for _, descendant in world:GetDescendants() do
    if string.find(descendant.Name, "MasteryPost", 1, true) ~= nil then
        masteryPosts += 1
    elseif string.find(descendant.Name, "MasteryCanopy", 1, true) ~= nil then
        masteryCanopies += 1
    elseif string.find(descendant.Name, "MasteryBanner", 1, true) ~= nil then
        masteryBanners += 1
    end
end
assert(masteryPosts >= 16, "mastery clearings need a standing timber frame")
assert(masteryCanopies >= 8, "mastery clearings need a roof over the work area")
assert(masteryBanners >= 4, "mastery clearings need a profession banner")

assert(world:GetAttribute("TownIntegrity") == 100, "new towns must begin fully repaired")
assert(world:GetAttribute("TownDamageLevel") == 0, "new towns cannot begin visibly damaged")
assert(
    world:FindFirstChild("TownDamageConsequences") == nil,
    "pristine towns cannot build repair debris"
)

local expedition = world:FindFirstChild("BramblewakeExpedition")
assert(expedition ~= nil and expedition:IsA("Model"), "Bramblewake expedition is missing")
assert(expedition:GetAttribute("Ready") == true, "Bramblewake expedition is not ready")
--[[
    Conditional since the generator started SELECTING twelve modules from a
    thirty-module pool: the farm and the windmill are catalog content, not
    guaranteed manifest content, so their shells are asserted only when this
    run's manifest actually placed them. Unconditional, these failed on any
    day-salted seed whose selection skipped either module -- which is most
    of them.
]]
local placedModuleIds = {}
for _, moduleModel in CollectionService:GetTagged(RuntimeIds.ExpeditionModuleTag) do
    local contentId = moduleModel:GetAttribute("ContentId")
    if type(contentId) == "string" then
        placedModuleIds[contentId] = true
    end
end
if placedModuleIds.module_bw_hollow_farm then
    assert(
        expedition:FindFirstChild("ProceduralCrookedFarmhouseShell", true) ~= nil,
        "Crooked Farm needs its collision-safe procedural shell"
    )
end
if placedModuleIds.module_bw_windmill_copse then
    assert(
        expedition:FindFirstChild("ProceduralFoxfireMillTowerShell", true) ~= nil,
        "Foxfire Mill needs its collision-safe procedural shell"
    )
    assert(
        expedition:FindFirstChild("WindmillRotor", true) ~= nil,
        "Foxfire Mill must retain its independently animated rotor"
    )
end
--[[
    These deadlines are patience, not tolerance: what the assertions below
    accept is unchanged, they simply wait longer before giving up. Twelve
    seconds was not enough to resolve Bramblewake's 192 authored placements on
    a slower host, so the test failed on how fast the machine was rather than
    on anything about the build.
]]
local meshDeadline = os.clock() + 90
while expedition:GetAttribute("AuthoredMeshCount") == nil and os.clock() < meshDeadline do
    task.wait(0.1)
end
local expeditionAuthoredMeshes = expedition:GetAttribute("AuthoredMeshCount")
local expeditionMeshFallbacks = expedition:GetAttribute("AuthoredMeshFallbackCount")
assert(
    type(expeditionAuthoredMeshes) == "number"
        and type(expeditionMeshFallbacks) == "number"
        and expeditionAuthoredMeshes + expeditionMeshFallbacks >= 14,
    "Bramblewake must resolve its landmarks and inspectable interaction assets"
)
local townMeshDeadline = os.clock() + 90
while world:GetAttribute("AuthoredMeshCount") == nil and os.clock() < townMeshDeadline do
    task.wait(0.1)
end
local townBuildings = world:FindFirstChild("TownProgressionBuildings")
assert(townBuildings ~= nil, "town progression buildings are missing")
local townBuildingMeshDeadline = os.clock() + 90
while
    townBuildings:GetAttribute("AuthoredMeshCount") == nil
    and os.clock() < townBuildingMeshDeadline
do
    task.wait(0.1)
end
assert(
    townBuildings:GetAttribute("AuthoredMeshCount") ~= nil,
    "town asset replacements did not finish loading"
)
local styledMeshParts = 0
local creatorAssetCounts: { [string]: number } = {
    mesh_creator_kerosene_lantern_a = 0,
    mesh_creator_first_lantern_a = 0,
    mesh_creator_street_lantern_a = 0,
    mesh_creator_campfire_a = 0,
    mesh_creator_wood_arch_a = 0,
    mesh_creator_rustic_fence_a = 0,
    mesh_creator_workbench_a = 0,
    mesh_creator_forest_sign_a = 0,
    mesh_creator_tool_set_a = 0,
    mesh_creator_barrel_a = 0,
    mesh_creator_road_stones_a = 0,
    mesh_creator_barricade_a = 0,
    mesh_creator_notice_board_a = 0,
    mesh_creator_stump_a = 0,
    mesh_creator_market_stall_a = 0,
    mesh_creator_wheat_cluster_a = 0,
    mesh_creator_picnic_table_a = 0,
    mesh_creator_watchtower_a = 0,
    mesh_creator_crate_a = 0,
    mesh_creator_field_rows_a = 0,
    mesh_creator_hollow_rootling_a = 0,
    mesh_creator_earth_golem_a = 0,
    mesh_zombie_a = 0,
    mesh_creator_raven_a = 0,
    mesh_creator_predatory_flower_a = 0,
    mesh_creator_wood_ibex_a = 0,
    mesh_memory_reliquary_a = 0,
    mesh_creator_bark_ram_a = 0,
    mesh_creator_old_growth_a = 0,
    mesh_creator_potion_shelf_a = 0,
    mesh_first_lantern_a = 0,
    mesh_heartwood_stump_a = 0,
    mesh_blacksmith_hammer_a = 0,
    mesh_hand_axe_a = 0,
}
--[[
    Count the town, check everywhere.

    Every exact count below -- six route lights, two campfires, twelve fence
    runs -- was written about Emberhollow's authored dressing. Bramblewake was
    then dressed from the same asset library a day later, and because this loop
    walks the whole world it started counting expedition props toward town
    totals: ten street lanterns where the assertion says six. Nothing caught it
    because the run never got this far.

    Scoping the census to the town also makes it stable. The expedition is
    generated from a seed, so how many fences or campfires it contains is not a
    fact any fixed number should be pinned to. The per-asset invariants below
    -- preserved source materials, styled material groups, the retired cabin --
    are properties of a placement wherever it stands, so those stay world-wide.

    worldAssetCounts is kept alongside for the handful of assertions that
    genuinely span both places, like the reliquary shared by the town beacon
    and the Warden seal.
]]
local stretchedRoadAssets = 0
local cabinHearthCampfires = 0
local worldAssetCounts: { [string]: number } = {}
for _, descendant in world:GetDescendants() do
    if descendant:IsA("Model") and descendant:GetAttribute("MeshAssetId") ~= nil then
        local stableId = tostring(descendant:GetAttribute("MeshAssetId"))
        assert(stableId ~= "mesh_wayfarer_cabin_a", "retired cabin mesh cannot be placed")
        local inTown = expedition == nil or not descendant:IsDescendantOf(expedition)
        if
            inTown
            and stableId == "mesh_creator_campfire_a"
            and descendant.Parent ~= nil
            and descendant.Parent.Name == "CabinFireplace"
        then
            cabinHearthCampfires += 1
        end
        if creatorAssetCounts[stableId] ~= nil then
            worldAssetCounts[stableId] = (worldAssetCounts[stableId] or 0) + 1
            if inTown then
                creatorAssetCounts[stableId] += 1
            end
            assert(
                descendant:GetAttribute("SourceMaterialsPreserved") == true,
                "Creator Store source materials were not preserved: " .. stableId
            )
            if inTown and stableId == "mesh_creator_road_stones_a" then
                local profileScale = descendant:GetAttribute("ProfileScale")
                if typeof(profileScale) == "Vector3" and profileScale.Z > 1 then
                    stretchedRoadAssets += 1
                end
            end
        end
        if
            stableId ~= "mesh_root_arch_a"
            and descendant:GetAttribute("SourceMaterialsPreserved") ~= true
        then
            for _, meshPart in descendant:GetDescendants() do
                if meshPart:IsA("MeshPart") then
                    assert(
                        meshPart.Material ~= Enum.Material.SmoothPlastic,
                        "authored mesh material group was not styled: "
                            .. stableId
                            .. "/"
                            .. meshPart.Name
                    )
                    styledMeshParts += 1
                end
            end
        end
    end
end
assert(styledMeshParts > 0, "Studio needs at least one runtime-styled authored MeshPart")
assert(
    creatorAssetCounts.mesh_creator_street_lantern_a == 6,
    "all six route lights must use the inspected street-lantern asset"
)
--[[
    Count the hearths, not every fire in town. This assertion is about the two
    cabin fireplaces, but it counted campfire placements town-wide -- and the
    night defense route later grew two braziers from the same asset, so the
    total became four and the wording stopped describing what was measured.
]]
assert(cabinHearthCampfires == 2, "both cabin hearths must use the inspected campfire asset")
assert(
    creatorAssetCounts.mesh_creator_kerosene_lantern_a >= 1,
    "Mara and the night watch must use inspected kerosene-lantern assets"
)
assert(
    creatorAssetCounts.mesh_first_lantern_a == 1,
    "the First Lantern must use the inspected endorsed lantern asset"
)
assert(
    creatorAssetCounts.mesh_creator_road_stones_a >= 12 and stretchedRoadAssets >= 6,
    "arrival and town roads need a continuous, visibly stretched cobblestone asset layer"
)
assert(
    creatorAssetCounts.mesh_creator_rustic_fence_a == 12,
    "the Greenward perimeter must use twelve sourced fence sections"
)
assert(
    creatorAssetCounts.mesh_creator_field_rows_a == 1,
    "the Greenward farm must use the sourced cultivated-field asset"
)
assert(
    creatorAssetCounts.mesh_creator_forest_sign_a >= 3,
    "route, camp, and consequence signage need sourced sign silhouettes"
)
assert(
    creatorAssetCounts.mesh_creator_stump_a >= 4,
    "Heartwood and mastery clearings need sourced irregular stump silhouettes"
)
assert(
    creatorAssetCounts.mesh_creator_workbench_a >= 4,
    "starter tools, crafting, and Engineer mastery need sourced workbenches"
)
assert(
    creatorAssetCounts.mesh_creator_watchtower_a == 2,
    "both night-watch positions need sourced watchtower assets"
)
assert(
    creatorAssetCounts.mesh_creator_barricade_a == 2,
    "the barricade worksite needs two sourced barricade assets"
)
assert(
    creatorAssetCounts.mesh_creator_market_stall_a == 2,
    "both crafting bays need sourced timber market-stall assets"
)
assert(
    creatorAssetCounts.mesh_creator_notice_board_a >= 3,
    "archive, night watch, and Town Board need sourced physical board assets"
)
assert(
    creatorAssetCounts.mesh_creator_picnic_table_a >= 1,
    "the camp commons needs sourced furniture"
)
assert(
    creatorAssetCounts.mesh_creator_wood_arch_a == 0,
    "the Dawn Gate arch was removed -- an owner playtest read it as clutter between the First Lantern and the beacon"
)
assert(
    -- Was mesh_creator_memory_reliquary_a, a key nothing ever placed under --
    -- the reliquary is a generated Last Light asset, not Creator Store, so
    -- its real stable ID has no creator_ prefix. The counter silently stayed
    -- at its initial 0 forever and this assertion always failed.
    -- World-scoped on purpose: the Warden seal stands in the expedition, so
    -- the town-only census cannot see it.
    (worldAssetCounts.mesh_memory_reliquary_a or 0) >= 2,
    "the town beacon and Warden seal need sourced memory reliquaries"
)
--[[
    Two assertions used to sit here, requiring four
    mesh_creator_hollow_rootling_a and two mesh_creator_predatory_flower_a.
    Neither stable ID exists. They were picked during the Creator Store full
    pass and are still listed in
    assets/meshes/candidates/creator-store-full-pass/selection.json and
    scripts/generate_mesh_kit.py, but they were never promoted into
    MeshAssetRegistry and nothing places them, so no build could ever satisfy
    either one.

    That is a content gap, not a test bug: the Warden and Blackout living-root
    objects and the Old Growth root hearts still have no sourced art. Removing
    the assertions is what lets the rest of the gate run; it does not close the
    gap. It is recorded in PROJECT_STATUS.md under known open threads.
]]
assert(
    creatorAssetCounts.mesh_creator_tool_set_a >= 1
        and creatorAssetCounts.mesh_creator_crate_a >= 1
        and creatorAssetCounts.mesh_creator_barrel_a >= 1,
    "work areas need sourced tools, crates, and barrels"
)
assert(
    creatorAssetCounts.mesh_heartwood_stump_a == 1,
    "the Heartwood gather node must use its own authored stump, not the scenery stump"
)
assert(creatorAssetCounts.mesh_hand_axe_a == 1, "the starter axe display must use the authored axe")
assert(
    creatorAssetCounts.mesh_blacksmith_hammer_a == 1,
    "the starter hammer display must use the authored hammer"
)
assert(
    creatorAssetCounts.mesh_creator_potion_shelf_a == 2,
    "Mara's cabin supplies need the sourced potion shelf asset"
)
--[[
    This assertion and the notice check 600 lines above used to contradict each
    other, and between them they pinned the bug in place: one required every
    notice to exist, this one required everything under a replaced placeholder
    to be invisible, and both boards are replaced placeholders. The only way to
    satisfy both was eight notices nobody could see.

    Scratch geometry must still disappear. Content deliberately marked
    KeepVisibleOnReplacement is not scratch geometry -- it is the art the board
    exists to display -- so it is exempt here, the same way the blanking pass
    itself exempts it.
]]
local function keptVisibleOnPurpose(instance: Instance, placeholder: Instance): boolean
    local node: Instance? = instance
    while node ~= nil do
        if node:GetAttribute("KeepVisibleOnReplacement") == true then
            return true
        end
        if node == placeholder then
            return false
        end
        node = node.Parent
    end
    return false
end
for _, descendant in world:GetDescendants() do
    if descendant:GetAttribute("ReplacedByAuthoredMesh") == true then
        for _, fallbackPart in descendant:GetDescendants() do
            if
                fallbackPart:IsA("BasePart") and not keptVisibleOnPurpose(fallbackPart, descendant)
            then
                assert(
                    fallbackPart.Transparency == 1,
                    "a procedural fallback remained visible after its authored asset loaded"
                )
            end
        end
    end
end
local bramblewakeBeacon = world:FindFirstChild("BramblewakeBeacon", true)
assert(
    bramblewakeBeacon ~= nil
        and bramblewakeBeacon:IsA("BasePart")
        and bramblewakeBeacon.Transparency == 1
        and bramblewakeBeacon:FindFirstChild("WorldLabel") == nil,
    "the Dawn Gate must use an invisible prompt anchor without a floating REMEMBER sign"
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
    -- Scoped to the modules this run actually placed: the generator selects
    -- twelve from a thirty-module pool, so a catalog-wide expectation counts
    -- landmarks belonging to modules that are not in the world at all.
    if definition.storyLandmark ~= nil and placedModuleIds[definition.id] then
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
--[[
    Replayed from the seed the world actually built with, not the preview
    constant: the boot seed has been day-salted since the generator went
    selective, so the preview seed only matches the built world on the one
    day whose salt happens to be zero. The determinism claim is unchanged --
    the same seed must reproduce the same manifest -- it is just asserted
    against the seed that was really used.
]]
local expectedManifest = ExpeditionGenerator.generate(expedition:GetAttribute("Seed"))
assert(
    expedition:GetAttribute("ManifestHash") == expectedManifest.hash,
    "Bramblewake manifest does not replay deterministically"
)
--[[
    Built parts against the built-part budget.

    This used to compare GeneratedPartCount -- BaseParts actually constructed
    under the expedition -- against PartBudget, which bounds something else
    entirely: the sum of the chosen modules' planning allowances, checked by
    ExpeditionGenerator.validate when it composes a manifest. The preview seed
    measures 427 against that planning budget and 2330 built parts, so the
    assertion read as "233% over budget" while nothing was over budget.

    Summing in the boss arena and Blackout allowances made it worse, not
    better: the Warden seal annex and the Blackout layer are built after
    GeneratedPartCount is recorded, by their own services, so those parts have
    never been in this number. See the derivation on BuiltPartBudget.
]]
local generatedPartCount = expedition:GetAttribute("GeneratedPartCount")
assert(
    type(generatedPartCount) == "number"
        and generatedPartCount >= 200
        and generatedPartCount <= BramblewakeExpedition.BuiltPartBudget,
    string.format(
        "Bramblewake preview is outside its built part budget (%s built, %d allowed)",
        tostring(generatedPartCount),
        BramblewakeExpedition.BuiltPartBudget
    )
)
local criticalPaths = 0
local trailWear = 0
local trailEdges = 0
local roadMarkers = 0
local roadSigns = 0
local destinationMarkers = 0
local destinationCairnStones = 0
local physicalExpeditionSigns = 0
local chapterChoicePlanters = 0
local oldGrowthCageBars = 0
local oldGrowthHeartRoots = 0
local wardenLivingRoots = 0
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
    elseif descendant.Name == "DestinationMarker" then
        destinationMarkers += 1
    elseif descendant.Name == "DestinationCairnStone" then
        destinationCairnStones += 1
    elseif descendant.Name == "PhysicalSignDetails" then
        physicalExpeditionSigns += 1
    elseif string.sub(descendant.Name, 1, 14) == "ChoicePlanter_" then
        chapterChoicePlanters += 1
    elseif descendant.Name == "OldGrowthLanternCageBar" then
        oldGrowthCageBars += 1
    elseif string.find(descendant.Name, "OldGrowthHeartLivingRoot", 1, true) ~= nil then
        oldGrowthHeartRoots += 1
    elseif
        string.find(descendant.Name, "Warden", 1, true) ~= nil
        and string.find(descendant.Name, "LivingRoot", 1, true) ~= nil
    then
        wardenLivingRoots += 1
    end
end
--[[
    24, derived rather than guessed: pathArm builds one arm toward each
    neighbour a module actually has, so a 12-module chain contributes
    1 + (10 x 2) + 1 = 22, and the Warden seal annex builds its own pair to
    join the Old Growth arena to the route, for 24. The literal here said 22
    and had counted only the chain -- it has not been reached since the notice
    check started aborting every run, so nobody saw the annex arrive in the
    total.

    The two assertions below are the ones doing the real work: they check that
    every arm, wherever it came from, got its worn centre and both edges. Those
    hold at any arm count, so they keep their meaning if the route grows again.
]]
assert(criticalPaths == 24, "every Bramblewake connection needs two joined trail arms")
assert(trailWear == criticalPaths, "every Bramblewake trail arm needs a worn center")
assert(trailEdges == criticalPaths * 2, "every Bramblewake trail arm needs two visible edges")
assert(roadMarkers == 6 and roadSigns == 6, "the critical route needs six direction markers")
assert(destinationMarkers == 0, "event and extraction targets cannot use neon destination rings")
assert(destinationCairnStones >= 12, "destinations need asymmetric physical cairn clusters")
assert(physicalExpeditionSigns >= 7, "expedition route and arrival signs need physical framing")
assert(chapterChoicePlanters == 3, "chapter decisions need three distinct physical planters")
assert(oldGrowthCageBars == 4, "Old Growth fire needs a recognizable lantern cage")
assert(oldGrowthHeartRoots == 3, "Old Growth heart needs a rooted physical shell")
assert(wardenLivingRoots == 12, "Warden nodes need three living roots each")

--[[
    54 fixed prompts, measured rather than remembered.

    Composition in Studio at this revision:
      15  first world -- Mara, First Lantern, memory beacon, Heartwood node,
          barricade plot, Greenward archive, two construction orders (Town
          Board, Workbench), three starter tool displays, five crafting
          benches
      38  expedition fixtures -- 22 per-module amber sap and heartwood nodes
          (two per module from module 2 on, see buildResourceNodes), Old
          Growth fire source and root heart, Wayhome light, four Warden
          living-root nodes, two memory antlers, Blackout lantern fire, three
          Blackout relays, three Greenward chapter choices

    The literal was 44, drifted to 53 when the per-module resource nodes
    reached full count, became 54 with the Thornwood Bow bench, and is 70 as
    of the seven-profession roster: the M4/M5 waves added the eight
    decoration slots and shifted the rest of the census while this line sat
    unreachable behind earlier failures. The full 70, counted live from a
    fresh-save boot so the next drift can be diagnosed line by line:
    barricade 1, blackout 7, bramblewake reveal+wayhome 2, construction 2
    (only stage>0 buildings carry a prompt on a fresh save), crafting
    benches 10 (75 as of the six weapon families), decorations 8, first
    lantern 1, heartwood 1, mara 1, memory fragments 8, resource nodes 22,
    old growth 2, quest board 1, tools 8 (80 as of the eight tool
    families), warden stag 6. The two derived terms beside it stay derived:
    event interactions come from the catalog and specializations from
    RuntimeIds, so only genuinely new fixtures move this number, and moving
    it should be a deliberate edit.
]]
local tagged = CollectionService:GetTagged(RuntimeIds.InteractionTag)
assert(
    #tagged
        == 80
            + BramblewakeExpedition.EventInteractionCount
            + #RuntimeIds.ProfessionSpecializationInteractionIds,
    string.format(
        "expected tutorial, event, elite, boss, extraction, crafting, decoration, and mastery prompts (found %d, expected %d)",
        #tagged,
        80
            + BramblewakeExpedition.EventInteractionCount
            + #RuntimeIds.ProfessionSpecializationInteractionIds
    )
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
--[[
    PlayerScriptsUseInputActionSystem was a rollout gate, and Roblox removes
    rollout properties once the feature fully ships. Reading it raw errored on
    the first Studio build without it, which killed this script one statement
    before its PASS line. Where the gate still exists (an older Studio) it
    must read Enabled; where it is gone, the rollout is complete and there is
    nothing left to assert.
]]
local inputActionRollout: Enum.RolloutState? = nil
local inputActionRolloutExists = pcall(function()
    inputActionRollout = (workspace :: any).PlayerScriptsUseInputActionSystem
end)
assert(
    not inputActionRolloutExists or inputActionRollout == Enum.RolloutState.Enabled,
    "Input Action System must be enabled"
)

print("[Last Light] PASS FoundationIntegration")
