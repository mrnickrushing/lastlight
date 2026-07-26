--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EnemyService = {}
EnemyService.__index = EnemyService
EnemyService.Name = "EnemyService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

type Enemy = {
    model: Model,
    health: number,
    lastAttackAt: number,
}

export type EnemyService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _worldService: any,
        _survivalService: any,
        _active: Enemy?,
        _nightActive: boolean,
        _lanternHealth: number,
        _speed: number,
        _onChanged: ((string?) -> ())?,
        _heartbeat: RBXScriptConnection?,
    },
    EnemyService
))

local function enemyPart(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CastShadow = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function EnemyService.new(logger: Logger, worldService: any, survivalService: any): EnemyService
    return setmetatable({
        Name = EnemyService.Name,
        _logger = logger,
        _worldService = worldService,
        _survivalService = survivalService,
        _active = nil,
        _nightActive = false,
        _lanternHealth = 100,
        _speed = 7,
        _onChanged = nil,
        _heartbeat = nil,
    }, EnemyService)
end

function EnemyService.Init(_self: EnemyService, _context: any) end

function EnemyService.Start(self: EnemyService)
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        self:_step(deltaTime)
    end)
end

function EnemyService.setChangedHandler(self: EnemyService, callback: (string?) -> ())
    self._onChanged = callback
end

function EnemyService._notify(self: EnemyService, toast: string?)
    local callback = self._onChanged
    if callback ~= nil then
        callback(toast)
    end
end

function EnemyService.startNight(self: EnemyService)
    self._nightActive = true
    self._lanternHealth = 100
    self._speed = 7
    self:_notify(nil)
end

function EnemyService.stopNight(self: EnemyService)
    self._nightActive = false
    local active = self._active
    if active ~= nil then
        active.model:Destroy()
        self._active = nil
    end
    self._lanternHealth = 100
    self:_notify(nil)
end

function EnemyService.spawn(self: EnemyService): boolean
    if not self._nightActive or self._active ~= nil then
        return false
    end

    local model = Instance.new("Model")
    model.Name = "RootlingScout"
    model:SetAttribute("EnemyId", "enemy_bramblewake_rootling")
    local origin = self._worldService:enemySpawnPosition()

    local core = enemyPart(
        model,
        "RootCore",
        Vector3.new(4.5, 5.4, 3.4),
        CFrame.new(origin),
        Color3.fromRGB(25, 29, 27),
        Enum.Material.Wood
    )
    core.Shape = Enum.PartType.Ball
    model.PrimaryPart = core

    local crown = enemyPart(
        model,
        "BrambleCrown",
        Vector3.new(5.4, 2.1, 2.6),
        CFrame.new(origin + Vector3.new(0, 3.2, 0)),
        Color3.fromRGB(39, 49, 39),
        Enum.Material.Grass
    )
    crown.Shape = Enum.PartType.Ball

    for side = -1, 1, 2 do
        enemyPart(
            model,
            "RootArm",
            Vector3.new(1.1, 5.5, 1.1),
            CFrame.new(origin + Vector3.new(side * 2.5, 0.2, 0))
                * CFrame.Angles(0, 0, math.rad(side * 28)),
            Color3.fromRGB(49, 40, 32),
            Enum.Material.Wood
        )
        local eye = enemyPart(
            model,
            "Eye",
            Vector3.new(0.58, 0.58, 0.35),
            CFrame.new(origin + Vector3.new(side * 0.72, 0.8, -1.62)),
            Color3.fromRGB(255, 114, 75),
            Enum.Material.Neon
        )
        eye.Shape = Enum.PartType.Ball
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ThreatOutline"
    highlight.FillColor = Color3.fromRGB(80, 29, 29)
    highlight.FillTransparency = 0.68
    highlight.OutlineColor = Color3.fromRGB(255, 119, 79)
    highlight.OutlineTransparency = 0.18
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model

    model:PivotTo(CFrame.lookAt(origin, self._worldService:lanternPosition()))
    model.Parent = workspace
    self._active = {
        model = model,
        health = 100,
        lastAttackAt = 0,
    }
    self._logger:info("rootling_spawned")
    self:_notify("A ROOTLING ENTERS THE TRAIL")
    return true
