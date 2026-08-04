--!strict

--[[
    Runs admin commands typed in chat.

    Every decision about who may run what lives in the pure AdminRoster module.
    This service only listens, asks, and — if the answer is yes — performs the
    effect through the same service methods the game itself uses. It never
    reaches into state directly, so an admin command cannot put the game
    somewhere the game cannot otherwise be.

    Three properties matter more than the commands themselves:

      * The feature flag is a real off switch. It is checked on every message,
        not cached at startup, so flipping it stops admin commands mid-session
        for everyone including the roster.
      * Nothing is silent. Every accepted command is logged with the admin's
        user ID and the value applied, which is the audit trail the roadmap
        asks for before admin tooling counts as done.
      * Refusals are quiet to everyone else. An ordinary player typing chat
        gets no reply and no hint that a roster exists.
]]

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local AdminService = {}
AdminService.__index = AdminService
AdminService.Name = "AdminService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type AdminService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _adminRoster: any,
        _featureFlags: any,
        _profileService: any,
        _survivalService: any,
        _combatService: any,
        _tutorialService: any,
        _worldService: any,
        _expeditionService: any,
        _performanceService: any,
    },
    AdminService
))

function AdminService.new(
    logger: Logger,
    adminRoster: any,
    featureFlags: any,
    profileService: any,
    survivalService: any,
    combatService: any,
    worldService: any,
    expeditionService: any,
    performanceService: any
): AdminService
    return setmetatable({
        Name = AdminService.Name,
        _logger = logger,
        _adminRoster = adminRoster,
        _featureFlags = featureFlags,
        _profileService = profileService,
        _survivalService = survivalService,
        _combatService = combatService,
        _tutorialService = nil,
        _worldService = worldService,
        _expeditionService = expeditionService,
        _performanceService = performanceService,
    }, AdminService)
end

function AdminService.Init(_self: AdminService, _context: any) end

-- Set after construction because TutorialService is built later and owns the
-- player-facing toast an admin needs as confirmation.
function AdminService.setTutorialService(self: AdminService, tutorialService: any)
    self._tutorialService = tutorialService
end

function AdminService._reply(self: AdminService, player: Player, message: string)
    local tutorialService = self._tutorialService
    if tutorialService ~= nil then
        tutorialService:adminToast(player, message)
    end
end

function AdminService._run(self: AdminService, player: Player, decision: any)
    local command = decision.command

    if command == "night" then
        -- Town tier derives from the night count, so this is also how a
        -- tester brings the resident cast in without editing the gate that
        -- authored them to arrive with chapter one.
        self._profileService:setNightNumber(player, decision.value)
        self:_reply(
            player,
            string.format("NIGHT SET TO %d — REJOIN TO SEE THE TOWN", decision.value)
        )
    elseif command == "give" then
        self._tutorialService:adminGrantResources(player, decision.value)
        self:_reply(player, string.format("HEARTWOOD SET TO %d", decision.value))
    elseif command == "perf" then
        -- The headline goes to the toast because a tester on a phone cannot
        -- read a table, and every line goes to the log because whoever closes
        -- the exit gate needs the numbers rather than the verdict.
        local lines = self._performanceService:formattedReport()
        self:_reply(player, lines[1])
        for _, line in lines do
            self._logger:info("performance_report", { line = line })
        end
    elseif command == "heal" then
        self._survivalService:healInRadius(player, 500)
        self._combatService:restoreStamina(player, 100)
        self:_reply(player, "HEALED")
    elseif command == "phase" then
        local applied = self._worldService:adminSetPhase(decision.text)
        self:_reply(
            player,
            if applied
                then string.upper(decision.text) .. " APPLIED"
                else "PHASE UNAVAILABLE RIGHT NOW"
        )
    elseif command == "go" then
        -- Uses the same enter and exit the game uses, so an admin cannot
        -- arrive somewhere the transition would not normally put them.
        if command == nil then
            return
        end
        if decision.text == "bramblewake" then
            if player:GetAttribute("LastLightInExpedition") == true then
                self:_reply(player, "ALREADY IN BRAMBLEWAKE")
            else
                local entered = self._expeditionService:enter(player)
                self:_reply(player, if entered then "ENTERING BRAMBLEWAKE" else "ENTRY UNAVAILABLE")
            end
        else
            if player:GetAttribute("LastLightInExpedition") ~= true then
                self:_reply(player, "ALREADY IN TOWN")
            else
                local left = self._worldService:exitBramblewake(player)
                self:_reply(
                    player,
                    if left then "RETURNING TO EMBERHOLLOW" else "RETURN UNAVAILABLE"
                )
            end
        end
    elseif command == "where" then
        local root = if player.Character ~= nil
            then player.Character:FindFirstChild("HumanoidRootPart")
            else nil
        if root ~= nil and root:IsA("BasePart") then
            local at = root.Position
            self:_reply(player, string.format("%.0f, %.0f, %.0f", at.X, at.Y, at.Z))
        end
    elseif command == "inspect" then
        -- The roster only reaches this branch with allowed = true once
        -- decision.text is a non-empty string of bounded length -- see
        -- AdminRoster.authorize's inspect case -- so the cast documents an
        -- invariant this file does not itself enforce, rather than skips one.
        self:_inspect(player, decision.text :: string)
    elseif command == "unlock" then
        self:_unlock(player, decision.text :: string)
    elseif command == "backups" then
        self:_backups(player, decision.text :: string)
    elseif command == "restore" then
        self:_restore(player, decision.text :: string)
    end

    self._logger:info("admin_command", {
        admin = player.UserId,
        command = command,
        value = decision.value,
        text = decision.text,
    })
