--!strict

local QuestCatalog = require("./QuestCatalog")
local ResidentRoster = require("./ResidentRoster")

local ResidentDialogue = {}

export type Response = {
    message: string,
    questId: string,
    state: string,
}

--[[
    Names and quests come from the roster now; the two tables that used to
    hold them here were the first place the roster drifted, which is why
    it exists.
]]
--[[
    A resident's arc, in order, taken from the quest catalog rather than
    from a list here -- the roster names where an arc starts and the
    catalog's `requires` chain says what follows, so the two cannot drift
    into disagreeing about what somebody is asking for.
]]
local RESIDENT_ARCS: { [string]: { string } } = {}
local RESIDENT_NAMES: { [string]: string } = {}
for _, definition in ResidentRoster.list() do
    RESIDENT_ARCS[definition.id] = { definition.questId }
    RESIDENT_NAMES[definition.id] = definition.displayName
end
for _, quest in QuestCatalog.list() do
    local residentId = quest.residentId
    if residentId ~= nil and quest.requires ~= nil and RESIDENT_ARCS[residentId] ~= nil then
        table.insert(RESIDENT_ARCS[residentId], quest.id)
    end
end
table.freeze(RESIDENT_NAMES)

--[[
    What the residents brought back from their own regions say once their
    work is done. Chapter I's three answer to the town's decisions, which
    is handled below; these four-and-four answer to the places they came
    from, and each one is a person rather than a job title.
]]
-- What each resident asks for, in their own words.
local GUIDANCE = table.freeze({
    npc_tomas_reed = "CRAFT ONE USEFUL ITEM AT THE WORKBENCH",
    npc_pip_wren = "HELP THE LANTERN ROAD SURVIVE THREE NIGHTS",
    npc_ena_moss = "RETURN SAFELY FROM BRAMBLEWAKE THREE TIMES",
    npc_hesper_vane = "BRING ME GEAR THAT HAS FOUND ITS OWN CHARACTER",
    npc_odell_crane = "FILL THE STORES — SIXTY OF ANYTHING WILL DO",
    npc_junie_falk = "KEEP THE LIGHT LIT FOR SEVEN NIGHTS",
    npc_bartram_hoke = "RAISE FOUR BUILDINGS SO THERE IS SOMEWHERE TO COOK",
    npc_saoirse_quill = "COME BACK FROM BRAMBLEWAKE EIGHT TIMES, AND I WILL RULE THE COLUMN",
    npc_wren_dabbler = "PUT UP THREE DECORATIONS — THIS TOWN SHOULD LOOK LIVED IN",
    npc_marek_still = "CRAFT SIX THINGS AND LOOK TWICE AT EACH",
    npc_lissen_ford = "BE TRUSTED BY THREE RESIDENTS — CHECK ON THEM",
    npc_isolde_maren = "KEEP THE LIGHT LIT FOURTEEN NIGHTS. I HAVE DONE LONGER FOR LESS",
    npc_cass_pell = "MAKE TWENTY THINGS WITH YOUR HANDS AND I WILL TEACH YOU ROPE",
    npc_alder_kine = "TWO HUNDRED IN THE STORES. I WANT TO SEE THE COLUMN IN BLACK ONCE",
    npc_nell_barrow = "FOURTEEN TRIPS BACK FROM BRAMBLEWAKE — BACK IS THE PART THAT COUNTS",
    npc_anselm_rill = "FIND FOUR OF WHAT THIS PLACE REMEMBERS. SOMEBODY SHOULD KEEP IT",
    npc_ivy_thorn = "BE TRUSTED BY EIGHT OF US. I COUNT BY NAME, NOT BY HEAD",
    npc_halvard_sunn = "CLOSE EVERY CHAPTER. A STORE IS ONLY FULL WHEN NOTHING IS STILL OPEN",
    npc_maud_ferrow = "RAISE TWELVE BUILDINGS. TWELVE DOORS IS A TOWN, NOT A CAMP",
    npc_sabine_ash = "MAKE FORTY THINGS. NOT ONE OF THEM SHAPED LIKE A PERSON",
    npc_theo_marl = "FIND EIGHT OF WHAT THIS WORLD REMEMBERS AND I WILL COPY THEM OUT",
    npc_delia_kass = "BE TRUSTED BY FOURTEEN OF US. NAMES, NOT NUMBERS",
    npc_bran_holt = "TWENTY BUILDINGS STANDING. I WILL CUT THE BEAMS FOR THE REST",
    npc_orin_vale = "CLOSE ALL SEVEN. I HAVE BEEN WAITING ON THE LAST ONE A LONG TIME",
    npc_signe_marr = "FOUR HUNDRED IN THE STORES. A TOWN SHOULD NEVER BE THIRSTY AGAIN",
    npc_ruth_calder = "PUT UP EIGHT DECORATIONS. NOBODY MEETS IN A ROOM NOBODY LIKES",
    npc_edda_pyne = "THIRTY NIGHTS. I WILL HAVE THE WARDS UP BY THE TENTH",
})

