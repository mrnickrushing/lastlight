--!strict

--[[
    Companions -- the M6 deliverable's first resident: the Beastkeeper's
    bonded briar hound, a persistent creature that walks beside its keeper
    rather than existing only for seven seconds of ability.

    v1 charter, deliberately bounded: the hound exists in town while its
    keeper wears the Beastkeeper profession, follows at the flank (or stays
    where told via the FOLLOW/STAY command), and has no combat role of its
    own -- the Briar Hound ability IS its combat moment, and the fiction is
    now whole: the creature you send at the night was at your side all day.
    It does not enter Bramblewake yet; expedition pathing is a live-tested
    wave, not a blind one.

    Movement is the same anchored PivotTo stepping every night creature
    uses -- no Humanoid, no physics, no pathfinding debt -- with the pure
    math in CompanionMotion where the specs can reach it.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)

local CompanionService = {}
CompanionService.__index = CompanionService
CompanionService.Name = "CompanionService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

type Companion = {
    model: Model,
    position: Vector3,
    mode: string, -- "follow" | "stay"
    bobPhase: number,
}

export type CompanionService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _companionMotion: any,
        _companions: { [Player]: Companion },
        _heartbeat: RBXScriptConnection?,
    },
    CompanionService
))

local HOUND_RUSSET = Color3.fromRGB(146, 94, 52)
local HOUND_DARK = Color3.fromRGB(96, 62, 36)
local HOUND_EYE = Color3.fromRGB(94, 206, 176)

function CompanionService.new(logger: Logger, companionMotion: any): CompanionService
    return setmetatable({
        Name = CompanionService.Name,
        _logger = logger,
        _companionMotion = companionMotion,
        _companions = {},
        _heartbeat = nil,
    }, CompanionService)
end

function CompanionService.Init(_self: CompanionService, _context: any) end

local function buildHound(): Model
    local model = Instance.new("Model")
    model.Name = "BriarHound"

    local function part(name: string, size: Vector3, offset: CFrame, color: Color3): Part
        local piece = Instance.new("Part")
        piece.Name = name
        piece.Size = size
        piece.CFrame = offset
        piece.Color = color
        piece.Material = Enum.Material.Wood
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = true
        piece.Parent = model
        return piece
    end

    -- A hound readable at gameplay distance: long low body, forward head
    -- with bright eyes, four legs, an up-curled tail. Bramble growing along
    -- the spine keeps it this forest's creature rather than a generic dog.
    local body = part("Body", Vector3.new(1.4, 1.2, 3), CFrame.new(0, 1.35, 0), HOUND_RUSSET)
    part("Head", Vector3.new(1.05, 0.95, 1.15), CFrame.new(0, 1.95, -1.85), HOUND_RUSSET)
    part("Snout", Vector3.new(0.6, 0.45, 0.6), CFrame.new(0, 1.75, -2.6), HOUND_DARK)
    for side = -1, 1, 2 do
        part(
            "Ear",
            Vector3.new(0.22, 0.55, 0.34),
            CFrame.new(side * 0.36, 2.55, -1.8) * CFrame.Angles(0, 0, side * 0.18),
            HOUND_DARK
        )
        local eye = part(
            "Eye",
            Vector3.new(0.16, 0.16, 0.1),
            CFrame.new(side * 0.26, 2.05, -2.42),
            HOUND_EYE
        )
        eye.Material = Enum.Material.Neon
        for legZ = -1, 1, 2 do
            part(
                "Leg",
                Vector3.new(0.38, 1.05, 0.38),
                CFrame.new(side * 0.5, 0.55, legZ * 1.1),
                HOUND_DARK
            )
        end
    end
    part(
        "Tail",
        Vector3.new(0.3, 1.1, 0.3),
        CFrame.new(0, 2.1, 1.6) * CFrame.Angles(math.rad(-32), 0, 0),
        HOUND_RUSSET
    )
    for index = -1, 1 do
        part(
            "SpineBramble",
            Vector3.new(0.28, 0.5, 0.28),
            CFrame.new(index * 0.15, 2.1, index * 0.85) * CFrame.Angles(0, 0, index * 0.3),
            Color3.fromRGB(74, 96, 46)
        )
    end
    model.PrimaryPart = body
    return model
end

