--!strict

local ExpeditionEventFlow = require("./ExpeditionEventFlow")
local PrivateServerControls = require("./PrivateServerControls")
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

-- One board per private-server control, generated from the control list rather
-- than written out, for the reason the construction prompts are generated: a
-- control added to the catalog gets a board it can be pressed on instead of
-- needing somebody to remember to add one. The rail is the only place these
-- exist, so a control with no board is a control nobody can reach.
local privateControlInteractionIds: { [string]: string } = {}
for _, control in PrivateServerControls.controls() do
    privateControlInteractionIds[control.id] = "private_control_" .. control.id
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
        RepairGear = "repair_gear",
        CompanionCommand = "companion_command",
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
        --[[
            Parties. Four kinds rather than one because they are four
            different questions, and folding them into a mode field would
            put a target and a verb in the same payload -- which is two
            extra fields, and the one-extra-field rule is the wall that
            #219 was found against.

            PartyInvite carries nothing at all on purpose: it offers a seat
            to whoever is standing on the departure platform, measured
            server-side, so a press cannot name a stranger across the map
            and cannot be forged into naming one.
        ]]
        PartyInvite = "party_invite",
        PartyReply = "party_reply",
        PartyLeave = "party_leave",
        PartyRejoin = "party_rejoin",
        --[[
            One phrase from a closed vocabulary, and nothing else. The phrase
            decides both what is said and what kind of marker it leaves; where
            the marker lands is the sender's own position, read server-side.
            A payload that could name a place would be a payload that could
            name somebody else's place.
        ]]
        QuickChat = "quick_chat",
        --[[
            Who may visit this town. Interaction-routed like every other thing
            in the world you walk up to: the gate carries it, the client sends
            a plain Interact naming the gate, and the server reads the ActionId
            off the prompt. No payload, because the press does not choose a
            value -- it takes the next one, and the gate says which that is.
        ]]
        SetVisitPolicy = "set_visit_policy",
        --[[
            The store, in four kinds because they are four different questions
            and the taxonomy already counts them apart: a view, a card looked
            at, a prompt raised, a thing worn.

            OpenStore is interaction-routed and carries nothing -- the
            outfitter's stand is the only door, so there is no payload in which
            to name a store that is somewhere else. The other three each carry
            exactly one id.

            EquipCosmetic names a cosmetic and never a slot. The slot is the
            catalog's answer about that cosmetic, which is the only version of
            it a server should trust: #331's review found `equip` letting any
            owned cosmetic go in any slot, so an outfit could be worn as a
            lantern shell. A payload that cannot name a slot cannot name the
            wrong one. Pressing an id you are already wearing takes it off,
            which is what keeps taking-off from needing a second field.
        ]]
        OpenStore = "open_store",
        StoreDetail = "store_detail",
        StorePurchase = "store_purchase",
        EquipCosmetic = "equip_cosmetic",
        --[[
            A board on the private server's control rail, and it carries no
            payload at all -- not even which board.

            Which control was pressed is an attribute on the prompt the player
            is standing at, read server-side, the same way a profession
            specialization's is. That is deliberate rather than tidy: these
            controls end a server's rewards permanently, and a payload naming
            one would let a client end them from anywhere, at any moment, with
            no rail in front of it. There is nothing to forge because there is
            nothing in the payload.
        ]]
        PrivateControl = "private_control",
        --[[
            The destination board and the region arenas, both
            interaction-routed. A destination plank carries its region id
            as the prompt's payload the way a crafting bench carries its
            recipe; an arena anchor carries its encounter and its own
            anchor id as prompt attributes, so the client can name
            neither a region it is not standing at nor a lever it cannot
            reach.
        ]]
        SelectDestination = "select_destination",
        RegionEncounter = "region_encounter",
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
        --[[
            The town gate, which is where you decide who comes through it.
            An interaction rather than a HUD control on purpose: the owner's
            screen is a portrait phone, this HUD has already had to take
            buttons back off it twice, and a setting about the town belongs in
            the town. The same reasoning moved FIND and STRIKE onto the world
            objects they act on.
        ]]
        TownGate = "town_gate_policy",
        --[[
            The outfitter's stand in the departure lodge, which is the only
            way into the store.

            A storefront that opens from a HUD button is a storefront that can
            open at any moment, and the moments this one may not open in are
            the whole of the milestone's exit gate. Making it a thing you walk
            up to in a room you are not being attacked in means the refusal is
            the rule's second line of defence rather than its only one -- the
            same reasoning that put the visit policy on the town gate.
        ]]
        Outfitter = "outfitter_stand",
    }),
    ResidentInteractionIds = table.freeze({
        npc_tomas_reed = "resident_tomas_reed",
        npc_pip_wren = "resident_pip_wren",
        npc_ena_moss = "resident_ena_moss",
    }),
    PrivateControlInteractionIds = table.freeze(privateControlInteractionIds),
    ConstructionInteractionIds = table.freeze(constructionInteractionIds),
    TownRepairInteractionIdByBuilding = table.freeze(townRepairInteractionIds),
    ProfessionSpecializationInteractionIds = table.freeze(professionSpecializationInteractionIds),
    ProfessionSpecializationInteractionIdBySpecialization = table.freeze(
        professionSpecializationInteractionIdBySpecialization
    ),
}

return table.freeze(RuntimeIds)
