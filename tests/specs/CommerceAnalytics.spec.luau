--!strict

--[[
    The commerce taxonomy and the code, held against each other.

    MONETIZATION_LIVEOPS_ANALYTICS names six commerce events, and the store
    safety section says why they are six rather than one: "purchase analytics
    separates prompt, platform completion, receipt grant, and equip/use". That
    separation is the only way a support answer can be given. A player who says
    *I bought it and I do not have it* is asking which of four things happened,
    and one merged `purchase` event answers none of them -- it cannot tell a
    prompt nobody completed from a receipt that never resolved, and those two
    have opposite answers.

    So the check is `GateMetrics.spec`'s three layers pointed at commerce:

      * every event the taxonomy lists has an emitter in `AnalyticsService`
        that logs that exact name;
      * that emitter has a call site marked `COMMERCE-EVENT: <name>` where the
        fact is produced, because an emitter nobody calls is a dashboard
        reading zero and a dashboard reading zero is indistinguishable from a
        store nobody opened;
      * and every marker in `src` is an event the taxonomy lists, so neither
        list may grow alone.

    Writing it caught the thing a spec like this is for: the taxonomy said
    `purchase_platform_result` and the code emitted `purchase_prompt_finished`.
    Both existed, both were called, both were documented -- in two documents
    that named different events. A dashboard built from the taxonomy would have
    had one empty panel and no way to tell it apart from a quiet week.

    The fourth rule is a boundary rather than a count: **no commerce event may
    be emitted from client code.** A store view a client reports is a store
    view a client decides, and the measurement contract already forbids it in
    prose.
]]

local fs = require("@lune/fs")
local TestRunner = require("../TestRunner")

local DOC = "docs/MONETIZATION_LIVEOPS_ANALYTICS.md"
local EMITTER_FILE = "src/server/Services/AnalyticsService.luau"
local MARKER = "COMMERCE%-EVENT:%s*([%a_]+)"

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
    The Commerce list out of the taxonomy, read rather than copied.

    Parsed from the document because a copy in this file would be a third list
    to keep in agreement, and three lists drift faster than two -- the same
    reasoning GateMetrics.spec gives for parsing RELEASE_GATES.md.
]]
local function taxonomyEvents(): { string }
    local doc = fs.readFile(DOC)
    local events: { string } = {}
    local inSection = false
    for line in string.gmatch(doc, "[^\n]+") do
        if string.match(line, "^###%s") ~= nil then
            inSection = string.find(line, "Commerce", 1, true) ~= nil
        elseif inSection then
            local event = string.match(line, "^%-%s*`([%a_]+)`%s*$")
            if event ~= nil then
                table.insert(events, event)
            end
        end
    end
    return events
end

-- Which AnalyticsService function logs which event, derived from the file so a
-- renamed string cannot pass by leaving a table alone.
local function emittersInService(): { [string]: string }
    local source = fs.readFile(EMITTER_FILE)
    local starts: { { name: string, at: number } } = {}
    local searchFrom = 1
    while true do
        local from, to, name =
            string.find(source, "function AnalyticsService%.([%w_]+)%(", searchFrom)
        if from == nil or to == nil or name == nil then
            break
        end
        table.insert(starts, { name = name, at = to })
        searchFrom = to + 1
    end

    local byEvent: { [string]: string } = {}
    for index, entry in starts do
        local stop = if starts[index + 1] ~= nil then starts[index + 1].at else #source
        local body = string.sub(source, entry.at, stop)
        for event in string.gmatch(body, '_logger:%a+%("([%a_]+)"') do
            if byEvent[event] == nil then
                byEvent[event] = entry.name
            end
        end
    end
    return byEvent
end

local function markedCallSites(): { [string]: { string } }
    local files: { { path: string, source: string } } = {}
    readTree("src", files)
    local sites: { [string]: { string } } = {}
    for _, file in files do
        for event in string.gmatch(file.source, MARKER) do
            if sites[event] == nil then
                sites[event] = {}
            end
            table.insert(sites[event], file.path)
        end
    end
    return sites
