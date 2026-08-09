--!strict

--[[
    Mireglass Fen's six standard enemies, in the shared definition shape.

    The Delve's roster is fast and positional: it uses straight lines and
    open plate. The Fen's is patient and deceptive. Almost nothing here
    closes on you at speed -- lurkers wait in water that looks empty,
    mirrorlings return the last thing you did, leeches attach and drain
    what you need to run, false friends call in a resident's voice, and
    the bog bell simply summons until somebody interrupts it. Its danger
    is misplaced trust, so its numbers are built around low speed, long
    telegraphs and effects that cost you resources rather than health.

    Two catalog behaviors -- copying a player's last basic attack, and a
    drain an ally can remove -- are approximated with the existing status
    vocabulary rather than invented blind, and recorded open for a live
    session, exactly as the Delve's hot zones were.
]]

local Strings = require("./Strings")

local MireglassEnemies = {}

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
    -- It is already there, in water you have looked at twice.
    enemy_reed_lurker = freezeDefinition({
        id = "enemy_reed_lurker",
        displayName = "Reed Lurker",
        modelKey = "reed_lurker",
        health = 105,
        speed = 5.4,
        attackRange = 9,
        attackCooldown = 2.4,
        playerDamage = 30,
        lanternDamage = 6,
        strikeRange = 9,
        strikeDamage = 36,
        attackId = "reed_lurker_lunge",
        attackName = Strings.get("enemy.lurker_lunge"),
        instruction = Strings.get("enemy.back_out_of_the_shallows"),
        shape = "circle",
        radius = 7,
        width = nil,
        length = nil,
        windup = 0.85,
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
    -- It gives back what you last gave, a beat late.
    enemy_mirrorling = freezeDefinition({
        id = "enemy_mirrorling",
        displayName = "Mirrorling",
        modelKey = "mirrorling",
        health = 90,
        speed = 6,
        attackRange = 11,
        attackCooldown = 3,
        playerDamage = 24,
        lanternDamage = 5,
        strikeRange = 10,
        strikeDamage = 34,
        attackId = "mirrorling_return",
        attackName = Strings.get("enemy.returned_blow"),
        instruction = Strings.get("enemy.do_not_stand_where_you_just"),
        shape = "circle",
        radius = 8,
        width = nil,
        length = nil,
        windup = 1.45,
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
    -- It costs you the thing you need to leave: your legs.
    enemy_mire_leech = freezeDefinition({
        id = "enemy_mire_leech",
        displayName = "Mire Leech",
        modelKey = "mire_leech",
        health = 70,
        speed = 4.6,
        attackRange = 7,
        attackCooldown = 2.8,
        playerDamage = 12,
        lanternDamage = 3,
        strikeRange = 8,
        strikeDamage = 42,
        attackId = "mire_leech_latch",
        attackName = Strings.get("enemy.leech_latch"),
        instruction = Strings.get("enemy.shake_it_off_keep_moving"),
        shape = "circle",
        radius = 6,
        width = nil,
        length = nil,
        windup = 1,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "drowsy",
        statusDuration = 8,
        statusMultiplier = 0.68,
        statusLanternDamage = nil,
    }),
    -- It calls in a voice from town, and it is patient about it.
    enemy_false_friend = freezeDefinition({
        id = "enemy_false_friend",
        displayName = "False Friend",
        modelKey = "false_friend",
        health = 115,
        speed = 5,
        attackRange = 10,
        attackCooldown = 3.2,
        playerDamage = 28,
        lanternDamage = 10,
        strikeRange = 10,
        strikeDamage = 34,
        attackId = "false_friend_embrace",
        attackName = Strings.get("enemy.false_welcome"),
        instruction = Strings.get("enemy.it_is_not_who_it_sounds"),
        shape = "circle",
        radius = 9,
        width = nil,
        length = nil,
        windup = 1.6,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "spark_theft",
        statusDuration = 6,
        statusMultiplier = nil,
        statusLanternDamage = 8,
    }),
    -- A single exact line across still water. Stand out of it.
    enemy_glass_heron = freezeDefinition({
        id = "enemy_glass_heron",
        displayName = "Glass Heron",
        modelKey = "glass_heron",
        health = 80,
        speed = 3.2,
        attackRange = 30,
        attackCooldown = 3.6,
        playerDamage = 34,
        lanternDamage = 8,
        strikeRange = 10,
        strikeDamage = 38,
        attackId = "glass_heron_strike",
        attackName = Strings.get("enemy.heron_strike"),
        instruction = Strings.get("enemy.step_out_of_its_line"),
        shape = "lane",
        radius = nil,
        width = 4,
        length = 30,
        windup = 1.7,
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
    -- It does not fight. It rings, and the fen answers, until you stop it.
    enemy_bog_bell = freezeDefinition({
        id = "enemy_bog_bell",
        displayName = "Bog Bell",
        modelKey = "bog_bell",
        health = 140,
        speed = 0,
        attackRange = 18,
        attackCooldown = 4.4,
        playerDamage = 16,
        lanternDamage = 20,
        strikeRange = 12,
        strikeDamage = 36,
        attackId = "bog_bell_toll",
        attackName = Strings.get("enemy.the_tolling"),
        instruction = Strings.get("enemy.silence_the_bell_before_it_finishes"),
        shape = "circle",
        radius = 15,
        width = nil,
        length = nil,
        windup = 2,
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
    "enemy_reed_lurker",
    "enemy_mirrorling",
    "enemy_mire_leech",
    "enemy_false_friend",
    "enemy_glass_heron",
    "enemy_bog_bell",
})

function MireglassEnemies.get(enemyId: string): EnemyDefinition?
    return DEFINITIONS[enemyId]
end

function MireglassEnemies.require(enemyId: string): EnemyDefinition
    local definition = DEFINITIONS[enemyId]
    assert(definition ~= nil, string.format("unknown Mireglass enemy ID %q", enemyId))
    return definition
end

function MireglassEnemies.order(): { string }
    return table.clone(ORDER)
end

function MireglassEnemies.all(): { EnemyDefinition }
    local result: { EnemyDefinition } = {}
    for _, enemyId in ORDER do
        table.insert(result, DEFINITIONS[enemyId])
    end
    return result
end

return table.freeze(MireglassEnemies)
