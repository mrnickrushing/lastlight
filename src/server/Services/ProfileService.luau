--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ProfileService = {}
ProfileService.__index = ProfileService
ProfileService.Name = "ProfileService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type ProfileService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _persistent: boolean,
        _profiles: { [Player]: any },
        _writable: { [Player]: boolean },
        _dirty: { [Player]: boolean },
        _saving: { [Player]: boolean },
        _loading: { [Player]: boolean },
        _loadedEvent: BindableEvent,
        _saveSchema: any,
        _store: GlobalDataStore?,
    },
    ProfileService
))

function ProfileService.new(logger: Logger, persistent: boolean): ProfileService
    return setmetatable({
        Name = ProfileService.Name,
        _logger = logger,
        _persistent = persistent,
        _profiles = {},
        _writable = {},
        _dirty = {},
        _saving = {},
        _loading = {},
        _loadedEvent = Instance.new("BindableEvent"),
        _saveSchema = nil,
        _store = nil,
    }, ProfileService)
end

function ProfileService.Init(self: ProfileService, context: any)
    self._saveSchema = context.saveSchema
    if self._persistent then
        self._store = DataStoreService:GetDataStore("LastLightProfile_v1")
    end
end

function ProfileService._load(self: ProfileService, player: Player)
    if self._loading[player] or self._profiles[player] ~= nil then
        return
    end
    self._loading[player] = true

    local now = os.time()
    local profile = self._saveSchema.default(now)
    local source = "fallback"
    local writable = not self._persistent

    if self._persistent and self._store ~= nil then
        local finished = false
        local ok = false
        local result: any = nil

        task.spawn(function()
            ok, result = pcall(function()
                return (self._store :: GlobalDataStore):GetAsync(
                    string.format("player_%d", player.UserId)
                )
            end)
            finished = true
        end)

        local deadline = os.clock() + 6
        while not finished and os.clock() < deadline and player.Parent ~= nil do
            task.wait(0.1)
        end

        if finished and ok then
            profile = self._saveSchema.normalize(result, now)
            source = result == nil and "new" or "datastore"
            writable = true
        elseif finished then
            source = "read_only"
            self._logger:warn("profile_load_failed", {
                player = player.UserId,
                reason = tostring(result),
            })
        else
            source = "read_only"
            self._logger:warn("profile_load_timed_out", { player = player.UserId })
        end
    else
        source = "session"
    end

    if player.Parent == nil then
        self._loading[player] = nil
        return
    end

    self._profiles[player] = profile
    self._writable[player] = writable
    self._loading[player] = nil
    self._loadedEvent:Fire(player, profile)
    self._logger:info("profile_loaded", {
        player = player.UserId,
        source = source,
        stage = profile.tutorial.stage,
    })
end

function ProfileService.Start(self: ProfileService)
    Players.PlayerAdded:Connect(function(player: Player)
        task.spawn(function()
            self:_load(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        self:save(player)
        self._profiles[player] = nil
        self._writable[player] = nil
        self._dirty[player] = nil
        self._saving[player] = nil
        self._loading[player] = nil
    end)

    for _, player in Players:GetPlayers() do
        task.spawn(function()
            self:_load(player)
        end)
    end

    if self._persistent then
        task.spawn(function()
            while true do
                task.wait(10)
                for player in self._dirty do
                    if player.Parent ~= nil then
                        task.spawn(function()
                            self:save(player)
                        end)
                    end
                end
            end
        end)
    end

    game:BindToClose(function()
        local remaining = 0
        for player in self._profiles do
            remaining += 1
            task.spawn(function()
                self:save(player)
                remaining -= 1
            end)
        end

        local deadline = os.clock() + 7
        while remaining > 0 and os.clock() < deadline do
            task.wait(0.1)
        end
    end)
end

function ProfileService.onLoaded(
    self: ProfileService,
    callback: (Player, any) -> ()
): RBXScriptConnection
    return self._loadedEvent.Event:Connect(callback)
end

function ProfileService.get(self: ProfileService, player: Player): any
    return self._profiles[player]
end

function ProfileService.isLoaded(self: ProfileService, player: Player): boolean
    return self._profiles[player] ~= nil
end

function ProfileService.isWritable(self: ProfileService, player: Player): boolean
    return self._profiles[player] ~= nil
        and (not self._persistent or self._writable[player] == true)
end

function ProfileService.setTutorial(
    self: ProfileService,
    player: Player,
    stage: string,
    selectedTool: string?
): boolean
    local profile = self._profiles[player]
    if profile == nil then
        return false
    end

    self._profiles[player] = self._saveSchema.withTutorial(profile, stage, selectedTool, os.time())
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    return true
end

function ProfileService.save(self: ProfileService, player: Player): boolean
    local profile = self._profiles[player]
    if profile == nil then
        return false
    end
    if not self._persistent then
        return true
    end
    if self._store == nil or self._writable[player] ~= true then
        self._logger:warn("profile_save_skipped_read_only", {
            player = player.UserId,
        })
        return false
    end
    if self._saving[player] then
        return false
    end
    self._saving[player] = true

    local retainedNewer = false
    local newerProfile: any = nil
    local ok, message = pcall(function()
        (self._store :: GlobalDataStore):UpdateAsync(
            string.format("player_%d", player.UserId),
            function(current: any)
                if current ~= nil then
                    local normalized = self._saveSchema.normalize(current, os.time())
                    if normalized.revision > profile.revision then
                        retainedNewer = true
                        newerProfile = normalized
                        return current
                    end
                end
                return profile
            end
        )
    end)
    self._saving[player] = nil

    if not ok then
        self._logger:warn("profile_save_failed", {
            player = player.UserId,
            reason = tostring(message),
        })
        return false
    end

    if retainedNewer and newerProfile ~= nil then
        local activeProfile = self._profiles[player]
        if activeProfile ~= nil and activeProfile.revision <= newerProfile.revision then
            self._profiles[player] = newerProfile
            self._dirty[player] = nil
        end
        self._logger:warn("profile_save_retained_newer_revision", {
            player = player.UserId,
            attemptedRevision = profile.revision,
            storedRevision = newerProfile.revision,
        })
        return true
    end

    local activeProfile = self._profiles[player]
    if activeProfile ~= nil and activeProfile.revision == profile.revision then
        self._dirty[player] = nil
    end
    self._logger:info("profile_saved", {
        player = player.UserId,
        revision = profile.revision,
        stage = profile.tutorial.stage,
    })
    return true
end

return table.freeze(ProfileService)
