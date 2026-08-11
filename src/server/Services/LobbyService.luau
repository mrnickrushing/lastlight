--!strict

--[[
    Drives the Emberhollow departure platform.

    All the rules about whether a departure may start, how long is left, and
    who may board live in the pure LobbyDeparture module. This service owns
    only the parts that need the world: who is physically standing on the
    platform, moving a launched party to the arrival clearing, and keeping a
    departed player there across respawns.

    Occupancy is measured server-side from character positions every tick. A
    client cannot claim to be on the platform, and a client that asks for a
    departure is only ever asking -- LobbyDeparture re-checks every bound.
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local RegionAccess =
    require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").RegionAccess)
local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)
local RegionExpeditionAssembly = require(script.Parent.Parent.World.RegionExpeditionAssembly)

local LobbyService = {}
LobbyService.__index = LobbyService
LobbyService.Name = "LobbyService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type LobbyService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _lobbyDeparture: any,
        _runHandoff: any,
        _isRunServer: boolean,
        _featureFlags: any,
        _worldService: any,
        _analyticsService: any,
        _partyService: any,
        _state: any,
        _departed: { [Player]: boolean },
        _onChanged: ((string?) -> ())?,
        _heartbeat: RBXScriptConnection?,
        _lastPublishedSeconds: number,
    },
    LobbyService
))

local PLATFORM_VERTICAL_TOLERANCE = 12

function LobbyService.new(
    logger: Logger,
    config: any,
    lobbyDeparture: any,
    runHandoff: any,
    featureFlags: any,
    worldService: any,
    analyticsService: any
): LobbyService
    return setmetatable({
        Name = LobbyService.Name,
        _logger = logger,
        _config = config,
        _lobbyDeparture = lobbyDeparture,
        _runHandoff = runHandoff,
        _isRunServer = false,
        _featureFlags = featureFlags,
        _worldService = worldService,
        _analyticsService = analyticsService,
        _partyService = nil,
        _state = lobbyDeparture.create(),
        _departed = {},
        _onChanged = nil,
        _heartbeat = nil,
        _lastPublishedSeconds = -1,
    }, LobbyService)
end

function LobbyService.Init(_self: LobbyService, _context: any) end

function LobbyService.setChangedHandler(self: LobbyService, callback: (string?) -> ())
    self._onChanged = callback
end

--[[
    Parties, if this server has them.

    Optional on purpose. Everything below works without a party service and
    behaves exactly as it did before parties existed: seats are spent in the
    order the platform reports them, a departure carries no party ID, and
    nobody is issued a ticket home. What a party adds is an ordering and a way
    back, not a requirement.
]]
function LobbyService.setPartyService(self: LobbyService, partyService: any)
    self._partyService = partyService
end

