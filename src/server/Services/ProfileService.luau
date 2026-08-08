--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
        _lockHeartbeat: { [Player]: number },
        _loadedEvent: BindableEvent,
        _equipmentChangedEvent: BindableEvent,
        _saveSchema: any,
        _profilePersistence: any,
        _profileBackup: any,
        _adminInspectionReport: any,
        _config: any,
        _jobId: string,
        _store: GlobalDataStore?,
        _backupStore: GlobalDataStore?,
        _lastBackupAt: { [number]: number },
    },
    ProfileService
))

-- The materials the launch region actually uses. Kept explicit rather than
-- derived so a future region's currency cannot be granted by an old hook.
local LAUNCH_MATERIAL_IDS = table.freeze({
    "material_heartwood",
    "material_meadow_fiber",
    "material_amber_sap",
    "material_brightcap",
    "material_spring_clay",
})

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
        _lockHeartbeat = {},
        _loadedEvent = Instance.new("BindableEvent"),
        _equipmentChangedEvent = Instance.new("BindableEvent"),
        _saveSchema = nil,
        _profilePersistence = nil,
        _profileBackup = nil,
        _adminInspectionReport = nil,
        _config = nil,
        _jobId = "",
        _store = nil,
        _backupStore = nil,
        _lastBackupAt = {},
    }, ProfileService)
end

function ProfileService.Init(self: ProfileService, context: any)
    self._saveSchema = context.saveSchema
    self._profilePersistence =
        assert(context.profilePersistence, "profile persistence rules unavailable")
    self._profileBackup = assert(context.profileBackup, "profile backup rules unavailable")
    self._adminInspectionReport =
        assert(context.adminInspectionReport, "admin inspection report unavailable")
    self._config = assert(context.config, "config unavailable")
    -- Studio has no JobId. A stable stand-in keeps the lock logic identical
    -- there instead of leaving every Studio session sharing an empty ID.
    self._jobId = if game.JobId ~= nil and game.JobId ~= ""
        then game.JobId
        else "studio-" .. tostring(os.time())
    if self._persistent then
        self._store = DataStoreService:GetDataStore("LastLightProfile_v1")
        -- A separate store rather than another field on the profile: a backup
        -- must survive whatever went wrong with the profile, and a ring of
        -- snapshots living inside the value it is meant to protect would be
        -- lost to the same bad write.
        self._backupStore = DataStoreService:GetDataStore("LastLightProfileBackup_v1")
    end
end

--[[
    Copy a save aside, if this one is worth copying.

    Deliberately never raises: a backup is a best-effort safety net, and a
    DataStore hiccup on this path must not take down the load or save that
    triggered it. A failure is logged and the caller carries on -- the
    alternative, refusing to save because the backup failed, would turn a
    redundancy feature into a new way to lose progress.
]]
function ProfileService._captureBackup(
    self: ProfileService,
    userId: number,
    profile: any,
    storedSchemaVersion: any,
    forcedReason: string?
): string?
    if not self._persistent or self._backupStore == nil or profile == nil then
        return nil
    end

    local now = os.time()
    local key = string.format("player_%d", userId)
    local capturedReason: string? = nil

    local ok, message = pcall(function()
        (self._backupStore :: GlobalDataStore):UpdateAsync(key, function(current: any)
            local decision = if forcedReason ~= nil
                then { capture = true, reason = forcedReason }
                else self._profileBackup.shouldCapture(
                    current,
                    storedSchemaVersion,
                    self._config.SaveSchemaVersion,
                    now,
                    self._config.ProfileBackupIntervalSeconds
                )
            if not decision.capture then
                return nil
            end
            capturedReason = decision.reason
            return self._profileBackup.capture(
                current,
                profile,
                now,
                decision.reason,
                self._config.ProfileBackupRetained
            )
        end)
    end)

    if not ok then
        self._logger:warn("profile_backup_failed", {
            player = userId,
            reason = tostring(message),
        })
        return nil
    end

    if capturedReason ~= nil then
        self._lastBackupAt[userId] = now
        self._logger:info("profile_backup_captured", {
            player = userId,
            reason = capturedReason,
            revision = profile.revision,
            schemaVersion = profile.schemaVersion,
        })
    end
    return capturedReason
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

        local outcome = self._profilePersistence.loadOutcome(finished, ok, result)
        source = outcome.source
        writable = outcome.writable
        if outcome.useStored or outcome.source == "new" then
            -- Photograph the stored bytes *before* normalize folds them into
            -- the current shape. This is the moment TECHNICAL_ARCHITECTURE asks
            -- for a backup: a migration here is not a numbered pipeline that
            -- can be replayed backwards, it is a fold into the current default,
            -- so anything it drops is gone with nothing left to compare against.
            -- Spawned rather than awaited -- a player must never wait on the
            -- join path for a redundancy write.
            if outcome.useStored and type(result) == "table" then
                local storedValue = result
                local storedSchemaVersion = storedValue.schemaVersion
                task.spawn(function()
                    self:_captureBackup(player.UserId, storedValue, storedSchemaVersion, nil)
                end)
            end
            profile = self._saveSchema.normalize(if outcome.useStored then result else nil, now)
        elseif finished then
            self._logger:warn("profile_load_failed", {
                player = player.UserId,
                reason = tostring(result),
            })
        else
            self._logger:warn("profile_load_timed_out", { player = player.UserId })
        end

        -- A profile another live server still holds is played read-only rather
        -- than refused: the player gets a session, and nothing they do in it
        -- can overwrite the copy the other server is still writing.
        if writable then
            local lockDecision = self._profilePersistence.acquireLock(
                if type(result) == "table" then result.sessionLock else nil,
                self._jobId,
                now,
                self._config.ProfileLockStaleAfterSeconds
            )
            if not lockDecision.acquired then
                writable = false
                source = "locked_read_only"
                self._logger:warn("profile_locked_by_another_server", {
                    player = player.UserId,
                    reason = lockDecision.reason,
                })
            elseif lockDecision.reason ~= "unlocked" then
                self._logger:info("profile_lock_acquired", {
                    player = player.UserId,
                    reason = lockDecision.reason,
                })
            end
        end
    else
        source = "session"
    end

    if player.Parent == nil then
        self._loading[player] = nil
        return
    end

    profile = self:_applyStudioStock(profile, now)
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

