--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)
local RegionExpeditionAssembly = require(script.Parent.Parent.World.RegionExpeditionAssembly)

local TutorialService = {}
TutorialService.__index = TutorialService
TutorialService.Name = "TutorialService"

-- Mirrors the earliest stage the authored First Night can target a player
-- (TutorialFlow only reaches "survive" once a player has a barricade, a
-- tool, and the First Lantern prepared). EnemyService reads this attribute
-- so the recurring town night cycle can't target a player still gathering,
-- choosing a tool, or building, the same way the one-time first night never
-- could before it existed.
local function isCombatEligibleStage(stage: string): boolean
    return stage == "survive" or stage == "reveal" or stage == "complete"
end

type Session = {
    stage: string,
    resources: number,
    selectedTool: string?,
    compactHud: boolean,
    toast: string?,
    toastRevision: number,
}

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type TutorialService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _runtimeIds: any,
        _tutorialFlow: any,
        _rateLimiter: any,
        _actionPayloadContract: any,
        _featureFlags: any,
        _networkService: any,
        _profileService: any,
        _worldService: any,
        _enemyService: any,
        _survivalService: any,
        _combatService: any,
        _professionService: any,
        _phaseService: any,
        _townNightService: any,
        _lobbyService: any,
        _expeditionService: any,
        _oldGrowthService: any,
        _wardenStagService: any,
        _blackoutService: any,
        _analyticsService: any,
        _craftingCatalog: any,
        _equipmentCatalog: any,
        _residentDialogue: any,
        _actionProgress: any,
        _toolCatalog: any,
        _gearWear: any,
        _gearTraits: any,
        _consumables: any,
        _townVisitPolicy: any,
        _storeAvailability: any,
        _companionService: any,
        _partyService: any,
        _socialService: any,
        _commerceService: any,
        _privateServerService: any,
        _regionEncounterService: any,
        --[[
            Which store view each player is on, so the panel can be told to
            open by the world rather than by a HUD button. It is a revision
            rather than a boolean for the same reason the toast is: closing is
            the client's own business, and a boolean the client cannot clear
            would reopen the panel on every push.
        ]]
        _storeRevision: { [Player]: number },
        _actions: { [Player]: any },
        _sessions: { [Player]: Session },
        _expeditionModuleIndex: { [Player]: number },
        _expeditionEventRevision: { [Player]: number },
        _expeditionEventSecond: { [Player]: number },
        _limiter: any,
    },
    TutorialService
))

function TutorialService.new(
    logger: Logger,
    config: any,
    runtimeIds: any,
    tutorialFlow: any,
    rateLimiter: any,
    featureFlags: any,
    networkService: any,
    profileService: any,
    worldService: any,
    enemyService: any,
    survivalService: any,
    combatService: any,
    professionService: any,
    phaseService: any,
    townNightService: any,
    lobbyService: any,
    expeditionService: any,
    oldGrowthService: any,
    wardenStagService: any,
    blackoutService: any,
    analyticsService: any,
    craftingCatalog: any,
    equipmentCatalog: any,
    residentDialogue: any,
    actionProgress: any,
    toolCatalog: any,
    gearWear: any,
    gearTraits: any,
    consumables: any,
    townVisitPolicy: any,
    storeAvailability: any
): TutorialService
    return setmetatable({
        Name = TutorialService.Name,
        _logger = logger,
        _config = config,
        _runtimeIds = runtimeIds,
        _tutorialFlow = tutorialFlow,
        _rateLimiter = rateLimiter,
        _actionPayloadContract = nil,
        _featureFlags = featureFlags,
        _networkService = networkService,
        _profileService = profileService,
        _worldService = worldService,
        _enemyService = enemyService,
        _survivalService = survivalService,
        _combatService = combatService,
        _professionService = professionService,
        _phaseService = phaseService,
        _townNightService = townNightService,
        _lobbyService = lobbyService,
        _expeditionService = expeditionService,
        _oldGrowthService = oldGrowthService,
        _wardenStagService = wardenStagService,
        _blackoutService = blackoutService,
        _analyticsService = analyticsService,
        _craftingCatalog = craftingCatalog,
        _equipmentCatalog = equipmentCatalog,
        _residentDialogue = residentDialogue,
        _actionProgress = actionProgress,
        _toolCatalog = toolCatalog,
        _gearWear = gearWear,
        _gearTraits = gearTraits,
        _consumables = consumables,
        _townVisitPolicy = townVisitPolicy,
        _storeAvailability = storeAvailability,
        _companionService = nil,
        _partyService = nil,
        _socialService = nil,
        _commerceService = nil,
        _privateServerService = nil,
        _regionEncounterService = nil,
        _storeRevision = {},
        _actions = {},
        _sessions = {},
        _expeditionModuleIndex = {},
        _expeditionEventRevision = {},
        _expeditionEventSecond = {},
        _limiter = rateLimiter.new(config.ActionRatePerSecond, config.ActionRatePerSecond * 2),
    }, TutorialService)
end

function TutorialService.Init(self: TutorialService, context: any)
    self._actionPayloadContract =
        assert(context.actionPayloadContract, "action payload contract unavailable")

    self._profileService:onLoaded(function(player: Player, profile: any)
        self:_profileLoaded(player, profile)
    end)

    self._networkService:setActionHandler(function(player: Player, payload: any)
        self:_handleAction(player, payload)
    end)
    self._networkService:setSnapshotProvider(function(player: Player)
        return self:snapshot(player)
    end)
    self._phaseService:setChangedHandler(function(toast: string?)
        if toast ~= nil then
            for player, session in self._sessions do
                session.toast = toast
                session.toastRevision += 1
                self:_publish(player)
            end
        else
            self:_publishAll()
        end
    end)
    self._phaseService:setCompleteHandler(function()
        self:_nightComplete()
    end)
    self._townNightService:setChangedHandler(function(toast: string?)
        if toast ~= nil then
            for _, session in self._sessions do
                if session.stage == "complete" then
                    session.toast = toast
                    session.toastRevision += 1
                end
            end
        end
        self:_publishAll()
    end)
    self._townNightService:setNightCompletedHandler(
        function(nightNumber: number, endingLanternHealth: number, condition: any)
            -- Resident life resolves on the night that just ran. The context
            -- is identical for every profile on the server, so every player's
            -- town remembers the same night.
            local buildingIntegrity: { [string]: number } = {}
            for _, entry in condition.damaged or {} do
                buildingIntegrity[entry.buildingId] = entry.integrity / 100
            end
            local residentContext = {
                nightNumber = nightNumber - 1,
                buildingIntegrity = buildingIntegrity,
                lanternHitFloor = endingLanternHealth <= 18,
            }
            local sharedReport: any = nil
            for player in self._sessions do
                self._profileService:setNightNumber(player, nightNumber)
                self._profileService:setTownCondition(player, condition)
                local report = self._profileService:applyResidentNight(player, residentContext)
                if sharedReport == nil and report ~= nil then
                    sharedReport = report
                end
                local questSuffix = self:_questToastSuffix(player)
                if questSuffix ~= nil then
                    self:_setToast(player, questSuffix)
                end
            end
            if sharedReport ~= nil then
                for _, residentId in sharedReport.injuries do
                    self._worldService:setResidentInjured(residentId, true)
                    self:_toastAll(
                        string.format(
                            Strings.get("tutorial.n_was_hurt_in_the_night"),
                            string.upper(string.gsub(string.gsub(residentId, "npc_", ""), "_", " "))
                        )
                    )
                end
                for _, residentId in sharedReport.recoveries do
                    self._worldService:setResidentInjured(residentId, false)
                end
                if sharedReport.crisis ~= nil then
                    self:_toastAll(
                        sharedReport.crisis.title .. " — " .. sharedReport.crisis.detail
                    )
                end
            end
            -- Dawn boons from whoever is present; the effects are town-wide
            -- and deterministic, so the first profile speaks for the server.
            for player in self._sessions do
                local boons = self._profileService:residentDawnBoons(player)
                for _, boon in boons do
                    if boon.boon == "dawn_repair" then
                        local repaired = self._townNightService:residentRepair()
                        if repaired ~= nil then
                            self:_toastAll(boon.label)
                        end
                    elseif boon.boon == "night_forewarning" then
                        self:_toastAll(
                            string.format(
                                Strings.get("tutorial.n_night_n_n"),
                                boon.label,
                                nightNumber,
                                self._townNightService:themeForNight(nightNumber)
                            )
                        )
                    elseif boon.boon == "lantern_reserve" then
                        self._enemyService:grantLanternReserve(6)
                        self:_toastAll(boon.label)
                    end
                end
                break
            end
            self._analyticsService:townNightConsequence(
                nightNumber - 1,
                endingLanternHealth,
                condition.integrity,
                condition.damageLevel
            )
            --[[
                Dawn is when the tier can move, and the tier is what decides
                which buildings stand and who lives here. The consequence
                used to render only at profile load, so three survived
                nights raised a town nobody saw until they rejoined.
                setTownConsequence skips the rebuild when nothing changed,
                so most dawns this costs a comparison.
            ]]
            for player in self._sessions do
                self._worldService:setTownConsequence(self._profileService:townConsequence(player))
                break
            end
            self:_publishAll()
        end
    )
    self._enemyService:setChangedHandler(function(toast: string?)
        if toast ~= nil then
            for _, session in self._sessions do
                if session.stage == "survive" then
                    session.toast = toast
                    session.toastRevision += 1
                end
            end
        end
        self:_publishAll()
    end)
    self._oldGrowthService:setChangedHandler(function(toast: string?)
        if toast ~= nil then
            for player, session in self._sessions do
                if self._oldGrowthService:snapshot(player) ~= nil then
                    session.toast = toast
                    session.toastRevision += 1
                end
            end
        end
        self:_publishAll()
    end)
    self._wardenStagService:setChangedHandler(function(toast: string?)
        if toast ~= nil then
            for player, session in self._sessions do
                if self._wardenStagService:snapshot(player) ~= nil then
                    session.toast = toast
                    session.toastRevision += 1
                end
            end
        end
        self:_publishAll()
    end)
    self._blackoutService:setChangedHandler(function(toast: string?)
        if toast ~= nil then
            for player, session in self._sessions do
                if self._blackoutService:snapshot(player) ~= nil then
                    session.toast = toast
                    session.toastRevision += 1
                end
            end
        end
        self:_publishAll()
    end)
    self._survivalService:setChangedHandler(function(player: Player?, toast: string?)
        if player ~= nil and toast ~= nil then
            self:_setToast(player, toast)
        end
        self:_publishAll()
    end)
    self._combatService:setChangedHandler(function(player: Player, toast: string?)
        if toast ~= nil then
            self:_setToast(player, toast)
        end
        self:_publish(player)
    end)
    self._professionService:setChangedHandler(function(player: Player, toast: string?)
        if toast ~= nil then
            self:_setToast(player, toast)
        end
        self:_publishAll()
    end)
end

--[[
    The other half of the Studio verification hooks, and it has to live
    here rather than in ProfileService.

    `LastLightStockProfile` fills a purse so a driver can craft without
    playing an hour first. But crafting -- and the progress panel, the
    equip column, the consumable column, almost every surface worth
    looking at -- sits behind tutorial completion, and a fresh Studio
    profile is always pre-tutorial. A live pass on 2026-08-07 launched
    Studio to check two rewritten HUD surfaces, found both correctly
    empty, and ended knowing nothing.

    The obvious place to fix that is ProfileService, beside the stock
    hook, and it does not work there: the profile flag would be set and
    nothing a player can see would change, because this service has
    already built the session it gates on. It was written there, tested
    green, and reverted for exactly that reason.

    So the skip is applied where the stage is decided -- at session build,
    and again whenever the attribute changes, because a Play session
    starts from a fresh DataModel and an edit-time value never arrives.
    Same guard as the stock hook: Studio only, which is false on every
    Roblox server, and logged loudly every time.

    First Light is verified by playing First Light. Nothing else should
    have to be.
]]
function TutorialService._studioSkipRequested(_self: TutorialService): boolean
    return RunService:IsStudio() and game:GetAttribute("LastLightSkipTutorial") == true
