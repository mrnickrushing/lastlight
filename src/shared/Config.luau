--!strict

return table.freeze({
    GameName = "Last Light",
    BuildVersion = "0.47.0",
    MaxExpeditionPlayers = 8,
    NormalDaySeconds = 12 * 60,
    DuskSeconds = 2 * 60,
    NormalNightSeconds = 6 * 60,
    BlackoutNightSeconds = 9 * 60,
    BlackoutInterval = 7,
    SaveSchemaVersion = 12,
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
    -- How often a client reports its own frame and memory samples, and the
    -- floor the server enforces on that remote. Telemetry only: nothing a
    -- client reports here grants it anything.
    PerformanceReportIntervalSeconds = 5,
    -- The Last Light universe (10611704810) and its start place. Registered
    -- per the publishing runbook so environment checks can tell a real
    -- production place from an unregistered one.
    ProductionPlaceIds = table.freeze({ 115897110071287 }),
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
        region_bramblewake_enabled = true,
        region_ironroot_enabled = false,
        region_mireglass_enabled = false,
        region_tempest_enabled = false,
        region_frostmere_enabled = false,
        region_cinderfall_enabled = false,
        region_hollow_enabled = false,
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
