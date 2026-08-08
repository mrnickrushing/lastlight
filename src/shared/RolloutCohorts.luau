--!strict

--[[
    Which players a flag has reached, and in what order it reaches them.

    Milestone 13's rollout is four rungs -- team and trusted testers, then a
    small allowlist across devices and age ranges with guardian consent, then
    a larger cohort behind controlled flags, then the creator and community
    test once moderation and scale look healthy. The flag service this game
    has shipped since Milestone 1 answers one question globally: on, or off.
    A staged rollout needs it to answer per player, and the interesting part
    is not the answer. It is what happens when somebody *advances* the stage.

    **The ladder only ever widens.** A flag moved from `team` to `allowlist`
    must not take the feature away from the testers who have been living with
    it, because those are the people whose reports the next rung is decided
    on. That is not a promise kept by whoever edits the table -- it is
    structural here: `admits` walks the rungs from the bottom up to the flag's
    current stage and returns at the first one that lets the player in, so a
    later stage cannot narrow an earlier one. There is no rung that subtracts.

    **A cohort-scoped flag read without a player is refused, not guessed.**
    Every call site in this game today asks globally, and a flag that becomes
    cohort-scoped while one of them still asks globally has to answer
    something. Both answers are wrong in a way that is invisible: `true` ships
    an unreleased feature to the whole population, which is the exact thing
    a staged rollout exists to prevent, and `false` makes it untestable for
    the cohort it was turned on for. So there is no answer. The read throws,
    the same way an unknown flag already does, because this can only be
    reached by a programming mistake and a loud one costs a Studio session
    while a quiet one costs a beta.

    **A bucket is stable per player and independent per flag.** Stable
    because a feature that is on in one server and off in the next is worse
    than a feature that is off: the player reports a bug nobody can
    reproduce. Independent because if the same players are picked for every
    flag, the beta has one cohort wearing four flags and every measurement is
    about that one group.

    The independence is the part that had to be measured rather than
    reasoned about. The first version hashed `flag .. userId` and ran the
    result through the same Lehmer step `ExpeditionGenerator` uses, and every
    operation in that chain is affine -- so changing the flag name shifted
    every player's bucket by one constant. Two flags at ten percent produced
    cohorts that were **perfectly disjoint** (measured: 0 players in both,
    against 201 expected), and two flags at fifty percent would have cut the
    population into exact complements, so no player would ever have seen both
    features. Folding the two hashes together with an exclusive or breaks the
    affinity, and the same measurement then returns 200 against 201 expected.

    Pure. No players, no services, no clock: user IDs and flag names in,
    booleans out.
]]

local RolloutCohorts = {}

export type Stage = "off" | "team" | "allowlist" | "cohort" | "everyone"

export type Rollout = {
    stage: Stage,
    -- What share of the population the `cohort` rung admits, 0 to 100. Read
    -- at no other stage, and required at every stage so a flag advancing to
    -- `cohort` cannot arrive without one.
    percent: number,
}

export type Roster = {
    -- Milestone 13 rung one: the team and the trusted testers.
    team: { [number]: boolean },
    -- Rung two: the consented allowlist across devices and age ranges.
    allowlist: { [number]: boolean },
}

--[[
    The rungs, in the order the roadmap climbs them. `off` is a real rung
    rather than an absent one: a flag nobody has yet is a state a matrix has
    to be able to say out loud, and it is where every unreleased flag in this
    game sits today.
]]
local STAGES: { Stage } = table.freeze({
    "off" :: Stage,
    "team",
    "allowlist",
    "cohort",
    "everyone",
})

local RANK: { [string]: number } = {}
for index, stage in STAGES do
    RANK[stage] = index
end
table.freeze(RANK)

local HASH_MULTIPLIER = 33
local HASH_MODULUS = 2147483647
local MIX_MULTIPLIER = 16807
local BUCKETS = 100

local function textHash(text: string): number
    local result = 0
    for index = 1, #text do
        result = (result * HASH_MULTIPLIER + string.byte(text, index)) % HASH_MODULUS
    end
    return result
end

function RolloutCohorts.stages(): { Stage }
    return table.clone(STAGES)
end

function RolloutCohorts.rank(stage: any): number?
    if type(stage) ~= "string" then
        return nil
    end
    return RANK[stage]
end

function RolloutCohorts.isStage(value: any): boolean
    return RolloutCohorts.rank(value) ~= nil
end

--[[
    Whether this stage has a single answer for the whole population.

    `off` and `everyone` do; the three rungs between them do not, and a read
    of one of those without a player is the refusal this module exists to
    make loud.
]]
function RolloutCohorts.isScoped(stage: any): boolean
    local rank = RolloutCohorts.rank(stage)
    return rank ~= nil and rank > 1 and rank < #STAGES
end

--[[
    The one answer a global read is allowed to give. `everyone` is the only
    stage that is on for a player nobody has said anything about, which is
    what makes the flag table and the stage matrix the same fact rather than
    two facts that can drift.
]]
function RolloutCohorts.globalDefault(stage: any): boolean
    return stage == "everyone"
end

--[[
    Where a player sits in the 0..99 spread for one flag.

    The two hashes are folded with an exclusive or rather than concatenated,
    for the reason written at the top of this file: concatenation is affine
    all the way through and produced rotations of one ordering instead of a
    different ordering per flag.
]]
function RolloutCohorts.bucket(flag: string, userId: number): number
    local folded = bit32.bxor(textHash(flag), textHash("u" .. tostring(math.floor(userId))))
    local state = folded % HASH_MODULUS
    if state == 0 then
        state = 1
    end
    return ((state * MIX_MULTIPLIER) % HASH_MODULUS) % BUCKETS
end

local function inRoster(roster: Roster?, key: string, userId: number): boolean
    if roster == nil then
        return false
    end
    local list = (roster :: any)[key]
    return type(list) == "table" and list[userId] == true
end

--[[
    Whether this player has the flag, and which rung let them in.

    The walk is bottom-up on purpose. Every rung is asked in turn until one
    admits or the flag's own stage is passed, so widening a rollout can only
    ever add people. There is no branch here that takes the feature back off
    somebody, which is the property the whole module is for.
]]
function RolloutCohorts.admits(
    flag: string,
    rollout: Rollout,
    roster: Roster?,
    userId: number
): (boolean, string)
    local ceiling = RolloutCohorts.rank(rollout.stage)
    if ceiling == nil then
        return false, "unknown_stage"
    end

    if type(userId) ~= "number" or userId ~= userId or math.floor(userId) ~= userId then
        return false, "no_subject"
    end

    for rank = 2, ceiling do
        local stage = STAGES[rank]
        if stage == "team" then
            if inRoster(roster, "team", userId) then
                return true, "team"
            end
        elseif stage == "allowlist" then
            if inRoster(roster, "allowlist", userId) then
                return true, "allowlist"
            end
        elseif stage == "cohort" then
            local percent = rollout.percent
            if type(percent) == "number" and RolloutCohorts.bucket(flag, userId) < percent then
                return true, "cohort"
            end
        elseif stage == "everyone" then
            return true, "everyone"
        end
    end

    if ceiling == 1 then
        return false, "stage_off"
    end
    return false, "outside_cohort"
end

return table.freeze(RolloutCohorts)