function LobbyService._notify(self: LobbyService, message: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(message)
    end
end

local function rootOf(player: Player): BasePart?
    local character = player.Character
    if character == nil then
        return nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    return if root ~= nil and root:IsA("BasePart") then root else nil
end

--[[
    Players physically standing on the platform.

    Measured from the server's own view of character positions, never from a
    client claim. A departed player is excluded so someone who walks back onto
    the platform after launching cannot be counted into the next party while
    still mid-transition.
]]
function LobbyService.readyPlayers(self: LobbyService): { Player }
    local center, radius = self._worldService:departurePlatform()
    local ready = {}
    for _, player in Players:GetPlayers() do
        if not self._departed[player] then
            local root = rootOf(player)
            if root ~= nil then
                local offset = root.Position - center
                --[[
                    The built platform (WorldService) is a square, RADIUS*2 on
                    a side -- but this used to test the flat offset's
                    magnitude against RADIUS, which is the circle *inscribed*
                    in that square. A circle's corners fall short of the
                    square's, so a player standing in any of the platform's
                    four corners -- visibly on the dais, arguably the part of
                    it closest to the doorway -- was told to stand on the
                    platform while doing exactly that. About a fifth of the
                    platform's own surface area (1 - pi/4) was a dead zone.
                    Testing each axis against RADIUS independently matches the
                    square WorldService actually builds, corners included.
                ]]
                if
                    math.abs(offset.X) <= radius
                    and math.abs(offset.Z) <= radius
                    and math.abs(offset.Y) <= PLATFORM_VERTICAL_TOLERANCE
                then
                    table.insert(ready, player)
                end
            end
        end
    end
    return ready
end

function LobbyService.isDeparted(self: LobbyService, player: Player): boolean
    return self._departed[player] == true
end

--[[
    A client asking to start a departure for `size` players.

    Every bound is re-checked in LobbyDeparture against the server's own ready
    count and the configured capacity, so a forged size or a spammed request
    cannot start, resize, or rush a countdown.
]]
function LobbyService.requestDeparture(self: LobbyService, player: Player, size: any): any
    if not self._featureFlags:isEnabled("lobby_departure_enabled") then
        return { accepted = false, reason = "lobby_disabled" }
    end
    local ready = self:readyPlayers(self)
    local readyCount = #ready
    local now = workspace:GetServerTimeNow()
    local nextState, result = self._lobbyDeparture.requestDeparture(
        self._state,
        size,
        now,
        readyCount,
        self._config.MaxExpeditionPlayers
    )
    self._state = nextState
    self._analyticsService:lobbyDeparture(player, "request", result.accepted, result.reason, size)
    if result.accepted then
        self:_notify(
            string.format(Strings.get("toast.departing_in_n_stand_on_the"), result.secondsRemaining)
        )
    elseif result.reason == "platform_empty" then
        self:_notify(Strings.get("hud.stand_on_the_platform_to_depart"))
    elseif result.reason == "already_counting" then
        self:_notify(Strings.get("toast.a_departure_is_already_under_way"))
    end
    return result
end

function LobbyService.snapshot(self: LobbyService): any
    local now = workspace:GetServerTimeNow()
    local view = self._lobbyDeparture.snapshot(self._state, now)
    return {
        counting = view.counting,
        partySize = view.partySize,
        secondsRemaining = view.secondsRemaining,
        readyCount = #self:readyPlayers(self),
        maxPartySize = self._config.MaxExpeditionPlayers,
    }
end

--[[
    Send a boarded party to the arrival clearing.

    Players are placed in a small ring so a full party does not land inside one
    another, and marked departed so a respawn keeps them in the game rather
    than dropping them back into the lobby.
]]
--[[
    Is this server a run, or the lobby?

    Resolved once from the teleport payload this server was started with.
    Anything unrecognised resolves to a lobby, which is the safe direction:
    a server that wrongly thinks it is a run drops players into the world
    with no way to start one, while a server that wrongly thinks it is a
    lobby only shows a staging room they can depart from again.
]]
function LobbyService.isRunServer(self: LobbyService): boolean
    return self._isRunServer
end

--[[
    Read the teleport payload a joining player arrived with.

    The payload travels per player, so the first arrival carrying a valid run
    payload settles what this server is, and later joins cannot change it. The
    payload is inert by design -- it can say "this is a run" and nothing about
    rewards or progression -- so trusting it decides only which room the
    player wakes up in.
]]
function LobbyService._adoptArrival(self: LobbyService, player: Player)
    local data: any = nil
    pcall(function()
        data = player:GetJoinData().TeleportData
    end)
    local read = self._runHandoff.readPayload(data)
    if not read.isRun then
        return
    end
    if not self._isRunServer then
        self._isRunServer = true
        self._logger:info("run_server_adopted", { partySize = read.partySize })
    end
    -- A run server that knows which party it belongs to can recognise one of
    -- its own members coming back on a rejoin ticket and leave them where
    -- they landed, rather than forwarding them into the world they are
    -- already standing in.
    if read.partyId ~= nil and self._partyService ~= nil then
        self._partyService:adoptRun(read.partyId)
    end
    -- Departed players skip the lodge: the existing respawn path puts them at
    -- the arrival clearing and keeps them there.
    self._departed[player] = true
end

--[[
    Send a boarded party to its own reserved server.

    Reserving and teleporting are separate calls and either can fail. Both are
    wrapped, and any failure runs the same recovery: the party stays in the
    lodge, the departure is cancelled, and nothing is consumed. A half-sent
    party that lost its staging state is worse than one that never left.
]]
function LobbyService._teleportParty(self: LobbyService, boarding: { Player }): boolean
    if not self._featureFlags:isEnabled("reserved_run_servers_enabled") then
        return false
    end
    local placeId = game.PlaceId
    if placeId == 0 then
        -- Studio and unpublished builds cannot reserve a server. Fall back to
        -- moving the party in place so the lodge still works while testing.
        self._logger:info("run_teleport_skipped", { reason = "unpublished_place" })
        return false
    end

    --[[
        The party is formed before the server is reserved, because its ID has
        to ride the payload, and the tickets are written after the code comes
        back but before anybody is sent. That order is load-bearing in both
        directions: a ticket written after the teleport is written to a
        profile nobody is holding any more.
    ]]
    local partyId: string? = nil
    if self._partyService ~= nil then
        partyId = self._partyService:formDeparture(boarding)
    end

    local payload, built =
        self._runHandoff.buildPayload(#boarding, workspace:GetServerTimeNow(), partyId)
    if payload == nil then
        self._logger:warn("run_teleport_payload_invalid", { reason = built.reason })
        return false
    end

    local reserved, accessCode = pcall(function()
        return TeleportService:ReserveServer(placeId)
    end)
    if not reserved or type(accessCode) ~= "string" then
        self:_recoverFromTeleportFailure(boarding, "reserve_failed")
        return true
    end

    if partyId ~= nil and self._partyService ~= nil then
        self._partyService:issueTickets(partyId, boarding, accessCode)
    end

    local options = Instance.new("TeleportOptions")
    options.ReservedServerAccessCode = accessCode
    options:SetTeleportData(payload)

    local sent = pcall(function()
        TeleportService:TeleportAsync(placeId, boarding, options)
    end)
    if not sent then
        self:_recoverFromTeleportFailure(boarding, "teleport_failed")
        return true
    end

    self._logger:info("run_teleport_started", { boarded = #boarding })
    self._analyticsService:lobbyDeparture(nil, "teleport", true, nil, #boarding)
    return true
end

function LobbyService._recoverFromTeleportFailure(
    self: LobbyService,
    boarding: { Player },
    reason: string
)
    local recovery = self._runHandoff.failureRecovery(reason)
    for _, player in boarding do
        self._departed[player] = nil
    end
    if recovery.cancelDeparture then
        self._state = self._lobbyDeparture.cancel(self._state)
    end
    self._logger:warn("run_teleport_failed", { reason = recovery.reason, party = #boarding })
    self._analyticsService:lobbyDeparture(nil, "teleport", false, recovery.reason, #boarding)
    self:_notify(recovery.message)
end

function LobbyService._launch(self: LobbyService, boarding: { Player })
    -- Each party gets its own world when reserved servers are on. Only when
    -- that is unavailable -- Studio, an unpublished place, or the flag off --
    -- does the party move within this server instead.
    if self:_teleportParty(boarding) then
        for _, player in boarding do
            self._departed[player] = true
        end
        return
    end

    local destination = self._worldService:arrivalSpawnPosition()
    for index, player in boarding do
        local character = player.Character
        if character ~= nil then
            local angle = (index - 1) / math.max(1, #boarding) * math.pi * 2
            local offset = Vector3.new(math.cos(angle) * 4, 0, math.sin(angle) * 4)
            character:PivotTo(CFrame.new(destination + offset))
        end
        self._departed[player] = true
    end
    self._logger:info("lobby_departure_launched", { boarded = #boarding })
    self._analyticsService:lobbyDeparture(nil, "launch", true, nil, #boarding)
    --[[
        The road is pointed at a region by the destination board, and the
        departure toast used to say EMBERHOLLOW no matter which plank was
        pressed -- the one line that confirms where a party just went,
        naming the town it just left. It reads the region the world
        actually raised, which is the same fact the arrival sign is built
        from.
    ]]
    self:_notify(
        string.format(
            Strings.get("toast.the_party_of_n_has_left"),
            #boarding,
            RegionExpeditionAssembly.displayName(
                self._worldService:expeditionRegionId() or RegionAccess.DefaultRegionId
            )
        )
    )
end

function LobbyService.Start(self: LobbyService)
    Players.PlayerRemoving:Connect(function(player: Player)
        self._departed[player] = nil
    end)
    for _, player in Players:GetPlayers() do
        self:_adoptArrival(player)
    end
    Players.PlayerAdded:Connect(function(player: Player)
        self:_adoptArrival(player)
        player.CharacterAdded:Connect(function(character: Model)
            -- A player who already left keeps playing the game after a death
            -- instead of being returned to the staging yard.
            if not self._departed[player] then
                return
            end
            task.defer(function()
                if character.Parent ~= nil then
                    character:PivotTo(CFrame.new(self._worldService:arrivalSpawnPosition()))
                end
            end)
        end)
    end)

    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.25 then
            return
        end
        accumulator = 0
        if not self._featureFlags:isEnabled("lobby_departure_enabled") then
            return
        end

        local ready = self:readyPlayers(self)
        local now = workspace:GetServerTimeNow()
        local nextState, result = self._lobbyDeparture.tick(self._state, now, #ready)
        self._state = nextState

        if result.launch then
            --[[
                Seats used to be spent in whatever order the engine listed
                players, so a bystander standing on the dais could take one
                from somebody's party. A party is asked first now; without
                one this is the same list it always was.
            ]]
            local capacity = math.min(result.capacity, #ready)
            local boarding = {}
            if self._partyService ~= nil then
                boarding = self._partyService:boardingOrder(ready, capacity)
            else
                for index = 1, capacity do
                    table.insert(boarding, ready[index])
                end
            end
            self:_launch(boarding)
            self._lastPublishedSeconds = -1
            return
        end

        if result.reason == "platform_emptied" then
            self:_notify(Strings.get("toast.departure_cancelled_the_platform_is_empty"))
            self._lastPublishedSeconds = -1
            return
        end

        -- Publish once per whole second so the countdown rail ticks without
        -- pushing a snapshot every frame.
        local view = self._lobbyDeparture.snapshot(nextState, now)
        if view.counting and view.secondsRemaining ~= self._lastPublishedSeconds then
            self._lastPublishedSeconds = view.secondsRemaining
            self:_notify(nil)
        end
    end)
end

return LobbyService
