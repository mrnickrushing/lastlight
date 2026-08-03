--!strict

--[[
    Milestone 4 exit gate: "forced crashes, lock contention, write failure,
    stale revision, and shutdown pass."

    One section per named scenario. Each asks the same question the gate asks --
    when this goes wrong, does a player lose their game -- rather than whether
    the happy path works.
]]

local Config = require("../../src/shared/Config")
local ProfilePersistence = require("../../src/shared/ProfilePersistence")
local TestRunner = require("../TestRunner")

local SERVER_A = "job-aaaa"
local SERVER_B = "job-bbbb"
local STALE = Config.ProfileLockStaleAfterSeconds

local function profile(revision: number): any
    return { revision = revision, schemaVersion = Config.SaveSchemaVersion }
end

return {
    name = "ProfilePersistence",
    cases = {
        --
        -- Write failure
        --
        {
            name = "a failed read never earns permission to overwrite the save",
            run = function()
                -- The worst thing this system could do is treat "I could not
                -- read your save" as "you have no save". Every unhappy path
                -- must come back read-only.
                local errored = ProfilePersistence.loadOutcome(true, false, nil)
                TestRunner.equal(errored.writable, false)
                TestRunner.equal(errored.useStored, false)
                TestRunner.equal(errored.source, "read_only")

                local timedOut = ProfilePersistence.loadOutcome(false, false, nil)
                TestRunner.equal(timedOut.writable, false)
                TestRunner.equal(timedOut.source, "read_only")

                -- A request that errored after returning data is still an
                -- error: the data cannot be trusted.
                local erroredWithData = ProfilePersistence.loadOutcome(false, true, profile(9))
                TestRunner.equal(erroredWithData.writable, false)
                TestRunner.equal(erroredWithData.useStored, false)
            end,
        },
        {
            name = "a clean read of a real save is the only path that may write",
            run = function()
                local loaded = ProfilePersistence.loadOutcome(true, true, profile(4))
                TestRunner.equal(loaded.source, "datastore")
                TestRunner.equal(loaded.writable, true)
                TestRunner.equal(loaded.useStored, true)

                -- A player with no save yet is writable too, or nobody could
                -- ever have a first session.
                local fresh = ProfilePersistence.loadOutcome(true, true, nil)
                TestRunner.equal(fresh.source, "new")
                TestRunner.equal(fresh.writable, true)
                TestRunner.equal(fresh.useStored, false)
            end,
        },

        --
        -- Lock contention
        --
        {
            name = "a second server cannot take a profile that is still beating",
            run = function()
                local held = ProfilePersistence.lock(SERVER_A, 1000)

                local contended = ProfilePersistence.acquireLock(held, SERVER_B, 1000, STALE)
                TestRunner.equal(contended.acquired, false)
                TestRunner.equal(contended.reason, "held_by_another_server")

                -- Still refused right up to the threshold.
                local justBefore =
                    ProfilePersistence.acquireLock(held, SERVER_B, 1000 + STALE - 1, STALE)
                TestRunner.equal(justBefore.acquired, false)
            end,
        },
        {
            name = "the server already holding a lock keeps it",
            run = function()
                local held = ProfilePersistence.lock(SERVER_A, 1000)
                local again = ProfilePersistence.acquireLock(held, SERVER_A, 1040, STALE)
                TestRunner.equal(again.acquired, true)
                TestRunner.equal(again.reason, "already_held")
            end,
        },
        {
            name = "an unlocked profile is free to take",
            run = function()
                local free = ProfilePersistence.acquireLock(nil, SERVER_A, 1000, STALE)
                TestRunner.equal(free.acquired, true)
                TestRunner.equal(free.reason, "unlocked")
            end,
        },

        --
        -- Forced crash
        --
        {
            name = "a crashed server's lock is reclaimable, or the player never plays again",
            run = function()
                -- A server that dies never runs BindToClose and never releases
                -- anything. The heartbeat going quiet is the only evidence the
                -- next session has.
                local abandoned = ProfilePersistence.lock(SERVER_A, 1000)

                local reclaimed =
                    ProfilePersistence.acquireLock(abandoned, SERVER_B, 1000 + STALE, STALE)
                TestRunner.equal(reclaimed.acquired, true)
                TestRunner.equal(reclaimed.reason, "reclaimed_stale")

                -- Long after, obviously still reclaimable.
                local muchLater =
                    ProfilePersistence.acquireLock(abandoned, SERVER_B, 1000 + STALE * 100, STALE)
                TestRunner.equal(muchLater.acquired, true)
            end,
        },
        {
            name = "corrupt lock bookkeeping never costs a player their save permanently",
            run = function()
                -- Every one of these is unusable as a lock. Refusing on them
                -- would lock the player out forever with no way back.
                local unusable: { any } = {
                    {},
                    { jobId = "" },
                    { jobId = SERVER_A },
                    { heartbeat = 1000 },
                    { jobId = 7, heartbeat = 1000 },
                    { jobId = SERVER_A, heartbeat = "soon" },
                    { jobId = SERVER_A, heartbeat = 0 / 0 },
                    { jobId = SERVER_A, heartbeat = math.huge },
                    "locked",
                    42,
                }
                for _, existing in unusable do
                    local decision = ProfilePersistence.acquireLock(existing, SERVER_B, 1000, STALE)
                    TestRunner.equal(decision.acquired, true)
                    TestRunner.equal(decision.reason, "malformed_lock")
                end
            end,
        },
        {
            name = "a heartbeat from the future is a broken clock, not a live server",
            run = function()
                local skewed = ProfilePersistence.lock(SERVER_A, 1000 + STALE * 5)
                local decision = ProfilePersistence.acquireLock(skewed, SERVER_B, 1000, STALE)
                TestRunner.equal(decision.acquired, true)
                TestRunner.equal(decision.reason, "reclaimed_future")

                -- Mild skew is still treated as a live server, because a clock
                -- a few seconds ahead is ordinary.
                local slight = ProfilePersistence.lock(SERVER_A, 1000 + 5)
                TestRunner.equal(
                    ProfilePersistence.acquireLock(slight, SERVER_B, 1000, STALE).acquired,
                    false
                )
            end,
        },
        {
            name = "the reclaim window leaves room for a slow save",
            run = function()
                -- Reclaiming a merely slow server means two servers writing one
                -- profile, which costs progress. Waiting too long only costs a
                -- wait. The gap has to be several missed beats, not one.
                TestRunner.truthy(
                    Config.ProfileLockStaleAfterSeconds >= Config.ProfileLockHeartbeatSeconds * 5,
                    "a lock must survive several missed heartbeats before it is reclaimable"
                )
            end,
        },
        {
            name = "heartbeats are due on their interval and whenever one is missing",
            run = function()
                local interval = Config.ProfileLockHeartbeatSeconds
                TestRunner.equal(ProfilePersistence.shouldRefreshLock(1000, 1000, interval), false)
                TestRunner.equal(
                    ProfilePersistence.shouldRefreshLock(1000, 1000 + interval, interval),
                    true
                )
                for _, missing in { nil, "never", 0 / 0, math.huge } do
                    TestRunner.equal(
                        ProfilePersistence.shouldRefreshLock(missing, 1000, interval),
                        true
                    )
                end
            end,
        },

        --
        -- Stale revision
        --
        {
            name = "a newer stored profile is never overwritten by an older one in memory",
            run = function()
                local decision = ProfilePersistence.resolveWrite(profile(12), profile(9))
                TestRunner.equal(decision.action, "retain_stored")
                TestRunner.equal(decision.reason, "stored_revision_is_newer")
            end,
        },
        {
            name = "the current revision writes, including an exact tie",
            run = function()
                TestRunner.equal(
                    ProfilePersistence.resolveWrite(profile(9), profile(9)).action,
                    "write"
                )
                TestRunner.equal(
                    ProfilePersistence.resolveWrite(profile(3), profile(40)).action,
                    "write"
                )
                TestRunner.equal(ProfilePersistence.resolveWrite(nil, profile(1)).action, "write")
            end,
        },
        {
            name = "unreadable stored data is replaced rather than deferred to",
            run = function()
                -- Deferring to something nothing can parse would strand the
                -- player on it forever.
                for _, stored in { "corrupt", 42, {}, { revision = "nine" }, { revision = 0 / 0 } } do
                    local decision = ProfilePersistence.resolveWrite(stored, profile(5))
                    TestRunner.equal(decision.action, "write")
                    TestRunner.equal(decision.reason, "stored_profile_unreadable")
                end
            end,
        },
        {
            name = "a write with no revision is refused outright",
            run = function()
                for _, pending in { {}, { revision = "five" }, { revision = 0 / 0 }, "profile" } do
                    TestRunner.throws(function()
                        ProfilePersistence.resolveWrite(profile(1), pending)
                    end)
                end
            end,
        },

        --
        -- Shutdown
        --
        {
            name = "a shutdown flush that loses the race still cannot clobber the winner",
            run = function()
                -- Shutdown is where two servers are likeliest to write at once:
                -- one closing, one that already reclaimed the lock and moved
                -- the player on. The closing server must lose.
                local movedOn = profile(20)
                local closing = profile(17)

                local decision = ProfilePersistence.resolveWrite(movedOn, closing)
                TestRunner.equal(decision.action, "retain_stored")

                -- And the server that took over is free to keep writing.
                local reclaimed = ProfilePersistence.acquireLock(
                    ProfilePersistence.lock(SERVER_A, 1000),
                    SERVER_B,
                    1000 + STALE,
                    STALE
                )
                TestRunner.equal(reclaimed.acquired, true)
                TestRunner.equal(ProfilePersistence.resolveWrite(closing, movedOn).action, "write")
            end,
        },
    },
}