end

--[[
    A username or a raw user ID, resolved to a user ID -- or nil, with the
    refusal already sent, so both /inspect and /unlock can share one lookup
    instead of two copies drifting apart.
]]
function AdminService._resolveTarget(self: AdminService, admin: Player, argument: string): number?
    local resolvedId: number? = tonumber(argument)
    if resolvedId == nil then
        local ok, byName = pcall(function()
            return Players:GetUserIdFromNameAsync(argument)
        end)
        if ok and type(byName) == "number" then
            resolvedId = byName
        end
    end
    if resolvedId == nil or resolvedId <= 0 then
        self:_reply(admin, "NO PLAYER NAMED " .. string.upper(argument))
        return nil
    end
    return math.floor(resolvedId)
end

--[[
    Reads a save without needing the target online, and writes the full
    result to the log rather than the toast.

    A toast is a HUD element sized for one line -- "HEALED", "NIGHT SET TO
    4". The report this produces has a dozen fields and is the actual audit
    record an operator wants, so it goes to Output next to profile_loaded and
    profile_saved, where the rest of a save's history already lives. The
    toast only confirms the command ran and gives the one number worth
    seeing without leaving the game.
]]
function AdminService._inspect(self: AdminService, admin: Player, argument: string)
    local userId = self:_resolveTarget(admin, argument)
    if userId == nil then
        return
    end

    local report = self._profileService:inspect(userId)
    if not report.found then
        self._logger:info("admin_inspection", {
            admin = admin.UserId,
            target = userId,
            found = false,
        })
        self:_reply(admin, string.format("NO SAVE ON RECORD FOR %d", userId))
        return
    end

    self._logger:info("admin_inspection", {
        admin = admin.UserId,
        target = userId,
        found = true,
        schemaVersion = report.schemaVersion,
        nightNumber = report.nightNumber,
        tutorialStage = report.tutorialStage,
        tutorialComplete = report.tutorialComplete,
        chapterOneStatus = report.chapterOneStatus,
        chapterOneDecision = report.chapterOneDecision,
        professionId = report.professionId,
        professionsWithMastery = report.professionsWithMastery,
        equippedCount = report.equippedCount,
        gearStacks = report.gearStacks,
        lockHeld = report.lock.held,
        lockHolder = report.lock.holder,
        lockStale = report.lock.stale,
    })
    self:_reply(
        admin,
        string.format(
            "%d — NIGHT %s · %s%s — SEE OUTPUT FOR FULL REPORT",
            userId,
            tostring(report.nightNumber),
            string.upper(tostring(report.tutorialStage)),
            if report.lock.held and report.lock.stale ~= true then " · LOCKED" else ""
        )
    )
end

