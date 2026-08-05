--!strict
--[[
    Owns the Sound instances and plays what SfxCatalog decides.

    Thin on purpose: all judgement about when a cue fires lives in the
    catalog's pure resolver where the specs are. This controller only pools
    sounds, rolls a little pitch variation so repetition doesn't grate, and
    enforces each cue's cooldown so a burst of snapshots cannot machine-gun
    a sound.
]]

local SoundService = game:GetService("SoundService")

local SfxController = {}
SfxController.__index = SfxController

export type SfxController = typeof(setmetatable(
    {} :: {
        _catalog: any,
        _group: SoundGroup,
        _sounds: { [string]: { Sound } },
        _nextSlot: { [string]: number },
        _lastPlayedAt: { [string]: number },
        _signature: any,
        _random: Random,
    },
    SfxController
))

-- Two slots per cue: a gather can land while the previous gather's tail is
-- still ringing without cutting it off.
local SLOTS_PER_CUE = 2

-- The catalog arrives injected, the same way MusicController receives its
-- catalog: shared modules live under ReplicatedStorage.LastLight and the
-- bootstrap owns requiring them.
function SfxController.new(catalog: any): SfxController
    local group = Instance.new("SoundGroup")
    group.Name = "LastLightSfx"
    group.Volume = 0.85
    group.Parent = SoundService

    local sounds: { [string]: { Sound } } = {}
    local nextSlot: { [string]: number } = {}
    for id, definition in catalog.Cues do
        local slots = {}
        for slot = 1, SLOTS_PER_CUE do
            local sound = Instance.new("Sound")
            sound.Name = "Sfx_" .. id .. "_" .. slot
            sound.SoundId = definition.soundId
            sound.Volume = definition.volume
            sound.SoundGroup = group
            sound.Parent = group
            table.insert(slots, sound)
        end
        sounds[id] = slots
        nextSlot[id] = 1
    end

    return setmetatable({
        _catalog = catalog,
        _group = group,
        _sounds = sounds,
        _nextSlot = nextSlot,
        _lastPlayedAt = {},
        _signature = nil,
        _random = Random.new(),
    }, SfxController)
end

function SfxController.play(self: SfxController, cueId: string)
    local definition = self._catalog.get(cueId)
    local slots = self._sounds[cueId]
    if definition == nil or slots == nil then
        return
    end
    local now = os.clock()
    local lastAt = self._lastPlayedAt[cueId]
    if lastAt ~= nil and now - lastAt < definition.cooldown then
        return
    end
    self._lastPlayedAt[cueId] = now
    local slot = self._nextSlot[cueId]
    self._nextSlot[cueId] = if slot >= #slots then 1 else slot + 1
    local sound = slots[slot]
    sound:Stop()
    sound.PlaybackSpeed = self._random:NextNumber(definition.minSpeed, definition.maxSpeed)
    sound:Play()
end

--[[
    Feed every server snapshot through. The first one only seeds the
    signature — joining mid-night must not play the night sting.
]]
function SfxController.setSnapshot(self: SfxController, snapshot: any)
    if type(snapshot) ~= "table" then
        return
    end
    local cues, signature = self._catalog.resolveTransitions(self._signature, snapshot)
    self._signature = signature
    for _, cueId in cues do
        self:play(cueId)
    end
end

return table.freeze(SfxController)
