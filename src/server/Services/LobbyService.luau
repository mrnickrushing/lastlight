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
local RunService = game:GetService("RunService")

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
        _featureFlags: any,
        _worldService: any,
        _analyticsService: any,
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
    featureFlags: any,
    worldService: any,
    analyticsService: any
): LobbyService
    return setmetatable({
        Name = LobbyService.Name,
        _logger = logger,
        _config = config,
        _lobbyDeparture = lobbyDeparture,
        _featureFlags = featureFlags,
        _worldService = worldService,
        _analyticsService = analyticsService,
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
                local flat = Vector3.new(offset.X, 0, offset.Z)
                if
                    flat.Magnitude <= radius
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
            string.format("DEPARTING IN %d — STAND ON THE PLATFORM", result.secondsRemaining)
        )
    elseif result.reason == "platform_empty" then
        self:_notify("STAND ON THE PLATFORM TO DEPART")
    elseif result.reason == "already_counting" then
        self:_notify("A DEPARTURE IS ALREADY UNDER WAY")
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
function LobbyService._launch(self: LobbyService, boarding: { Player })
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
    self:_notify(string.format("THE PARTY OF %d HAS LEFT FOR EMBERHOLLOW", #boarding))
end

function LobbyService.Start(self: LobbyService)
    Players.PlayerRemoving:Connect(function(player: Player)
        self._departed[player] = nil
    end)
    Players.PlayerAdded:Connect(function(player: Player)
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
            local boarding = {}
            for index = 1, math.min(result.capacity, #ready) do
                table.insert(boarding, ready[index])
            end
            self:_launch(boarding)
            self._lastPublishedSeconds = -1
            return
        end

        if result.reason == "platform_emptied" then
            self:_notify("DEPARTURE CANCELLED — THE PLATFORM IS EMPTY")
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
