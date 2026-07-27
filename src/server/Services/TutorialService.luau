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
        _networkService: any,
        _profileService: any,
        _worldService: any,
        _enemyService: any,
        _survivalService: any,
        _combatService: any,
        _professionService: any,
        _phaseService: any,
        _townNightService: any,
        _expeditionService: any,
        _oldGrowthService: any,
        _wardenStagService: any,
        _blackoutService: any,
        _analyticsService: any,
        _craftingCatalog: any,
        _equipmentCatalog: any,
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
    networkService: any,
    profileService: any,
    worldService: any,
    enemyService: any,
    survivalService: any,
    combatService: any,
    professionService: any,
    phaseService: any,
    townNightService: any,
    expeditionService: any,
    oldGrowthService: any,
    wardenStagService: any,
    blackoutService: any,
    analyticsService: any,
    craftingCatalog: any,
    equipmentCatalog: any
): TutorialService
    return setmetatable({
        Name = TutorialService.Name,
        _logger = logger,
        _config = config,
        _runtimeIds = runtimeIds,
        _tutorialFlow = tutorialFlow,
        _rateLimiter = rateLimiter,
        _networkService = networkService,
        _profileService = profileService,
        _worldService = worldService,
        _enemyService = enemyService,
        _survivalService = survivalService,
        _combatService = combatService,
        _professionService = professionService,
        _phaseService = phaseService,
        _townNightService = townNightService,
        _expeditionService = expeditionService,
        _oldGrowthService = oldGrowthService,
        _wardenStagService = wardenStagService,
        _blackoutService = blackoutService,
        _analyticsService = analyticsService,
        _craftingCatalog = craftingCatalog,
        _equipmentCatalog = equipmentCatalog,
        _sessions = {},
        _expeditionModuleIndex = {},
        _expeditionEventRevision = {},
        _expeditionEventSecond = {},
        _limiter = rateLimiter.new(config.ActionRatePerSecond, config.ActionRatePerSecond * 2),
    }, TutorialService)
end

function TutorialService.Init(self: TutorialService, _context: any)
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
    self._townNightService:setNightCompletedHandler(function(nightNumber: number)
        for player in self._sessions do
            self._profileService:setNightNumber(player, nightNumber)
            local questSuffix = self:_questToastSuffix(player)
            if questSuffix ~= nil then
                self:_setToast(player, questSuffix)
            end
        end
        self:_publishAll()
    end)
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

    local stage = profile.tutorial.stage
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
    self._sessions[player] = session

    if
        stage == "build"
        or stage == "prepare"
        or stage == "survive"
        or stage == "reveal"
        or stage == "complete"
    then
        self._worldService:buildBarricade()
    end
    if stage == "survive" then
        if self._phaseService:hasCompletedFirstNight() then
            self:_advanceSurvivorToReveal(player, session)
        else
            self._phaseService:ensureFirstNight()
        end
    elseif stage == "reveal" or stage == "complete" then
        self._worldService:setBeaconVisible(true)
        self._townNightService:ensureStarted(profile.town.nightNumber)
    end

    local currentStage = session.stage
    local definition = self._tutorialFlow.definition(currentStage)
    self._analyticsService:stage(player, definition.index, currentStage)
    self:_publish(player)
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

