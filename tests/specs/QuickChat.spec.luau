--!strict

--[[
    Quick chat is the only player-to-player channel this game has, so what this
    suite asserts is a safety property rather than a feature: there is no way
    to compose a string, every phrase a player can reach is a phrase somebody
    chose, and a block actually stops something.

    Three of the cases read source as text, which is the honest tool for the
    two questions that are not about behaviour at all -- does a free-text path
    exist anywhere, and can every phrase in the catalog actually be pressed.
    The second is the question the census keeps answering the hard way: 120
    recipes had no bench, 24 residents had no body, ninety craftable items
    could not be equipped, and all of them passed every behavioural spec.
]]

local fs = require("@lune/fs")
local ActionPayloadContract = require("../../src/shared/ActionPayloadContract")
local Config = require("../../src/shared/Config")
local QuickChat = require("../../src/shared/QuickChat")
local RuntimeIds = require("../../src/shared/RuntimeIds")
local TestRunner = require("../TestRunner")

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

local function listFiles(root: string, paths: { string })
    for _, entry in fs.readDir(root) do
        local path = root .. "/" .. entry
        if fs.isDir(path) then
            listFiles(path, paths)
        elseif string.sub(entry, -5) == ".luau" then
            table.insert(paths, path)
        end
    end
end

local function nobodySuppressed(_fromUserId: number): boolean
    return false
end

local function callOf(phraseId: string, fromUserId: number, at: number, sequence: number): any
    local phrase = assert(QuickChat.byId(phraseId), "missing phrase " .. phraseId)
    return QuickChat.call(phrase, fromUserId, "Traveller", at, sequence, 10, 2, 30)
end

