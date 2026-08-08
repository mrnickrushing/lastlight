--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local root = ReplicatedStorage:WaitForChild("LastLight", 8)
assert(root ~= nil, "Last Light shared root did not replicate before client bootstrap timeout")

local Config = require(root.Config)
local AmbientMotion = require(root.AmbientMotion)
local ExpeditionContracts = require(root.ExpeditionContracts)
local MusicCatalog = require(root.MusicCatalog)
local SfxCatalog = require(root.SfxCatalog)
local ProfessionCatalog = require(root.ProfessionCatalog)
local RuntimeIds = require(root.RuntimeIds)
local TownNightSchedule = require(root.TownNightSchedule)
local WeatherProfile = require(root.WeatherProfile)
local AmbientController = require(script.Controllers.AmbientController)
local HUDController = require(script.Controllers.HUDController)
local ObjectiveMarkerController = require(script.Controllers.ObjectiveMarkerController)
local SocialPingController = require(script.Controllers.SocialPingController)
local TapController = require(script.Controllers.TapController)
local VignetteController = require(script.Controllers.VignetteController)
local InputController = require(script.Controllers.InputController)
local InteractionController = require(script.Controllers.InteractionController)
local MusicController = require(script.Controllers.MusicController)
local SfxController = require(script.Controllers.SfxController)
local PerformanceController = require(script.Controllers.PerformanceController)
local WorldMotionController = require(script.Controllers.WorldMotionController)
local WeatherController = require(script.Controllers.WeatherController)

local runtime =
    ReplicatedStorage:WaitForChild(RuntimeIds.FolderName, Config.BootstrapTimeoutSeconds)
assert(runtime ~= nil, "Last Light runtime did not replicate before client bootstrap timeout")

local actionRequest =
    runtime:WaitForChild(RuntimeIds.Remotes.ActionRequest, Config.BootstrapTimeoutSeconds)
local stateChanged =
    runtime:WaitForChild(RuntimeIds.Remotes.StateChanged, Config.BootstrapTimeoutSeconds)
local getState = runtime:WaitForChild(RuntimeIds.Remotes.GetState, Config.BootstrapTimeoutSeconds)
local performanceReport =
    runtime:WaitForChild(RuntimeIds.Remotes.PerformanceReport, Config.BootstrapTimeoutSeconds)
assert(actionRequest ~= nil and actionRequest:IsA("RemoteEvent"), "missing ActionRequest")
assert(stateChanged ~= nil and stateChanged:IsA("RemoteEvent"), "missing StateChanged")
assert(getState ~= nil and getState:IsA("RemoteFunction"), "missing GetState")
assert(
    performanceReport ~= nil and performanceReport:IsA("RemoteEvent"),
    "missing PerformanceReport"
)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", Config.BootstrapTimeoutSeconds)
assert(playerGui ~= nil and playerGui:IsA("PlayerGui"), "PlayerGui unavailable")

local hud = HUDController.new(playerGui, ProfessionCatalog.list(), ExpeditionContracts.List)
local vignette = VignetteController.new(playerGui)
local objectiveMarkers = ObjectiveMarkerController.new(playerGui)
local socialPings = SocialPingController.new()
local ambient = AmbientController.new(RuntimeIds.AmbientMoteTag)
local worldMotion = WorldMotionController.new(
    RuntimeIds.AmbientMotionTag,
    RuntimeIds.AmbientLightTag,
    RuntimeIds.AmbientSwayTag,
    AmbientMotion
)
local weather = WeatherController.new(WeatherProfile)
local interaction = InteractionController.new(RuntimeIds.InteractionTag, hud)
local music = MusicController.new(MusicCatalog)
local sfx = SfxController.new(SfxCatalog)
PerformanceController.new(performanceReport :: RemoteEvent, Config.PerformanceReportIntervalSeconds)

local function send(kind: string, fields: { [string]: any }?)
    local payload = fields or {}
    payload.schemaVersion = 1
    payload.kind = kind
    actionRequest:FireServer(payload)
end

InputController.new(hud, function()
    local interactionId = interaction:currentInteractionId()
    if interactionId ~= nil then
        sfx:play("tap")
        send(RuntimeIds.Actions.Interact, { interactionId = interactionId })
    end
end, function()
    sfx:play("swing")
    send(RuntimeIds.Actions.UseTool)
end, function(enabled: boolean)
    send(RuntimeIds.Actions.Sprint, { enabled = enabled })
end, function()
    send(RuntimeIds.Actions.Dodge)
end, function()
    send(RuntimeIds.Actions.ProfessionAbility)
end, function()
    hud:setProfessionMenuOpen(true)
end, function(itemId: string)
    send(RuntimeIds.Actions.UseGear, { itemId = itemId })
end)

