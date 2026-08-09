--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "Last Light shared root did not replicate before bootstrap timeout")

local Config = require(root.Config)
local Strings = require(root.Strings)
local BramblewakeExpedition = require(root.Content.Definitions.BramblewakeExpedition)
local CraftingCatalog = require(root.CraftingCatalog)
local DefenseLanes = require(root.DefenseLanes)
local RegionAccess = require(root.RegionAccess)
local RegionBuilders = require(script.World.RegionBuilders)
local Equipment = require(root.Equipment)
local Consumables = require(root.Consumables)
local GearVisualPlan = require(root.GearVisualPlan)
local EnemyCatalog = require(root.EnemyCatalog)
local CombatState = require(root.CombatState)
local EnemyAttackFlow = require(root.EnemyAttackFlow)
local EnemyCombatRules = require(root.EnemyCombatRules)
local EnemyMotion = require(root.EnemyMotion)
local EngineerBrace = require(root.EngineerBrace)
local Environment = require(root.Environment)
local ExpeditionEventFlow = require(root.ExpeditionEventFlow)
local ExpeditionContracts = require(root.ExpeditionContracts)
local ExpeditionGenerator = require(root.ExpeditionGenerator)
local ExpeditionRewardLedger = require(root.ExpeditionRewardLedger)
local ExtractionPayoff = require(root.ExtractionPayoff)
local NightSchedule = require(root.NightSchedule)
local OldGrowthEncounter = require(root.OldGrowthEncounter)
local WardenStagEncounter = require(root.WardenStagEncounter)
local BramblewakeBlackout = require(root.BramblewakeBlackout)
local ProfessionCatalog = require(root.ProfessionCatalog)
local ProfessionAbilityVisuals = require(root.ProfessionAbilityVisuals)
local ProfessionMastery = require(root.ProfessionMastery)
local ProfessionRescue = require(root.ProfessionRescue)
local ProfessionState = require(root.ProfessionState)
local RateLimiter = require(root.RateLimiter)
local ResidentDialogue = require(root.ResidentDialogue)
local ResidentRoster = require(root.ResidentRoster)
local ReviveFlow = require(root.ReviveFlow)
local RuntimeIds = require(root.RuntimeIds)
local SaveSchema = require(root.SaveSchema)
local StatusEffectState = require(root.StatusEffectState)
local SurvivalState = require(root.SurvivalState)
local TownNightSchedule = require(root.TownNightSchedule)
local TownNightIncident = require(root.TownNightIncident)
local TownCondition = require(root.TownCondition)
local TownGuardLastStand = require(root.TownGuardLastStand)
local LobbyDeparture = require(root.LobbyDeparture)
local ActionProgress = require(root.ActionProgress)
local ToolCatalog = require(root.ToolCatalog)
local GearWear = require(root.GearWear)
local GearTraits = require(root.GearTraits)
local CompanionMotion = require(root.CompanionMotion)
local ActionPayloadContract = require(root.ActionPayloadContract)
local AdminInspectionReport = require(root.AdminInspectionReport)
local PerformanceBudget = require(root.PerformanceBudget)
local SessionSegment = require(root.SessionSegment)
local SoakProbe = require(root.SoakProbe)
local ProfilePersistence = require(root.ProfilePersistence)
local ProfileBackup = require(root.ProfileBackup)
local TownPermissions = require(root.TownPermissions)
local TownVisitPolicy = require(root.TownVisitPolicy)
local RolloutCohorts = require(root.RolloutCohorts)
local RunHandoff = require(root.RunHandoff)
local PartySession = require(root.PartySession)
local PrivateServerControls = require(root.PrivateServerControls)
local QuickChat = require(root.QuickChat)
local CosmeticCatalog = require(root.CosmeticCatalog)
local Entitlements = require(root.Entitlements)
local StoreAvailability = require(root.StoreAvailability)
local StoreCard = require(root.StoreCard)
local AdminRoster = require(root.AdminRoster)
local TownDecorations = require(root.TownDecorations)
local TownProgression = require(root.TownProgression)
local MemoryFragments = require(root.MemoryFragments)
local TownConstruction = require(root.TownConstruction)
local TutorialFlow = require(root.TutorialFlow)
local Registry = require(root.Content.Registry)
local Regions = require(root.Content.Definitions.Regions)