end

function TutorialService._watchStudioSkip(self: TutorialService)
    if not RunService:IsStudio() then
        return
    end
    game:GetAttributeChangedSignal("LastLightSkipTutorial"):Connect(function()
        if not self:_studioSkipRequested() then
            return
        end
        for player, session in self._sessions do
            if session.stage ~= "complete" then
                session.stage = "complete"
                session.toast = Strings.get("tutorial.studio_tutorial_skipped")
                session.toastRevision += 1
                player:SetAttribute("LastLightTutorialSurvivalReady", true)
                --[[
                    The same world setup a loaded complete profile gets.
                    Without it a skipped session has no way into Bramblewake
                    at all: the beacon that carries the only entry
                    interaction stays dark and disabled, which is how a
                    whole live session went looking for the expedition and
                    found a prompt that refused every click.
                ]]
                self._worldService:setBeaconVisible(true)
                local profile = self._profileService:get(player)
                if profile ~= nil then
                    self._townNightService:ensureStarted(
                        profile.town.nightNumber,
                        self._profileService:townCondition(player),
                        player.UserId
                    )
                end
                self._logger:warn("studio_tutorial_skipped", { player = player.UserId })
                self:_publish(player)
            end
        end
    end)
end

function TutorialService.Start(self: TutorialService)
    self:_watchStudioSkip()
    Players.PlayerRemoving:Connect(function(player: Player)
        self._sessions[player] = nil
        self._expeditionModuleIndex[player] = nil
        self._expeditionEventRevision[player] = nil
        self._expeditionEventSecond[player] = nil
        self._storeRevision[player] = nil
        self._limiter:clear(tostring(player.UserId))
        self._analyticsService:clear(player)
    end)

    for _, player in Players:GetPlayers() do
        local profile = self._profileService:get(player)
        if profile ~= nil then
            self:_profileLoaded(player, profile)
        end
    end

    -- Timed actions need a finer tick than the expedition poll below, because
    -- the whole point is a bar that visibly fills over a second or two.
    local actionAccumulator = 0
    RunService.Heartbeat:Connect(function(deltaTime: number)
        actionAccumulator += deltaTime
        if actionAccumulator < 0.1 then
            return
        end
        actionAccumulator = 0
        self:_stepActions()
    end)

    local expeditionAccumulator = 0
    RunService.Heartbeat:Connect(function(deltaTime: number)
        expeditionAccumulator += deltaTime
        if expeditionAccumulator < 0.5 then
            return
        end
        expeditionAccumulator = 0

        for player in self._sessions do
            local expedition = self._expeditionService:snapshot(player)
            local moduleIndex = if expedition.active then expedition.moduleIndex else 0
            local eventRevision = if expedition.active then expedition.eventRevision or 0 else 0
            local eventSecond = if expedition.active
                    and expedition.event ~= nil
                    and expedition.event.status == "active"
                then expedition.event.timeRemaining or 0
                else -1
            if
                self._expeditionModuleIndex[player] ~= moduleIndex
                or self._expeditionEventRevision[player] ~= eventRevision
                or self._expeditionEventSecond[player] ~= eventSecond
            then
                self._expeditionModuleIndex[player] = moduleIndex
                self._expeditionEventRevision[player] = eventRevision
                self._expeditionEventSecond[player] = eventSecond
                self:_publish(player)
            end
        end
    end)

    self._networkService:setWorldReady(true)
end

function TutorialService._profileLoaded(self: TutorialService, player: Player, profile: any)
    if self._sessions[player] ~= nil then
        return
    end

    --[[
        Every session starts a fresh run.

        The tutorial stage is still written to the profile, and the flag below
        can restore it, but with tutorial_persistence off a player who leaves
        and comes back begins at the lodge again rather than resuming mid-way
        through a run they have already left. Rejoining to find yourself
        halfway through the first night, holding an axe you do not remember
        picking, reads as the game having lost track rather than as progress.
    ]]
    local stage = if self._featureFlags:isEnabled("tutorial_persistence")
        then profile.tutorial.stage
        else self._tutorialFlow.firstStage()
    if self:_studioSkipRequested() then
        stage = "complete"
    end
    player:SetAttribute("LastLightTutorialSurvivalReady", isCombatEligibleStage(stage))
    local session: Session = {
        stage = stage,
        resources = if stage == "gather"
            then 0
            elseif stage == "choose_tool" or stage == "build" then 3
            else 0,
        selectedTool = profile.tutorial.selectedTool,
        compactHud = false,
        toast = if not self._profileService:isWritable(player)
            then Strings.get("tutorial.profile_offline_progress_will_not_save")
            elseif stage == "complete" then Strings.get("tutorial.welcome_back_to_emberhollow")
            else Strings.get("tutorial.follow_the_lantern_trail"),
        toastRevision = 1,
    }
    self:_applyToolAttributes(player, session.selectedTool)
    -- A guest is told they are one, at the door. The permission model has
    -- always protected the host's town; the visit only becomes deliberate
    -- when the visitor knows whose lanterns they are standing under.
    local hostInfo = self._townNightService:hostInfo(player.UserId)
    if hostInfo ~= nil and hostInfo.role == "visitor" then
        local hostPlayer = Players:GetPlayerByUserId(hostInfo.hostUserId)
        local hostName = if hostPlayer ~= nil
            then hostPlayer.DisplayName
            else Strings.get("tutorial.a_founder")
        session.toast =
            string.format(Strings.get("tutorial.you_are_a_guest_in_n"), string.upper(hostName))
        session.toastRevision += 1
    end
    self._sessions[player] = session
    self._worldService:setTownConsequence(self._profileService:townConsequence(player))
    -- Seeds the server's live construction accumulator from this player's
    -- own profile the same moment their tier ceiling is seeded. Without
    -- this, a fresh server session starts every building back at the
    -- accumulator's empty default until someone happens to fund a stage,
    -- which is exactly the "town collapses back to construction sites"
    -- regression this whole feature exists to avoid on the buildings a
    -- returning player already paid for (or was grandfathered into).
    self._worldService:setTownConstruction(self._profileService:townConstructionState(player))
    self._worldService:setTownDecorations(self._profileService:decorationsSnapshot(player))

    if stage == "prepare" or stage == "survive" or stage == "reveal" or stage == "complete" then
        self._worldService:buildBarricade(false)
    end
    if stage == "survive" then
        if self._phaseService:hasCompletedFirstNight() then
            self:_advanceSurvivorToReveal(player, session)
        else
            self._phaseService:ensureFirstNight()
        end
    elseif stage == "reveal" or stage == "complete" then
        self._worldService:setBeaconVisible(true)
        self._townNightService:ensureStarted(
            profile.town.nightNumber,
            self._profileService:townCondition(player),
            player.UserId
        )
    end

    local currentStage = session.stage
    local definition = self._tutorialFlow.definition(currentStage)
    self._analyticsService:stage(player, definition.index, currentStage)
    self:_publish(player)
end

local function gearShortName(itemId: string): string
    return string.upper((string.gsub((string.gsub(itemId, "^gear_", "")), "_", " ")))
end

--[[
    What a player should see an item called. Equipment and the crafting
    catalog both carry display names; the id is the last resort, and it
    should never actually be reached for real gear.

    Two toasts were reading the raw id out loud -- "EQUIPPED
    GEAR_AMBER_EDGE", which is how the underscore in a database row ends
    up in a player's face. Seen while equipping a freshly crafted edge in
    Studio.
]]
local function gearDisplayName(equipmentCatalog: any, itemId: string): string
    local definition = if equipmentCatalog ~= nil then equipmentCatalog.get(itemId) else nil
    if type(definition) == "table" and type(definition.displayName) == "string" then
        return string.upper(definition.displayName)
    end
    return gearShortName(itemId)
end

--[[
    What the Field Book says about each owned piece of gear: its rolled
    trait and its wear condition, plus which single item most deserves the
    whetstone. Composed server-side so the client stays a renderer -- it
    never learns the wear thresholds, only the words.
]]
function TutorialService._gearCare(self: TutorialService, player: Player): (any, any)
    local wear = self._profileService:gearWearOf(player)
    local care: { [string]: any } = {}
    local seen: { [string]: boolean } = {}
    local worstId: string? = nil
    local worstPoints = -1
    local function consider(itemId: any)
        if type(itemId) ~= "string" or seen[itemId] then
            return
        end
        seen[itemId] = true
        local traitDefinition =
            self._gearTraits.get(self._profileService:gearTraitOf(player, itemId))
        local condition = self._gearWear.condition(wear, itemId)
        if traitDefinition ~= nil or condition ~= "sound" then
            care[itemId] = {
                condition = condition,
                trait = if traitDefinition ~= nil then traitDefinition.displayName else nil,
            }
        end
        if condition ~= "sound" then
            local points = tonumber(wear[itemId]) or 0
            if points > worstPoints then
                worstPoints = points
                worstId = itemId
            end
        end
    end
    for itemId in self._profileService:gearSnapshot(player) do
        consider(itemId)
    end
    for _, itemId in self._profileService:equippedSnapshot(player) do
        consider(itemId)
    end
    local whetTarget = if worstId ~= nil
        then {
            itemId = worstId,
            label = string.format(Strings.get("tutorial.whet_n"), gearShortName(worstId)),
        }
        else nil
    return care, whetTarget
end