--[[
    Tapping the world is the interaction model, and it has to work on a
    finger. The server ClickDetectors stay -- they are what a mouse uses and
    they carry the server-side validation -- but touch resolves its own tap
    here and sends the same requests, because Roblox will not reliably turn a
    tap in the camera-drag region of a phone screen into a click.
]]
TapController.new(function()
    -- The swing sounds on the tap itself: feedback that waits for the server
    -- round-trip reads as lag, not as hitting.
    sfx:play("swing")
    send(RuntimeIds.Actions.UseTool)
end, function(interactionId: string)
    sfx:play("tap")
    send(RuntimeIds.Actions.Interact, { interactionId = interactionId })
end)

hud:setCompactHandler(function(enabled: boolean)
    send(RuntimeIds.Actions.CompactHud, { enabled = enabled })
end)

hud:setLobbyDepartHandler(function(partySize: number, contractId: string)
    send(RuntimeIds.Actions.LobbyDepart, { partySize = partySize, contractId = contractId })
end)

hud:setPartyHandlers(function()
    send(RuntimeIds.Actions.PartyInvite)
end, function(accept: boolean)
    send(RuntimeIds.Actions.PartyReply, { accept = accept })
end, function()
    send(RuntimeIds.Actions.PartyLeave)
end, function()
    send(RuntimeIds.Actions.PartyRejoin)
end)

hud:setQuickChatHandler(function(phraseId: string)
    send(RuntimeIds.Actions.QuickChat, { phraseId = phraseId })
end)

hud:setLoadoutHandlers(function(slot: number)
    send(RuntimeIds.Actions.SaveLoadout, { slot = slot })
end, function(slot: number)
    send(RuntimeIds.Actions.ApplyLoadout, { slot = slot })
end)

hud:setProfessionHandler(function(professionId: string)
    send(RuntimeIds.Actions.SelectProfession, { professionId = professionId })
end)

hud:setEquipHandler(function(itemId: string)
    send(RuntimeIds.Actions.EquipGear, { itemId = itemId })
end)

hud:setWhetHandler(function(itemId: string)
    send(RuntimeIds.Actions.RepairGear, { itemId = itemId })
end)

hud:setCompanionHandler(function(mode: string)
    send(RuntimeIds.Actions.CompanionCommand, { mode = mode })
end)

--[[
    Arrival vignettes ride the same state stream the HUD already consumes:
    each one fires on a specific transition, locally, at most once per
    arrival. The focus points are found in the workspace at trigger time so a
    streamed-out or missing landmark simply skips the shot instead of aiming
    a camera at nothing.
]]
local lastNightActive = false
local lastBlackoutStatus: string? = nil
local lastEliteActive = false
local lastBossActive = false

local function focusPart(name: string): Vector3?
    local found = workspace:FindFirstChild(name, true)
    return if found ~= nil and found:IsA("BasePart")
        then found.Position
        elseif found ~= nil and found:IsA("Model") then found:GetPivot().Position
        else nil
end

local function updateVignettes(snapshot: any, suppress: boolean?)
    vignette:setCompact(snapshot.compactHud == true)

    local nightActive = snapshot.nightActive == true
    if suppress then
        -- A reconnect mid-arrival is not an arrival: seed the trackers from
        -- the first snapshot so a player who joins during a night or an
        -- active encounter is not greeted by a stale cinematic.
        lastNightActive = nightActive
        local seedBlackout = snapshot.blackout
        lastBlackoutStatus = if type(seedBlackout) == "table"
            then tostring(seedBlackout.status)
            else nil
        local seedElite = snapshot.elite
        lastEliteActive = type(seedElite) == "table" and seedElite.active == true
        local seedBoss = snapshot.boss
        lastBossActive = type(seedBoss) == "table" and seedBoss.active == true
        return
    end
    if nightActive and not lastNightActive and snapshot.expeditionActive ~= true then
        local nightNumber = tonumber(snapshot.nightNumber) or 0
        local title = "THE FIRST NIGHT"
        local subtitle = "KEEP THE LIGHT ALIVE"
        if nightNumber >= 1 then
            local theme = TownNightSchedule.theme(nightNumber)
            local profile = TownNightSchedule.profile(nightNumber)
            title = string.format("NIGHT %d · %s", nightNumber, theme)
            subtitle = tostring(profile.instruction)
        end
        local focus = focusPart("FirstLantern")
        if focus ~= nil then
            vignette:play({
                title = title,
                subtitle = subtitle,
                focus = focus,
                duration = 5.5,
            })
        end
    end
    lastNightActive = nightActive

    local blackout = snapshot.blackout
    local blackoutStatus = if type(blackout) == "table" then tostring(blackout.status) else nil
    if blackoutStatus == "relay" and lastBlackoutStatus ~= "relay" then
        local focus = focusPart("BlackoutLanternFire")
        if focus ~= nil then
            vignette:play({
                title = "THE BLACKOUT",
                subtitle = "CARRY THE ROOTFIRE",
                focus = focus,
                duration = 5.5,
            })
        end
    end
    lastBlackoutStatus = blackoutStatus

    local elite = snapshot.elite
    local eliteActive = type(elite) == "table" and elite.active == true
    if eliteActive and not lastEliteActive then
        local focus = focusPart("OldGrowthElite")
        if focus ~= nil then
            vignette:play({
                title = "OLD GROWTH",
                subtitle = "STRIKE THE AMBER HEART",
                focus = focus,
                duration = 4.5,
            })
        end
    end
    lastEliteActive = eliteActive

    local boss = snapshot.boss
    local bossActive = type(boss) == "table" and boss.active == true
    if bossActive and not lastBossActive then
        local focus = focusPart("WardenStagBoss")
        if focus ~= nil then
            vignette:play({
                title = "THE WARDEN STAG",
                subtitle = "CLEANSE THE LIVING ROOTS",
                focus = focus,
                duration = 4.5,
            })
        end
    end
    lastBossActive = bossActive
