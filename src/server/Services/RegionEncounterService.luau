--!strict

--[[
    One service for the six encounters the new regions brought.

    OldGrowthService and WardenStagService are each ~800 lines, and most
    of those lines are the same lines: hold a state table, spawn a model,
    watch who is in the arena, run a telegraph, route a strike, settle a
    reward once. Writing that four more times for the elites and twice
    more for the bosses would be five thousand lines of copy with five
    thousand chances to diverge, and the divergences are exactly where
    the bugs would live.

    So the encounters describe themselves and this drives them. Each one
    already exposes the same shape -- create, activate, join, strike,
    snapshot, rewardTransactionId, Tuning, Reward -- because they were
    written to the Old Growth's contract on purpose. What differs between
    them is the verb in the middle: the Echo's levers, the Widow's
    anchors, the Maw's lines and vents, the Many-Face's mirrors, the
    Caller's pools, the Witch's copies. Those arrive as an interaction
    table, so a fight's own rules stay in its own module and this file
    stays the thing that makes any of them happen in a world.

    Deliberately not here: model geometry (the arena builder owns that),
    telegraph visuals (the enemy attack flow owns those), and anything
    that would let a client assert progress. Every mutation below is
    called by the server in answer to an interaction the world raised.
]]

local RunService = game:GetService("RunService")

local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)

local RegionEncounterService = {}
RegionEncounterService.__index = RegionEncounterService
RegionEncounterService.Name = "RegionEncounterService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

--[[
    What an encounter has to tell this service about itself. The verbs
    are optional because no two of these fights ask the same thing: the
    Echo has levers and no windows, the Widow has windows and no levers,
    the Witch has neither and asks a question instead.
]]
export type Definition = {
    id: string,
    regionId: string,
    module: any,
    -- interactionId -> what to do with it, server-side, on a real tap.
    interactions: { [string]: (state: any, player: Player, now: number) -> (any, any) },
    -- Called on the service's tick; returns a new state or nil for "no change".
    tick: ((state: any, now: number) -> any?)?,
}

type Live = {
    definition: Definition,
    state: any,
    anchors: { [string]: BasePart },
}

export type RegionEncounterService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _profileService: any,
        _survivalService: any,
        _featureFlags: any,
        _runId: string,
        _manifestHash: string,
        _live: { [string]: Live },
        _toastHandler: ((Player?, string) -> ())?,
        _heartbeat: RBXScriptConnection?,
    },
    RegionEncounterService
))

function RegionEncounterService.new(
    logger: Logger,
    profileService: any,
    survivalService: any,
    featureFlags: any
): RegionEncounterService
    return setmetatable({
        Name = RegionEncounterService.Name,
        _logger = logger,
        _profileService = profileService,
        _survivalService = survivalService,
        _featureFlags = featureFlags,
        _runId = "",
        _manifestHash = "",
        _live = {},
        _toastHandler = nil,
        _heartbeat = nil,
    }, RegionEncounterService)
end

function RegionEncounterService.Init(_self: RegionEncounterService, _context: any) end

function RegionEncounterService.setToastHandler(
    self: RegionEncounterService,
    handler: (Player?, string) -> ()
)
    self._toastHandler = handler
end

function RegionEncounterService._toast(
    self: RegionEncounterService,
    player: Player?,
    message: string?
)
    local handler = self._toastHandler
    if handler ~= nil and message ~= nil and message ~= "" then
        handler(player, message)
    end
end

--[[
    Bind a region's encounters to a run. Called when a region is built,
    with the manifest hash that makes every reward id in the run unique
    to it -- the same guarantee the Old Growth has had since it shipped,
    and the reason a player cannot farm one elite by rejoining.
]]
function RegionEncounterService.beginRun(
    self: RegionEncounterService,
    runId: string,
    manifestHash: string,
    definitions: { Definition },
    anchorsById: { [string]: { [string]: BasePart } }
)
    assert(runId ~= "", "encounter run id is required")
    assert(manifestHash ~= "", "encounter manifest hash is required")
    self._runId = runId
    self._manifestHash = manifestHash
    self._live = {}
    for _, definition in definitions do
        local enabled = self._featureFlags:isEnabled("region_encounters_enabled")
        self._live[definition.id] = {
            definition = definition,
            state = definition.module.create(runId, manifestHash, enabled),
            anchors = anchorsById[definition.id] or {},
        }
        self._logger:info("region_encounter_ready", {
            encounter = definition.id,
            enabled = enabled,
            region = definition.regionId,
        })
    end