-- Public toast entry points for services that live outside the session
-- pipeline (the defense plots' arming and bite feedback arrives here).
function TutorialService.toastEveryone(self: TutorialService, message: string)
    self:_toastAll(message)
end

function TutorialService.toastPlayer(self: TutorialService, player: Player, message: string)
    self:_setToast(player, message)
end

--[[
    Something changed for one player and they are looking at it right now.

    A toast that waits for the next unrelated push is a purchase that lands in
    silence, which is how a granted receipt read in the live pass: the ledger
    was right, the profile was right, and the card in front of the buyer still
    said NOT OWNED. Same shape as the town that never re-rendered in the
    session that changed it (#325).
]]
function TutorialService.announceTo(self: TutorialService, player: Player, message: string)
    self:_setToast(player, message)
    self:_publish(player)
end

function TutorialService._toastAll(self: TutorialService, message: string)
    for _, session in self._sessions do
        session.toast = message
        session.toastRevision += 1
    end
end

function TutorialService._setToast(self: TutorialService, player: Player, message: string)
    local session = self._sessions[player]
    if session == nil then
        return
    end
    session.toast = message
    session.toastRevision += 1
end

-- Quests have no quest board or accept step: this opportunistically claims
-- anything newly satisfiable and returns a toast fragment to fold into
-- whatever toast the caller was already about to show (a single session
-- only ever carries one pending toast, so the caller must combine rather
-- than set two in a row and lose the first).
function TutorialService._questToastSuffix(self: TutorialService, player: Player): string?
    local claimed = self._profileService:checkQuests(player)
    if #claimed == 0 then
        return nil
    end
    local parts = {}
    for _, quest in claimed do
        self._analyticsService:questClaimed(player, quest.questId)
        table.insert(
            parts,
            string.format(Strings.get("tutorial.quest_complete_n"), quest.displayName)
        )
    end
    return table.concat(parts, " · ")
end

function TutorialService._advance(
    self: TutorialService,
    player: Player,
    actionId: string
): (boolean, string?)
    local session = self._sessions[player]
    if session == nil then
        return false, Strings.get("tutorial.your_profile_is_still_loading")
    end

    local nextStage, reason = self._tutorialFlow.advance(session.stage, actionId)
    if nextStage == nil then
        return false, reason
    end

    session.stage = nextStage
    player:SetAttribute("LastLightTutorialSurvivalReady", isCombatEligibleStage(nextStage))
    self._profileService:setTutorial(player, nextStage, session.selectedTool)
    local definition = self._tutorialFlow.definition(nextStage)
    self._analyticsService:stage(player, definition.index, nextStage)

    return true, nil
end

--[[
    Timed actions.

    Gathering and building used to resolve the instant the button was pressed,
    which gave the player no sense of having done anything. They now start a
    short server-owned action: the character swings its tool, a progress bar
    runs, and the reward lands only when ActionProgress says the clock is up.
    A client cannot shorten it -- it only ever asks to start one.
]]
function TutorialService._beginTimedAction(
    self: TutorialService,
    player: Player,
    actionId: string,
    interactionId: string
): boolean
    if self._actionProgress.durationFor(actionId) == nil then
        return false
    end
    local now = workspace:GetServerTimeNow()
    local session = self._sessions[player]
    --[[
        Work identity: the hammer hurries every timed action, while the
        pick and sickle hurry only harvests of their own materials -- the
        node's reward decides, so a pick at a brightcap is just a pick.
        Combat identity lives in _strikeContext; this is the other half of
        "the tools actually differ".
    ]]
    local tool = self._toolCatalog.get(if session ~= nil then session.selectedTool else nil)
    local durationMultiplier = 1
    if tool ~= nil then
        if tool.actionDurationMultiplier ~= nil then
            durationMultiplier = tool.actionDurationMultiplier
        elseif
            tool.gatherDurationMultiplier ~= nil
            and actionId == self._runtimeIds.Actions.Gather
            and tool.gatherMaterials ~= nil
        then
            local node = self._worldService:resourceNode(interactionId)
            -- The node record carries materialId directly -- the same shape
            -- the grant site reads -- not nested under a reward table.
            local materialId = if node ~= nil then node.materialId else nil
            if materialId ~= nil and tool.gatherMaterials[materialId] == true then
                durationMultiplier = tool.gatherDurationMultiplier
            end
        end
    end
    local nextState, result = self._actionProgress.begin(
        self._actions[player],
        actionId,
        interactionId,
        now,
        durationMultiplier
    )
    self._actions[player] = nextState
    if not result.accepted then
        if result.reason == "already_working" then
            self:_setToast(player, Strings.get("tutorial.already_working"))
            self:_publish(player)
        end
        return true
    end
    self._worldService:playToolAction(player, actionId, result.duration, result.swings)
    self:_setToast(player, result.label .. "...")
    self:_publish(player)
    return true
end

-- Cancel a player's action when they can no longer be doing it.
function TutorialService.cancelAction(self: TutorialService, player: Player)
    if self._actions[player] ~= nil then
        self._actions[player] = self._actionProgress.cancel(self._actions[player])
        self:_publish(player)
    end
end

function TutorialService._stepActions(self: TutorialService)
    local now = workspace:GetServerTimeNow()
    for player, state in self._actions do
        local nextState, result = self._actionProgress.tick(state, now)
        self._actions[player] = nextState
        if result.complete then
            self:_interact(player, result.interactionId, true)
        end
    end
end

function TutorialService.actionSnapshot(self: TutorialService, player: Player): any
    return self._actionProgress.snapshot(self._actions[player], workspace:GetServerTimeNow())
end

-- Entry point for tapping a world object. Goes through the same rate limiter
-- and the same validated interaction path as the HUD button, so clicking is
-- another way to ask, not a way around any check.
-- Shared by the tool action and by tapping a creature. Every guard stays on
-- the server: a click only says which enemy the player meant.
-- Admin surface. Kept here because the toast and the session belong to this
-- service; AdminService decides nothing on its own.
function TutorialService.adminToast(self: TutorialService, player: Player, message: string)
    self:_setToast(player, message)
    self:_publish(player)
end

function TutorialService.adminGrantResources(self: TutorialService, player: Player, amount: number)
    local session = self._sessions[player]
    if session == nil then
        return
    end
    session.resources = amount
    self:_publish(player)
end

--[[
    What the striker is holding, resolved server-side.

    The three starter tools finally mean something: the axe hits a quarter
    harder, the torch's swung fire reaches four studs further at a small cost,
    and the hammer keeps its identity at the workbench rather than in combat
    (it swings build and repair work faster). A ranged weapon in the equipment
    slot extends reach to its own range and marks the strike as a shot, which
    is what the client's arrow visual keys off. All numbers live here and in
    Equipment; a client never submits any of them.
]]
--[[
    The endurance families work through per-player attributes, the same
    channel survival already syncs health through: the combat service reads
    them without a service edge existing in either direction, and they
    follow the tool wherever it is set -- selection at the yard, or a
    profile load restoring last session's choice.
]]
--[[
    The survey glass's exploration identity: while it is the held tool and
    the player walks Bramblewake, the objective markers include the nearest
    unharvested resource node, labeled with what it pays. One marker, the
    nearest only -- a surveyor's bearing, not a maphack.
]]
function TutorialService._addSurveyTarget(
    self: TutorialService,
    player: Player,
    add: (BasePart?, string) -> ()
)
    local session = self._sessions[player]
    local tool = self._toolCatalog.get(if session ~= nil then session.selectedTool else nil)
    if tool == nil or tool.surveyRevealsNodes ~= true then
        return
    end
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    if root == nil or not root:IsA("BasePart") then
        return
    end
    local node = self._worldService:nearestResourceNode(root.Position)
    if node ~= nil and node.target ~= nil then
        add(
            node.target,
            string.format(Strings.get("tutorial.survey_n"), string.upper(tostring(node.objectText)))
        )
    end
end

function TutorialService._applyToolAttributes(self: TutorialService, player: Player, toolId: any)
    local definition = self._toolCatalog.get(toolId)
    player:SetAttribute(
        "LastLightToolStaminaRegen",
        if definition ~= nil then definition.staminaRegenMultiplier else nil
    )
    player:SetAttribute(
        "LastLightToolSprintSpeed",
        if definition ~= nil then definition.sprintSpeedMultiplier else nil
    )
end

function TutorialService._strikeContext(self: TutorialService, player: Player): any
    local session = self._sessions[player]
    local context = { rangeBonus = 0, damageMultiplier = 1 }
    -- Tool identity comes from the catalog now that there are eight
    -- families, not a literal per starter tool.
    local tool = self._toolCatalog.get(if session ~= nil then session.selectedTool else nil)
    if tool ~= nil then
        context.rangeBonus = tool.strikeRangeBonus or 0
        context.damageMultiplier = tool.strikeDamageMultiplier or 1
    end
    local weapon = self._profileService:weaponStrikeProfile(player)
    --[[
        Wear gates the weapon, never the hand: a worn blade works at half
        its multiplier bonus and loses its riders, and a failing one is no
        weapon at all -- the strike falls back to bare hands (and the
        starter tool's own identity) until the bench sees it. GearWear owns
        the thresholds; this only multiplies.
    ]]
    local wearEffectiveness = 1
    if weapon ~= nil then
        wearEffectiveness =
            self._gearWear.effectiveness(self._profileService:gearWearOf(player), weapon.itemId)
    end
    if weapon ~= nil and wearEffectiveness <= 0 then
        weapon = nil
    end
    if weapon ~= nil then
        -- The family decides the moveset: ranged families carry strikeRange
        -- and a projectile visual, the lance carries reach without one, and
        -- the rider fields pass through untouched for the strike to apply.
        -- The item's rolled trait shades it: KEEN adds to the damage bonus,
        -- BALANCED to the reach, both before the wear scaling.
        local trait = self._gearTraits.get(self._profileService:gearTraitOf(player, weapon.itemId))
        if trait ~= nil then
            if trait.strikeDamageBonus ~= nil then
                weapon = table.clone(weapon)
                weapon.strikeDamageMultiplier = (weapon.strikeDamageMultiplier or 1)
                    + trait.strikeDamageBonus
            end
            if trait.reachBonus ~= nil then
                weapon = table.clone(weapon)
                if weapon.strikeRange ~= nil then
                    weapon.strikeRange += trait.reachBonus
                else
                    weapon.meleeReach = (weapon.meleeReach or 0) + trait.reachBonus
                end
            end
        end
        context.weaponRange = weapon.strikeRange or weapon.meleeReach
        -- 1 + (bonus * effectiveness): a worn 1.45x maul swings at 1.225x.
        context.damageMultiplier = 1
            + ((weapon.strikeDamageMultiplier or 1) - 1) * wearEffectiveness
        context.ranged = weapon.ranged == true
        context.weaponId = weapon.itemId
        context.weaponKind = weapon.kind
        if wearEffectiveness >= 1 then
            context.onHitStaminaRefund = weapon.onHitStaminaRefund
            context.onHitSnareSeconds = weapon.onHitSnareSeconds
        end
    end
    return context
end

function TutorialService.setCompanionService(self: TutorialService, companionService: any)
    self._companionService = companionService
end

function TutorialService.setPartyService(self: TutorialService, partyService: any)
    self._partyService = partyService
end

function TutorialService.setSocialService(self: TutorialService, socialService: any)
    self._socialService = socialService
end

function TutorialService.setCommerceService(self: TutorialService, commerceService: any)
    self._commerceService = commerceService
end

function TutorialService.setPrivateServerService(self: TutorialService, privateServerService: any)
    self._privateServerService = privateServerService
end

-- The toast channel is wired in the bootstrap beside every other
-- encounter service's; this reference is for routing interactions and
-- strikes into the arenas.
function TutorialService.setRegionEncounterService(
    self: TutorialService,
    regionEncounterService: any
)
    self._regionEncounterService = regionEncounterService
end

--[[
    Whether the store may open for this player, right now.

    The facts are read here because this is where they all already are, and the
    decision is made in the shared predicate because the HUD makes the same one
    from the same fields -- a panel open when a night starts has to shut itself
    on the frame the state changes, not when somebody presses something. The
    server's answer is the one that counts: it gates the door, and the client's
    copy only decides what is drawn.
]]
function TutorialService._storeVerdict(
    self: TutorialService,
    player: Player,
    knownPhase: any,
    knownSurvival: any
): any
    local session = self._sessions[player]
    local phase = knownPhase
    if phase == nil then
        local pastFirstLight = session ~= nil
            and (
                session.stage == "reveal"
                or session.stage == "complete"
                or self._phaseService:hasCompletedFirstNight()
            )
        phase = if pastFirstLight and self._townNightService:isRunning()
            then self._townNightService:snapshot()
            else self._phaseService:snapshot()
    end
    local survival = knownSurvival or self._survivalService:snapshot(player)
    return self._storeAvailability.evaluate({
        storeEnabled = self._featureFlags:isEnabled("cosmetic_store_enabled"),
        tutorialComplete = session ~= nil and session.stage == "complete",
        nightActive = phase.nightActive,
        enemyCount = phase.enemyCount,
        downed = survival.self ~= nil and survival.self.downed == true,
        partyDown = survival.partyDown == true,
    })
end

function TutorialService.strike(self: TutorialService, player: Player)
    local session = self._sessions[player]
    --[[
        isCombatEligibleStage, not stage == "survive": the literal meant a
        player who finished the tutorial could never strike a town-night
        enemy again -- swings and taps silently did nothing from the
        "complete" stage onward, in the very nights the repeating cycle
        keeps sending creatures at the lantern. The helper at the top of
        this file has always named the right set; the gate just did not
        use it. Found live: a crafted Amber Edge, a Night 1 Rootling, and
        a strike that refused to land.
    ]]
    if
        session ~= nil
        and self._survivalService:canAct(player)
        and (
            isCombatEligibleStage(session.stage)
            or player:GetAttribute("LastLightInExpedition") == true
        )
    then
        local context = self:_strikeContext(player)
        --[[
            An expedition strike asks the region arenas first: a player
            standing inside one is fighting that encounter, and only a
            player standing in none is offered to the roster. nil from
            strikeNearest means "not my fight", which is what lets one
            button serve a night wave and an arena without the client
            naming either.
        ]]
        local landed, message
        if
            player:GetAttribute("LastLightInExpedition") == true
            and self._regionEncounterService ~= nil
        then
            landed, message = self._regionEncounterService:strikeNearest(player, context)
        end
        if landed == nil then
            landed, message = self._enemyService:damageNearest(player, context)
        end
        if landed and context.weaponId ~= nil then
            local wearTrait =
                self._gearTraits.get(self._profileService:gearTraitOf(player, context.weaponId))
            local wearResult = self._profileService:accrueGearWear(
                player,
                context.weaponId,
                if wearTrait ~= nil then wearTrait.wearPointsOverride else nil
            )
            if
                wearResult.applied
                and wearResult.conditionAfter ~= wearResult.conditionBefore
                and wearResult.conditionAfter ~= "sound"
            then
                message = if wearResult.conditionAfter == "failing"
                    then Strings.get("tutorial.your_weapon_fails_whet_it_at")
                    else Strings.get("tutorial.your_weapon_dulls_half_strength_until")
            end
        end
        self:_setToast(player, message)
        self:_publishAll()
    end
end

function TutorialService.strikeFromClick(self: TutorialService, player: Player)
    if not self._limiter:allow(tostring(player.UserId), os.clock(), 2) then
        return
    end
    self:strike(player)
end

function TutorialService.interactFromClick(
    self: TutorialService,
    player: Player,
    interactionId: string
)
    if type(interactionId) ~= "string" or #interactionId > 64 then
        return
    end
    if not self._limiter:allow(tostring(player.UserId), os.clock(), 1) then
        return
    end
    self:_interact(player, interactionId)
end

function TutorialService._interact(
    self: TutorialService,
    player: Player,
    interactionId: string,
    skipTimer: boolean?
)
    local revivePrompt = self._survivalService:interaction(interactionId)
    if revivePrompt ~= nil then
        local result = self._survivalService:beginRevive(player, interactionId)
        self:_setToast(player, result.message)
        self:_publishAll()
        return
    end
    if not self._survivalService:canAct(player) then
        self:_setToast(player, Strings.get("tutorial.you_cannot_interact_while_downed"))
        self:_publishAll()
        return
    end

    local prompt = self._worldService:interaction(interactionId)
    if prompt == nil or not prompt.Enabled or not self._worldService:isInRange(player, prompt) then
        self:_setToast(player, Strings.get("tutorial.move_closer_to_the_marked_object"))
        self:_publish(player)
        return
    end

    local actionId = prompt:GetAttribute("ActionId")
    if type(actionId) ~= "string" then
        return
    end

    if actionId == self._runtimeIds.Actions.RecoverMemoryFragment then
        --[[
            Recovering a memory fragment.

            Handled before the tutorial-stage machinery for the same reason
            harvest nodes are: fragments belong to the expedition, not to the
            First Light sequence, and must neither advance it nor be gated by
            it. The client sends only the interaction ID; the server resolves
            which fragment that prompt carries, and the profile transaction is
            idempotent, so a duplicated tap re-reads rather than re-collecting.
        ]]
        local descriptor = self._worldService:memoryFragmentTarget(interactionId)
        if descriptor == nil then
            return
        end
        local result = self._profileService:collectMemoryFragment(player, descriptor.fragmentId)
        if result.accepted and result.fragment ~= nil then
            self:_setToast(
                player,
                string.format("%s — %s", result.fragment.title, result.fragment.body)
            )
            self._analyticsService:memoryFragmentRecovered(player, descriptor.fragmentId)
        elseif result.reason == "already_recovered" and result.fragment ~= nil then
            self:_setToast(
                player,
                string.format("%s — %s", result.fragment.title, result.fragment.body)
            )
        elseif result.reason == "chapter_unresolved" then
            self:_setToast(player, Strings.get("tutorial.this_memory_is_not_yet_yours"))
        else
            self:_setToast(player, Strings.get("tutorial.the_memory_slips_away_try_again"))
        end
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.GatherResource then
        --[[
            Harvesting a Bramblewake node.

            Handled before the tutorial-stage machinery below, because these
            nodes belong to the expedition rather than to the First Light
            sequence and must not advance or be gated by it. Uses the same
            timed gather as the town stump -- swing, bar, then the grant --
            and the same idempotent expedition grant path as events and
            encounters, keyed on the node's own ID, so a node pays out exactly
            once per run however many times it is clicked.
        ]]
        local node = self._worldService:resourceNode(interactionId)
        if node == nil then
            self:_setToast(player, Strings.get("tutorial.already_harvested"))
            self:_publish(player)
            return
        end
        if player:GetAttribute("LastLightInExpedition") ~= true then
            self:_setToast(player, Strings.get("tutorial.only_out_in_bramblewake"))
            self:_publish(player)
            return
        end
        if
            not skipTimer
            and self:_beginTimedAction(player, self._runtimeIds.Actions.Gather, interactionId)
        then
            return
        end
        -- { materialId = ..., amount = ... }, the ledger's contract -- not a
        -- materials map. The map shape threw "reward contract is invalid" on
        -- every single node harvest, which means no node on any route has
        -- ever actually paid out: the timer ran, the assert fired, the node
        -- survived to be clicked again. Found the first time the full
        -- harvest -> bank -> craft loop was driven end to end.
        local granted = self._expeditionService:grantNodeReward(
            player.UserId,
            interactionId,
            { materialId = node.materialId, amount = 1 }
        )
        if granted then
            self._worldService:markResourceNodeHarvested(interactionId)
            self:_setToast(player, "+1 " .. string.upper(node.objectText))
        end
        self:_publish(player)
        return
    end

    local session = self._sessions[player]
    if session == nil then
        return
    end

    if actionId == self._runtimeIds.Actions.ExpeditionEvent then
        local result = self._expeditionService:interact(player, prompt)
        self:_setToast(player, result.message)
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.RegionEncounter then
        local encounterId = prompt:GetAttribute("EncounterId")
        local anchorId = prompt:GetAttribute("Payload")
        if
            type(encounterId) == "string"
            and type(anchorId) == "string"
            and self._regionEncounterService ~= nil
        then
            self._regionEncounterService:interact(player, encounterId, anchorId)
            self:_publishAll()
        end
        return
    end
    if actionId == self._runtimeIds.Actions.SelectDestination then
        local regionId = prompt:GetAttribute("Payload")
        local result = self._expeditionService:selectDestination(player, regionId)
        self:_setToast(player, result.message)
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.OldGrowthFire then
        local result = self._oldGrowthService:interact(player, prompt)
        self:_setToast(player, result.message)
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.WardenStagChoice then
        local result = self._wardenStagService:interact(player, prompt)
        self:_setToast(player, result.message)
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.BramblewakeBlackout then
        local result = self._blackoutService:interact(player, prompt)
        --[[
            Coming home from a chapter has to show something changed, and
            it never did in the session it happened: the town consequence
            was only pushed at profile load, so the residents a resolved
            chapter sends and the greenward the vote plants waited for a
            rejoin. The single-place topology this ships on today has no
            rejoin between run and town, so push it the moment the profile
            has the chapter.
        ]]
        if result.reason == "resolved" then
            self._worldService:setTownConsequence(self._profileService:townConsequence(player))
        end
        self:_setToast(player, result.message)
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.Extract then
        local result = self._expeditionService:extract(player)
        local toast = result.message
        if result.accepted then
            local questSuffix = self:_questToastSuffix(player)
            if questSuffix ~= nil then
                toast = toast .. " · " .. questSuffix
            end
        end
        self:_setToast(player, toast)
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.CraftItem then
        if session.stage ~= "complete" then
            self:_setToast(player, Strings.get("tutorial.finish_first_light_to_craft"))
            self:_publish(player)
            return
        end
        local recipeId = prompt:GetAttribute("Payload")
        if type(recipeId) ~= "string" then
            return
        end
        local result = self._profileService:craftItem(player, recipeId)
        self._analyticsService:crafted(player, recipeId, result.accepted, result.reason)
        local toast: string
        if result.accepted then
            toast = string.format(Strings.get("tutorial.crafted_n"), prompt.ObjectText)
            local questSuffix = self:_questToastSuffix(player)
            if questSuffix ~= nil then
                toast = toast .. " · " .. questSuffix
            end
        elseif result.reason == "insufficient_materials" then
            toast = Strings.get("tutorial.not_enough_materials")
        else
            toast = Strings.get("tutorial.crafting_unavailable")
        end
        self:_setToast(player, toast)
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.ContributeConstruction then
        local buildingId = prompt:GetAttribute("Payload")
        if type(buildingId) ~= "string" then
            return
        end
        local result = self._profileService:contributeToConstruction(player, buildingId)
        if result.accepted then
            self:_setToast(
                player,
                string.format(
                    Strings.get("tutorial.n_built_to_stage_n"),
                    prompt.ObjectText,
                    result.stage
                )
            )
            -- Construction is shared town state, the same reasoning
            -- RepairTown's own _publishAll() call already uses: the stage a
            -- player just funded is visible to everyone in the world, not
            -- only to the player who paid for it.
            self._worldService:setTownConstruction(
                self._profileService:townConstructionState(player)
            )
            self:_publishAll()
            return
        end
        local toast: string
        if result.reason == "tier_not_ready" then
            toast = Strings.get("tutorial.survive_more_nights_before_building_further")
        elseif result.reason == "already_maxed" then
            toast = Strings.get("tutorial.already_fully_built")
        elseif result.reason == "insufficient_materials" then
            toast = Strings.get("tutorial.not_enough_materials_to_build")
        elseif result.reason == "unknown_building" then
            toast = Strings.get("tutorial.that_building_does_not_exist")
        else
            toast = Strings.get("tutorial.construction_unavailable")
        end
        self:_setToast(player, toast)
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.SetVisitPolicy then
        --[[
            The gate takes the next policy in the list rather than choosing
            one, so the press carries nothing and there is nothing in it to
            forge. Only the founder may set it: a visitor standing at the gate
            of somebody else's town is exactly the person a policy exists to
            answer, and letting them work the latch would be the whole feature
            backwards.
        ]]
        local hostInfo = self._townNightService:hostInfo(player.UserId)
        if hostInfo == nil or hostInfo.role ~= "host" then
            self:_setToast(player, Strings.get("tutorial.only_this_town_s_founder_sets"))
            self:_publish(player)
            return
        end
        local nextPolicy = self._townVisitPolicy.next(self._profileService:visitPolicy(player))
        self._profileService:setVisitPolicy(player, nextPolicy)
        self._townNightService:setHostPolicy(player.UserId, nextPolicy)
        self:_setToast(
            player,
            string.format(
                Strings.get("tutorial.the_gate_is_n"),
                self._townVisitPolicy.label(nextPolicy)
            )
        )
        -- Everyone, not just the presser: closing a gate changes what the
        -- people already standing in the town may read, and a snapshot they
        -- do not receive is a showcase they keep looking at.
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.PrivateControl then
        --[[
            A board on the private server's rail.

            Which board is the prompt's own attribute, read here, so nothing a
            client sends decides it. That matters more here than it does for
            the profession altars this pattern came from: working any of these
            ends the server's rewards permanently, and a payload that could
            name a control would be a one-line request that ends them from
            anywhere, with no rail in front of it and nobody standing at it.
        ]]
        local controlId = prompt:GetAttribute("Payload")
        if type(controlId) ~= "string" or self._privateServerService == nil then
            return
        end
        local _, message = self._privateServerService:press(player, controlId)
        self:_setToast(player, message)
        -- Everyone, because a held clock and a still night are facts about the
        -- server rather than about the presser, and a player watching the
        -- phase pill stop with no word for it is a player reporting a bug.
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.OpenStore then
        --[[
            The outfitter's stand, and the door the exit gate is about.

            The refusal is here rather than on the button because the button is
            a thing a client draws: a client that decided when the store may
            open is a client that could decide it may always open. A player
            refused is told which moment refused them, because "nothing
            happened" is how a working gate reads as a broken prompt.
        ]]
        local verdict = self:_storeVerdict(player)
        if not verdict.open then
            self:_setToast(player, verdict.label)
            self:_publish(player)
            return
        end
        --[[
            A revision rather than a flag. Closing the panel is the client's
            own business -- it has a CLOSE button and a world behind it -- and a
            server-held boolean the client cannot clear would reopen the store
            on the next push, which is a modal overlay reappearing over a night.
        ]]
        self._storeRevision[player] = (self._storeRevision[player] or 0) + 1
        if self._commerceService ~= nil then
            local store = self._commerceService:storeSnapshot(player)
            self._commerceService:recordStoreView(player, if store == nil then 0 else #store.cards)
        end
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.OpenFieldBook then
        self:_setToast(player, Strings.get("tutorial.field_book_updated_check_recipes_quests"))
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.SelectProfessionSpecialization then
        local specializationId = prompt:GetAttribute("Payload")
        if type(specializationId) ~= "string" then
            return
        end
        local result = self._professionService:selectSpecialization(player, specializationId)
        self:_setToast(player, result.message)
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.PlaceDecoration then
        local decorationId = prompt:GetAttribute("Payload")
        local result = self._profileService:placeDecoration(player, tostring(decorationId))
        if result.applied then
            self._worldService:setTownDecorations(self._profileService:decorationsSnapshot(player))
            self:_setToast(player, Strings.get("tutorial.decoration_placed_the_town_wears_your"))
        else
            local message = if result.reason == "decoration_cap"
                then Strings.get("tutorial.decoration_limit_reached_grow_the_town")
                elseif result.reason == "insufficient_materials" then Strings.get(
                    "tutorial.not_enough_materials"
                )
                elseif result.reason == "already_placed" then Strings.get(
                    "tutorial.already_decorated"
                )
                else Strings.get("tutorial.that_spot_cannot_be_decorated")
            self:_setToast(player, message)
        end
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.TalkResident then
        local residentId = prompt:GetAttribute("Payload")
        -- Talking IS checking on someone. Care shortens an injury and builds
        -- the bond; a healthy visit bonds once per night. The dialogue line
        -- still plays underneath, so the moment stays a conversation.
        local care = self._profileService:checkOnResident(player, tostring(residentId))
        if care.accepted and care.healed then
            self:_setToast(
                player,
                string.format(
                    Strings.get("tutorial.n_is_back_on_their_feet"),
                    string.upper(
                        string.gsub(string.gsub(tostring(residentId), "npc_", ""), "_", " ")
                    ),
                    care.bond
                )
            )
            self._worldService:setResidentInjured(tostring(residentId), false)
            self:_publish(player)
            return
        end
        local response = self._residentDialogue.respond(
            residentId,
            self._profileService:questSnapshot(player),
            self._profileService:townConsequence(player)
        )
        if response == nil then
            self:_setToast(player, Strings.get("tutorial.the_resident_is_busy_with_the"))
        else
            self:_setToast(player, response.message)
            self._analyticsService:residentTalked(
                player,
                tostring(residentId),
                response.questId,
                response.state
            )
        end
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.RepairTown then
        if player:GetAttribute("LastLightInExpedition") == true then
            self:_setToast(
                player,
                Strings.get("tutorial.return_through_wayhome_before_repairing_town")
            )
            self:_publish(player)
            return
        end
        -- Read off the prompt, never off client input: the repair prompt beside
        -- each damaged building carries that building's ID as its baked
        -- Payload, the same route a crafting bench uses for its recipe.
        local buildingId = prompt:GetAttribute("Payload")
        local result = self._townNightService:repairTown(buildingId)
        if result.accepted then
            for sessionPlayer in self._sessions do
                self._profileService:setTownCondition(sessionPlayer, result.condition)
            end
            self._analyticsService:townRepaired(
                player,
                result.condition.integrity,
                result.condition.repairsRemaining
            )
        end
        self:_setToast(player, result.message)
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.ResolveTownIncident then
        local result = self._townNightService:resolveIncident(player, prompt)
        self:_setToast(player, result.message)
        self:_publishAll()
        return
    end
    if actionId == self._runtimeIds.Actions.RecoverExpeditionCache then
        local result = self._expeditionService:recoverCache(player, prompt)
        self:_setToast(player, result.message)
        self:_publish(player)
        return
    end

    if actionId == self._runtimeIds.Actions.Build and session.resources < 3 then
        self:_setToast(player, Strings.get("tutorial.you_need_3_heartwood"))
        self:_publish(player)
        return
    end

    if actionId == self._runtimeIds.Actions.Reveal and session.stage == "complete" then
        if self._expeditionService:enter(player) then
            local regionId = self._expeditionService:currentSeed()
            -- The blackout is Bramblewake's own chapter event; a road
            -- pointed anywhere else has no blackout to join.
            local blackoutResult = if regionId == "region_bramblewake"
                then self._blackoutService:participantEntered(player)
                else { message = nil }
            -- Entering gets said first; the blackout's announcement follows
            -- rather than replacing it. Same reasoning as the completion
            -- toast in the tutorial's own Reveal handler below.
            self:_setToast(
                player,
                string.format(
                    Strings.get("toast.entering_n"),
                    RegionExpeditionAssembly.displayName(regionId)
                )
            )
            if blackoutResult.message ~= nil then
                local announcement = blackoutResult.message
                task.delay(3.4, function()
                    if player.Parent ~= nil and self._sessions[player] ~= nil then
                        self:_setToast(player, announcement)
                        self:_publish(player)
                    end
                end)
            end
            self._analyticsService:expeditionStarted(
                player,
                self._expeditionService:snapshot(player)
            )
        else
            self:_setToast(player, Strings.get("tutorial.the_wood_is_still_forming"))
        end
        self:_publish(player)
        return
    end

    --[[
        Gate timed actions here, after the resource and stage guards above but
        before _advance, which mutates. tutorialFlow.advance is pure, so the
        action can be checked for validity without committing to it: an
        invalid interaction still refuses immediately instead of making the
        player swing an axe and only then be told it was the wrong objective.
    ]]
    if not skipTimer and self._actionProgress.durationFor(actionId) ~= nil then
        local timedSession = self._sessions[player]
        local wouldAdvance = if timedSession == nil
            then nil
            else self._tutorialFlow.advance(timedSession.stage, actionId)
        if wouldAdvance ~= nil and self:_beginTimedAction(player, actionId, interactionId) then
            return
        end
    end

    --[[
        Tools stay swappable after First Light, the same freedom professions
        have: eight families are situational -- a pick for a sap run, the
        survey glass for an unfamiliar trail -- and locking the tutorial's
        one-shot choice forever would make seven of them dead content. The
        swap is town-only: not while downed, and not out in Bramblewake
        where the supply crates are a lodge away.
    ]]
    if
        actionId == self._runtimeIds.Actions.ChooseTool
        and session.stage == "complete"
        and self._survivalService:canAct(player)
        and player:GetAttribute("LastLightInExpedition") ~= true
    then
        local selectedTool = prompt:GetAttribute("Payload")
        if self._toolCatalog.isValid(selectedTool) then
            session.selectedTool = selectedTool
            self:_applyToolAttributes(player, selectedTool)
            self._profileService:setTutorial(player, session.stage, selectedTool)
            self:_setToast(player, self._toolCatalog.get(selectedTool).displayName .. " SELECTED")
            self:_publish(player)
            return
        end
    end

    local ok, reason = self:_advance(player, actionId)
    if not ok then
        local expected = self._tutorialFlow.definition(session.stage).objective
        self:_setToast(player, string.format(Strings.get("tutorial.current_objective_n"), expected))
        self._logger:warn("tutorial_action_rejected", {
            action = actionId,
            player = player.UserId,
            reason = reason,
            stage = session.stage,
        })
        self:_publish(player)
        return
    end

    if actionId == self._runtimeIds.Actions.Rescue then
        self._worldService:freeMara()
        self._worldService:moveMara(Vector3.new(2, 1.1, -38))
        self:_setToast(player, Strings.get("tutorial.mara_is_safe"))
    elseif actionId == self._runtimeIds.Actions.Gather then
        -- Handled by the timed-action path below, which swings the tool and
        -- runs the progress bar before granting anything.
        session.resources = 3
        self:_setToast(player, "+3 HEARTWOOD")
    elseif actionId == self._runtimeIds.Actions.ChooseTool then
        local selectedTool = prompt:GetAttribute("Payload")
        if self._toolCatalog.isValid(selectedTool) then
            session.selectedTool = selectedTool
            self:_applyToolAttributes(player, selectedTool)
            self._profileService:setTutorial(player, session.stage, selectedTool)
            local definition = self._toolCatalog.get(selectedTool)
            self:_setToast(player, definition.displayName .. " SELECTED")
        end
    elseif actionId == self._runtimeIds.Actions.Build then
        session.resources -= 3
        self._worldService:buildBarricade(true)
        self:_setToast(player, Strings.get("tutorial.barricade_complete"))
    elseif actionId == self._runtimeIds.Actions.Prepare then
        self:_setToast(player, Strings.get("tutorial.the_first_lantern_burns"))
        self._phaseService:startFirstNight()
    elseif actionId == self._runtimeIds.Actions.Reveal then
        if self._expeditionService:enter(player) then
            local firstRevealRegion = self._expeditionService:currentSeed()
            local blackoutResult = if firstRevealRegion == "region_bramblewake"
                then self._blackoutService:participantEntered(player)
                else { message = nil }
            --[[
                Finishing First Light gets its own line. The blackout's
                join announcement used to replace it entirely, so the
                moment the tutorial paid off, the only thing on screen
                was JOINED THE ACTIVE BRAMBLEWAKE BLACKOUT -- an event
                notice standing where the completion belonged. The event
                line follows a breath later instead of first.
            ]]
            self:_setToast(
                player,
                Strings.get("tutorial.first_light_complete_bramblewake_remembers_y")
            )
            if blackoutResult.message ~= nil then
                local announcement = blackoutResult.message
                task.delay(3.4, function()
                    if player.Parent ~= nil and self._sessions[player] ~= nil then
                        self:_setToast(player, announcement)
                        self:_publish(player)
                    end
                end)
            end
            self._analyticsService:expeditionStarted(
                player,
                self._expeditionService:snapshot(player)
            )
        else
            self:_setToast(player, Strings.get("tutorial.first_light_complete"))
        end
        -- GATE-METRIC: tutorial_completed
        self._analyticsService:complete(player)
    end

    self:_publishAll()
end

function TutorialService._advanceSurvivorToReveal(
    self: TutorialService,
    player: Player,
    session: Session
): boolean
    if session.stage ~= "survive" then
        return false
    end

    local nextStage = self._tutorialFlow.advanceSystem(session.stage)
    if nextStage == nil then
        return false
    end

    session.stage = nextStage
    session.toast = Strings.get("tutorial.dawn_breaks_follow_the_beacon")
    session.toastRevision += 1
    self._profileService:setTutorial(player, nextStage, session.selectedTool)
    local definition = self._tutorialFlow.definition(nextStage)
    self._analyticsService:stage(player, definition.index, nextStage)
    -- GATE-METRIC: first_night_completed
    -- Per player, at the moment this player's own tutorial leaves the night.
    -- The night itself resolves once for the whole server, and a gate that
    -- reads "first-night completion after onboarding" is counting people.
    self._analyticsService:firstNightCompleted(player)
    -- TUNING-METRIC: first_night_outcome
    -- The gate above says they got through it. This says what it cost, which
    -- is the only version of the question a tuning pass can act on.
    self._analyticsService:firstNightOutcome(player)
    -- TUNING-METRIC: difficulty_checkpoint
    -- The first checkpoint on the path, and the one every later cliff is
    -- measured against. Always cleared here, because reaching this line is
    -- what clearing it means.
    self._analyticsService:difficultyCheckpoint(player, "first_night", true)
    return true
end

function TutorialService._nightComplete(self: TutorialService)
    for player, session in self._sessions do
        self:_advanceSurvivorToReveal(player, session)
        self._townNightService:ensureStarted(
            self._profileService:nightNumber(player),
            self._profileService:townCondition(player),
            player.UserId
        )
    end
    self:_publishAll()
end

-- Consumable one-time buffs, not equipment: each craftable item is checked
-- for its own effect's preconditions before the item is spent, so a player
-- never loses one to a no-op (already full stamina, or unable to act).
function TutorialService._useGear(self: TutorialService, player: Player, itemId: string)
    local session = self._sessions[player]
    if session == nil or session.stage ~= "complete" then
        self._analyticsService:usedGear(player, itemId, false, "tutorial_incomplete")
        self:_setToast(player, Strings.get("tutorial.finish_first_light_to_use_gear"))
        self:_publish(player)
        return
    end
    if not self._survivalService:canAct(player) then
        self._analyticsService:usedGear(player, itemId, false, "player_downed")
        self:_setToast(player, Strings.get("tutorial.you_cannot_use_gear_while_downed"))
        self:_publish(player)
        return
    end
    --[[
        Everything below reads the consumable catalog rather than knowing
        item names. The precondition is checked before the item is spent,
        because a player must never lose one to a no-op, and the effect is
        applied by whichever service owns it -- this only decides which.
    ]]
    local definition = self._consumables.get(itemId)
    if definition == nil then
        self._analyticsService:usedGear(player, itemId, false, "unknown_item")
        return
    end
    local requires = definition.requires
    if requires == "stamina_not_full" then
        -- The freshly-advanced stamina restoreStamina itself computes, not
        -- the possibly-stale snapshot, so this cannot pass on stale data
        -- only for the real restore to find stamina already full after the
        -- item has been consumed.
        local staminaNow = self._combatService:peekStamina(player)
        if staminaNow == nil or staminaNow >= self._config.MaxStamina then
            self._analyticsService:usedGear(player, itemId, false, "stamina_full")
            self:_setToast(
                player,
                definition.refusedMessage or Strings.get("tutorial.nothing_to_restore")
            )
            self:_publish(player)
            return
        end
    elseif requires == "lantern_not_full" then
        if self._enemyService:lanternFull() then
            self._analyticsService:usedGear(player, itemId, false, "lantern_full")
            self:_setToast(
                player,
                definition.refusedMessage or Strings.get("tutorial.the_lantern_is_already_full")
            )
            self:_publish(player)
            return
        end
    elseif requires == "status_active" then
        if not self._combatService:isAfflicted(player) then
            self._analyticsService:usedGear(player, itemId, false, "nothing_to_clear")
            self:_setToast(
                player,
                definition.refusedMessage or Strings.get("tutorial.nothing_is_on_you")
            )
            self:_publish(player)
            return
        end
    elseif requires == "gear_worn" then
        if not self._profileService:hasWornGear(player) then
            self._analyticsService:usedGear(player, itemId, false, "nothing_worn")
            self:_setToast(
                player,
                definition.refusedMessage or Strings.get("tutorial.nothing_needs_mending")
            )
            self:_publish(player)
            return
        end
    elseif requires == "someone_hurt_nearby" then
        local canHeal, reason =
            self._survivalService:canHealInRadius(player, definition.effect.radius or 18)
        if not canHeal then
            self._analyticsService:usedGear(player, itemId, false, tostring(reason))
            self:_setToast(
                player,
                definition.refusedMessage or Strings.get("tutorial.nobody_near_you_needs_it")
            )
            self:_publish(player)
            return
        end
    end

    local result = self._profileService:useGearItem(player, itemId)
    self._analyticsService:usedGear(player, itemId, result.accepted, result.reason)
    if not result.accepted then
        self:_setToast(player, Strings.get("tutorial.you_don_t_have_that_item"))
        self:_publish(player)
        return
    end

    local effect = definition.effect
    if effect.kind == "shield" then
        self._combatService:applyShield(player, effect.amount, effect.seconds or 0.6)
    elseif effect.kind == "heal_party" then
        self._survivalService:healInRadius(player, effect.amount, effect.radius or 18)
    elseif effect.kind == "restore_lantern" then
        self._enemyService:restoreLanternStrength(effect.amount, "consumable:" .. itemId)
    elseif effect.kind == "cure_status" then
        self._combatService:clearAfflictions(player)
    elseif effect.kind == "repair_gear" then
        self._profileService:fieldRepairGear(player)
    else
        self._combatService:restoreStamina(player, effect.amount)
    end
    self:_setToast(player, definition.successMessage)
    self:_publish(player)
end

function TutorialService._handleAction(self: TutorialService, player: Player, payload: any)
    local contract = self._actionPayloadContract
    if not contract.isValidForKind(self._runtimeIds, payload) then
        --[[
            A request the payload contract refused, counted rather than only
            dropped.

            Every action in the game arrives through this door, so this is the
            one place that can say whether anybody is trying to send something
            they should not. The zero-tolerance gate is about a mutation that
            got through, which nothing can emit -- a mutation this server let
            through is by definition one it did not notice. What it can emit is
            the refusals, and a refusal rate that moves is the first sign a
            hole is being looked for.
        ]]
        -- GATE-METRIC: unauthorized_mutation
        self._analyticsService:unauthorizedMutation(
            player.UserId,
            "action_payload",
            if type(payload) == "table" then tostring(payload.kind) else "malformed"
        )
        return
    end
    local kind = payload.kind
    if
        not self._limiter:allow(
            tostring(player.UserId),
            os.clock(),
            contract.cost(self._runtimeIds, kind)
        )
    then
        return
    end

    if kind == self._runtimeIds.Actions.LobbyDepart then
        -- The client only ever asks. LobbyDeparture re-checks the size, the
        -- server's own ready count, and the capacity before anything starts.
        -- The departing party names its contract before the platform fires.
        -- Resolution is server-side and forgiving: junk becomes the standard
        -- sweep, never extra risk or reward.
        if payload.contractId ~= nil then
            local contractId = payload.contractId
            if type(contractId) == "string" and #contractId <= 40 then
                self._expeditionService:setContract(contractId)
            end
        end
        local result = self._lobbyService:requestDeparture(player, payload.partySize)
        if not result.accepted and result.reason == "invalid_party_size" then
            self:_setToast(player, Strings.get("tutorial.choose_a_party_size_first"))
        end
        self:_publishAll()
    elseif kind == self._runtimeIds.Actions.Interact then
        local interactionId = payload.interactionId
        if type(interactionId) == "string" and #interactionId <= 64 then
            self:_interact(player, interactionId)
        end
    elseif kind == self._runtimeIds.Actions.UseTool then
        self:strike(player)
    elseif kind == self._runtimeIds.Actions.Sprint and type(payload.enabled) == "boolean" then
        self._combatService:setSprint(player, payload.enabled)
    elseif kind == self._runtimeIds.Actions.Dodge then
        self._combatService:dodge(player)
    elseif kind == self._runtimeIds.Actions.ProfessionAbility then
        local result = self._professionService:useAbility(player)
        if not result.accepted then
            self:_setToast(player, result.message)
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.SelectProfession then
        local professionId = payload.professionId
        if type(professionId) == "string" and #professionId <= 32 then
            local result = self._professionService:select(player, professionId)
            if not result.accepted then
                self:_setToast(player, result.message)
                self:_publish(player)
            end
        end
    elseif kind == self._runtimeIds.Actions.UseGear then
        local itemId = payload.itemId
        if type(itemId) == "string" and #itemId <= 32 then
            self:_useGear(player, itemId)
        end
    elseif kind == self._runtimeIds.Actions.SaveLoadout then
        local slot = payload.slot
        if type(slot) == "number" then
            local result = self._profileService:saveLoadout(player, slot)
            self:_setToast(
                player,
                if result.applied
                    then string.format(Strings.get("tutorial.kit_n_saved"), slot)
                    else Strings.get("tutorial.kit_could_not_be_saved")
            )
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.ApplyLoadout then
        --[[
            Applying a kit walks the same validated paths its pieces use one
            at a time -- profession selection keeps its own daylight/town
            gates, equipping checks ownership, and the tool swap keeps the
            after-First-Light rule -- so a loadout can never smuggle a state
            change past a gate that a manual tap would have hit.
        ]]
        local slot = payload.slot
        local session2 = self._sessions[player]
        local loadout = if type(slot) == "number"
            then self._profileService:loadoutAt(player, slot)
            else nil
        if loadout == nil then
            self:_setToast(player, Strings.get("tutorial.that_kit_is_empty"))
            self:_publish(player)
        elseif
            session2 == nil
            or session2.stage ~= "complete"
            or not self._survivalService:canAct(player)
            or player:GetAttribute("LastLightInExpedition") == true
        then
            self:_setToast(player, Strings.get("tutorial.kits_swap_in_town_on_your"))
            self:_publish(player)
        else
            local applied = {}
            if loadout.professionId ~= nil then
                local result = self._professionService:select(player, loadout.professionId)
                if result.accepted then
                    table.insert(applied, Strings.get("hud.profession"))
                end
            end
            if loadout.weaponItemId ~= nil then
                local result = self._profileService:equipItem(player, loadout.weaponItemId)
                if result.accepted then
                    table.insert(applied, Strings.get("tutorial.weapon"))
                end
            end
            if loadout.toolId ~= nil and self._toolCatalog.isValid(loadout.toolId) then
                session2.selectedTool = loadout.toolId
                self:_applyToolAttributes(player, loadout.toolId)
                self._profileService:setTutorial(player, session2.stage, loadout.toolId)
                table.insert(applied, Strings.get("tutorial.tool"))
            end
            self:_setToast(
                player,
                if #applied > 0
                    then string.format(
                        Strings.get("tutorial.kit_n_n_ready"),
                        slot,
                        table.concat(applied, " · ")
                    )
                    else Strings.get("tutorial.kit_could_not_be_applied")
            )
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.PartyInvite then
        --[[
            The press names nobody. PartyService asks the platform who is
            standing there, which is the same reading the departure countdown
            works from, so an invitation and a boarding pass can never
            disagree about who was on the dais.
        ]]
        if self._partyService ~= nil then
            self._partyService:invite(player)
            self:_publishAll()
        end
    elseif kind == self._runtimeIds.Actions.PartyReply then
        local accept = payload.accept
        if self._partyService ~= nil and type(accept) == "boolean" then
            self._partyService:reply(player, accept)
            self:_publishAll()
        end
    elseif kind == self._runtimeIds.Actions.PartyLeave then
        if self._partyService ~= nil then
            self._partyService:leave(player)
            self:_publishAll()
        end
    elseif kind == self._runtimeIds.Actions.PartyRejoin then
        if self._partyService ~= nil then
            self._partyService:rejoin(player)
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.QuickChat then
        --[[
            A phrase reaches everyone who has not blocked the sender, so it is
            published to the whole server rather than to the presser. Nothing
            is toasted on success: the call appears in every recipient's own
            log, including the sender's, and a toast on top of that would be
            the game saying the same thing twice in the surface that #325
            found every success message dying in.
        ]]
        if self._socialService ~= nil then
            local result = self._socialService:say(player, payload.phraseId)
            if result.accepted then
                self:_publishAll()
            else
                if result.reason == "rate_limited" then
                    self:_setToast(player, Strings.get("tutorial.let_the_last_call_land"))
                elseif result.reason == "disabled" then
                    self:_setToast(player, Strings.get("tutorial.calls_are_closed_right_now"))
                end
                self:_publish(player)
            end
        end
    elseif kind == self._runtimeIds.Actions.StoreDetail then
        --[[
            A card looked at. It settles nothing and answers nothing, which is
            the point: the taxonomy counts detail views, and a count with no
            emitter is a dashboard reading nothing. The store gate is asked
            again anyway, because a card tapped through a stale panel during a
            night is still a store open during a night.
        ]]
        local productId = payload.productId
        if
            self._commerceService ~= nil
            and type(productId) == "string"
            and #productId <= 48
            and self:_storeVerdict(player).open
        then
            self._commerceService:viewDetail(player, productId)
        end
    elseif kind == self._runtimeIds.Actions.StorePurchase then
        local productId = payload.productId
        -- Bounded before it reaches anything, the same way every other id-carrying
        -- action here is. The catalog would refuse a non-string on its own; what
        -- the length adds is that a 128-character id never becomes a log line or
        -- an analytics field.
        if self._commerceService == nil or type(productId) ~= "string" or #productId > 48 then
            return
        end
        local verdict = self:_storeVerdict(player)
        if not verdict.open then
            self:_setToast(player, verdict.label)
            self:_publish(player)
            return
        end
        local result = self._commerceService:promptPurchase(player, productId)
        if not result.accepted then
            --[[
                Every refusal says something different, because the three mean
                genuinely different things to the person pressing. A product
                with no dashboard id is the owner's half of this milestone
                being outstanding, and saying so is better than a prompt that
                opens onto nothing -- which on a client looks exactly like the
                button being broken.
            ]]
            self:_setToast(
                player,
                if result.reason == "product_not_configured"
                    then Strings.get("tutorial.that_one_is_not_for_sale")
                    elseif result.reason == "unknown_product" then Strings.get(
                        "tutorial.no_such_thing_in_the_case"
                    )
                    elseif result.reason == "store_closed" then Strings.get(
                        "tutorial.the_outfitter_is_not_open_yet"
                    )
                    else Strings.get("tutorial.the_till_did_not_answer_try")
            )
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.EquipCosmetic then
        --[[
            Wearing is not buying, so it is not gated on the store being open.

            A player who is downed at the bottom of a night should not be sold
            anything, and this sells nothing: it changes a look they already
            paid for. Refusing it would mean a cosmetic that could only be
            taken off in daylight, which is a rule nobody asked for and one
            more thing a player would report as broken.
        ]]
        local cosmeticId = payload.cosmeticId
        if self._commerceService ~= nil and type(cosmeticId) == "string" and #cosmeticId <= 48 then
            local result = self._commerceService:equipById(player, cosmeticId)
            self:_setToast(
                player,
                if result.applied and result.reason == "removed"
                    then Strings.get("tutorial.taken_off")
                    elseif result.applied then Strings.get("tutorial.worn")
                    elseif result.reason == "not_owned" then Strings.get(
                        "tutorial.you_do_not_own_that"
                    )
                    elseif result.reason == "unknown_cosmetic" then Strings.get(
                        "tutorial.nothing_by_that_name"
                    )
                    elseif result.reason == "profile_loading" then Strings.get(
                        "tutorial.still_unpacking_your_things"
                    )
                    else Strings.get("tutorial.that_cannot_be_worn")
            )
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.CompanionCommand then
        local mode = payload.mode
        if self._companionService ~= nil and type(mode) == "string" and #mode <= 12 then
            local result = self._companionService:command(player, mode)
            self:_setToast(player, result.message)
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.RepairGear then
        local itemId = payload.itemId
        if type(itemId) == "string" and #itemId <= 32 then
            local result = self._profileService:repairGear(player, itemId)
            self:_setToast(
                player,
                if result.applied
                    then string.format(
                        Strings.get("tutorial.whetted_n_is_sound_again"),
                        gearDisplayName(self._equipmentCatalog, itemId)
                    )
                    elseif result.reason == "insufficient_materials" then Strings.get(
                        "tutorial.whetting_takes_half_the_recipe_s"
                    )
                    elseif result.reason == "not_worn" then Strings.get(
                        "tutorial.that_gear_is_already_sound"
                    )
                    else Strings.get("tutorial.that_gear_cannot_be_whetted")
            )
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.EquipGear then
        local itemId = payload.itemId
        if type(itemId) == "string" and #itemId <= 32 then
            local result = self._profileService:equipItem(player, itemId)
            self:_setToast(
                player,
                if result.accepted
                    then string.format(
                        Strings.get("tutorial.equipped_n"),
                        gearDisplayName(self._equipmentCatalog, itemId)
                    )
                    else Strings.get("tutorial.cannot_equip_item")
            )
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.CompactHud and type(payload.enabled) == "boolean" then
        local session = self._sessions[player]
        if session ~= nil then
            session.compactHud = payload.enabled
            self:_publish(player)
        end
    end
end

-- Push lobby state to every client. The countdown changes once a second and
-- is the same for everyone, so it broadcasts rather than publishing per-player
-- on a timer.
function TutorialService.broadcastLobby(self: TutorialService, toast: string?)
    if toast ~= nil then
        for player, session in self._sessions do
            session.toast = toast
            session.toastRevision += 1
            self:_publish(player)
        end
        return
    end
    self:_publishAll()
end

--[[
    Where the current objective physically is.

    The objective card names what to do; nothing ever said where. "Choose a
    starter tool" and "gather heartwood" both sent a new player wandering,
    which is the owner's report. Positions are resolved from the live
    interaction registry rather than a coordinate table, so a marker cannot
    drift from the thing it points at when a lot moves.
]]
function TutorialService._objectiveTargets(
    self: TutorialService,
    player: Player,
    session: Session
): { any }
    --[[
        In the expedition, the objective is whatever the Blackout wants next.
        The owner's tablet run made the gap concrete: "take rootfire from the
        Blackout Lantern" with no marker on the lantern, in the dark, in an
        unfamiliar forest. Every stage of the chapter now points somewhere --
        the fire source (or any lit root) when hands are empty, the next
        unlit root while carrying, the arenas for the encounters, the
        planters for the vote, and the Wayhome gate once the chapter is done.
    ]]
    if player:GetAttribute("LastLightInExpedition") == true then
        local resolved = {}
        local function add(part: BasePart?, label: string)
            if part ~= nil and part:IsA("BasePart") then
                table.insert(resolved, {
                    interactionId = part.Name,
                    x = part.Position.X,
                    y = part.Position.Y,
                    z = part.Position.Z,
                    label = label,
                })
            end
        end
        local blackout = self._blackoutService:snapshot(player)
        local arena = self._worldService:blackoutArena()
        if blackout ~= nil and arena ~= nil then
            if blackout.status == "relay" then
                self:_addSurveyTarget(player, add)
                if blackout.carryingFire and blackout.nextNodeId ~= nil then
                    add(
                        arena.relayNodes[blackout.nextNodeId],
                        Strings.get("world.deliver_rootfire")
                    )
                else
                    add(arena.fireSource, Strings.get("world.take_rootfire"))
                    -- deliveredNodeMap, not deliveredNodes: the latter is the
                    -- HUD's lit-count (a number), and iterating it threw
                    -- "attempt to iterate over a number value" on every
                    -- snapshot publish for the whole relay stage.
                    for nodeId, delivered in blackout.deliveredNodeMap or {} do
                        if delivered == true then
                            add(arena.relayNodes[nodeId], Strings.get("world.take_rootfire"))
                        end
                    end
                end
                return resolved
            elseif blackout.status == "old_growth" then
                local eliteArena = self._worldService:oldGrowthArena()
                if eliteArena ~= nil then
                    add(eliteArena.fireSource, Strings.get("tutorial.cleanse_old_growth"))
                end
                return resolved
            elseif blackout.status == "warden" then
                local bossSeal = self._worldService:wardenSealPart()
                add(bossSeal, Strings.get("tutorial.face_the_warden_stag"))
                return resolved
            elseif blackout.status == "resolution" then
                for _, target in arena.decisions do
                    add(target, Strings.get("tutorial.cast_your_vote"))
                end
                return resolved
            end
        end
        -- Chapter resolved or Blackout disabled: home is the objective.
        local wayhome = self._worldService:interaction(self._runtimeIds.InteractionIds.Wayhome)
        local holder = if wayhome ~= nil then wayhome.Parent else nil
        if holder ~= nil and holder:IsA("BasePart") then
            add(holder, Strings.get("bramblewake.wayhome_gate"))
        end
        self:_addSurveyTarget(player, add)
        return resolved
    end
    local definition = self._tutorialFlow.definition(session.stage)
    local targets = definition.targets
    if targets == nil then
        return {}
    end
    local resolved = {}
    for _, interactionId in targets do
        local prompt = self._worldService:interaction(interactionId)
        local holder = if prompt ~= nil then prompt.Parent else nil
        if holder ~= nil and holder:IsA("BasePart") then
            table.insert(resolved, {
                interactionId = interactionId,
                x = holder.Position.X,
                y = holder.Position.Y,
                z = holder.Position.Z,
                label = definition.objective,
            })
        end
    end
    return resolved
end

function TutorialService.snapshot(self: TutorialService, player: Player): any
    local session = self._sessions[player]
    if session == nil then
        return {
            schemaVersion = 1,
            status = "loading",
            worldReady = self._networkService:isWorldReady(),
        }
    end

    local definition = self._tutorialFlow.definition(session.stage)
    local progress, total = self._tutorialFlow.progress(session.stage)
    local objective = definition.objective
    local detail = definition.detail
    local mara = definition.mara
    local guideSpeaker = "Mara"
    local trailName = Strings.get("hud.first_light")
    local expedition = self._expeditionService:snapshot(player)
    if expedition.active then
        trailName = Strings.get("tutorial.bramblewake")
        progress = expedition.moduleIndex
        total = expedition.moduleTotal
        objective = if expedition.moduleIndex == expedition.moduleTotal
            then Strings.get("tutorial.bank_rewards_at_the_wayhome_gate")
            else Strings.get("tutorial.follow_the_foxfire_trail")
        local discovery = expedition.pointOfInterestName or expedition.eventName
        detail = if discovery == nil
            then expedition.moduleName
            else string.format("%s · %s", expedition.moduleName, discovery)
        -- A landmark gets to speak for itself; the generic line is only for
        -- the stretches of road between them.
        guideSpeaker = "You"
        mara = expedition.pointOfInterestDetail
            or Strings.get("tutorial.the_roots_remember_every_traveler_who")
        local event = expedition.event
        if event ~= nil then
            if event.status == "dormant" then
                objective = event.objective
                detail = string.format("%s · 0/%d", event.displayName, event.total)
                mara = event.detail
            elseif event.status == "active" then
                objective = event.objective
                detail = string.format(
                    "%s · %d/%d · %ds",
                    event.displayName,
                    event.progress,
                    event.total,
                    event.timeRemaining or 0
                )
                -- Once the event is running, Mara's line stops describing the
                -- scene and starts saying how to finish it. The flavour still
                -- plays while the event is dormant, which is when a player is
                -- deciding whether to start it rather than trying to solve it.
                mara = event.guidance or event.detail
            elseif event.status == "completed" then
                objective = Strings.get("tutorial.event_complete_follow_the_foxfire_trail")
                detail = event.completionMessage
                mara = Strings.get("tutorial.shared_expedition_rewards_are_safe_for")
            elseif event.status == "failed" then
                objective = Strings.get("tutorial.event_ended_follow_the_amber_path")
                detail = event.failureMessage
                mara = event.failureResolution
            end
        end
    end
    --[[
        Which clock the HUD pill shows follows the player's own progress and
        whether the town cycle is actually turning -- not whether the tutorial's
        First Night happened to run in this server session.

        PhaseService only leaves its initial "day" by running that night, so a
        player who arrives with a finished profile (or skips the tutorial in
        Studio) never moves it: hasCompletedFirstNight stayed false forever and
        the pill read DAY / MORNING through every night the town actually held,
        with nightActive false beside it. The town's clock is the one that is
        running for anyone past First Light, so that is the one they are shown.
    ]]
    local pastFirstLight = session.stage == "reveal"
        or session.stage == "complete"
        or self._phaseService:hasCompletedFirstNight()
    local phase = if pastFirstLight and self._townNightService:isRunning()
        then self._townNightService:snapshot()
        else self._phaseService:snapshot()
    local survival = self._survivalService:snapshot(player)
    local blackout = self._blackoutService:snapshot(player)
    if blackout ~= nil then
        trailName = Strings.get("tutorial.bramblewake_blackout")
        progress = blackout.stage
        total = blackout.stageCount
        objective = blackout.instruction
        detail = if blackout.status == "relay"
            then string.format(
                Strings.get("tutorial.n_next_n_n_n"),
                if blackout.carryingFire
                    then Strings.get("tutorial.carry_rootfire")
                    else Strings.get("world.take_rootfire"),
                tostring(blackout.nextNodeLabel or Strings.get("tutorial.root")),
                blackout.deliveredNodes,
                blackout.relayRequired
            )
            elseif blackout.status == "old_growth" then Strings.get(
                "tutorial.stage_2_4_rooted_walls_hold"
            )
            elseif blackout.status == "warden" then Strings.get(
                "tutorial.stage_3_4_the_warden_remembers"
            )
            elseif blackout.status == "resolution" then Strings.get(
                "tutorial.stage_4_4_farmland_wild_regrowth"
            )
            elseif blackout.status == "complete" then string.format(
                -- Decision IDs are snake_case; a raw one leaked into
                -- player-facing copy as "SHARED_AGROFOREST · PRESERVED".
                "%s · %s",
                string.upper(tostring(blackout.decision):gsub("_", " ")),
                string.upper(tostring(blackout.wardenOutcome):gsub("_", " "))
            )
            else Strings.get("tutorial.the_blackout_has_not_begun")
        --[[
            The traveler talks to themself out here -- the owner asked for
            exactly this: a voice saying what is actually going on and what to
            do next. Mara stayed in Emberhollow, so the expedition's guide
            voice is first person, and each line carries a piece of the
            chapter's story along with the instruction. The marker system says
            WHERE; this says WHY.
        ]]
        guideSpeaker = "You"
        mara = if blackout.status == "relay"
            then if blackout.carryingFire
                then Strings.get("tutorial.it_burns_fast_the_marked_root")
                else Strings.get("tutorial.the_evacuation_s_fire_still_burns")
            elseif blackout.status == "resolution" then Strings.get(
                "tutorial.the_greenward_is_asking_what_this"
            )
            elseif blackout.status == "complete" then Strings.get(
                "tutorial.the_seal_answered_me_whatever_i"
            )
            else Strings.get("tutorial.the_dark_out_here_is_old")
    end
    local elite = self._oldGrowthService:snapshot(player)
    if elite ~= nil and (blackout == nil or blackout.status == "old_growth") then
        if elite.active then
            objective = elite.instruction
            detail = string.format(
                Strings.get("tutorial.old_growth_phase_n_3_n"),
                elite.phase,
                elite.health,
                elite.maxHealth
            )
            mara = if elite.shielded
                then Strings.get("tutorial.steel_means_nothing_to_that_shield")
                else Strings.get("tutorial.there_the_amber_heart_strike_it")
        elseif elite.complete then
            objective = Strings.get("tutorial.old_growth_cleansed_continue_to_wayhome")
            detail = if elite.rewardEligible
                then "+3 AMBER SAP UNBANKED"
                else Strings.get("tutorial.the_oldest_roots_have_released_the")
            mara = if elite.rewardEligible
                then Strings.get("tutorial.the_oldest_roots_have_released_their")
                else Strings.get("tutorial.the_oldest_roots_were_cleansed_before")
        end
    end
    local boss = self._wardenStagService:snapshot(player)
    if boss ~= nil and (blackout == nil or blackout.status == "warden") then
        if blackout == nil then
            trailName = Strings.get("tutorial.warden_s_seal")
        end
        progress = boss.phase
        total = 3
        if boss.active then
            objective = boss.instruction
            detail = if boss.exposed
                then string.format(
                    Strings.get("tutorial.warden_stag_phase_n_3_n"),
                    boss.phase,
                    boss.health,
                    boss.maxHealth
                )
                else string.format(
                    Strings.get("tutorial.living_roots_n_n_antlers_broken"),
                    boss.cleansedNodes,
                    boss.rootNodesRequired,
                    boss.antlersBroken
                )
            mara = if boss.exposed
                then Strings.get("tutorial.its_memory_heart_is_open_strike")
                else Strings.get("tutorial.cleanse_living_roots_to_preserve_the")
        elseif boss.complete then
            objective = boss.instruction
            detail = if boss.rewardEligible
                then "+5 AMBER SAP UNBANKED"
                else Strings.get("tutorial.the_warden_s_choice_was_settled")
            mara = if boss.outcome == "preserved"
                then Strings.get("tutorial.the_warden_remembers_mercy_a_future")
                else Strings.get("tutorial.the_forest_remembers_what_was_broken")
        elseif boss.status == "locked" then
            objective = boss.instruction
            detail = Strings.get("tutorial.the_memory_seal_remains_rooted")
            mara = Strings.get("tutorial.the_oldest_growth_guards_the_way")
        end
    end
    local gearCare, whetTarget = self:_gearCare(player)
    return {
        schemaVersion = 1,
        status = "ready",
        worldReady = true,
        lobby = self._lobbyService:snapshot(),
        action = self:actionSnapshot(player),
        departed = self._lobbyService:isDeparted(player),
        stage = session.stage,
        tutorialComplete = session.stage == "complete",
        objective = objective,
        detail = detail,
        mara = mara,
        trailName = trailName,
        progress = progress,
        progressTotal = total,
        resources = session.resources,
        selectedTool = session.selectedTool,
        compactHud = session.compactHud,
        toast = session.toast,
        toastRevision = session.toastRevision,
        phase = phase.phase,
        phaseEndsAt = phase.phaseEndsAt,
        -- Only the town clock can be held, so the tutorial's own snapshot has
        -- neither field and both read nil there, which is the right answer.
        phaseHeld = phase.phaseHeld,
        phaseRemaining = phase.phaseRemaining,
        nightActive = phase.nightActive,
        lanternHealth = phase.lanternHealth,
        enemyCount = phase.enemyCount,
        nightNumber = phase.nightNumber,
        blackoutDue = phase.blackoutDue,
        expeditionActive = expedition.active,
        regionId = if expedition.active then "region_bramblewake" else "region_emberhollow",
        expeditionSeed = expedition.seed,
        expeditionManifestHash = expedition.manifestHash,
        expeditionModuleId = expedition.moduleId,
        expeditionPointOfInterestId = expedition.poiId,
        expeditionEventId = expedition.eventId,
        expeditionEventStatus = if expedition.event == nil then nil else expedition.event.status,
        expeditionEventProgress = if expedition.event == nil
            then nil
            else expedition.event.progress,
        expeditionEventProgressTotal = if expedition.event == nil
            then nil
            else expedition.event.total,
        unbankedExpeditionRewards = expedition.unbankedRewards,
        bankedMaterials = expedition.bankedMaterials,
        gear = self._profileService:gearSnapshot(player),
        companion = if self._companionService ~= nil
            then self._companionService:snapshot(player)
            else nil,
        party = if self._partyService ~= nil then self._partyService:snapshot(player) else nil,
        social = if self._socialService ~= nil then self._socialService:snapshot(player) else nil,
        store = (function(): any
            if self._commerceService == nil then
                return nil
            end
            local store = self._commerceService:storeSnapshot(player)
            if store == nil then
                return nil
            end
            local verdict = self:_storeVerdict(player, phase, survival)
            store.available = verdict.open
            store.reason = verdict.reason
            store.closedLabel = if verdict.open then nil else verdict.label
            -- The open instruction, and the only one the client acts on. It
            -- rises when the stand is used and never falls, so a client that
            -- missed a push opens late rather than never.
            store.revision = self._storeRevision[player] or 0
            return store
        end)(),
        --[[
            Whether this server still pays, and it is pushed to everyone rather
            than to the owner who latched it.

            A guest in somebody's practice server has no way to tell from the
            world that nothing they do is being kept -- the town looks the same,
            the toasts read the same, and the loss only shows up as a save that
            did not move. Saying it on the HUD is the difference between a
            practice server and a silently broken one.
        ]]
        practice = if self._privateServerService ~= nil
            then self._privateServerService:isPractice()
            else false,
        gearCare = gearCare,
        whetTarget = whetTarget,
        equipped = self._profileService:equippedSnapshot(player),
        equipmentStats = self._profileService:equipmentStats(player),
        mastery = self._profileService:masterySnapshot(player),
        townConsequence = self._profileService:townConsequence(player),
        townCondition = self._townNightService:conditionSnapshot(),
        recipes = self._craftingCatalog:list(),
        equipmentCatalog = self._equipmentCatalog.list(),
        objectiveTargets = self:_objectiveTargets(player, session),
        residentLife = self._profileService:residentLifeSnapshot(player),
        decorations = self._profileService:decorationsSnapshot(player),
        contract = self._expeditionService:contractSnapshot(),
        townHost = (function(): any
            local info = self._townNightService:hostInfo(player.UserId)
            if info == nil then
                return nil
            end
            local hostPlayer = Players:GetPlayerByUserId(info.hostUserId)
            --[[
                SAFETY-CHANNEL: town_showcase -- one player's town record read
                by another, gated on the role the visit policy decided.

                The showcase: the host's own town record, and the reason a
                policy is worth having. It is attached only for a host or an
                admitted visitor -- an outsider gets the role and nothing else,
                and so does a player whose relation the platform has not
                answered on yet. A record that renders before the gate has
                spoken is the gate not existing.
            ]]
            local showcase = nil
            if (info.role == "host" or info.role == "visitor") and hostPlayer ~= nil then
                local consequence = self._profileService:townConsequence(hostPlayer)
                showcase = {
                    tier = if type(consequence) == "table" then consequence.tier else nil,
                    nightNumber = self._townNightService:nightNumber(),
                    condition = self._townNightService:conditionSnapshot(),
                }
            end
            return {
                role = info.role,
                policy = if info.role == "host" then info.policy else nil,
                policyLabel = if info.role == "host"
                    then self._townVisitPolicy.label(info.policy)
                    else nil,
                hostName = if hostPlayer ~= nil then hostPlayer.DisplayName else nil,
                showcase = showcase,
            }
        end)(),
        guideSpeaker = guideSpeaker,
        quests = self._profileService:questSnapshot(player),
        memoryArchive = self._profileService:memoryFragments(player),
        combat = self._combatService:snapshot(player),
        profession = self._professionService:snapshot(player),
        elite = elite,
        boss = boss,
        blackout = blackout,
        threat = self._enemyService:threatSnapshot(player),
        survival = survival,
    }
end

function TutorialService._publish(self: TutorialService, player: Player)
    self._networkService:send(player, self:snapshot(player))
end

function TutorialService._publishAll(self: TutorialService)
    for player in self._sessions do
        self:_publish(player)
    end
end

return table.freeze(TutorialService)