local ARRIVAL_LINES = table.freeze({
    npc_hesper_vane = "A TOOL YOU KEPT SHARP IS A DAY YOU MEANT TO SURVIVE. BRING ME THE DULL ONES.",
    npc_odell_crane = "FULL STORES AND A QUIET BELL. I COULD ALMOST SIT DOWN.",
    npc_junie_falk = "SEVEN NIGHTS LIT IN A ROW. DOWN BELOW WE NEVER MANAGED THREE.",
    npc_bartram_hoke = "A REAL KITCHEN. I HAVE BEEN COOKING OUT OF A HELMET SINCE I WAS TWENTY.",
    npc_saoirse_quill = "NAMES OUT AND NAMES BACK, AND THE COLUMNS AGREE. I HAVE NOT WRITTEN THAT IN YEARS.",
    npc_wren_dabbler = "I WOVE ONE FOR EVERY HOUSE THE WATER TOOK. NOW I WEAVE THEM FOR DOORS THAT STAND.",
    npc_marek_still = "LOOK TWICE AT WHAT YOU CARRY. THE FEN TAUGHT ME THAT AND IT COST IT NOTHING.",
    npc_lissen_ford = "EVERY HEAD COUNTED AT DUSK, AND EVERY ONE OF THEM KNOWS YOUR NAME. THAT IS THE WORK.",
    npc_isolde_maren = "FOURTEEN NIGHTS AND THE LIGHT NEVER WENT OUT. NOBODY DROWNED LOOKING FOR IT.",
    npc_cass_pell = "GOOD ROPE IS A PROMISE YOU CAN PULL ON. THIS TOWN HAS ENOUGH OF IT NOW.",
    npc_alder_kine = "THE COLUMN IS IN BLACK. I HAVE NOT WRITTEN THAT SINCE THE HARBOUR WENT.",
    npc_nell_barrow = "EVERY TRIP OUT CAME BACK. THAT IS THE ONLY LEDGER I HAVE EVER KEPT.",
    npc_anselm_rill = "FOUR THINGS THIS PLACE REMEMBERS, AND SOMEONE ALIVE TO REMEMBER THEM.",
    npc_ivy_thorn = "EIGHT NAMES, ALL OF THEM ANSWERING. THE ABBEY NEVER MANAGED THAT.",
    npc_halvard_sunn = "NOTHING LEFT OPEN AND THE STORE STILL SHUT. THAT IS A WINTER SURVIVED.",
    npc_maud_ferrow = "TWELVE DOORS, AND NOT ONE OF THEM MINE TO GIVE AWAY. GOOD.",
    npc_sabine_ash = "FORTY THINGS AND NOT A FACE AMONG THEM. I CAN WORK IN A TOWN LIKE THIS.",
    npc_theo_marl = "EIGHT OF THEM, COPIED OUT PROPERLY. THE SCRATCHED NAMES GO IN THE SAME BOOK NOW.",
    npc_delia_kass = "FOURTEEN PEOPLE WHO KNOW YOUR NAME AND YOU KNOW THEIRS. THAT IS A MEMORIAL.",
    npc_bran_holt = "TWENTY STANDING. LET SOMETHING TRY TO BURN THIS ONE.",
    npc_orin_vale = "ALL SEVEN CLOSED, AND I AM STANDING IN DAYLIGHT. I HAD STOPPED EXPECTING IT.",
    npc_signe_marr = "FOUR HUNDRED IN STORE AND THE WELL STILL COLD. NOBODY GOES SHORT THIS YEAR.",
    npc_ruth_calder = "EIGHT THINGS SOMEBODY CHOSE TO PUT UP. NOW IT IS A ROOM AND NOT A SHELTER.",
    npc_edda_pyne = "THIRTY NIGHTS AND THE WARDS TOOK THE FIRST BITE OF EVERY ONE.",
})

