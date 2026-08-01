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
