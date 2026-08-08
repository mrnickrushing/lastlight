--!strict

--[[
    Parties at the lodge, and the way back to one.

    All the rules about who may join, who boards first and whether a returning
    player may be sent anywhere live in the pure PartySession module. This
    service owns only the parts that need the running game: which Player owns
    which user ID, who is physically standing on the departure platform, the
    profile write that persists a rejoin ticket, and the teleport that spends
    one.

    Two things it is deliberately careful about:

      * **The access code never leaves the server.** A rejoin ticket carries
        a reserved-server access code, which is the entire key to a private
        world. It is written to the profile, which is server-owned storage,
        and the only thing that reaches a client is PartySession.publicTicket
        -- available, party size, seconds left. Nothing here builds a snapshot
        field by hand out of a ticket, because that is the version of this
        rule that stops being true the first time somebody adds a field.
      * **An invitation names nobody.** The invite press carries no payload at
        all: it offers a seat to whoever the server can see standing on the
        platform. A press cannot be forged into naming a stranger across the
        map, because there is no name in it to forge.
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local PartyService = {}
PartyService.__index = PartyService
PartyService.Name = "PartyService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type PartyService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _partySession: any,
        _profileService: any,
        _analyticsService: any,
        _parties: { [string]: any },
        _partyByUser: { [number]: string },
        _inviteByUser: { [number]: string },
        --[[
            The party that is mid-launch, held in one slot rather than added
            to `_parties`. A departure is sealed and then never touched again,
            so filing it with the live rosters would grow that table by one
            per launch for the life of the server and nothing would ever read
            the entries. One slot is enough because the platform launches one
            party at a time, and an unclaimed one is simply overwritten by the
            next.
        ]]
        _departing: any,
        _runPartyId: string?,
        _onToast: ((Player?, string) -> ())?,
        _platformProvider: (() -> { Player })?,
    },
    PartyService
))

function PartyService.new(
    logger: Logger,
    config: any,
    partySession: any,
    profileService: any,
    analyticsService: any
): PartyService
    return setmetatable({
        Name = PartyService.Name,
        _logger = logger,
        _config = config,
        _partySession = partySession,
        _profileService = profileService,
        _analyticsService = analyticsService,
        _parties = {},
        _partyByUser = {},
        _inviteByUser = {},
        _departing = nil,
        _runPartyId = nil,
        _onToast = nil,
        _platformProvider = nil,
    }, PartyService)
end

function PartyService.Init(_self: PartyService, _context: any) end

function PartyService.setToastHandler(self: PartyService, callback: (Player?, string) -> ())
    self._onToast = callback
end

--[[
    Who the server can see standing on the departure platform.

    Supplied by LobbyService, which already measures occupancy from character
    positions every tick. Asking it rather than measuring again means an
    invitation and a boarding pass always agree about who is on the dais.
]]
function PartyService.setPlatformProvider(self: PartyService, provider: () -> { Player })
    self._platformProvider = provider
end

function PartyService._toast(self: PartyService, player: Player?, message: string)
    local handler = self._onToast
    if handler ~= nil then
        handler(player, message)
    end
end

local function now(): number
    return workspace:GetServerTimeNow()
end

function PartyService._partyOf(self: PartyService, player: Player): (string?, any)
    local partyId = self._partyByUser[player.UserId]
    if partyId == nil then
        return nil, nil
    end
    local state = self._parties[partyId]
    if state == nil then
        -- A roster that dissolved out from under a stale index. Clear rather
        -- than resurrect: an empty party would gladly accept an invitation.
        self._partyByUser[player.UserId] = nil
        return nil, nil
    end
    return partyId, state
end

function PartyService._store(self: PartyService, partyId: string, state: any)
    if state == nil then
        self._parties[partyId] = nil
        for userId, held in self._partyByUser do
            if held == partyId then
                self._partyByUser[userId] = nil
            end
        end
        for userId, held in self._inviteByUser do
            if held == partyId then
                self._inviteByUser[userId] = nil
            end
        end
        return
    end
    self._parties[partyId] = state
    for _, userId in self._partySession.memberIds(state) do
        self._partyByUser[userId] = partyId
    end
end

