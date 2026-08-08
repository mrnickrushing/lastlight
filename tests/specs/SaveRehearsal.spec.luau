--!strict

--[[
    Milestone 12's exit gate: "save-loss and purchase-loss rate is zero in a
    forced scenario suite."

    A gate phrased that way needs the forced scenario suite to exist before
    anybody can claim it, and this is that suite. `SaveMigration.spec` already
    holds an era fixture per released schema and refuses a bump without one --
    but it normalizes each fixture **once, straight to current**, which is not
    what a real player's save does.

    A save that has been played since schema 11 has been through fourteen
    migrations *in sequence*, each one reading what the one before it wrote.
    That is a different question, and it is the one a rehearsal is for: a
    migration written against the fixture beside it can be correct about that
    fixture and wrong about the shape the previous migration actually produces.
    The sequential walk below is the only place that difference shows up.

    The forced scenarios are the other half. Each is a way a real save is lost,
    and each is expressed against the pure module that already decides it,
    because the decision is where the loss happens -- the DataStore call around
    it is Roblox's and cannot be exercised here at all:

      * **a disconnect mid-write** -- the write never lands, and the question is
        whether the next session reads the older copy or nothing;
      * **a profile lock** -- somebody else's server holds the claim;
      * **a DataStore failure** -- the read came back an error rather than a
        value, which is the one that has to be told apart from "new player";
      * **a restore from backup** -- an operator rolling a save back;
      * **and every one of them again with a purchase in the mailbox**, because
        a receipt is the one thing in this game a player paid real money for and
        it lives *outside* the profile by construction, so nothing the profile
        loses can take it.

    The last of those is the point of running the suite twice. Purchase loss and
    save loss are separate gates in RELEASE_GATES.md, and a scenario suite that
    only checked the profile would pass on a build where every rollback quietly
    dropped a paid-for cosmetic.
]]

local Config = require("../../src/shared/Config")
local Entitlements = require("../../src/shared/Entitlements")
local ProfileBackup = require("../../src/shared/ProfileBackup")
local ProfilePersistence = require("../../src/shared/ProfilePersistence")
local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

local NOW = 9000
local OUR_JOB = "job_this_server"
local OTHER_JOB = "job_other_server"

--[[
    The oldest save this rehearsal walks, written the way schema 11 wrote them.

    Eleven rather than one because that is where the roadmap's own phrasing
    starts -- "a schema-11 profile arrives at current with every field that ever
    meant something still meaning it" -- and because a schema-1 save has almost
    nothing in it to lose. What makes this fixture worth walking is that every
    field in it was earned: a finished tutorial, a chosen tool, a chosen
    profession, twelve nights of town, a resolved chapter with its transaction
    id, and materials in the pouch.
]]
local function era11(): any
    return {
        schemaVersion = 11,
        createdAt = 100,
        updatedAt = 200,
        revision = 61,
        tutorial = { stage = "complete", complete = true, selectedTool = "axe" },
        profession = { selectedId = "profession_engineer" },
        town = { nightNumber = 12 },
        inventory = { materials = { material_heartwood = 9, material_meadow_fiber = 4 } },
        gear = { gear_meadow_satchel = 1 },
        equipped = { weapon = "gear_thornwood_bow" },
        story = {
            chapterOne = {
                completedAt = 150,
                decision = "restore_farmland",
                status = "complete",
                wardenOutcome = "preserved",
                transactionId = "chapter_1:era11:rehearsal",
            },
        },
    }
end