function TutorialService._interact(self: TutorialService, player: Player, interactionId: string)
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
    if actionId == self._runtimeIds.Actions.OpenFieldBook then
        self:_setToast(player, "FIELD BOOK UPDATED — CHECK RECIPES, QUESTS, AND MASTERY")
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
        self._worldService:moveMara(Vector3.new(2, 1.1, -38))
        self:_setToast(player, "MARA IS SAFE")
    elseif actionId == self._runtimeIds.Actions.Gather then
        session.resources = 3
        self:_setToast(player, "+3 HEARTWOOD")
    elseif actionId == self._runtimeIds.Actions.ChooseTool then
        local selectedTool = prompt:GetAttribute("Payload")
        if type(selectedTool) == "string" then
            session.selectedTool = selectedTool
            self._profileService:setTutorial(player, session.stage, selectedTool)
            self:_setToast(player, string.upper(selectedTool) .. " SELECTED")
        end
    elseif actionId == self._runtimeIds.Actions.Build then
        session.resources -= 3
        self._worldService:buildBarricade()
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
        self._townNightService:ensureStarted(self._profileService:nightNumber(player))
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
    if type(payload) ~= "table" or payload.schemaVersion ~= 1 then
        return
    end
    local kind = payload.kind
    if type(kind) ~= "string" or #kind > 32 then
        return
    end

    local allowedFields: { [string]: boolean } = {
        schemaVersion = true,
        kind = true,
    }
    if kind == self._runtimeIds.Actions.Interact then
        allowedFields.interactionId = true
    elseif kind == self._runtimeIds.Actions.SelectProfession then
        allowedFields.professionId = true
    elseif
        kind == self._runtimeIds.Actions.UseGear
        or kind == self._runtimeIds.Actions.EquipGear
    then
        allowedFields.itemId = true
    elseif
        kind == self._runtimeIds.Actions.Sprint
        or kind == self._runtimeIds.Actions.CompactHud
    then
        allowedFields.enabled = true
    end
    for key in payload do
        if type(key) ~= "string" or allowedFields[key] ~= true then
            return
        end
    end
    if
        not self._limiter:allow(
            tostring(player.UserId),
            os.clock(),
            if kind == self._runtimeIds.Actions.UseTool
                    or kind == self._runtimeIds.Actions.ProfessionAbility
                then 2
                else 1
        )
    then
        return
    end

    if kind == self._runtimeIds.Actions.Interact then
        local interactionId = payload.interactionId
        if type(interactionId) == "string" and #interactionId <= 64 then
            self:_interact(player, interactionId)
        end
    elseif kind == self._runtimeIds.Actions.UseTool then
        local session = self._sessions[player]
        if
            session ~= nil
            and self._survivalService:canAct(player)
            and (session.stage == "survive" or player:GetAttribute("LastLightInExpedition") == true)
        then
            local _, message = self._enemyService:damageNearest(player)
            self:_setToast(player, message)
            self:_publishAll()
        end
    elseif kind == self._runtimeIds.Actions.Sprint and type(payload.enabled) == "boolean" then
        self._combatService:setSprint(player, payload.enabled)
    elseif kind == self._runtimeIds.Actions.Dodge then
        self._combatService:dodge(player)
    elseif kind == self._runtimeIds.Actions.ProfessionAbility then
        local result = self._professionService:useAbility(player)
        if result.accepted then
            local profile = self._profileService:get(player)
            if profile ~= nil and profile.profession.selectedId ~= nil then
                self._profileService:awardMastery(player, profile.profession.selectedId, 10)
            end
        else
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
        mara = "The roots remember every traveler. Keep to the amber path."
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
                mara = event.detail
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
                "ROOTFIRE RELAY · %d/%d%s",
                blackout.deliveredNodes,
                blackout.relayRequired,
                if blackout.carryingFire then " · CARRYING FIRE" else ""
            )
            elseif
                blackout.status == "old_growth"
            then "STAGE 2/4 · ROOTED WALLS HOLD UNTIL OLD GROWTH FALLS"
            elseif blackout.status == "warden" then "STAGE 3/4 · THE WARDEN REMEMBERS EVERY ANTLER"
            elseif
                blackout.status == "resolution"
            then "STAGE 4/4 · FARMLAND, WILD REGROWTH, OR SHARED AGROFOREST"
            elseif blackout.status == "complete" then string.format(
                "%s · %s",
                string.upper(tostring(blackout.decision)),
                string.upper(tostring(blackout.wardenOutcome))
            )
            else "THE BLACKOUT HAS NOT BEGUN"
        mara = if blackout.status == "relay"
            then "Take rootfire from the Blackout Lantern and carry it to each marked living root."
            elseif
                blackout.status == "resolution"
            then "Every active traveler votes. A tie becomes the shared agroforest."
            elseif
                blackout.status == "complete"
            then "The Greenward will remember this choice when the town grows."
            else "Keep the living path open. The Blackout clock never erases earned progress."
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
                then "The shield drinks force. Carry lantern fire from the ember to its heart."
                else "The amber heart is exposed. Strike, then clear the roots when they rise."
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
        recipes = self._craftingCatalog:list(),
        equipmentCatalog = self._equipmentCatalog.list(),
        quests = self._profileService:questSnapshot(player),
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
