--!strict

local Strings = require("./Strings")

local BramblewakeEnemies = {}

export type AttackShape = "circle" | "lane"
export type TargetMode = "lantern" | "player"
export type StatusEffect = "drowsy" | "spark_theft"

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
    shape: AttackShape,
    radius: number?,
    width: number?,
    length: number?,
    windup: number,
    stationary: boolean,
    targetMode: TargetMode,
    frontShield: boolean,
    frontalStrikeDamage: number?,
    flankStrikeDamage: number?,
    statusEffect: StatusEffect?,
    statusDuration: number?,
    statusMultiplier: number?,
    statusLanternDamage: number?,
}

local function freezeDefinition(definition: EnemyDefinition): EnemyDefinition
    return table.freeze(definition)
end

local DEFINITIONS: { [string]: EnemyDefinition } = {
    enemy_rootling = freezeDefinition({
        id = "enemy_rootling",
        displayName = "Rootling",
        modelKey = "rootling",
        health = 100,
        speed = 7,
        attackRange = 9,
        attackCooldown = 2,
        playerDamage = 24,
        lanternDamage = 6,
        strikeRange = 9,
        strikeDamage = 34,
        attackId = "rootling_swipe",
        attackName = Strings.get("enemy.rootling_swipe"),
        instruction = Strings.get("enemy.dodge_out_of_the_ring"),
        shape = "circle",
        radius = 7,
        width = nil,
        length = nil,
        windup = 0.9,
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
    enemy_briarback = freezeDefinition({
        id = "enemy_briarback",
        displayName = "Briarback",
        modelKey = "briarback",
        health = 120,
        speed = 5.6,
        attackRange = 10,
        attackCooldown = 2.2,
        playerDamage = 22,
        lanternDamage = 7,
        strikeRange = 10,
        strikeDamage = 34,
        attackId = "briarback_sweep",
        attackName = Strings.get("enemy.briarback_sweep"),
        instruction = Strings.get("enemy.clear_the_lane_flank_it"),
        shape = "lane",
        radius = nil,
        width = 8,
        length = 12,
        windup = 1.05,
        stationary = false,
        targetMode = "lantern",
        frontShield = true,
        frontalStrikeDamage = 8,
        flankStrikeDamage = 40,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    enemy_zombie = freezeDefinition({
        id = "enemy_zombie",
        displayName = Strings.get("enemy.hollow_zombie"),
        modelKey = "zombie",
        health = 68,
        speed = 6.8,
        attackRange = 12,
        attackCooldown = 2.7,
        playerDamage = 12,
        lanternDamage = 4,
        strikeRange = 11,
        strikeDamage = 34,
        attackId = "zombie_rot_miasma",
        attackName = Strings.get("enemy.rot_miasma"),
        instruction = Strings.get("enemy.leave_the_miasma"),
        shape = "circle",
        radius = 10,
        width = nil,
        length = nil,
        windup = 1.25,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "drowsy",
        statusDuration = 3,
        statusMultiplier = 0.65,
        statusLanternDamage = nil,
    }),
    enemy_hollow_crow = freezeDefinition({
        id = "enemy_hollow_crow",
        displayName = "Hollow Crow",
        modelKey = "hollow_crow",
        health = 60,
        speed = 9,
        attackRange = 13,
        attackCooldown = 1.9,
        playerDamage = 10,
        lanternDamage = 5,
        strikeRange = 12,
        strikeDamage = 34,
        attackId = "hollow_crow_swoop",
        attackName = Strings.get("enemy.crow_swoop"),
        instruction = Strings.get("enemy.step_out_of_the_flight_path"),
        shape = "lane",
        radius = nil,
        width = 5,
        length = 16,
        windup = 0.8,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "spark_theft",
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = 4,
    }),
    enemy_snapvine = freezeDefinition({
        id = "enemy_snapvine",
        displayName = "Snapvine",
        modelKey = "snapvine",
        health = 82,
        speed = 0,
        attackRange = 14,
        attackCooldown = 2.4,
        playerDamage = 18,
        lanternDamage = 0,
        strikeRange = 12,
        strikeDamage = 34,
        attackId = "snapvine_bite",
        attackName = Strings.get("enemy.snapvine_bite"),
        instruction = Strings.get("enemy.back_out_of_the_root_ring"),
        shape = "circle",
        radius = 9,
        width = nil,
        length = nil,
        windup = 1.15,
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
    enemy_bark_ram = freezeDefinition({
        id = "enemy_bark_ram",
        displayName = "Bark Ram",
        modelKey = "bark_ram",
        health = 145,
        speed = 5.2,
        attackRange = 14,
        attackCooldown = 2.8,
        playerDamage = 28,
        lanternDamage = 14,
        strikeRange = 11,
        strikeDamage = 34,
        attackId = "bark_ram_charge",
        attackName = Strings.get("enemy.bark_ram_charge"),
        instruction = Strings.get("encounter.clear_the_charge_lane"),
        shape = "lane",
        radius = nil,
        width = 7,
        length = 18,
        windup = 1.4,
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
}

local ORDER = table.freeze({
    "enemy_rootling",
    "enemy_briarback",
    "enemy_zombie",
    "enemy_hollow_crow",
    "enemy_snapvine",
    "enemy_bark_ram",
})

function BramblewakeEnemies.get(enemyId: string): EnemyDefinition?
    return DEFINITIONS[enemyId]
end

function BramblewakeEnemies.require(enemyId: string): EnemyDefinition
    local definition = DEFINITIONS[enemyId]
    assert(definition ~= nil, string.format("unknown Bramblewake enemy ID %q", enemyId))
    return definition
end

function BramblewakeEnemies.order(): { string }
    return table.clone(ORDER)
end

function BramblewakeEnemies.all(): { EnemyDefinition }
    local result: { EnemyDefinition } = {}
    for _, enemyId in ORDER do
        table.insert(result, DEFINITIONS[enemyId])
    end
    return result
end

return table.freeze(BramblewakeEnemies)
