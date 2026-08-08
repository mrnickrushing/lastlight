--!strict

--[[
    Every action has to be wired end to end, and this suite could not see
    whether it was.

    Two defects reached the owner because of that blind spot, and they are
    opposite halves of the same shape:

      * #219 -- the departure button's payload gained a contractId, the
        payload contract's allow-list did not, and the server dropped
        every real press. The action had a handler and a sender; what it
        lacked was agreement between them.
      * #249 -- CompanionCommand had an id, a contract entry, a handler
        and two toasts, and nothing on the client ever sent it. Half of
        companions was unreachable in the shipped game.

    Both were invisible to tests that check behavior, because the
    behavior was correct in isolation on both sides. What was wrong was
    the wiring, so the wiring is what this reads: the ids, the contract,
    the server's branches, and the client's senders, as text.

    A text check is the honest tool here. The client and the server are
    Roblox scripts full of Instance and game:GetService; Lune cannot run
    either. What it can do is read them, and the questions worth asking
    -- does every action have a handler, does every action have a way to
    be sent, does every extra field the client sends survive the contract
    -- are all answerable from the source.
]]

local fs = require("@lune/fs")
local ActionPayloadContract = require("../../src/shared/ActionPayloadContract")
local RuntimeIds = require("../../src/shared/RuntimeIds")
local TestRunner = require("../TestRunner")

--[[
    Read every file on each side rather than a hand-picked few: a
    hardcoded list is a second thing to keep in agreement, which is the
    exact failure mode this spec exists to catch.
]]
local function readTree(root: string, chunks: { string })
    for _, entry in fs.readDir(root) do
        local path = root .. "/" .. entry
        if fs.isDir(path) then
            readTree(path, chunks)
        elseif string.sub(entry, -5) == ".luau" then
            table.insert(chunks, fs.readFile(path))
        end
    end
end

local function readSide(root: string): string
    local chunks: { string } = {}
    readTree(root, chunks)
    return table.concat(chunks, "\n")
end

--[[
    RuntimeIds.Actions holds two different kinds of id, and conflating
    them is what made the first draft of this spec shout about seventeen
    healthy actions.

      * **Sent kinds** ride the ActionRequest remote as `payload.kind`.
        The client names them; the server branches on them. These are the
        ones the wiring cases below police.
      * **Interaction ids** are stamped on a world prompt as its ActionId
        attribute. The player taps the prompt, the client sends a plain
        Interact carrying the prompt's interactionId, and the server
        routes by the attribute. Crafting, extracting, reviving, talking
        to a resident and a dozen others work this way -- there is no
        button that sends "craft_item", there is a bench you tap.

    An id in the second group is reachable exactly when something in the
    world stamps it, so that is what gets checked for it, rather than
    demanding a client sender it should never have.
]]
local INTERACTION_ROUTED: { [string]: boolean } = {
    expedition_event = true,
    bramblewake_blackout = true,
    resolve_town_incident = true,
    extract = true,
    open_field_book = true,
    talk_resident = true,
    recover_expedition_cache = true,
    repair_town = true,
    revive = true,
    gather_resource = true,
    place_decoration = true,
    contribute_construction = true,
    select_profession_specialization = true,
    old_growth_fire = true,
    craft_item = true,
    warden_stag_choice = true,
    recover_memory_fragment = true,
    set_visit_policy = true,
    -- The outfitter's stand in the departure lodge is the store's only door.
    -- There is no HUD button that opens it, deliberately: a storefront that
    -- can be opened from anywhere can be opened in the four moments
    -- Milestone 11's exit gate says it must not.
    open_store = true,
    -- The four boards on the private server's rail. Which board is a prompt
    -- attribute the server reads, never a field the client sends: working one
    -- ends the server's rewards for good, and a payload that could name a
    -- control would end them from anywhere.
    private_control = true,
}

-- Actions the server raises on its own behalf, never in answer to a
-- client message.
local SERVER_ORIGINATED: { [string]: string } = {
    prepare = "the tutorial arms the lantern as a stage transition",
    reveal = "the tutorial reveals the road when its stage completes",
}

