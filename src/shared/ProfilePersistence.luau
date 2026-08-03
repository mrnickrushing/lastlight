--!strict

--[[
    The decisions ProfileService makes about a save, separated from the calls
    it makes to reach one.

    Milestone 4's exit gate asks that forced crashes, lock contention, write
    failure, stale revision, and shutdown all pass. Every one of those is a
    decision about state -- should this load be trusted, may this server claim
    this profile, whose copy wins -- and none of them needs a DataStore to
    answer. They live here so the gate can be tested rather than argued about,
    and so the one place that decides whether a save may be overwritten is a
    place you can read in one sitting.

    The property everything else protects: **a save is never overwritten by a
    profile that failed to load.** A DataStore read that errors or times out
    produces a playable session with a default profile and no write permission,
    because the alternative -- treating "I could not read your save" as "you
    have no save" -- deletes a player's game during a Roblox outage. That is
    the single worst thing this system could do, and it is why loadOutcome
    returns writable = false on every unhappy path.
]]

local ProfilePersistence = {}

export type Lock = {
    jobId: string,
    heartbeat: number,
}

export type LoadOutcome = {
    source: string,
    writable: boolean,
    useStored: boolean,
}

export type LockDecision = {
    acquired: boolean,
    reason: string,
}

export type WriteDecision = {
    action: string,
    reason: string,
}

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

--[[
    What a load attempt produced.

    `finished` is whether the request came back at all before the deadline, and
    `ok` whether it came back without erroring. Only the path where both hold
    and the store answered may write.
]]
function ProfilePersistence.loadOutcome(finished: boolean, ok: boolean, stored: any): LoadOutcome
    if not finished then
        -- The request never returned. Somebody else's copy may still be live;
        -- writing over it from here would be guessing.
        return { source = "read_only", writable = false, useStored = false }
    end
    if not ok then
        return { source = "read_only", writable = false, useStored = false }
    end
    if stored == nil then
        return { source = "new", writable = true, useStored = false }
    end
    return { source = "datastore", writable = true, useStored = true }
end

--[[
    Whether this server may claim a profile.

    A lock is a job ID and a heartbeat. The heartbeat is what makes a crash
    survivable: a server that dies never releases its lock, so the only way the
    player ever plays again is for a later session to reclaim a lock that has
    stopped beating. `staleAfter` therefore has to exceed the heartbeat interval
    by enough that a slow save is not mistaken for a dead server.

    Two shapes of bad data are treated as unlocked rather than as locked, on the
    principle that corrupt bookkeeping must never cost a player their save
    permanently: a lock that is not a well-formed record, and a lock whose
    heartbeat is far enough in the future that it cannot be a real clock.
]]
function ProfilePersistence.acquireLock(
    existing: any,
    jobId: string,
    now: number,
    staleAfter: number
): LockDecision
    assert(type(jobId) == "string" and jobId ~= "", "a lock needs a job ID")
    assert(finite(now), "lock time must be finite")
    assert(finite(staleAfter) and staleAfter > 0, "stale threshold must be positive")

    if existing == nil then
        return { acquired = true, reason = "unlocked" }
    end
    if
        type(existing) ~= "table"
        or type(existing.jobId) ~= "string"
        or existing.jobId == ""
        or not finite(existing.heartbeat)
    then
        return { acquired = true, reason = "malformed_lock" }
    end
    if existing.jobId == jobId then
        return { acquired = true, reason = "already_held" }
    end

    local age = now - existing.heartbeat
    if age >= staleAfter then
        return { acquired = true, reason = "reclaimed_stale" }
    end
    if age < -staleAfter then
        -- A heartbeat from the future by more than the whole stale window is a
        -- broken clock, not a live server holding the profile.
        return { acquired = true, reason = "reclaimed_future" }
    end
    return { acquired = false, reason = "held_by_another_server" }
end

function ProfilePersistence.lock(jobId: string, now: number): Lock
    return { jobId = jobId, heartbeat = now }
end

--[[
    Whose copy of a profile wins.

    Two servers can hold the same profile briefly -- a reclaimed lock, a
    teleport, a rejoin before the old session flushed. Revision is the tie
    break, and the rule is that the higher revision is never overwritten by a
    lower one. Losing here is not a failure: it means the copy in memory is
    behind, and the caller adopts the stored one instead of pushing stale
    progress over fresh progress.
]]
function ProfilePersistence.resolveWrite(stored: any, pending: any): WriteDecision
    assert(type(pending) == "table" and finite(pending.revision), "a write needs a revision")

    if stored == nil then
        return { action = "write", reason = "no_stored_profile" }
    end
    if type(stored) ~= "table" or not finite(stored.revision) then
        -- Unreadable stored data is replaced rather than deferred to: deferring
        -- would strand the player on a profile nothing can parse.
        return { action = "write", reason = "stored_profile_unreadable" }
    end
    if stored.revision > pending.revision then
        return { action = "retain_stored", reason = "stored_revision_is_newer" }
    end
    return { action = "write", reason = "pending_revision_is_current" }
end

-- Whether a heartbeat is due. Kept here so the interval that refreshes a lock
-- and the threshold that reclaims one stay visibly related.
function ProfilePersistence.shouldRefreshLock(
    lastHeartbeat: any,
    now: number,
    interval: number
): boolean
    if not finite(lastHeartbeat) then
        return true
    end
    return now - lastHeartbeat >= interval
end

return table.freeze(ProfilePersistence)
