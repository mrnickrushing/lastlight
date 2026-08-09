--!strict

--[[
    Defense plots -- the M6 deliverable that turns "place defenses" from a
    dusk-phase promise in the GDD into something a player can actually do.

    Three snare plots stand in town, one per approach lane, always visible
    so dusk preparation is legible. Arming one is a tap on the plot's stake
    (a ClickDetector -- the same server-authoritative touch pattern strikes
    use, so no new client payload exists to get past ActionPayloadContract)
    and costs materials, spent atomically through the profile. An armed
    plot holds two bites; when a night enemy walks into the trigger ring,
    the snare takes a charge and holds the enemy with the same snaredUntil
    timer the Foxfire Sling uses -- which also means the "exposed" x1.2
    strike reaction from the status system applies. The systems already
    knew each other; the trap just introduces them at a place of the
    player's choosing.

    Resident defenders, v1: on solo nights only (the GDD's "solo players
    receive stronger resident support"), a Watch resident stands at the
    Meadow Gate plot and chips the active enemy when it passes -- softening,
    never finishing, so every defeat still belongs to the player.
]]

local RunService = game:GetService("RunService")

local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)
local TerrainBuilder = require(script.Parent.Parent.World.TerrainBuilder)

local DefenseService = {}
DefenseService.__index = DefenseService
DefenseService.Name = "DefenseService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

type Plot = {
    laneId: string,
    displayName: string,
    position: Vector3,
    model: Model,
    ember: Part,
    charges: number,
    quietUntil: number,
}

export type DefenseService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _defenseLanes: any,
        _extractionPayoff: any,
        _worldService: any,
        _enemyService: any,
        _profileService: any,
        _config: any,
        _plots: { [string]: Plot },
        _toastHandler: ((Player?, string) -> ())?,
        _nightActive: boolean,
        _watchDefender: Model?,
        _watchPosition: Vector3?,
        _nextChipAt: number,
        _heartbeat: RBXScriptConnection?,
    },
    DefenseService
))

local EMBER_ARMED = Color3.fromRGB(255, 170, 66)
local EMBER_COLD = Color3.fromRGB(64, 52, 40)
local STONE = Color3.fromRGB(112, 108, 100)
local STAKE_WOOD = Color3.fromRGB(94, 66, 40)
local WATCH_COAT = Color3.fromRGB(52, 74, 92)

function DefenseService.new(
    logger: Logger,
    defenseLanes: any,
    worldService: any,
    enemyService: any,
    profileService: any,
    config: any,
    extractionPayoff: any
): DefenseService
    return setmetatable({
        Name = DefenseService.Name,
        _logger = logger,
        _defenseLanes = defenseLanes,
        _extractionPayoff = extractionPayoff,
        _worldService = worldService,
        _enemyService = enemyService,
        _profileService = profileService,
        _config = config,
        _plots = {},
        _toastHandler = nil,
        _nightActive = false,
        _watchDefender = nil,
        _watchPosition = nil,
        _nextChipAt = 0,
        _heartbeat = nil,
    }, DefenseService)
end

function DefenseService.Init(_self: DefenseService, _context: any) end

function DefenseService.setToastHandler(self: DefenseService, handler: (Player?, string) -> ())
    self._toastHandler = handler
end

function DefenseService._toast(self: DefenseService, player: Player?, message: string)
    local handler = self._toastHandler
    if handler ~= nil then
        handler(player, message)
    end
end