--[[
    A stocked profile for live verification, and nothing else.

    Several systems can only be judged by playing them -- arming a snare
    costs materials, whetting a blade needs one that has dulled -- and
    reaching that state honestly means a full playthrough every time
    somebody wants to look at a two-second interaction. A live session on
    2026-08-06 spent itself discovering exactly that, and closed with the
    checks still open.

    So: set `LastLightStockProfile` on the DataModel to a number and a
    joining profile arrives with that many of each launch material. Three
    guards, all of which must hold:

      * Studio only. RunService:IsStudio() is false on every Roblox server.
      * Non-persistent environments only. Production runs with persistence
        on; this is refused there even if someone sets the attribute.
      * Logged loudly, every time, with the amount.

    It grants materials, which are earned in play and spent in play. It
    cannot grant progress, chapters, professions or gear, because those
    are the things a verification run is supposed to actually perform.

    The attribute is read at join and again whenever it changes, because a
    Play session starts from a fresh DataModel: a value set while editing
    does not survive into the run, and a driver who has already pressed
    play should not have to restart to stock a purse.
]]
function ProfileService._applyStudioStock(self: ProfileService, profile: any, now: number): any
    if self._persistent or not RunService:IsStudio() then
        return profile
    end
    local requested = tonumber(game:GetAttribute("LastLightStockProfile"))
    if requested == nil then
        return profile
    end
    local amount = math.clamp(math.floor(requested), 1, 200)
    local nextProfile = table.clone(profile)
    nextProfile.inventory = table.clone(profile.inventory)
    local materials = table.clone(profile.inventory.materials)
    for _, materialId in LAUNCH_MATERIAL_IDS do
        materials[materialId] = (tonumber(materials[materialId]) or 0) + amount
    end
    nextProfile.inventory.materials = materials
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    self._logger:warn("studio_profile_stocked", {
        amount = amount,
        materials = #LAUNCH_MATERIAL_IDS,
    })
    return nextProfile
end

function ProfileService._watchStudioStock(self: ProfileService)
    if self._persistent or not RunService:IsStudio() then
        return
    end
    game:GetAttributeChangedSignal("LastLightStockProfile"):Connect(function()
        for player, profile in self._profiles do
            local stocked = self:_applyStudioStock(profile, os.time())
            if stocked ~= profile then
                self._profiles[player] = stocked
                self._loadedEvent:Fire(player, stocked)
            end
        end
    end)
end

