--!strict

local Players = game:GetService("Players")

--[[
    The private server's control rail, and the latch behind it.

    `PrivateServerControls` decides everything decidable without a running
    server -- who may press, what a press does to the state, and the one rule
    that every press ends this server's rewards. This service is the shell: it
    holds the state, asks the pure module, and turns the answer into the three
    things in this game that can be held still.

    It is deliberately the only caller of `ProfileService:beginPractice`,
    `TownNightService:setHold`/`stepPhase`, `EnemyService:setStillness` and
    `ExpeditionService:rebuildWithSeed`. Those five entry points exist for this
    file and nothing else reaches them, which is what keeps "a practice phase
    grants nothing" a statement about one path rather than about five.

    The order inside `press` is load-bearing and runs latch-first: the profile
    goes read-only *before* the world is touched. The other order has a window
    -- narrow, real, and exactly the width of a DataStore round trip -- in
    which the clock is already stopped and the rewards are not yet off.
]]

local PrivateServerService = {}
PrivateServerService.__index = PrivateServerService
PrivateServerService.Name = "PrivateServerService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type PrivateServerService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _controls: any,
        _profileService: any,
        _townNightService: any,
        _enemyService: any,
        _expeditionService: any,
        _analyticsService: any,
        _state: any,
    },
    PrivateServerService
))

function PrivateServerService.new(
    logger: Logger,
    privateServerControls: any,
    profileService: any,
    townNightService: any,
    enemyService: any,
    analyticsService: any
): PrivateServerService
    return setmetatable({
        Name = PrivateServerService.Name,
        _logger = logger,
        _controls = privateServerControls,
        _profileService = profileService,
        _townNightService = townNightService,
        _enemyService = enemyService,
        _expeditionService = nil,
        _analyticsService = analyticsService,
        _state = privateServerControls.default(),
    }, PrivateServerService)
end

function PrivateServerService.Init(_self: PrivateServerService, _context: any) end

function PrivateServerService.Start(_self: PrivateServerService) end

function PrivateServerService.setExpeditionService(
    self: PrivateServerService,
    expeditionService: any
)
    self._expeditionService = expeditionService
end

--[[
    What Roblox says about this server, in the shape the pure module reads.

    A Studio session is neither a private server nor a reserved one, so the
    attribute is the only way to reach this rail from a playtest at all --
    the same reason `LastLightStudioStore` exists, and it fakes exactly one
    thing: the owner. Every refusal, every latch and every consequence below
    is the real path.
]]
function PrivateServerService.server(_self: PrivateServerService): any
    local studioOwner = tonumber(game:GetAttribute("LastLightStudioPrivateServer"))
    if studioOwner ~= nil and studioOwner > 0 then
        return { privateServerId = "studio", privateServerOwnerId = studioOwner }
    end
    return {
        privateServerId = game.PrivateServerId,
        privateServerOwnerId = game.PrivateServerOwnerId,
    }
end

function PrivateServerService.state(self: PrivateServerService): any
    return self._controls.normalize(self._state)
end

function PrivateServerService.isPractice(self: PrivateServerService): boolean
    return not self._controls.rewardsAllowed(self._state)
end

function PrivateServerService.readout(
    self: PrivateServerService,
    player: Player,
    controlId: string
): string
    return self._controls.readout(
        self._state,
        controlId,
        self._profileService:discoveredSeeds(player)
    )
end

--[[
    Press one of the boards.

    Returns a message rather than a boolean because every path here has
    something worth saying: a refusal names which of the three reasons it is,
    and an acceptance names what the world now does. A control that changed
    the server and said nothing would be indistinguishable from a dead board,
    which is the failure #337 found on the store's BUY button.
]]
function PrivateServerService.press(
    self: PrivateServerService,
    player: Player,
    controlId: any
): (boolean, string)
    local allowed, reason = self._controls.authority(self:server(), player.UserId)
    if not allowed then
        return false, self._controls.refusal(reason)
    end

    local seeds = self._profileService:discoveredSeeds(player)
    local result = self._controls.apply(self._state, controlId, seeds)
    if not result.ok then
        return false, self._controls.refusal(result.reason)
    end

    local control = self._controls.byId(controlId)
    local firstPress = self._controls.rewardsAllowed(self._state)
    self._state = result.state

    -- The latch, before anything in the world moves.
    if firstPress then
        self._profileService:beginPractice("private_server_control:" .. tostring(controlId))
        self._logger:warn("private_server_practice_engaged", {
            control = controlId,
            owner = player.UserId,
        })
    end

    local message = self:_engage(player, control, result, seeds)
    if firstPress then
        message ..= " · THIS SERVER NO LONGER SAVES"
    end
    return true, message
end

function PrivateServerService._engage(
    self: PrivateServerService,
    player: Player,
    control: any,
    result: any,
    seeds: any
): string
    if control.id == "hold_clock" then
        self._townNightService:setHold(result.state.hold)
        return if result.state.hold then "THE CLOCK IS HELD" else "THE CLOCK RUNS AGAIN"
    elseif control.id == "still_dark" then
        self._enemyService:setStillness(result.state.still)
        return if result.state.still then "THE DARK HOLDS STILL" else "THE DARK MOVES AGAIN"
    elseif control.id == "call_phase" then
        if not self._townNightService:stepPhase() then
            return "THERE IS NO CLOCK TO CALL ON YET"
        end
        return "THE PHASE IS CALLED"
    elseif control.id == "choose_seed" then
        local chosen = self._controls.chosenSeed(result.state, seeds)
        local expeditionService = self._expeditionService
        if expeditionService == nil then
            return "THE WOOD IS NOT STANDING YET"
        end
        --[[
            Cycling back past the end of the history is a return to the seed
            this server rolled for itself, which has to mean rebuilding to it
            rather than leaving the last chosen one standing. A control that
            said THIS SERVER'S OWN over somebody else's wood would be lying in
            the one place the readout is all the player has.
        ]]
        local _, ownSeed = expeditionService:currentSeed()
        local seed = if chosen == nil then ownSeed else chosen.seed
        local rebuilt, why = expeditionService:rebuildWithSeed(seed)
        if not rebuilt then
            return if why == "expedition_occupied"
                then "SOMEBODY IS STILL IN THE WOOD"
                else "THAT SEED DOES NOT ANSWER"
        end
        return "THE WOOD IS " .. self:readout(player, control.id)
    end
    return "SET"
end

--[[
    Everything the rail's boards read, for the snapshot.

    Built per player because the seed board reads that player's own history,
    and a rail that showed the owner's chosen seed to a guest would be showing
    them a number out of a save they cannot see.
]]
function PrivateServerService.snapshot(self: PrivateServerService, player: Player): any
    local allowed = self._controls.authority(self:server(), player.UserId)
    local boards = {}
    for _, control in self._controls.controls() do
        table.insert(boards, {
            id = control.id,
            label = control.label,
            readout = self:readout(player, control.id),
        })
    end
    return {
        available = allowed,
        practice = self:isPractice(),
        boards = boards,
    }
end

-- Whether anybody in this server is standing in the expedition, which the seed
-- board refuses over. Exposed for the same reason the readout is: a refusal a
-- player can predict is a refusal that does not read as a broken board.
function PrivateServerService.expeditionOccupied(_self: PrivateServerService): boolean
    for _, player in Players:GetPlayers() do
        if player:GetAttribute("LastLightInExpedition") == true then
            return true
        end
    end
    return false
end

return PrivateServerService
