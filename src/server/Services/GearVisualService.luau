--!strict

local Players = game:GetService("Players")

local GearVisualService = {}
GearVisualService.__index = GearVisualService
GearVisualService.Name = "GearVisualService"

local VISUAL_MODEL_NAME = "LastLightEquipmentVisuals"

local MATERIALS = {
    Fabric = Enum.Material.Fabric,
    Ground = Enum.Material.Ground,
    Wood = Enum.Material.Wood,
}

export type GearVisualService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: any,
        _profileService: any,
        _gearVisualPlan: any,
        _connections: { [Player]: RBXScriptConnection },
    },
    GearVisualService
))

function GearVisualService.new(
    logger: any,
    profileService: any,
    gearVisualPlan: any
): GearVisualService
    return setmetatable({
        Name = GearVisualService.Name,
        _logger = logger,
        _profileService = profileService,
        _gearVisualPlan = gearVisualPlan,
        _connections = {},
    }, GearVisualService)
end

local function targetFor(character: Model, targetName: string): BasePart?
    if targetName == "head" then
        return character:FindFirstChild("Head") :: BasePart?
    end
    if targetName == "RightHand" then
        for _, name in { "RightHand", "Right Arm" } do
            local candidate = character:FindFirstChild(name)
            if candidate ~= nil and candidate:IsA("BasePart") then
                return candidate
            end
        end
        return nil
    end
    --[[
        Torso and left hand exist because the armour lines use body, hands
        and charm slots. R15 and R6 name these differently, so each target
        is a list tried in order -- the same shape the feet have always
        used, for the same reason.
    ]]
    if targetName == "torso" then
        for _, name in { "UpperTorso", "Torso" } do
            local candidate = character:FindFirstChild(name)
            if candidate ~= nil and candidate:IsA("BasePart") then
                return candidate
            end
        end
        return nil
    end
    if targetName == "leftHand" then
        for _, name in { "LeftHand", "Left Arm" } do
            local candidate = character:FindFirstChild(name)
            if candidate ~= nil and candidate:IsA("BasePart") then
                return candidate
            end
        end
        return nil
    end
    local names = if targetName == "leftFoot"
        then { "LeftFoot", "LeftLowerLeg", "Left Leg" }
        else { "RightFoot", "RightLowerLeg", "Right Leg" }
    for _, name in names do
        local candidate = character:FindFirstChild(name)
        if candidate ~= nil and candidate:IsA("BasePart") then
            return candidate
        end
    end
    return nil
end

local function localFrame(plan: any, target: BasePart): CFrame
    local y = plan.offset[2]
    if plan.target ~= "head" and not string.find(target.Name, "Foot", 1, true) then
        y += -target.Size.Y * 0.5 + 0.42
    end
    return CFrame.new(plan.offset[1], y, plan.offset[3])
        * CFrame.Angles(
            math.rad(plan.rotation[1]),
            math.rad(plan.rotation[2]),
            math.rad(plan.rotation[3])
        )
end

local function buildPart(parent: Model, target: BasePart, plan: any): BasePart
    local visual = if plan.shape == "Wedge" then Instance.new("WedgePart") else Instance.new("Part")
    visual.Name = plan.name
    visual.Size = Vector3.new(plan.size[1], plan.size[2], plan.size[3])
    visual.Color = Color3.fromRGB(plan.color[1], plan.color[2], plan.color[3])
    visual.Material = MATERIALS[plan.material] or Enum.Material.SmoothPlastic
    if visual:IsA("Part") then
        visual.Shape = if plan.shape == "Cylinder"
            then Enum.PartType.Cylinder
            elseif plan.shape == "Ball" then Enum.PartType.Ball
            else Enum.PartType.Block
    end
    visual.Anchored = false
    visual.CanCollide = false
    visual.CanQuery = false
    visual.CanTouch = false
    visual.CastShadow = true
    visual.Massless = true
    visual.TopSurface = Enum.SurfaceType.Smooth
    visual.BottomSurface = Enum.SurfaceType.Smooth
    visual.CFrame = target.CFrame * localFrame(plan, target)
    visual.Parent = parent

    local weld = Instance.new("WeldConstraint")
    weld.Name = "EquipmentWeld"
    weld.Part0 = target
    weld.Part1 = visual
    weld.Parent = visual
    return visual
end

local function buildHeldPart(model: Model, target: BasePart, visual: BasePart)
    visual.Anchored = false
    visual.CanCollide = false
    visual.CanTouch = false
    visual.CanQuery = false
    visual.Massless = true
    visual.CastShadow = true
    visual.Parent = model
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = target
    weld.Part1 = visual
    weld.Parent = visual
end

