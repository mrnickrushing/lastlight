--!strict

--[[
    The tuning decisions and the telemetry that could produce them, held
    against each other.

    `docs/BETA_TUNING.md` names the five things Milestone 13 tunes and the
    number each is decided on. The failure this suite exists for is the one
    `GateMetrics.spec` was written against and it applies unchanged here: **a
    dashboard reading zero and a dashboard reading nothing look identical to
    the person making the decision.** A tuning pass held over a panel that has
    always been empty concludes that nobody is failing the third night.

    So the agreement is a check, in both directions and in three layers:

      * every decision in the document names an event with an emitter in
        `AnalyticsService`;
      * that emitter has a call site, marked `TUNING-METRIC: <id>` where the
        fact is produced;
      * every marker in `src` is a decision the document lists.

    And one rule this suite has that the gate suite does not: **the difficulty
    checkpoint has to be marked in more than one place.** A cliff is a
    comparison between two checkpoints, so a single call site is a metric that
    cannot answer its own question no matter how correct each reading is.
]]

local fs = require("@lune/fs")
local TestRunner = require("../TestRunner")

local DOC = "docs/BETA_TUNING.md"
local EMITTER_FILE = "src/server/Services/AnalyticsService.luau"

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

--[[
    Every decision row, read out of the document rather than copied here. A
    copy would be a third list, and three lists drift faster than two.
]]
local function rowsInDoc(): { { decision: string, event: string } }
    local doc = fs.readFile(DOC)
    local rows: { { decision: string, event: string } } = {}
    local inTable = false
    for line in string.gmatch(doc, "[^\n]+") do
        if string.sub(line, 1, 1) ~= "|" then
            inTable = false
        elseif string.find(line, "Emitted by", 1, true) ~= nil then
            inTable = true
        elseif inTable and string.find(line, "^|%s*%-") == nil then
            local cells: { string } = {}
            for cell in string.gmatch(line, "|([^|]*)") do
                table.insert(cells, trim(cell))
            end
            if #cells >= 4 then
                local event = string.match(cells[3], "^`([a-z_]+)`$")
                if event ~= nil then
                    table.insert(rows, { decision = cells[1], event = event })
                end
            end
        end
    end
    return rows
end

-- Which AnalyticsService function emits which event, derived from the file
-- rather than declared beside it: a declared mapping passes on the day
-- somebody renames the logged string and leaves the table alone.
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

local MARKER_BLOCK = 900

local function markersInSource(): { { id: string, path: string, block: string } }
    local files: { { path: string, source: string } } = {}
    readTree("src", files)
    local found: { { id: string, path: string, block: string } } = {}
    for _, file in files do
        local searchFrom = 1
        while true do
            local from, to, id = string.find(file.source, "TUNING%-METRIC: ([a-z_]+)", searchFrom)
            if from == nil or to == nil or id == nil then
                break
            end
            table.insert(found, {
                id = id,
                path = file.path,
                block = string.sub(file.source, to, to + MARKER_BLOCK),
            })
            searchFrom = to + 1
        end
    end
    return found
end

local function markedIds(): { [string]: { string } }
    local byId: { [string]: { string } } = {}
    for _, marker in markersInSource() do
        local paths = byId[marker.id]
        if paths == nil then
            paths = {}
            byId[marker.id] = paths
        end
        if table.find(paths, marker.path) == nil then
            table.insert(paths, marker.path)
        end
    end
    return byId
end