function CompanionService._dismiss(self: CompanionService, player: Player)
    local companion = self._companions[player]
    if companion == nil then
        return
    end
    if companion.model.Parent ~= nil then
        companion.model:Destroy()
    end
    self._companions[player] = nil
end

local function keeperRoot(player: Player): BasePart?
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    return if root ~= nil and root:IsA("BasePart") then root else nil
end

local function eligible(player: Player): boolean
    return player:GetAttribute("LastLightProfessionId") == "profession_beastkeeper"
        and player:GetAttribute("LastLightInExpedition") ~= true
        and player:GetAttribute("LastLightDowned") ~= true
end

function CompanionService._summon(self: CompanionService, player: Player)
    local root = keeperRoot(player)
    if root == nil then
        return
    end
    local model = buildHound()
    local side, back = self._companionMotion.followOffset()
    local start = (root.CFrame * CFrame.new(side, 0, back)).Position
    start = Vector3.new(start.X, root.Position.Y - 1.5, start.Z)
    model:PivotTo(CFrame.new(start))
    model.Parent = workspace
    self._companions[player] = {
        model = model,
        position = start,
        mode = "follow",
        bobPhase = 0,
    }
    self._logger:info("companion_summoned", { player = player.UserId })
end

function CompanionService.command(self: CompanionService, player: Player, mode: any): any
    local companion = self._companions[player]
    if companion == nil then
        return { accepted = false, message = Strings.get("toast.your_hound_is_not_with_you") }
    end
    if mode ~= "follow" and mode ~= "stay" then
        return { accepted = false, message = Strings.get("toast.the_hound_tilts_its_head") }
    end
    companion.mode = mode
    self._logger:info("companion_commanded", { player = player.UserId, mode = mode })
    return {
        accepted = true,
        message = if mode == "stay"
            then Strings.get("toast.the_hound_settles_and_waits")
            else Strings.get("toast.the_hound_falls_in"),
    }
end

--[[
    What the HUD needs to know: whether this player has a hound at all, and
    what it was last told. The client renders the order button from this
    rather than guessing from the profession, so a keeper whose hound has
    not been summoned yet sees no button.
]]
function CompanionService.snapshot(self: CompanionService, player: Player): any
    local companion = self._companions[player]
    if companion == nil then
        return { present = false, mode = "follow" }
    end
    return { present = true, mode = companion.mode }
end

function CompanionService._step(self: CompanionService, deltaTime: number)
    for _, player in Players:GetPlayers() do
        local companion = self._companions[player]
        if eligible(player) then
            if companion == nil then
                self:_summon(player)
                companion = self._companions[player]
            end
        elseif companion ~= nil then
            self:_dismiss(player)
            companion = nil
        end
        local root = keeperRoot(player)
        if companion ~= nil and root ~= nil and companion.model.Parent ~= nil then
            local moving = false
            if companion.mode == "follow" then
                local side, back = self._companionMotion.followOffset()
                local target = (root.CFrame * CFrame.new(side, 0, back)).Position
                local nx, nz
                nx, nz, moving = self._companionMotion.step(
                    companion.position.X,
                    companion.position.Z,
                    target.X,
                    target.Z,
                    deltaTime
                )
                companion.position = Vector3.new(nx, companion.position.Y, nz)
            end
            companion.bobPhase += deltaTime * (if moving then 9 else 2.2)
            local bob = math.sin(companion.bobPhase) * (if moving then 0.16 else 0.05)
            local faceTarget = if companion.mode == "follow"
                then Vector3.new(root.Position.X, companion.position.Y, root.Position.Z)
                else companion.position + companion.model:GetPivot().LookVector
            if (faceTarget - companion.position).Magnitude <= 0.05 then
                faceTarget = companion.position + Vector3.new(0, 0, -1)
            end
            companion.model:PivotTo(
                CFrame.lookAt(companion.position + Vector3.new(0, bob, 0), faceTarget)
            )
        end
    end
end

function CompanionService.Start(self: CompanionService)
    Players.PlayerRemoving:Connect(function(player: Player)
        self:_dismiss(player)
    end)
    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.05 then
            return
        end
        local elapsed = accumulator
        accumulator = 0
        self:_step(elapsed)
    end)
end

return table.freeze(CompanionService)