function GearVisualService._refresh(self: GearVisualService, player: Player)
    local character = player.Character
    if character == nil or character.Parent == nil then
        return
    end

    local oldVisuals = character:FindFirstChild(VISUAL_MODEL_NAME)
    if oldVisuals ~= nil then
        oldVisuals:Destroy()
    end
    if not self._profileService:isLoaded(player) then
        return
    end

    local model = Instance.new("Model")
    model.Name = VISUAL_MODEL_NAME
    model.Archivable = false
    local equipped = self._profileService:equippedSnapshot(player)
    local visualPartCount = 0
    for slot, itemId in equipped do
        local itemPlan = self._gearVisualPlan.get(itemId)
        if itemPlan ~= nil and itemPlan.slot == slot then
            model:SetAttribute(string.format("%sItemId", slot), itemId)
            for _, partPlan in itemPlan.parts do
                local target = targetFor(character, partPlan.target)
                if target ~= nil then
                    buildPart(model, target, partPlan)
                    visualPartCount += 1
                end
            end
        end
    end
    --[[
        The held tool, in the hand that uses it.

        A strike used to happen with visibly empty hands. The selected starter
        tool (and the bow when one is equipped) is welded to the right hand as
        a small silhouette: enough to say what the character is holding at
        gameplay distance, cheap enough to rebuild on every respawn. The torch
        also actually lights -- its blurb says "lights the dark", and a claim
        on a plaque has to be true in play.
    ]]
    local rightHand = targetFor(character, "RightHand")
    -- The bow's visual comes from GearVisualPlan like every other equipment
    -- piece; only the starter tools are held here, because they are tutorial
    -- state rather than equipment. A weapon in the hand wins the hand.
    local heldId = if equipped.weapon ~= nil then nil else self._profileService:selectedTool(player)
    if rightHand ~= nil and heldId ~= nil then
        local hold = CFrame.new(0, -0.55, 0)
        if heldId == "axe" or heldId == "hammer" or heldId == "torch" then
            local handle = Instance.new("Part")
            handle.Name = "HeldToolHandle"
            handle.Size = Vector3.new(0.28, 2.4, 0.28)
            handle.Color = Color3.fromRGB(111, 76, 48)
            handle.Material = Enum.Material.Wood
            handle.CFrame = rightHand.CFrame * hold
            buildHeldPart(model, rightHand, handle)
            visualPartCount += 1
            if heldId == "axe" then
                local head = Instance.new("Part")
                head.Name = "HeldAxeHead"
                head.Size = Vector3.new(1.15, 0.5, 0.26)
                head.Color = Color3.fromRGB(154, 169, 174)
                head.Material = Enum.Material.Metal
                head.CFrame = rightHand.CFrame * hold * CFrame.new(0.35, 1.0, 0)
                buildHeldPart(model, rightHand, head)
                visualPartCount += 1
            elseif heldId == "hammer" then
                local head = Instance.new("Part")
                head.Name = "HeldHammerHead"
                head.Size = Vector3.new(1.05, 0.55, 0.55)
                head.Color = Color3.fromRGB(123, 132, 137)
                head.Material = Enum.Material.Metal
                head.CFrame = rightHand.CFrame * hold * CFrame.new(0, 1.05, 0)
                buildHeldPart(model, rightHand, head)
                visualPartCount += 1
            else
                local flame = Instance.new("Part")
                flame.Name = "HeldTorchFlame"
                flame.Size = Vector3.new(0.5, 0.9, 0.5)
                flame.Color = Color3.fromRGB(255, 158, 54)
                flame.Material = Enum.Material.Neon
                flame.CFrame = rightHand.CFrame * hold * CFrame.new(0, 1.35, 0)
                buildHeldPart(model, rightHand, flame)
                local glow = Instance.new("PointLight")
                glow.Color = Color3.fromRGB(255, 168, 82)
                glow.Brightness = 1.6
                glow.Range = 16
                glow.Shadows = false
                glow.Parent = flame
                visualPartCount += 1
            end
        end
    end
    model:SetAttribute("VisualPartCount", visualPartCount)
    model.Parent = character
end

function GearVisualService._bindPlayer(self: GearVisualService, player: Player)
    if self._connections[player] ~= nil then
        return
    end
    self._connections[player] = player.CharacterAdded:Connect(function()
        task.defer(function()
            self:_refresh(player)
        end)
    end)
    if player.Character ~= nil then
        task.defer(function()
            self:_refresh(player)
        end)
    end
end

--[[
    Public refresh: the tool yard calls this the moment a starter tool is
    chosen, so the tool appears in the hand at the pedestal rather than on the
    next respawn.
]]
function GearVisualService.refresh(self: GearVisualService, player: Player)
    task.defer(function()
        self:_refresh(player)
    end)
end

function GearVisualService.Init(self: GearVisualService)
    self._profileService:onLoaded(function(player: Player)
        self:_bindPlayer(player)
        self:_refresh(player)
    end)
    self._profileService:onEquipmentChanged(function(player: Player)
        self:_refresh(player)
    end)
end

function GearVisualService.Start(self: GearVisualService)
    Players.PlayerAdded:Connect(function(player: Player)
        self:_bindPlayer(player)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        local connection = self._connections[player]
        if connection ~= nil then
            connection:Disconnect()
            self._connections[player] = nil
        end
    end)
    for _, player in Players:GetPlayers() do
        self:_bindPlayer(player)
    end
    self._logger:info("gear_visuals_started", {
        itemPlans = #self._gearVisualPlan.list(),
    })
end

return GearVisualService