--[[
    Lists the copies held for a player, changing nothing.

    Always the first half of a repair: /restore is a deliberate move backwards
    in someone's progress, and this is how an operator sees how far back it
    would go and why each copy was taken before deciding.
]]
function AdminService._backups(self: AdminService, admin: Player, argument: string)
    local userId = self:_resolveTarget(admin, argument)
    if userId == nil then
        return
    end

    local summary = self._profileService:backupSummary(userId)
    self._logger:info("admin_backup_list", {
        admin = admin.UserId,
        target = userId,
        count = summary.count,
        newestRevision = summary.newestRevision,
        newestCapturedAt = summary.newestCapturedAt,
        entries = summary.entries,
    })

    if summary.count == 0 then
        self:_reply(admin, string.format("NO BACKUPS ON RECORD FOR %d", userId))
        return
    end

    self:_reply(
        admin,
        string.format(
            "%d — %d BACKUP%s · NEWEST REV %s — SEE OUTPUT",
            userId,
            summary.count,
            if summary.count == 1 then "" else "S",
            tostring(summary.newestRevision)
        )
    )
end

--[[
    Rolls a save back to its newest copy.

    The write half, and the one command here that changes a player's progress
    rather than the world around them, so it is worth being explicit about what
    keeps it safe. ProfileService refuses while a live server holds the profile,
    copies the replaced profile before overwriting it -- so running /restore
    twice undoes the first -- and writes only a profile this player already had.
    Nothing here merges, tops up, or grants.
]]
function AdminService._restore(self: AdminService, admin: Player, argument: string)
    local userId = self:_resolveTarget(admin, argument)
    if userId == nil then
        return
    end

    local result = self._profileService:restoreLatestBackup(userId)
    self._logger:info("admin_restore", {
        admin = admin.UserId,
        target = userId,
        applied = result.applied,
        reason = result.reason,
        fromRevision = result.fromRevision,
        restoredRevision = result.restoredRevision,
        capturedAt = result.capturedAt,
        schemaVersion = result.schemaVersion,
    })

    if result.applied then
        self:_reply(
            admin,
            string.format(
                "%d — RESTORED TO REV %s (WAS %s) · RUN AGAIN TO UNDO",
                userId,
                tostring(result.restoredRevision),
                tostring(result.fromRevision)
            )
        )
        return
    end

    local reply = if result.reason == "no_backup_on_record"
        then string.format("NO BACKUPS ON RECORD FOR %d", userId)
        elseif result.reason == "no_save_on_record" then string.format(
            "NO SAVE ON RECORD FOR %d",
            userId
        )
        elseif result.reason == "lock_is_active" then string.format(
            "%d — A SERVER IS STILL HOLDING THIS SAVE",
            userId
        )
        else string.format("%d — RESTORE UNAVAILABLE RIGHT NOW", userId)
    self:_reply(admin, reply)
end

--[[
    Clears a lock, but only the ProfileService method backing this will ever
    clear a lock that is already dead. Every refusal reason it can return
    means the same thing to a player waiting to get back in: try rejoining
    now, because the lock either never existed, was already gone, or was
    just cleared. The one reason that does not is lock_is_active, and that
    one is not a bug to route around -- it means a server is still genuinely
    holding this save, and forcing it open from here is the exact race this
    whole system exists to prevent.
]]
function AdminService._unlock(self: AdminService, admin: Player, argument: string)
    local userId = self:_resolveTarget(admin, argument)
    if userId == nil then
        return
    end

    local result = self._profileService:forceUnlock(userId)
    self._logger:info("admin_unlock", {
        admin = admin.UserId,
        target = userId,
        applied = result.applied,
        reason = result.reason,
    })

    if result.applied then
        self:_reply(admin, string.format("%d — LOCK CLEARED (%s)", userId, result.reason))
        return
    end

    local reply = if result.reason == "no_save_on_record"
        then string.format("NO SAVE ON RECORD FOR %d", userId)
        elseif result.reason == "already_unlocked" then string.format(
            "%d — NOT LOCKED",
            userId
        )
        elseif result.reason == "lock_is_active" then string.format(
            "%d — A SERVER IS STILL HOLDING THIS SAVE",
            userId
        )
        else string.format("%d — UNLOCK UNAVAILABLE RIGHT NOW", userId)
    self:_reply(admin, reply)