--[[
    What that save earned, as facts rather than as a shape. A rehearsal that
    only checked the shape would pass on a migration that reset every one of
    them.

    Deliberately not the revision. A revision is bookkeeping about writes rather
    than something a player earned, and a restore is *supposed* to raise it --
    the walk checks it separately, where holding still is the correct answer.
]]
local function assertEarned(profile: any, label: string)
    TestRunner.equal(profile.tutorial.complete, true, label .. ": the tutorial came undone")
    TestRunner.equal(profile.tutorial.selectedTool, "axe", label .. ": the chosen tool was lost")
    TestRunner.equal(
        profile.profession.selectedId,
        "profession_engineer",
        label .. ": the profession was lost"
    )
    TestRunner.equal(profile.town.nightNumber, 12, label .. ": nights survived were reset")
    TestRunner.equal(
        profile.story.chapterOne.status,
        "complete",
        label .. ": a resolved chapter came unresolved"
    )
    TestRunner.equal(
        profile.story.chapterOne.transactionId,
        "chapter_1:era11:rehearsal",
        label .. ": the chapter's transaction id was dropped"
    )
    TestRunner.equal(
        profile.inventory.materials.material_heartwood,
        9,
        label .. ": banked materials were lost"
    )
    TestRunner.equal(profile.gear.gear_meadow_satchel, 1, label .. ": crafted gear was lost")
end

local function receipt(purchaseId: string): any
    return {
        purchaseId = purchaseId,
        productId = "product_lantern_keeper_coat",
        userId = 4242,
        receivedAt = NOW,
    }
end

local function resolve(productId: string): { string }
    return if productId == "product_lantern_keeper_coat"
        then { "cosmetic_lantern_keeper_coat" }
        else {}
end

