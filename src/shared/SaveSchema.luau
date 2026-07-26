--!strict

local TutorialFlow = require("./TutorialFlow")
local ExpeditionInventory = require("./ExpeditionInventory")
local ProfessionCatalog = require("./ProfessionCatalog")
local Crafting = require("./Crafting")

local SaveSchema = {}

export type Tutorial = {
    stage: TutorialFlow.Stage,
    complete: boolean,
    selectedTool: string?,
    completedAt: number?,
}

export type Profile = {
    schemaVersion: number,
    createdAt: number,
    updatedAt: number,
    revision: number,
    tutorial: Tutorial,
    inventory: any,
    profession: {
        selectedId: string?,
    },
    story: {
        chapterOne: {
            completedAt: number?,
            decision: string?,
            status: string,
            transactionId: string?,
            wardenOutcome: string?,
        },
    },
    town: {
        nightNumber: number,
    },
    gear: { [string]: number },
}

local MAX_NIGHT_NUMBER = 1_000_000

local CHAPTER_ONE_DECISIONS = table.freeze({
    restore_farmland = true,
    wild_regrowth = true,
    shared_agroforest = true,
})
local WARDEN_OUTCOMES = table.freeze({
    preserved = true,
    scarred = true,
    harmed = true,
})

function SaveSchema.default(now: number): Profile
    return {
        schemaVersion = 6,
        createdAt = now,
        updatedAt = now,
        revision = 0,
        tutorial = {
            stage = "arrive",
            complete = false,
            selectedTool = nil,
            completedAt = nil,
        },
        inventory = ExpeditionInventory.default(),
        profession = {
            selectedId = nil,
        },
        story = {
            chapterOne = {
                completedAt = nil,
                decision = nil,
                status = "unresolved",
                transactionId = nil,
                wardenOutcome = nil,
            },
        },
        town = {
            nightNumber = 1,
        },
        gear = Crafting.default(),
    }
end

function SaveSchema.normalize(value: any, now: number): Profile
    local profile = SaveSchema.default(now)
    if type(value) ~= "table" then
        return profile
    end

    if type(value.createdAt) == "number" and value.createdAt > 0 then
        profile.createdAt = value.createdAt
    end
    if type(value.updatedAt) == "number" and value.updatedAt > 0 then
        profile.updatedAt = value.updatedAt
    end
    if type(value.revision) == "number" and value.revision >= 0 then
        profile.revision = math.floor(value.revision)
    end

    local tutorial = value.tutorial
    if type(tutorial) == "table" then
        if TutorialFlow.isValidStage(tutorial.stage) then
            profile.tutorial.stage = tutorial.stage
        end
        if tutorial.complete == true or profile.tutorial.stage == "complete" then
            profile.tutorial.complete = true
            profile.tutorial.stage = "complete"
        end
        if
            type(tutorial.selectedTool) == "string"
            and (
                tutorial.selectedTool == "axe"
                or tutorial.selectedTool == "hammer"
                or tutorial.selectedTool == "torch"
            )
        then
            profile.tutorial.selectedTool = tutorial.selectedTool
        end
        if
            profile.tutorial.complete
            and type(tutorial.completedAt) == "number"
            and tutorial.completedAt > 0
        then
            profile.tutorial.completedAt = tutorial.completedAt
        end
    end

    profile.inventory = ExpeditionInventory.normalize(value.inventory)
    local profession = value.profession
    if type(profession) == "table" and ProfessionCatalog.isValid(profession.selectedId) then
        profile.profession.selectedId = profession.selectedId
    end
    local story = value.story
    local chapterOne = if type(story) == "table" then story.chapterOne else nil
    if
        type(chapterOne) == "table"
        and chapterOne.status == "complete"
        and CHAPTER_ONE_DECISIONS[chapterOne.decision] == true
        and WARDEN_OUTCOMES[chapterOne.wardenOutcome] == true
        and type(chapterOne.transactionId) == "string"
        and chapterOne.transactionId ~= ""
        and #chapterOne.transactionId <= 160
        and type(chapterOne.completedAt) == "number"
        and chapterOne.completedAt > 0
    then
        profile.story.chapterOne = {
            completedAt = chapterOne.completedAt,
            decision = chapterOne.decision,
            status = "complete",
            transactionId = chapterOne.transactionId,
            wardenOutcome = chapterOne.wardenOutcome,
        }
    end
    local town = value.town
    if
        type(town) == "table"
        and type(town.nightNumber) == "number"
        and town.nightNumber >= 1
        and town.nightNumber <= MAX_NIGHT_NUMBER
        and town.nightNumber == math.floor(town.nightNumber)
    then
        profile.town.nightNumber = town.nightNumber
    end
    profile.gear = Crafting.normalizeGear(value.gear)

    profile.schemaVersion = 6
    return profile
end

function SaveSchema.withTutorial(
    profile: Profile,
    stage: TutorialFlow.Stage,
    selectedTool: string?,
    now: number
): Profile
    local nextProfile = table.clone(profile)
    nextProfile.tutorial = table.clone(profile.tutorial)
    nextProfile.tutorial.stage = stage
    nextProfile.tutorial.complete = stage == "complete"
    nextProfile.tutorial.selectedTool = selectedTool
    if stage == "complete" then
        if not profile.tutorial.complete or nextProfile.tutorial.completedAt == nil then
            nextProfile.tutorial.completedAt = now
        end
    else
        nextProfile.tutorial.completedAt = nil
    end
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
end

