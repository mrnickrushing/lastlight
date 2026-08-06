--!strict
--[[
    Resident life: jobs, injury, bonds, and town crises.

    Milestone 4 asks for residents who are part of the town's systems rather
    than scenery on a schedule. This module is the whole of that judgement,
    kept pure — night outcomes in, next resident state out — so the specs can
    hold every rule still and the services stay wiring.

    Design rules this module enforces:
    - Everything here is deterministic. An injury is caused by a workplace
      falling, never by a dice roll, so a player can always answer "why".
    - Effects touch town systems only (repairs, warnings, the lantern's
      floor). No resident boon ever changes player damage, speed, or drops —
      that keeps the no-paid-power line easy to hold forever.
    - Bonds are per-profile: they are the town remembering *you*.
]]

local ResidentRoster = require("./ResidentRoster")

local ResidentLife = {}

export type ResidentState = {
    injuredUntilNight: number,
    bond: number,
    lastVisitNight: number,
}

export type State = { [string]: ResidentState }

export type Job = {
    residentId: string,
    buildingId: string,
    title: string,
    boon: string,
    boonLabel: string,
}

export type NightContext = {
    nightNumber: number,
    buildingIntegrity: { [string]: number },
    lanternHitFloor: boolean,
}

export type Crisis = {
    id: string,
    kind: string,
    title: string,
    detail: string,
    startedNight: number,
}

export type NightReport = {
    injuries: { string },
    recoveries: { string },
    crisis: Crisis?,
}

--[[
    Who exists, and what job each holds, now comes from ResidentRoster --
    one list instead of the several that used to drift apart. Chapter I's
    three still come first, in their original order, with their original
    jobs, so nothing about an existing town changes.
]]
local RESIDENT_IDS = ResidentRoster.Order

local JOBS: { [string]: Job } = table.freeze(ResidentRoster.jobs())

-- A workplace this damaged injures its keeper during the night's chaos.
local INJURY_INTEGRITY_THRESHOLD = 0.5
-- Nights of rest an injury costs, before anyone checks on them.
local INJURY_REST_NIGHTS = 2
local BOND_MAX = 100
local BOND_VISIT = 1
local BOND_CARE = 5

ResidentLife.Ids = RESIDENT_IDS
ResidentLife.Jobs = JOBS
ResidentLife.BondTiers = table.freeze({
    { threshold = 75, title = "KINDRED" },
    { threshold = 50, title = "TRUSTED" },
    { threshold = 25, title = "ACQUAINTED" },
    { threshold = 0, title = "NEWCOMER" },
})

local function defaultResident(): ResidentState
    return {
        injuredUntilNight = 0,
        bond = 0,
        lastVisitNight = 0,
    }
end

function ResidentLife.default(): State
    local state: State = {}
    for _, residentId in RESIDENT_IDS do
        state[residentId] = defaultResident()
    end
    return state
end

function ResidentLife.normalize(value: any): State
    local state = ResidentLife.default()
    if type(value) ~= "table" then
        return state
    end
    for _, residentId in RESIDENT_IDS do
        local stored = value[residentId]
        if type(stored) == "table" then
            local resident = state[residentId]
            resident.injuredUntilNight =
                math.max(0, math.floor(tonumber(stored.injuredUntilNight) or 0))
            resident.bond = math.clamp(math.floor(tonumber(stored.bond) or 0), 0, BOND_MAX)
            resident.lastVisitNight = math.max(0, math.floor(tonumber(stored.lastVisitNight) or 0))
        end
    end
    return state
end

function ResidentLife.isInjured(state: State, residentId: string, nightNumber: number): boolean
    local resident = state[residentId]
    return resident ~= nil and resident.injuredUntilNight >= nightNumber
end

function ResidentLife.bondTitle(bond: number): string
    for _, tier in ResidentLife.BondTiers do
        if bond >= tier.threshold then
            return tier.title
        end
    end
    return "NEWCOMER"
end

local function clone(state: State): State
    local next: State = {}
    for residentId, resident in state do
        next[residentId] = {
            injuredUntilNight = resident.injuredUntilNight,
            bond = resident.bond,
            lastVisitNight = resident.lastVisitNight,
        }
    end
    return next
end

