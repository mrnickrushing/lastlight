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
    end

    self._logger:info("admin_command", {
        admin = player.UserId,
        command = command,
        value = decision.value,
        text = decision.text,
    })
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
