--!strict

--[[
    Milestone 4's persistence deliverable names backups alongside locking and
    migrations, and QA_RELEASE_PLAN lists "restore from backup" as a save
    scenario that must be tested.

    The cases below are organised around the two ways a backup system fails
    silently -- a restore that writes nothing, and a restore that hands back a
    profile the player cannot use -- rather than around the happy path, which is
    the least interesting thing here.
]]

local Config = require("../../src/shared/Config")
local ProfileBackup = require("../../src/shared/ProfileBackup")
local ProfilePersistence = require("../../src/shared/ProfilePersistence")
local TestRunner = require("../TestRunner")

local CURRENT = Config.SaveSchemaVersion
local INTERVAL = Config.ProfileBackupIntervalSeconds
local RETAINED = Config.ProfileBackupRetained

local function profile(revision: number, schemaVersion: number?): any
    return {
        revision = revision,
        schemaVersion = schemaVersion or CURRENT,
        updatedAt = 1000,
        town = { nightNumber = 4 },
    }
end

return {
    name = "ProfileBackup",
    cases = {
        --
        -- A restore has to actually land
        --
        {
            name = "a restored profile out-ranks the live profile it replaces",
            run = function()
                -- The subtle failure this prevents: resolveWrite retains the
                -- stored copy whenever its revision is higher, so a restore
                -- carrying the snapshot's original revision would be refused by
                -- the very rule that protects against stale servers -- and would
                -- report success while changing nothing.
                local ring = ProfileBackup.capture(nil, profile(7), 100, "interval", RETAINED)
                local snapshot = ProfileBackup.newest(ring)
                TestRunner.truthy(snapshot ~= nil)

                local restored = ProfileBackup.restoredProfile(snapshot, 41, 500)
                TestRunner.equal(restored.revision, 42)

                -- And the write rule that guards live saves must now accept it.
                local decision = ProfilePersistence.resolveWrite(profile(41), restored)
                TestRunner.equal(decision.action, "write")
            end,
        },
        {
            name = "a restore still advances when the live save is older than the snapshot",
            run = function()
                local ring = ProfileBackup.capture(nil, profile(30), 100, "interval", RETAINED)
                local restored = ProfileBackup.restoredProfile(ProfileBackup.newest(ring), 2, 500)
                -- Above the snapshot, not merely above the live copy.
                TestRunner.equal(restored.revision, 31)
                TestRunner.equal(
                    ProfilePersistence.resolveWrite(profile(2), restored).action,
                    "write"
                )
            end,
        },
        {
            name = "an unreadable live revision cannot stall a restore",
            run = function()
                local ring = ProfileBackup.capture(nil, profile(5), 100, "interval", RETAINED)
                local snapshot = ProfileBackup.newest(ring)

                -- nil is checked on its own rather than as the first element of
                -- the list below: a generic for over an array literal skips a
                -- leading nil entirely, so folding it in would quietly drop the
                -- one input this case most needs to cover.
                TestRunner.equal(ProfileBackup.restoredProfile(snapshot, nil, 500).revision, 6)

                for _, broken in { "seven", 0 / 0, -3, math.huge } do
                    local restored = ProfileBackup.restoredProfile(snapshot, broken, 500)
                    TestRunner.equal(restored.revision, 6)
                end
            end,
        },
        {
            name = "restoring carries the snapshot's contents, not the live save's",
            run = function()
                local old = profile(3)
                old.town = { nightNumber = 2 }
                local ring = ProfileBackup.capture(nil, old, 100, "interval", RETAINED)
                local restored = ProfileBackup.restoredProfile(ProfileBackup.newest(ring), 9, 500)
                TestRunner.equal(restored.town.nightNumber, 2)
                TestRunner.equal(restored.updatedAt, 500)
            end,
        },

        --
        -- A restore must not hand back an unusable profile
        --
        {
            name = "a snapshot never carries a session lock",
            run = function()
                -- Locks ride inside the saved profile so a crash leaves a
                -- heartbeat that stops. Copy one into a backup and a restore
                -- resurrects a lock held by a job that no longer exists, leaving
                -- the player read-only until an admin runs /unlock.
                local live = profile(4)
                live.sessionLock = { jobId = "job-dead", heartbeat = 100 }

                local ring = ProfileBackup.capture(nil, live, 100, "interval", RETAINED)
                local snapshot = ProfileBackup.newest(ring)
                TestRunner.equal(snapshot.profile.sessionLock, nil)

                local restored = ProfileBackup.restoredProfile(snapshot, 4, 500)
                TestRunner.equal(restored.sessionLock, nil)

                -- The live profile handed in is not edited as a side effect.
                TestRunner.truthy(live.sessionLock ~= nil)
            end,
        },
        {
            name = "a lock stored by an older build is stripped on the way back out",
            run = function()
                -- Defence in depth: a backup written before the strip-on-capture
                -- rule existed must not be able to carry a lock through.
                local legacy = {
                    version = 1,
                    snapshots = {
                        {
                            revision = 2,
                            capturedAt = 100,
                            schemaVersion = CURRENT,
                            reason = "interval",
                            profile = {
                                revision = 2,
                                sessionLock = { jobId = "job-old", heartbeat = 1 },
                            },
                        },
                    },
                }
                local normalized = ProfileBackup.normalize(legacy)
                TestRunner.equal(normalized.snapshots[1].profile.sessionLock, nil)
            end,
        },

        --
        -- When a copy is worth taking
        --
        {
            name = "a schema change is photographed regardless of the interval",
            run = function()
                -- The requirement from TECHNICAL_ARCHITECTURE: backups are
                -- required before a migration. normalize() folds an old profile
                -- into the current default, so anything it drops is gone with
                -- nothing to compare against.
                local ring = ProfileBackup.capture(nil, profile(1), 1000, "interval", RETAINED)
                local decision =
                    ProfileBackup.shouldCapture(ring, CURRENT - 1, CURRENT, 1001, INTERVAL)
                TestRunner.equal(decision.capture, true)
                TestRunner.equal(decision.reason, "schema_change")
            end,
        },
        {
            name = "a missing or malformed stored schema version counts as a change",
            run = function()
                -- Checked separately; see the note in the restore case above.
                local missing = ProfileBackup.shouldCapture(nil, nil, CURRENT, 500, INTERVAL)
                TestRunner.equal(missing.capture, true)
                TestRunner.equal(missing.reason, "schema_change")

                for _, broken in { "twelve", 0, -1, 1.5 } do
                    local decision =
                        ProfileBackup.shouldCapture(nil, broken, CURRENT, 500, INTERVAL)
                    TestRunner.equal(decision.capture, true)
                    TestRunner.equal(decision.reason, "schema_change")
                end
            end,
        },
        {
            name = "the first backup is always taken, later ones are rate limited",
            run = function()
                local first = ProfileBackup.shouldCapture(nil, CURRENT, CURRENT, 500, INTERVAL)
                TestRunner.equal(first.capture, true)
                TestRunner.equal(first.reason, "first_backup")

                local ring = ProfileBackup.capture(nil, profile(1), 500, "first_backup", RETAINED)

                local tooSoon = ProfileBackup.shouldCapture(
                    ring,
                    CURRENT,
                    CURRENT,
                    500 + INTERVAL - 1,
                    INTERVAL
                )
                TestRunner.equal(tooSoon.capture, false)
                TestRunner.equal(tooSoon.reason, "recent_backup_exists")

                local due =
                    ProfileBackup.shouldCapture(ring, CURRENT, CURRENT, 500 + INTERVAL, INTERVAL)
                TestRunner.equal(due.capture, true)
                TestRunner.equal(due.reason, "interval")
            end,
        },

        --
        -- Bounds
        --
        {
            name = "the ring never grows past its retained count and keeps the newest",
            run = function()
                -- A DataStore value has a hard size ceiling and a profile is not
                -- small. An unbounded history eventually fails every write to
                -- this key -- taking backups down exactly as the save grows.
                local ring: any = nil
                for revision = 1, RETAINED + 5 do
                    ring = ProfileBackup.capture(
                        ring,
                        profile(revision),
                        revision,
                        "interval",
                        RETAINED
                    )
                    TestRunner.truthy(#ring.snapshots <= RETAINED)
                end

                TestRunner.equal(#ring.snapshots, RETAINED)
                TestRunner.equal(ProfileBackup.newest(ring).revision, RETAINED + 5)
                -- Oldest retained is the newest minus the window, so the drop
                -- came off the front rather than anywhere else.
                TestRunner.equal(ring.snapshots[1].revision, 6)
            end,
        },
        {
            name = "capture does not mutate the ring it was handed",
            run = function()
                local original = ProfileBackup.capture(nil, profile(1), 100, "interval", RETAINED)
                local before = #original.snapshots
                ProfileBackup.capture(original, profile(2), 200, "interval", RETAINED)
                -- A failed DataStore write must not leave the caller holding a
                -- ring that claims a snapshot it never stored.
                TestRunner.equal(#original.snapshots, before)
            end,
        },
        {
            name = "an unknown capture reason is refused rather than stored",
            run = function()
                TestRunner.throws(function()
                    ProfileBackup.capture(nil, profile(1), 100, "because", RETAINED)
                end, "unknown capture reason")
            end,
        },

        --
        -- Malformed storage
        --
        {
            name = "unreadable backup storage degrades to no backups, never an error",
            run = function()
                -- The caller is usually a load path with a player waiting on it.
                -- Checked separately; see the note in the restore case above.
                -- An absent backup key is the ordinary case for every player
                -- who has never had one taken, so it must not be the input the
                -- loop silently skipped.
                TestRunner.equal(#ProfileBackup.normalize(nil).snapshots, 0)
                TestRunner.equal(ProfileBackup.newest(nil), nil)

                for _, broken in { 7, "backups", {}, { snapshots = 3 } } do
                    local ring = ProfileBackup.normalize(broken)
                    TestRunner.equal(#ring.snapshots, 0)
                    TestRunner.equal(ProfileBackup.newest(ring), nil)
                end
            end,
        },
        {
            name = "one corrupt snapshot does not cost the good ones beside it",
            run = function()
                local mixed = {
                    version = 1,
                    snapshots = {
                        {
                            revision = 1,
                            capturedAt = 10,
                            schemaVersion = CURRENT,
                            reason = "interval",
                            profile = { revision = 1 },
                        },
                        {
                            revision = "two",
                            capturedAt = 20,
                            schemaVersion = CURRENT,
                            reason = "interval",
                            profile = { revision = 2 },
                        },
                        {
                            revision = 3,
                            capturedAt = 30,
                            schemaVersion = CURRENT,
                            reason = "nonsense",
                            profile = { revision = 3 },
                        },
                        {
                            revision = 4,
                            capturedAt = 40,
                            schemaVersion = CURRENT,
                            reason = "interval",
                            profile = "not a profile",
                        },
                        {
                            revision = 5,
                            capturedAt = 50,
                            schemaVersion = CURRENT,
                            reason = "pre_restore",
                            profile = { revision = 5 },
                        },
                    },
                }
                local ring = ProfileBackup.normalize(mixed)
                TestRunner.equal(#ring.snapshots, 2)
                TestRunner.equal(ring.snapshots[1].revision, 1)
                TestRunner.equal(ring.snapshots[2].revision, 5)
                TestRunner.equal(ProfileBackup.newest(ring).reason, "pre_restore")
            end,
        },

        --
        -- What an operator sees
        --
        {
            name = "a summary reports depth and shape without profile contents",
            run = function()
                local ring = ProfileBackup.capture(
                    nil,
                    profile(3, CURRENT - 1),
                    100,
                    "schema_change",
                    RETAINED
                )
                ring = ProfileBackup.capture(ring, profile(8), 900, "interval", RETAINED)

                local summary = ProfileBackup.summary(ring)
                TestRunner.equal(summary.count, 2)
                TestRunner.equal(summary.newestRevision, 8)
                TestRunner.equal(summary.newestCapturedAt, 900)
                TestRunner.equal(summary.entries[1].reason, "schema_change")
                TestRunner.equal(summary.entries[1].schemaVersion, CURRENT - 1)
                -- Contents are what /inspect is for; a summary must not leak them.
                TestRunner.equal((summary.entries[1] :: any).profile, nil)
            end,
        },
        {
            name = "an empty summary is reportable rather than nil",
            run = function()
                local summary = ProfileBackup.summary(nil)
                TestRunner.equal(summary.count, 0)
                TestRunner.equal(summary.newestRevision, nil)
            end,
        },
        {
            name = "snapshotAt names its copy exactly or answers nil",
            run = function()
                local ring = ProfileBackup.default()
                for revision = 1, 3 do
                    ring = ProfileBackup.capture(
                        ring,
                        { schemaVersion = 16, revision = revision },
                        100 + revision,
                        "interval",
                        3
                    )
                end
                local oldest = ProfileBackup.snapshotAt(ring, 1)
                local newest = ProfileBackup.snapshotAt(ring, 3)
                TestRunner.equal(oldest ~= nil and oldest.revision, 1)
                TestRunner.equal(newest ~= nil and newest.revision, 3)
                TestRunner.equal(
                    newest ~= nil and newest.revision,
                    (ProfileBackup.newest(ring) :: any).revision
                )
                TestRunner.equal(ProfileBackup.snapshotAt(ring, 4), nil)
                TestRunner.equal(ProfileBackup.snapshotAt(ring, 0), nil)
                TestRunner.equal(ProfileBackup.snapshotAt(ring, 1.5), nil)
            end,
        },
    },
}
