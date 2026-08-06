--!strict

--[[
    The Ironroot Delve's six standard enemies, in the same definition
    shape the Bramblewake roster uses so the night systems need no new
    vocabulary to run them.

    The Delve does not fight like the forest. Bramblewake's roster is
    slow, heavy and structure-hungry: things that shoulder toward the
    lantern and telegraph in wide circles. The Delve's is fast, narrow and
    positional -- it uses the mine's own geometry against you. Rail hounds
    charge down straight lanes, slag spitters hold a corridor from a fixed
    mouth, crank guards present armored plate until you take their flank,
    and gas blooms sit still and make the ground itself the threat. Where
    a Bramblewake enemy wants your lantern, most of these want you.

    Two behaviors the content catalog names for this region -- persistent
    hot zones that outlive their attack, and a hazard the player can
    redirect rather than merely avoid -- are expressed here with the
    existing telegraph and status vocabulary, because inventing new
    mechanics without a live session to feel them is how a system ships
    wrong. They are recorded open in the region runbook; the enemies read
    correctly today and gain depth when the Delve's own encounter wave
    can be driven in Studio.
]]

local IronrootEnemies = {}

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
    -- Swarm pressure: individually trivial, dangerous in number and near
    -- heat. The fastest thing in either roster, and the frailest.
    enemy_cinder_mite = freezeDefinition({
        id = "enemy_cinder_mite",
        displayName = "Cinder Mite",
        modelKey = "cinder_mite",
        health = 55,
        speed = 10.5,
        attackRange = 7,
        attackCooldown = 1.6,
        playerDamage = 14,
        lanternDamage = 4,
        strikeRange = 8,
        strikeDamage = 40,
        attackId = "cinder_mite_scald",
        attackName = "CINDER MITE SCALD",
        instruction = "STEP OUT OF THE EMBER RING",
        shape = "circle",
        radius = 5,
        width = nil,
        length = nil,
        windup = 0.7,
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
    -- The rails are its road: a long, narrow charge that owns a corridor
    -- until you leave it. Fast to close, slow to turn around.
    enemy_rail_hound = freezeDefinition({
        id = "enemy_rail_hound",
        displayName = "Rail Hound",
        modelKey = "rail_hound",
        health = 95,
        speed = 9,
        attackRange = 16,
        attackCooldown = 3,
        playerDamage = 30,
        lanternDamage = 8,
        strikeRange = 10,
        strikeDamage = 34,
        attackId = "rail_hound_run",
        attackName = "RAIL HOUND RUN",
        instruction = "GET OFF THE RAILS",
        shape = "lane",
        radius = nil,
        width = 6,
        length = 22,
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
    -- Holds a corridor from a fixed mouth. It never chases; it makes the
    -- ground between you and it expensive.
    enemy_slag_spitter = freezeDefinition({
        id = "enemy_slag_spitter",
        displayName = "Slag Spitter",
        modelKey = "slag_spitter",
        health = 130,
        speed = 0,
        attackRange = 26,
        attackCooldown = 3.4,
        playerDamage = 26,
        lanternDamage = 12,
        strikeRange = 11,
        strikeDamage = 32,
        attackId = "slag_spitter_pour",
        attackName = "SLAG POUR",
        instruction = "CROSS THE POUR LINE, DO NOT STAND IN IT",
        shape = "lane",
        radius = nil,
        width = 5,
        length = 26,
        windup = 1.5,
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
    -- A worker's last motion, repeating. Being caught in it leaves you
    -- moving like the shift did at hour eleven.
    enemy_shift_echo = freezeDefinition({
        id = "enemy_shift_echo",
        displayName = "Shift Echo",
        modelKey = "shift_echo",
        health = 85,
        speed = 6.4,
        attackRange = 10,
        attackCooldown = 2.6,
        playerDamage = 18,
        lanternDamage = 5,
        strikeRange = 9,
        strikeDamage = 36,
        attackId = "shift_echo_repeat",
        attackName = "REPEATED MOTION",
        instruction = "BREAK THE PATTERN — MOVE ASIDE",
        shape = "circle",
        radius = 8,
        width = nil,
        length = nil,
        windup = 1.2,
        stationary = false,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "drowsy",
        statusDuration = 7,
        statusMultiplier = 0.72,
        statusLanternDamage = nil,
    }),
    -- Plate at the front, mechanism at the back. The Delve's answer to the
    -- Briarback, and a harder one: slower, tougher, and it hunts the
    -- lantern rather than the person, so you cannot simply walk away.
    enemy_crank_guard = freezeDefinition({
        id = "enemy_crank_guard",
        displayName = "Crank Guard",
        modelKey = "crank_guard",
        health = 165,
        speed = 4.2,
        attackRange = 11,
        attackCooldown = 3.2,
        playerDamage = 32,
        lanternDamage = 16,
        strikeRange = 10,
        strikeDamage = 30,
        attackId = "crank_guard_sweep",
        attackName = "CRANK SWEEP",
        instruction = "TAKE THE MECHANISM — STRIKE FROM BEHIND",
        shape = "circle",
        radius = 9,
        width = nil,
        length = nil,
        windup = 1.5,
        stationary = false,
        targetMode = "lantern",
        frontShield = true,
        frontalStrikeDamage = 8,
        flankStrikeDamage = 44,
        statusEffect = nil,
        statusDuration = nil,
        statusMultiplier = nil,
        statusLanternDamage = nil,
    }),
    -- It does not come to you. It opens, and the air in a wide circle
    -- becomes the attack; the lantern gutters while the bloom is open.
    enemy_gas_bloomer = freezeDefinition({
        id = "enemy_gas_bloomer",
        displayName = "Gas Bloomer",
        modelKey = "gas_bloomer",
        health = 110,
        speed = 0,
        attackRange = 15,
        attackCooldown = 4,
        playerDamage = 20,
        lanternDamage = 18,
        strikeRange = 12,
        strikeDamage = 38,
        attackId = "gas_bloomer_open",
        attackName = "WHITEDAMP BLOOM",
        instruction = "LEAVE THE CLOUD BEFORE IT OPENS",
        shape = "circle",
        radius = 13,
        width = nil,
        length = nil,
        windup = 1.8,
        stationary = true,
        targetMode = "player",
        frontShield = false,
        frontalStrikeDamage = nil,
        flankStrikeDamage = nil,
        statusEffect = "drowsy",
        statusDuration = 9,
        statusMultiplier = 0.8,
        statusLanternDamage = 6,
    }),
}

local ORDER = table.freeze({
    "enemy_cinder_mite",
    "enemy_rail_hound",
    "enemy_slag_spitter",
    "enemy_shift_echo",
    "enemy_crank_guard",
    "enemy_gas_bloomer",
})

function IronrootEnemies.get(enemyId: string): EnemyDefinition?
    return DEFINITIONS[enemyId]
end

function IronrootEnemies.require(enemyId: string): EnemyDefinition
    local definition = DEFINITIONS[enemyId]
    assert(definition ~= nil, string.format("unknown Ironroot enemy ID %q", enemyId))
    return definition
end

function IronrootEnemies.order(): { string }
    return table.clone(ORDER)
end

function IronrootEnemies.all(): { EnemyDefinition }
    local result: { EnemyDefinition } = {}
    for _, enemyId in ORDER do
        table.insert(result, DEFINITIONS[enemyId])
    end
    return result
end

return table.freeze(IronrootEnemies)
