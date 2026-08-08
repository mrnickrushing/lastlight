--!strict

local ToolCatalog = require("./ToolCatalog")
local TutorialFlow = require("./TutorialFlow")
local ExpeditionInventory = require("./ExpeditionInventory")
local ProfessionCatalog = require("./ProfessionCatalog")
local ChapterCatalog = require("./ChapterCatalog")
local Crafting = require("./Crafting")
local HollowFinale = require("./Content/Definitions/HollowFinale")
local NamelessNight = require("./NamelessNightEncounter")
local MemoryFragments = require("./MemoryFragments")
local PartySession = require("./PartySession")
local TownVisitPolicy = require("./TownVisitPolicy")
local Entitlements = require("./Entitlements")
local CosmeticCatalog = require("./CosmeticCatalog")
local Quests = require("./Quests")
local ProfessionMastery = require("./ProfessionMastery")
local Equipment = require("./Equipment")
local GearTraits = require("./GearTraits")
local GearWear = require("./GearWear")
local ResidentLife = require("./ResidentLife")
local ResidentRoster = require("./ResidentRoster")
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
    loadouts: { any },
    gearWear: { [string]: number },
    gearTraits: { [string]: string },
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
        --[[
            Chapters II onward. Chapter I keeps its original home above --
            too many systems read story.chapterOne to move it for tidiness
            -- but every chapter after it is stored uniformly here, keyed
            by chapter id, and validated against ChapterCatalog.
        ]]
        chapters: { [string]: any },
        --[[
            The finale's own record. It could not live in `chapters`: that
            block is deliberately five fixed fields, and the Hollow
            records what a party did in its scenes as well as what they
            chose at the end -- the post left empty, the light spent, who
            came back up. The epilogue reads all of it.
        ]]
        finale: {
            abandonedPost: string?,
            completedAt: number?,
            ending: string?,
            leftBehind: string?,
            light: number,
            rescued: string?,
            status: string,
            transactionId: string?,
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
    --[[
        Everything about this player's relationship to other players. One
        field so far: the ticket back to the party they were with when they
        dropped. It is a block rather than a bare `rejoin` because the rest of
        Milestone 11 arrives here too -- a visit policy, a block list -- and a
        second migration to make room for them would be a migration spent on
        tidying.

        The ticket holds a reserved-server access code, which is the whole key
        to a private world. It is written here because a profile is server-
        owned storage; it must never be put in a snapshot. PartySession's
        `publicTicket` is the shape a client may see.
    ]]
    social: {
        rejoin: PartySession.Ticket?,
        --[[
            Who may visit this player's Emberhollow. Lives beside the rejoin
            ticket because both answer the same question from opposite ends --
            the ticket is how you get back to people, the policy is who gets to
            you -- and because a `social` table with one field in it was always
            going to gain a second.
        ]]
        visitPolicy: TownVisitPolicy.Policy,
    },
    --[[
        What this player owns, what they are wearing, and every purchase
        already applied.

        Stored on the profile because entitlements are resolved outside
        gameplay and land as plain data -- nothing downstream asks the platform
        anything. The distinction the whole design rests on: gameplay branches
        on `equipped`, which is a profile field like every other, and never on
        `entitlements`, which only the commerce seam is allowed to read.
    ]]
    commerce: Entitlements.State,
    --[[
        The seeds this player has already walked, newest first.

        It exists for one reader: a private server's owner choosing which
        expedition to run again. "Among already-discovered seeds" is the whole
        bound in MONETIZATION_LIVEOPS_ANALYTICS' description of the control,
        and a bound that cannot be checked against anything is not a bound --
        so the history is a save field rather than a session's memory, because
        a player who found a layout on Tuesday means it on Thursday.

        Capped, and the cap is the point rather than tidiness: an unbounded
        list on a profile grows for the life of an account, and M12's soak gate
        asks in as many words that profile size not grow without bound. A
        history long enough to find a run you remember is short.
    ]]
    expeditions: {
        seeds: { { regionId: string, seed: number, walkedAt: number } },
    },
}

