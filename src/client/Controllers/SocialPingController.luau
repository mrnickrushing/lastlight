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

local function decorate(part: BasePart, colour: Color3, transparency: number)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = colour
    part.Transparency = transparency
end

--[[
    Where the floor is under a recorded position.

    The position the server sends is a character's HumanoidRootPart, which on
    an R15 rig stands about three studs above whatever it is standing on. A
    ring drawn at that height is a ring floating at hip level, which the first
    live look caught immediately: the disc cut through the player's shins. So
    the client casts down for the actual surface, which also puts the mark on
    the slope rather than through it.

    The fall back is the root's own height minus three rather than the root
    itself: if the cast finds nothing -- over a gap, mid-fall -- a ring at
    ankle height is wrong by less than a ring at the hip. Ignoring the ping
    folder keeps a mark from seating on the mark before it.
]]
local function groundBelow(folder: Folder, position: Vector3): number
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = { folder, Players.LocalPlayer.Character :: any }
    parameters.IgnoreWater = false
    local hit =
        workspace:Raycast(position + Vector3.new(0, 1, 0), Vector3.new(0, -14, 0), parameters)
    if hit ~= nil then
        return hit.Position.Y
    end
    return position.Y - 3
end

--[[
    The mark itself, as geometry.

    VISUAL_QUALITY_STANDARD is explicit that floating labels are close-range
    confirmation and not navigation, and a ping is navigation -- it exists to
    be walked to. A text card alone is 198 pixels that shrink to nothing at the
    far end of the marker's own five-hundred-stud reach, which is exactly the
    range at which it has to do its job.

    So the marker is a ring on the ground and a shaft of light standing out of
    it, in the ping kind's own colour, and the card rides above as the
    close-range half. Two parts because that is what reads: the ring says where
    on the floor, the shaft says which direction from anywhere, and a single
    shape cannot do both. The colour is the catalog's, so a new ping kind is
    coloured correctly without this file learning its name.
]]
function SocialPingController._buildMark(folder: Folder, anchor: Part, colour: Color3)
    local floor = groundBelow(folder, anchor.Position)
    local base = Vector3.new(anchor.Position.X, floor + 0.08, anchor.Position.Z)

    local ring = Instance.new("Part")
    ring.Name = "Ring"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.25, 6, 6)
    -- A Roblox cylinder lies on its side, so a disc on the floor is one turned
    -- a quarter over. The same quarter turn the town's props needed in #316.
    ring.CFrame = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90))
    decorate(ring, colour, 0.45)
    ring.Parent = anchor

    local shaft = Instance.new("Part")
    shaft.Name = "Shaft"
    shaft.Size = Vector3.new(0.55, 13, 0.55)
    shaft.CFrame = CFrame.new(base + Vector3.new(0, 6.5, 0))
    -- Fainter than the ring: a beam a player looks straight through is a beam
    -- that does not hide the thing being pointed at, which for HARVEST HERE is
    -- the entire point of the ping.
    decorate(shaft, colour, 0.62)
    shaft.Parent = anchor

    local glow = Instance.new("PointLight")
    glow.Color = colour
    glow.Brightness = 1.4
    glow.Range = 14
    glow.Shadows = false
    glow.Parent = ring
end

--[[
    Where a card hangs.

    A marking call gets an anchor at the recorded position, carrying the mark
    above. A courtesy is adorned to the speaker's head and gets no geometry at
    all -- speech is close range, which is the one case the standard says a
    floating label is the right answer for. If that player has left, or has no
    character yet, it is simply not drawn: a thank-you from somebody who is
    gone is nothing, and inventing a place for it would be the one case where a
    card stands somewhere nobody stood.
]]
function SocialPingController._build(self: SocialPingController, call: any): boolean
    local adornee: Instance? = nil
    local anchor: Part? = nil
    local accent, glyph = presentationOf(call)
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
        SocialPingController._buildMark(self._folder, part, accent)
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