return {
    name = "ActionWiring",
    cases = {
        {
            name = "every action the client can send survives the payload contract",
            run = function()
                for name, kind in RuntimeIds.Actions do
                    local extra = ActionPayloadContract.extraField(RuntimeIds, kind)
                    local payload: { [string]: any } = {
                        schemaVersion = 1,
                        kind = kind,
                    }
                    if extra ~= nil then
                        payload[extra] = if extra == "partySize" or extra == "slot"
                            then 1
                            elseif extra == "enabled" or extra == "accept" then true
                            else "probe"
                    end
                    TestRunner.truthy(
                        ActionPayloadContract.isValidForKind(RuntimeIds, payload),
                        string.format(
                            "%s (%s) is refused by its own contract",
                            tostring(name),
                            tostring(kind)
                        )
                    )
                end
            end,
        },
        {
            -- #249's shape: an action nothing can send is an unreachable
            -- feature, however correct its server half is.
            name = "every action has something that sends it",
            run = function()
                local client = readSide("src/client")
                local unsent: { string } = {}
                for name, kind in RuntimeIds.Actions do
                    if SERVER_ORIGINATED[kind] == nil and not INTERACTION_ROUTED[kind] then
                        local byName = string.find(client, "Actions." .. tostring(name), 1, true)
                        local byKind = string.find(client, string.format("%q", kind), 1, true)
                        if byName == nil and byKind == nil then
                            table.insert(unsent, string.format("%s (%s)", tostring(name), kind))
                        end
                    end
                end
                TestRunner.truthy(
                    #unsent == 0,
                    "actions nothing on the client can send: " .. table.concat(unsent, ", ")
                )
            end,
        },
        {
            -- The other half: an action the client can send but the server
            -- never branches on is a button that does nothing.
            name = "every action has something that handles it",
            run = function()
                local server = readSide("src/server")
                local unhandled: { string } = {}
                for name, kind in RuntimeIds.Actions do
                    local byName = string.find(server, "Actions." .. tostring(name), 1, true)
                    local byKind = string.find(server, string.format("%q", kind), 1, true)
                    if byName == nil and byKind == nil then
                        table.insert(unhandled, string.format("%s (%s)", tostring(name), kind))
                    end
                end
                TestRunner.truthy(
                    #unhandled == 0,
                    "actions no server branch answers: " .. table.concat(unhandled, ", ")
                )
            end,
        },
        {
            --[[
                The interaction-routed half: an id nothing in the world
                stamps on a prompt is as unreachable as an action nothing
                sends, it just fails somewhere else. This is the case that
                would notice a bench losing its ActionId.
            ]]
            name = "every interaction-routed action is stamped on something in the world",
            run = function()
                local server = readSide("src/server")
                local unstamped: { string } = {}
                for name, kind in RuntimeIds.Actions do
                    if INTERACTION_ROUTED[kind] then
                        local byName = string.find(server, "Actions." .. tostring(name), 1, true)
                        if byName == nil then
                            table.insert(unstamped, string.format("%s (%s)", tostring(name), kind))
                        end
                    end
                end
                TestRunner.truthy(
                    #unstamped == 0,
                    "interaction ids nothing stamps: " .. table.concat(unstamped, ", ")
                )
            end,
        },
        {
            -- The two groups must stay disjoint and cover the roster, so a
            -- new action cannot be quietly filed under neither.
            name = "every action belongs to exactly one wiring group",
            run = function()
                for _, kind in RuntimeIds.Actions do
                    local routed = INTERACTION_ROUTED[kind] == true
                    local originated = SERVER_ORIGINATED[kind] ~= nil
                    TestRunner.equal(
                        routed and originated,
                        false,
                        kind .. " is filed in two groups at once"
                    )
                end
            end,
        },
        {
            --[[
                The gap the cases above cannot see: an action can have a
                sender in `init.client` and still be unreachable, because the
                sender is wired to a button the HUD never draws. That is the
                same shape as the equip panel's hardcoded eight-item list,
                which left ninety craftable items unwearable while every spec
                passed -- a thing existing and a thing being reachable are
                different facts.

                The party row is checked by name because it is the newest and
                because all five of its presses share one wiring call: if
                `setPartyHandlers` were dropped, every party action would
                still have a sender by the case above and none of them would
                do anything.
            ]]
            name = "every party press has a button behind it and a wire out of it",
            run = function()
                local client = readSide("src/client")
                for _, key in { "rejoin", "accept", "decline", "invite", "leave" } do
                    TestRunner.truthy(
                        string.find(client, string.format("key = %q", key), 1, true) ~= nil,
                        "the party row draws no " .. key .. " button"
                    )
                    TestRunner.truthy(
                        string.find(client, "_partyButtons." .. key, 1, true) ~= nil,
                        "nothing reads the party row's " .. key .. " button"
                    )
                end
                --[[
                    Searched as a CALL, not as a name. `readSide` reads the
                    whole client including HUDController, which defines
                    `setPartyHandlers` -- so a bare name search is a check
                    satisfied by the very definition it is meant to prove
                    somebody uses, which is the same species of mistake as
                    the wiring gaps this spec exists for.
                ]]
                TestRunner.truthy(
                    string.find(client, "hud:setPartyHandlers", 1, true) ~= nil,
                    "the party buttons are never wired to the remote"
                )
            end,
        },
        {
            -- #219 exactly: the departure payload carries two fields, and
            -- the contract has to keep allowing both. The one-extra-field
            -- rule makes this the easiest thing in the codebase to break
            -- by accident, so it is pinned by name.
            name = "the departure payload keeps carrying its contract id",
            run = function()
                local kind = RuntimeIds.Actions.LobbyDepart
                TestRunner.equal(
                    ActionPayloadContract.isValidForKind(RuntimeIds, {
                        schemaVersion = 1,
                        kind = kind,
                        partySize = 3,
                        contractId = "contract_storm_salvage",
                    }),
                    true
                )
                -- and a field nobody agreed on is still refused
                TestRunner.equal(
                    ActionPayloadContract.isValidForKind(RuntimeIds, {
                        schemaVersion = 1,
                        kind = kind,
                        partySize = 3,
                        smuggled = "no",
                    }),
                    false
                )
            end,
        },
    },
}
