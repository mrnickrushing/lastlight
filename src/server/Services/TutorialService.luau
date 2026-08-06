--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
        _companionService: any,
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
    gearTraits: any
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
        _companionService = nil,
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
                            "%s WAS HURT IN THE NIGHT — CHECK ON THEM",
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
                                "%s — NIGHT %d: %s",
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

function TutorialService.Start(self: TutorialService)
    Players.PlayerRemoving:Connect(function(player: Player)
        self._sessions[player] = nil
        self._expeditionModuleIndex[player] = nil
        self._expeditionEventRevision[player] = nil
        self._expeditionEventSecond[player] = nil
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
            then "PROFILE OFFLINE — PROGRESS WILL NOT SAVE"
            elseif stage == "complete" then "WELCOME BACK TO EMBERHOLLOW"
            else "FOLLOW THE LANTERN TRAIL",
        toastRevision = 1,
    }
    self:_applyToolAttributes(player, session.selectedTool)
    -- A guest is told they are one, at the door. The permission model has
    -- always protected the host's town; the visit only becomes deliberate
    -- when the visitor knows whose lanterns they are standing under.
    local hostInfo = self._townNightService:hostInfo(player.UserId)
    if hostInfo ~= nil and hostInfo.role == "visitor" then
        local hostPlayer = Players:GetPlayerByUserId(hostInfo.hostUserId)
        local hostName = if hostPlayer ~= nil then hostPlayer.DisplayName else "A FOUNDER"
        session.toast = string.format(
            "YOU ARE A GUEST IN %s'S EMBERHOLLOW — HELP IT GROW",
            string.upper(hostName)
        )
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
        table.insert(parts, string.format("QUEST COMPLETE: %s", quest.displayName))
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
        return false, "Your profile is still loading."
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
            self:_setToast(player, "ALREADY WORKING")
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
        add(node.target, "SURVEY · " .. string.upper(tostring(node.objectText)))
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
        local landed, message = self._enemyService:damageNearest(player, context)
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
                    then "YOUR WEAPON FAILS — WHET IT AT ITS BENCH"
                    else "YOUR WEAPON DULLS — HALF STRENGTH UNTIL WHETTED"
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
        self:_setToast(player, "YOU CANNOT INTERACT WHILE DOWNED")
        self:_publishAll()
        return
    end

    local prompt = self._worldService:interaction(interactionId)
    if prompt == nil or not prompt.Enabled or not self._worldService:isInRange(player, prompt) then
        self:_setToast(player, "MOVE CLOSER TO THE MARKED OBJECT")
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
            self:_setToast(player, "THIS MEMORY IS NOT YET YOURS TO READ")
        else
            self:_setToast(player, "THE MEMORY SLIPS AWAY — TRY AGAIN")
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
            self:_setToast(player, "ALREADY HARVESTED")
            self:_publish(player)
            return
        end
        if player:GetAttribute("LastLightInExpedition") ~= true then
            self:_setToast(player, "ONLY OUT IN BRAMBLEWAKE")
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
            self:_setToast(player, "FINISH FIRST LIGHT TO CRAFT")
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
            toast = string.format("CRAFTED %s", prompt.ObjectText)
            local questSuffix = self:_questToastSuffix(player)
            if questSuffix ~= nil then
                toast = toast .. " · " .. questSuffix
            end
        elseif result.reason == "insufficient_materials" then
            toast = "NOT ENOUGH MATERIALS"
        else
            toast = "CRAFTING UNAVAILABLE"
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
                string.format("%s BUILT TO STAGE %d", prompt.ObjectText, result.stage)
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
            toast = "SURVIVE MORE NIGHTS BEFORE BUILDING FURTHER"
        elseif result.reason == "already_maxed" then
            toast = "ALREADY FULLY BUILT"
        elseif result.reason == "insufficient_materials" then
            toast = "NOT ENOUGH MATERIALS TO BUILD"
        elseif result.reason == "unknown_building" then
            toast = "THAT BUILDING DOES NOT EXIST"
        else
            toast = "CONSTRUCTION UNAVAILABLE"
        end
        self:_setToast(player, toast)
        self:_publish(player)
        return
    end
    if actionId == self._runtimeIds.Actions.OpenFieldBook then
        self:_setToast(player, "FIELD BOOK UPDATED — CHECK RECIPES, QUESTS, AND MASTERY")
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
            self:_setToast(player, "DECORATION PLACED — THE TOWN WEARS YOUR WORK")
        else
            local message = if result.reason == "decoration_cap"
                then "DECORATION LIMIT REACHED — GROW THE TOWN FOR MORE ROOM"
                elseif result.reason == "insufficient_materials" then "NOT ENOUGH MATERIALS"
                elseif result.reason == "already_placed" then "ALREADY DECORATED"
                else "THAT SPOT CANNOT BE DECORATED"
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
                    "%s IS BACK ON THEIR FEET — BOND · %d",
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
            self:_setToast(player, "THE RESIDENT IS BUSY WITH THE NIGHT WATCH")
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
            self:_setToast(player, "RETURN THROUGH WAYHOME BEFORE REPAIRING TOWN")
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
        self:_setToast(player, "YOU NEED 3 HEARTWOOD")
        self:_publish(player)
        return
    end

    if actionId == self._runtimeIds.Actions.Reveal and session.stage == "complete" then
        if self._expeditionService:enter(player) then
            local blackoutResult = self._blackoutService:participantEntered(player)
            self:_setToast(player, blackoutResult.message or "ENTERING BRAMBLEWAKE")
            self._analyticsService:expeditionStarted(
                player,
                self._expeditionService:snapshot(player)
            )
        else
            self:_setToast(player, "BRAMBLEWAKE IS STILL FORMING")
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
        self:_setToast(player, "CURRENT OBJECTIVE: " .. expected)
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
        self:_setToast(player, "MARA IS SAFE")
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
        self:_setToast(player, "BARRICADE COMPLETE")
    elseif actionId == self._runtimeIds.Actions.Prepare then
        self:_setToast(player, "THE FIRST LANTERN BURNS")
        self._phaseService:startFirstNight()
    elseif actionId == self._runtimeIds.Actions.Reveal then
        if self._expeditionService:enter(player) then
            local blackoutResult = self._blackoutService:participantEntered(player)
            self:_setToast(player, blackoutResult.message or "BRAMBLEWAKE REMEMBERS YOU")
            self._analyticsService:expeditionStarted(
                player,
                self._expeditionService:snapshot(player)
            )
        else
            self:_setToast(player, "FIRST LIGHT COMPLETE")
        end
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
    session.toast = "DAWN BREAKS — FOLLOW THE BEACON"
    session.toastRevision += 1
    self._profileService:setTutorial(player, nextStage, session.selectedTool)
    local definition = self._tutorialFlow.definition(nextStage)
    self._analyticsService:stage(player, definition.index, nextStage)
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
        self:_setToast(player, "FINISH FIRST LIGHT TO USE GEAR")
        self:_publish(player)
        return
    end
    if not self._survivalService:canAct(player) then
        self._analyticsService:usedGear(player, itemId, false, "player_downed")
        self:_setToast(player, "YOU CANNOT USE GEAR WHILE DOWNED")
        self:_publish(player)
        return
    end
    if itemId == "gear_meadow_satchel" then
        -- Uses the same freshly-advanced stamina restoreStamina itself
        -- computes below, not the possibly-stale snapshot() value, so this
        -- check can't pass on stale data only for the real restore to find
        -- stamina already full after the item has been consumed.
        local staminaNow = self._combatService:peekStamina(player)
        if staminaNow == nil or staminaNow >= self._config.MaxStamina then
            self._analyticsService:usedGear(player, itemId, false, "stamina_full")
            self:_setToast(player, "STAMINA ALREADY FULL")
            self:_publish(player)
            return
        end
    elseif itemId ~= "gear_amber_charm" then
        self._analyticsService:usedGear(player, itemId, false, "unknown_item")
        return
    end

    local result = self._profileService:useGearItem(player, itemId)
    self._analyticsService:usedGear(player, itemId, result.accepted, result.reason)
    if not result.accepted then
        self:_setToast(player, "YOU DON'T HAVE THAT ITEM")
        self:_publish(player)
        return
    end

    if itemId == "gear_amber_charm" then
        self._combatService:applyShield(player, 5, 0.6)
        self:_setToast(player, "AMBER CHARM — SHIELDED")
    else
        local staminaResult = self._combatService:restoreStamina(player, 50)
        self:_setToast(
            player,
            if staminaResult.applied
                then "MEADOW SATCHEL — STAMINA RESTORED"
                else "MEADOW SATCHEL USED"
        )
    end
    self:_publish(player)
