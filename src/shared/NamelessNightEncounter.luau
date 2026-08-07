--!strict

--[[
    The Nameless Night -- the finale, in five scenes rather than phases.

    Every boss so far has been a fight with a verb in the middle. This one
    is five different things in a row, because a finale that is a longer
    version of the Warden Stag is not a finale, it is a boss with more
    health. So: hold a street you cannot hold all of, follow something
    down at the price of your own light, choose which of two people comes
    out, look at what the lantern road actually is, and then decide what
    to do about it.

    Nothing here is a menu until the last scene, and by then the game has
    already taken three decisions off the player in the only way that
    works -- by making them make those decisions with their hands while
    something else was going on. The post they left empty, the light they
    spent, and the person they carried out are all recorded, and the
    epilogue reads them alongside the ending.

    Idempotency is load-bearing here in a way it is not anywhere else. A
    player who disconnects at the bottom of the Hollow must not be able to
    resolve the finale twice, and a party must not be able to resolve
    scenes for each other twice. So every scene carries its own
    transaction id, and so does the ending.
]]

local NamelessNightEncounter = {}

export type Status = "disabled" | "locked" | "dormant" | "playing" | "complete"

export type State = {
    abandonedPost: string?,
    chosenEnding: string?,
    completedScenes: { [string]: boolean },
    followed: { [string]: boolean },
    held: { [string]: boolean },
    leftBehind: string?,
    light: number,
    manifestHash: string,
    participants: { [string]: boolean },
    rescued: string?,
    revision: number,
    runId: string,
    scene: number,
    status: Status,
    trapped: { string },
    witnessed: { [string]: boolean },
}

local SCENE_COUNT = 5
local POST_IDS = table.freeze({ "post_gate", "post_road", "post_hearth" })
-- Two of three, because a party that could hold all three would not be
-- making a decision.
local POSTS_REQUIRED = 2
local MARK_IDS = table.freeze({ "mark_kerb", "mark_stair", "mark_sill", "mark_floor" })
local MARKS_REQUIRED = 3
local STARTING_LIGHT = 5
local MOMENT_IDS = table.freeze({
    "moment_the_flame",
    "moment_the_record",
    "moment_the_hands",
    "moment_the_year",
})
local ENDING_IDS = table.freeze({ "ending_kept", "ending_ended", "ending_shared" })

local THE_STREET = table.freeze({
    attackId = "nameless_night_street",
    attackName = "IT IS IN THE STREET",
    damage = 28,
    instruction = "IT COMES THROUGH THE POST NOBODY IS AT",
    radius = 16,
    shape = "circle",
    windup = 1.6,
})

local THE_WITHDRAWAL = table.freeze({
    attackId = "nameless_night_withdraw",
    attackName = "IT WITHDRAWS",
    damage = 22,
    instruction = "IT IS NOT RUNNING — DO NOT RUN EITHER",
    length = 32,
    shape = "lane",
    width = 9,
    windup = 1.35,
})

local THE_ARITHMETIC = table.freeze({
    attackId = "nameless_night_arithmetic",
    attackName = "THE ARITHMETIC",
    damage = 32,
    instruction = "IT IS WAITING FOR YOU TO DECIDE",
    radius = 18,
    shape = "circle",
    windup = 2.2,
})

NamelessNightEncounter.Id = "boss_nameless_night"
NamelessNightEncounter.SceneCount = SCENE_COUNT
NamelessNightEncounter.PostIds = POST_IDS
NamelessNightEncounter.PostsRequired = POSTS_REQUIRED
NamelessNightEncounter.MarkIds = MARK_IDS
NamelessNightEncounter.MarksRequired = MARKS_REQUIRED
NamelessNightEncounter.StartingLight = STARTING_LIGHT
NamelessNightEncounter.MomentIds = MOMENT_IDS
NamelessNightEncounter.EndingIds = ENDING_IDS
NamelessNightEncounter.Reward = table.freeze({
    amount = 8,
    materialId = "material_memory_glass",
})
NamelessNightEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.8,
    witnessAttackCooldownSeconds = 0,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.completedScenes = table.clone(state.completedScenes)
    nextState.followed = table.clone(state.followed)
    nextState.held = table.clone(state.held)
    nextState.participants = table.clone(state.participants)
    nextState.trapped = table.clone(state.trapped)
    nextState.witnessed = table.clone(state.witnessed)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function contains(list: { string }, value: any): boolean
    for _, entry in list do
        if entry == value then
            return true
        end
    end
    return false
end

local function countTrue(set: { [string]: boolean }): number
    local total = 0
    for _, value in set do
        if value then
            total += 1
        end
    end
    return total
end

function NamelessNightEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Nameless Night run ID is required")
    assert(manifestHash ~= "", "Nameless Night manifest hash is required")
    return {
        abandonedPost = nil,
        chosenEnding = nil,
        completedScenes = {},
        followed = {},
        held = {},
        leftBehind = nil,
        light = STARTING_LIGHT,
        manifestHash = manifestHash,
        participants = {},
        rescued = nil,
        revision = 0,
        runId = runId,
        scene = 1,
        status = if enabled then "locked" else "disabled",
        trapped = {},
        witnessed = {},
    }
end

function NamelessNightEncounter.unlock(state: State): (State, any)
    if state.status ~= "locked" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "dormant"
    nextState.revision += 1
    return nextState, { accepted = true, reason = "unlocked" }
end

--[[
    The two people in the third scene are not written into this module.
    The service names whoever is actually in town when the finale opens,
    which is what makes the choice cost anything -- the game asks about
    people a specific save has spent chapters getting to know.
]]
function NamelessNightEncounter.activate(
    state: State,
    userId: number,
    trapped: { string }
): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    if #trapped ~= 2 or trapped[1] == trapped[2] then
        return state, { accepted = false, reason = "invalid_trapped" }
    end
    local nextState = cloneState(state)
    nextState.status = "playing"
    nextState.trapped = { trapped[1], trapped[2] }
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function NamelessNightEncounter.join(state: State, userId: number): State
    if state.status ~= "playing" then
        return state
    end
    local key = participantKey(userId)
    if state.participants[key] then
        return state
    end
    local nextState = cloneState(state)
    nextState.participants[key] = true
    nextState.revision += 1
    return nextState
end

local function advance(state: State, sceneId: string): State
    state.completedScenes[sceneId] = true
    state.scene += 1
    return state
end

-- Scene one. Two posts of three, and whichever is left is how it gets in.
function NamelessNightEncounter.holdPost(state: State, userId: number, postId: any): (State, any)
    if state.status ~= "playing" or state.scene ~= 1 then
        return state, { accepted = false, reason = "wrong_scene" }
    end
    if not contains(POST_IDS, postId) then
        return state, { accepted = false, reason = "unknown_post" }
    end
    if state.held[postId] then
        return state, { accepted = false, reason = "already_held" }
    end
    local nextState = cloneState(state)
    nextState.held[postId] = true
    nextState.participants[participantKey(userId)] = true
    local held = countTrue(nextState.held)
    if held >= POSTS_REQUIRED then
        for _, id in POST_IDS do
            if not nextState.held[id] then
                nextState.abandonedPost = id
                break
            end
        end
        nextState = advance(nextState, "scene_defend")
    end
    nextState.revision += 1
    return nextState,
        {
            abandoned = nextState.abandonedPost,
            accepted = true,
            held = held,
            reason = if nextState.scene > 1 then "street_held" else "post_held",
            required = POSTS_REQUIRED,
        }
end

--[[
    Scene two. It withdraws at the speed you are willing to spend light
    following it, so every mark costs one and a wrong mark costs two. A
    party that guesses its way down arrives with nothing left, which is
    the scene the third one is built on.
]]
function NamelessNightEncounter.follow(state: State, userId: number, markId: any): (State, any)
    if state.status ~= "playing" or state.scene ~= 2 then
        return state, { accepted = false, reason = "wrong_scene" }
    end
    if not contains(MARK_IDS, markId) then
        return state, { accepted = false, reason = "unknown_mark" }
    end
    local followed = countTrue(state.followed)
    local expected = MARK_IDS[followed + 1]
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    if markId ~= expected then
        nextState.light = math.max(0, state.light - 2)
        nextState.revision += 1
        return nextState, { accepted = false, light = nextState.light, reason = "lost_the_trail" }
    end
    nextState.followed[markId] = true
    nextState.light = math.max(0, state.light - 1)
    local total = followed + 1
    if total >= MARKS_REQUIRED then
        nextState = advance(nextState, "scene_pursue")
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            followed = total,
            light = nextState.light,
            reason = if nextState.scene > 2 then "run_to_ground" else "mark_followed",
            required = MARKS_REQUIRED,
        }
end

--[[
    Scene three. Light enough for one. Taking neither is allowed and is
    its own answer -- the game does not refuse a player who will not
    choose, it records that they did not.
]]
function NamelessNightEncounter.rescue(state: State, userId: number, residentId: any): (State, any)
    if state.status ~= "playing" or state.scene ~= 3 then
        return state, { accepted = false, reason = "wrong_scene" }
    end
    if not contains(state.trapped, residentId) then
        return state, { accepted = false, reason = "not_trapped" }
    end
    local nextState = cloneState(state)
    nextState.rescued = residentId
    nextState.leftBehind = if state.trapped[1] == residentId
        then state.trapped[2]
        else state.trapped[1]
    nextState.participants[participantKey(userId)] = true
    nextState = advance(nextState, "scene_rescue")
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            left = nextState.leftBehind,
            reason = "carried_out",
            rescued = residentId,
        }
end

