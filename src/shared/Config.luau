--!strict

return table.freeze({
    GameName = "Last Light",
    BuildVersion = "0.46.1",
    MaxExpeditionPlayers = 8,
    NormalDaySeconds = 12 * 60,
    DuskSeconds = 2 * 60,
    NormalNightSeconds = 6 * 60,
    BlackoutNightSeconds = 9 * 60,
    BlackoutInterval = 7,
    SaveSchemaVersion = 11,
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
