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
local CombatState = require(root.CombatState)
local EnemyAttackFlow = require(root.EnemyAttackFlow)
local ExpeditionEventFlow = require(root.ExpeditionEventFlow)
local ExpeditionGenerator = require(root.ExpeditionGenerator)
local ProfessionCatalog = require(root.ProfessionCatalog)
local ProfessionState = require(root.ProfessionState)
local ReviveFlow = require(root.ReviveFlow)
local RuntimeIds = require(root.RuntimeIds)
local SurvivalState = require(root.SurvivalState)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)
local ServiceRegistry = require(serverRoot.ServiceRegistry)

local content = Registry.new(Regions)
assert(Config.SaveSchemaVersion == 3, "unexpected save schema version")
assert(Config.BuildVersion == "0.9.0", "unexpected build version")
assert(content:count() == 7, "all launch region definitions must load")
assert(content:has("region_bramblewake"), "starter region is missing")

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
assert(world:GetAttribute("Ready") == true, "world model is not marked ready")
assert(world:FindFirstChild("ArrivalSpawn", true) ~= nil, "arrival spawn is missing")
assert(world:FindFirstChild("Mara", true) ~= nil, "Mara is missing")
assert(world:FindFirstChild("HeartwoodStump", true) ~= nil, "gather node is missing")
assert(world:FindFirstChild("ConstructionPlot", true) ~= nil, "construction plot is missing")
assert(world:FindFirstChild("FirstLantern", true) ~= nil, "First Lantern is missing")

local expedition = world:FindFirstChild("BramblewakeExpedition")
assert(expedition ~= nil and expedition:IsA("Model"), "Bramblewake expedition is missing")
assert(expedition:GetAttribute("Ready") == true, "Bramblewake expedition is not ready")
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
assert(
    expedition:GetAttribute("EventInteractionCount") == BramblewakeExpedition.EventInteractionCount,
    "Bramblewake event interaction count is incorrect"
)
local expectedManifest = ExpeditionGenerator.generate(Config.BramblewakePreviewSeed)
assert(
    expedition:GetAttribute("ManifestHash") == expectedManifest.hash,
    "Bramblewake manifest does not replay deterministically"
)
local generatedPartCount = expedition:GetAttribute("GeneratedPartCount")
assert(
    type(generatedPartCount) == "number"
        and generatedPartCount >= 200
        and generatedPartCount <= BramblewakeExpedition.PartBudget,
    "Bramblewake preview is outside its detailed mobile part budget"
)

local tagged = CollectionService:GetTagged(RuntimeIds.InteractionTag)
assert(
    #tagged == 9 + BramblewakeExpedition.EventInteractionCount,
    "expected tutorial, event, and extraction interaction prompts"
)
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
assert(
    #CollectionService:GetTagged(RuntimeIds.ExpeditionPointOfInterestTag)
        == BramblewakeExpedition.PointOfInterestCount,
    "expected four Bramblewake points of interest"
)
assert(
    #CollectionService:GetTagged(RuntimeIds.ExpeditionEventTag) == BramblewakeExpedition.EventCount,
    "expected four Bramblewake event sockets"
)
local eventSteps = CollectionService:GetTagged(RuntimeIds.ExpeditionEventStepTag)
assert(
    #eventSteps == BramblewakeExpedition.EventInteractionCount,
    "expected every Bramblewake event interaction step"
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