local AnalyticsService = require(script.Services.AnalyticsService)
local EnemyService = require(script.Services.EnemyService)
local ExpeditionService = require(script.Services.ExpeditionService)
local Logger = require(script.Services.Logger)
local FeatureFlagService = require(script.Services.FeatureFlagService)
local GearVisualService = require(script.Services.GearVisualService)
local NetworkService = require(script.Services.NetworkService)
local PerformanceService = require(script.Services.PerformanceService)
local OldGrowthService = require(script.Services.OldGrowthService)
local WardenStagService = require(script.Services.WardenStagService)
local BramblewakeBlackoutService = require(script.Services.BramblewakeBlackoutService)
local PhaseService = require(script.Services.PhaseService)
local ProfileService = require(script.Services.ProfileService)
local TownNightService = require(script.Services.TownNightService)
local LobbyService = require(script.Services.LobbyService)
local PartyService = require(script.Services.PartyService)
local SocialService = require(script.Services.SocialService)
local CommerceService = require(script.Services.CommerceService)
local PrivateServerService = require(script.Services.PrivateServerService)
local AdminService = require(script.Services.AdminService)
local CompanionService = require(script.Services.CompanionService)
local DefenseService = require(script.Services.DefenseService)
local RegionEncounterService = require(script.Services.RegionEncounterService)
local PlayerSurvivalService = require(script.Services.PlayerSurvivalService)
local PlayerCombatService = require(script.Services.PlayerCombatService)
local ProfessionService = require(script.Services.ProfessionService)
local TutorialService = require(script.Services.TutorialService)
local WorldService = require(script.Services.WorldService)
local ServiceRegistry = require(script.ServiceRegistry)
local BramblewakeEnemyBuilder = require(script.World.BramblewakeEnemyBuilder)
local OldGrowthBuilder = require(script.World.OldGrowthBuilder)
local WardenStagBuilder = require(script.World.WardenStagBuilder)

local environment, environmentError = Environment.resolve({
    isStudio = RunService:IsStudio(),
    placeId = game.PlaceId,
    requested = game:GetAttribute("LastLightEnvironment"),
    productionPlaceIds = Config.ProductionPlaceIds,
})
assert(environment ~= nil, environmentError)

local environmentConfig = Config.Environments[environment]
local logger = Logger.new(environment, environmentConfig.LogLevel)
local featureFlags = FeatureFlagService.new(
    Config.FeatureFlags,
    environmentConfig.AllowFlagOverrides,
    logger,
    RolloutCohorts,
    Config.FeatureFlagRollouts,
    Config.RolloutRoster
)
local content = Registry.new(Regions)
local networkService = NetworkService.new(logger)
-- Analytics before the profile service, because a profile transaction is one
-- of the release gates and the thing that measures it cannot be built after
-- the thing it measures.
local analyticsService = AnalyticsService.new(logger)
local profileService =
    ProfileService.new(logger, environmentConfig.UsePersistentData, analyticsService)
local gearVisualService = GearVisualService.new(logger, profileService, GearVisualPlan)
local worldService = WorldService.new(
    logger,
    ExtractionPayoff,
    TownProgression,
    ProfessionAbilityVisuals,
    TownConstruction,
    MemoryFragments,
    TownDecorations,
    CraftingCatalog,
    Consumables,
    ResidentRoster
)
--[[
    The third gate on a region, after its enabled flag and its chapter:
    can its builder actually draw a world a party could walk. Bramblewake
    can; the Delve and the Fen have module geometry and nothing else yet,
    and RegionBuilders is where that stays honest.
]]
RegionAccess.setReadinessProvider(function(regionId: string): boolean
    return RegionBuilders.readiness(regionId).walkable
end)

local expeditionService = ExpeditionService.new(
    logger,
    worldService,
    ExpeditionGenerator,
    RegionAccess,
    BramblewakeExpedition,
    featureFlags,
    ExpeditionEventFlow,
    ExpeditionRewardLedger,
    ExtractionPayoff,
    profileService,
    analyticsService,
    Config.BramblewakePreviewSeed,
    ExpeditionContracts
)
local survivalService = PlayerSurvivalService.new(
    logger,
    Config,
    RuntimeIds,
    ReviveFlow,
    SurvivalState,
    featureFlags,
    worldService,
    analyticsService
)
survivalService:setExpeditionFailureHandler(function(player: Player): any
    return expeditionService:failExpedition(player)
end)
local combatService = PlayerCombatService.new(
    logger,
    Config,
    CombatState,
    StatusEffectState,
    featureFlags,
    survivalService,
    analyticsService
)
local function equipmentStats(player: Player): any
    return profileService:equipmentStats(player)
