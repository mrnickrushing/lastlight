--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkService = {}
NetworkService.__index = NetworkService
NetworkService.Name = "NetworkService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type NetworkService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _folder: Folder?,
        _actionPayloadContract: any,
        _actionRequest: RemoteEvent?,
        _stateChanged: RemoteEvent?,
        _getState: RemoteFunction?,
        _performanceReport: RemoteEvent?,
        _actionHandler: ((Player, any) -> ())?,
        _actionObserver: ((Player) -> ())?,
        _performanceHandler: ((Player, any) -> ())?,
        _snapshotProvider: ((Player) -> any)?,
        _snapshotCache: { [Player]: { at: number, value: any } },
        _lastActionAt: { [Player]: number },
        _lastStateAt: { [Player]: number },
    },
    NetworkService
))

function NetworkService.new(logger: Logger): NetworkService
    return setmetatable({
        Name = NetworkService.Name,
        _logger = logger,
        _folder = nil,
        _actionPayloadContract = nil,
        _actionRequest = nil,
        _stateChanged = nil,
        _getState = nil,
        _performanceReport = nil,
        _actionHandler = nil,
        _actionObserver = nil,
        _performanceHandler = nil,
        _snapshotProvider = nil,
        _snapshotCache = {},
        _lastActionAt = {},
        _lastStateAt = {},
    }, NetworkService)
end

local function makeRemote(className: string, name: string, parent: Instance): Instance
    local remote = Instance.new(className)
    remote.Name = name
    remote.Parent = parent
    return remote
end

function NetworkService.Init(self: NetworkService, context: any)
    local runtimeIds = context.runtimeIds
    self._actionPayloadContract =
        assert(context.actionPayloadContract, "action payload contract unavailable")
    local existing = ReplicatedStorage:FindFirstChild(runtimeIds.FolderName)
    if existing ~= nil then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = runtimeIds.FolderName
    folder:SetAttribute("SchemaVersion", 1)
    folder:SetAttribute("WorldReady", false)
    folder.Parent = ReplicatedStorage

    self._folder = folder
    self._actionRequest =
        makeRemote("RemoteEvent", runtimeIds.Remotes.ActionRequest, folder) :: RemoteEvent
    self._stateChanged =
        makeRemote("RemoteEvent", runtimeIds.Remotes.StateChanged, folder) :: RemoteEvent
    self._getState =
        makeRemote("RemoteFunction", runtimeIds.Remotes.GetState, folder) :: RemoteFunction
    self._performanceReport =
        makeRemote("RemoteEvent", runtimeIds.Remotes.PerformanceReport, folder) :: RemoteEvent
end

function NetworkService.Start(self: NetworkService)
    local actionRequest = assert(self._actionRequest, "action remote unavailable")
    local getState = assert(self._getState, "state function unavailable")
    local contract = assert(self._actionPayloadContract, "action payload contract unavailable")
    local performanceReport = assert(self._performanceReport, "performance remote unavailable")

    -- Telemetry, kept off the action path on purpose. The handler bounds and
    -- rate limits the payload itself; nothing here can grant a player
    -- anything, so the worst a lying client achieves is a wrong row in its own
    -- performance report.
    performanceReport.OnServerEvent:Connect(function(player: Player, payload: any)
        local handler = self._performanceHandler
        if handler ~= nil then
            handler(player, payload)
        end
    end)

    actionRequest.OnServerEvent:Connect(function(player: Player, payload: any)
        if not contract.isValidTransport(payload) then
            return
        end
        local now = os.clock()
        local lastActionAt = self._lastActionAt[player]
        if lastActionAt ~= nil and os.clock() - lastActionAt < 0.05 then
            return
        end
        self._lastActionAt[player] = now
        local observer = self._actionObserver
        if observer ~= nil then
            observer(player)
        end
        local handler = self._actionHandler
        if handler ~= nil then
            handler(player, payload)
        end
    end)

    getState.OnServerInvoke = function(player: Player)
        if typeof(player) ~= "Instance" or not player:IsA("Player") then
            return nil
        end
        local lastStateAt = self._lastStateAt[player]
        if lastStateAt ~= nil and os.clock() - lastStateAt < 0.1 then
            return nil
        end
        self._lastStateAt[player] = os.clock()
        local provider = self._snapshotProvider
        if provider == nil then
            return nil
        end
        local now = os.clock()
        local cached = self._snapshotCache[player]
        if cached ~= nil and now - cached.at < 0.2 then
            return cached.value
        end

        local snapshot = provider(player)
        self._snapshotCache[player] = {
            at = now,
            value = snapshot,
        }
        return snapshot
    end
    Players.PlayerRemoving:Connect(function(player: Player)
        self._snapshotCache[player] = nil
        self._lastActionAt[player] = nil
        self._lastStateAt[player] = nil
    end)

    self._logger:info("network_started", { schemaVersion = 1 })
end

function NetworkService.setActionHandler(self: NetworkService, handler: (Player, any) -> ())
    self._actionHandler = handler
end

-- Counts accepted actions for the remote-traffic budget. Set after the fact
-- because the observer belongs to a service built later, and kept separate
-- from the handler so measuring can never change what a payload does.
function NetworkService.setActionObserver(self: NetworkService, observer: (Player) -> ())
    self._actionObserver = observer
end

function NetworkService.setPerformanceHandler(self: NetworkService, handler: (Player, any) -> ())
    self._performanceHandler = handler
end

function NetworkService.setSnapshotProvider(self: NetworkService, provider: (Player) -> any)
    self._snapshotProvider = provider
end

function NetworkService.send(self: NetworkService, player: Player, snapshot: any)
    local stateChanged = self._stateChanged
    if stateChanged ~= nil and player.Parent ~= nil then
        self._snapshotCache[player] = {
            at = os.clock(),
            value = snapshot,
        }
        stateChanged:FireClient(player, snapshot)
    end
end

function NetworkService.broadcast(self: NetworkService, snapshotProvider: (Player) -> any)
    for _, player in Players:GetPlayers() do
        self:send(player, snapshotProvider(player))
    end
end

function NetworkService.setWorldReady(self: NetworkService, ready: boolean)
    local folder = self._folder
    if folder ~= nil then
        folder:SetAttribute("WorldReady", ready)
    end
end

function NetworkService.isWorldReady(self: NetworkService): boolean
    local folder = self._folder
    return folder ~= nil and folder:GetAttribute("WorldReady") == true
end

function NetworkService.folder(self: NetworkService): Folder
    return assert(self._folder, "network service has not initialized")
end

return table.freeze(NetworkService)