--[[
    A night has ended; decide who it hurt and whether the town tips into
    crisis. Injuries come only from a resident's own workplace falling below
    half integrity while they were out defending it. Two or more injuries at
    once is a crisis: the clinic story writes itself, and the town needs its
    players to go check on people.
]]
function ResidentLife.resolveNight(state: State, context: NightContext): (State, NightReport)
    local nextState = clone(state)
    local report: NightReport = { injuries = {}, recoveries = {}, crisis = nil }
    for _, residentId in RESIDENT_IDS do
        local resident = nextState[residentId]
        local job = JOBS[residentId]
        local wasInjured = resident.injuredUntilNight >= context.nightNumber
        if not wasInjured and resident.injuredUntilNight > 0 then
            resident.injuredUntilNight = 0
            table.insert(report.recoveries, residentId)
        end
        local integrity = context.buildingIntegrity[job.buildingId]
        if not wasInjured and integrity ~= nil and integrity < INJURY_INTEGRITY_THRESHOLD then
            resident.injuredUntilNight = context.nightNumber + INJURY_REST_NIGHTS
            table.insert(report.injuries, residentId)
        end
    end

    local injuredNow = 0
    for _, residentId in RESIDENT_IDS do
        if ResidentLife.isInjured(nextState, residentId, context.nightNumber + 1) then
            injuredNow += 1
        end
    end
    if injuredNow >= 2 then
        report.crisis = {
            id = string.format("crisis_clinic_%d", context.nightNumber),
            kind = "care",
            title = "THE CLINIC IS FULL",
            detail = "Check on the injured residents to help them back on their feet.",
            startedNight = context.nightNumber,
        }
    elseif context.lanternHitFloor and injuredNow >= 1 then
        report.crisis = {
            id = string.format("crisis_darkwatch_%d", context.nightNumber),
            kind = "care",
            title = "A HARD NIGHT'S TOLL",
            detail = "The light nearly failed and someone was hurt. Check on them.",
            startedNight = context.nightNumber,
        }
    end
    return nextState, report
end

export type CheckResult = {
    accepted: boolean,
    reason: string?,
    healed: boolean,
    bond: number,
}

--[[
    A player checks on a resident. Injured: recovery accelerates by one night
    and the bond grows properly — care is how people become close. Healthy:
    a small bond nudge, once per night, so the loop is worth doing without
    being a tapping exercise.
]]
function ResidentLife.checkOn(
    state: State,
    residentId: string,
    nightNumber: number
): (State, CheckResult)
    local resident = state[residentId]
    if resident == nil then
        return state, { accepted = false, reason = "unknown_resident", healed = false, bond = 0 }
    end
    local nextState = clone(state)
    local target = nextState[residentId]
    if target.injuredUntilNight >= nightNumber then
        target.injuredUntilNight = math.max(0, target.injuredUntilNight - 1)
        target.bond = math.min(BOND_MAX, target.bond + BOND_CARE)
        target.lastVisitNight = nightNumber
        return nextState,
            {
                accepted = true,
                reason = nil,
                healed = target.injuredUntilNight < nightNumber,
                bond = target.bond,
            }
    end
    if target.lastVisitNight >= nightNumber then
        return state,
            {
                accepted = false,
                reason = "already_visited",
                healed = false,
                bond = target.bond,
            }
    end
    target.bond = math.min(BOND_MAX, target.bond + BOND_VISIT)
    target.lastVisitNight = nightNumber
    return nextState, { accepted = true, reason = nil, healed = false, bond = target.bond }
end

export type Boon = {
    residentId: string,
    boon: string,
    label: string,
}

--[[
    What the healthy, employed residents contribute at dawn. A resident sits
    a boon out while injured or while their workplace is an unbuilt site —
    which is exactly the pressure that makes repairs and rescues matter.
]]
function ResidentLife.dawnBoons(
    state: State,
    nightNumber: number,
    buildingStages: { [string]: number },
    activeResidentIds: { string }
): { Boon }
    local active: { [string]: boolean } = {}
    for _, residentId in activeResidentIds do
        active[residentId] = true
    end
    local boons: { Boon } = {}
    for _, residentId in RESIDENT_IDS do
        local job = JOBS[residentId]
        if
            active[residentId]
            and not ResidentLife.isInjured(state, residentId, nightNumber)
            and (buildingStages[job.buildingId] or 0) > 0
        then
            table.insert(boons, { residentId = residentId, boon = job.boon, label = job.boonLabel })
        end
    end
    return boons
end

--[[
    Snapshot for the client: status, job, and bond per resident, plus the
    crisis if one is standing. Pure formatting; the client renders it in the
    Field Book and never decides anything from it.
]]
function ResidentLife.snapshot(
    state: State,
    nightNumber: number,
    activeResidentIds: { string },
    crisis: Crisis?
): { [string]: any }
    local residents = {}
    local active: { [string]: boolean } = {}
    for _, residentId in activeResidentIds do
        active[residentId] = true
    end
    for _, residentId in RESIDENT_IDS do
        local resident = state[residentId]
        local job = JOBS[residentId]
        table.insert(residents, {
            residentId = residentId,
            title = job.title,
            buildingId = job.buildingId,
            present = active[residentId] == true,
            injured = ResidentLife.isInjured(state, residentId, nightNumber),
            bond = resident.bond,
            bondTitle = ResidentLife.bondTitle(resident.bond),
        })
    end
    return {
        residents = residents,
        crisis = crisis,
    }
end

return table.freeze(ResidentLife)
