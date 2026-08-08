--!strict

--[[
    The release gates and the telemetry that could produce them, held against
    each other.

    `docs/RELEASE_GATES.md` is the document a promotion decision is made
    against. Every threshold in it names a rate, and a rate needs a numerator
    and a denominator that something in this game actually emits. Most of them
    had neither -- and the reason that survived so long is the failure mode the
    document is least able to detect on its own: **a dashboard reading zero and
    a dashboard reading nothing look identical to the person approving a
    release.** The first says the gate passed; the second says nobody measured
    it; the release goes out either way. A gate nobody measures is a gate
    nobody can fail.

    So the agreement is a check, in both directions and in three layers:

      * every gate in the document names an event, and that event has an
        emitter in `AnalyticsService`;
      * that emitter has a call site, marked `GATE-METRIC: <id>` where the fact
        is actually produced -- because an emitter nobody calls is exactly the
        dashboard reading zero;
      * and every marker in `src` is a gate the document lists, so the two
        lists cannot grow apart.

    This is the same question `ContentCensus.spec` asks about content and the
    reachability sweep asked about benches and residents -- **a thing existing
    and a thing being reachable are different facts** -- asked about telemetry,
    where the gap is invisible by construction rather than merely easy to miss.

    Two gates name `review` instead of an event, and that is a statement rather
    than a gap: a blocker defect on the launch path is a triage decision and a
    platform-policy failure arrives through Roblox's moderation. Nothing here
    can emit either, and an event invented to stand in for one would be a gate
    passing on a number that measures something else. The count of those rows
    is pinned, so a threshold cannot be quietly downgraded into "a human will
    look at it".
]]

local fs = require("@lune/fs")
local TestRunner = require("../TestRunner")

local DOC = "docs/RELEASE_GATES.md"
local EMITTER_FILE = "src/server/Services/AnalyticsService.luau"

-- A gate whose emitter is a human reading a triage queue. Named here only so
-- the parser has a word for it; the document is where the reasoning lives.
local REVIEW = "review"

local function trim(value: string): string
    return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

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

export type Row = {
    gate: string,
    emitter: string,
}

