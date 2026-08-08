--!strict

--[[
    What the owner of a private server may do to it, and what it costs.

    Milestone 11's deliverable list names "private-server controls", and
    MONETIZATION_LIVEOPS_ANALYTICS describes them as phase pause in non-reward
    practice, seed selection among already-discovered seeds, and cinematic
    tools -- with one sentence attached that decides this entire module:
    **reward-bearing modifiers remain server-defined.**

    There are two ways to keep that promise. The usual way is to sort the
    controls into the ones that touch rewards and the ones that do not, and
    trust the sorting. That sorting is a judgement call made once, by whoever
    adds the fifth control, about a system they are not thinking about; this
    project has a written history of exactly that shape going wrong quietly.

    So this module does not sort. **Every control forces practice, and practice
    is a one-way latch on the whole server.** The argument is short enough to
    hold in one line: a control that changes nothing about the world does not
    need a private server to house it, and a control that changes the world
    changes the run. Hiding your own HUD is not a private-server privilege --
    it is a HUD feature, and it belongs on the HUD. What is left, once that is
    taken out, is a list where every entry is reward-bearing, and the honest
    answer to a reward-bearing modifier is that this run no longer pays.

    That makes the exit-gate line ("no private-server setting changes a
    reward") true structurally rather than by inspection: there is no reward
    left for a setting to change. `apply` sets `practice` on every accepted
    change with no per-control branch, so a control added tomorrow is latched
    by the same line as the four here, and the spec drives the whole catalog
    through it rather than holding a case per entry.

    The latch never lifts. A practice server that could go back to paying
    would let somebody hold the clock, arrange a night, release it and bank --
    which is the modifier the promise is about, arrived at in two presses. It
    lifts when the server restarts, which is a real act with a real cost.

    Nothing here is a purchase. Authority is a property of the *server* --
    Roblox's own `PrivateServerOwnerId` -- and not an entitlement of the
    player, which is what keeps it outside the monetization guard's reach: no
    gameplay branch reads what anybody owns. If this ever becomes a paid pass,
    the entitlement resolves outside gameplay into plain profile data like
    every other one, and this file still asks the same question.
]]

local PrivateServerControls = {}

export type Control = {
    id: string,
    label: string,
    -- The state key a toggle latches, or nil for a control that happens once
    -- and remembers nothing.
    field: string?,
    kind: string,
    -- Why this one is a practice control, said per entry rather than in one
    -- paragraph, because the four reasons are genuinely different and the
    -- fifth author needs to be able to tell whether theirs is one of them.
    why: string,
}

export type State = {
    practice: boolean,
    hold: boolean,
    still: boolean,
    seedIndex: number,
}

export type Server = {
    privateServerId: string,
    privateServerOwnerId: number,
}

export type Seed = {
    regionId: string,
    seed: number,
}

export type Result = {
    ok: boolean,
    state: State,
    -- What the server should do once, now, beyond storing the state. A
    -- momentary control has no state to store, so an effect is the only trace
    -- it leaves.
    effect: string?,
    reason: string,
}

local CONTROLS: { Control } = {
    {
        id = "hold_clock",
        label = "HOLD THE CLOCK",
        field = "hold",
        kind = "toggle",
        why = "A clock you can stop is a night you can wait out.",
    },
    {
        id = "call_phase",
        label = "CALL THE NEXT PHASE",
        field = nil,
        kind = "moment",
        why = "Skipping to night is choosing which night you fight.",
    },
    {
        id = "still_dark",
        label = "STILL THE DARK",
        field = "still",
        kind = "toggle",
        why = "Creatures that hold still are creatures that are not fighting back.",
    },
    {
        id = "choose_seed",
        label = "CHOOSE A SEED",
        field = "seed",
        kind = "seed",
        why = "A seed you choose is a drop table you chose.",
    },
}

local CONTROL_BY_ID: { [string]: Control } = {}
for _, control in CONTROLS do
    assert(CONTROL_BY_ID[control.id] == nil, "duplicate private server control: " .. control.id)
    CONTROL_BY_ID[control.id] = control
end

table.freeze(CONTROLS)
table.freeze(CONTROL_BY_ID)

function PrivateServerControls.controls(): { Control }
    return CONTROLS
end

function PrivateServerControls.byId(controlId: any): Control?
    if type(controlId) ~= "string" then
        return nil
    end
    return CONTROL_BY_ID[controlId]
end

function PrivateServerControls.default(): State
    return {
        practice = false,
        hold = false,
        still = false,
        -- 0 is the server's own roll, which is what every ordinary server
        -- runs. A chosen seed is 1..#seeds into the player's own history.
        seedIndex = 0,
    }
end

function PrivateServerControls.normalize(value: any): State
    local state = PrivateServerControls.default()
    if type(value) ~= "table" then
        return state
    end
    state.practice = value.practice == true
    state.hold = value.hold == true
    state.still = value.still == true
    local index = tonumber(value.seedIndex)
    if type(index) == "number" and index == index and index >= 0 then
        state.seedIndex = math.floor(index)
    end
    return state
end

--[[
    Who may work these controls.

    Three refusals rather than one, because they mean different things to the
    person pressing and only one of them is about them.

    A **reserved** server is the interesting case. `PartyService` launches every
    expedition into one, and Roblox reports a reserved server with a non-empty
    `PrivateServerId` and an owner of zero -- so the naive test ("is this a
    private server") is true of every run this game has ever launched. Treating
    a party's run world as a private town would put a clock-holding, dark-
    stilling control rail inside the reward-bearing half of the game, which is
    precisely the thing the promise forbids. Nobody bought a reserved server, so
    nobody sets it.
]]
function PrivateServerControls.authority(server: any, actorUserId: any): (boolean, string)
    if type(server) ~= "table" then
        return false, "not_private_server"
    end
    local id = server.privateServerId
    if type(id) ~= "string" or id == "" then
        return false, "not_private_server"
    end
    local ownerId = tonumber(server.privateServerOwnerId) or 0
    if ownerId <= 0 then
        return false, "reserved_server"
    end
    if tonumber(actorUserId) ~= ownerId then
        return false, "not_server_owner"
    end
    return true, "owner"
end

local REFUSALS: { [string]: string } = {
    not_private_server = "THESE CONTROLS ONLY ANSWER IN A PRIVATE SERVER",
    reserved_server = "AN EXPEDITION WORLD HAS NO OWNER TO SET THEM",
    not_server_owner = "ONLY THIS SERVER'S OWNER WORKS THE RAIL",
    unknown_control = "NOTHING IS WRITTEN ON THAT BOARD",
    no_seeds_discovered = "YOU HAVE NOT WALKED A SEED WORTH KEEPING YET",
}

function PrivateServerControls.refusal(reason: any): string
    return REFUSALS[reason] or "THE RAIL DID NOT ANSWER"
end

--[[
    Press a board.

    `seeds` is the presser's own discovered-seed history, newest first, and it
    is the only thing seed selection may reach: a seed the player has already
    walked unlocks no region, reveals no layout they have not seen, and cannot
    name a place the generator would otherwise have refused them. Selection
    cycles rather than naming an index, so the payload carries nothing and the
    board cannot be asked for the fortieth seed of a history that holds four.
]]
function PrivateServerControls.apply(state: any, controlId: any, seeds: any): Result
    local current = PrivateServerControls.normalize(state)
    local control = PrivateServerControls.byId(controlId)
    if control == nil then
        return { ok = false, state = current, effect = nil, reason = "unknown_control" }
    end

    local next_: State = {
        practice = current.practice,
        hold = current.hold,
        still = current.still,
        seedIndex = current.seedIndex,
    }
    local effect: string? = nil

    if control.kind == "toggle" then
        -- Named rather than written as a parenthesised cast on its own line:
        -- a statement that begins with `(` is the one shape Luau's parser has
        -- to guess at, and a guess that happens to be right today is not a
        -- thing to leave in a file somebody will edit.
        local field = control.field :: string
        local mutable = next_ :: any
        mutable[field] = not (current :: any)[field]
    elseif control.kind == "moment" then
        effect = control.id
    elseif control.kind == "seed" then
        local history = if type(seeds) == "table" then seeds else {}
        if #history == 0 then
            return { ok = false, state = current, effect = nil, reason = "no_seeds_discovered" }
        end
        local index = current.seedIndex + 1
        if index > #history then
            index = 0
        end
        next_.seedIndex = index
    end

    --[[
        The one line the whole module is about, and it has no branch in it on
        purpose. Every accepted press latches practice; nothing anywhere clears
        it. A per-control exemption would be one `if` away from existing, and
        the author of the fifth control is exactly the person who would write
        it, in the commit where it looked harmless.
    ]]
    next_.practice = true
    return { ok = true, state = next_, effect = effect, reason = "applied" }
end

function PrivateServerControls.rewardsAllowed(state: any): boolean
    return not PrivateServerControls.normalize(state).practice
end

-- The seed this state has chosen out of a history, or nil for the server's own
-- roll. An index past the end of a shortened history reads as nil rather than
-- as the last entry: a history that lost its tail should stop choosing, not
-- silently choose something else.
function PrivateServerControls.chosenSeed(state: any, seeds: any): Seed?
    local current = PrivateServerControls.normalize(state)
    if current.seedIndex <= 0 or type(seeds) ~= "table" then
        return nil
    end
    local entry = seeds[current.seedIndex]
    if type(entry) ~= "table" then
        return nil
    end
    local seed = tonumber(entry.seed)
    if type(entry.regionId) ~= "string" or seed == nil then
        return nil
    end
    return { regionId = entry.regionId, seed = seed }
end

-- What a board reads once its control has been worked, so the rail says the
-- state of the world rather than only the name of the lever.
function PrivateServerControls.readout(state: any, controlId: any, seeds: any): string
    local control = PrivateServerControls.byId(controlId)
    if control == nil then
        return ""
    end
    local current = PrivateServerControls.normalize(state)
    if control.kind == "toggle" then
        return if (current :: any)[control.field :: string] then "ON" else "OFF"
    elseif control.kind == "seed" then
        local chosen = PrivateServerControls.chosenSeed(current, seeds)
        if chosen == nil then
            return "THIS SERVER'S OWN"
        end
        -- The catalog's id with its namespace taken off. Read live, the raw
        -- form came back as THE WOOD IS REGION_BRAMBLEWAKE · 32693, which is
        -- a database key shouted at a player standing in front of a plank.
        local name = string.gsub(chosen.regionId, "^region_", "")
        return string.format("%s · %d", string.upper(name), chosen.seed)
    end
    return "READY"
end

return table.freeze(PrivateServerControls)
