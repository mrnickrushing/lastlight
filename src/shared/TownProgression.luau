--!strict

local TownProgression = {}

export type Consequence = {
    tier: number,
    title: string,
    detail: string,
    decision: string?,
    wardenOutcome: string?,
    landscapeKind: string,
    memorialKind: string,
    growthStage: number,
}

function TownProgression.resolve(profile: any): Consequence
    local chapter = if type(profile) == "table" and type(profile.story) == "table"
        then profile.story.chapterOne
        else nil
    local town = if type(profile) == "table" and type(profile.town) == "table"
        then profile.town
        else nil
    local nights = if town ~= nil and type(town.nightNumber) == "number"
        then town.nightNumber
        else 1
    local tier = math.clamp(math.floor(math.max(0, nights - 1) / 3), 0, 3)
    local decision = if type(chapter) == "table" then chapter.decision else nil
    local outcome = if type(chapter) == "table" then chapter.wardenOutcome else nil
    if type(chapter) == "table" and chapter.status == "complete" then
        tier = math.max(1, tier)
    end
    local title = if decision == "restore_farmland"
        then "FARMLAND RENEWED"
        elseif decision == "wild_regrowth" then "WILD REGROWTH"
        elseif decision == "shared_agroforest" then "SHARED AGROFOREST"
        else "EMBERHOLLOW AWAKENS"
    local detail = if outcome == "preserved"
        then "The Warden's mercy keeps the old paths open."
        elseif outcome == "scarred" then "Scored roots mark a harder road through the forest."
        elseif outcome == "harmed" then "Broken antlers leave the town under a watchful shadow."
        else "Every safe night makes the lantern town stronger."
    local landscapeKind = if decision == "restore_farmland"
        then "cultivated_fields"
        elseif decision == "wild_regrowth" then "living_grove"
        elseif decision == "shared_agroforest" then "community_orchard"
        else "seed_ground"
    local memorialKind = if outcome == "preserved"
        then "living_antlers"
        elseif outcome == "scarred" then "scarred_antlers"
        elseif outcome == "harmed" then "broken_antlers"
        else "unmarked_stone"
    return {
        tier = tier,
        title = title,
        detail = detail,
        decision = decision,
        wardenOutcome = outcome,
        landscapeKind = landscapeKind,
        memorialKind = memorialKind,
        growthStage = tier,
    }
end

return table.freeze(TownProgression)