--[[
    Offer a seat to everyone else standing on the platform.

    A party is created only if there is somebody to ask. Pressing invite on an
    empty dais leaves no roster lying around, which matters because an
    existing party changes who boards first -- a party of one would quietly
    outrank the friend who walks up thirty seconds later.

    Anyone already in a party is skipped rather than refused. Two overlapping
    parties is a problem with no good answer at the platform, and the simplest
    honest rule is that you leave the one you are in before you join another.
]]
function PartyService.invite(self: PartyService, player: Player): any
    local provider = self._platformProvider
    if provider == nil then
        return { accepted = false, reason = "no_platform" }
    end

    local standing = provider()
    local onPlatform = false
    local eligible: { Player } = {}
    for _, other in standing do
        if other == player then
            onPlatform = true
        elseif self._partyByUser[other.UserId] == nil then
            table.insert(eligible, other)
        end
    end

    if not onPlatform then
        self:_toast(player, "STAND ON THE PLATFORM TO GATHER A PARTY")
        return { accepted = false, reason = "not_on_platform" }
    end
    if #eligible == 0 then
        self:_toast(player, "NOBODY ELSE IS STANDING HERE TO ASK")
        return { accepted = false, reason = "nobody_to_ask" }
    end

    local partyId, state = self:_partyOf(player)
    local createdHere = false
    if state == nil then
        local created, result = self._partySession.create(player.UserId, now())
        if created == nil then
            return { accepted = false, reason = result.reason }
        end
        partyId = created.partyId
        state = created
        createdHere = true
        self:_store(created.partyId, created)
    end

    local asked = 0
    local refusal: string? = nil
    for _, other in eligible do
        local nextState, result = self._partySession.invite(
            state,
            player.UserId,
            other.UserId,
            now(),
            self._config.MaxExpeditionPlayers
        )
        if result.accepted then
            state = nextState
            asked += 1
            self._inviteByUser[other.UserId] = partyId :: string
            self:_toast(
                other,
                string.format(
                    "%s ASKS YOU TO TRAVEL WITH THEM — JOIN OR DECLINE",
                    player.DisplayName
                )
            )
        else
            refusal = result.reason
        end
    end
    self:_store(partyId :: string, state)

    if asked == 0 then
        --[[
            A roster nobody joined must not survive the press. The paragraph
            above is only true if the party created a moment ago is taken
            back when every invitation was refused, because a stray party of
            one still outranks the friend who walks up thirty seconds later.

            The refusal is reported rather than assumed, too. "No room" was
            being said for every reason a party can turn somebody down, which
            makes the one message that will ever be read the one least likely
            to be true.
        ]]
        if createdHere then
            self:_store(partyId :: string, nil)
        end
        self:_toast(
            player,
            if refusal == "party_full"
                then "THERE IS NO ROOM LEFT IN YOUR PARTY"
                else "NOBODY HERE CAN BE ASKED RIGHT NOW"
        )
        return { accepted = false, reason = refusal or "nobody_to_ask" }
    end
    self:_toast(player, string.format("ASKED %d TO TRAVEL WITH YOU", asked))
    self._logger:info("party_invited", { partyId = partyId, asked = asked })
    return { accepted = true, asked = asked }
end

function PartyService.reply(self: PartyService, player: Player, accept: boolean): any
    local partyId = self._inviteByUser[player.UserId]
    local state = if partyId == nil then nil else self._parties[partyId]
    if state == nil then
        self._inviteByUser[player.UserId] = nil
        self:_toast(player, "NOBODY HAS ASKED YOU TO TRAVEL WITH THEM")
        return { accepted = false, reason = "no_invite" }
    end

    if not accept then
        local nextState = self._partySession.decline(state, player.UserId, now())
        self._inviteByUser[player.UserId] = nil
        self:_store(partyId :: string, nextState)
        self:_toast(player, "YOU TRAVEL ALONE")
        return { accepted = true, joined = false }
    end

    local nextState, result =
        self._partySession.accept(state, player.UserId, now(), self._config.MaxExpeditionPlayers)
    if not result.accepted then
        self._inviteByUser[player.UserId] = nil
        self:_toast(
            player,
            if result.reason == "party_full"
                then "THAT PARTY FILLED BEFORE YOU ANSWERED"
                else "THAT INVITATION HAS PASSED"
        )
        return { accepted = false, reason = result.reason }
    end

    self._inviteByUser[player.UserId] = nil
    self:_store(partyId :: string, nextState)
    for _, userId in self._partySession.memberIds(nextState) do
        local member = Players:GetPlayerByUserId(userId)
        if member ~= nil then
            self:_toast(
                member,
                string.format("PARTY OF %d — %s IS WITH YOU", result.size, player.DisplayName)
            )
        end
    end
    self._logger:info("party_joined", { partyId = partyId, size = result.size })
    return { accepted = true, joined = true }
end

function PartyService.leave(self: PartyService, player: Player): any
    local partyId, state = self:_partyOf(player)
    if state == nil then
        self:_toast(player, "YOU ARE NOT IN A PARTY")
        return { accepted = false, reason = "not_in_party" }
    end

    local nextState, result = self._partySession.leave(state, player.UserId, now())
    if not result.accepted then
        return { accepted = false, reason = result.reason }
    end
    self._partyByUser[player.UserId] = nil
    self:_store(partyId :: string, nextState)
    self:_toast(player, "YOU TRAVEL ALONE")

    if result.handedTo ~= nil then
        local leader = Players:GetPlayerByUserId(result.handedTo)
        if leader ~= nil then
            self:_toast(leader, "THE PARTY IS YOURS TO LEAD NOW")
        end
    end
    return { accepted = true, dissolved = result.dissolved == true }