return {
    name = "QuickChat",
    cases = {
        {
            name = "the vocabulary is closed and every phrase is filed",
            run = function()
                local phrases = QuickChat.list()
                TestRunner.equal(#phrases, 24)
                local categories: { [string]: number } = {}
                for _, category in QuickChat.categories() do
                    categories[category.id] = 0
                end
                for _, phrase in phrases do
                    TestRunner.truthy(
                        categories[phrase.category] ~= nil,
                        phrase.id .. " names a category the wheel has no tab for"
                    )
                    categories[phrase.category] += 1
                    TestRunner.truthy(
                        QuickChat.pingKind(phrase.ping) ~= nil,
                        phrase.id .. " names a ping kind that does not exist"
                    )
                    TestRunner.truthy(#phrase.text > 0, phrase.id .. " says nothing")
                end
                -- Even categories, so no tab is a page of one and none is a
                -- page that scrolls.
                for id, count in categories do
                    TestRunner.equal(count, 6, id .. " does not hold six phrases")
                end
            end,
        },
        {
            --[[
                The reachability case. The wheel is the only way in, so walking
                it must visit every phrase exactly once -- a phrase the wheel
                skips is a phrase nobody can ever say, and the equip panel
                proves that ships silently.
            ]]
            name = "the wheel reaches every phrase exactly once",
            run = function()
                local seen: { [string]: number } = {}
                local total = 0
                for _, group in QuickChat.wheel() do
                    TestRunner.truthy(#group.label > 0, group.category .. " has no tab label")
                    for _, phrase in group.phrases do
                        TestRunner.equal(
                            phrase.category,
                            group.category,
                            phrase.id .. " is drawn under the wrong tab"
                        )
                        seen[phrase.id] = (seen[phrase.id] or 0) + 1
                        total += 1
                    end
                end
                TestRunner.equal(total, #QuickChat.list())
                for _, phrase in QuickChat.list() do
                    TestRunner.equal(seen[phrase.id], 1, phrase.id .. " is not on the wheel once")
                end
            end,
        },
        {
            name = "every ping kind can be drawn",
            run = function()
                for _, kind in QuickChat.pingKinds() do
                    TestRunner.truthy(#kind.glyph > 0, kind.id .. " has no glyph")
                    TestRunner.truthy(kind.seconds > 0, kind.id .. " expires instantly")
                    TestRunner.equal(#kind.colour, 3, kind.id .. " has no colour")
                    for _, channel in kind.colour do
                        TestRunner.truthy(
                            channel >= 0 and channel <= 255,
                            kind.id .. " has a colour channel outside 0-255"
                        )
                    end
                end
            end,
        },
        {
            --[[
                A courtesy marks nothing even when the sender's position is
                known, and everything else marks the position it was given.
                This is the rule the six polite phrases exist under: six people
                being polite must not put six cards over the town.
            ]]
            name = "a courtesy is spoken and a callout is placed",
            run = function()
                local polite = callOf("qc_thank_you", 7, 100, 1)
                TestRunner.equal(polite.marks, false)
                TestRunner.equal(polite.x, nil)
                local shout = callOf("qc_enemy_here", 7, 100, 2)
                TestRunner.equal(shout.marks, true)
                TestRunner.equal(shout.x, 10)
                TestRunner.equal(shout.z, 30)
            end,
        },
        {
            name = "a call with no position marks nothing",
            run = function()
                local phrase = assert(QuickChat.byId("qc_enemy_here"))
                local call = QuickChat.call(phrase, 7, "Traveller", 100, 1, nil, nil, nil)
                TestRunner.equal(call.marks, false)
                TestRunner.equal(call.x, nil)
            end,
        },
        {
            name = "an expired call is heard by nobody",
            run = function()
                local calls = { callOf("qc_enemy_here", 7, 100, 1) }
                TestRunner.equal(#QuickChat.visibleCalls(calls, 9, nobodySuppressed, 101), 1)
                -- danger lives eight seconds
                TestRunner.equal(#QuickChat.visibleCalls(calls, 9, nobodySuppressed, 120), 0)
            end,
        },
        {
            --[[
                The gate line: a blocked player's phrases and pings do not
                reach the blocker. Both lists, because a suppression rule that
                covers the log and not the marker is a suppression rule that
                does nothing -- the marker is the loud half.
            ]]
            name = "a blocked sender reaches the blocker through neither list",
            run = function()
                local calls = {
                    callOf("qc_enemy_here", 7, 100, 1),
                    callOf("qc_thank_you", 8, 100, 2),
                }
                local function blocksSeven(fromUserId: number): boolean
                    return fromUserId == 7
                end
                local visible = QuickChat.visibleCalls(calls, 9, blocksSeven, 101)
                TestRunner.equal(#visible, 1)
                TestRunner.equal(visible[1].fromUserId, 8)
                TestRunner.equal(
                    #QuickChat.visiblePings(calls, 9, blocksSeven, 101, 10, 2, 30, 400),
                    0
                )
            end,
        },
        {
            -- A player always hears themselves. A press that appears to do
            -- nothing is a press a player makes again.
            name = "a sender always hears their own call",
            run = function()
                local calls = { callOf("qc_enemy_here", 7, 100, 1) }
                local function blocksEverybody(_fromUserId: number): boolean
                    return true
                end
                TestRunner.equal(#QuickChat.visibleCalls(calls, 7, blocksEverybody, 101), 1)
            end,
        },
        {
            name = "a marker out of range is heard and not drawn",
            run = function()
                local calls = { callOf("qc_harvest_here", 7, 100, 1) }
                TestRunner.equal(#QuickChat.visibleCalls(calls, 9, nobodySuppressed, 101), 1)
                TestRunner.equal(
                    #QuickChat.visiblePings(calls, 9, nobodySuppressed, 101, 10, 2, 30, 400),
                    1
                )
                -- 900 studs down the z axis, well past the radius
                TestRunner.equal(
                    #QuickChat.visiblePings(calls, 9, nobodySuppressed, 101, 10, 2, 930, 400),
                    0
                )
                -- A recipient with no character has no origin to measure from,
                -- so range cannot refuse them anything.
                TestRunner.equal(
                    #QuickChat.visiblePings(calls, 9, nobodySuppressed, 101, nil, nil, nil, 400),
                    1
                )
            end,
        },
        {
            name = "a courtesy is never in the ping list",
            run = function()
                local calls = { callOf("qc_yes", 7, 100, 1) }
                TestRunner.equal(#QuickChat.visibleCalls(calls, 9, nobodySuppressed, 101), 1)
                TestRunner.equal(
                    #QuickChat.visiblePings(calls, 9, nobodySuppressed, 101, 10, 2, 30, 400),
                    0
                )
            end,
        },
        {
            name = "an unknown or oversized phrase id resolves to nothing",
            run = function()
                TestRunner.equal(QuickChat.byId("qc_not_a_phrase"), nil)
                TestRunner.equal(QuickChat.byId(""), nil)
                TestRunner.equal(QuickChat.byId(42), nil)
                TestRunner.equal(QuickChat.byId(string.rep("q", 200)), nil)
            end,
        },
        {
            --[[
                The payload carries a phrase id and nothing else. A second
                field is how a ping would become forgeable -- name a position
                and the sender is no longer where the marker is -- and the
                one-extra-field wall is what #219 was found against.
            ]]
            name = "the payload carries one field and it is the phrase id",
            run = function()
                local kind = RuntimeIds.Actions.QuickChat
                TestRunner.equal(ActionPayloadContract.extraField(RuntimeIds, kind), "phraseId")
                TestRunner.equal(
                    ActionPayloadContract.isValidForKind(RuntimeIds, {
                        schemaVersion = 1,
                        kind = kind,
                        phraseId = "qc_enemy_here",
                    }),
                    true
                )
                for _, smuggled in { "x", "y", "z", "targetUserId", "text" } do
                    local payload: { [string]: any } = {
                        schemaVersion = 1,
                        kind = kind,
                        phraseId = "qc_enemy_here",
                    }
                    payload[smuggled] = 1
                    TestRunner.equal(
                        ActionPayloadContract.isValidForKind(RuntimeIds, payload),
                        false,
                        "a quick chat payload accepted " .. smuggled
                    )
                end
            end,
        },
        {
            --[[
                No player-authored string passes through this game, asserted
                over the source rather than argued for in a document.

                The names checked are the ones such a path would have to use:
                the filter entry points (a game only filters text it is
                carrying), a TextBox (a client only builds one to collect a
                string), a TextChannel and SendAsync (the way a message is put
                into chat), and SetCore (the way one is put on somebody's
                screen). None of them appear, and there is no way to add quick
                chat's twenty-fifth phrase that would make one appear.

                Roblox's own chat is a separate matter and deliberately not
                what this case is about: it is the platform's channel with the
                platform's filtering and moderation behind it, and whether it
                is on is a Creator Dashboard setting rather than a fact about
                this repository. It belongs in the safety review's inventory,
                not in a source check. The one place TextChatService is
                touched at all is AdminService, which registers slash commands
                for the two roster user IDs -- that is the game reading a
                command, not carrying a message, and it is pinned to that one
                file so it cannot spread.
            ]]
            name = "no player-authored string passes through the game",
            run = function()
                local paths: { string } = {}
                listFiles("src/server", paths)
                listFiles("src/client", paths)
                listFiles("src/shared", paths)
                for _, path in paths do
                    local source = fs.readFile(path)
                    for _, forbidden in
                        {
                            "FilterStringAsync",
                            "FilterStringForBroadcast",
                            'Instance.new("TextBox")',
                            'Instance.new("TextChannel")',
                            ":SendAsync(",
                            ":SetCore(",
                        }
                    do
                        TestRunner.equal(
                            string.find(source, forbidden, 1, true),
                            nil,
                            path .. " opens a free-text path: " .. forbidden
                        )
                    end
                    if
                        string.find(source, "TextChatService", 1, true) ~= nil
                        and path ~= "src/server/Services/AdminService.luau"
                    then
                        error(path .. " reaches into TextChatService")
                    end
                end
                --[[
                    The block list is *called* in exactly one place. Matched
                    with its open paren so the prose explaining it does not
                    count as a second caller. A second real caller is a second
                    home for the suppression rule, and the rule with two homes
                    is the one that stops being true in one of them.
                ]]
                local uses = 0
                for _ in
                    string.gmatch(
                        readSide("src/server") .. "\n" .. readSide("src/client"),
                        "Chat:CanUsersChatAsync%("
                    )
                do
                    uses += 1
                end
                TestRunner.equal(uses, 1, "the block list is consulted in more than one place")
            end,
        },
        {
            --[[
                The wiring half. A wheel drawn from a hardcoded list would pass
                every case above and still leave phrases unreachable, so this
                reads the client for the walk itself: the panel is built from
                QuickChat.wheel(), the press carries the button's own stamped
                phrase id, and no phrase id is written into the client by hand.
            ]]
            name = "the client draws the wheel from the catalog and names no phrase itself",
            run = function()
                local client = readSide("src/client")
                TestRunner.truthy(
                    string.find(client, "QuickChat.wheel()", 1, true) ~= nil,
                    "the wheel is not built from the catalog"
                )
                TestRunner.truthy(
                    string.find(client, "hud:setQuickChatHandler", 1, true) ~= nil,
                    "the phrase buttons are never wired to the remote"
                )
                for _, phrase in QuickChat.list() do
                    TestRunner.equal(
                        string.find(client, string.format("%q", phrase.id), 1, true),
                        nil,
                        "the client hardcodes the phrase id " .. phrase.id
                    )
                end
            end,
        },
        {
            -- The budget is config rather than a constant in a service,
            -- because M13 tunes it and a tuning pass must not be a rebuild.
            name = "the channel has a budget and a reach",
            run = function()
                TestRunner.truthy(Config.QuickChatRatePerSecond > 0)
                TestRunner.truthy(Config.QuickChatBurst >= 1)
                TestRunner.truthy(Config.QuickChatPingRadius > 0)
                TestRunner.equal(Config.FeatureFlags.quick_chat_enabled, true)
            end,
        },
    },
}