--[[
    Later stages of an arc speak for themselves rather than for the person
    -- the same resident is asking, so the name is already on the line,
    and what changes is what they want next. Stage one keeps GUIDANCE and
    ARRIVAL_LINES above, which players have already heard.
]]
local STAGE_GUIDANCE = table.freeze({
    quest_tomas_second_bench = "TWELVE THINGS MADE. I WANT A BENCH THAT LOOKS WORKED AT",
    quest_tomas_full_house = "TEN PEOPLE WHO TRUST YOU. THEN EVERY BED HERE IS FULL",
    quest_pip_further_roads = "SIX RUNS OUT AND BACK. I WANT THE FAR ROADS ON THE BOARD",
    quest_pip_every_night = "TWENTY-ONE NIGHTS POSTED BEFORE THEY ARRIVED. NOT ONE SURPRISE",
    quest_ena_first_growth = "FIVE THINGS PLANTED OR HUNG. THIS PLACE SHOULD LOOK TENDED",
    quest_ena_the_archive = "SIX OF WHAT THE FOREST KEPT. IT IS A STORY, NOT A COLLECTION",
})

local STAGE_STORIES = table.freeze({
    quest_tomas_second_bench = "TWELVE THINGS OFF THAT BENCH AND THE GRAIN IS GOING SMOOTH. THAT IS WHAT A TOOL BENCH IS FOR.",
    quest_tomas_full_house = "EVERY BED FULL AND I KNOW WHO IS IN EACH ONE. I DID NOT THINK I WOULD SEE THAT AGAIN.",
    quest_pip_further_roads = "SIX RUNS OUT AND SIX BACK. THE FAR ROADS ARE ON THE BOARD NOW, IN INK.",
    quest_pip_every_night = "TWENTY-ONE NIGHTS AND NOBODY WAS SURPRISED BY ANY OF THEM. THAT IS THE WHOLE JOB.",
    quest_ena_first_growth = "FIVE THINGS PLANTED, AND THE TOWN LOOKS TENDED INSTEAD OF OCCUPIED.",
    quest_ena_the_archive = "SIX OF THEM, IN ORDER. IT IS A STORY, AND SOMEBODY IS FINALLY READING IT.",
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

local function completedStory(residentId: string, consequence: any, questId: string?): string
    -- A later stage of an arc has its own answer; only stage one falls
    -- back to the resident's arrival line.
    local staged = if questId ~= nil then STAGE_STORIES[questId] else nil
    if staged ~= nil then
        return staged
    end
    local arrival = ARRIVAL_LINES[residentId]
    if arrival ~= nil then
        return arrival
    end
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
    local arc = RESIDENT_ARCS[residentId]
    local residentName = RESIDENT_NAMES[residentId]
    if arc == nil or residentName == nil then
        return nil
    end
    --[[
        Whichever stage of their arc they are on: the first one they have
        not finished. A stage the caller knows nothing about is not the
        answer -- an arc can run ahead of what a snapshot carries -- so an
        unknown stage falls back to the last one there is a record for,
        and a resident who has been answered talks about what happened
        rather than repeating a request.
    ]]
    local questId: string? = nil
    local lastKnown: string? = nil
    for _, candidate in arc do
        local record = questById(quests, candidate)
        if record ~= nil then
            lastKnown = candidate
            if record.claimed ~= true then
                questId = candidate
                break
            end
        end
    end
    -- arc[1] always exists: the roster's own questId seeded it.
    local currentQuestId: string = questId or lastKnown or arc[1]

    local quest = questById(quests, currentQuestId)
    if quest == nil then
        return {
            message = residentName .. ": CHECK BACK WHEN THE GREENWARD RECORDS ARE READY.",
            questId = currentQuestId,
            state = "loading",
        }
    end
    if quest.claimed == true then
        return {
            message = residentName
                .. ": "
                .. completedStory(residentId, consequence, currentQuestId),
            questId = currentQuestId,
            state = "story",
        }
    end

    local current = math.max(0, math.floor(tonumber(quest.progress) or 0))
    local threshold = math.max(1, math.floor(tonumber(quest.threshold) or 1))
    local guidance = STAGE_GUIDANCE[currentQuestId]
        or GUIDANCE[residentId]
        or "RETURN SAFELY FROM BRAMBLEWAKE THREE TIMES"
    return {
        message = string.format(
            "%s: %s — %d/%d. I WILL MARK IT WHEN IT IS DONE.",
            residentName,
            guidance,
            math.min(current, threshold),
            threshold
        ),
        questId = currentQuestId,
        state = if current >= threshold then "ready" else "active",
    }
end

return table.freeze(ResidentDialogue)