end

stateChanged.OnClientEvent:Connect(function(snapshot: any)
    hud:update(snapshot)
    ambient:setPhase(tostring(snapshot.phase or "day"))
    worldMotion:setPhase(tostring(snapshot.phase or "day"))
    weather:setContext(
        snapshot.expeditionActive == true,
        tostring(snapshot.phase or "day"),
        if type(snapshot.contract) == "table" then snapshot.contract.weather else nil
    )
    music:setSnapshot(snapshot)
    sfx:setSnapshot(snapshot)
    objectiveMarkers:setTargets(
        if snapshot.departed == true then snapshot.objectiveTargets else nil
    )
    socialPings:setCalls(
        if type(snapshot.social) == "table" then snapshot.social.calls else nil,
        if type(snapshot.social) == "table" then snapshot.social.pings else nil
    )
    updateVignettes(snapshot)
end)

task.spawn(function()
    local ok, snapshot = pcall(function()
        return getState:InvokeServer()
    end)
    if ok and snapshot ~= nil then
        hud:update(snapshot)
        ambient:setPhase(tostring(snapshot.phase or "day"))
        worldMotion:setPhase(tostring(snapshot.phase or "day"))
        weather:setContext(
            snapshot.expeditionActive == true,
            tostring(snapshot.phase or "day"),
            if type(snapshot.contract) == "table" then snapshot.contract.weather else nil
        )
        music:setSnapshot(snapshot)
        -- Seeds the SFX signature only: joining mid-night is not a night falling.
        sfx:setSnapshot(snapshot)
        objectiveMarkers:setTargets(
            if snapshot.departed == true then snapshot.objectiveTargets else nil
        )
        socialPings:setCalls(
            if type(snapshot.social) == "table" then snapshot.social.calls else nil,
            if type(snapshot.social) == "table" then snapshot.social.pings else nil
        )
        updateVignettes(snapshot, true)
    end
end)

print(string.format("[Last Light] Client boot %s", Config.BuildVersion))

--[[
    Pull the world's mesh assets down before a player reaches them.

    The server hides a mesh's primitive placeholder the moment the mesh
    is swapped in, but that swap is a fact about the server: a phone that
    has not yet downloaded the mesh renders nothing where the placeholder
    was, and the placeholder is still the collision. The first minute of
    a mobile session was full of solid air because of exactly this --
    walls that had visibly "not loaded yet" would at least be honest;
    these were invisible.

    So the client asks for every mesh in the world up front,
    nearest-to-spawn first, in small batches so the request queue never
    starves the assets the engine wants for what is actually on screen.
    Fire-and-forget: nothing waits on it, it just shrinks the window in
    which a mesh can be touched before it can be seen.
]]
task.spawn(function()
    local ContentProvider = game:GetService("ContentProvider")
    local spawnPosition = Vector3.new(0, 0, 74)
    local meshes: { { part: MeshPart, distance: number } } = {}
    for _, descendant in workspace:GetDescendants() do
        if descendant:IsA("MeshPart") then
            table.insert(meshes, {
                part = descendant,
                distance = (descendant.Position - spawnPosition).Magnitude,
            })
        end
    end
    table.sort(meshes, function(a, b)
        return a.distance < b.distance
    end)
    local batch: { Instance } = {}
    for _, entry in meshes do
        table.insert(batch, entry.part)
        if #batch >= 12 then
            pcall(function()
                ContentProvider:PreloadAsync(batch)
            end)
            batch = {}
        end
    end
    if #batch > 0 then
        pcall(function()
            ContentProvider:PreloadAsync(batch)
        end)
    end
end)
