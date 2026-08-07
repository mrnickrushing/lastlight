--!strict

--[[
    Cinderfall Crown's six standard enemies.

    The other rosters ask how a thing reaches you or what it takes when it
    does. This one asks whether it is real. Half of these are not
    creatures at all -- the ash extra repeats one ceremonial attack
    forever because that is the move it was cast mid-way through, the
    false citizen is scenery until it is caught mending the scenery -- and
    a party's first job in any Crown fight is working out which of the
    things in front of them is actually doing something.

    That is why so much of the Crown's threat is indirect. The crown spark
    does no meaningful damage and makes everything near it worse; the
    false citizen repairs what you just broke; the parade giant does not
    chase, it divides. Killing the wrong one first is how a Crown fight
    goes long, and going long is what the region punishes.
]]

local CinderfallEnemies = {}

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
    -- Cast mid-gesture and still making it. Predictable to the point of\n    -- being a rhythm, which is the only kindness the Crown offers.
    enemy_ash_extra = freezeDefinition({
        id = "enemy_ash_extra",
        displayName = "Ash Extra",
        modelKey = "ash_extra",
        health = 85,
        speed = 6.5,
        attackRange = 9,
        attackCooldown = 2.4,
        playerDamage = 17,
        lanternDamage = 6,
        strikeRange = 9,
        strikeDamage = 38,
        attackId = "ash_extra_ovation",
        attackName = "CEREMONIAL BOW",
        instruction = "IT ONLY KNOWS THE ONE MOVE",
        shape = "circle",
        radius = 7,
        width = nil,
        length = nil,
        windup = 1.1,
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
    -- Reflects anything thrown at its face, which makes it the first\n    -- enemy in the game that punishes the safe option.
    enemy_glass_knight = freezeDefinition({
        id = "enemy_glass_knight",
        displayName = "Glass Knight",
        modelKey = "glass_knight",
        health = 150,
        speed = 4.6,
        attackRange = 10,
        attackCooldown = 3.2,
        playerDamage = 24,
        lanternDamage = 14,
        strikeRange = 10,
        strikeDamage = 30,
        attackId = "glass_knight_parry",
        attackName = "MIRROR PARRY",
        instruction = "GO ROUND — IT SENDS THE FRONT BACK",
        shape = "lane",
        radius = nil,
        width = 7,
        length = 26,
        windup = 1.5,
        stationary = false,
        targetMode = "lantern",
        frontShield = true,
        frontalStrikeDamage = 5,
        flankStrikeDamage = 42,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    -- Travels between heat sources, so the lit modules are the ones it\n    -- can reach and a cold room is a room it has to cross open ground\n    -- to enter.
    enemy_kiln_worm = freezeDefinition({
        id = "enemy_kiln_worm",
        displayName = "Kiln Worm",
        modelKey = "kiln_worm",
        health = 120,
        speed = 7.8,
        attackRange = 8,
        attackCooldown = 2.8,
        playerDamage = 21,
        lanternDamage = 9,
        strikeRange = 10,
        strikeDamage = 34,
        attackId = "kiln_worm_surface",
        attackName = "SURFACING",
        instruction = "IT COMES UP WHERE THE HEAT IS",
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
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    -- Almost harmless alone and the reason a Crown fight is hard. It\n    -- makes everything near it better, so it is always the correct\n    -- target and never the obvious one.
    enemy_crown_spark = freezeDefinition({
        id = "enemy_crown_spark",
        displayName = "Crown Spark",
        modelKey = "crown_spark",
        health = 55,
        speed = 9.2,
        attackRange = 13,
        attackCooldown = 3.4,
        playerDamage = 8,
        lanternDamage = 4,
        strikeRange = 9,
        strikeDamage = 20,
        attackId = "crown_spark_gild",
        attackName = "GILDING",
        instruction = "KILL THE SPARK, NOT WHAT IT IS FEEDING",
        shape = "circle",
        radius = 13,
        width = nil,
        length = nil,
        windup = 1.4,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "spark_theft",
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = 5,
    }),
    -- Slow, enormous, and uninterested in chasing anyone. It walks its\n    -- route, and what it does is separate a party from itself.
    enemy_parade_giant = freezeDefinition({
        id = "enemy_parade_giant",
        displayName = "Parade Giant",
        modelKey = "parade_giant",
        health = 240,
        speed = 2.6,
        attackRange = 12,
        attackCooldown = 4,
        playerDamage = 26,
        lanternDamage = 20,
        strikeRange = 12,
        strikeDamage = 40,
        attackId = "parade_giant_sweep",
        attackName = "PROCESSIONAL SWEEP",
        instruction = "DO NOT LET IT CUT THE PARTY IN HALF",
        shape = "lane",
        radius = nil,
        width = 11,
        length = 34,
        windup = 2,
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
    -- Stands in the scenery until it is caught repairing the scenery.\n    -- Stationary because it is not fighting; it is working.
    enemy_false_citizen = freezeDefinition({
        id = "enemy_false_citizen",
        displayName = "False Citizen",
        modelKey = "false_citizen",
        health = 100,
        speed = 5.4,
        attackRange = 9,
        attackCooldown = 3,
        playerDamage = 19,
        lanternDamage = 8,
        strikeRange = 10,
        strikeDamage = 32,
        attackId = "false_citizen_mend",
        attackName = "MENDING",
        instruction = "IT IS PUTTING THE FIGHT BACK TOGETHER",
        shape = "circle",
        radius = 8,
        width = nil,
        length = nil,
        windup = 1.3,
        stationary = true,
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
    "enemy_ash_extra",
    "enemy_glass_knight",
    "enemy_kiln_worm",
    "enemy_crown_spark",
    "enemy_parade_giant",
    "enemy_false_citizen",
})
function CinderfallEnemies.get(enemyId: string): EnemyDefinition?
    return DEFINITIONS[enemyId]
end

function CinderfallEnemies.require(enemyId: string): EnemyDefinition
    local definition = DEFINITIONS[enemyId]
    assert(definition ~= nil, string.format("unknown Cinderfall enemy ID %q", enemyId))
    return definition
end

function CinderfallEnemies.order(): { string }
    return table.clone(ORDER)
end

function CinderfallEnemies.all(): { EnemyDefinition }
    local result: { EnemyDefinition } = {}
    for _, enemyId in ORDER do
        table.insert(result, DEFINITIONS[enemyId])
    end
    return result
end

return table.freeze(CinderfallEnemies)