end
survivalService:setEquipmentStatsProvider(equipmentStats)
combatService:setEquipmentStatsProvider(equipmentStats)
local professionService = ProfessionService.new(
    logger,
    ProfessionCatalog,
    ProfessionState,
    ProfessionMastery,
    ProfessionRescue,
    featureFlags,
    profileService,
    worldService,
    survivalService,
    analyticsService
)
survivalService:setReviveTuningProvider(function(player: Player): any
    return professionService:rescueTuning(
        player,
        Config.ReviveChannelSeconds,
        Config.ReviveHealth,
        Config.ReviveInvulnerabilitySeconds
    )
end)
local enemyService = EnemyService.new(
    logger,
    Config,
    worldService,
    survivalService,
    combatService,
    EnemyAttackFlow,
    EnemyCatalog,
    EnemyCombatRules,
    EnemyMotion,
    EngineerBrace,
    BramblewakeEnemyBuilder,
    analyticsService
)
professionService:setEnemyService(enemyService)
professionService:setCombatService(combatService)
expeditionService:bindEnemyService(enemyService)
enemyService:setProfessionService(professionService)
local companionService = CompanionService.new(logger, CompanionMotion)
--[[
    The six encounters the Delve and the Fen brought. Registered even
    though no region can open yet: a service that first boots on the day
    its content ships is a service nobody has ever booted, and that is the
    wrong day to find out.
]]
local regionEncounterService =
    RegionEncounterService.new(logger, profileService, survivalService, featureFlags)
local defenseService = DefenseService.new(
    logger,
    DefenseLanes,
    worldService,
    enemyService,
    profileService,
    Config,
    ExtractionPayoff
)
enemyService:setDefenseLanes(DefenseLanes)
local oldGrowthService = OldGrowthService.new(
    logger,
    worldService,
    expeditionService,
    survivalService,
    combatService,
    professionService,
    OldGrowthEncounter,
    EnemyAttackFlow,
    EnemyCombatRules,
    OldGrowthBuilder,
    analyticsService,
    featureFlags,
    Config
)
enemyService:setEliteService(oldGrowthService)
local wardenStagService = WardenStagService.new(
    logger,
    worldService,
    expeditionService,
    survivalService,
    combatService,
    professionService,
    oldGrowthService,
    WardenStagEncounter,
    EnemyAttackFlow,
    EnemyCombatRules,
    WardenStagBuilder,
    analyticsService,
    featureFlags,
    Config
)
enemyService:setBossService(wardenStagService)
local blackoutService = BramblewakeBlackoutService.new(
    logger,
    Config,
    worldService,
    expeditionService,
    profileService,
    survivalService,
    oldGrowthService,
    wardenStagService,
    BramblewakeBlackout,
    analyticsService,
    featureFlags
)
oldGrowthService:setActivationGate(function(): boolean
    return blackoutService:allowsOldGrowth()
end)
wardenStagService:setUnlockGate(function(): boolean
    return blackoutService:allowsWarden()
end)
local phaseService = PhaseService.new(
    logger,
    worldService,
    enemyService,
    NightSchedule,
    Config.FirstNightDuskSeconds,
    Config.FirstNightSeconds
)
local lobbyService = LobbyService.new(
    logger,
    Config,
    LobbyDeparture,
    RunHandoff,
    featureFlags,
    worldService,
    analyticsService
)
--[[
    Parties, and the way back to one. LobbyService measures who is standing on
    the departure platform every tick already, so the party service reads that
    rather than measuring the dais a second time: an invitation and a boarding
    pass have to agree about who was there, and two independent measurements
    is how they stop agreeing.
]]
local partyService =
    PartyService.new(logger, Config, PartySession, profileService, analyticsService)
partyService:setPlatformProvider(function(): { Player }
    return lobbyService:readyPlayers(lobbyService)
end)
lobbyService:setPartyService(partyService)
--[[
    Quick chat, the one channel a player has to another player. Registered
    beside the party service because they are the two halves of the same
    question -- who you are travelling with, and what you can say to them --
    and because the block list one of them consults is the block list the
    other one will (M11 wave D).
]]
local socialService =
    SocialService.new(logger, Config, QuickChat, RateLimiter, featureFlags, analyticsService)