end

function EnemyService._step(self: EnemyService, deltaTime: number)
    local enemy = self._active
    if not self._nightActive or enemy == nil or enemy.model.Parent == nil then
        return
    end

    local current = enemy.model:GetPivot()
    local now = os.clock()
    local closestPlayer = nil
    local closestDistance = math.huge
    if enemy.model.PrimaryPart ~= nil then
        for _, player in Players:GetPlayers() do
            local root = if player.Character == nil
                then nil
                else player.Character:FindFirstChild("HumanoidRootPart")
            if root ~= nil and root:IsA("BasePart") and self._survivalService:canAct(player) then
                local distance = (root.Position - enemy.model.PrimaryPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    if closestPlayer ~= nil and closestDistance <= 8 and now - enemy.lastAttackAt >= 1.5 then
        enemy.lastAttackAt = now
        local result = self._survivalService:damage(closestPlayer, 24, "enemy_bramblewake_rootling")
        if result.downed then
            self:_notify("ALLY DOWN — ROOTLING STRIKE")
        elseif result.applied then
            self:_notify("ROOTLING STRIKE — FIND COVER")
        end
        return
    end

    local target = self._worldService:lanternPosition()
    local flatTarget = Vector3.new(target.X, current.Position.Y, target.Z)
    local delta = flatTarget - current.Position

    if delta.Magnitude > 10 then
        local distance = math.min(delta.Magnitude, self._speed * deltaTime)
        local nextPosition = current.Position + delta.Unit * distance
        enemy.model:PivotTo(CFrame.lookAt(nextPosition, flatTarget))
        return
    end

    if now - enemy.lastAttackAt >= 1.5 then
        enemy.lastAttackAt = now
        self._lanternHealth = math.max(0, self._lanternHealth - 6)
        if self._lanternHealth <= 0 then
            self._lanternHealth = 18
            enemy.model:Destroy()
            self._active = nil
            self:_notify("THE LIGHT FLICKERS — MARA RESTORES A SPARK")
        else
            self:_notify(nil)
        end
    end
end

function EnemyService.damageNearest(self: EnemyService, player: Player): (boolean, string)
    if not self._nightActive then
        return false, "The tool is calm in daylight."
    end
    if not self._survivalService:canAct(player) then
        return false, "You cannot strike while downed."
    end

    local enemy = self._active
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    if
        enemy == nil
        or root == nil
        or not root:IsA("BasePart")
        or enemy.model.PrimaryPart == nil
    then
        return false, "No Rootling is close enough."
    end

    local distance = (root.Position - enemy.model.PrimaryPart.Position).Magnitude
    if distance > 20 then
        return false, "Move closer to the Rootling."
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { character :: Model }
    local result = workspace:Raycast(
        root.Position,
        enemy.model.PrimaryPart.Position - root.Position,
        raycastParams
    )
    if result ~= nil and not result.Instance:IsDescendantOf(enemy.model) then
        return false, "The Rootling is behind cover."
    end

    enemy.health -= 34
    if enemy.health <= 0 then
        enemy.model:Destroy()
        self._active = nil
        self._logger:info("rootling_defeated", { player = player.UserId })
        self:_notify("ROOTLING DRIVEN BACK")
        return true, "Rootling driven back!"
    end

    self:_notify("HIT — ROOTLING " .. tostring(math.max(0, enemy.health)) .. "%")
    return true, "Your tool strikes the Rootling."
end

function EnemyService.setBreach(self: EnemyService)
    self._speed = 9.5
    self:_notify("THE ROOTS SURGE — HOLD THE LIGHT")
end

function EnemyService.lanternHealth(self: EnemyService): number
    return self._lanternHealth
end

function EnemyService.activeCount(self: EnemyService): number
    return if self._active == nil then 0 else 1
end

return table.freeze(EnemyService)
