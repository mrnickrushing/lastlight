--!strict

local ExpeditionEventFlow = require("./ExpeditionEventFlow")
local ProfessionMastery = require("./ProfessionMastery")
local TownProgression = require("./TownProgression")

local professionSpecializationInteractionIds = {}
local professionSpecializationInteractionIdBySpecialization = {}
for _, specializationId in ProfessionMastery.specializationIds() do
    local interactionId = "mastery_" .. specializationId
    assert(
        professionSpecializationInteractionIdBySpecialization[specializationId] == nil,
        "duplicate profession specialization runtime ID: " .. specializationId
    )
    table.insert(professionSpecializationInteractionIds, interactionId)
    professionSpecializationInteractionIdBySpecialization[specializationId] = interactionId
end

-- One construction interaction per building, generated from the shared
-- sixteen-building list rather than written out by hand, the same reasoning
-- TownProgression.luau itself gives for driving the later eleven buildings
-- off one table: a building added to the town gets an interaction ID for
-- free instead of needing someone to remember to add one.
local constructionInteractionIds = {}
-- Storm damage is per building now, so a repair prompt belongs to a building
-- the same way a construction prompt does. Generated from the same list for the
-- same reason: a building added to the town gets both for free.
local townRepairInteractionIds = {}
for _, buildingId in TownProgression.buildingIds() do
    constructionInteractionIds[buildingId] = "construction_" .. buildingId
    townRepairInteractionIds[buildingId] = "town_repair_" .. buildingId
end

local RuntimeIds = {
    FolderName = "LastLightRuntime",
    WorldName = "LastLightWorld",
    InteractionTag = "LastLightInteractable",
    AmbientMoteTag = "LastLightAmbientMote",
    AmbientMotionTag = "LastLightAmbientMotion",
    AmbientLightTag = "LastLightAmbientLight",
    AmbientSwayTag = "LastLightAmbientSway",
    ExpeditionModuleTag = "LastLightExpeditionModule",
    ExpeditionPointOfInterestTag = "LastLightExpeditionPOI",
    ExpeditionEventTag = "LastLightExpeditionEvent",
    ExpeditionEventStepTag = "LastLightExpeditionEventStep",
    ExpeditionExtractionTag = "LastLightExpeditionExtraction",
    ExpeditionEliteTag = "LastLightExpeditionElite",
    ExpeditionBossTag = "LastLightExpeditionBoss",
    ExpeditionBlackoutTag = "LastLightExpeditionBlackout",
    PlayerDownedTag = "LastLightPlayerDowned",
    eventInteractionId = ExpeditionEventFlow.interactionId,
    Remotes = table.freeze({
        ActionRequest = "ActionRequest",
        StateChanged = "StateChanged",
        GetState = "GetState",
        -- Deliberately not an action kind. Perf samples are telemetry that
        -- grants nothing, and keeping them off the action remote means the
        -- gameplay payload contract stays one field per kind.
        PerformanceReport = "PerformanceReport",
    }),
    Actions = table.freeze({
        Rescue = "rescue",
        Gather = "gather",
        ChooseTool = "choose_tool",
        Build = "build",
        Prepare = "prepare",
        PlaceDecoration = "place_decoration",
        Reveal = "reveal",
        Interact = "interact",
        UseTool = "use_tool",
        Sprint = "sprint",
        Dodge = "dodge",
        ProfessionAbility = "profession_ability",
        SelectProfession = "select_profession",
        CompactHud = "compact_hud",
        ExpeditionEvent = "expedition_event",
        OldGrowthFire = "old_growth_fire",
        WardenStagChoice = "warden_stag_choice",
        BramblewakeBlackout = "bramblewake_blackout",
        Extract = "extract",
        Revive = "revive",
        CraftItem = "craft_item",
        UseGear = "use_gear",
        EquipGear = "equip_gear",
        LobbyDepart = "lobby_depart",
        SaveLoadout = "save_loadout",
        ApplyLoadout = "apply_loadout",
        GatherResource = "gather_resource",
        OpenFieldBook = "open_field_book",
        TalkResident = "talk_resident",
        RepairTown = "repair_town",
        ResolveTownIncident = "resolve_town_incident",
        RecoverExpeditionCache = "recover_expedition_cache",
        SelectProfessionSpecialization = "select_profession_specialization",
        ContributeConstruction = "contribute_construction",
        RecoverMemoryFragment = "recover_memory_fragment",
    }),
    InteractionIds = table.freeze({
        Mara = "mara_rescue",
        Heartwood = "heartwood_gather",
        ToolAxe = "tool_axe",
        ToolHammer = "tool_hammer",
        ToolTorch = "tool_torch",
        ToolPick = "tool_pick",
        ToolSickle = "tool_sickle",
        ToolFishingKit = "tool_fishing_kit",
        ToolClimbingKit = "tool_climbing_kit",
        ToolSurveyKit = "tool_survey_kit",
        Barricade = "barricade_build",
        Lantern = "first_lantern_prepare",
        Beacon = "bramblewake_reveal",
        Wayhome = "bramblewake_wayhome",
        OldGrowthFireSource = "old_growth_fire_source",
        OldGrowthHeart = "old_growth_root_heart",
        WardenStagRootNorth = "warden_stag_root_node_north",
        WardenStagRootEast = "warden_stag_root_node_east",
        WardenStagRootSouth = "warden_stag_root_node_south",
        WardenStagRootWest = "warden_stag_root_node_west",
        WardenStagAntlerLeft = "warden_stag_antler_left",
        WardenStagAntlerRight = "warden_stag_antler_right",
        BlackoutFireSource = "blackout_fire_source",
        BlackoutRootFarm = "blackout_root_farm",
        BlackoutRootMill = "blackout_root_mill",
        BlackoutRootCathedral = "blackout_root_cathedral",
        BlackoutDecisionFarmland = "blackout_decision_farmland",
        BlackoutDecisionWild = "blackout_decision_wild",
        BlackoutDecisionShared = "blackout_decision_shared",
        CraftMeadowSatchel = "craft_meadow_satchel_bench",
        CraftAmberCharm = "craft_amber_charm_bench",
        CraftIronrootHood = "craft_ironroot_hood_bench",
        CraftBrambleBoots = "craft_bramble_boots_bench",
        CraftThornwoodBow = "craft_thornwood_bow_bench",
        CraftHeartwoodMaul = "craft_heartwood_maul_bench",
        CraftBriarLance = "craft_briar_lance_bench",
        CraftFoxfireSling = "craft_foxfire_sling_bench",
        CraftAmberEdge = "craft_amber_edge_bench",
        CraftWardenCudgel = "craft_warden_cudgel_bench",
        QuestBoard = "quest_board",
    }),
    ResidentInteractionIds = table.freeze({
        npc_tomas_reed = "resident_tomas_reed",
        npc_pip_wren = "resident_pip_wren",
        npc_ena_moss = "resident_ena_moss",
    }),
    ConstructionInteractionIds = table.freeze(constructionInteractionIds),
    TownRepairInteractionIdByBuilding = table.freeze(townRepairInteractionIds),
    ProfessionSpecializationInteractionIds = table.freeze(professionSpecializationInteractionIds),
    ProfessionSpecializationInteractionIdBySpecialization = table.freeze(
        professionSpecializationInteractionIdBySpecialization
    ),
}

return table.freeze(RuntimeIds)