--[[
    One block reader for the whole game. PartyService asks the same authority
    quick chat asks, rather than reaching for the platform a second time: a
    suppression rule with two homes is a rule that stops being true in one of
    them, and the safety review's whole claim is that every channel consults
    the same list.
]]
partyService:setBlockReader(function(fromUserId: number, toUserId: number): boolean
    return socialService:isSuppressed(fromUserId, toUserId)
end)

--[[
    The one module allowed to touch a purchase API, and the only grant
    authority in the game. Everything it decides is decided in the pure
    Entitlements module; what it owns is the profile write, the mailbox and the
    platform call.
]]
local commerceService = CommerceService.new(
    logger,
    Config,
    CosmeticCatalog,
    Entitlements,
    StoreCard,
    profileService,
    featureFlags,
    analyticsService
)

local performanceService = PerformanceService.new(
    logger,
    Config,
    PerformanceBudget,
    SessionSegment,
    analyticsService,
    SoakProbe
)
local adminService = AdminService.new(
    logger,
    AdminRoster,
    featureFlags,
    profileService,
    survivalService,
    combatService,
    worldService,
    expeditionService,
    performanceService,
    analyticsService
)
local townNightService = TownNightService.new(
    logger,
    Config,
    worldService,
    enemyService,
    TownNightSchedule,
    TownNightIncident,
    TownCondition,
    TownPermissions,
    TownVisitPolicy,
    TownGuardLastStand,
    analyticsService,
    featureFlags
)
townNightService:setDefense(defenseService, DefenseLanes)

