--!strict

--[[
    When a save is copied aside, which copies are kept, and what a restore
    writes back.

    Milestone 4's persistence deliverable asks for "versioned profile, locking,
    autosave, shutdown, migrations, backups". Everything but the last of those
    already exists in ProfileService and ProfilePersistence. This module is the
    last one, and it is deliberately the same shape as ProfilePersistence: pure
    decisions about state, no DataStore, so the properties that matter can be
    tested rather than argued about.

    TECHNICAL_ARCHITECTURE names the requirement that drove the design: "Backups
    and export tooling are required before migrations that alter inventory or
    commerce." A migration in this codebase is not a numbered pipeline -- it is
    SaveSchema.normalize folding an older profile into the current default --
    which means a migration that drops a field drops it silently and leaves
    nothing behind to compare against. So the moment a stored profile arrives
    carrying a schema version other than the current one is the moment worth
    photographing, and `shouldCapture` treats it as unconditional.

    Two properties are load-bearing, and both are easy to get wrong in a way
    that is invisible until someone actually needs a restore:

      * **A restored profile must out-rank the profile it replaces.**
        ProfilePersistence.resolveWrite retains the stored copy whenever its
        revision is higher, which is exactly right for two servers racing and
        exactly wrong for a restore -- a restore is a deliberate move backwards
        in content and must still be a move forwards in revision, or it writes
        nothing and reports success.
      * **A snapshot never carries a session lock.** Locks ride along inside the
        saved profile so a crashed server leaves a heartbeat that stops. Copy one
        into a backup and a restore months later resurrects a lock held by a job
        that no longer exists, and the player is read-only until someone runs
        /unlock. Snapshots are stripped on the way in, not on the way out, so
        even a backup written by an older build cannot carry one through.
]]

local ProfileBackup = {}

export type Snapshot = {
    revision: number,
    capturedAt: number,
    schemaVersion: number,
    reason: string,
    profile: any,
}

export type Ring = {
    version: number,
    snapshots: { Snapshot },
}

export type CaptureDecision = {
    capture: boolean,
    reason: string,
}

-- Why a snapshot was taken. Kept as a closed set so an operator reading an
-- audit line sees one of a handful of known words rather than free text.
local CAPTURE_REASONS: { [string]: boolean } = table.freeze({
    schema_change = true,
    first_backup = true,
    interval = true,
    pre_restore = true,
})

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function wholeAtLeast(value: any, low: number): boolean
    return finite(value) and value == math.floor(value) and value >= low
end

function ProfileBackup.default(): Ring
    return { version = 1, snapshots = {} }
end

function ProfileBackup.captureReasons(): { string }
    local reasons: { string } = {}
    for reason in CAPTURE_REASONS do
        table.insert(reasons, reason)
    end
    table.sort(reasons)
    return reasons
end

--[[
    Read whatever the backup key held into a ring this build understands.

    Forgiving in the same way SaveSchema.normalize is forgiving, and for the
    same reason: a backup that cannot be parsed must degrade to "no backups"
    rather than to an error, because the caller is usually a load path that has
    a player waiting on it. A malformed entry is dropped individually so one bad
    snapshot cannot cost a player the good ones sitting next to it.
]]
function ProfileBackup.normalize(value: any): Ring
    local ring = ProfileBackup.default()
    if type(value) ~= "table" or type(value.snapshots) ~= "table" then
        return ring
    end

    for _, candidate in value.snapshots do
        if
            type(candidate) == "table"
            and type(candidate.profile) == "table"
            and wholeAtLeast(candidate.revision, 0)
            and finite(candidate.capturedAt)
            and wholeAtLeast(candidate.schemaVersion, 1)
            and type(candidate.reason) == "string"
            and CAPTURE_REASONS[candidate.reason] == true
        then
            local profile = table.clone(candidate.profile)
            -- Defence in depth: strip on the way out as well as on the way in,
            -- so a snapshot written by a build that predates this rule cannot
            -- carry a dead lock into a restore.
            profile.sessionLock = nil
            table.insert(ring.snapshots, {
                revision = math.floor(candidate.revision),
                capturedAt = candidate.capturedAt,
                schemaVersion = math.floor(candidate.schemaVersion),
                reason = candidate.reason,
                profile = profile,
            })
        end
    end

    return ring
end

--[[
    Whether this save is worth copying aside right now.

    A backup on every autosave would double the write traffic of the busiest
    path in the game to photograph a profile that has usually not meaningfully
    changed, so ordinary captures are rate limited. A schema change is not
    ordinary and ignores the limit: it is the one moment where the old shape
    stops being recoverable from the new one.
]]
function ProfileBackup.shouldCapture(
    ring: any,
    storedSchemaVersion: any,
    currentSchemaVersion: number,
    now: number,
    interval: number
): CaptureDecision
    assert(
        wholeAtLeast(currentSchemaVersion, 1),
        "current schema version must be a positive whole number"
    )
    assert(finite(now), "capture time must be finite")
    assert(finite(interval) and interval > 0, "capture interval must be positive")

    -- An unreadable or absent stored schema version is treated as a change: it
    -- means the profile did not come from this build, which is precisely when a
    -- copy is worth having.
    if not wholeAtLeast(storedSchemaVersion, 1) or storedSchemaVersion ~= currentSchemaVersion then
        return { capture = true, reason = "schema_change" }
    end

    local normalized = ProfileBackup.normalize(ring)
    local newest = ProfileBackup.newest(normalized)
    if newest == nil then
        return { capture = true, reason = "first_backup" }
    end
    if now - newest.capturedAt >= interval then
        return { capture = true, reason = "interval" }
    end
    return { capture = false, reason = "recent_backup_exists" }