--[[
    Every gate row in the document, read out of the tables that declare an
    emitter column.

    Parsed rather than copied into this file, for the reason the whole suite
    exists: a list here would be a third thing to keep in agreement, and three
    lists drift faster than two.
]]
local function rowsInDoc(): { Row }
    local doc = fs.readFile(DOC)
    local rows: { Row } = {}
    local inTable = false
    for line in string.gmatch(doc, "[^\n]+") do
        if string.sub(line, 1, 1) ~= "|" then
            inTable = false
        elseif string.find(line, "Emitted by", 1, true) ~= nil then
            inTable = true
        elseif inTable and string.find(line, "^|%s*%-") == nil then
            local cells: { string } = {}
            for cell in string.gmatch(line, "|([^|]*)") do
                local trimmed = trim(cell)
                if #trimmed > 0 then
                    table.insert(cells, trimmed)
                end
            end
            if #cells >= 2 then
                local last = cells[#cells]
                local emitter = string.match(last, "^`([a-z_]+)`$")
                table.insert(rows, {
                    gate = cells[1],
                    emitter = if emitter ~= nil then emitter else last,
                })
            end
        end
    end
    return rows
end

-- The distinct events the document says it reads, without the review rows.
local function emittedMetrics(): { [string]: string }
    local metrics: { [string]: string } = {}
    for _, row in rowsInDoc() do
        if row.emitter ~= REVIEW then
            metrics[row.emitter] = row.gate
        end
    end
    return metrics
end

--[[
    Which AnalyticsService function emits which event, derived from the file
    rather than declared beside it.

    A declared mapping would pass on the day somebody renamed the logged string
    and left the table alone, which is the same class of drift this suite is
    built to catch one level up.
]]
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
            -- First one wins: a function that logs twice logs its own event
            -- first and anything conditional after it.
            if byEvent[event] == nil then
                byEvent[event] = entry.name
            end
        end
    end
    return byEvent
end

-- Every `GATE-METRIC: <id>` marker in the source, with the files it sits in.
local function markersInSource(): { [string]: { string } }
    local files: { { path: string, source: string } } = {}
    readTree("src", files)
    local found: { [string]: { string } } = {}
    for _, file in files do
        for id in string.gmatch(file.source, "GATE%-METRIC: ([a-z_]+)") do
            local paths = found[id]
            if paths == nil then
                paths = {}
                found[id] = paths
            end
            if table.find(paths, file.path) == nil then
                table.insert(paths, file.path)
            end
        end
    end
    return found
end

return {
    name = "GateMetrics",
    cases = {
        {
            name = "the gate document parses and every gate declares who emits it",
            run = function()
                TestRunner.truthy(fs.isFile(DOC), "the release gate document is missing")
                local rows = rowsInDoc()
                TestRunner.truthy(
                    #rows >= 15,
                    "the gate tables look truncated: " .. tostring(#rows) .. " rows"
                )
                local malformed: { string } = {}
                for _, row in rows do
                    if row.emitter ~= REVIEW and string.match(row.emitter, "^[a-z_]+$") == nil then
                        table.insert(malformed, row.gate .. " -> " .. row.emitter)
                    end
                end
                TestRunner.truthy(
                    #malformed == 0,
                    "gates whose emitter cell is neither an event nor review: "
                        .. table.concat(malformed, "; ")
                )
            end,
        },
        {
            --[[
                The direction that catches a threshold written down with
                nothing behind it, which is the state most of this document was
                in: the numbers were agreed, the dashboards were named, and
                four of them could only ever have read zero.
            ]]
            name = "every gate the document names has an emitter in AnalyticsService",
            run = function()
                local emitters = emittersInService()
                local missing: { string } = {}
                for metric, gate in emittedMetrics() do
                    if emitters[metric] == nil then
                        table.insert(missing, metric .. " (" .. gate .. ")")
                    end
                end
                table.sort(missing)
                TestRunner.truthy(
                    #missing == 0,
                    "gates whose event nothing emits: " .. table.concat(missing, "; ")
                )
            end,
        },
        {
            --[[
                An emitter is not a measurement. A function that logs a perfect
                event and is called from nowhere produces exactly the dashboard
                this suite exists to distinguish from a passing gate, so the
                call site is checked as well -- and checked where the fact is
                produced, not merely somewhere in the file.
            ]]
            name = "every gate emitter has a marked call site that calls it",
            run = function()
                local emitters = emittersInService()
                local markers = markersInSource()
                local files: { { path: string, source: string } } = {}
                readTree("src", files)
                local sourceOf: { [string]: string } = {}
                for _, file in files do
                    sourceOf[file.path] = file.source
                end

                local problems: { string } = {}
                for metric in emittedMetrics() do
                    local paths = markers[metric]
                    if paths == nil then
                        table.insert(problems, metric .. " has no GATE-METRIC marker in src")
                        continue
                    end
                    local method = emitters[metric]
                    if method == nil then
                        continue
                    end
                    for _, path in paths do
                        if
                            string.find(sourceOf[path] or "", ":" .. method .. "(", 1, true) == nil
                        then
                            table.insert(
                                problems,
                                string.format(
                                    "%s is marked in %s but that file never calls :%s()",
                                    metric,
                                    path,
                                    method
                                )
                            )
                        end
                    end
                end
                table.sort(problems)
                TestRunner.truthy(#problems == 0, table.concat(problems, "; "))
            end,
        },
        {
            --[[
                And the direction that catches an emitter added to the game and
                never written into the gates, which is the worse of the two: it
                is a measurement nobody promotes on, taken every session,
                against a threshold that was never agreed.
            ]]
            name = "every marked metric in the source is a gate the document names",
            run = function()
                local metrics = emittedMetrics()
                local orphans: { string } = {}
                for id, paths in markersInSource() do
                    if metrics[id] == nil then
                        table.insert(orphans, id .. " (" .. table.concat(paths, ", ") .. ")")
                    end
                end
                table.sort(orphans)
                TestRunner.truthy(
                    #orphans == 0,
                    "metrics marked in src with no gate in the document: "
                        .. table.concat(orphans, "; ")
                )
            end,
        },
        {
            --[[
                "Operational rates use authoritative server events. Client
                telemetry is diagnostic and cannot hide a server failure." A
                gate emitted from a client is a gate a client can pass.
            ]]
            name = "no gate is emitted from client code",
            run = function()
                local wrong: { string } = {}
                for id, paths in markersInSource() do
                    for _, path in paths do
                        if string.sub(path, 1, 11) ~= "src/server/" then
                            table.insert(wrong, id .. " in " .. path)
                        end
                    end
                end
                TestRunner.truthy(
                    #wrong == 0,
                    "gates emitted outside the server: " .. table.concat(wrong, ", ")
                )
            end,
        },
        {
            --[[
                Every reliability and comprehension gate has a second, looser
                per-segment threshold, and a threshold that can only be read
                across the whole population is exactly the one a phone-only
                failure hides behind. The session pair carries the two labels
                the slices are cut on, so the dimension travels with the data
                rather than being reconstructed later from something else.
            ]]
            name = "the session pair carries the dimensions the per-segment gates are read on",
            run = function()
                local source = fs.readFile(EMITTER_FILE)
                local sessionStart =
                    string.match(source, "function AnalyticsService%.sessionStarted%b()(.-)\nend")
                local sessionEnd =
                    string.match(source, "function AnalyticsService%.sessionEnded%b()(.-)\nend")
                TestRunner.truthy(sessionStart ~= nil, "sessionStarted is missing")
                TestRunner.truthy(sessionEnd ~= nil, "sessionEnded is missing")
                TestRunner.truthy(
                    string.find(sessionStart :: string, "platform = ", 1, true) ~= nil,
                    "interactive_session carries no platform class"
                )
                TestRunner.truthy(
                    string.find(sessionStart :: string, "daysSinceFirstSession", 1, true) ~= nil,
                    "interactive_session carries nothing D1 and D7 could be counted from"
                )
                TestRunner.truthy(
                    string.find(sessionEnd :: string, "platform = ", 1, true) ~= nil,
                    "session_ended carries no platform class"
                )
                TestRunner.truthy(
                    string.find(sessionEnd :: string, "segment = ", 1, true) ~= nil,
                    "session_ended carries no device segment"
                )
                TestRunner.truthy(
                    string.find(sessionEnd :: string, "reason = ", 1, true) ~= nil,
                    "session_ended carries no reason, so no crash can be counted"
                )
            end,
        },
        {
            --[[
                The two human gates, pinned by count.

                Both are real: a blocker defect is a triage decision and a
                policy failure comes through Roblox's moderation. What the pin
                stops is the cheap move -- a threshold nobody wants to
                instrument becoming a third one, and then a fifth, until the
                document is a list of intentions again.
            ]]
            name = "only the two human gates are left to review",
            run = function()
                local reviewed: { string } = {}
                for _, row in rowsInDoc() do
                    if row.emitter == REVIEW then
                        table.insert(reviewed, row.gate)
                    end
                end
                TestRunner.equal(
                    #reviewed,
                    2,
                    "gates left to a human: " .. table.concat(reviewed, "; ")
                )
            end,
        },
        {
            --[[
                The five zero-tolerance gates that can be emitted, named here
                rather than only counted. Both directions of the checks above
                pass on an empty document; these are the rows that must exist,
                and they are the ones whose failure stops a release outright.
            ]]
            name = "the zero-tolerance gates that can be measured are measured",
            run = function()
                local metrics = emittedMetrics()
                for _, id in
                    {
                        "generator_fallback",
                        "purchase_loss",
                        "save_loss",
                        "unauthorized_mutation",
                    }
                do
                    TestRunner.truthy(
                        metrics[id] ~= nil,
                        id .. " is no longer a gate in the document"
                    )
                end
            end,
        },
    },
}