--[[
    The soak, wired here because this is the only file that can see all
    three things it reads and none of them should learn about each other.

    The counters are injected rather than reached for. This service has no
    business knowing how many creatures EnemyService believes in or how
    large a profile encodes to, and a soak that reached across the server
    for its own numbers would be a second copy of every service's
    internals going stale on its own schedule.

    `LastLightSoak` is read **inside the observer, every cycle**, and that
    is not a style choice. A Studio Play session starts from a fresh
    DataModel that does not carry attributes set in Edit mode, so a check
    made once at boot can never be true in the only place this is ever
    driven from: the wiring existed, ran on every server, and was
    unreachable. Read per cycle it can also be turned on partway through a
    session, which is what a soak actually gets used like.

    Registering a counter costs nothing; running one costs a full
    descendant walk of the world. That is why the list is always installed
    and the sampling is not.
]]
performanceService:setSoakCounters({
    instances = function(): number
        return #workspace:GetDescendants()
    end,
    tracked_enemies = function(): number
        return enemyService:trackedCount()
    end,
    --[[
        Every per-player table this server is still holding for somebody who
        has gone, and it has to be every service that keeps one. It read only
        ProfileService's tables until AnalyticsService started counting things
        per player for the tuning metrics, at which point a counter described
        as watching the game's player residue would have been watching a
        subset -- which is worse than watching nothing, because it reports a
        clean zero while a leak grows beside it.
    ]]
    player_residue = function(): number
        local present: { [Player]: boolean } = {}
        for _, player in Players:GetPlayers() do
            present[player] = true
        end
        return profileService:playerResidue() + analyticsService:playerResidue(present)
    end,
    profile_bytes = function(): number
        return profileService:largestProfileBytes()
    end,
})
townNightService:setCycleObserver(function(cycle: number, phase: string)
    if game:GetAttribute("LastLightSoak") ~= true then
        return
    end
    if not performanceService:isSoaking() then
        performanceService:beginSoak(phase)
    end
    performanceService:sampleSoak(cycle, phase)
end)
--[[
    The private server's control rail.

    Constructed after the three things it can hold still, and it is the only
    caller of any of them: the profile write latch, the town clock's hold, the
    creature simulation's stillness and the expedition's rebuild all exist for
    this service. Keeping the callers to one is what makes "no private-server
    setting changes a reward" a claim about a single file rather than about
    however many places learned to stop the clock.
]]
local privateServerService = PrivateServerService.new(
    logger,
    PrivateServerControls,
    profileService,
    townNightService,
    enemyService,
    analyticsService
)
privateServerService:setExpeditionService(expeditionService)
--[[
    Who may visit this town, in the two pieces the service cannot supply
    itself.

    The policy is read once, from the founder's own profile, at the moment the
    server adopts them as host -- so a founder who disconnects leaves their
    gate exactly as they set it. The relation is the asynchronous half:
    friendship is a platform round trip, and a party membership is something
    PartyService already knows, so both are answered here and handed back
    through the callback rather than blocking a profile load on a web call.

    Order matters in the check. Being asked along beats being on a friends
    list, because the party is the group actually playing together; a stranger
    the founder invited onto the departure platform is somebody the founder
    chose, and a town set to "invited" should let them in.
]]
townNightService:setVisitPolicyProvider(function(hostUserId: number): string
    local hostPlayer = Players:GetPlayerByUserId(hostUserId)
    if hostPlayer == nil then
        return TownVisitPolicy.Default
    end
    return profileService:visitPolicy(hostPlayer)
end)
townNightService:setRelationResolver(
    function(actorUserId: number, hostUserId: number, resolve: (string) -> ())
        task.spawn(function()
            if partyService:sharesPartyWith(hostUserId, actorUserId) then
                resolve("invited")
                return
            end
            local hostPlayer = Players:GetPlayerByUserId(hostUserId)
            if hostPlayer ~= nil then
                local ok, friends = pcall(function(): boolean
                    return hostPlayer:IsFriendsWith(actorUserId)
                end)
                if ok and friends == true then
                    resolve("friend")
                    return
                end
                if not ok then
                    -- The platform did not answer. A stranger is the honest
                    -- reading and the safe one: it can only ever refuse, and a
                    -- refusal costs an upward contribution the town was fine
                    -- without, while a wrong "friend" opens a closed town.
                    logger:warn("town_friendship_unavailable", { host = hostUserId })
                end
            end
            resolve("stranger")
        end)
    end
)
survivalService:setPartyRecoveryProvider(
    function(eligiblePlayers: number, downedPlayers: number): any
        return townNightService:attemptLastStand(eligiblePlayers, downedPlayers)
    end
)
professionService:setSwitchProvider(function(player: Player): (boolean, string?)
    local profile = profileService:get(player)
    if profile == nil or profile.tutorial.complete ~= true then
        return false, Strings.get("toast.complete_first_light_to_choose_a")
    end
    if phaseService:snapshot().nightActive or townNightService:isNightActive() then
        return false, Strings.get("toast.return_to_daylight_before_switching_professi")
    end
    if expeditionService:snapshot(player).active then
        return false, Strings.get("toast.return_through_the_wayhome_gate_before")
    end
    return true, nil
end)
local tutorialService = TutorialService.new(
    logger,
    Config,
    RuntimeIds,
    TutorialFlow,
    RateLimiter,
    featureFlags,
    networkService,
    profileService,
    worldService,
    enemyService,
    survivalService,
    combatService,
    professionService,
    phaseService,
    townNightService,
    lobbyService,
    expeditionService,
    oldGrowthService,
    wardenStagService,
    blackoutService,
    analyticsService,
    CraftingCatalog,
    Equipment,
    ResidentDialogue,
    ActionProgress,
    ToolCatalog,
    GearWear,
    GearTraits,
    Consumables,
    TownVisitPolicy,
    StoreAvailability
)