local MAX_NIGHT_NUMBER = 1_000_000
-- Long enough to hold a run somebody remembers, short enough that the list is
-- a fixed cost on every save rather than a growing one.
local MAX_DISCOVERED_SEEDS = 24

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
        schemaVersion = 25,
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
        loadouts = {},
        gearWear = {},
        gearTraits = {},
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
            chapters = {},
            finale = {
                abandonedPost = nil,
                completedAt = nil,
                ending = nil,
                leftBehind = nil,
                light = NamelessNight.StartingLight,
                rescued = nil,
                status = "unresolved",
                transactionId = nil,
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
        social = {
            rejoin = nil,
            visitPolicy = TownVisitPolicy.Default,
        },
        commerce = Entitlements.default(),
        expeditions = { seeds = {} },
    }
end

-- Newest first, deduplicated by region and seed, capped. Deduplicating matters
-- more than it looks: the same seed walked twice is one layout, and a history
-- that counted it twice would push a genuinely different run off the end.
local function normalizeSeeds(value: any): { { regionId: string, seed: number, walkedAt: number } }
    local seeds = {}
    if type(value) ~= "table" then
        return seeds
    end
    local seen: { [string]: boolean } = {}
    for _, entry in value do
        if
            type(entry) == "table"
            and type(entry.regionId) == "string"
            and #entry.regionId <= 48
        then
            local seed = tonumber(entry.seed)
            local walkedAt = tonumber(entry.walkedAt)
            if seed ~= nil and seed == seed and seed >= 0 and seed < math.huge then
                local key = entry.regionId .. ":" .. tostring(math.floor(seed))
                if not seen[key] then
                    seen[key] = true
                    table.insert(seeds, {
                        regionId = entry.regionId,
                        seed = math.floor(seed),
                        walkedAt = if walkedAt ~= nil
                                and walkedAt == walkedAt
                                and walkedAt >= 0
                            then math.floor(walkedAt)
                            else 0,
                    })
                    if #seeds >= MAX_DISCOVERED_SEEDS then
                        break
                    end
                end
            end
        end
    end
    return seeds
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

    --[[
        Schema 17: saved loadouts. Up to three slots, each remembering a
        profession, a weapon, and a tool -- every id revalidated against its
        own catalog on load, so a retired item degrades to an empty field
        rather than a faulting apply. Absent entirely (any pre-17 save),
        the player simply has no kits saved yet.
    ]]
    profile.loadouts = {}
    if type(value.loadouts) == "table" then
        for slot = 1, 3 do
            local raw = value.loadouts[slot]
            if type(raw) == "table" then
                profile.loadouts[slot] = {
                    professionId = if ProfessionCatalog.isValid(raw.professionId)
                        then raw.professionId
                        else nil,
                    weaponItemId = if Equipment.isKnown(raw.weaponItemId)
                        then raw.weaponItemId
                        else nil,
                    toolId = if ToolCatalog.isValid(raw.toolId) then raw.toolId else nil,
                }
            end
        end
    end

    -- Schema 18: equipment wear. Absent on any pre-18 save (nothing had
    -- dulled yet); junk and retired items are stripped by GearWear itself.
    profile.gearWear = GearWear.normalize(value.gearWear)
    -- Schema 19: rolled equipment traits. Revalidated per item against the
    -- trait pools; a pre-19 save arrives traitless and rolls at next craft.
    profile.gearTraits = GearTraits.normalize(value.gearTraits)

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
    --[[
        Chapters II onward. A record survives only if it names a chapter
        the catalog knows, with a decision and an outcome that chapter
        actually offers, and a real transaction id -- the same bar chapter
        one's record has always had to clear.
    ]]
    local chapters = if type(story) == "table" then story.chapters else nil
    if type(chapters) == "table" then
        for chapterId, record in chapters do
            if
                type(record) == "table"
                and record.status == "complete"
                and ChapterCatalog.get(chapterId) ~= nil
                and chapterId ~= "chapter_one"
                and ChapterCatalog.isDecision(chapterId, record.decision)
                and ChapterCatalog.isOutcome(chapterId, record.outcome)
                and type(record.transactionId) == "string"
                and record.transactionId ~= ""
                and #record.transactionId <= 160
                and type(record.completedAt) == "number"
                and record.completedAt > 0
            then
                profile.story.chapters[chapterId] = {
                    completedAt = record.completedAt,
                    decision = record.decision,
                    outcome = record.outcome,
                    status = "complete",
                    transactionId = record.transactionId,
                }
            end
        end
    end
    --[[
        The finale. A record survives only if it names an ending the
        Hollow actually offers, with a real transaction id -- the same bar
        every chapter record clears. Everything else it carries is
        detail the epilogue reads, and each field is dropped on its own
        rather than taking the record down with it, because a save that
        forgot which post was abandoned should still remember how the
        story ended.
    ]]
    local finale = if type(story) == "table" then story.finale else nil
    if type(finale) == "table" and finale.status == "complete" then
        local ending: string? = nil
        for _, definition in HollowFinale.Endings do
            if definition.id == finale.ending then
                ending = definition.id
            end
        end
        local post: string? = nil
        for _, postId in NamelessNight.PostIds do
            if postId == finale.abandonedPost then
                post = postId
            end
        end
        if
            ending ~= nil
            and type(finale.transactionId) == "string"
            and finale.transactionId ~= ""
            and #finale.transactionId <= 160
            and type(finale.completedAt) == "number"
            and finale.completedAt > 0
        then
            profile.story.finale = {
                abandonedPost = post,
                completedAt = finale.completedAt,
                ending = ending,
                leftBehind = if type(finale.leftBehind) == "string"
                        and ResidentRoster.get(finale.leftBehind) ~= nil
                    then finale.leftBehind
                    else nil,
                light = math.clamp(
                    math.floor(tonumber(finale.light) or 0),
                    0,
                    NamelessNight.StartingLight
                ),
                rescued = if type(finale.rescued) == "string"
                        and ResidentRoster.get(finale.rescued) ~= nil
                    then finale.rescued
                    else nil,
                status = "complete",
                transactionId = finale.transactionId,
            }
        end
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

    --[[
        Schema 22: the rejoin ticket. A pre-22 save arrives with none, which
        is the truthful migration -- there were no parties to be a member of,
        so there is nothing anyone should be sent back to.

        The bounding is PartySession's, not a copy of it, and it is strict:
        an unreadable ticket is no ticket. A ticket is the one saved field
        that resolves to a teleport, so the cost of accepting a bad one is a
        player thrown at a world that may not be theirs, and the cost of
        refusing a good one is that they walk to the platform again.
    ]]
    profile.social.rejoin = PartySession.normalizeTicket(
        if type(value.social) == "table" then value.social.rejoin else nil
    )
    -- An era-22 save has no policy, and the value it arrives with is the one
    -- it was already being played under: every town before this schema was
    -- open to whoever the matchmaker sent. Migrating them to `closed` would be
    -- a silent change of behaviour dressed as a safe default.
    profile.social.visitPolicy = TownVisitPolicy.normalize(
        if type(value.social) == "table" then value.social.visitPolicy else nil
    )

    -- An era-23 save owns nothing and wears nothing, because there was nothing
    -- to own: no product existed and no receipt had ever been processed. The
    -- empty default is the honest migration rather than a conservative one.
    profile.commerce = Entitlements.normalize(value.commerce, function(cosmeticId: string): boolean
        return CosmeticCatalog.get(cosmeticId) ~= nil
    end)

    -- An era-24 save has walked expeditions and remembers none of them, which
    -- is the truth rather than a loss: nothing recorded a seed before this
    -- schema, so an empty history is exactly what that player has. It fills up
    -- again on the next run they walk.
    profile.expeditions = {
        seeds = normalizeSeeds(
            if type(value.expeditions) == "table" then value.expeditions.seeds else nil
        ),
    }

    profile.schemaVersion = 25
    return profile
