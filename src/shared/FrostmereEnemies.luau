--!strict

--[[
    Frostmere Vale's six standard enemies.

    Every other roster answers the question "how does it reach you". This
    one answers "what does it take from you first". The hush pup hunts
    noise, so it finds whoever moved carelessly; the rime shell wears
    armour that only melts near warmth, so it has to be fought where a
    fire is; the cold echo freezes the ability you just used, which is the
    only roster in the game that spends a player's kit rather than their
    health.

    Which is why so little here hits hard. The valley's damage numbers are
    the lowest of any region and its status effects the most common: what
    kills in Frostmere is being cold, quiet and out of options at the same
    time, and these six are the things that arrange that.
]]

local FrostmereEnemies = {}

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
    -- Hunts noise, so it arrives at whoever moved carelessly rather than\n    -- at whoever is closest.
    enemy_hush_pup = freezeDefinition({
        id = "enemy_hush_pup",
        displayName = "Hush Pup",
        modelKey = "hush_pup",
        health = 75,
        speed = 9,
        attackRange = 8,
        attackCooldown = 2,
        playerDamage = 16,
        lanternDamage = 4,
        strikeRange = 9,
        strikeDamage = 40,
        attackId = "hush_pup_pounce",
        attackName = "HUSH POUNCE",
        instruction = "IT HEARD YOU — BREAK ITS LINE",
        shape = "circle",
        radius = 6,
        width = nil,
        length = nil,
        windup = 0.8,
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
    -- Its armour only melts near warmth, so the fight has to be taken to a\n    -- hearth. Struck cold it is the hardest thing in the valley; struck\n    -- warm it is the softest.
    enemy_rime_shell = freezeDefinition({
        id = "enemy_rime_shell",
        displayName = "Rime Shell",
        modelKey = "rime_shell",
        health = 160,
        speed = 3.8,
        attackRange = 9,
        attackCooldown = 3.2,
        playerDamage = 22,
        lanternDamage = 12,
        strikeRange = 10,
        strikeDamage = 26,
        attackId = "rime_shell_crush",
        attackName = "RIME CRUSH",
        instruction = "FIGHT IT WHERE THE FIRE IS",
        shape = "circle",
        radius = 8,
        width = nil,
        length = nil,
        windup = 1.5,
        stationary = false,
        targetMode = "lantern",
        frontShield = true,
        frontalStrikeDamage = 6,
        flankStrikeDamage = 40,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    -- Makes sound somewhere it is not. Frail, and the reason a party stops\n    -- trusting its ears.
    enemy_bell_moth = freezeDefinition({
        id = "enemy_bell_moth",
        displayName = "Bell Moth",
        modelKey = "bell_moth",
        health = 60,
        speed = 7.5,
        attackRange = 14,
        attackCooldown = 2.6,
        playerDamage = 14,
        lanternDamage = 6,
        strikeRange = 9,
        strikeDamage = 42,
        attackId = "bell_moth_chime",
        attackName = "FALSE CHIME",
        instruction = "THE SOUND IS NOT WHERE IT SAYS",
        shape = "circle",
        radius = 9,
        width = nil,
        length = nil,
        windup = 1.2,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "drowsy",
        statusDuration = 6,
        statusMultiplier = 0.78,
        statusLanternDamage = nil,
    }),
    -- Buried, and visible only as a trail moving under the snow. It never\n    -- moves once it has you.
    enemy_snowbound = freezeDefinition({
        id = "enemy_snowbound",
        displayName = "Snowbound",
        modelKey = "snowbound",
        health = 130,
        speed = 0,
        attackRange = 7,
        attackCooldown = 3,
        playerDamage = 26,
        lanternDamage = 10,
        strikeRange = 10,
        strikeDamage = 34,
        attackId = "snowbound_grab",
        attackName = "BURIED GRAB",
        instruction = "THE TRAIL IN THE SNOW IS THE WARNING",
        shape = "circle",
        radius = 7,
        width = nil,
        length = nil,
        windup = 1.35,
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
    -- Freezes the ability a player just spent, which is the only enemy in\n    -- the game that costs a kit rather than health.
    enemy_cold_echo = freezeDefinition({
        id = "enemy_cold_echo",
        displayName = "Cold Echo",
        modelKey = "cold_echo",
        health = 90,
        speed = 6.2,
        attackRange = 12,
        attackCooldown = 3.4,
        playerDamage = 18,
        lanternDamage = 7,
        strikeRange = 10,
        strikeDamage = 36,
        attackId = "cold_echo_still",
        attackName = "STILLED HAND",
        instruction = "IT IS TAKING WHAT YOU JUST USED",
        shape = "lane",
        radius = nil,
        width = 6,
        length = 22,
        windup = 1.45,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "drowsy",
        statusDuration = 8,
        statusMultiplier = 0.7,
        statusLanternDamage = nil,
    }),
    -- Eats the floor and the walls, which in a valley of shelters is the\n    -- most expensive thing anything here can do.
    enemy_ice_borer = freezeDefinition({
        id = "enemy_ice_borer",
        displayName = "Ice Borer",
        modelKey = "ice_borer",
        health = 115,
        speed = 5,
        attackRange = 11,
        attackCooldown = 3.6,
        playerDamage = 24,
        lanternDamage = 18,
        strikeRange = 11,
        strikeDamage = 32,
        attackId = "ice_borer_undermine",
        attackName = "UNDERMINE",
        instruction = "GET OFF WHAT IT IS EATING",
        shape = "circle",
        radius = 11,
        width = nil,
        length = nil,
        windup = 1.7,
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
    "enemy_hush_pup",
    "enemy_rime_shell",
    "enemy_bell_moth",
    "enemy_snowbound",
    "enemy_cold_echo",
    "enemy_ice_borer",
})
function FrostmereEnemies.get(enemyId: string): EnemyDefinition?
    return DEFINITIONS[enemyId]
end

function FrostmereEnemies.require(enemyId: string): EnemyDefinition
    local definition = DEFINITIONS[enemyId]
    assert(definition ~= nil, string.format("unknown Frostmere enemy ID %q", enemyId))
    return definition
end

function FrostmereEnemies.order(): { string }
    return table.clone(ORDER)
end

function FrostmereEnemies.all(): { EnemyDefinition }
    local result: { EnemyDefinition } = {}
    for _, enemyId in ORDER do
        table.insert(result, DEFINITIONS[enemyId])
    end
    return result
end

return table.freeze(FrostmereEnemies)
