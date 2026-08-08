--!strict

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

    The order inside `press` is load-bearing: refuse, then latch, then move the
    world. Latching before the world is touched closes a window the width of a
    DataStore round trip in which the clock is already stopped and the rewards
    are not yet off; asking the refusal before either keeps a press that cannot
    land from latching anything at all.
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

    --[[
        Asked before anything is committed, and the ordering here is the whole
        of the review's finding about it.

        Two properties have to hold at once and they pull in opposite
        directions. A press whose world effect never lands must not advance the
        state or latch practice -- otherwise a refused seed press leaves
        `seedIndex` naming a seed the wood is not built on, and the readout
        starts lying about which wood you are standing next to. But the latch
        must also come *before* the world moves, or there is a window the width
        of a DataStore round trip in which the clock is already stopped and the
        rewards are not yet off.

        Both hold if the refusal is asked first: nothing is committed for a
        press that cannot land, and nothing can be written between the latch and
        the change it pays for.
    ]]
    local ready, refusal = self:_ready(control)
    if not ready then
        return false, refusal
    end

    local firstPress = self._controls.rewardsAllowed(self._state)
    if firstPress then
        self._profileService:beginPractice("private_server_control:" .. tostring(controlId))
        self._logger:warn("private_server_practice_engaged", {
            control = controlId,
            owner = player.UserId,
        })
    end
    self._state = result.state

    local message = self:_engage(player, control, result, seeds)
    if firstPress then
        message ..= " · THIS SERVER NO LONGER SAVES"
    end
    return true, message
end

-- Whether this control's world effect can land right now. Only the two that
-- can fail have anything to say; a toggle is a field and always can.
function PrivateServerService._ready(self: PrivateServerService, control: any): (boolean, string)
    if control.id == "call_phase" then
        if not self._townNightService:isRunning() then
            return false, "THERE IS NO CLOCK TO CALL ON YET"
        end
    elseif control.id == "choose_seed" then
        local expeditionService = self._expeditionService
        if expeditionService == nil then
            return false, "THE WOOD IS NOT STANDING YET"
        end
        if expeditionService:occupied() then
            return false, "SOMEBODY IS STILL IN THE WOOD"
        end
    end
    return true, ""
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
        self._townNightService:stepPhase()
        return "THE PHASE IS CALLED"
    elseif control.id == "choose_seed" then
        local chosen = self._controls.chosenSeed(result.state, seeds)
        local expeditionService = self._expeditionService :: any
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

return PrivateServerService