end

--[[
    Record a seed this player has now walked.

    Called where a manifest is actually built for somebody rather than where a
    departure is requested, because a seed nobody reached is not a seed they
    discovered -- and "already-discovered" is the only bound seed selection
    has.
]]
function SaveSchema.withDiscoveredSeed(
    profile: Profile,
    regionId: any,
    seed: any,
    now: number
): Profile
    local numericSeed = tonumber(seed)
    if type(regionId) ~= "string" or numericSeed == nil then
        return profile
    end
    local nextProfile = table.clone(profile)
    local seeds = { { regionId = regionId, seed = numericSeed, walkedAt = now } }
    for _, entry in profile.expeditions.seeds do
        table.insert(seeds, entry)
    end
    nextProfile.expeditions = { seeds = normalizeSeeds(seeds) }
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
end

-- A copy, for the same reason `commerce` hands back copies: a caller that
-- edited the profile's own table in place would change a save with no
-- normalization, no revision bump and nothing written.
function SaveSchema.discoveredSeeds(profile: Profile): { { regionId: string, seed: number } }
    local seeds = {}
    for _, entry in profile.expeditions.seeds do
        table.insert(seeds, { regionId = entry.regionId, seed = entry.seed })
    end
    return seeds
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

--[[
    Resolve chapter II or later. Same idempotency contract as chapter
    one's: a repeat of the same transaction is a duplicate rather than an
    error, a different transaction against a resolved chapter is refused,
    and a chapter cannot be resolved before the one it requires.
]]
function SaveSchema.withChapterResolution(
    profile: Profile,
    chapterId: string,
    transactionId: string,
    decision: string,
    outcome: string,
    now: number
): (Profile, any)
    assert(transactionId ~= "" and #transactionId <= 160, "chapter transaction ID is invalid")
    local definition = ChapterCatalog.get(chapterId)
    assert(definition ~= nil, "chapter is unknown")
    assert(chapterId ~= "chapter_one", "chapter one resolves through its own path")
    assert(ChapterCatalog.isDecision(chapterId, decision), "chapter decision is invalid")
    assert(ChapterCatalog.isOutcome(chapterId, outcome), "chapter outcome is invalid")

    local current = profile.story.chapters[chapterId]
    if type(current) == "table" and current.status == "complete" then
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
    if not SaveSchema.isChapterComplete(profile, (definition :: any).requires) then
        return profile,
            {
                applied = false,
                duplicate = false,
                reason = "chapter_locked",
                record = nil,
            }
    end

    local nextProfile: any = table.clone(profile)
    nextProfile.story = table.clone(profile.story)
    nextProfile.story.chapters = table.clone(profile.story.chapters)
    nextProfile.story.chapters[chapterId] = {
        completedAt = now,
        decision = decision,
        outcome = outcome,
        status = "complete",
        transactionId = transactionId,
    }
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile,
        {
            applied = true,
            duplicate = false,
            reason = "resolved",
            record = table.clone(nextProfile.story.chapters[chapterId]),
        }
end

--[[
    Record the finale.

    Written like a chapter resolution and idempotent the same way, but it
    writes two places: the finale block, which carries what a party did in
    the Hollow's scenes, and chapter seven's record, so everything that
    already reasons about chapters (tier floors, resident arrival, the
    story's shape) sees the last chapter close without learning a new
    thing to read.

    The ending is chapter seven's decision and the world state it produces
    is its outcome, which keeps the catalog's contract intact: a player
    chose `ending_shared`, and what the world became is `lantern_shared`.
]]
local ENDING_OUTCOMES: { [string]: string } = {
    ending_kept = "lantern_kept",
    ending_ended = "lantern_out",
    ending_shared = "lantern_shared",
}

function SaveSchema.withFinaleResolution(
    profile: Profile,
    transactionId: string,
    record: any,
    now: number
): (Profile, any)
    assert(transactionId ~= "" and #transactionId <= 160, "finale transaction ID is invalid")
    assert(type(record) == "table", "finale record is required")
    local outcome = ENDING_OUTCOMES[record.ending]
    assert(outcome ~= nil, "finale ending is unknown")

    local current = profile.story.finale
    if current.status == "complete" then
        return profile,
            {
                applied = false,
                duplicate = current.transactionId == transactionId,
                reason = if current.transactionId == transactionId
                    then "duplicate"
                    else "finale_already_resolved",
                record = table.clone(current),
            }
    end
    if not SaveSchema.isChapterComplete(profile, "chapter_six") then
        return profile,
            { applied = false, duplicate = false, reason = "chapter_locked", record = nil }
    end

    local nextProfile: any = table.clone(profile)
    nextProfile.story = table.clone(profile.story)
    nextProfile.story.chapters = table.clone(profile.story.chapters)
    nextProfile.story.finale = {
        abandonedPost = record.abandonedPost,
        completedAt = now,
        ending = record.ending,
        leftBehind = record.leftBehind,
        light = math.clamp(math.floor(tonumber(record.light) or 0), 0, NamelessNight.StartingLight),
        rescued = record.rescued,
        status = "complete",
        transactionId = transactionId,
    }
    nextProfile.story.chapters.chapter_seven = {
        completedAt = now,
        decision = record.ending,
        outcome = outcome,
        status = "complete",
        transactionId = transactionId,
    }
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile,
        {
            applied = true,
            duplicate = false,
            reason = "resolved",
            record = table.clone(nextProfile.story.finale),
        }
end

function SaveSchema.isChapterComplete(profile: Profile, chapterId: any): boolean
    if chapterId == nil then
        return true
    end
    if chapterId == "chapter_one" then
        return profile.story.chapterOne.status == "complete"
    end
    local record = profile.story.chapters[chapterId]
    return type(record) == "table" and record.status == "complete"
end

function SaveSchema.chapterRecord(profile: Profile, chapterId: any): any
    if chapterId == "chapter_one" then
        return table.clone(profile.story.chapterOne)
    end
    local record = profile.story.chapters[chapterId]
    return if type(record) == "table" then table.clone(record) else nil
end

--[[
    How far the story has come, as a chapter number: the highest chapter
    whose own prerequisites are all satisfied and which is itself
    complete, plus one -- i.e. the chapter now being played. Residents use
    this to know whether they have arrived yet.
]]
function SaveSchema.chapterProgress(profile: Profile): number
    local reached = 1
    for _, definition in ChapterCatalog.list() do
        if SaveSchema.isChapterComplete(profile, definition.id) then
            reached = math.max(reached, definition.number + 1)
        end
    end
    return math.min(reached, #ChapterCatalog.Order)
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

--[[
    Write, or clear, the ticket back to the party this player left with.

    Passing nil clears it, which is the call made the moment a rejoin is
    spent or refused: a ticket that outlives its usefulness is an offer the
    lodge keeps making for a world that has emptied out.

    The ticket is bounded on the way in as well as on the way out. It is
    handed over by a service that built it from a teleport call's return
    value, and a reserved-server code that came back as something other than
    a string should stop here rather than at the next load.

    Clearing is nil and only nil. A malformed ticket is refused outright
    rather than treated as a clear, because those two look identical here and
    are opposite in effect: one is a player who has arrived home, the other is
    a bad write that would silently take away the way back from a player who
    still has one.
]]
function SaveSchema.withRejoinTicket(profile: Profile, ticket: any, now: number): Profile
    local bounded = if ticket == nil then nil else PartySession.normalizeTicket(ticket)
    if ticket ~= nil and bounded == nil then
        return profile
    end
    if bounded == nil and profile.social.rejoin == nil then
        return profile
    end
    local nextProfile = table.clone(profile)
    nextProfile.social = table.clone(profile.social)
    nextProfile.social.rejoin = bounded
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
end

function SaveSchema.rejoinTicket(profile: Profile): any
    return profile.social.rejoin
end

--[[
    Set who may visit. A value the catalog does not know is refused outright
    rather than normalized to the default: the caller is the gate, the gate
    only ever offers the next value in the list, and quietly writing something
    else would mean a press that says one thing and stores another.
]]
function SaveSchema.withVisitPolicy(profile: Profile, policy: any, now: number): Profile
    if not TownVisitPolicy.isValid(policy) or policy == profile.social.visitPolicy then
        return profile
    end
    local nextProfile = table.clone(profile)
    nextProfile.social = table.clone(profile.social)
    nextProfile.social.visitPolicy = policy
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
end

function SaveSchema.visitPolicy(profile: Profile): TownVisitPolicy.Policy
    return TownVisitPolicy.normalize(profile.social.visitPolicy)
end

--[[
    Commerce state, read and written whole.

    Deliberately one accessor pair rather than a field-by-field API: every
    change to what a player owns comes from a receipt, and a receipt is applied
    by `Entitlements` in one step. Handing callers a way to set an entitlement
    directly would be handing them a way to grant one.
]]
function SaveSchema.commerce(profile: Profile): Entitlements.State
    --[[
        A copy, not the profile's own table. Every other accessor here hands
        back a scalar or a frozen value; commerce is three mutable maps, and a
        caller that edited one in place would grant an entitlement without
        going through `withCommerce` -- no normalization, no revision bump, no
        dirty flag, and a save that never records it.
    ]]
    return {
        entitlements = table.clone(profile.commerce.entitlements),
        processed = table.clone(profile.commerce.processed),
        equipped = table.clone(profile.commerce.equipped),
    }
end

function SaveSchema.withCommerce(profile: Profile, commerce: any, now: number): Profile
    local bounded = Entitlements.normalize(commerce, function(cosmeticId: string): boolean
        return CosmeticCatalog.get(cosmeticId) ~= nil
    end)
    local nextProfile = table.clone(profile)
    nextProfile.commerce = bounded
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile
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
    --[[
        The trait rolls here, at the first craft of this item type, from
        the profile's own creation time -- deterministic per save, distinct
        across saves, and never re-rolled: crafting a second bow keeps the
        first roll, because the trait belongs to YOUR bows, not to a copy.
    ]]
    nextProfile.gearTraits = table.clone((profile :: any).gearTraits or {})
    if result.itemId ~= nil and nextProfile.gearTraits[result.itemId] == nil then
        local rolled = GearTraits.rollFor(result.itemId, profile.createdAt)
        if rolled ~= nil then
            nextProfile.gearTraits[result.itemId] = rolled
            result.traitId = rolled
        end
    end
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
    --[[
        Wear reaches passive gear the same way it reaches weapons: worn
        halves what the piece adds, failing removes it entirely. The trait
        nudge rides the same per-item factor, so a worn STURDY hood fades
        as one thing, not two.
    ]]
    local wear = (profile :: any).gearWear or {}
    local effectiveness: { [string]: number } = {}
    for _, itemId in profile.equipped do
        if type(itemId) == "string" then
            effectiveness[itemId] = GearWear.effectiveness(wear, itemId)
        end
    end
    local stats = Equipment.stats(profile.equipped, effectiveness)
    -- Passive trait nudges fold in under the same clamps Equipment.stats
    -- already enforces, so a trait can shade a build but never escape it.
    local traits = (profile :: any).gearTraits or {}
    for _, itemId in profile.equipped do
        local trait = GearTraits.get(traits[itemId])
        if trait ~= nil then
            local itemEffectiveness = if type(itemId) == "string"
                then effectiveness[itemId] or 1
                else 1
            stats.damageReduction = math.clamp(
                stats.damageReduction + (trait.damageReductionBonus or 0) * itemEffectiveness,
                0,
                0.25
            )
            stats.staminaRegenMultiplier = math.clamp(
                stats.staminaRegenMultiplier + (trait.staminaRegenBonus or 0) * itemEffectiveness,
                0.75,
                1.5
            )
        end
    end
    return stats
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
    --[[
        The Milestone 7 resident quests read facts the profile already
        keeps: how much is banked, how far construction has come, how many
        decorations stand, how many pieces of gear have rolled a trait,
        and how many residents count you as more than a stranger.
    ]]
    local materialsBanked = 0
    for _, count in profile.inventory.materials do
        materialsBanked += math.max(0, math.floor(tonumber(count) or 0))
    end
    local buildingsRaised = 0
    for _, stage in (profile :: any).town.construction do
        if (tonumber(stage) or 0) >= 1 then
            buildingsRaised += 1
        end
    end
    local decorationsPlaced = 0
    for _, placed in (profile :: any).town.decorations do
        if placed == true then
            decorationsPlaced += 1
        end
    end
    local gearTraits = 0
    for _ in (profile :: any).gearTraits or {} do
        gearTraits += 1
    end
    local residentsBonded = 0
    for _, resident in (profile :: any).town.residents do
        if type(resident) == "table" and (tonumber(resident.bond) or 0) >= 50 then
            residentsBonded += 1
        end
    end
    local chaptersResolved = 0
    if (profile :: any).story.chapterOne.status == "complete" then
        chaptersResolved += 1
    end
    for _, record in (profile :: any).story.chapters do
        if type(record) == "table" and record.status == "complete" then
            chaptersResolved += 1
        end
    end
    local fragmentsRecovered = 0
    local fragmentsByRegion: { [string]: number } = {}
    for fragmentId, found in (profile :: any).story.fragments do
        if found == true then
            fragmentsRecovered += 1
            local definition = MemoryFragments.byId(fragmentId)
            local regionId = if definition ~= nil
                then (definition :: any).regionId or "region_bramblewake"
                else nil
            if regionId ~= nil then
                fragmentsByRegion[regionId] = (fragmentsByRegion[regionId] or 0) + 1
            end
        end
    end
    local masteryByProfession: { [string]: number } = {}
    for professionId, entry in (profile :: any).profession.mastery do
        if type(entry) == "table" then
            masteryByProfession[professionId] = math.max(0, tonumber(entry.level) or 0)
        end
    end
    return {
        bramblewakeSettlements = #profile.inventory.settlementOrder,
        chaptersResolved = chaptersResolved,
        fragmentsByRegion = fragmentsByRegion,
        fragmentsRecovered = fragmentsRecovered,
        masteryByProfession = masteryByProfession,
        buildingsRaised = buildingsRaised,
        craftedItems = craftedItems,
        decorationsPlaced = decorationsPlaced,
        gearTraits = gearTraits,
        materialsBanked = materialsBanked,
        nightsSurvived = math.max(0, profile.town.nightNumber - 1),
        residentsBonded = residentsBonded,
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

--[[
    Save the player's current kit into a slot: the profession they wear, the
    weapon in their hand, the tool at their hip. Reads the profile's own
    authoritative fields, so a loadout can never remember something the
    save does not actually hold.
]]
function SaveSchema.withLoadout(profile: Profile, slot: number, now: number): (Profile, any)
    if type(slot) ~= "number" or slot ~= math.floor(slot) or slot < 1 or slot > 3 then
        return profile, { applied = false, reason = "invalid_slot" }
    end
    local nextProfile: any = table.clone(profile)
    nextProfile.loadouts = table.clone((profile :: any).loadouts or {})
    local equipped = (profile :: any).equipped or {}
    local loadout = {
        professionId = (profile :: any).profession.selectedId,
        weaponItemId = equipped.weapon,
        toolId = (profile :: any).tutorial.selectedTool,
    }
    nextProfile.loadouts[slot] = loadout
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, { applied = true, slot = slot, loadout = table.clone(loadout) }
end

function SaveSchema.loadoutAt(profile: Profile, slot: any): any
    if type(slot) ~= "number" or slot ~= math.floor(slot) or slot < 1 or slot > 3 then
        return nil
    end
    local loadouts = (profile :: any).loadouts
    return if type(loadouts) == "table" then loadouts[slot] else nil
end

function SaveSchema.withGearWear(profile: Profile, itemId: any, points: number): (Profile, any)
    local nextWear, result = GearWear.accrue((profile :: any).gearWear or {}, itemId, points)
    if not result.applied then
        return profile, result
    end
    local nextProfile: any = table.clone(profile)
    nextProfile.gearWear = nextWear
    nextProfile.revision += 1
    return nextProfile, result
end

--[[
    Spend a flat table of materials ({ materialId = amount }) atomically:
    either every line is affordable and all are deducted, or nothing
    changes. Defense trap arming pays through this; it adds no profile
    field, so no schema bump rides along with it.
]]
function SaveSchema.withSpentMaterials(profile: Profile, cost: any, now: number): (Profile, any)
    local materials = (profile :: any).inventory.materials or {}
    if type(cost) ~= "table" then
        return profile, { applied = false, reason = "invalid_cost" }
    end
    for materialId, amount in cost do
        if type(amount) ~= "number" or amount <= 0 then
            return profile, { applied = false, reason = "invalid_cost" }
        end
        if (tonumber(materials[materialId]) or 0) < amount then
            return profile, { applied = false, reason = "insufficient_materials" }
        end
    end
    local nextMaterials: { [string]: number } = table.clone(materials)
    for materialId, amount in cost do
        local remaining = (nextMaterials[materialId] or 0) - amount
        if remaining <= 0 then
            nextMaterials[materialId] = nil
        else
            nextMaterials[materialId] = remaining
        end
    end
    local nextProfile: any = table.clone(profile)
    nextProfile.inventory = table.clone((profile :: any).inventory)
    nextProfile.inventory.materials = nextMaterials
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, { applied = true }
end

function SaveSchema.withRepairedGear(profile: Profile, itemId: any, now: number): (Profile, any)
    local materials = (profile :: any).inventory.materials or {}
    local nextWear, nextMaterials, result =
        GearWear.repair((profile :: any).gearWear or {}, materials, itemId)
    if not result.applied then
        return profile, result
    end
    local nextProfile: any = table.clone(profile)
    nextProfile.gearWear = nextWear
    nextProfile.inventory = table.clone((profile :: any).inventory)
    nextProfile.inventory.materials = nextMaterials
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile, result
end

--[[
    Repair a worn item in the field, with no material cost.

    Bench repair spends half a recipe's materials, which is right in a
    town with a wallet open. A field repair is a thing a player crafted
    and carried, so it has already been paid for -- charging twice would
    make the item strictly worse than walking home, which is the one place
    it cannot be used.

    Picks the most-worn item rather than taking a name, because the point
    of it is being used in a hurry.
]]
function SaveSchema.withFieldRepair(profile: Profile, now: number): (Profile, any)
    local wear = (profile :: any).gearWear or {}
    local worstId: string? = nil
    local worstPoints = 0
    for itemId, points in wear do
        local amount = tonumber(points) or 0
        if amount > worstPoints then
            worstId = itemId
            worstPoints = amount
        end
    end
    if worstId == nil then
        return profile, { applied = false, reason = "nothing_worn" }
    end
    local nextProfile: any = table.clone(profile)
    nextProfile.gearWear = table.clone(wear)
    nextProfile.gearWear[worstId] = nil
    nextProfile.updatedAt = now
    nextProfile.revision += 1
    return nextProfile,
        { applied = true, itemId = worstId, points = worstPoints, reason = "repaired" }
end

return table.freeze(SaveSchema)