end

function AdminService._onChatted(self: AdminService, player: Player, message: string)
    local decision = self._adminRoster.authorize(
        player.UserId,
        message,
        self._featureFlags:isEnabled("admin_commands_enabled")
    )
    if decision.allowed then
        local ok, err = pcall(function()
            self:_run(player, decision)
        end)
        if not ok then
            self._logger:warn("admin_command_failed", {
                admin = player.UserId,
                command = decision.command,
                error = tostring(err),
            })
            self:_reply(player, "THAT COMMAND FAILED")
        end
        return
    end

    -- Ordinary chat produces nothing at all. Only someone who typed a real
    -- command and is on the roster hears why it was refused, so the roster
    -- stays invisible to everyone else.
    if decision.reason == "not_a_command" or decision.reason == "not_an_admin" then
        return
    end
    if not self._adminRoster.isAdmin(player.UserId) then
        return
    end
    if decision.reason == "out_of_range" then
        self:_reply(
            player,
            string.format(
                "%s TAKES %d TO %d",
                string.upper(tostring(decision.command)),
                decision.low,
                decision.high
            )
        )
    elseif decision.reason == "unknown_destination" then
        self:_reply(player, "GO TAKES TOWN OR BRAMBLEWAKE")
    elseif decision.reason == "unknown_phase" then
        self:_reply(player, "PHASE TAKES DAY, DUSK, OR NIGHT")
    elseif decision.reason == "invalid_inspection_target" then
        self:_reply(player, "INSPECT TAKES A USERNAME OR USER ID")
    elseif decision.reason == "invalid_unlock_target" then
        self:_reply(player, "UNLOCK TAKES A USERNAME OR USER ID")
    elseif decision.reason == "invalid_backup_target" then
        self:_reply(
            player,
            string.format(
                "%s TAKES A USERNAME OR USER ID",
                string.upper(tostring(decision.command))
            )
        )
    elseif decision.reason == "admin_disabled" then
        self:_reply(player, "ADMIN COMMANDS ARE OFF")
    end
end

--[[
    Register one TextChatCommand per admin command.

    Player.Chatted is a legacy-chat event and does not fire when an
    experience uses TextChatService, which is the default for anything made
    recently. Every admin command in this game was therefore dead on arrival:
    the message went out as ordinary chat, nothing listened, and the only
    symptom was that typing it did nothing at all.

    AutocompleteVisible is false on every one of them. A registered command
    otherwise appears in the chat autocomplete for every player in the
    server, which would advertise the roster to exactly the people the silent
    refusals elsewhere in this file exist to keep it from.
]]
function AdminService._registerChatCommands(self: AdminService)
    for _, name in self._adminRoster.commandNames() do
        local command = Instance.new("TextChatCommand")
        command.Name = "LastLightAdmin_" .. name
        command.PrimaryAlias = "/" .. name
        command.AutocompleteVisible = false
        command.Triggered:Connect(function(textSource: TextSource, text: string)
            local player = Players:GetPlayerByUserId(textSource.UserId)
            if player ~= nil then
                self:_onChatted(player, text)
            end
        end)
        command.Parent = TextChatService
    end
end

function AdminService.Start(self: AdminService)
    -- Both paths are wired because only one of them can fire. Under
    -- TextChatService the commands above carry every message and Chatted
    -- stays silent; under legacy chat there are no TextChatCommands and
    -- Chatted is the only route. Neither knows about the other, and running
    -- both costs nothing.
    local registered, err = pcall(function()
        self:_registerChatCommands()
    end)
    if not registered then
        self._logger:warn("admin_chat_commands_unavailable", { error = tostring(err) })
    end

    local function bind(player: Player)
        player.Chatted:Connect(function(message: string)
            self:_onChatted(player, message)
        end)
    end
    for _, player in Players:GetPlayers() do
        bind(player)
    end
    Players.PlayerAdded:Connect(bind)

    self._logger:info("admin_service_started", {
        admins = #self._adminRoster.adminUserIds(),
        enabled = self._featureFlags:isEnabled("admin_commands_enabled"),
        chatCommands = registered,
    })
end

return AdminService