end

--[[
    Append a snapshot, dropping the oldest beyond `limit`.

    Returns a new ring; the input is never mutated, so a failed DataStore write
    cannot leave the caller holding a ring that claims a snapshot it never
    stored. The bound exists because a DataStore value has a hard size ceiling
    and a profile is not small -- an unbounded history would eventually fail
    every write to this key, silently taking backups down at the exact moment
    the save is growing fastest.
]]
function ProfileBackup.capture(
    ring: any,
    profile: any,
    now: number,
    reason: string,
    limit: number
): Ring
    assert(type(profile) == "table", "a snapshot needs a profile")
    assert(finite(now), "capture time must be finite")
    assert(CAPTURE_REASONS[reason] == true, "unknown capture reason: " .. tostring(reason))
    assert(wholeAtLeast(limit, 1), "retained backup count must be at least one")

    local normalized = ProfileBackup.normalize(ring)

    local copied = table.clone(profile)
    -- The lock belongs to the session that wrote the save, never to the copy.
    copied.sessionLock = nil

    local snapshot: Snapshot = {
        revision = if wholeAtLeast(profile.revision, 0) then math.floor(profile.revision) else 0,
        capturedAt = now,
        schemaVersion = if wholeAtLeast(profile.schemaVersion, 1)
            then math.floor(profile.schemaVersion)
            else 1,
        reason = reason,
        profile = copied,
    }

    local snapshots = table.clone(normalized.snapshots)
    table.insert(snapshots, snapshot)
    while #snapshots > limit do
        table.remove(snapshots, 1)
    end

    return { version = normalized.version, snapshots = snapshots }
end

-- The most recently captured snapshot, or nil when there are none.
function ProfileBackup.newest(ring: any): Snapshot?
    local normalized = if type(ring) == "table"
            and type(ring.snapshots) == "table"
            and ring.version ~= nil
        then ring :: Ring
        else ProfileBackup.normalize(ring)
    local count = #normalized.snapshots
    if count == 0 then
        return nil
    end
    return normalized.snapshots[count]
end

--[[
    A specific copy, 1 = the oldest kept. Bounded and explicit: an operator
    restoring history names the copy they read in /backups, and an index off
    either end is nil rather than a clamp -- silently restoring a different
    copy than the one asked for is the one unforgivable behaviour here.
]]
function ProfileBackup.snapshotAt(ring: any, index: number): Snapshot?
    local normalized = if type(ring) == "table"
            and type(ring.snapshots) == "table"
            and ring.version ~= nil
        then ring :: Ring
        else ProfileBackup.normalize(ring)
    if type(index) ~= "number" or index ~= math.floor(index) then
        return nil
    end
    return normalized.snapshots[index]
end

--[[
    The profile a restore should write.

    `storedRevision` is the revision currently sitting in the live profile key,
    not the one in the snapshot. The returned profile takes a revision above
    both, because a restore has to survive ProfilePersistence.resolveWrite --
    which, left to itself, would see an old revision arriving over a newer one
    and correctly refuse it. Getting this wrong produces the worst possible
    failure mode: a restore that logs success and changes nothing.
]]
function ProfileBackup.restoredProfile(snapshot: any, storedRevision: any, now: number): any
    assert(
        type(snapshot) == "table" and type(snapshot.profile) == "table",
        "a restore needs a snapshot"
    )
    assert(finite(now), "restore time must be finite")

    local restored = table.clone(snapshot.profile)
    restored.sessionLock = nil
    restored.updatedAt = now

    local snapshotRevision = if wholeAtLeast(snapshot.revision, 0) then snapshot.revision else 0
    local liveRevision = if wholeAtLeast(storedRevision, 0) then storedRevision else 0
    restored.revision = math.max(snapshotRevision, liveRevision) + 1

    return restored
end

--[[
    What an operator sees before deciding to restore.

    Deliberately counts and timestamps rather than profile contents: an admin
    choosing whether to roll a save back needs to know how far back it goes and
    what shape it was in, and the full contents are what /inspect is for.
]]
function ProfileBackup.summary(ring: any): any
    local normalized = ProfileBackup.normalize(ring)
    local entries = {}
    for _, snapshot in normalized.snapshots do
        table.insert(entries, {
            revision = snapshot.revision,
            capturedAt = snapshot.capturedAt,
            schemaVersion = snapshot.schemaVersion,
            reason = snapshot.reason,
        })
    end
    local newest = ProfileBackup.newest(normalized)
    return {
        count = #entries,
        entries = entries,
        newestRevision = if newest ~= nil then newest.revision else nil,
        newestCapturedAt = if newest ~= nil then newest.capturedAt else nil,
    }
end

return table.freeze(ProfileBackup)
