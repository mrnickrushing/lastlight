--!strict

local ToolCatalog = require("./ToolCatalog")
local TutorialFlow = require("./TutorialFlow")
local ExpeditionInventory = require("./ExpeditionInventory")
local ProfessionCatalog = require("./ProfessionCatalog")
local Crafting = require("./Crafting")
local MemoryFragments = require("./MemoryFragments")
local Quests = require("./Quests")
local ProfessionMastery = require("./ProfessionMastery")
local Equipment = require("./Equipment")
local ResidentLife = require("./ResidentLife")
local TownDecorations = require("./TownDecorations")
local TownProgression = require("./TownProgression")
local TownCondition = require("./TownCondition")
local TownConstruction = require("./TownConstruction")

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
        mastery: ProfessionMastery.State,
    },
    story: {
        chapterOne: {
            completedAt: number?,
            decision: string?,
            status: string,
            transactionId: string?,
            wardenOutcome: string?,
        },
        fragments: { [string]: boolean },
    },
    town: {
        nightNumber: number,
        condition: TownCondition.State,
        construction: { [string]: number },
        residents: ResidentLife.State,
        crisis: ResidentLife.Crisis?,
        decorations: TownDecorations.State,
    },
    gear: { [string]: number },
    equipped: Equipment.Equipped,
    quests: {
        claimed: { [string]: boolean },
    },
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
        schemaVersion = 16,
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
            mastery = ProfessionMastery.default(),
        },
        story = {
            chapterOne = {
                completedAt = nil,
                decision = nil,
                status = "unresolved",
                transactionId = nil,
                wardenOutcome = nil,
            },
            fragments = MemoryFragments.normalize(nil),
        },
        town = {
            nightNumber = 1,
            condition = TownCondition.default(),
            construction = TownConstruction.default(),
            residents = ResidentLife.default(),
            crisis = nil,
            decorations = TownDecorations.default(),
        },
        gear = Crafting.default(),
        equipped = Equipment.default(),
        quests = {
            claimed = Quests.default(),
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
        -- Validated against the tool catalog rather than three literals:
        -- the roster is eight families now, and the catalog is where a
        -- tool's very existence is decided.
        if ToolCatalog.isValid(tutorial.selectedTool) then
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
    if type(profession) == "table" then
        if ProfessionCatalog.isValid(profession.selectedId) then
            profile.profession.selectedId = profession.selectedId
        end
        profile.profession.mastery = ProfessionMastery.normalize(profession.mastery)
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
    -- Recovered memory fragments. Unknown IDs are dropped the same way gear
    -- and quest claims drop theirs, so a retired fragment cannot keep
    -- occupying an archive count. A schema-13 profile simply arrives with
    -- none recovered, which is the truthful migration: nothing was collected
    -- before the system existed.
    profile.story.fragments =
        MemoryFragments.normalize(if type(story) == "table" then story.fragments else nil)
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
    profile.town.condition =
        TownCondition.normalize(if type(town) == "table" then town.condition else nil)

    --[[
        Construction orders (schema 12) must grandfather every save that
        predates them. A save from before this field existed carries no
        `town.construction` table at all -- that absence, not any particular
        value inside it, is what marks a pre-migration profile, because a
        genuinely fresh schema-12 save also starts with an empty table (no
        building funded yet) and must not be treated as needing a rescue.

        Grandfathering happens by re-deriving the exact ceiling nights and
        chapter one already granted, using TownProgression.resolve against
        the `profile` this function has already built above -- its
        town.nightNumber and story.chapterOne are already the trustworthy,
        normalized values for this save, not the raw (and possibly forged)
        input. Seeding the ledger to that ceiling means every building a
        player already had looks exactly as built as it did a moment ago;
        only growth beyond what nights had already unlocked requires payment
        from here on. Getting this wrong either lets a hostile save claim
        stages nights never granted, or -- far worse -- rolls every existing
        town back to bare construction sites the instant this ships.
    ]]
    if type(town) == "table" and type(town.construction) == "table" then
        profile.town.construction = TownConstruction.normalize(town.construction)
    else
        profile.town.construction =
            TownConstruction.normalize(TownProgression.resolve(profile).buildingStages)
    end

    -- Resident life (schema 15). A pre-15 profile arrives with everyone
    -- healthy, no bonds, and no crisis -- the truthful migration: none of it
    -- existed before the system did.
    profile.town.residents =
        ResidentLife.normalize(if type(town) == "table" then town.residents else nil)
    local crisis = if type(town) == "table" then town.crisis else nil
    if
        type(crisis) == "table"
        and type(crisis.id) == "string"
        and type(crisis.kind) == "string"
        and type(crisis.title) == "string"
        and type(crisis.detail) == "string"
        and type(crisis.startedNight) == "number"
    then
        profile.town.crisis = {
            id = crisis.id,
            kind = crisis.kind,
            title = crisis.title,
            detail = crisis.detail,
            startedNight = math.max(1, math.floor(crisis.startedNight)),
        }
    else
        profile.town.crisis = nil
    end

    -- Decorations (schema 16): a pre-16 save simply has none placed.
    profile.town.decorations =
        TownDecorations.normalize(if type(town) == "table" then town.decorations else nil)

    profile.gear = Crafting.normalizeGear(value.gear)
    profile.equipped = Equipment.normalize(value.equipped)
    local quests = value.quests
    profile.quests.claimed =
        Quests.normalizeClaimed(if type(quests) == "table" then quests.claimed else nil)

    profile.schemaVersion = 16
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

function SaveSchema.withMasteryAward(
    profile: Profile,
    professionId: string,
    amount: number,
    now: number
): (Profile, any)
    local nextMastery, result =
        ProfessionMastery.award(profile.profession.mastery, professionId, amount)
    if not result.applied then
        return profile, result
    end
    local nextProfile = table.clone(profile)
    nextProfile.profession = table.clone(profile.profession)
    nextProfile.profession.mastery = nextMastery
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.withProfessionSpecialization(
    profile: Profile,
    professionId: string,
    specializationId: string,
    now: number
): (Profile, any)
    local nextMastery, result = ProfessionMastery.selectSpecialization(
        profile.profession.mastery,
        professionId,
        specializationId
    )
    if not result.applied then
        return profile, result
    end
    local nextProfile = table.clone(profile)
    nextProfile.profession = table.clone(profile.profession)
    nextProfile.profession.mastery = nextMastery
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
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

function SaveSchema.expeditionRecoveryCacheId(
    runId: string,
    userId: number,
    fingerprint: string
): string
    return ExpeditionInventory.recoveryCacheId(runId, userId, fingerprint)
end

function SaveSchema.withExpeditionFailureCache(
    profile: Profile,
    cacheId: string,
    manifestHash: string,
    now: number
): (Profile, any)
    local nextInventory, result =
        ExpeditionInventory.cacheAfterFailure(profile.inventory, cacheId, manifestHash, now)
    if not result.applied then
        return profile, result
    end
    local nextProfile = table.clone(profile)
    nextProfile.inventory = nextInventory
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.expeditionRecovery(profile: Profile): any
    return ExpeditionInventory.activeRecovery(profile.inventory)
end

function SaveSchema.expeditionCachedTransactionIds(profile: Profile): { string }
    return ExpeditionInventory.cachedTransactionIds(profile.inventory)
end

function SaveSchema.withRecoveredExpeditionCache(
    profile: Profile,
    cacheId: string,
    now: number
): (Profile, any)
    local nextInventory, result = ExpeditionInventory.recover(profile.inventory, cacheId, now)
    if not result.applied then
        return profile, result
    end
    local nextProfile = table.clone(profile)
    nextProfile.inventory = nextInventory
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
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
    local nextInventory, result = ExpeditionInventory.settle(
        profile.inventory,
        settlementId,
        manifestHash,
        now,
        TownProgression.storageCapForTier(TownProgression.resolve(profile).tier)
    )
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

-- Whether two condition states describe the same town. Compared building by
-- building rather than through the derived average, because two different sets
-- of damaged buildings can average to the same number and writing one over the
-- other would lose a player's repairs without changing the revision.
local function sameTownCondition(left: TownCondition.State, right: TownCondition.State): boolean
    if
        left.lastNightNumber ~= right.lastNightNumber
        or left.lastDamage ~= right.lastDamage
        or left.repairsCompleted ~= right.repairsCompleted
    then
        return false
    end
    for buildingId, integrity in left.buildings do
        if right.buildings[buildingId] ~= integrity then
            return false
        end
    end
    for buildingId, integrity in right.buildings do
        if left.buildings[buildingId] ~= integrity then
            return false
        end
    end
    return true
end

function SaveSchema.withTownCondition(profile: Profile, condition: any, now: number): Profile
    local normalized = TownCondition.normalize(condition)
    local current = TownCondition.normalize(profile.town.condition)
    if sameTownCondition(normalized, current) then
        return profile
    end
    local nextProfile = table.clone(profile)
    nextProfile.town = table.clone(profile.town)
    nextProfile.town.condition = normalized
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
end

function SaveSchema.townCondition(profile: Profile): any
    return TownCondition.snapshot(profile.town.condition)
end

function SaveSchema.residentLifeSnapshot(profile: Profile): any
    local resolved = TownProgression.resolve(profile)
    return ResidentLife.snapshot(
        profile.town.residents,
        profile.town.nightNumber,
        resolved.residentIds,
        profile.town.crisis
    )
end

function SaveSchema.residentDawnBoons(profile: Profile): { ResidentLife.Boon }
    local resolved = TownProgression.resolve(profile)
    return ResidentLife.dawnBoons(
        profile.town.residents,
        profile.town.nightNumber,
        resolved.buildingStages,
        resolved.residentIds
    )
end

--[[
    A night's resident outcome: injuries, recoveries, and whatever crisis the
    night earned. One revision bump for the whole settlement, and clearing a
    crisis is part of the same write so the two can never disagree.
]]
function SaveSchema.withResidentNight(
    profile: Profile,
    context: ResidentLife.NightContext,
    now: number
): (Profile, ResidentLife.NightReport)
    local nextResidents, report = ResidentLife.resolveNight(profile.town.residents, context)
    local nextProfile = table.clone(profile)
    nextProfile.town = table.clone(profile.town)
    nextProfile.town.residents = nextResidents
    if report.crisis ~= nil then
        nextProfile.town.crisis = report.crisis
    elseif profile.town.crisis ~= nil then
        local anyInjured = false
        for _, residentId in ResidentLife.Ids do
            if ResidentLife.isInjured(nextResidents, residentId, context.nightNumber + 1) then
                anyInjured = true
                break
            end
        end
        if not anyInjured then
            nextProfile.town.crisis = nil
        end
    end
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, report
end

function SaveSchema.withResidentCheck(
    profile: Profile,
    residentId: string,
    now: number
): (Profile, ResidentLife.CheckResult)
    local nextResidents, result =
        ResidentLife.checkOn(profile.town.residents, residentId, profile.town.nightNumber)
    if not result.accepted then
        return profile, result
    end
    local nextProfile = table.clone(profile)
    nextProfile.town = table.clone(profile.town)
    nextProfile.town.residents = nextResidents
    -- Care can end a crisis: when the last injury is tended, the town
    -- exhales in the same write.
    if nextProfile.town.crisis ~= nil then
        local anyInjured = false
        for _, id in ResidentLife.Ids do
            if ResidentLife.isInjured(nextResidents, id, profile.town.nightNumber) then
                anyInjured = true
                break
            end
        end
        if not anyInjured then
            nextProfile.town.crisis = nil
        end
    end
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
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

--[[
    Recover one memory fragment.

    Idempotent by way of MemoryFragments.collect: a repeat recovery is
    reported, never applied, so a duplicated interaction cannot double-count
    the archive or bump the revision.
]]
function SaveSchema.withMemoryFragment(
    profile: Profile,
    fragmentId: string,
    now: number
): (Profile, any)
    local nextFragments, result = MemoryFragments.collect(
        profile.story.fragments,
        fragmentId,
        profile.story.chapterOne.status == "complete"
    )
    if not result.accepted then
        return profile, result
    end

    local nextProfile = table.clone(profile)
    nextProfile.story = table.clone(profile.story)
    nextProfile.story.fragments = nextFragments
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.memoryFragmentSnapshot(profile: Profile): any
    return MemoryFragments.snapshot(
        profile.story.fragments,
        profile.story.chapterOne.status == "complete"
    )
end

function SaveSchema.weaponStrikeProfile(profile: Profile): any
    return Equipment.weaponStrikeProfile(profile.equipped)
end

function SaveSchema.gearSnapshot(profile: Profile): { [string]: number }
    return table.clone(profile.gear)
end

-- Spends materials to advance one building's construction by exactly one
-- stage. `ceilingStage` is the caller's own tier-derived ceiling for this
-- building (see TownProgression.resolve), not trusted from anywhere the
-- profile itself stores, since nights and chapter one already govern it
-- independently of what a player has paid for.
function SaveSchema.withConstructionContribution(
    profile: Profile,
    buildingId: string,
    ceilingStage: number,
    now: number
): (Profile, any)
    local nextMaterials, nextConstruction, result = TownConstruction.contribute(
        profile.inventory.materials,
        profile.town.construction,
        buildingId,
        ceilingStage,
        now
    )
    if not result.applied then
        return profile, result
    end

    local nextProfile = table.clone(profile)
    nextProfile.inventory = table.clone(profile.inventory)
    nextProfile.inventory.materials = nextMaterials
    nextProfile.town = table.clone(profile.town)
    nextProfile.town.construction = nextConstruction
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.constructionSnapshot(profile: Profile): { [string]: number }
    return table.clone(profile.town.construction)
end

function SaveSchema.withPlacedDecoration(
    profile: Profile,
    decorationId: string,
    now: number
): (Profile, any)
    local tier = TownProgression.resolve(profile).tier
    local nextMaterials, nextDecorations, result = TownDecorations.place(
        profile.inventory.materials,
        profile.town.decorations,
        decorationId,
        tier
    )
    if not result.applied then
        return profile, result
    end
    local nextProfile = table.clone(profile)
    nextProfile.inventory = table.clone(profile.inventory)
    nextProfile.inventory.materials = nextMaterials
    nextProfile.town = table.clone(profile.town)
    nextProfile.town.decorations = nextDecorations
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.decorationsSnapshot(profile: Profile): any
    local tier = TownProgression.resolve(profile).tier
    return {
        placed = table.clone(profile.town.decorations),
        count = TownDecorations.count(profile.town.decorations),
        cap = TownDecorations.capForTier(tier),
    }
end

function SaveSchema.masterySnapshot(profile: Profile): ProfessionMastery.State
    return ProfessionMastery.snapshot(profile.profession.mastery)
end

function SaveSchema.equippedSnapshot(profile: Profile): Equipment.Equipped
    return Equipment.normalize(profile.equipped)
end

function SaveSchema.equipmentStats(profile: Profile): any
    return Equipment.stats(profile.equipped)
end

function SaveSchema.withEquippedItem(profile: Profile, itemId: string, now: number): (Profile, any)
    local nextEquipped, result = Equipment.equip(profile.gear, profile.equipped, itemId)
    if not result.applied then
        return profile, result
    end
    local nextProfile = table.clone(profile)
    nextProfile.equipped = nextEquipped
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

function SaveSchema.withUnequippedItem(profile: Profile, slot: string, now: number): (Profile, any)
    local nextEquipped, result = Equipment.unequip(profile.equipped, slot)
    if not result.applied then
        return profile, result
    end
    local nextProfile = table.clone(profile)
    nextProfile.equipped = nextEquipped
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
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

local function questSignals(profile: Profile): Quests.Signals
    local craftedItems = 0
    for _, count in profile.gear do
        craftedItems += count
    end
    return {
        bramblewakeSettlements = #profile.inventory.settlementOrder,
        craftedItems = craftedItems,
        nightsSurvived = math.max(0, profile.town.nightNumber - 1),
    }
end

-- Opportunistic, not event-driven: call this after any action that could
-- move a quest signal (a night completing, a craft succeeding, an
-- expedition settling). Safe to call anytime, including when nothing is
-- newly claimable — it just returns an empty result list and the same
-- profile reference.
function SaveSchema.checkAndClaimQuests(profile: Profile, now: number): (Profile, { any })
    local nextClaimed, nextMaterials, claimedResults = Quests.checkAndClaim(
        profile.quests.claimed,
        profile.inventory.materials,
        questSignals(profile)
    )
    if #claimedResults == 0 then
        return profile, claimedResults
    end

    local nextProfile = table.clone(profile)
    nextProfile.quests = table.clone(profile.quests)
    nextProfile.quests.claimed = nextClaimed
    nextProfile.inventory = table.clone(profile.inventory)
    nextProfile.inventory.materials = nextMaterials
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, claimedResults
end

function SaveSchema.questSnapshot(profile: Profile): { any }
    return Quests.snapshot(profile.quests.claimed, questSignals(profile))
end

function SaveSchema.townConsequence(profile: Profile): TownProgression.Consequence
    return TownProgression.resolve(profile)
end

return table.freeze(SaveSchema)
