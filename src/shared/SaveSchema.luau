--!strict

local TutorialFlow = require("./TutorialFlow")

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
}

function SaveSchema.default(now: number): Profile
    return {
        schemaVersion = 1,
        createdAt = now,
        updatedAt = now,
        revision = 0,
        tutorial = {
            stage = "arrive",
            complete = false,
            selectedTool = nil,
            completedAt = nil,
        },
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
        if type(tutorial.completedAt) == "number" and tutorial.completedAt > 0 then
            profile.tutorial.completedAt = tutorial.completedAt
        end
    end

    profile.schemaVersion = 1
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
    if stage == "complete" and nextProfile.tutorial.completedAt == nil then
        nextProfile.tutorial.completedAt = now
    end
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
end

return table.freeze(SaveSchema)
