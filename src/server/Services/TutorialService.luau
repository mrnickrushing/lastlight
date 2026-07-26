--!strict

local Players = game:GetService("Players")

local TutorialService = {}
TutorialService.__index = TutorialService
TutorialService.Name = "TutorialService"

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
        _phaseService: any,
        _analyticsService: any,
        _sessions: { [Player]: Session },
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
    phaseService: any,
    analyticsService: any
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
        _phaseService = phaseService,
        _analyticsService = analyticsService,
        _sessions = {},
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
end

function TutorialService.Start(self: TutorialService)
    Players.PlayerRemoving:Connect(function(player: Player)
        self._sessions[player] = nil
        self._limiter:clear(tostring(player.UserId))
        self._analyticsService:clear(player)
    end)

    for _, player in Players:GetPlayers() do
        local profile = self._profileService:get(player)
        if profile ~= nil then
            self:_profileLoaded(player, profile)
        end
    end

    self._networkService:setWorldReady(true)
end

function TutorialService._profileLoaded(self: TutorialService, player: Player, profile: any)
    if self._sessions[player] ~= nil then
        return
    end

    local stage = profile.tutorial.stage
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
    self._profileService:setTutorial(player, nextStage, session.selectedTool)
    local definition = self._tutorialFlow.definition(nextStage)
    self._analyticsService:stage(player, definition.index, nextStage)

    return true, nil
end

function TutorialService._interact(self: TutorialService, player: Player, interactionId: string)
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

    if actionId == self._runtimeIds.Actions.Build and session.resources < 3 then
        self:_setToast(player, "YOU NEED 3 HEARTWOOD")
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
        self:_setToast(player, "FIRST LIGHT COMPLETE")
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
    end
    self:_publishAll()
end

function TutorialService._setSprint(self: TutorialService, player: Player, enabled: boolean)
    local character = player.Character
    local humanoid = if character == nil then nil else character:FindFirstChildOfClass("Humanoid")
    if humanoid ~= nil then
        humanoid.WalkSpeed = if enabled
            then self._config.SprintWalkSpeed
            else self._config.BaseWalkSpeed
    end
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
            if kind == self._runtimeIds.Actions.UseTool then 2 else 1
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
        if session ~= nil and session.stage == "survive" then
            local _, message = self._enemyService:damageNearest(player)
            self:_setToast(player, message)
            self:_publishAll()
        end
    elseif kind == self._runtimeIds.Actions.Sprint and type(payload.enabled) == "boolean" then
        self:_setSprint(player, payload.enabled)
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
    local phase = self._phaseService:snapshot()
    return {
        schemaVersion = 1,
        status = "ready",
        worldReady = true,
        stage = session.stage,
        tutorialComplete = session.stage == "complete",
        objective = definition.objective,
        detail = definition.detail,
        mara = definition.mara,
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