end

--[[
    Re-order a boarding list so the party goes first.

    Called by LobbyService with everyone standing on the dais and the number
    of seats the chosen size allows. Before this, seats were spent in whatever
    order `Players:GetPlayers()` returned, so a bystander who wandered onto
    the platform could take one from somebody's party. Presence is still the
    platform's business: this only re-orders what it reports.
]]
function PartyService.boardingOrder(
    self: PartyService,
    ready: { Player },
    capacity: number
): { Player }
    local byUserId: { [number]: Player } = {}
    local userIds: { number } = {}
    for _, player in ready do
        byUserId[player.UserId] = player
        table.insert(userIds, player.UserId)
    end

    -- Whichever party has the most people on the dais is the one being
    -- boarded. With two parties standing on one platform somebody's run is
    -- going to be interrupted, and the larger group is the less bad answer.
    local best: any = nil
    local bestPresent = 0
    for _, partyId in self._partyByUser do
        local state = self._parties[partyId]
        if state ~= nil then
            local present = 0
            for _, userId in self._partySession.memberIds(state) do
                if byUserId[userId] ~= nil then
                    present += 1
                end
            end
            if present > bestPresent then
                best = state
                bestPresent = present
            end
        end
    end

    local ordered: { Player } = {}
    for _, userId in self._partySession.boardingOrder(best, userIds, capacity) do
        local player = byUserId[userId]
        if player ~= nil then
            table.insert(ordered, player)
        end
    end
    return ordered
end

