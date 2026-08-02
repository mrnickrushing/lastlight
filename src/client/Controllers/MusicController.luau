--!strict

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MusicController = {}
MusicController.__index = MusicController

export type MusicController = typeof(setmetatable(
    {} :: {
        _catalog: any,
        _group: SoundGroup,
        _slots: { Sound },
        _activeSlot: number,
        _trackId: string?,
        _revision: number,
        _retryConnection: RBXScriptConnection?,
    },
    MusicController
))

local CROSSFADE_SECONDS = 3.2

local function musicSlot(name: string, group: SoundGroup): Sound
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.Looped = true
    sound.Volume = 0
    sound.SoundGroup = group
    sound.Parent = SoundService
    return sound
end

function MusicController.new(catalog: any): MusicController
    local group = Instance.new("SoundGroup")
    group.Name = "LastLightMusic"
    group.Volume = 0.78
    group.Parent = SoundService

    local self = setmetatable({
        _catalog = catalog,
        _group = group,
        _slots = { musicSlot("MusicA", group), musicSlot("MusicB", group) },
        _activeSlot = 2,
        _trackId = nil,
        _revision = 0,
        _retryConnection = nil,
    }, MusicController)

    -- Some mobile clients defer autoplay until the first real interaction.
    self._retryConnection = UserInputService.InputBegan:Connect(function()
        local active = self._slots[self._activeSlot]
        if self._trackId ~= nil and not active.Playing then
            active:Play()
        end
    end)
    return self
end

function MusicController.setSnapshot(self: MusicController, snapshot: any)
    local nextTrack = self._catalog.resolveSnapshot(snapshot)
    if nextTrack.id == self._trackId then
        return
    end

    self._revision += 1
    local revision = self._revision
    local oldSlotIndex = self._activeSlot
    local nextSlotIndex = if oldSlotIndex == 1 then 2 else 1
    local outgoing = self._slots[oldSlotIndex]
    local incoming = self._slots[nextSlotIndex]
    self._activeSlot = nextSlotIndex
    self._trackId = nextTrack.id

    incoming:Stop()
    incoming.SoundId = "rbxassetid://" .. tostring(nextTrack.assetId)
    incoming.Volume = 0
    incoming:SetAttribute("TrackId", nextTrack.id)
    incoming:SetAttribute("RegionMusic", true)

    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync({ incoming })
        end)
        if revision ~= self._revision then
            return
        end
        incoming:Play()
        TweenService
            :Create(
                incoming,
                TweenInfo.new(CROSSFADE_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Volume = nextTrack.volume }
            )
            :Play()
        TweenService
            :Create(
                outgoing,
                TweenInfo.new(CROSSFADE_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Volume = 0 }
            )
            :Play()
        task.delay(CROSSFADE_SECONDS + 0.1, function()
            if revision == self._revision then
                outgoing:Stop()
            end
        end)
    end)
end

return MusicController
