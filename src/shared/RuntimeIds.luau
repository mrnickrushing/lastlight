--!strict

local ExpeditionEventFlow = require("./ExpeditionEventFlow")

local RuntimeIds = {
    FolderName = "LastLightRuntime",
    WorldName = "LastLightWorld",
    InteractionTag = "LastLightInteractable",
    ExpeditionModuleTag = "LastLightExpeditionModule",
    ExpeditionPointOfInterestTag = "LastLightExpeditionPOI",
    ExpeditionEventTag = "LastLightExpeditionEvent",
    ExpeditionEventStepTag = "LastLightExpeditionEventStep",
    ExpeditionExtractionTag = "LastLightExpeditionExtraction",
    PlayerDownedTag = "LastLightPlayerDowned",
    eventInteractionId = ExpeditionEventFlow.interactionId,
    Remotes = table.freeze({
        ActionRequest = "ActionRequest",
        StateChanged = "StateChanged",
        GetState = "GetState",
    }),
    Actions = table.freeze({
        Rescue = "rescue",
        Gather = "gather",
        ChooseTool = "choose_tool",
        Build = "build",
        Prepare = "prepare",
        Reveal = "reveal",
        Interact = "interact",
        UseTool = "use_tool",
        Sprint = "sprint",
        Dodge = "dodge",
        ProfessionAbility = "profession_ability",
        SelectProfession = "select_profession",
        CompactHud = "compact_hud",
        ExpeditionEvent = "expedition_event",
        Extract = "extract",
        Revive = "revive",
    }),
    InteractionIds = table.freeze({
        Mara = "mara_rescue",
        Heartwood = "heartwood_gather",
        ToolAxe = "tool_axe",
        ToolHammer = "tool_hammer",
        ToolTorch = "tool_torch",
        Barricade = "barricade_build",
        Lantern = "first_lantern_prepare",
        Beacon = "bramblewake_reveal",
        Wayhome = "bramblewake_wayhome",
    }),
}

return table.freeze(RuntimeIds)
