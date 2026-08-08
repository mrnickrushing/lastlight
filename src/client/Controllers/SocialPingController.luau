--!strict

--[[
    Draw what somebody said where they said it.

    There is deliberately no call log on the HUD, and that is a decision about
    a phone rather than an omission. The owner plays this game in portrait, and
    a portrait canvas is about five hundred points wide with the objective card
    across the top, the lantern bar under it and the thumb cluster along the
    bottom; the band left over is the band a player is trying to see creatures
    in. #325's report was literally that the fight UI hid the monsters. A
    scrolling list of who said what would be one more thing in front of the
    world.

    So a call is drawn in the world instead, which is also where it means
    something:

      * A phrase that marks a place gets a card standing at that place, with
        the sender's name, the phrase, and how far away it is. The place came
        from the server reading the sender's character, so the card cannot
        stand anywhere the sender was not.
      * A phrase that marks nothing -- the six courtesies -- gets a card over
        the speaker's own head for its few seconds. Speech belongs to a person,
        not to a spot on the ground.

    How a card looks is resolved from the catalog by the ping kind the server
    named, not chosen here by that name. The difference matters: a `if kind ==
    "danger" then red` ladder is a ladder a twenty-fifth phrase's new kind falls
    off silently, which is the census's lesson in its smallest possible form.
    Glyph, colour and reach all come out of QuickChat.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local QuickChat = require(ReplicatedStorage:WaitForChild("LastLight").QuickChat)

local SocialPingController = {}
SocialPingController.__index = SocialPingController

export type SocialPingController = typeof(setmetatable(
    {} :: {
        _folder: Folder,
        -- Keyed by call id, which the server mints once and never reuses, so a
        -- card is built once and then only re-read for its distance.
        _cards: { [string]: { billboard: BillboardGui, anchor: Part?, call: any, glyph: string } },
        _connection: RBXScriptConnection?,
    },
    SocialPingController
))

local INK = Color3.fromRGB(18, 14, 11)

function SocialPingController.new(): SocialPingController
    local folder = Instance.new("Folder")
    folder.Name = "LastLightSocialPings"
    folder.Parent = workspace

    local self = setmetatable({
        _folder = folder,
        _cards = {},
        _connection = nil,
    }, SocialPingController)
    self._connection = RunService.RenderStepped:Connect(function()
        self:_step()
    end)
    return self
end

local function presentationOf(call: any): (Color3, string)
    local kind = QuickChat.pingKind(call.ping)
    if kind == nil then
        -- A kind the catalog does not know cannot be drawn honestly, so it is
        -- drawn plainly rather than guessed at.
        return Color3.fromRGB(200, 208, 202), "·"
    end
    return Color3.fromRGB(kind.colour[1], kind.colour[2], kind.colour[3]), kind.glyph
end

--[[
    Where a card hangs.

    A marking call gets an invisible anchor at the recorded position. A
    courtesy is adorned to the speaker's head, and if that player has left --
    or has no character yet -- it is simply not drawn: a thank-you from
    somebody who is gone is nothing, and inventing a place for it would be the
    one case where a card stands somewhere nobody stood.
]]
function SocialPingController._build(self: SocialPingController, call: any): boolean
    local adornee: Instance? = nil
    local anchor: Part? = nil
    if call.marks == true and call.x ~= nil then
        local part = Instance.new("Part")
        part.Name = "PingAnchor_" .. tostring(call.id)
        part.Size = Vector3.new(0.2, 0.2, 0.2)
        part.Transparency = 1
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Position = Vector3.new(call.x, call.y, call.z)
        part.Parent = self._folder
        anchor = part
        adornee = part
    else
        local speaker = Players:GetPlayerByUserId(call.fromUserId)
        local character = if speaker ~= nil then speaker.Character else nil
        local head = if character ~= nil then character:FindFirstChild("Head") else nil
        if head == nil or not head:IsA("BasePart") then
            return false
        end
        adornee = head
    end

    local accent, glyph = presentationOf(call)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SocialPing_" .. tostring(call.id)
    billboard.Adornee = adornee
    billboard.AlwaysOnTop = call.marks == true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.fromOffset(198, 50)
    billboard.StudsOffsetWorldSpace = if call.marks == true
        then Vector3.new(0, 6.5, 0)
        else Vector3.new(0, 2.4, 0)
    -- A marker is guidance and has to be readable from across a module; a
    -- courtesy is a nearby remark and does not need to carry.
    billboard.MaxDistance = if call.marks == true then 500 else 90
    billboard.Parent = if anchor ~= nil then anchor else self._folder

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.BackgroundColor3 = INK
    card.BackgroundTransparency = 0.14
    card.BorderSizePixel = 0
    card.Size = UDim2.fromScale(1, 1)
    card.Parent = billboard
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = accent
    cardStroke.Transparency = 0.28
    cardStroke.Thickness = 1.5
    cardStroke.Parent = card

    local phrase = Instance.new("TextLabel")
    phrase.Name = "PhraseText"
    phrase.BackgroundTransparency = 1
    phrase.Position = UDim2.fromOffset(0, 4)
    phrase.Size = UDim2.new(1, 0, 0, 24)
    phrase.Font = Enum.Font.GothamBold
    phrase.TextSize = 15
    phrase.TextColor3 = accent
    phrase.TextScaled = false
    phrase.Text = string.format("%s %s", glyph, tostring(call.text))
    phrase.Parent = card

    local who = Instance.new("TextLabel")
    who.Name = "Sender"
    who.BackgroundTransparency = 1
    who.Position = UDim2.fromOffset(0, 27)
    who.Size = UDim2.new(1, 0, 0, 18)
    who.Font = Enum.Font.Gotham
    who.TextSize = 12
    who.TextColor3 = Color3.fromRGB(200, 208, 202)
    who.Text = tostring(call.fromName)
    who.Parent = card

    self._cards[call.id] = { billboard = billboard, anchor = anchor, call = call, glyph = glyph }
    return true
end

function SocialPingController._destroy(self: SocialPingController, callId: string)
    local card = self._cards[callId]
    if card == nil then
        return
    end
    self._cards[callId] = nil
    if card.anchor ~= nil then
        card.anchor:Destroy()
    else
        card.billboard:Destroy()
    end
end

--[[
    Take the two lists the server sends, and draw one card per entry.

    They are two lists because they answer two questions. `calls` is
    everything this player may hear -- the whole record, filtered for expiry
    and for who has blocked whom -- and the courtesies in it are drawn over
    their speakers. `pings` is the marking subset that is also close enough for
    a marker to be guidance rather than clutter; a shout from four hundred
    studs away is in `calls` and not in `pings`, which is exactly right: it was
    said, and there is no useful arrow to it.

    Additive and subtractive rather than a rebuild, because the snapshot
    arrives several times a second and rebuilding would make every card
    flicker. Same reasoning the objective markers already carry.

    **One card per speaker per surface, newest wins.** Found by playing it: the
    budget allows three calls in a burst, and three courtesies drew three
    billboards on the same head at the same offset -- one unreadable smear of
    stacked text. The same thing happens on the ground when somebody shouts
    twice without moving. Your latest ping replacing your previous one is also
    what every game with a ping wheel does, so the fix and the expectation
    agree. The rate limiter bounds how much is said; this bounds how much is
    drawn, and those are different problems.
]]
function SocialPingController.setCalls(self: SocialPingController, calls: { any }?, pings: { any }?)
    local present: { [string]: boolean } = {}
    local function take(list: { any }?, wantMarks: boolean)
        if type(list) ~= "table" then
            return
        end
        local newest: { [number]: any } = {}
        for _, call in list do
            if
                type(call) == "table"
                and type(call.id) == "string"
                and type(call.fromUserId) == "number"
                and (call.marks == true) == wantMarks
            then
                local held = newest[call.fromUserId]
                if held == nil or (tonumber(call.at) or 0) >= (tonumber(held.at) or 0) then
                    newest[call.fromUserId] = call
                end
            end
        end
        for _, call in newest do
            present[call.id] = true
            if self._cards[call.id] == nil then
                self:_build(call)
            end
        end
    end
    -- Courtesies from the full record, markers from the in-range subset. Taking
    -- markers from `calls` instead would draw a card for every shout on the
    -- map, which is the thing the radius exists to prevent.
    take(calls, false)
    take(pings, true)
    for callId in self._cards do
        if not present[callId] then
            self:_destroy(callId)
        end
    end
end

function SocialPingController._step(self: SocialPingController)
    local character = Players.LocalPlayer.Character
    local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
    if root == nil or not root:IsA("BasePart") then
        return
    end
    for _, card in self._cards do
        local anchor = card.anchor
        if anchor ~= nil then
            local label = card.billboard:FindFirstChild("PhraseText", true)
            if label ~= nil and label:IsA("TextLabel") then
                local distance = (anchor.Position - root.Position).Magnitude
                label.Text = string.format(
                    "%s %s · %dm",
                    card.glyph,
                    tostring(card.call.text),
                    math.floor(distance + 0.5)
                )
            end
        end
    end
end

function SocialPingController.destroy(self: SocialPingController)
    local connection = self._connection
    if connection ~= nil then
        connection:Disconnect()
        self._connection = nil
    end
    for callId in self._cards do
        self:_destroy(callId)
    end
    self._folder:Destroy()
end

return table.freeze(SocialPingController)