--[[
    Form the party that is actually leaving, and name it.

    Called before the reserved server is asked for, because the ID has to ride
    the teleport payload. The party formed here is the boarding list rather
    than whatever roster existed at the lodge -- see PartySession's own note on
    why: a stranger who boarded is in that world too, and needs a way home
    from it.
]]
function PartyService.formDeparture(self: PartyService, boarding: { Player }): string?
    local userIds: { number } = {}
    for _, player in boarding do
        table.insert(userIds, player.UserId)
    end

    local formed, result = self._partySession.createForDeparture(userIds, now())
    if formed == nil then
        self._logger:warn("party_departure_unformed", { reason = result.reason })
        return nil
    end
    local sealed = self._partySession.depart(formed, now())

    -- The lodge-side parties these people were in are finished: they have
    -- left, and the rosters that decided their boarding order have nothing
    -- left to decide.
    for _, player in boarding do
        local partyId = self._partyByUser[player.UserId]
        self._partyByUser[player.UserId] = nil
        self._inviteByUser[player.UserId] = nil
        if partyId ~= nil and self._parties[partyId] ~= nil then
            local remaining = self._partySession.leave(self._parties[partyId], player.UserId, now())
            self:_store(partyId, remaining)
        end
    end

    --[[
        Held in the one departing slot, not filed with the live rosters. A
        sealed party is read exactly once, by issueTickets a moment later, and
        adding it to `_parties` would grow that table by one entry per launch
        for the life of the server with nothing ever reading them again.
    ]]
    self._departing = sealed
    self._logger:info("party_departed", { partyId = sealed.partyId, size = #userIds })
    return sealed.partyId
end

--[[
    Write each traveller their way back.

    Called after the reserved server exists and before the teleport, because
    a profile is saved when its player leaves and a ticket written afterwards
    would be a ticket written to a profile nobody is holding.
]]
function PartyService.issueTickets(
    self: PartyService,
    partyId: string,
    boarding: { Player },
    accessCode: string
)
    local state = self._departing
    if state == nil or state.partyId ~= partyId then
        self._logger:warn("party_tickets_unissued", { partyId = partyId })
        return
    end
    -- The slot is spent whether or not every write lands. A departure is read
    -- once, and leaving it filled would hand the next launch's tickets to the
    -- party before it.
    self._departing = nil

    local issued = 0
    for _, player in boarding do
        local ticket, result =
            self._partySession.issueTicket(state, player.UserId, accessCode, now())
        if ticket == nil then
            self._logger:warn("party_ticket_refused", { reason = result.reason })
        elseif self._profileService:setRejoinTicket(player, ticket) then
            issued += 1
        else
            --[[
                A traveller who boards without a ticket has no way back and no
                sign that anything went wrong, which is the quietest failure
                in this whole wave. It is worth a line each rather than only
                a total, because the total looks fine until somebody counts.
            ]]
            self._logger:warn("party_ticket_unwritten", { partyId = partyId })
        end
    end
    self._logger:info(
        "party_tickets_issued",
        { partyId = partyId, issued = issued, boarded = #boarding }
    )
end

--[[
    Tell this server which party's run it is.

    Read from the teleport payload by LobbyService. Without it a member who
    dropped and came back to the same reserved server would be offered a
    rejoin into the world they are standing in, forever.
]]
function PartyService.adoptRun(self: PartyService, partyId: string)
    if self._runPartyId == nil then
        self._runPartyId = partyId
        self._logger:info("party_run_adopted", { partyId = partyId })
    end
end

function PartyService.rejoin(self: PartyService, player: Player): any
    local read = self._partySession.readTicket(
        self._profileService:rejoinTicket(player),
        now(),
        self._runPartyId
    )
    if not read.rejoin then
        if read.reason == "expired" then
            self._profileService:setRejoinTicket(player, nil)
            self:_toast(player, "THAT ROAD HAS GONE COLD — THE PLATFORM IS STILL HERE")
        else
            self:_toast(player, "THERE IS NOWHERE TO GO BACK TO")
        end
        return { accepted = false, reason = read.reason }
    end

    local placeId = game.PlaceId
    if placeId == 0 then
        -- Studio and unpublished builds cannot resolve a reserved server, the
        -- same limit the departure teleport lives with.
        self._logger:info("party_rejoin_skipped", { reason = "unpublished_place" })
        self:_toast(player, "THE ROAD BACK NEEDS A PUBLISHED WORLD")
        return { accepted = false, reason = "unpublished_place" }
    end

    local sent = pcall(function()
        TeleportService:TeleportToPrivateServer(placeId, read.accessCode, { player })
    end)
    if not sent then
        --[[
            The ticket is kept. A teleport can fail for a minute and succeed
            on the next press, and throwing away the only way back to punish a
            transient failure is the worse of the two mistakes. It expires on
            its own soon enough.
        ]]
        self._logger:warn("party_rejoin_failed", { partyId = read.partyId })
        self:_toast(player, "THE ROAD DID NOT OPEN — TRY AGAIN")
        return { accepted = false, reason = "teleport_failed" }
    end

    self._logger:info("party_rejoin_started", { partyId = read.partyId })
    return { accepted = true }
end

--[[
    What a client may be told about parties.

    Every field here is presentation. The rejoin half comes from
    PartySession.publicTicket rather than from the stored ticket, so the access
    code is absent by construction rather than by omission.
]]
function PartyService.snapshot(self: PartyService, player: Player): any
    local _, state = self:_partyOf(player)
    local inviteFrom: string? = nil
    local invitePartyId = self._inviteByUser[player.UserId]
    if invitePartyId ~= nil then
        local inviteState = self._parties[invitePartyId]
        local invite = self._partySession.pendingInvite(inviteState, player.UserId, now())
        if invite == nil then
            self._inviteByUser[player.UserId] = nil
        else
            local from = Players:GetPlayerByUserId(invite.fromUserId)
            inviteFrom = if from ~= nil then from.DisplayName else "SOMEONE"
        end
    end

    local leaderName: string? = nil
    if state ~= nil then
        local leader = Players:GetPlayerByUserId(state.leaderUserId)
        leaderName = if leader ~= nil then leader.DisplayName else nil
    end

    return {
        inParty = state ~= nil,
        size = self._partySession.size(state),
        leader = state ~= nil and state.leaderUserId == player.UserId,
        leaderName = leaderName,
        inviteFrom = inviteFrom,
        rejoin = self._partySession.publicTicket(
            self._profileService:rejoinTicket(player),
            now(),
            self._runPartyId
        ),
    }
end

function PartyService.Start(self: PartyService)
    Players.PlayerRemoving:Connect(function(player: Player)
        local partyId, state = self:_partyOf(player)
        if state ~= nil then
            self:_store(partyId :: string, self._partySession.leave(state, player.UserId, now()))
        end
        self._partyByUser[player.UserId] = nil
        self._inviteByUser[player.UserId] = nil
    end)

    --[[
        The offer is made once, when the profile is loaded, because that is
        the first moment the ticket can be read at all. It is a toast and a
        button rather than an automatic teleport: a player who deliberately
        left a run and came back to town should not be dragged out of it by
        the game deciding it knows better.
    ]]
    self._profileService:onLoaded(function(player: Player)
        local public = self._partySession.publicTicket(
            self._profileService:rejoinTicket(player),
            now(),
            self._runPartyId
        )
        if public == nil then
            return
        end
        self:_toast(
            player,
            string.format("YOUR PARTY OF %d IS STILL OUT THERE — REJOIN THEM", public.partySize)
        )
    end)
end

return PartyService