function SaveSchema.withProfession(profile: Profile, professionId: string, now: number): Profile
    assert(ProfessionCatalog.isValid(professionId), "profession ID is invalid")
    local nextProfile = table.clone(profile)
    nextProfile.profession = table.clone(profile.profession)
    nextProfile.profession.selectedId = professionId
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
end

function SaveSchema.withUnbankedExpeditionReward(
    profile: Profile,
    transactionId: string,
    manifestHash: string,
    reward: any,
    now: number
): (Profile, any)
    local nextInventory, result =
        ExpeditionInventory.addUnbanked(profile.inventory, transactionId, manifestHash, reward, now)
    if not result.applied then
        return profile, result
    end

    local nextProfile = table.clone(profile)
    nextProfile.inventory = nextInventory
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.expeditionPending(profile: Profile): any
    return ExpeditionInventory.pending(profile.inventory)
end

function SaveSchema.expeditionSettlementId(
    runId: string,
    userId: number,
    pendingFingerprint: string
): string
    return ExpeditionInventory.settlementId(runId, userId, pendingFingerprint)
end

function SaveSchema.withExpeditionSettlement(
    profile: Profile,
    settlementId: string,
    manifestHash: string,
    now: number
): (Profile, any)
    local nextInventory, result =
        ExpeditionInventory.settle(profile.inventory, settlementId, manifestHash, now)
    if not result.applied then
        return profile, result
    end

    local nextProfile = table.clone(profile)
    nextProfile.inventory = nextInventory
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.hasExpeditionSettlement(profile: Profile, settlementId: string): boolean
    return ExpeditionInventory.hasSettlement(profile.inventory, settlementId)
end

function SaveSchema.hasExpeditionReward(profile: Profile, transactionId: string): boolean
    return ExpeditionInventory.hasReward(profile.inventory, transactionId)
end

function SaveSchema.findExpeditionSettlementForRewards(
    profile: Profile,
    rewardTransactionIds: { string }
): (string?, any?)
    return ExpeditionInventory.findSettlementForRewards(profile.inventory, rewardTransactionIds)
end

function SaveSchema.withChapterOneResolution(
    profile: Profile,
    transactionId: string,
    decision: string,
    wardenOutcome: string,
    now: number
): (Profile, any)
    assert(transactionId ~= "" and #transactionId <= 160, "chapter transaction ID is invalid")
    assert(CHAPTER_ONE_DECISIONS[decision] == true, "chapter decision is invalid")
    assert(WARDEN_OUTCOMES[wardenOutcome] == true, "Warden outcome is invalid")
    local current = profile.story.chapterOne
    if current.status == "complete" then
        return profile,
            {
                applied = false,
                duplicate = current.transactionId == transactionId,
                reason = if current.transactionId == transactionId
                    then "duplicate"
                    else "chapter_already_resolved",
                record = table.clone(current),
            }
    end

    local nextProfile = table.clone(profile)
    nextProfile.story = table.clone(profile.story)
    nextProfile.story.chapterOne = {
        completedAt = now,
        decision = decision,
        status = "complete",
        transactionId = transactionId,
        wardenOutcome = wardenOutcome,
    }
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile,
        {
            applied = true,
            duplicate = false,
            reason = "resolved",
            record = table.clone(nextProfile.story.chapterOne),
        }
end

function SaveSchema.chapterOne(profile: Profile): any
    return table.clone(profile.story.chapterOne)
end

-- The town's night count is server-session state (see TownNightService) that
-- gets pushed out to every connected player's own profile whenever a night
-- completes, so a later server session can resume from whichever returning
-- player's record is highest instead of always restarting at night one.
function SaveSchema.withNightNumber(profile: Profile, nightNumber: number, now: number): Profile
    assert(
        type(nightNumber) == "number"
            and nightNumber >= 1
            and nightNumber <= MAX_NIGHT_NUMBER
            and nightNumber == math.floor(nightNumber),
        "night number is invalid"
    )
    if nightNumber <= profile.town.nightNumber then
        return profile
    end
    local nextProfile = table.clone(profile)
    nextProfile.town = table.clone(profile.town)
    nextProfile.town.nightNumber = nightNumber
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
end

function SaveSchema.nightNumber(profile: Profile): number
    return profile.town.nightNumber
end

function SaveSchema.withCraftedItem(profile: Profile, recipeId: string, now: number): (Profile, any)
    local nextMaterials, nextGear, result =
        Crafting.craft(profile.inventory.materials, profile.gear, recipeId)
    if not result.applied then
        return profile, result
    end

    local nextProfile = table.clone(profile)
    nextProfile.inventory = table.clone(profile.inventory)
    nextProfile.inventory.materials = nextMaterials
    nextProfile.gear = nextGear
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.gearSnapshot(profile: Profile): { [string]: number }
    return table.clone(profile.gear)
end

function SaveSchema.withUsedGearItem(profile: Profile, itemId: string, now: number): (Profile, any)
    local nextGear, result = Crafting.useItem(profile.gear, itemId)
    if not result.applied then
        return profile, result
    end

    local nextProfile = table.clone(profile)
    nextProfile.gear = nextGear
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

return table.freeze(SaveSchema)
