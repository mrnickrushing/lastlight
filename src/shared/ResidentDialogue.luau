--!strict

local ResidentDialogue = {}

export type Response = {
    message: string,
    questId: string,
    state: string,
}

local RESIDENT_QUESTS = table.freeze({
    npc_tomas_reed = "quest_first_craft",
    npc_pip_wren = "quest_survive_three_nights",
    npc_ena_moss = "quest_bramblewake_veteran",
})

local RESIDENT_NAMES = table.freeze({
    npc_tomas_reed = "TOMAS",
    npc_pip_wren = "PIP",
    npc_ena_moss = "ENA",
})

local function questById(quests: any, questId: string): any
    if type(quests) ~= "table" then
        return nil
    end
    for _, quest in quests do
        if type(quest) == "table" and quest.id == questId then
            return quest
        end
    end
    return nil
end

local function completedStory(residentId: string, consequence: any): string
    local decision = if type(consequence) == "table" then consequence.decision else nil
    local wardenOutcome = if type(consequence) == "table" then consequence.wardenOutcome else nil
    if residentId == "npc_tomas_reed" then
        if decision == "restore_farmland" then
            return "THE RENEWED FIELDS NEED TOOLS AS MUCH AS SEED. KEEP THE BENCH BUSY."
        elseif decision == "wild_regrowth" then
            return "THE WILD GROVE GIVES LESS ON COMMAND, BUT MORE TO THOSE WHO LISTEN."
        elseif decision == "shared_agroforest" then
            return "FOREST AND FIELD ARE SHARING ONE TABLE NOW. THAT IS WORTH BUILDING FOR."
        end
        return "ONE GOOD TOOL CAN TURN A BAD NIGHT. KEEP MAKING WHAT THE TOWN NEEDS."
    elseif residentId == "npc_pip_wren" then
        if wardenOutcome == "preserved" then
            return "THE WARDEN LEFT OLD TRACKS OPEN. I HAVE MARKED THE SAFEST ONES."
        elseif wardenOutcome == "scarred" then
            return "THE SCARRED TRAILS SHIFT AFTER RAIN. FOLLOW THE FRESH AMBER MARKS."
        elseif wardenOutcome == "harmed" then
            return "THE FOREST IS WATCHING THE ROAD NOW. TRAVEL WITH LIGHT AND COMPANY."
        end
        return "THREE DAWNS PROVE A ROAD CAN HOLD. THE NEXT ONE STILL NEEDS A SCOUT."
    elseif decision == "restore_farmland" then
        return "I SAVED BRAMBLEWAKE SEED FOR THESE FURROWS. THE FIRST SHOOTS ARE YOURS TOO."
    elseif decision == "wild_regrowth" then
        return "THE GROVE IS CHOOSING ITS OWN SHAPE. WATCH WHERE THE BRIGHTCAPS RETURN."
    elseif decision == "shared_agroforest" then
        return "ROOT, CROP, AND LANTERN ARE GROWING TOGETHER. KEEP BRINGING PEOPLE HOME."
    end
    return "EVERY SAFE RETURN TEACHES THE GREENWARD HOW TO GROW AROUND US."
end

function ResidentDialogue.respond(residentId: any, quests: any, consequence: any): Response?
    if type(residentId) ~= "string" then
        return nil
    end
    local questId = RESIDENT_QUESTS[residentId]
    local residentName = RESIDENT_NAMES[residentId]
    if questId == nil or residentName == nil then
        return nil
    end

    local quest = questById(quests, questId)
    if quest == nil then
        return {
            message = residentName .. ": CHECK BACK WHEN THE GREENWARD RECORDS ARE READY.",
            questId = questId,
            state = "loading",
        }
    end
    if quest.claimed == true then
        return {
            message = residentName .. ": " .. completedStory(residentId, consequence),
            questId = questId,
            state = "story",
        }
    end

    local current = math.max(0, math.floor(tonumber(quest.progress) or 0))
    local threshold = math.max(1, math.floor(tonumber(quest.threshold) or 1))
    local guidance = if residentId == "npc_tomas_reed"
        then "CRAFT ONE USEFUL ITEM AT THE WORKBENCH"
        elseif residentId == "npc_pip_wren" then "HELP THE LANTERN ROAD SURVIVE THREE NIGHTS"
        else "RETURN SAFELY FROM BRAMBLEWAKE THREE TIMES"
    return {
        message = string.format(
            "%s: %s — %d/%d. I WILL MARK IT WHEN IT IS DONE.",
            residentName,
            guidance,
            math.min(current, threshold),
            threshold
        ),
        questId = questId,
        state = if current >= threshold then "ready" else "active",
    }
end

return table.freeze(ResidentDialogue)
