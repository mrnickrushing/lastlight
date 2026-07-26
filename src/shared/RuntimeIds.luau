--!strict

local RuntimeIds = {
    FolderName = "LastLightRuntime",
    WorldName = "LastLightWorld",
    InteractionTag = "LastLightInteractable",
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
        CompactHud = "compact_hud",
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
    }),
}

return table.freeze(RuntimeIds)