function ProfileService.Start(self: ProfileService)
    self:_watchStudioStock()
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
        self._lockHeartbeat[player] = nil
    end)

    for _, player in Players:GetPlayers() do
        task.spawn(function()
            self:_load(player)
        end)
    end

    if self._persistent then
        task.spawn(function()
            while true do
                task.wait(self._config.ProfileLockHeartbeatSeconds)
                for player in self._dirty do
                    if player.Parent ~= nil then
                        task.spawn(function()
                            self:save(player)
                        end)
                    end
                end

                -- A player who is simply standing still writes nothing, and a
                -- lock only refreshes on write. Without this pass their own
                -- lock goes stale underneath them and another server becomes
                -- free to reclaim a profile that is still being played.
                local now = os.time()
                for player in self._profiles do
                    if
                        player.Parent ~= nil
                        and self._writable[player] == true
                        and self._dirty[player] == nil
                        and self._profilePersistence.shouldRefreshLock(
                            self._lockHeartbeat[player],
                            now,
                            self._config.ProfileLockHeartbeatSeconds
                        )
                    then
                        local target = player
                        task.spawn(function()
                            self:save(target)
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

function ProfileService.onEquipmentChanged(
    self: ProfileService,
    callback: (Player, any) -> ()
): RBXScriptConnection
    return self._equipmentChangedEvent.Event:Connect(callback)
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

    local previousTool = profile.tutorial.selectedTool
    self._profiles[player] = self._saveSchema.withTutorial(profile, stage, selectedTool, os.time())
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    if selectedTool ~= previousTool then
        -- The held-tool visual rides the equipment-changed signal: choosing a
        -- starter tool should put it in the hand at the pedestal, not on the
        -- next respawn, and the gear visual service already listens here.
        self._equipmentChangedEvent:Fire(
            player,
            self._saveSchema.equippedSnapshot(self._profiles[player])
        )
    end
    return true
end

function ProfileService.gearTraitOf(self: ProfileService, player: Player, itemId: any): any
    local profile = self._profiles[player]
    if profile == nil then
        return nil
    end
    local traits = (profile :: any).gearTraits
    return if type(traits) == "table" and type(itemId) == "string" then traits[itemId] else nil
end

function ProfileService.accrueGearWear(
    self: ProfileService,
    player: Player,
    itemId: any,
    pointsOverride: number?
): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { applied = false }
    end
    local nextProfile, result = self._saveSchema.withGearWear(profile, itemId, pointsOverride or 2)
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent and self._writable[player] == true then
            self._dirty[player] = true
        end
    end
    return result
end

function ProfileService.repairGear(self: ProfileService, player: Player, itemId: any): any
    local profile = self._profiles[player]
    if profile == nil then
        return { applied = false, reason = "profile_loading" }
    end
    if not self:isWritable(player) then
        return { applied = false, reason = "profile_read_only" }
    end
    local nextProfile, result = self._saveSchema.withRepairedGear(profile, itemId, os.time())
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent and self._writable[player] == true then
            self._dirty[player] = true
        end
    end
    return result
end

function ProfileService.spendMaterials(self: ProfileService, player: Player, cost: any): any
    local profile = self._profiles[player]
    if profile == nil then
        return { applied = false, reason = "profile_loading" }
    end
    if not self:isWritable(player) then
        return { applied = false, reason = "profile_read_only" }
    end
    local nextProfile, result = self._saveSchema.withSpentMaterials(profile, cost, os.time())
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent and self._writable[player] == true then
            self._dirty[player] = true
        end
    end
    return result
end

--[[
    Field repair: the most-worn item, no material cost. Used by a carried
    item rather than a bench, so it works where a bench cannot.
]]
function ProfileService.fieldRepairGear(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return { applied = false, reason = "profile_loading" }
    end
    if not self:isWritable(player) then
        return { applied = false, reason = "profile_read_only" }
    end
    local nextProfile, result = self._saveSchema.withFieldRepair(profile, os.time())
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent and self._writable[player] == true then
            self._dirty[player] = true
        end
    end
    return result
end

function ProfileService.hasWornGear(self: ProfileService, player: Player): boolean
    local wear = self:gearWearOf(player)
    for _, points in wear do
        if (tonumber(points) or 0) > 0 then
            return true
        end
    end
    return false
end

function ProfileService.gearWearOf(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    return if profile ~= nil then (profile :: any).gearWear or {} else {}
end

function ProfileService.saveLoadout(self: ProfileService, player: Player, slot: number): any
    local profile = self._profiles[player]
    if profile == nil then
        return { applied = false, reason = "profile_loading" }
    end
    if not self:isWritable(player) then
        return { applied = false, reason = "profile_read_only" }
    end
    local nextProfile, result = self._saveSchema.withLoadout(profile, slot, os.time())
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent and self._writable[player] == true then
            self._dirty[player] = true
        end
    end
    return result
end

function ProfileService.loadoutAt(self: ProfileService, player: Player, slot: any): any
    local profile = self._profiles[player]
    if profile == nil then
        return nil
    end
    return self._saveSchema.loadoutAt(profile, slot)
end

function ProfileService.setProfession(
    self: ProfileService,
    player: Player,
    professionId: string
): boolean
    local profile = self._profiles[player]
    if profile == nil then
        return false
    end

    self._profiles[player] = self._saveSchema.withProfession(profile, professionId, os.time())
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    return true
end

function ProfileService.awardMastery(
    self: ProfileService,
    player: Player,
    professionId: string,
    amount: number
): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { applied = false, reason = "profile_unavailable" }
    end
    local nextProfile, result =
        self._saveSchema.withMasteryAward(profile, professionId, amount, os.time())
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent then
            self._dirty[player] = true
        end
    end
    return result
end

function ProfileService.masterySnapshot(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return {}
    end
    return self._saveSchema.masterySnapshot(profile)
end

function ProfileService.selectProfessionSpecialization(
    self: ProfileService,
    player: Player,
    professionId: string,
    specializationId: string
): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { applied = false, reason = "profile_unavailable" }
    end
    local nextProfile, result = self._saveSchema.withProfessionSpecialization(
        profile,
        professionId,
        specializationId,
        os.time()
    )
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent then
            self._dirty[player] = true
        end
    end
    return result
end

function ProfileService.setNightNumber(
    self: ProfileService,
    player: Player,
    nightNumber: number
): boolean
    local profile = self._profiles[player]
    if profile == nil then
        return false
    end

    self._profiles[player] = self._saveSchema.withNightNumber(profile, nightNumber, os.time())
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    return true
end

function ProfileService.setTownCondition(
    self: ProfileService,
    player: Player,
    condition: any
): boolean
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return false
    end
    local nextProfile = self._saveSchema.withTownCondition(profile, condition, os.time())
    if nextProfile == profile then
        return true
    end
    self._profiles[player] = nextProfile
    if self._persistent then
        self._dirty[player] = true
    end
    return true
end

function ProfileService.townCondition(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return { integrity = 100, damageLevel = 0, repairsRemaining = 0 }
    end
    return self._saveSchema.townCondition(profile)
end

function ProfileService.nightNumber(self: ProfileService, player: Player): number
    local profile = self._profiles[player]
    if profile == nil then
        return 1
    end
    return self._saveSchema.nightNumber(profile)
end

function ProfileService.craftItem(self: ProfileService, player: Player, recipeId: string): any
    local profile = self._profiles[player]
    if profile == nil then
        return {
            accepted = false,
            reason = "profile_loading",
        }
    end
    if not self:isWritable(player) then
        return {
            accepted = false,
            reason = "profile_read_only",
        }
    end

    local nextProfile, result = self._saveSchema.withCraftedItem(profile, recipeId, os.time())
    if not result.applied then
        return {
            accepted = false,
            reason = result.reason,
        }
    end

    self._profiles[player] = nextProfile
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    return {
        accepted = true,
        itemId = result.itemId,
    }
end

function ProfileService.collectMemoryFragment(
    self: ProfileService,
    player: Player,
    fragmentId: string
): any
    local profile = self._profiles[player]
    if profile == nil then
        return { accepted = false, reason = "profile_loading" }
    end
    if not self:isWritable(player) then
        return { accepted = false, reason = "profile_read_only" }
    end

    local nextProfile, result = self._saveSchema.withMemoryFragment(profile, fragmentId, os.time())
    if not result.accepted then
        return { accepted = false, reason = result.reason, fragment = result.fragment }
    end

    self._profiles[player] = nextProfile
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    return { accepted = true, fragment = result.fragment }
end

function ProfileService.memoryFragments(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return nil
    end
    return self._saveSchema.memoryFragmentSnapshot(profile)
end

function ProfileService.useGearItem(self: ProfileService, player: Player, itemId: string): any
    local profile = self._profiles[player]
    if profile == nil then
        return {
            accepted = false,
            reason = "profile_loading",
        }
    end
    if not self:isWritable(player) then
        return {
            accepted = false,
            reason = "profile_read_only",
        }
    end

    local nextProfile, result = self._saveSchema.withUsedGearItem(profile, itemId, os.time())
    if not result.applied then
        return {
            accepted = false,
            reason = result.reason,
        }
    end

    self._profiles[player] = nextProfile
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    return {
        accepted = true,
        itemId = result.itemId,
    }
end

function ProfileService.equipItem(self: ProfileService, player: Player, itemId: string): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { accepted = false, reason = "profile_unavailable" }
    end
    local nextProfile, result = self._saveSchema.withEquippedItem(profile, itemId, os.time())
    if not result.applied then
        return { accepted = false, reason = result.reason }
    end
    self._profiles[player] = nextProfile
    if self._persistent then
        self._dirty[player] = true
    end
    self._equipmentChangedEvent:Fire(player, self._saveSchema.equippedSnapshot(nextProfile))
    return { accepted = true, itemId = result.itemId, slot = result.slot }
end

function ProfileService.unequipItem(self: ProfileService, player: Player, slot: string): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { accepted = false, reason = "profile_unavailable" }
    end
    local nextProfile, result = self._saveSchema.withUnequippedItem(profile, slot, os.time())
    if not result.applied then
        return { accepted = false, reason = result.reason }
    end
    self._profiles[player] = nextProfile
    if self._persistent then
        self._dirty[player] = true
    end
    self._equipmentChangedEvent:Fire(player, self._saveSchema.equippedSnapshot(nextProfile))
    return { accepted = true, slot = slot }
end

function ProfileService.equippedSnapshot(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return {}
    end
    return self._saveSchema.equippedSnapshot(profile)
end

function ProfileService.selectedTool(self: ProfileService, player: Player): string?
    local profile = self._profiles[player]
    if profile == nil then
        return nil
    end
    return profile.tutorial.selectedTool
end

function ProfileService.weaponStrikeProfile(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return nil
    end
    return self._saveSchema.weaponStrikeProfile(profile)
end

function ProfileService.equipmentStats(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return { damageReduction = 0, staminaRegenMultiplier = 1 }
    end
    return self._saveSchema.equipmentStats(profile)
end

function ProfileService.applyResidentNight(self: ProfileService, player: Player, context: any): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return nil
    end
    local nextProfile, report = self._saveSchema.withResidentNight(profile, context, os.time())
    self._profiles[player] = nextProfile
    return report
end

function ProfileService.checkOnResident(
    self: ProfileService,
    player: Player,
    residentId: string
): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { accepted = false, reason = "profile_unavailable", healed = false, bond = 0 }
    end
    local nextProfile, result = self._saveSchema.withResidentCheck(profile, residentId, os.time())
    self._profiles[player] = nextProfile
    return result
end

function ProfileService.residentLifeSnapshot(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return nil
    end
    return self._saveSchema.residentLifeSnapshot(profile)
end

function ProfileService.residentDawnBoons(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return {}
    end
    return self._saveSchema.residentDawnBoons(profile)
end

function ProfileService.placeDecoration(
    self: ProfileService,
    player: Player,
    decorationId: string
): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { applied = false, reason = "profile_unavailable" }
    end
    local nextProfile, result =
        self._saveSchema.withPlacedDecoration(profile, decorationId, os.time())
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent then
            self._dirty[player] = true
        end
    end
    return result
end

--[[
    The ticket back to the party this player left with.

    Deliberately two plain accessors rather than a snapshot: this is the one
    profile field that must never be published, so nothing here shapes it for
    a client. PartyService reads it to decide whether a rejoin is on offer and
    hands the presentable half to the snapshot itself.
]]
function ProfileService.setRejoinTicket(self: ProfileService, player: Player, ticket: any): boolean
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return false
    end
    local nextProfile = self._saveSchema.withRejoinTicket(profile, ticket, os.time())
    if nextProfile == profile then
        return false
    end
    self._profiles[player] = nextProfile
    if self._persistent then
        self._dirty[player] = true
    end
    return true
end

function ProfileService.rejoinTicket(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return nil
    end
    return self._saveSchema.rejoinTicket(profile)
end

function ProfileService.decorationsSnapshot(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return { placed = {}, count = 0, cap = 0 }
    end
    return self._saveSchema.decorationsSnapshot(profile)
end

function ProfileService.townConsequence(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return { tier = 0, title = "EMBERHOLLOW AWAKENS", detail = "" }
    end
    return self._saveSchema.townConsequence(profile)
end

function ProfileService.townConstructionState(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return {}
    end
    return self._saveSchema.constructionSnapshot(profile)
end

function ProfileService.contributeToConstruction(
    self: ProfileService,
    player: Player,
    buildingId: string
): any
    local profile = self._profiles[player]
    if profile == nil then
        return {
            accepted = false,
            reason = "profile_loading",
        }
    end
    if not self:isWritable(player) then
        return {
            accepted = false,
            reason = "profile_read_only",
        }
    end

    local ceilingStage = self._saveSchema.townConsequence(profile).buildingStages[buildingId] or 0
    local nextProfile, result =
        self._saveSchema.withConstructionContribution(profile, buildingId, ceilingStage, os.time())
    if not result.applied then
        return {
            accepted = false,
            reason = result.reason,
        }
    end

    self._profiles[player] = nextProfile
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    return {
        accepted = true,
        buildingId = result.buildingId,
        stage = result.stage,
    }
end

-- Safe to call after any action, whether or not it moved a quest signal:
-- returns an empty list and touches nothing when there's nothing newly
-- claimable.
function ProfileService.checkQuests(self: ProfileService, player: Player): { any }
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return {}
    end

    local nextProfile, claimedResults = self._saveSchema.checkAndClaimQuests(profile, os.time())
    if #claimedResults == 0 then
        return claimedResults
    end

    self._profiles[player] = nextProfile
    if self._persistent then
        self._dirty[player] = true
    end
    return claimedResults
end

function ProfileService.questSnapshot(self: ProfileService, player: Player): { any }
    local profile = self._profiles[player]
    if profile == nil then
        return {}
    end
    return self._saveSchema.questSnapshot(profile)
end

function ProfileService.gearSnapshot(self: ProfileService, player: Player): { [string]: number }
    local profile = self._profiles[player]
    if profile == nil then
        return {}
    end
    return self._saveSchema.gearSnapshot(profile)
end

function ProfileService.grantUnbankedExpeditionReward(
    self: ProfileService,
    player: Player,
    transactionId: string,
    manifestHash: string,
    reward: any
): any
    local profile = self._profiles[player]
    if profile == nil then
        return {
            accepted = false,
            durable = false,
            reason = "profile_loading",
        }
    end
    if not self:isWritable(player) then
        return {
            accepted = false,
            durable = false,
            reason = "profile_read_only",
        }
    end

    local nextProfile, result = self._saveSchema.withUnbankedExpeditionReward(
        profile,
        transactionId,
        manifestHash,
        reward,
        os.time()
    )
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent then
            self._dirty[player] = true
        end
    elseif not result.duplicate then
        return {
            accepted = false,
            durable = false,
            reason = result.reason,
        }
    end

    local durable = not self._persistent
    if self._persistent and result.applied then
        task.spawn(function()
            self:save(player)
        end)
    elseif self._persistent and result.duplicate then
        durable = self._dirty[player] ~= true
    end
    return {
        accepted = true,
        applied = result.applied == true,
        durable = durable,
        reason = if durable then nil else "save_queued",
    }
end

function ProfileService.settleExpedition(
    self: ProfileService,
    player: Player,
    runId: string,
    manifestHash: string,
    sessionRewards: { any }
): any
    local profile = self._profiles[player]
    if profile == nil then
        return {
            accepted = false,
            reason = "profile_loading",
        }
    end
    if not self:isWritable(player) then
        return {
            accepted = false,
            reason = "profile_read_only",
        }
    end

    local workingProfile = profile
    local sessionTransactionIds = {}
    for _, sessionReward in sessionRewards do
        local nextProfile, result = self._saveSchema.withUnbankedExpeditionReward(
            workingProfile,
            sessionReward.transactionId,
            sessionReward.manifestHash,
            {
                amount = sessionReward.amount,
                materialId = sessionReward.materialId,
            },
            os.time()
        )
        if not result.applied and not result.duplicate then
            return {
                accepted = false,
                reason = result.reason,
            }
        end
        workingProfile = nextProfile
        table.insert(sessionTransactionIds, sessionReward.transactionId)
    end

    local pending = self._saveSchema.expeditionPending(workingProfile)
    local settlementId = nil
    local settlementRecord = nil
    if pending.count > 0 then
        settlementId =
            self._saveSchema.expeditionSettlementId(runId, player.UserId, pending.fingerprint)
        local nextProfile, result = self._saveSchema.withExpeditionSettlement(
            workingProfile,
            settlementId,
            manifestHash,
            os.time()
        )
        if not result.applied and not result.duplicate then
            return {
                accepted = false,
                reason = result.reason,
            }
        end
        workingProfile = nextProfile
        settlementRecord = result.record
    elseif #sessionTransactionIds > 0 then
        settlementId, settlementRecord = self._saveSchema.findExpeditionSettlementForRewards(
            workingProfile,
            sessionTransactionIds
        )
    end

    if workingProfile ~= profile then
        self._profiles[player] = workingProfile
        if self._persistent then
            self._dirty[player] = true
        end
    end
    if settlementId == nil then
        return {
            accepted = true,
            empty = true,
            inventory = table.clone(workingProfile.inventory.materials),
            sessionTransactionIds = sessionTransactionIds,
        }
    end

    local saved = if self._persistent then self:save(player) else true
    local activeProfile = self._profiles[player]
    local durable = saved
        and activeProfile ~= nil
        and self._saveSchema.hasExpeditionSettlement(activeProfile, settlementId)
    return {
        accepted = durable,
        durable = durable,
        inventory = if activeProfile == nil
            then {}
            else table.clone(activeProfile.inventory.materials),
        materials = if settlementRecord == nil then {} else table.clone(settlementRecord.materials),
        overflow = if settlementRecord ~= nil and settlementRecord.overflow ~= nil
            then table.clone(settlementRecord.overflow)
            else nil,
        reason = if durable then nil else "save_pending",
        settlementId = settlementId,
        sessionTransactionIds = sessionTransactionIds,
    }
end

function ProfileService.inventorySnapshot(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return {
            banked = {},
            cachedTransactionIds = {},
            pending = {},
            pendingRewards = {},
            recovery = nil,
        }
    end
    local pending = self._saveSchema.expeditionPending(profile)
    return {
        banked = table.clone(profile.inventory.materials),
        cachedTransactionIds = self._saveSchema.expeditionCachedTransactionIds(profile),
        pending = pending.materials,
        pendingRewards = pending.rewards,
        recovery = self._saveSchema.expeditionRecovery(profile),
    }
end

function ProfileService.cacheExpeditionFailure(
    self: ProfileService,
    player: Player,
    runId: string,
    manifestHash: string,
    sessionRewards: { any }
): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { accepted = false, reason = "profile_unavailable" }
    end
    local workingProfile = profile
    for _, sessionReward in sessionRewards do
        local nextProfile, result = self._saveSchema.withUnbankedExpeditionReward(
            workingProfile,
            sessionReward.transactionId,
            sessionReward.manifestHash,
            { amount = sessionReward.amount, materialId = sessionReward.materialId },
            os.time()
        )
        if not result.applied and not result.duplicate then
            return { accepted = false, reason = result.reason }
        end
        workingProfile = nextProfile
    end

    local pending = self._saveSchema.expeditionPending(workingProfile)
    if pending.count < 2 then
        if workingProfile ~= profile then
            self._profiles[player] = workingProfile
            if self._persistent then
                self._dirty[player] = true
            end
        end
        local durable = if self._persistent and self._dirty[player] == true
            then self:save(player)
            else true
        return {
            accepted = durable,
            cached = false,
            durable = durable,
            reason = if durable then "pouch_retained" else "save_pending",
        }
    end
    local baseCacheId =
        self._saveSchema.expeditionRecoveryCacheId(runId, player.UserId, pending.fingerprint)
    local cacheId = baseCacheId
    local suffix = 1
    while
        workingProfile.inventory.recoveryCaches[cacheId] ~= nil
        and workingProfile.inventory.recoveryCaches[cacheId].status == "recovered"
    do
        suffix += 1
        cacheId = string.format("%s:%d", baseCacheId, suffix)
    end
    local nextProfile, result = self._saveSchema.withExpeditionFailureCache(
        workingProfile,
        cacheId,
        manifestHash,
        os.time()
    )
    if not result.applied and not result.duplicate then
        return { accepted = false, reason = result.reason }
    end
    self._profiles[player] = nextProfile
    if self._persistent then
        self._dirty[player] = true
    end
    local durable = if self._persistent then self:save(player) else true
    return {
        accepted = durable,
        cacheId = cacheId,
        cached = true,
        durable = durable,
        materials = result.materials or {},
        reason = if durable then "cached" else "save_pending",
        retained = result.retained or 0,
        transactionIds = result.transactionIds or {},
    }
end

function ProfileService.recoveryCache(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    return if profile == nil then nil else self._saveSchema.expeditionRecovery(profile)
end

function ProfileService.recoverExpeditionCache(
    self: ProfileService,
    player: Player,
    cacheId: string
): any
    local profile = self._profiles[player]
    if profile == nil or not self:isWritable(player) then
        return { accepted = false, reason = "profile_unavailable" }
    end
    local nextProfile, result =
        self._saveSchema.withRecoveredExpeditionCache(profile, cacheId, os.time())
    if not result.applied then
        if result.duplicate then
            local durable = if self._persistent and self._dirty[player] == true
                then self:save(player)
                else true
            return {
                accepted = durable,
                cacheId = cacheId,
                durable = durable,
                materials = result.materials or {},
                reason = if durable then "recovered" else "save_pending",
            }
        end
        return { accepted = false, reason = result.reason }
    end
    self._profiles[player] = nextProfile
    if self._persistent then
        self._dirty[player] = true
    end
    local durable = if self._persistent then self:save(player) else true
    return {
        accepted = durable,
        cacheId = cacheId,
        durable = durable,
        materials = result.materials or {},
        reason = if durable then "recovered" else "save_pending",
    }
end

function ProfileService.completeChapterOne(
    self: ProfileService,
    player: Player,
    transactionId: string,
    decision: string,
    wardenOutcome: string
): any
    local profile = self._profiles[player]
    if profile == nil then
        return {
            accepted = false,
            durable = false,
            reason = "profile_loading",
        }
    end
    if not self:isWritable(player) then
        return {
            accepted = false,
            durable = false,
            reason = "profile_read_only",
        }
    end
    local nextProfile, result = self._saveSchema.withChapterOneResolution(
        profile,
        transactionId,
        decision,
        wardenOutcome,
        os.time()
    )
    if not result.applied and not result.duplicate then
        return {
            accepted = false,
            durable = true,
            reason = result.reason,
        }
    end
    if result.applied then
        self._profiles[player] = nextProfile
        if self._persistent then
            self._dirty[player] = true
        end
    end
    local durable = not self._persistent
    if self._persistent and result.applied then
        local saved = self:save(player)
        local activeProfile = self._profiles[player]
        local chapter = if activeProfile == nil
            then nil
            else self._saveSchema.chapterOne(activeProfile)
        durable = saved
            and chapter ~= nil
            and chapter.status == "complete"
            and chapter.transactionId == transactionId
    elseif self._persistent and result.duplicate then
        local saved = if self._dirty[player] == true then self:save(player) else true
        local activeProfile = self._profiles[player]
        local chapter = if activeProfile == nil
            then nil
            else self._saveSchema.chapterOne(activeProfile)
        durable = saved
            and self._dirty[player] ~= true
            and chapter ~= nil
            and chapter.status == "complete"
            and chapter.transactionId == transactionId
    end
    return {
        accepted = true,
        applied = result.applied == true,
        durable = durable,
        reason = if durable then result.reason else "save_pending",
        story = result.record,
    }
end

function ProfileService.chapterOneSnapshot(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return nil
    end
    return self._saveSchema.chapterOne(profile)
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
                local normalized = if current == nil
                    then nil
                    else self._saveSchema.normalize(current, os.time())
                local decision = self._profilePersistence.resolveWrite(normalized, profile)
                if decision.action == "retain_stored" then
                    retainedNewer = true
                    newerProfile = normalized
                    return current
                end
                -- The lock rides along with the profile so a crash leaves
                -- behind a heartbeat that stops, which is the only thing a
                -- later session can use to tell dead from merely slow.
                local written = table.clone(profile)
                written.sessionLock = self._profilePersistence.lock(self._jobId, os.time())
                return written
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

    -- The write carried a fresh lock, so the heartbeat is only recorded on the
    -- path that actually reached the store.
    self._lockHeartbeat[player] = os.time()

    -- Ordinary rate-limited copy of a save that has just been written. Spawned
    -- for the same reason as the load-path capture: the autosave beat is the
    -- busiest path in the game and must not wait on a second store.
    task.spawn(function()
        self:_captureBackup(player.UserId, profile, profile.schemaVersion, nil)
    end)

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

--[[
    Read-only inspection of any player's save, online or not.

    Reads the DataStore key directly rather than going through a live
    session, which is the entire point: an admin needs to look at a save
    whether or not that player is on this server, or on any server at all.
    It never touches self._profiles, never claims the lock, and cannot be
    reached by anything but AdminService, which is itself gated to the
    roster.

    In non-persistent mode (Studio without ProfileLockStaleAfterSeconds
    wired to a real store) there is nothing durable to read, so this reports
    "not found" rather than reaching for a store that was never opened.
]]
function ProfileService.inspect(self: ProfileService, userId: number): any
    assert(type(userId) == "number" and userId > 0, "inspection target must be a valid user ID")
    local now = os.time()
    local staleAfter = self._config.ProfileLockStaleAfterSeconds

    if not self._persistent or self._store == nil then
        return self._adminInspectionReport.build(nil, now, staleAfter)
    end

    local ok, result = pcall(function()
        return (self._store :: GlobalDataStore):GetAsync(string.format("player_%d", userId))
    end)
    if not ok then
        self._logger:warn("profile_inspection_failed", {
            userId = userId,
            reason = tostring(result),
        })
        error("could not read that profile right now")
    end

    return self._adminInspectionReport.build(result, now, staleAfter)
end

--[[
    Clears a lock, but only one that is already dead.

    This is the one write an offline profile is allowed to receive from an
    admin, and it is deliberately the narrowest write that could exist: it
    can remove a stale sessionLock field and nothing else. It cannot touch
    night number, materials, equipment, or anything a player earned, which is
    what keeps it out of the "repair tool becomes a duplication vector"
    problem inspect's own doc comment warns about.

    Safety is UpdateAsync re-deciding from scratch on the value it is actually
    about to commit over, using the exact same ProfilePersistence.acquireLock
    a real server uses to decide whether it may start playing a profile --
    not a snapshot read beforehand, which could be stale by the time the
    write lands. A throwaway job ID is passed in because this is not claiming
    the lock for a session; a decision of "already_held" would only mean the
    stored jobId happens to collide with that throwaway string, which cannot
    happen. Every other acquireLock outcome -- unlocked, malformed, stale, a
    heartbeat from a broken clock -- means the same thing here: no live
    server is holding this, so the field may go.
]]
function ProfileService.forceUnlock(self: ProfileService, userId: number): any
    assert(type(userId) == "number" and userId > 0, "unlock target must be a valid user ID")

    if not self._persistent or self._store == nil then
        return { applied = false, reason = "not_persistent" }
    end

    local outcome: any = { applied = false, reason = "update_did_not_run" }
    local ok, err = pcall(function()
        (self._store :: GlobalDataStore):UpdateAsync(
            string.format("player_%d", userId),
            function(current: any)
                if current == nil then
                    outcome = { applied = false, reason = "no_save_on_record" }
                    return nil
                end
                local existingLock = if type(current) == "table" then current.sessionLock else nil
                if existingLock == nil then
                    outcome = { applied = false, reason = "already_unlocked" }
                    return nil
                end
                local decision = self._profilePersistence.acquireLock(
                    existingLock,
                    "admin-unlock-check",
                    os.time(),
                    self._config.ProfileLockStaleAfterSeconds
                )
                if not decision.acquired then
                    outcome = { applied = false, reason = "lock_is_active" }
                    return nil
                end
                local updated = table.clone(current)
                updated.sessionLock = nil
                outcome = { applied = true, reason = decision.reason }
                return updated
            end
        )
    end)
    if not ok then
        self._logger:warn("profile_unlock_failed", { userId = userId, reason = tostring(err) })
        error("could not update that profile right now")
    end

    return outcome
end

--[[
    What copies exist for a player, without restoring anything.

    The read half of the repair tooling, and the one an operator should always
    run first: a restore is a deliberate move backwards in a player's progress,
    and the only way to make that judgement is to see how far back the copies go
    and why each was taken.
]]
function ProfileService.backupSummary(self: ProfileService, userId: number): any
    assert(type(userId) == "number" and userId > 0, "backup target must be a valid user ID")

    if not self._persistent or self._backupStore == nil then
        return self._profileBackup.summary(nil)
    end

    local ok, result = pcall(function()
        return (self._backupStore :: GlobalDataStore):GetAsync(string.format("player_%d", userId))
    end)
    if not ok then
        self._logger:warn("profile_backup_read_failed", {
            userId = userId,
            reason = tostring(result),
        })
        error("could not read that player's backups right now")
    end

    return self._profileBackup.summary(result)
end

--[[
    Roll a save back to its most recent copy.

    The safe-repair half of Milestone 4's admin deliverable, and the riskiest
    call in this file, so the constraints are worth stating plainly:

      * **It refuses while a live server holds the profile.** Restoring under a
        session that is still writing would have that session's next autosave
        immediately overwrite the restore -- or worse, land between the read and
        the write. `lock_is_active` here means the same thing it means for
        /unlock: something is genuinely still playing this, and forcing it is
        the exact race the locking system exists to prevent.
      * **The pre-restore profile is itself copied first.** A restore is
        therefore undoable: an operator who rolls back the wrong player, or the
        wrong far, has the state they replaced sitting in the same ring. Without
        this the tool is a one-way door, and a one-way door in a repair tool is
        how a repair becomes an incident.
      * **It never invents progress.** The only thing written is a profile this
        player previously had, at a revision above the live one so the write
        actually lands. Nothing is merged, topped up, or granted.
]]
--[[
    The raw stored profile as JSON, for the export half of the admin
    tooling. Reads the stored bytes, not the in-memory session, because an
    export exists to answer "what is actually in the datastore" -- the same
    question a migration audit asks.
]]
function ProfileService.exportProfile(self: ProfileService, userId: number): any
    assert(type(userId) == "number" and userId > 0, "export target must be a valid user ID")
    if not self._persistent or self._store == nil then
        return { ok = false, reason = "not_persistent" }
    end
    local readOk, stored = pcall(function()
        return (self._store :: GlobalDataStore):GetAsync(string.format("player_%d", userId))
    end)
    if not readOk then
        return { ok = false, reason = "read_failed" }
    end
    if stored == nil then
        return { ok = false, reason = "no_save_on_record" }
    end
    local encodeOk, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(stored)
    end)
    if not encodeOk then
        return { ok = false, reason = "encode_failed" }
    end
    return { ok = true, json = encoded }
end

function ProfileService.restoreLatestBackup(
    self: ProfileService,
    userId: number,
    copyIndex: number?
): any
    assert(type(userId) == "number" and userId > 0, "restore target must be a valid user ID")

    if not self._persistent or self._store == nil or self._backupStore == nil then
        return { applied = false, reason = "not_persistent" }
    end

    local readOk, stored = pcall(function()
        return (self._backupStore :: GlobalDataStore):GetAsync(string.format("player_%d", userId))
    end)
    if not readOk then
        self._logger:warn("profile_backup_read_failed", {
            userId = userId,
            reason = tostring(stored),
        })
        error("could not read that player's backups right now")
    end

    -- An explicit copy index restores history; no index keeps the everyday
    -- newest-copy behaviour. An index with no copy behind it refuses rather
    -- than falling back -- see ProfileBackup.snapshotAt.
    local snapshot = if copyIndex ~= nil
        then self._profileBackup.snapshotAt(stored, copyIndex)
        else self._profileBackup.newest(stored)
    if snapshot == nil then
        return {
            applied = false,
            reason = if copyIndex ~= nil then "no_such_copy" else "no_backup_on_record",
        }
    end

    local outcome: any = { applied = false, reason = "update_did_not_run" }
    local replaced: any = nil
    local ok, err = pcall(function()
        (self._store :: GlobalDataStore):UpdateAsync(
            string.format("player_%d", userId),
            function(current: any)
                if current == nil then
                    outcome = { applied = false, reason = "no_save_on_record" }
                    return nil
                end

                -- Decided against the value actually about to be committed
                -- over, not against a snapshot read beforehand, for the same
                -- reason forceUnlock does it here.
                local existingLock = if type(current) == "table" then current.sessionLock else nil
                if existingLock ~= nil then
                    local decision = self._profilePersistence.acquireLock(
                        existingLock,
                        "admin-restore-check",
                        os.time(),
                        self._config.ProfileLockStaleAfterSeconds
                    )
                    if not decision.acquired then
                        outcome = { applied = false, reason = "lock_is_active" }
                        return nil
                    end
                end

                local storedRevision = if type(current) == "table" then current.revision else nil
                local restored =
                    self._profileBackup.restoredProfile(snapshot, storedRevision, os.time())

                replaced = current
                outcome = {
                    applied = true,
                    reason = snapshot.reason,
                    restoredRevision = restored.revision,
                    fromRevision = storedRevision,
                    capturedAt = snapshot.capturedAt,
                    schemaVersion = snapshot.schemaVersion,
                }
                return restored
            end
        )
    end)
    if not ok then
        self._logger:warn("profile_restore_failed", { userId = userId, reason = tostring(err) })
        error("could not update that profile right now")
    end

    -- Only after the restore has actually committed, so a refused restore does
    -- not spend a slot in the ring on a copy of a profile nothing replaced.
    if outcome.applied and replaced ~= nil then
        self:_captureBackup(userId, replaced, nil, "pre_restore")
    end

    return outcome
end

return table.freeze(ProfileService)
