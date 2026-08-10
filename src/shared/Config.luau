--!strict

return table.freeze({
    GameName = "Last Light",
    BuildVersion = "0.53.0",
    MaxExpeditionPlayers = 8,
    NormalDaySeconds = 12 * 60,
    DuskSeconds = 2 * 60,
    NormalNightSeconds = 6 * 60,
    BlackoutNightSeconds = 9 * 60,
    BlackoutInterval = 7,
    SaveSchemaVersion = 25,
    --[[
        The save schema freeze.

        Milestone 14's deliverable list says "frozen save schema except blocker
        fixes", and that is a promise nobody can keep by remembering. Setting
        this to the version the launch candidate ships on makes
        `validate_schema_freeze.py` refuse any bump past it, and the refusal
        names the two ways through: raise the freeze deliberately, or set
        SaveSchemaFreezeOverride to the exact version being allowed and say in
        the pull request why the fix is a blocker.

        `nil` means not frozen, which is the correct state until a launch
        candidate is declared. A freeze that is on during development is a
        freeze somebody turns off and forgets to turn back on.
    ]]
    SaveSchemaFreeze = nil :: number?,
    -- The one version a bump is allowed to reach while the freeze is set. Has
    -- to be typed out, so a blocker fix is a deliberate act rather than a
    -- number quietly incrementing past a guard.
    SaveSchemaFreezeOverride = nil :: number?,
    --[[
        The declared launch candidate.

        QA_RELEASE_PLAN.md's release checklist is nearly all owner rows, so a
        checklist enforced from the day it lands fails every build forever and
        gets switched off within a week. This is the switch that turns it into
        a gate: while it is `nil` the checklist is only checked for shape, and
        setting it to the candidate's build makes every blocking row have to be
        answered before `npm run check` passes.

        Setting it also requires SaveSchemaFreeze to be set, because a launch
        candidate whose save schema is still moving is the failure the freeze
        exists to prevent. The two declarations are one act.
    ]]
    LaunchCandidate = nil :: string?,
    BootstrapTimeoutSeconds = 8,
    FirstNightDuskSeconds = 15,
    FirstNightSeconds = 120,
    BramblewakePreviewSeed = 1847,
    BaseWalkSpeed = 16,
    BaseJumpHeight = 7.2,
    BaseJumpPower = 50,
    SprintWalkSpeed = 24,
    MaxStamina = 100,
    -- A full bar used to empty in about five seconds, which made sprinting
    -- feel broken rather than costly. At 7/s a full bar carries roughly
    -- fourteen seconds of running, long enough to cross the arrival clearing
    -- or break away from a wave, while still forcing a decision in a fight.
    SprintDrainPerSecond = 7,
    StaminaRegenPerSecond = 16,
    StaminaRegenDelaySeconds = 0.75,
    MinSprintStamina = 10,
    DodgeStaminaCost = 35,
    DodgeCooldownSeconds = 1.25,
    DodgeInvulnerabilitySeconds = 0.42,
    DodgeSpeed = 43,
    RootlingAttackWindupSeconds = 0.9,
    RootlingAttackRadius = 7,
    DownedWalkSpeed = 6,
    MaxHealth = 100,
    DownedSeconds = 30,
    ReviveHealth = 35,
    RecoveryHealth = 50,
    -- Standing in the First Lantern's light is the only way a player who is
    -- not a Medic can recover health. Deliberately slow: a reason to come home
    -- between runs, not a substitute for the Medic's burst heal, which stays
    -- the only healing available out in the field.
    LanternSafeRadius = 34,
    LanternRegenPerSecond = 1.6,
    ReviveInvulnerabilitySeconds = 3,
    RecoveryInvulnerabilitySeconds = 5,
    InteractionDistance = 14,
    ReviveDistance = 12,
    ReviveChannelSeconds = 2.5,
    EngineerBraceSeconds = 12,
    EngineerBraceCapacity = 14,
    ActionRatePerSecond = 8,
    --[[
        Quick chat's own budget, separate from the action budget on purpose.
        A player working the phrase wheel must not lose the ability to swing,
        and a player in a fight must not lose the ability to say I AM DOWN.

        Three in hand and roughly one every two seconds after that: enough to
        answer a question and point at something without waiting, not enough
        to fill anybody's screen. The wheel is the one surface in the game
        whose whole purpose is to reach other players, so its ceiling is a
        civility setting rather than an anti-macro one.
    ]]
    QuickChatRatePerSecond = 0.5,
    QuickChatBurst = 3,
    -- How far a ping marker carries. A ping is guidance, and guidance to
    -- somewhere four hundred studs behind you is noise on the screen. The log
    -- line is not distance-limited: hearing that someone is down is the point
    -- even when you cannot reach them.
    QuickChatPingRadius = 400,
    -- What a baseline phone is assumed to have for this experience before
    -- Roblox starts reclaiming. Client memory headroom is measured against it,
    -- so it decides whether that budget reads as healthy or as one asset load
    -- from a reload. Provisional: TECHNICAL_ARCHITECTURE.md says budgets are
    -- finalized on the baseline device during the vertical slice, and this is
    -- one of the numbers that pass exists to replace.
    BaselinePhoneMemoryCeilingMb = 700,
    -- Session locking. A server refreshes its lock on the same ten-second beat
    -- as the autosave, and a lock is reclaimable once it has been silent for
    -- ninety -- nine missed beats. The gap is deliberately wide: reclaiming a
    -- lock that is merely slow means two servers writing one profile, which
    -- costs a player progress, while waiting too long only costs them a wait.
    -- The number that matters after a crash is this one, because a server that
    -- dies never releases its lock and this is the only way the player plays
    -- again.
    ProfileLockHeartbeatSeconds = 10,
    ProfileLockStaleAfterSeconds = 90,
    -- Backups. A copy every autosave would double the write traffic of the
    -- busiest path in the game to photograph a profile that usually has not
    -- meaningfully changed, so ordinary copies are taken at most this often.
    -- A schema change ignores the interval entirely -- that is the one moment
    -- the old shape stops being recoverable from the new one, and it is the
    -- case TECHNICAL_ARCHITECTURE asks for a backup before.
    ProfileBackupIntervalSeconds = 900,
    -- How many copies are kept. Bounded because a DataStore value has a hard
    -- size ceiling and a profile is not small: an unbounded history would
    -- eventually fail every write to the backup key, taking backups down at
    -- exactly the moment the save is growing fastest.
    ProfileBackupRetained = 3,
    -- How often a client reports its own frame and memory samples, and the
    -- floor the server enforces on that remote. Telemetry only: nothing a
    -- client reports here grants it anything.
    PerformanceReportIntervalSeconds = 5,
    --[[
        Creator Dashboard product IDs, keyed by this game's own product id.

        Empty, and that is the correct state: a developer product does not
        exist until somebody creates it in the dashboard and copies the number
        back. A product with no ID here cannot be bought, which is true of all
        of them today. The store flag below is off for the same reason -- there
        is nothing behind it yet.

        The spec that reads this table does not require it to be full. It
        requires that every key in it names a product the catalog knows, so a
        number pasted against a product that does not exist fails on the day it
        is pasted rather than on the day somebody presses buy.
    ]]
    CommerceProductIds = table.freeze({}),
    -- The Last Light universe (10611704810) and its start place. Registered
    -- per the publishing runbook so environment checks can tell a real
    -- production place from an unregistered one.
    ProductionPlaceIds = table.freeze({ 115897110071287 }),
    --[[
        The knobs a closed beta turns.

        BETA_TUNING.md's first table says which number each of Milestone 13's
        five tuning decisions is read on; this is the other half of that
        sentence -- what you actually change once you have read it. The values
        below were locals in four services until this wave, which meant every
        tuning pass was a code change, a rebuild and a publish, and the
        practical consequence of that is not effort: it is that nobody tries a
        second value.

        The rule that keeps this honest is that a knob has exactly **one**
        home. A service that reads `Config.EliteStrikeRange` and also keeps its
        own `STRIKE_RANGE` is a knob somebody will turn and watch do nothing,
        and `TuningKnobs.spec` refuses that shape.

        Engagement distances, in studs. The elite and the boss carry their own
        rather than sharing, because they are different fights: the Old Growth
        is stationary and the Warden Stag closes, so the distance at which each
        becomes unavoidable is a separate decision.
    ]]
    EliteActivationRadius = 28,
    EliteEncounterRadius = 58,
    EliteStrikeRange = 14,
    BossActivationRadius = 27,
    BossEncounterRadius = 56,
    BossStrikeRange = 15,
    -- The town watch's chip damage against anything that reaches the lantern:
    -- how hard, how often, and from how far. The first difficulty dial anybody
    -- reaches for when a night is too hard or too safe, because it changes the
    -- floor of every night rather than one encounter.
    TownWatchChipDamage = 3,
    TownWatchChipEverySeconds = 7,
    TownWatchChipRange = 26,
    -- Where the First Lantern's health tops out. The town's whole difficulty
    -- ceiling: every night is measured against it and every repair is a share
    -- of it.
    LanternHealthCeiling = 100,
    FeatureFlags = table.freeze({
        bounded_join = true,
        first_ten_minutes = true,
        input_action_system = true,
        combat_mobility_enabled = true,
        profession_kits_enabled = true,
        player_survival_enabled = true,
        -- Off: a session starts a fresh run at the lodge. Rejoining to find
        -- yourself halfway through a night you already left reads as the
        -- game having lost track, not as progress. The stage is still
        -- written to the profile, so turning this on resumes as before.
        tutorial_persistence = false,
        content_registry = true,
        bramblewake_events_enabled = true,
        old_growth_elite_enabled = true,
        warden_stag_boss_enabled = true,
        bramblewake_blackout_enabled = true,
        town_night_cycle_enabled = true,
        lobby_departure_enabled = true,
        -- Each departing party gets its own reserved server. Off falls back
        -- to moving the party within the current server, which is also what
        -- happens in Studio and on an unpublished place, where reserving is
        -- impossible.
        reserved_run_servers_enabled = true,
        -- Chat commands for the AdminRoster user IDs. Checked on every
        -- message rather than cached, so turning this off stops them
        -- mid-session for everyone, roster included.
        admin_commands_enabled = true,
        --[[
            The six encounters the Delve and the Fen brought, behind one
            switch. They cannot run at all until a region opens, so this
            starts on: the flag is here to turn them off in a hurry if one
            of them misbehaves in front of players, not to stage them in.
        ]]
        region_encounters_enabled = true,
        region_bramblewake_enabled = true,
        region_ironroot_enabled = true,
        region_mireglass_enabled = true,
        region_tempest_enabled = true,
        region_frostmere_enabled = false,
        region_cinderfall_enabled = false,
        region_hollow_enabled = false,
        --[[
            Quick chat, the only player-to-player channel this game has. On,
            because it is a closed vocabulary of twenty-four phrases rather
            than a text box -- there is nothing a player can compose, so there
            is nothing to moderate. The flag exists so a single press can take
            the channel away if the phrase list turns out to carry a meaning
            nobody intended, which is the failure mode a closed vocabulary
            actually has.
        ]]
        quick_chat_enabled = true,
        --[[
            The cosmetic store. Off, and it stays off until there are products
            in the Creator Dashboard, prices the owner has decided, and a
            purchase that has been made once with a real receipt. A store that
            is on with an empty catalog is a store that shows a player an empty
            room and asks them to trust it.
        ]]
        cosmetic_store_enabled = false,
    }),
    --[[
        Which rung of Milestone 13's rollout each flag has reached.

        The roadmap's four rungs are team and trusted testers, the consented
        allowlist, the larger controlled cohort, and everyone. `off` is the
        rung below all of them.

        This table is not a second copy of the switches above -- it is the
        same fact said in the vocabulary a staged rollout needs, and
        `RolloutCohorts.globalDefault` is what holds the two together: a flag
        at `everyone` is on for a player nobody has said anything about, and
        a flag at any other rung is not. `FeatureFlagService.spec` walks both
        tables and refuses any disagreement, so a flag added to one and not
        the other fails on the day it is added rather than on the day a
        cohort is supposed to see it.

        Nothing sits mid-ladder today, and that is the honest state rather
        than an oversight: the rungs are populations, and there is no
        population yet. `RolloutRoster` below is empty for the same reason
        `CommerceProductIds` is. Why each flag is where it is, is written in
        the matrix in BETA_ROLLOUT.md, which this table is checked against.

        `percent` is carried at every stage rather than only at `cohort`, so
        a flag advancing to the cohort rung cannot arrive without one and
        have somebody pick a number in the same commit that opens the gate.
    ]]
    FeatureFlagRollouts = table.freeze({
        bounded_join = table.freeze({ stage = "everyone", percent = 100 }),
        first_ten_minutes = table.freeze({ stage = "everyone", percent = 100 }),
        input_action_system = table.freeze({ stage = "everyone", percent = 100 }),
        combat_mobility_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        profession_kits_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        player_survival_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        tutorial_persistence = table.freeze({ stage = "off", percent = 0 }),
        content_registry = table.freeze({ stage = "everyone", percent = 100 }),
        bramblewake_events_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        old_growth_elite_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        warden_stag_boss_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        bramblewake_blackout_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        town_night_cycle_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        lobby_departure_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        reserved_run_servers_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        admin_commands_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        region_encounters_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        region_bramblewake_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        region_ironroot_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        region_mireglass_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        region_tempest_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        region_frostmere_enabled = table.freeze({ stage = "off", percent = 0 }),
        region_cinderfall_enabled = table.freeze({ stage = "off", percent = 0 }),
        region_hollow_enabled = table.freeze({ stage = "off", percent = 0 }),
        quick_chat_enabled = table.freeze({ stage = "everyone", percent = 100 }),
        cosmetic_store_enabled = table.freeze({ stage = "off", percent = 0 }),
    }),
    --[[
        The two rosters the first two rungs are read from, by Roblox user ID.

        Empty, and correctly so: a trusted tester is a person the owner has
        asked, and an allowlisted player is one whose guardian has consented.
        Neither is something this repository can invent. A flag standing at
        `team` with an empty roster is on for nobody, which is the safe way
        for this to be wrong.

        By user ID rather than by name, for `AdminRoster`'s reason: a display
        name can be changed by the person using it, and the number they join
        with cannot.
    ]]
    RolloutRoster = table.freeze({
        team = table.freeze({}),
        allowlist = table.freeze({}),
    }),
    Environments = table.freeze({
        ["local"] = table.freeze({
            LogLevel = "debug",
            AllowFlagOverrides = true,
            UsePersistentData = false,
        }),
        test = table.freeze({
            LogLevel = "debug",
            AllowFlagOverrides = true,
            UsePersistentData = false,
        }),
        staging = table.freeze({
            LogLevel = "info",
            AllowFlagOverrides = true,
            UsePersistentData = true,
        }),
        production = table.freeze({
            LogLevel = "info",
            AllowFlagOverrides = false,
            UsePersistentData = true,
        }),
    }),
})