local function makePart(
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    parent: Model
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
    part.Parent = parent
    return part
end

--[[
    A snare plot readable at a glance: a low ring of stones around a
    leaning stake, with an ember lamp that is cold until armed. The stake
    carries the ArmClick detector; on touch, tapping the stake IS the
    arming gesture, same as tapping a night creature is the strike.
]]
function DefenseService._buildPlot(self: DefenseService, lane: any, position: Vector3): Plot
    local model = Instance.new("Model")
    model.Name = "DefensePlot_" .. lane.id

    for index = 0, 5 do
        local angle = index * math.pi / 3
        local offset = Vector3.new(math.cos(angle) * 4.4, 0.35, math.sin(angle) * 4.4)
        makePart(
            "RingStone",
            Vector3.new(1.4, 0.8, 1.1),
            CFrame.new(position + offset) * CFrame.Angles(0, angle, 0),
            STONE,
            Enum.Material.Slate,
            model
        )
    end
    local stake = makePart(
        "Stake",
        Vector3.new(0.7, 4.6, 0.7),
        CFrame.new(position + Vector3.new(0, 2.3, 0)) * CFrame.Angles(0, 0, math.rad(6)),
        STAKE_WOOD,
        Enum.Material.Wood,
        model
    )
    stake.CanQuery = true
    local ember = makePart(
        "Ember",
        Vector3.new(0.9, 0.9, 0.9),
        CFrame.new(position + Vector3.new(0, 4.9, 0)),
        EMBER_COLD,
        Enum.Material.Neon,
        model
    )
    model.PrimaryPart = stake

    local click = Instance.new("ClickDetector")
    click.Name = "ArmClick"
    click.MaxActivationDistance = 42
    click.CursorIcon = ""
    click.Parent = stake
    click.MouseClick:Connect(function(clicker: Player)
        self:_armAttempt(clicker, lane.id)
    end)

    model.Parent = workspace
    return {
        laneId = lane.id,
        displayName = lane.displayName,
        position = position,
        model = model,
        ember = ember,
        charges = 0,
        quietUntil = 0,
    }
end

function DefenseService._buildPlots(self: DefenseService)
    local lantern = self._worldService:lanternPosition()
    local spawn = self._worldService:enemySpawnPosition()
    for _, lane in self._defenseLanes.list() do
        local px, pz = self._defenseLanes.plotPoint(lane, spawn.X, spawn.Z, lantern.X, lantern.Z)
        local position = Vector3.new(px, TerrainBuilder.surfaceHeight(px, pz), pz)
        self._plots[lane.id] = self:_buildPlot(lane, position)
    end
    self._logger:info("defense_plots_built", { lanes = #self._defenseLanes.list() })
end

-- The snare's price, in the materials' own words. Upper-casing an id and
-- swapping its underscores for spaces reads correctly for most of the catalog
-- and lies about the rest -- SHIPS IRON for SHIP'S IRON -- so the label comes
-- from the one place that holds it.
local function costLine(extractionPayoff: any, cost: { [string]: number }): string
    local parts = {}
    for _, entry in extractionPayoff.summarize(cost) do
        table.insert(parts, string.format("%d %s", entry.amount, entry.label))
    end
    return table.concat(parts, " AND ")
end

function DefenseService._armAttempt(self: DefenseService, player: Player, laneId: string)
    local plot = self._plots[laneId]
    if plot == nil then
        return
    end
    if player:GetAttribute("LastLightInExpedition") == true then
        return
    end
    if player:GetAttribute("LastLightDowned") == true then
        return
    end
    if plot.charges > 0 then
        self:_toast(
            player,
            string.format(Strings.get("toast.the_n_snare_is_already_set"), plot.displayName)
        )
        return
    end
    local trap = self._defenseLanes.Trap
    local result = self._profileService:spendMaterials(player, trap.armCost)
    if result.applied ~= true then
        self:_toast(
            player,
            string.format(
                Strings.get("toast.setting_the_snare_takes_n"),
                costLine(self._extractionPayoff, trap.armCost)
            )
        )
        return
    end
    plot.charges = trap.charges
    plot.ember.Color = EMBER_ARMED
    self._logger:info("defense_trap_armed", {
        lane = laneId,
        player = player.UserId,
    })
    self:_toast(
        player,
        string.format(Strings.get("toast.the_n_snare_is_set_n"), plot.displayName, trap.charges)
    )
end

function DefenseService.plotSnapshot(self: DefenseService): { [string]: number }
    local charges = {}
    for laneId, plot in self._plots do
        charges[laneId] = plot.charges
    end
    return charges
end

local function buildWatchDefender(position: Vector3): Model
    local model = Instance.new("Model")
    model.Name = "WatchDefender"
    local body = makePart(
        "Body",
        Vector3.new(1.6, 2.4, 1),
        CFrame.new(position + Vector3.new(0, 2.2, 0)),
        WATCH_COAT,
        Enum.Material.Fabric,
        model
    )
    makePart(
        "Head",
        Vector3.new(0.9, 0.9, 0.9),
        CFrame.new(position + Vector3.new(0, 3.85, 0)),
        Color3.fromRGB(214, 178, 148),
        Enum.Material.SmoothPlastic,
        model
    )
    makePart(
        "Pike",
        Vector3.new(0.25, 6.4, 0.25),
        CFrame.new(position + Vector3.new(1.1, 3.2, 0)) * CFrame.Angles(0, 0, math.rad(-8)),
        STAKE_WOOD,
        Enum.Material.Wood,
        model
    )
    local lamp = makePart(
        "Lamp",
        Vector3.new(0.5, 0.5, 0.5),
        CFrame.new(position + Vector3.new(1.55, 5.9, 0)),
        EMBER_ARMED,
        Enum.Material.Neon,
        model
    )
    lamp.CanQuery = false
    model.PrimaryPart = body
    return model
end

function DefenseService.onNightStarted(self: DefenseService, partySize: number)
    self._nightActive = true
    self._nextChipAt = 0
    if partySize ~= 1 then
        return
    end
    local plot = self._plots["lane_meadow_gate"]
    if plot == nil then
        return
    end
    local position = plot.position + Vector3.new(3.4, 0, 3.4)
    self._watchDefender = buildWatchDefender(position)
    self._watchPosition = position
    if self._watchDefender ~= nil then
        self._watchDefender.Parent = workspace
    end
    self._logger:info("defense_watch_posted", { lane = plot.laneId })
    self:_toast(nil, Strings.get("toast.the_watch_stands_with_you_at"))
end

function DefenseService.onNightEnded(self: DefenseService)
    self._nightActive = false
    if self._watchDefender ~= nil then
        self._watchDefender:Destroy()
        self._watchDefender = nil
        self._watchPosition = nil
    end
end

function DefenseService._step(self: DefenseService, now: number)
    --[[
        A lit snare bites whatever walks its ring, on any night.

        This used to gate on the service's own night flag, which only
        TownNightService raises -- so through the tutorial's first night
        the three plots stood there armed, with creatures walking straight
        through their rings, and nothing could ever happen. Watched it
        happen in Studio: the ember stayed lit, both charges intact, while
        a rootling, a briarback and a hollow zombie walked the Meadow Gate.

        The enemy service's own answer is the better source of truth: it
        returns a position only while a night is running and something is
        actually on the field, which is exactly the condition a trap cares
        about. The night flag stays for the Watch defender below, which
        genuinely is a town-night affair (it needs the party census).
    ]]
    local ex, ez = self._enemyService:activeFlatPosition()
    if ex == nil or ez == nil then
        return
    end
    for _, plot in self._plots do
        if
            plot.charges > 0
            and now >= plot.quietUntil
            and self._defenseLanes.trapTriggers(ex, ez, plot.position.X, plot.position.Z)
        then
            local trap = self._defenseLanes.Trap
            local held = self._enemyService:applyTrapSnare(trap.snareSeconds)
            if held ~= nil then
                plot.charges -= 1
                -- One bite per victim: stay quiet until this snare has
                -- fully released before the ring can trigger again.
                plot.quietUntil = now + trap.snareSeconds + 2
                if plot.charges <= 0 then
                    plot.ember.Color = EMBER_COLD
                end
                self._logger:info("defense_trap_bit", {
                    charges = plot.charges,
                    enemy = held,
                    lane = plot.laneId,
                })
                self:_toast(
                    nil,
                    string.format(
                        Strings.get("toast.the_snare_bites_n_is_held"),
                        string.upper(held)
                    )
                )
            end
        end
    end
    local watchPosition = self._watchPosition
    if watchPosition ~= nil and now >= self._nextChipAt then
        local dx = ex - watchPosition.X
        local dz = ez - watchPosition.Z
        if dx * dx + dz * dz <= self._config.TownWatchChipRange ^ 2 then
            if self._enemyService:residentChip(self._config.TownWatchChipDamage) then
                self._nextChipAt = now + self._config.TownWatchChipEverySeconds
            end
        end
    end
end

function DefenseService.Start(self: DefenseService)
    -- The plots need the lantern, which the world raises during its own
    -- startup; wait for it rather than racing it.
    task.spawn(function()
        for _ = 1, 120 do
            local ready = pcall(function()
                return self._worldService:lanternPosition()
            end)
            if ready then
                self:_buildPlots()
                break
            end
            task.wait(0.5)
        end
    end)
    local accumulator = 0
    self._heartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.25 then
            return
        end
        accumulator = 0
        self:_step(workspace:GetServerTimeNow())
    end)
end

return table.freeze(DefenseService)