end

function TutorialService._handleAction(self: TutorialService, player: Player, payload: any)
    local contract = self._actionPayloadContract
    if not contract.isValidForKind(self._runtimeIds, payload) then
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
            self:_setToast(player, "CHOOSE A PARTY SIZE FIRST")
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
                    then string.format("KIT %d SAVED", slot)
                    else "KIT COULD NOT BE SAVED"
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
            self:_setToast(player, "THAT KIT IS EMPTY")
            self:_publish(player)
        elseif
            session2 == nil
            or session2.stage ~= "complete"
            or not self._survivalService:canAct(player)
            or player:GetAttribute("LastLightInExpedition") == true
        then
            self:_setToast(player, "KITS SWAP IN TOWN, ON YOUR FEET")
            self:_publish(player)
        else
            local applied = {}
            if loadout.professionId ~= nil then
                local result = self._professionService:select(player, loadout.professionId)
                if result.accepted then
                    table.insert(applied, "PROFESSION")
                end
            end
            if loadout.weaponItemId ~= nil then
                local result = self._profileService:equipItem(player, loadout.weaponItemId)
                if result.accepted then
                    table.insert(applied, "WEAPON")
                end
            end
            if loadout.toolId ~= nil and self._toolCatalog.isValid(loadout.toolId) then
                session2.selectedTool = loadout.toolId
                self:_applyToolAttributes(player, loadout.toolId)
                self._profileService:setTutorial(player, session2.stage, loadout.toolId)
                table.insert(applied, "TOOL")
            end
            self:_setToast(
                player,
                if #applied > 0
                    then string.format("KIT %d — %s READY", slot, table.concat(applied, " · "))
                    else "KIT COULD NOT BE APPLIED"
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
                    then "WHETTED — " .. string.upper(itemId) .. " IS SOUND AGAIN"
                    elseif
                        result.reason == "insufficient_materials"
                    then "WHETTING TAKES HALF THE RECIPE'S MATERIALS"
                    elseif result.reason == "not_worn" then "THAT GEAR IS ALREADY SOUND"
                    else "THAT GEAR CANNOT BE WHETTED"
            )
            self:_publish(player)
        end
    elseif kind == self._runtimeIds.Actions.EquipGear then
        local itemId = payload.itemId
        if type(itemId) == "string" and #itemId <= 32 then
            local result = self._profileService:equipItem(player, itemId)
            self:_setToast(
                player,
                if result.accepted then "EQUIPPED " .. string.upper(itemId) else "CANNOT EQUIP ITEM"
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
                    add(arena.relayNodes[blackout.nextNodeId], "DELIVER ROOTFIRE")
                else
                    add(arena.fireSource, "TAKE ROOTFIRE")
                    -- deliveredNodeMap, not deliveredNodes: the latter is the
                    -- HUD's lit-count (a number), and iterating it threw
                    -- "attempt to iterate over a number value" on every
                    -- snapshot publish for the whole relay stage.
                    for nodeId, delivered in blackout.deliveredNodeMap or {} do
                        if delivered == true then
                            add(arena.relayNodes[nodeId], "TAKE ROOTFIRE")
                        end
                    end
                end
                return resolved
            elseif blackout.status == "old_growth" then
                local eliteArena = self._worldService:oldGrowthArena()
                if eliteArena ~= nil then
                    add(eliteArena.fireSource, "CLEANSE OLD GROWTH")
                end
                return resolved
            elseif blackout.status == "warden" then
                local bossSeal = self._worldService:wardenSealPart()
                add(bossSeal, "FACE THE WARDEN STAG")
                return resolved
            elseif blackout.status == "resolution" then
                for _, target in arena.decisions do
                    add(target, "CAST YOUR VOTE")
                end
                return resolved
            end
        end
        -- Chapter resolved or Blackout disabled: home is the objective.
        local wayhome = self._worldService:interaction(self._runtimeIds.InteractionIds.Wayhome)
        local holder = if wayhome ~= nil then wayhome.Parent else nil
        if holder ~= nil and holder:IsA("BasePart") then
            add(holder, "WAYHOME GATE")
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
    local trailName = "FIRST LIGHT"
    local expedition = self._expeditionService:snapshot(player)
    if expedition.active then
        trailName = "BRAMBLEWAKE"
        progress = expedition.moduleIndex
        total = expedition.moduleTotal
        objective = if expedition.moduleIndex == expedition.moduleTotal
            then "BANK REWARDS AT THE WAYHOME GATE"
            else "FOLLOW THE FOXFIRE TRAIL"
        local discovery = expedition.pointOfInterestName or expedition.eventName
        detail = if discovery == nil
            then expedition.moduleName
            else string.format("%s · %s", expedition.moduleName, discovery)
        -- A landmark gets to speak for itself; the generic line is only for
        -- the stretches of road between them.
        guideSpeaker = "You"
        mara = expedition.pointOfInterestDetail
            or "The roots remember every traveler who walked out. Stay on the amber path and they remember me kindly."
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
                objective = "EVENT COMPLETE — FOLLOW THE FOXFIRE TRAIL"
                detail = event.completionMessage
                mara = "Shared expedition rewards are safe for this server run."
            elseif event.status == "failed" then
                objective = "EVENT ENDED — FOLLOW THE AMBER PATH"
                detail = event.failureMessage
                mara = event.failureResolution
            end
        end
    end
    local phase = if self._phaseService:hasCompletedFirstNight()
        then self._townNightService:snapshot()
        else self._phaseService:snapshot()
    local survival = self._survivalService:snapshot(player)
    local blackout = self._blackoutService:snapshot(player)
    if blackout ~= nil then
        trailName = "BRAMBLEWAKE BLACKOUT"
        progress = blackout.stage
        total = blackout.stageCount
        objective = blackout.instruction
        detail = if blackout.status == "relay"
            then string.format(
                "%s · NEXT %s · %d/%d",
                if blackout.carryingFire then "CARRY ROOTFIRE" else "TAKE ROOTFIRE",
                tostring(blackout.nextNodeLabel or "ROOT"),
                blackout.deliveredNodes,
                blackout.relayRequired
            )
            elseif
                blackout.status == "old_growth"
            then "STAGE 2/4 · ROOTED WALLS HOLD UNTIL OLD GROWTH FALLS"
            elseif blackout.status == "warden" then "STAGE 3/4 · THE WARDEN REMEMBERS EVERY ANTLER"
            elseif
                blackout.status == "resolution"
            then "STAGE 4/4 · FARMLAND, WILD REGROWTH, OR SHARED AGROFOREST"
            elseif blackout.status == "complete" then string.format(
                -- Decision IDs are snake_case; a raw one leaked into
                -- player-facing copy as "SHARED_AGROFOREST · PRESERVED".
                "%s · %s",
                string.upper(tostring(blackout.decision):gsub("_", " ")),
                string.upper(tostring(blackout.wardenOutcome):gsub("_", " "))
            )
            else "THE BLACKOUT HAS NOT BEGUN"
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
                then "It burns fast. The marked root, before the flame forgets my hands."
                else "The evacuation's fire still burns in that lantern. The living roots are starving for it — I carry, they wake."
            elseif
                blackout.status == "resolution"
            then "The Greenward is asking what this land becomes. Whatever we plant here, the town inherits."
            elseif
                blackout.status == "complete"
            then "The seal answered me. Whatever I am carrying, it is time to bring it home."
            else "The dark out here is old grief, not weather. Keep moving — nothing I have earned can be taken by the clock."
    end
    local elite = self._oldGrowthService:snapshot(player)
    if elite ~= nil and (blackout == nil or blackout.status == "old_growth") then
        if elite.active then
            objective = elite.instruction
            detail = string.format(
                "OLD GROWTH · PHASE %d/3 · %d/%d",
                elite.phase,
                elite.health,
                elite.maxHealth
            )
            mara = if elite.shielded
                then "Steel means nothing to that shield. Fire does — carry it from the ember to the heart."
                else "There — the amber heart. Strike it, and mind the roots when they rise."
        elseif elite.complete then
            objective = "OLD GROWTH CLEANSED — CONTINUE TO WAYHOME"
            detail = if elite.rewardEligible
                then "+3 AMBER SAP UNBANKED"
                else "THE OLDEST ROOTS HAVE RELEASED THE TRAIL"
            mara = if elite.rewardEligible
                then "The oldest roots have released their Amber Sap."
                else "The oldest roots were cleansed before you arrived."
        end
    end
    local boss = self._wardenStagService:snapshot(player)
    if boss ~= nil and (blackout == nil or blackout.status == "warden") then
        if blackout == nil then
            trailName = "WARDEN'S SEAL"
        end
        progress = boss.phase
        total = 3
        if boss.active then
            objective = boss.instruction
            detail = if boss.exposed
                then string.format(
                    "WARDEN STAG · PHASE %d/3 · %d/%d",
                    boss.phase,
                    boss.health,
                    boss.maxHealth
                )
                else string.format(
                    "LIVING ROOTS · %d/%d · ANTLERS BROKEN %d/2",
                    boss.cleansedNodes,
                    boss.rootNodesRequired,
                    boss.antlersBroken
                )
            mara = if boss.exposed
                then "Its memory heart is open. Strike before the roots close again."
                else "Cleanse living roots to preserve the forest. Breaking antlers is faster, but permanent."
        elseif boss.complete then
            objective = boss.instruction
            detail = if boss.rewardEligible
                then "+5 AMBER SAP UNBANKED"
                else "THE WARDEN'S CHOICE WAS SETTLED BEFORE YOU ARRIVED"
            mara = if boss.outcome == "preserved"
                then "The Warden remembers mercy. A future forest path remains possible."
                else "The forest remembers what was broken. The chapter can continue, but changed."
        elseif boss.status == "locked" then
            objective = boss.instruction
            detail = "THE MEMORY SEAL REMAINS ROOTED"
            mara = "The oldest growth guards the way to the Warden."
        end
    end
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
            return {
                role = info.role,
                hostName = if hostPlayer ~= nil then hostPlayer.DisplayName else nil,
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
