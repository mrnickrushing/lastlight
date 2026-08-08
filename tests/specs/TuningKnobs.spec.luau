--!strict

--[[
    The knobs a tuning pass turns, and the one thing that makes them knobs.

    Wave B gave every tuning decision a number. A number you cannot act on is
    an observation, so this is the other half: **every decision has at least
    one knob**, and every knob has exactly **one home**.

    The one-home rule is the whole of it and it is not tidiness. Ten of these
    values were locals inside four services, which meant a tuning pass was a
    code change, a rebuild and a publish -- and the cost of that is not effort,
    it is that nobody tries a second value. The failure the rule prevents is
    worse than the one it fixes, though: a service that reads
    `Config.EliteStrikeRange` and also keeps a `STRIKE_RANGE` local is a knob
    somebody turns, reads their telemetry, and concludes the number does not
    matter. That is a tuning pass producing a wrong answer rather than no
    answer, which is exactly the shape `GateMetrics.spec` was written against
    one level up.
]]

local fs = require("@lune/fs")
local Config = require("../../src/shared/Config")
local TestRunner = require("../TestRunner")

local DOC = "docs/BETA_TUNING.md"

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

-- Rows of the decision table (wave B's) and of the knob table, told apart by
-- their header rather than by position, so reordering the document is safe and
-- deleting a table is not.
local function tableRows(header: string, columns: number): { { string } }
    local doc = fs.readFile(DOC)
    local rows: { { string } } = {}
    local inTable = false
    for line in string.gmatch(doc, "[^\n]+") do
        if string.sub(line, 1, 1) ~= "|" then
            inTable = false
        elseif string.find(line, header, 1, true) ~= nil then
            inTable = true
        elseif inTable and string.find(line, "^|%s*%-") == nil then
            local cells: { string } = {}
            for cell in string.gmatch(line, "|([^|]*)") do
                table.insert(cells, trim(cell))
            end
            if #cells >= columns then
                table.insert(rows, cells)
            end
        end
    end
    return rows
end

local function knobRows(): { { decision: string, knob: string } }
    local rows: { { decision: string, knob: string } } = {}
    for _, cells in tableRows("What turning it does", 4) do
        local knob = string.match(cells[2], "^`([%a]+)`$")
        if knob ~= nil then
            table.insert(rows, { decision = cells[1], knob = knob })
        end
    end
    return rows
end

local function decisionNames(): { string }
    local names: { string } = {}
    for _, cells in tableRows("Emitted by", 4) do
        if #cells[1] > 0 then
            table.insert(names, cells[1])
        end
    end
    return names
end

return {
    name = "TuningKnobs",
    cases = {
        {
            name = "every knob in the document is a real number in Config",
            run = function()
                local rows = knobRows()
                TestRunner.truthy(#rows >= 15, "the knob table looks truncated")
                local problems: { string } = {}
                for _, row in rows do
                    local value = (Config :: any)[row.knob]
                    if type(value) ~= "number" then
                        table.insert(problems, row.knob .. " is not a number in Config")
                    elseif value ~= value or value == math.huge then
                        table.insert(problems, row.knob .. " is not finite")
                    end
                end
                table.sort(problems)
                TestRunner.truthy(#problems == 0, table.concat(problems, "; "))
            end,
        },
        {
            --[[
                The pairing, and the reason this wave exists after wave B
                rather than beside it. A decision with a number and no knob is
                a measurement nobody can act on, and it is the easy thing to
                leave behind: the event is the interesting half to build.
            ]]
            name = "every tuning decision has at least one knob",
            run = function()
                local withKnobs: { [string]: boolean } = {}
                for _, row in knobRows() do
                    withKnobs[row.decision] = true
                end
                local orphans: { string } = {}
                for _, decision in decisionNames() do
                    if not withKnobs[decision] then
                        table.insert(orphans, decision)
                    end
                end
                table.sort(orphans)
                TestRunner.truthy(
                    #orphans == 0,
                    "decisions with a number and nothing to turn: " .. table.concat(orphans, "; ")
                )
            end,
        },
        {
            --[[
                And the other direction: a knob attributed to a decision that
                does not exist is a number somebody will turn expecting to move
                a metric that is not being read.
            ]]
            name = "every knob is attributed to a decision the document names",
            run = function()
                local known: { [string]: boolean } = {}
                for _, decision in decisionNames() do
                    known[decision] = true
                end
                local orphans: { string } = {}
                for _, row in knobRows() do
                    if not known[row.decision] then
                        table.insert(orphans, row.knob .. " (" .. row.decision .. ")")
                    end
                end
                table.sort(orphans)
                TestRunner.truthy(#orphans == 0, table.concat(orphans, "; "))
            end,
        },
        {
            --[[
                A knob nothing reads is a number in a table. This is the same
                question the gate suite asks about emitters -- existing and
                being reached are different facts -- asked about configuration,
                where the gap is quieter still because a config value that is
                never read raises nothing at all.
            ]]
            name = "every knob is read somewhere outside Config",
            run = function()
                local files: { { path: string, source: string } } = {}
                readTree("src", files)
                local unread: { string } = {}
                for _, row in knobRows() do
                    local found = false
                    for _, file in files do
                        if file.path == "src/shared/Config.luau" then
                            continue
                        end
                        if string.find(file.source, "%." .. row.knob .. "%f[^%w_]") ~= nil then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(unread, row.knob)
                    end
                end
                table.sort(unread)
                TestRunner.truthy(
                    #unread == 0,
                    "knobs nothing reads: " .. table.concat(unread, "; ")
                )
            end,
        },
        {
            --[[
                The one-home rule, and the version of it that does not cry
                wolf. The obvious check is "a file that reads a knob must not
                declare a constant holding the same number", and it fires on
                any two unrelated numbers that happen to be 8 -- the first run
                of it reported `TerrainBuilder` reading
                `Config.BootstrapTimeoutSeconds` beside its own
                `SURFACE_PATCH_DEPTH`, which are the same value and nothing
                else. A check that has to be argued with every time it fires is
                a check somebody deletes.

                A second home is a constant that is the same **number** and
                also the same **thing**: names normalized and compared as
                substrings, so `STRIKE_RANGE` matches `EliteStrikeRange` and
                `SURFACE_PATCH_DEPTH` matches nothing. Both halves are
                required, because a similarly named constant with a different
                value is a different number and a coincidental value with a
                different name is a coincidence.
            ]]
            name = "no file that reads a knob keeps its own copy of the number",
            run = function()
                local files: { { path: string, source: string } } = {}
                readTree("src", files)

                local function normalize(name: string): string
                    return string.lower((string.gsub(name, "_", "")))
                end

                local problems: { string } = {}
                for _, row in knobRows() do
                    local value = (Config :: any)[row.knob]
                    local knobKey = normalize(row.knob)
                    for _, file in files do
                        if file.path == "src/shared/Config.luau" then
                            continue
                        end
                        if string.find(file.source, "%." .. row.knob .. "%f[^%w_]") == nil then
                            continue
                        end
                        for name, literal in
                            string.gmatch(file.source, "\nlocal ([A-Z][A-Z_0-9]*) = ([%d%.]+)\n")
                        do
                            local localKey = normalize(name)
                            local related = string.find(knobKey, localKey, 1, true) ~= nil
                                or string.find(localKey, knobKey, 1, true) ~= nil
                            if related and tonumber(literal) == value then
                                table.insert(
                                    problems,
                                    string.format(
                                        "%s reads Config.%s and also declares %s = %s",
                                        file.path,
                                        row.knob,
                                        name,
                                        literal
                                    )
                                )
                            end
                        end
                    end
                end
                table.sort(problems)
                TestRunner.truthy(#problems == 0, table.concat(problems, "; "))
            end,
        },
        {
            --[[
                The four services this wave emptied, checked by name. A general
                rule cannot say "these particular numbers came out", and a
                later refactor that quietly puts one back would otherwise pass
                every case above as long as the Config entry stayed.
            ]]
            name = "the four services this wave emptied hold no engagement constants",
            run = function()
                local emptied = {
                    "src/server/Services/OldGrowthService.luau",
                    "src/server/Services/WardenStagService.luau",
                    "src/server/Services/DefenseService.luau",
                    "src/server/Services/EnemyService.luau",
                }
                local banned = {
                    "ACTIVATION_RADIUS",
                    "ENCOUNTER_RADIUS",
                    "STRIKE_RANGE",
                    "WATCH_CHIP",
                    "LANTERN_CEILING",
                }
                local problems: { string } = {}
                for _, path in emptied do
                    local source = fs.readFile(path)
                    for _, name in banned do
                        if string.find(source, "\nlocal " .. name, 1, false) ~= nil then
                            table.insert(problems, path .. " declares " .. name .. " again")
                        end
                    end
                end
                table.sort(problems)
                TestRunner.truthy(#problems == 0, table.concat(problems, "; "))
            end,
        },
    },
}
