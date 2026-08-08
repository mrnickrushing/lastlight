--!strict

--[[
    The safety review's document and the game's own source, held against each
    other.

    `docs/SOCIAL_SAFETY_REVIEW.md` is the artifact a privacy and abuse review
    reads: every way one player reaches another, what bounds it, and what a
    block does to it. A document like that is worth exactly as much as its
    agreement with the code, and documents drift -- this project's whole
    handoff exists because of what goes missing between sessions.

    So the agreement is a check rather than a habit. Every channel in the table
    that the doc marks as this game's own has a `SAFETY-CHANNEL: <id>` marker
    at the place in `src` that bounds it, and every marker in `src` has a row.
    **Neither list may grow alone**: adding a channel to the game without
    writing it down fails here, and writing one down that nothing implements
    fails here too.

    Channels the doc marks `platform` are Roblox's own -- its text chat, its
    report menu -- and have no marker, because this repository neither
    implements nor extends them. They are in the table because a review that
    only reads what this game built would miss the largest surface in the
    experience.
]]

local fs = require("@lune/fs")
local TestRunner = require("../TestRunner")

local DOC = "docs/SOCIAL_SAFETY_REVIEW.md"

local function readTree(root: string, files: { { path: string, source: string } })
    for _, entry in fs.readDir(root) do
        local path = root .. "/" .. entry
        if fs.isDir(path) then
            readTree(path, files)
        elseif string.sub(entry, -5) == ".luau" then
            table.insert(files, { path = path, source = fs.readFile(path) })
        end
    end
end

--[[
    Every marker in the source, with the file it sits in. The file matters for
    the failure message: "quick_chat_ping is not in the document" is only
    actionable if you know where it came from.
]]
local function markersInSource(): { [string]: string }
    local files: { { path: string, source: string } } = {}
    readTree("src", files)
    local found: { [string]: string } = {}
    for _, file in files do
        for id in string.gmatch(file.source, "SAFETY%-CHANNEL: ([a-z_]+)") do
            found[id] = file.path
        end
    end
    return found
end

--[[
    Every row of the channel table, read as `| id | kind | ...`.

    Parsed rather than hand-listed here for the reason the whole suite exists:
    a copy of the table inside the spec would be a third list to keep in
    agreement, and three lists drift faster than two.
]]
local function rowsInDoc(): { [string]: string }
    local doc = fs.readFile(DOC)
    local rows: { [string]: string } = {}
    for id, kind in string.gmatch(doc, "\n|%s*`([a-z_]+)`%s*|%s*([a-z]+)%s*|") do
        -- A duplicated id would let one row's claim be checked while another
        -- row silently says something else about the same channel.
        assert(rows[id] == nil, "the review lists " .. id .. " twice")
        rows[id] = kind
    end
    return rows
end

return {
    name = "SocialSafety",
    cases = {
        {
            name = "the review document exists and names its channels",
            run = function()
                TestRunner.truthy(fs.isFile(DOC), "the safety review document is missing")
                local rows = rowsInDoc()
                local count = 0
                for id, kind in rows do
                    count += 1
                    TestRunner.truthy(
                        kind == "game" or kind == "platform",
                        id .. " has a kind that is neither game nor platform: " .. kind
                    )
                end
                TestRunner.truthy(count >= 8, "the channel table looks truncated: " .. count)
            end,
        },
        {
            -- The direction that catches a channel being added to the game and
            -- never written down, which is how a review reads a list that is
            -- quietly short.
            name = "every channel the game implements appears in the document",
            run = function()
                local rows = rowsInDoc()
                local missing: { string } = {}
                for id, path in markersInSource() do
                    if rows[id] == nil then
                        table.insert(missing, string.format("%s (%s)", id, path))
                    elseif rows[id] ~= "game" then
                        table.insert(
                            missing,
                            string.format(
                                "%s is marked %s but is implemented in %s",
                                id,
                                rows[id],
                                path
                            )
                        )
                    end
                end
                TestRunner.truthy(
                    #missing == 0,
                    "channels in the source with no row in the review: "
                        .. table.concat(missing, ", ")
                )
            end,
        },
        {
            -- And the direction that catches a document claiming a bound that
            -- nothing in the code applies, which is worse than a short list:
            -- it is a review passing on a promise.
            name = "every channel the document claims is bounded in the source",
            run = function()
                local markers = markersInSource()
                local unimplemented: { string } = {}
                for id, kind in rowsInDoc() do
                    if kind == "game" and markers[id] == nil then
                        table.insert(unimplemented, id)
                    end
                end
                TestRunner.truthy(
                    #unimplemented == 0,
                    "channels the review claims that nothing in src marks: "
                        .. table.concat(unimplemented, ", ")
                )
            end,
        },
        {
            --[[
                The two channels a reviewer will look for first, pinned by name
                so a refactor cannot drop them from the table and stay green by
                also dropping their markers. Both directions of the check above
                pass on an empty list; these are the rows that must exist.
            ]]
            name = "the block-suppressed channels are named, and so is the platform's own",
            run = function()
                local rows = rowsInDoc()
                for _, id in { "quick_chat_phrase", "quick_chat_ping", "party_invite" } do
                    TestRunner.equal(rows[id], "game", id .. " is missing from the review")
                end
                for _, id in { "platform_chat", "platform_report" } do
                    TestRunner.equal(
                        rows[id],
                        "platform",
                        id .. " is missing from the review, or is claimed as this game's"
                    )
                end
            end,
        },
        {
            --[[
                Reporting is the platform's, deliberately, and the document has
                to say so. A game-authored report button either duplicates
                Roblox's pipeline into an inbox nobody staffs, or looks like it
                did something it did not -- and a reviewer needs that to be a
                recorded decision rather than an omission they have to guess at.
            ]]
            name = "the document records that reporting and blocking are the platform's",
            run = function()
                local doc = fs.readFile(DOC)
                TestRunner.truthy(
                    string.find(doc, "does not implement a report flow", 1, true) ~= nil,
                    "the review does not say where reporting goes"
                )
                TestRunner.truthy(
                    string.find(doc, "Roblox's block list is the block list", 1, true) ~= nil,
                    "the review does not say whose block list is authoritative"
                )
            end,
        },
        {
            --[[
                The claim the whole document rests on, checked here as well as
                in QuickChat.spec, because this is the file a reviewer reads and
                a claim that is only true in another suite is a claim that can
                be broken by deleting that suite.
            ]]
            name = "one block reader, and no second caller of the platform",
            run = function()
                local files: { { path: string, source: string } } = {}
                readTree("src", files)
                local callers: { string } = {}
                for _, file in files do
                    if string.find(file.source, "CanUsersChatAsync(", 1, true) ~= nil then
                        table.insert(callers, file.path)
                    end
                end
                TestRunner.equal(
                    #callers,
                    1,
                    "the block list is read in more than one file: " .. table.concat(callers, ", ")
                )
                TestRunner.equal(callers[1], "src/server/Services/SocialService.luau")
            end,
        },
    },
}