function NamelessNightEncounter.passBy(state: State, userId: number): (State, any)
    if state.status ~= "playing" or state.scene ~= 3 then
        return state, { accepted = false, reason = "wrong_scene" }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState = advance(nextState, "scene_rescue")
    nextState.revision += 1
    return nextState, { accepted = true, reason = "passed_by", rescued = nil }
end

-- Scene four. Nothing attacks; the only thing that can be got wrong here
-- is leaving before you have seen it.
function NamelessNightEncounter.witness(state: State, userId: number, momentId: any): (State, any)
    if state.status ~= "playing" or state.scene ~= 4 then
        return state, { accepted = false, reason = "wrong_scene" }
    end
    if not contains(MOMENT_IDS, momentId) then
        return state, { accepted = false, reason = "unknown_moment" }
    end
    if state.witnessed[momentId] then
        return state, { accepted = false, reason = "already_seen" }
    end
    local nextState = cloneState(state)
    nextState.witnessed[momentId] = true
    nextState.participants[participantKey(userId)] = true
    local seen = countTrue(nextState.witnessed)
    if seen >= #MOMENT_IDS then
        nextState = advance(nextState, "scene_witness")
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = if nextState.scene > 4 then "seen_it_all" else "witnessed",
            required = #MOMENT_IDS,
            seen = seen,
        }
end

-- Scene five. The only menu in the game, and it comes after everything
-- that could have been decided without one already has been.
function NamelessNightEncounter.choose(state: State, userId: number, endingId: any): (State, any)
    if state.status ~= "playing" or state.scene ~= 5 then
        return state, { accepted = false, reason = "wrong_scene" }
    end
    if not contains(ENDING_IDS, endingId) then
        return state, { accepted = false, reason = "unknown_ending" }
    end
    if state.chosenEnding ~= nil then
        return state, { accepted = false, reason = "already_chosen" }
    end
    local nextState = cloneState(state)
    nextState.chosenEnding = endingId
    nextState.participants[participantKey(userId)] = true
    nextState = advance(nextState, "scene_choose")
    nextState.status = "complete"
    nextState.revision += 1
    return nextState, { accepted = true, completed = true, ending = endingId, reason = "chosen" }
end

function NamelessNightEncounter.attack(scene: number): any?
    if scene == 1 then
        return THE_STREET
    elseif scene == 2 then
        return THE_WITHDRAWAL
    elseif scene == 3 then
        return THE_ARITHMETIC
    end
    -- Scenes four and five have no attack at all. That is the point of
    -- them, and a caller that expects one everywhere would put one here.
    return nil
end

function NamelessNightEncounter.snapshot(state: State, userId: number): any
    local instruction = if state.status == "complete"
        then "IT IS DECIDED"
        elseif state.status == "locked" then "THE HOLLOW IS NOT OPEN TO YOU YET"
        elseif state.status == "disabled" then "THE HOLLOW DOES NOT ANSWER"
        elseif state.status == "dormant" then "THE ROAD KEEPS GOING"
        elseif state.scene == 1 then string.format(
            "HOLD TWO POSTS — %d OF %d",
            countTrue(state.held),
            POSTS_REQUIRED
        )
        elseif state.scene == 2 then string.format(
            "FOLLOW IT DOWN — %d MARKS, %d LIGHT LEFT",
            countTrue(state.followed),
            state.light
        )
        elseif state.scene == 3 then "THERE IS LIGHT FOR ONE OF THEM"
        elseif state.scene == 4 then string.format(
            "LOOK AT ALL OF IT — %d OF %d",
            countTrue(state.witnessed),
            #MOMENT_IDS
        )
        else "DECIDE WHAT HAPPENS TO THE LIGHT"
    return {
        abandonedPost = state.abandonedPost,
        active = state.status == "playing",
        complete = state.status == "complete",
        displayName = "THE NAMELESS NIGHT",
        enabled = state.status ~= "disabled",
        ending = state.chosenEnding,
        instruction = instruction,
        leftBehind = state.leftBehind,
        light = state.light,
        rescued = state.rescued,
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        scene = math.min(state.scene, SCENE_COUNT),
        sceneCount = SCENE_COUNT,
        status = state.status,
        trapped = table.clone(state.trapped),
    }
end

--[[
    One transaction id per scene, and a separate one for the ending. A
    disconnect at the bottom of the Hollow must not let anything be
    resolved twice, and the ledger is what enforces that -- not this
    module remembering, which a rejoin would wipe.
]]
function NamelessNightEncounter.sceneTransactionId(state: State, sceneId: string): string
    return string.format(
        "%s:%s:%s:%s",
        NamelessNightEncounter.Id,
        state.runId,
        state.manifestHash,
        sceneId
    )
end

function NamelessNightEncounter.endingTransactionId(state: State): string
    return string.format(
        "%s:ending:%s:%s",
        NamelessNightEncounter.Id,
        state.runId,
        state.manifestHash
    )
end

function NamelessNightEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        NamelessNightEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(NamelessNightEncounter)
