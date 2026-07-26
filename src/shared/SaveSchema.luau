--!strict

local TutorialFlow = require("./TutorialFlow")
local ExpeditionInventory = require("./ExpeditionInventory")

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
}

function SaveSchema.default(now: number): Profile
    return {
        schemaVersion = 2,
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
    profile.schemaVersion = 2
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

return table.freeze(SaveSchema)