end

function RegionEncounterService.endRun(self: RegionEncounterService)
    self._live = {}
end

--[[
    A player taps something in an arena. The interaction table decides
    what that means to this fight, and the fight's own module decides
    whether it was allowed -- this only carries the answer back out.
]]
function RegionEncounterService.interact(
    self: RegionEncounterService,
    player: Player,
    encounterId: string,
    interactionId: string
): boolean
    local live = self._live[encounterId]
    if live == nil then
        return false
    end
    if not self._survivalService:canAct(player) then
        self:_toast(player, Strings.get("toast.you_cannot_do_that_while_downed"))
        return false
    end
    local handler = live.definition.interactions[interactionId]
    if handler == nil then
        return false
    end
    local nextState, result = handler(live.state, player, workspace:GetServerTimeNow())
    if nextState ~= nil then
        live.state = nextState
    end
    if type(result) == "table" then
        self:_toast(player, result.message)
        if result.completed == true then
            self:_settle(player, live)
        end
    end
    return true
end

--[[
    Strike whichever encounter this player is standing in. Returns the
    same (landed, message) shape EnemyService.damageNearest does, because
    the strike path routes through one call site and every encounter that
    answers it has to answer it the same way.
]]
function RegionEncounterService.damageNearest(
    self: RegionEncounterService,
    player: Player,
    encounterId: string,
    amount: number
): (boolean, string)
    local live = self._live[encounterId]
    if live == nil then
        return false, Strings.get("toast.no_encounter_is_active")
    end
    if not self._survivalService:canAct(player) then
        return false, Strings.get("toast.you_cannot_strike_while_downed")
    end
    local strike = live.definition.module.strike
    local nextState, result =
        strike(live.state, player.UserId, amount, workspace:GetServerTimeNow())
    live.state = nextState
    if type(result) ~= "table" or result.accepted ~= true then
        local snapshot = live.definition.module.snapshot(live.state, player.UserId, 0)
        return false, tostring(snapshot.instruction)
    end
    if result.completed == true then
        self:_settle(player, live)
    end
    return true, tostring(result.reason)
end

--[[
    Pay the encounter out, once per participant per run. The transaction
    id is the encounter's own, which is what makes a rejoin idempotent:
    the ledger has seen that id before and refuses the second grant
    without anyone here having to remember.
]]
function RegionEncounterService._settle(self: RegionEncounterService, player: Player, live: Live)
    local reward = live.definition.module.Reward
    if type(reward) ~= "table" then
        return
    end
    local transactionId = live.definition.module.rewardTransactionId(live.state, player.UserId)
    local result = self._profileService:grantUnbankedExpeditionReward(
        player,
        transactionId,
        self._manifestHash,
        { materialId = reward.materialId, amount = reward.amount }
    )
    self._logger:info("region_encounter_settled", {
        applied = if type(result) == "table" then result.applied else nil,
        encounter = live.definition.id,
        player = player.UserId,
    })
end

function RegionEncounterService.snapshot(
    self: RegionEncounterService,
    player: Player,
    encounterId: string
): any
    local live = self._live[encounterId]
    if live == nil then
        return nil
    end
    return live.definition.module.snapshot(live.state, player.UserId, workspace:GetServerTimeNow())
end

function RegionEncounterService.activeIds(self: RegionEncounterService): { string }
    local ids: { string } = {}
    for encounterId in self._live do
        table.insert(ids, encounterId)
    end
    table.sort(ids)
    return ids
end

function RegionEncounterService.Start(self: RegionEncounterService)
    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.25 then
            return
        end
        accumulator = 0
        local now = workspace:GetServerTimeNow()
        for _, live in self._live do
            local tick = live.definition.tick
            if tick ~= nil then
                local nextState = tick(live.state, now)
                if nextState ~= nil then
                    live.state = nextState
                end
            end
        end
    end)
end

return table.freeze(RegionEncounterService)
