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
        _equipmentChangedEvent: BindableEvent,
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
        _equipmentChangedEvent = Instance.new("BindableEvent"),
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

    self._profiles[player] = self._saveSchema.withTutorial(profile, stage, selectedTool, os.time())
    if self._persistent and self._writable[player] == true then
        self._dirty[player] = true
    end
    return true
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

function ProfileService.equipmentStats(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return { damageReduction = 0, staminaRegenMultiplier = 1 }
    end
    return self._saveSchema.equipmentStats(profile)
end

function ProfileService.townConsequence(self: ProfileService, player: Player): any
    local profile = self._profiles[player]
    if profile == nil then
        return { tier = 0, title = "EMBERHOLLOW AWAKENS", detail = "" }
    end
    return self._saveSchema.townConsequence(profile)
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
            pending = {},
            pendingRewards = {},
        }
    end
    local pending = self._saveSchema.expeditionPending(profile)
    return {
        banked = table.clone(profile.inventory.materials),
        pending = pending.materials,
        pendingRewards = pending.rewards,
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
