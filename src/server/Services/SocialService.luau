--!strict

--[[
    The live half of quick chat: who said what, where they were standing, and
    who is allowed to hear it.

    Everything about *what may be said* is in the pure QuickChat module. What
    needs the running game is here, and it is a short list on purpose:

      * **Where the sender is.** The payload carries a phrase id and nothing
        else, so the position comes from reading the sender's own character.
        A client cannot name a place, which is the whole reason a ping cannot
        be forged into marking somewhere its sender is not.
      * **Who has blocked whom.** Roblox's block list is the authority. It is
        asynchronous and it is not free, so it is resolved once per ordered
        pair and cached for the session.
      * **A budget.** Quick chat gets its own bucket through the same
        RateLimiter every action uses. Two budgets rather than one because a
        player spamming the wheel should not lose the ability to swing, and a
        player in a fight should not lose the ability to say I AM DOWN.

    The call log is one list for the whole server, filtered per recipient when
    a snapshot is built, rather than a copy per player. A per-player copy is a
    second place the suppression rule has to be remembered, and the rule that
    has two homes is the rule that stops being true in one of them.
]]

local Chat = game:GetService("Chat")
local Players = game:GetService("Players")

local SocialService = {}
SocialService.__index = SocialService
SocialService.Name = "SocialService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type SocialService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _quickChat: any,
        _featureFlags: any,
        _analyticsService: any,
        _limiter: any,
        _calls: { any },
        _sequence: number,
        --[[
            Resolved block answers, keyed "fromUserId>toUserId". Absent means
            unresolved rather than allowed, and an unresolved pair resolves in
            the background the first time it is asked about, so the second
            call between the same two people is already correct.
        ]]
        _canChat: { [string]: boolean },
        _resolving: { [string]: boolean },
        _blockApiWarned: boolean,
    },
    SocialService
))

function SocialService.new(
    logger: Logger,
    config: any,
    quickChat: any,
    rateLimiter: any,
    featureFlags: any,
    analyticsService: any
): SocialService
    return setmetatable({
        Name = SocialService.Name,
        _logger = logger,
        _config = config,
        _quickChat = quickChat,
        _featureFlags = featureFlags,
        _analyticsService = analyticsService,
        _limiter = rateLimiter.new(config.QuickChatRatePerSecond, config.QuickChatBurst),
        _calls = {},
        _sequence = 0,
        _canChat = {},
        _resolving = {},
        _blockApiWarned = false,
    }, SocialService)
end

function SocialService.Init(_self: SocialService, _context: any) end

function SocialService.Start(self: SocialService)
    Players.PlayerRemoving:Connect(function(player: Player)
        self._limiter:clear(tostring(player.UserId))
    end)
    self._logger:info("social_started", {
        phrases = #self._quickChat.list(),
    })
end

local function pairKey(fromUserId: number, toUserId: number): string
    return string.format("%d>%d", fromUserId, toUserId)
end

--[[
    Has `toUserId` blocked `fromUserId`.

    Chat:CanUsersChatAsync is the platform's own answer, and it accounts for
    more than an explicit block -- an account whose settings do not permit
    chat with the other party answers false too, which is the right answer for
    a phrase as much as for a sentence.

    Unresolved defaults to *allowed*, and that is a deliberate call rather
    than an oversight. Defaulting to suppressed would mean the first press
    between any two players is always silent, and in Studio -- where the
    endpoint is not reachable at all -- every press would be silent forever,
    which is how a feature ships unverified. A pair that the platform has
    actually answered on is always honoured, in both directions.
]]
function SocialService._resolvePair(self: SocialService, fromUserId: number, toUserId: number)
    local key = pairKey(fromUserId, toUserId)
    if self._canChat[key] ~= nil or self._resolving[key] then
        return
    end
    self._resolving[key] = true
    task.spawn(function()
        local ok, result = pcall(function()
            return Chat:CanUsersChatAsync(fromUserId, toUserId)
        end)
        self._resolving[key] = nil
        if ok then
            self._canChat[key] = result == true
            if result ~= true then
                self._logger:info("social_chat_suppressed", {
                    from = fromUserId,
                    to = toUserId,
                })
            end
        elseif not self._blockApiWarned then
            -- Once per server. A warning per pair per session is a log nobody
            -- reads, and the fallback is the same every time.
            self._blockApiWarned = true
            self._logger:warn("social_block_list_unavailable", { reason = tostring(result) })
        end
    end)