end

return {
    name = "CommerceAnalytics",
    cases = {
        {
            name = "every commerce event the taxonomy names has an emitter that logs that name",
            run = function()
                local events = taxonomyEvents()
                TestRunner.truthy(
                    #events >= 6,
                    string.format(
                        "the taxonomy's Commerce section parsed as %d events, which means the "
                            .. "parser stopped matching the document",
                        #events
                    )
                )
                local emitters = emittersInService()
                local missing: { string } = {}
                for _, event in events do
                    if emitters[event] == nil then
                        table.insert(missing, event)
                    end
                end
                TestRunner.truthy(
                    #missing == 0,
                    "commerce events the taxonomy names with nothing emitting them: "
                        .. table.concat(missing, ", ")
                )
            end,
        },
        {
            --[[
                The layer that matters most, and the one a review cannot do by
                eye. Wave F added all five emitters and two of them had no call
                site for a whole milestone wave; nothing failed, because an
                emitter that is never called looks exactly like a store nobody
                opened.
            ]]
            name = "every commerce emitter is actually called, where the fact happens",
            run = function()
                local sites = markedCallSites()
                local missing: { string } = {}
                for _, event in taxonomyEvents() do
                    local marked = sites[event]
                    if marked == nil or #marked == 0 then
                        table.insert(missing, event)
                    end
                end
                TestRunner.truthy(
                    #missing == 0,
                    "commerce events with an emitter and no marked call site: "
                        .. table.concat(missing, ", ")
                )
            end,
        },
        {
            name = "no marker names an event the taxonomy does not list",
            run = function()
                local listed: { [string]: boolean } = {}
                for _, event in taxonomyEvents() do
                    listed[event] = true
                end
                local strays: { string } = {}
                for event, paths in markedCallSites() do
                    if not listed[event] then
                        table.insert(strays, event .. " (" .. paths[1] .. ")")
                    end
                end
                TestRunner.truthy(
                    #strays == 0,
                    "commerce markers naming events the taxonomy does not list: "
                        .. table.concat(strays, ", ")
                )
            end,
        },
        {
            --[[
                A store view a client reports is a store view a client decides,
                and the same is true of every other event here: a purchase
                prompt, a receipt and an equip are all facts about what the
                server did. Checked as a property of the source rather than
                left as prose in the measurement contract.
            ]]
            name = "no commerce event is emitted from client or shared code",
            run = function()
                local offenders: { string } = {}
                for _, root in { "src/client", "src/shared" } do
                    local files: { { path: string, source: string } } = {}
                    readTree(root, files)
                    for _, file in files do
                        for event in string.gmatch(file.source, MARKER) do
                            table.insert(offenders, file.path .. " (" .. event .. ")")
                        end
                    end
                end
                TestRunner.truthy(
                    #offenders == 0,
                    "commerce events emitted outside the server: " .. table.concat(offenders, ", ")
                )
            end,
        },
        {
            --[[
                The support runbook has to exist before anything is sold --
                MONETIZATION_LIVEOPS_ANALYTICS says so in its store-safety
                list, and Milestone 11's deliverables repeat it. A document
                that exists and answers none of the four questions a support
                request actually arrives as would satisfy the letter of that
                and none of it, so the headings are checked too.
            ]]
            name = "the support runbook exists and answers the questions support arrives as",
            run = function()
                local runbook = fs.readFile("docs/COMMERCE_SUPPORT.md")
                for _, required in
                    {
                        "Refunds",
                        "Removing a product from sale",
                        "I bought it and I do not have it",
                        "purchase_loss",
                        "receipt_result",
                    }
                do
                    TestRunner.truthy(
                        string.find(runbook, required, 1, true) ~= nil,
                        "COMMERCE_SUPPORT.md never mentions " .. required
                    )
                end
            end,
        },
    },
}
