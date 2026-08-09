--!strict

--[[
    Tempest Reach's six standard enemies.

    The Fen waits and the Delve charges; the Reach *throws*. Almost
    everything here attacks along a line the weather is already pushing,
    so its fights are fought sideways: you are rarely running from the
    creature, you are getting out from between it and where the wind is
    going. Two of them cannot be beaten by damage alone -- the salt husk
    reforms unless it is dried out, and the storm ray's charge has to be
    grounded rather than dodged -- which is the region's whole lesson
    about weather being a thing you route rather than survive.
]]

local Strings = require("./Strings")

local TempestEnemies = {}

export type EnemyDefinition = {
    id: string,
    displayName: string,
    modelKey: string,
    health: number,
    speed: number,
    attackRange: number,
    attackCooldown: number,
    playerDamage: number,
    lanternDamage: number,
    strikeRange: number,
    strikeDamage: number,
    attackId: string,
    attackName: string,
    instruction: string,
    shape: "circle" | "lane",
    radius: number?,
    width: number?,
    length: number?,
    windup: number,
    stationary: boolean,
    targetMode: "lantern" | "player",
    frontShield: boolean,
    frontalStrikeDamage: number?,
    flankStrikeDamage: number?,
    statusEffect: ("drowsy" | "spark_theft")?,
    statusDuration: number?,
    statusMultiplier: number?,
    statusLanternDamage: number?,
}

local function freezeDefinition(definition: EnemyDefinition): EnemyDefinition
    return table.freeze(definition)
end

local DEFINITIONS: { [string]: EnemyDefinition } = {
    -- Small, fast, and always shooting along the wind rather than at you.
    enemy_gale_imp = freezeDefinition({
        id = "enemy_gale_imp",
        displayName = "Gale Imp",
        modelKey = "gale_imp",
        health = 70,
        speed = 8.5,
        attackRange = 12,
        attackCooldown = 2.2,
        playerDamage = 20,
        lanternDamage = 5,
        strikeRange = 9,
        strikeDamage = 38,
        attackId = "gale_imp_gust",
        attackName = Strings.get("enemy.gale_imp_gust"),
        instruction = Strings.get("enemy.step_out_of_the_gust_line"),
        shape = "lane",
        radius = nil,
        width = 5,
        length = 18,
        windup = 0.95,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    -- Climbs whatever a town built to keep the sea out, and pulls it down.
    enemy_wreck_crawler = freezeDefinition({
        id = "enemy_wreck_crawler",
        displayName = Strings.get("enemy.wreck_crawler"),
        modelKey = "wreck_crawler",
        health = 120,
        speed = 6,
        attackRange = 10,
        attackCooldown = 2.6,
        playerDamage = 26,
        lanternDamage = 14,
        strikeRange = 10,
        strikeDamage = 34,
        attackId = "wreck_crawler_haul",
        attackName = Strings.get("enemy.rigging_haul"),
        instruction = Strings.get("enemy.get_off_the_rigging"),
        shape = "circle",
        radius = 8,
        width = nil,
        length = nil,
        windup = 1.25,
        stationary = false,
        targetMode = "lantern",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    -- Its charge is passed through grounding, not dodged. Outrunning a\n    -- thing that moves at nine and a half is not a plan.
    enemy_storm_ray = freezeDefinition({
        id = "enemy_storm_ray",
        displayName = "Storm Ray",
        modelKey = "storm_ray",
        health = 95,
        speed = 9.5,
        attackRange = 20,
        attackCooldown = 3.2,
        playerDamage = 32,
        lanternDamage = 8,
        strikeRange = 10,
        strikeDamage = 36,
        attackId = "storm_ray_charge",
        attackName = Strings.get("enemy.storm_ray_charge"),
        instruction = Strings.get("enemy.ground_it_do_not_outrun_it"),
        shape = "lane",
        radius = nil,
        width = 7,
        length = 26,
        windup = 1.35,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    -- Reforms near water unless it is dried. Damage alone only postpones.
    enemy_salt_husk = freezeDefinition({
        id = "enemy_salt_husk",
        displayName = "Salt Husk",
        modelKey = "salt_husk",
        health = 110,
        speed = 4.4,
        attackRange = 9,
        attackCooldown = 2.8,
        playerDamage = 24,
        lanternDamage = 10,
        strikeRange = 10,
        strikeDamage = 32,
        attackId = "salt_husk_break",
        attackName = Strings.get("enemy.salt_break"),
        instruction = Strings.get("enemy.dry_it_out_or_it_comes"),
        shape = "circle",
        radius = 7,
        width = nil,
        length = nil,
        windup = 1.15,
        stationary = false,
        targetMode = "lantern",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "drowsy",
        statusDuration = 6,
        statusMultiplier = 0.82,
        statusLanternDamage = nil,
    }),
    -- Never moves. Pulls you somewhere worse, which is the same problem\n    -- from the other end.
    enemy_rigging_snare = freezeDefinition({
        id = "enemy_rigging_snare",
        displayName = Strings.get("enemy.rigging_snare"),
        modelKey = "rigging_snare",
        health = 85,
        speed = 0,
        attackRange = 16,
        attackCooldown = 3,
        playerDamage = 18,
        lanternDamage = 6,
        strikeRange = 11,
        strikeDamage = 40,
        attackId = "rigging_snare_pull",
        attackName = Strings.get("enemy.snare_pull"),
        instruction = Strings.get("enemy.cut_loose_before_the_hazard"),
        shape = "lane",
        radius = nil,
        width = 4,
        length = 20,
        windup = 1.1,
        stationary = true,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    -- Wave-shaped: wide, slow, and aimed at what a town built. Its face\n    -- is a wall and its flank is not, which is the Crank Guard's lesson\n    -- taught by water.
    enemy_breaker = freezeDefinition({
        id = "enemy_breaker",
        displayName = "Breaker",
        modelKey = "breaker",
        health = 150,
        speed = 5.2,
        attackRange = 14,
        attackCooldown = 3.6,
        playerDamage = 30,
        lanternDamage = 20,
        strikeRange = 12,
        strikeDamage = 34,
        attackId = "breaker_wave",
        attackName = Strings.get("enemy.breaker"),
        instruction = Strings.get("enemy.brace_or_clear_the_line"),
        shape = "lane",
        radius = nil,
        width = 12,
        length = 24,
        windup = 1.6,
        stationary = false,
        targetMode = "lantern",
        frontShield = true,
        frontalStrikeDamage = 10,
        flankStrikeDamage = 42,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
}

local ORDER = table.freeze({
    "enemy_gale_imp",
    "enemy_wreck_crawler",
    "enemy_storm_ray",
    "enemy_salt_husk",
    "enemy_rigging_snare",
    "enemy_breaker",
})
function TempestEnemies.get(enemyId: string): EnemyDefinition?
    return DEFINITIONS[enemyId]
end

function TempestEnemies.require(enemyId: string): EnemyDefinition
    local definition = DEFINITIONS[enemyId]
    assert(definition ~= nil, string.format("unknown Tempest enemy ID %q", enemyId))
    return definition
end

function TempestEnemies.order(): { string }
    return table.clone(ORDER)
end

function TempestEnemies.all(): { EnemyDefinition }
    local result: { EnemyDefinition } = {}
    for _, enemyId in ORDER do
        table.insert(result, DEFINITIONS[enemyId])
    end
    return result
end

return table.freeze(TempestEnemies)