return {
    name = "SaveRehearsal",
    cases = {
        {
            --[[
                The walk, one era at a time.

                `SaveSchema.normalize` is version-agnostic -- it reads whatever
                fields are present -- so stepping it once per era with the
                version stamped back down is what actually re-runs each
                migration against the previous one's output rather than against
                the fixture that was written beside it.
            ]]
            name = "a schema-11 save walked one era at a time arrives whole",
            run = function()
                local profile: any = era11()
                for version = 11, Config.SaveSchemaVersion - 1 do
                    local stepped = SaveSchema.normalize(profile, NOW + version)
                    TestRunner.equal(
                        stepped.schemaVersion,
                        Config.SaveSchemaVersion,
                        string.format("step from %d did not land on current", version)
                    )
                    assertEarned(stepped, string.format("after the step from %d", version))
                    TestRunner.equal(
                        stepped.revision,
                        61,
                        string.format("the revision moved stepping from %d", version)
                    )
                    -- Stamped back down so the next pass is another migration
                    -- rather than a no-op over an already-current profile.
                    profile = table.clone(stepped)
                    profile.schemaVersion = version + 1
                end

                local final = SaveSchema.normalize(profile, NOW + 100)
                assertEarned(final, "at the end of the walk")
                TestRunner.equal(final.schemaVersion, Config.SaveSchemaVersion)
                -- And every field the current default produces is present, so
                -- the walk cannot have arrived at something merely plausible.
                for _, field in
                    {
                        "inventory",
                        "loadouts",
                        "gearWear",
                        "gearTraits",
                        "quests",
                        "social",
                        "commerce",
                        "expeditions",
                    }
                do
                    TestRunner.truthy(final[field] ~= nil, "the walk arrived without " .. field)
                end
            end,
        },
        {
            --[[
                A disconnect mid-write.

                The write never reached the store, so the stored copy is still
                the older revision and the session that comes next has to read
                it rather than nothing. The failure this guards against is the
                opposite of the obvious one: not that the newer write is lost --
                it is, and that is what a disconnect means -- but that the older
                one is thrown away too because something decided an interrupted
                write left the key unusable.
            ]]
            name = "a disconnect mid-write loses the unsaved beat and nothing else",
            run = function()
                local stored = SaveSchema.normalize(era11(), NOW)
                local inFlight = SaveSchema.withNightNumber(stored, 13, NOW + 1)
                TestRunner.equal(inFlight.revision, stored.revision + 1)

                -- The write never happened, so the next load sees `stored`.
                local outcome = ProfilePersistence.loadOutcome(true, true, stored)
                TestRunner.equal(outcome.useStored, true)
                TestRunner.equal(outcome.writable, true)
                local reloaded = SaveSchema.normalize(stored, NOW + 2)
                assertEarned(reloaded, "after a disconnect mid-write")
                TestRunner.equal(reloaded.town.nightNumber, 12)

                -- And the interrupted write is still the newer one, so if it
                -- does land later it wins rather than being refused.
                local decision = ProfilePersistence.resolveWrite(stored, inFlight)
                TestRunner.equal(decision.action, "write")
            end,
        },
        {
            --[[
                A profile another server still holds.

                Read-only rather than refused: the player gets a session and
                nothing they do in it can overwrite the copy the other server is
                still writing. The loss this prevents is the one that would
                happen if we wrote anyway -- two servers with two revisions, and
                whichever saves last wins.
            ]]
            name = "a locked profile is played read-only and never overwritten",
            run = function()
                local held = SaveSchema.normalize(era11(), NOW)
                held.sessionLock = ProfilePersistence.lock(OTHER_JOB, NOW)

                local claim = ProfilePersistence.acquireLock(
                    held.sessionLock,
                    OUR_JOB,
                    NOW + 5,
                    Config.ProfileLockStaleAfterSeconds
                )
                TestRunner.equal(claim.acquired, false)

                -- What the player is given is still their own save, whole.
                assertEarned(SaveSchema.normalize(held, NOW + 5), "while locked elsewhere")

                -- And the lock is reclaimable once it stops beating, or the
                -- player never plays again after a server crash.
                local afterStale = ProfilePersistence.acquireLock(
                    held.sessionLock,
                    OUR_JOB,
                    NOW + Config.ProfileLockStaleAfterSeconds + 1,
                    Config.ProfileLockStaleAfterSeconds
                )
                TestRunner.equal(afterStale.acquired, true)
            end,
        },
        {
            --[[
                A DataStore that answered with an error, or did not answer.

                This is the scenario that has to be told apart from a new
                player, and getting it wrong is how a save is destroyed rather
                than merely unavailable: a failed read treated as "no stored
                profile" hands the player a default and the next write puts it
                over the top of everything they had.
            ]]
            name = "a failed read never earns permission to overwrite",
            run = function()
                local errored = ProfilePersistence.loadOutcome(true, false, nil)
                TestRunner.equal(errored.writable, false)
                TestRunner.equal(errored.useStored, false)
                TestRunner.equal(errored.source, "read_only")

                local timedOut = ProfilePersistence.loadOutcome(false, false, nil)
                TestRunner.equal(timedOut.writable, false)
                TestRunner.equal(timedOut.source, "read_only")

                -- A genuine new player is the only shape that writes.
                local fresh = ProfilePersistence.loadOutcome(true, true, nil)
                TestRunner.equal(fresh.writable, true)
                TestRunner.equal(fresh.source, "new")
            end,
        },
        {
            --[[
                An operator rolling a save back.

                A restore has to come back with a revision higher than whatever
                is stored, or the write that follows it is refused as stale and
                the restore silently does nothing -- which is the worst possible
                outcome, because the operator has been told it worked.
            ]]
            name = "a restore from backup outranks whatever is stored now",
            run = function()
                local good = SaveSchema.normalize(era11(), NOW)
                local ring =
                    ProfileBackup.capture(ProfileBackup.default(), good, NOW, "pre_restore", 3)
                local damaged = SaveSchema.withNightNumber(good, 1, NOW + 10)

                local snapshot = ProfileBackup.newest(ring)
                TestRunner.truthy(snapshot ~= nil, "the ring captured nothing")
                local restored = ProfileBackup.restoredProfile(snapshot, damaged.revision, NOW + 20)

                assertEarned(SaveSchema.normalize(restored, NOW + 20), "after a restore")
                TestRunner.truthy(
                    restored.revision > damaged.revision,
                    "a restore that does not outrank the live save is refused as stale"
                )
                TestRunner.equal(ProfilePersistence.resolveWrite(damaged, restored).action, "write")
                TestRunner.equal(restored.sessionLock, nil, "a restore carried a lock with it")
            end,
        },
        {
            --[[
                Every scenario above, again, with money in it.

                The mailbox lives outside the profile by construction, and this
                is the case that construction exists for: a receipt held while
                the profile could not be written must survive the profile being
                rolled back, refused, or replaced. Purchase loss is its own gate
                for the same reason -- a suite that only watched the profile
                would pass on a build where every rollback dropped a paid-for
                cosmetic.
            ]]
            name = "a purchase in the mailbox survives every one of those scenarios",
            run = function()
                local mailbox = Entitlements.emptyMailbox()
                local enqueued = Entitlements.enqueue(mailbox, receipt("purchase_rehearsal"))
                TestRunner.equal(#enqueued, 1)

                -- Read-only, locked, and failed-read sessions all leave it
                -- exactly where it was: nothing about a profile that cannot be
                -- written touches a mailbox that is not in it.
                for _, outcome in
                    {
                        ProfilePersistence.loadOutcome(true, false, nil),
                        ProfilePersistence.loadOutcome(false, false, nil),
                    }
                do
                    TestRunner.equal(outcome.writable, false)
                    TestRunner.equal(#Entitlements.normalizeMailbox(enqueued), 1)
                end

                -- A rollback replaces the profile and cannot reach the mailbox.
                local good = SaveSchema.normalize(era11(), NOW)
                local ring =
                    ProfileBackup.capture(ProfileBackup.default(), good, NOW, "pre_restore", 3)
                local restored = ProfileBackup.restoredProfile(
                    ProfileBackup.newest(ring),
                    good.revision + 5,
                    NOW + 20
                )
                TestRunner.equal(#Entitlements.normalizeMailbox(enqueued), 1)

                -- And when the profile is finally writable, the held receipt
                -- drains into it and grants exactly once.
                local state = SaveSchema.commerce(SaveSchema.normalize(restored, NOW + 20))
                local afterDrain, remaining, granted = Entitlements.drain(state, enqueued, resolve)
                TestRunner.equal(#remaining, 0, "a resolvable receipt stayed in the mailbox")
                TestRunner.equal(#granted, 1)
                TestRunner.equal(granted[1], "cosmetic_lantern_keeper_coat")
                TestRunner.equal(
                    Entitlements.owns(afterDrain, "cosmetic_lantern_keeper_coat"),
                    true
                )

                -- Draining the same mailbox again grants nothing new, which is
                -- the retry a platform makes while it waits for the first
                -- answer to be acknowledged.
                local twice, _, grantedAgain = Entitlements.drain(afterDrain, enqueued, resolve)
                TestRunner.equal(#grantedAgain, 0, "a retry granted a second copy")
                TestRunner.equal(Entitlements.owns(twice, "cosmetic_lantern_keeper_coat"), true)
            end,
        },
        {
            --[[
                And the rehearsal's own version of the walk: money that was
                bought under an older schema is still owned under the current
                one.

                An entitlement is the one field on this profile that cost a real
                person real currency, so a migration that dropped it is the most
                expensive thing this suite can catch. Walked era by era rather
                than normalized once, for the reason the first case exists.
            ]]
            name = "a cosmetic bought under an older schema survives the walk to current",
            run = function()
                local profile: any = SaveSchema.normalize(era11(), NOW)
                profile = SaveSchema.withCommerce(profile, {
                    entitlements = { cosmetic_lantern_keeper_coat = true },
                    -- The ledger stores when a purchase settled, not merely that it
                    -- did, so a boolean here would be dropped by normalize.
                    processed = { purchase_rehearsal = NOW },
                    equipped = { outfit = "cosmetic_lantern_keeper_coat" },
                }, NOW)
                profile = table.clone(profile)
                profile.schemaVersion = 24

                for version = 24, Config.SaveSchemaVersion - 1 do
                    local stepped = SaveSchema.normalize(profile, NOW + version)
                    local commerce = SaveSchema.commerce(stepped)
                    TestRunner.equal(
                        Entitlements.owns(commerce, "cosmetic_lantern_keeper_coat"),
                        true,
                        string.format("the entitlement was dropped stepping from %d", version)
                    )
                    TestRunner.equal(
                        Entitlements.equippedIn(commerce, "outfit"),
                        "cosmetic_lantern_keeper_coat",
                        string.format("what was worn came off stepping from %d", version)
                    )
                    TestRunner.equal(
                        commerce.processed.purchase_rehearsal,
                        NOW,
                        string.format("the processed ledger was cleared stepping from %d", version)
                    )
                    profile = table.clone(stepped)
                    profile.schemaVersion = version + 1
                end
            end,
        },
    },
}