return {
    name = "TuningMetrics",
    cases = {
        {
            name = "the roadmap's five tuning decisions each have a row",
            run = function()
                TestRunner.truthy(fs.isFile(DOC), "the tuning document is missing")
                local rows = rowsInDoc()
                TestRunner.equal(#rows, 5, "expected one row per tuning decision")

                --[[
                    Held against the roadmap's own words rather than against a
                    list here, because the sentence in the roadmap is what the
                    milestone is judged on and a paraphrase in this file could
                    drift away from it without anything failing.
                ]]
                local roadmap = fs.readFile("docs/PRODUCTION_ROADMAP.md")
                TestRunner.truthy(
                    string.find(
                        roadmap,
                        "tune first session, first night, difficulty cliffs, group scaling, and repetition",
                        1,
                        true
                    ) ~= nil,
                    "the roadmap's tuning sentence has changed; the table has to change with it"
                )
            end,
        },
        {
            name = "every tuning decision names an event with an emitter",
            run = function()
                local emitters = emittersInService()
                local missing: { string } = {}
                for _, row in rowsInDoc() do
                    if emitters[row.event] == nil then
                        table.insert(missing, row.event .. " (" .. row.decision .. ")")
                    end
                end
                table.sort(missing)
                TestRunner.truthy(
                    #missing == 0,
                    "decisions whose event nothing emits: " .. table.concat(missing, "; ")
                )
            end,
        },
        {
            --[[
                An emitter is not a measurement. A function that logs a perfect
                event and is called from nowhere is the empty panel this suite
                exists to distinguish from a decision that has been measured --
                and the call is looked for in the code the marker introduces
                rather than anywhere in its file, because a marker left behind
                after its call moved is the same lie as a document naming an
                emitter that does not exist.
            ]]
            name = "every tuning emitter has a marked call site that calls it",
            run = function()
                local emitters = emittersInService()
                local marked = markedIds()
                local problems: { string } = {}

                for _, row in rowsInDoc() do
                    if marked[row.event] == nil then
                        table.insert(problems, row.event .. " has no TUNING-METRIC marker in src")
                    end
                end
                for _, marker in markersInSource() do
                    local method = emitters[marker.id]
                    if method == nil then
                        continue
                    end
                    if string.find(marker.block, ":" .. method .. "(", 1, true) == nil then
                        table.insert(
                            problems,
                            string.format(
                                "the %s marker in %s introduces no call to :%s()",
                                marker.id,
                                marker.path,
                                method
                            )
                        )
                    end
                end
                table.sort(problems)
                TestRunner.truthy(#problems == 0, table.concat(problems, "; "))
            end,
        },
        {
            name = "every marked tuning metric in the source is a decision the document names",
            run = function()
                local known: { [string]: boolean } = {}
                for _, row in rowsInDoc() do
                    known[row.event] = true
                end
                local orphans: { string } = {}
                for id, paths in markedIds() do
                    if not known[id] then
                        table.insert(orphans, id .. " (" .. table.concat(paths, ", ") .. ")")
                    end
                end
                table.sort(orphans)
                TestRunner.truthy(
                    #orphans == 0,
                    "metrics marked in src with no decision in the document: "
                        .. table.concat(orphans, "; ")
                )
            end,
        },
        {
            --[[
                The rule this suite has that the gate suite does not. A cliff
                is the difference between one checkpoint and the next, so a
                single call site produces a metric that cannot answer its own
                question however correct each reading is -- and one call site
                is exactly what a first pass at this leaves behind.
            ]]
            name = "the difficulty checkpoint is marked in more than one place",
            run = function()
                local paths = markedIds()["difficulty_checkpoint"]
                TestRunner.truthy(paths ~= nil, "nothing emits a difficulty checkpoint")
                TestRunner.truthy(
                    #(paths :: { string }) >= 3,
                    "a cliff is a comparison: found checkpoints in only "
                        .. tostring(#(paths :: { string }))
                        .. " place(s)"
                )
            end,
        },
        {
            --[[
                No tuning metric may come from a client. The measurement
                contract in RELEASE_GATES.md says operational numbers use
                authoritative server events, and a tuning number is worse to
                get from a client than a gate number is: nobody audits it, and
                a difficulty reading a client supplies is a difficulty a client
                decides.
            ]]
            name = "no tuning metric is emitted from client or shared code",
            run = function()
                local offenders: { string } = {}
                for _, marker in markersInSource() do
                    if
                        string.find(marker.path, "src/client", 1, true) ~= nil
                        or string.find(marker.path, "src/shared", 1, true) ~= nil
                    then
                        table.insert(offenders, marker.id .. " in " .. marker.path)
                    end
                end
                table.sort(offenders)
                TestRunner.truthy(#offenders == 0, table.concat(offenders, "; "))
            end,
        },
        {
            --[[
                The counters these events read live on the analytics service
                and are dropped when a player leaves. A table that is not in
                `clear` is a leak, and it is a leak the soak's `player_residue`
                metric now watches -- so the two lists have to be the same one.
            ]]
            name = "every per-player table the tuning counters keep is cleared and counted",
            run = function()
                local source = fs.readFile(EMITTER_FILE)
                local declared: { string } = {}
                local block = string.match(source, "AnalyticsService%.new.-\n end") or source
                for field in string.gmatch(source, "\n        (_%a[%w_]*): { %[Player%]") do
                    if table.find(declared, field) == nil then
                        table.insert(declared, field)
                    end
                end
                TestRunner.truthy(#declared >= 9, "expected the player-keyed tables to be declared")
                TestRunner.truthy(#block > 0)

                local clearBody = string.match(source, "function AnalyticsService%.clear.-\nend")
                local residueBody =
                    string.match(source, "function AnalyticsService%.playerResidue.-\nend")
                TestRunner.truthy(clearBody ~= nil, "AnalyticsService.clear is missing")
                TestRunner.truthy(residueBody ~= nil, "AnalyticsService.playerResidue is missing")

                local missing: { string } = {}
                for _, field in declared do
                    if string.find(clearBody :: string, field, 1, true) == nil then
                        table.insert(missing, field .. " is never cleared")
                    end
                    if string.find(residueBody :: string, field, 1, true) == nil then
                        table.insert(missing, field .. " is not counted as residue")
                    end
                end
                table.sort(missing)
                TestRunner.truthy(#missing == 0, table.concat(missing, "; "))
            end,
        },
    },
}