end

function SocialService.isSuppressed(
    self: SocialService,
    fromUserId: number,
    toUserId: number
): boolean
    if fromUserId == toUserId then
        return false
    end
    local resolved = self._canChat[pairKey(fromUserId, toUserId)]
    if resolved == nil then
        self:_resolvePair(fromUserId, toUserId)
        return false
    end
    return resolved == false
end

--[[
    Suppression is symmetric here even though the platform answers a directed
    question. If either party cannot chat with the other, neither hears the
    other -- a one-way channel between two people who have blocked each other
    in one direction is a channel somebody did not expect to have.
]]
function SocialService._suppressionFor(self: SocialService, recipient: Player): (number) -> boolean
    local recipientUserId = recipient.UserId
    return function(fromUserId: number): boolean
        return self:isSuppressed(fromUserId, recipientUserId)
            or self:isSuppressed(recipientUserId, fromUserId)
    end
end

local function characterPosition(player: Player): (number?, number?, number?)
    local character = player.Character
    if character == nil then
        return nil, nil, nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root == nil or not root:IsA("BasePart") then
        return nil, nil, nil
    end
    local position = root.Position
    return position.X, position.Y, position.Z
end

--[[
    Say one phrase. The only way anything reaches this service.
]]
function SocialService.say(self: SocialService, player: Player, phraseId: any): any
    if not self._featureFlags:isEnabled("quick_chat_enabled") then
        return { accepted = false, reason = "disabled" }
    end
    local phrase = self._quickChat.byId(phraseId)
    if phrase == nil then
        return { accepted = false, reason = "unknown_phrase" }
    end
    local now = workspace:GetServerTimeNow()
    if not self._limiter:allow(tostring(player.UserId), now, 1) then
        return { accepted = false, reason = "rate_limited" }
    end

    self._sequence += 1
    local x, y, z = characterPosition(player)
    local call = self._quickChat.call(
        phrase,
        player.UserId,
        player.DisplayName,
        now,
        self._sequence,
        x,
        y,
        z
    )
    table.insert(self._calls, call)
    -- Trimmed from the front: the log is the last few things said, and an
    -- unbounded list on a server that runs for hours is a leak the soak test
    -- would eventually find.
    while #self._calls > self._quickChat.LogLength do
        table.remove(self._calls, 1)
    end
    -- Every player in the server is a potential recipient, so every pair gets
    -- resolved now rather than on the snapshot that needs it. The first press
    -- of a session is otherwise the one press that ignores a block.
    for _, other in Players:GetPlayers() do
        if other ~= player then
            self:_resolvePair(player.UserId, other.UserId)
            self:_resolvePair(other.UserId, player.UserId)
        end
    end
    if self._analyticsService ~= nil then
        self._analyticsService:quickChatSent(player, phrase, call.marks)
    end
    return { accepted = true, call = call }
end

--[[
    SAFETY-CHANNEL: quick_chat_phrase -- what somebody said, filtered per
    recipient for expiry and for who has blocked whom.
    SAFETY-CHANNEL: quick_chat_ping -- the marker that phrase left, filtered by
    the same block rule and additionally by distance.

    Both filters live in the pure module and are applied here, at the one door
    a snapshot is built through. Filtering at the four places a snapshot is
    read would be four places to forget.
]]
function SocialService.snapshot(self: SocialService, player: Player): any
    local now = workspace:GetServerTimeNow()
    local suppressed = self:_suppressionFor(player)
    local x, y, z = characterPosition(player)
    return {
        calls = self._quickChat.visibleCalls(self._calls, player.UserId, suppressed, now),
        pings = self._quickChat.visiblePings(
            self._calls,
            player.UserId,
            suppressed,
            now,
            x,
            y,
            z,
            self._config.QuickChatPingRadius
        ),
    }
end

--[[
    Drop calls nobody can still see. The snapshot filters by expiry already,
    so this only keeps the list from holding stale entries between presses --
    which matters for the soak check, not for correctness.
]]
function SocialService.prune(self: SocialService, now: number)
    local kept = {}
    for _, call in self._calls do
        if call.expiresAt > now then
            table.insert(kept, call)
        end
    end
    self._calls = kept
end

return table.freeze(SocialService)