local services = ServiceRegistry.new({
    environment = environment,
    logger = logger,
    featureFlags = featureFlags,
    content = content,
    runtimeIds = RuntimeIds,
    saveSchema = SaveSchema,
    actionPayloadContract = ActionPayloadContract,
    adminInspectionReport = AdminInspectionReport,
    profilePersistence = ProfilePersistence,
    townVisitPolicy = TownVisitPolicy,
    privateServerControls = PrivateServerControls,
    profileBackup = ProfileBackup,
    config = Config,
})
services:register(featureFlags)
services:register(performanceService)
services:register(networkService)
services:register(profileService)
services:register(gearVisualService)
services:register(analyticsService)
services:register(worldService)
services:register(expeditionService)
services:register(survivalService)
services:register(combatService)
services:register(professionService)
services:register(enemyService)
services:register(oldGrowthService)
services:register(wardenStagService)
services:register(blackoutService)
services:register(phaseService)
services:register(lobbyService)
services:register(townNightService)
services:register(companionService)
services:register(defenseService)
services:register(regionEncounterService)
services:register(partyService)
services:register(socialService)
services:register(commerceService)
services:register(privateServerService)
-- Without this the departure countdown never reached a client: LobbyService
-- published every whole second into a handler nobody had set, so the panel
-- froze at "DEPARTING IN 10" while the server counted down and launched.
lobbyService:setChangedHandler(function(toast: string?)
    tutorialService:broadcastLobby(toast)
end)
worldService:setClickHandler(function(clicker: Player, interactionId: string)
    tutorialService:interactFromClick(clicker, interactionId)
end)
tutorialService:setCompanionService(companionService)
tutorialService:setPartyService(partyService)
tutorialService:setSocialService(socialService)
tutorialService:setCommerceService(commerceService)
tutorialService:setPrivateServerService(privateServerService)
--[[
    A grant has to arrive somewhere the buyer can see.

    `applyReceipt` and the mailbox drain both settle correctly on their own,
    and both were silent: the live pass granted a product, watched the ledger
    and the profile take it, and the card in front of the buyer went on saying
    NOT OWNED until an unrelated push happened along. A purchase that lands
    without a word is the one moment in this game where the player has already
    paid.
]]
commerceService:setGrantHandler(function(player: Player, granted: { string })
    -- A grant that handed over nothing is a bug somewhere behind this, not a
    -- sentence to read out: "0 THINGS ARE YOURS" is worse than silence.
    if #granted == 0 then
        return
    end
    tutorialService:announceTo(
        player,
        if #granted == 1
            then Strings.get("toast.it_is_yours_wear_it_at")
            else string.format(Strings.get("toast.n_things_are_yours_wear_them"), #granted)
    )
end)
partyService:setToastHandler(function(player: Player?, message: string)
    if player ~= nil then
        tutorialService:toastPlayer(player, message)
    else
        tutorialService:toastEveryone(message)
    end
end)
--[[
    Passive gear wears from the blows it softens: one point per mitigated
    hit, against the weapon's two per landed strike -- you strike more
    often than you are struck. Toasts only on a condition change, so the
    Field Book nags exactly twice per piece: once worn, once failing.
]]
survivalService:setGearWearAccruer(function(player: Player)
    for slot, itemId in profileService:equippedSnapshot(player) do
        if slot ~= "weapon" and type(itemId) == "string" then
            local wearResult = profileService:accrueGearWear(player, itemId, 1)
            if
                wearResult.applied
                and wearResult.conditionAfter ~= wearResult.conditionBefore
                and wearResult.conditionAfter ~= "sound"
            then
                local name =
                    string.upper((string.gsub((string.gsub(itemId, "^gear_", "")), "_", " ")))
                tutorialService:toastPlayer(
                    player,
                    if wearResult.conditionAfter == "failing"
                        then string.format(Strings.get("toast.your_n_has_failed_it_shields"), name)
                        else string.format(
                            Strings.get("toast.your_n_is_worn_it_protects"),
                            name
                        )
                )
            end
        end
    end
end)
regionEncounterService:setToastHandler(function(player: Player?, message: string)
    if player ~= nil then
        tutorialService:toastPlayer(player, message)
    else
        tutorialService:toastEveryone(message)
    end
end)
defenseService:setToastHandler(function(player: Player?, message: string)
    if player ~= nil then
        tutorialService:toastPlayer(player, message)
    else
        tutorialService:toastEveryone(message)
    end
end)
enemyService:setStrikeHandler(function(clicker: Player)
    tutorialService:strikeFromClick(clicker)
end)
oldGrowthService:setStrikeHandler(function(clicker: Player)
    tutorialService:strikeFromClick(clicker)
end)
wardenStagService:setStrikeHandler(function(clicker: Player)
    tutorialService:strikeFromClick(clicker)
end)
-- The three sample sources the server owns. Join time is measured to the
-- moment a profile is loaded, which is the first moment a player can actually
-- do anything, rather than to the moment their character appeared.
networkService:setPerformanceHandler(function(player: Player, payload: any)
    performanceService:acceptClientReport(player, payload)
end)
profileService:onLoaded(function(player: Player, profile: any)
    performanceService:markInteractive(player, profile.createdAt)
end)
networkService:setActionObserver(function(player: Player)
    performanceService:noteAction(player)
end)
adminService:setTutorialService(tutorialService)
services:register(adminService)
services:register(tutorialService)
services:initialize()
services:start()

logger:info("server_boot_complete", {
    build = Config.BuildVersion,
    contentDefinitions = content:count(),
    environment = environment,
    services = services:count(),
})
