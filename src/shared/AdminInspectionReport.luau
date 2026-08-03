--!strict

--[[
    What an admin sees when they inspect a player's save.

    Milestone 4 asks for "admin save inspection ... with audit logs." This is
    the inspection half: pure formatting over whatever ProfileService reads
    back, so what an admin is shown is exact rather than approximate, and so
    the report can be tested without a DataStore.

    It never returns anything that could be written back as a profile -- only
    descriptive counts and states. That is deliberate: repair is not built
    yet. Every other admin command in this game applies its effect through
    the same service method the game calls on itself, which is what keeps an
    admin from putting a save in a state the game could not otherwise reach.
    A repair tool for an offline profile has no live service to route
    through, and shipping one before deciding what "safe" means there is how
    a debugging tool becomes a duplication vector. This module exists so
    inspection can ship now without that decision being rushed to unlock it.
]]

local SaveSchema = require("./SaveSchema")

local AdminInspectionReport = {}

export type LockState = {
    held: boolean,
    holder: string?,
    stale: boolean?,
}

export type Report = {
    found: boolean,
    schemaVersion: number?,
    nightNumber: number?,
    tutorialStage: string?,
    tutorialComplete: boolean?,
    chapterOneStatus: string?,
    chapterOneDecision: string?,
    professionId: string?,
    professionsWithMastery: number?,
    equippedCount: number?,
    gearStacks: number?,
    lock: LockState,
}

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

--[[
    Describes a lock without acting on it.

    ProfilePersistence.acquireLock exists to decide whether a server may
    *claim* a profile, which is not what inspection wants: reading a save
    must never contend with the server actually holding it, or with a player
    who reconnects while an admin is looking. This only reports what is
    already written down.
]]
local function describeLock(lock: any, now: any, staleAfter: any): LockState
    if type(lock) ~= "table" or type(lock.jobId) ~= "string" or lock.jobId == "" then
        return { held = false, holder = nil, stale = nil }
    end
    local heartbeat = lock.heartbeat
    local canJudgeAge = finite(heartbeat) and finite(now) and finite(staleAfter)
    return {
        held = true,
        holder = lock.jobId,
        stale = if canJudgeAge then (now - heartbeat) > staleAfter else nil,
    }
end

--[[
    `stored` is exactly what GetAsync would return for this player: nil for a
    key that was never written, or whatever value is on record. Never a live
    Profile, so a locked or currently-playing save is inspected the same way
    an offline one is.
]]
function AdminInspectionReport.build(stored: any, now: number, staleAfter: number): Report
    assert(finite(now), "inspection time must be finite")
    assert(finite(staleAfter) and staleAfter > 0, "stale threshold must be positive")

    local lock =
        describeLock(if type(stored) == "table" then stored.sessionLock else nil, now, staleAfter)

    if stored == nil then
        return {
            found = false,
            lock = lock,
        } :: Report
    end

    local profile = SaveSchema.normalize(stored, now)
    local chapterOne = SaveSchema.chapterOne(profile)

    -- profile.profession.mastery, not SaveSchema.masterySnapshot: the
    -- snapshot is a display view that fills in every catalog profession at
    -- level 1 for a UI that always shows all of them, so counting its
    -- entries always returns the full profession count regardless of
    -- progress. The stored table itself only has an entry for a profession
    -- the player has actually put experience into.
    local professionsWithMastery = 0
    for _ in profile.profession.mastery do
        professionsWithMastery += 1
    end

    local equippedCount = 0
    for _ in SaveSchema.equippedSnapshot(profile) do
        equippedCount += 1
    end

    local gearStacks = 0
    for _ in SaveSchema.gearSnapshot(profile) do
        gearStacks += 1
    end

    return {
        found = true,
        schemaVersion = profile.schemaVersion,
        nightNumber = SaveSchema.nightNumber(profile),
        tutorialStage = profile.tutorial.stage,
        tutorialComplete = profile.tutorial.complete,
        chapterOneStatus = chapterOne.status,
        chapterOneDecision = chapterOne.decision,
        professionId = profile.profession.selectedId,
        professionsWithMastery = professionsWithMastery,
        equippedCount = equippedCount,
        gearStacks = gearStacks,
        lock = lock,
    } :: Report
end

return table.freeze(AdminInspectionReport)
