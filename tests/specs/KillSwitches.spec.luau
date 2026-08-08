--!strict

--[[
    The kill switches, and the one property that makes a switch a switch.

    `docs/ROLLBACK.md` lists every system that can be turned off and what
    turning it off leaves. The list is worth exactly its agreement with the
    code, so both directions are checked -- but the interesting case is not
    either list. It is **scope**.

    A switch you have to restart every server to use is not a switch. The only
    moment one exists for is an incident, and during an incident the servers
    are already running with players in them. So a flag declared `live` has to
    be *read where the decision is made*, and the failure shape is specific and
    invisible: a service that caches `isEnabled` into a field at construction
    passes every other check in this repository, reports the right value on
    every snapshot, and quietly requires a restart.

    This project has paid for that twice. #344's soak switch was read once at
    boot and could never be turned on from the only place anybody drove it,
    with nothing failing while it could not. And `TownNightService` cached the
    town cycle's flag at construction until the wave that added this file.

    So: no service may keep a flag's answer in a field. Three encounter
    switches are `restart`-scoped by declaration, and **their count is pinned**
    for the reason RELEASE_GATES.md pins its `review` rows -- a switch nobody
    wants to make live becoming a fourth is how a kill-switch list quietly
    stops being one.
]]

local fs = require("@lune/fs")
local Config = require("../../src/shared/Config")
local TestRunner = require("../TestRunner")

local DOC = "docs/ROLLBACK.md"
local RESTART_SCOPED = 3
-- Flags nothing reads. Pinned harder than the restart count: a switch that
-- turns nothing off is indistinguishable from a working one until somebody
-- reaches for it during an incident.
local UNWIRED = 4

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

local function switchRows(): { { system: string, flag: string, scope: string } }
    local doc = fs.readFile(DOC)
    local rows: { { system: string, flag: string, scope: string } } = {}
    local inTable = false
    for line in string.gmatch(doc, "[^\n]+") do
        if string.sub(line, 1, 1) ~= "|" then
            inTable = false
        elseif string.find(line, "What turning it off leaves", 1, true) ~= nil then
            inTable = true
        elseif inTable and string.find(line, "^|%s*%-") == nil then
            local cells: { string } = {}
            for cell in string.gmatch(line, "|([^|]*)") do
                table.insert(cells, trim(cell))
            end
            if #cells >= 4 then
                local flag = string.match(cells[2], "^`([a-z_]+)`$")
                if flag ~= nil then
                    table.insert(rows, { system = cells[1], flag = flag, scope = cells[4] })
                end
            end
        end
    end
    return rows
end

return {
    name = "KillSwitches",
    cases = {
        {
            name = "every flag is a listed switch and every listed switch is a flag",
            run = function()
                local rows = switchRows()
                local listed: { [string]: boolean } = {}
                local problems: { string } = {}
                for _, row in rows do
                    if listed[row.flag] then
                        table.insert(problems, row.flag .. " is listed twice")
                    end
                    listed[row.flag] = true
                    if Config.FeatureFlags[row.flag] == nil then
                        table.insert(problems, row.flag .. " is not a feature flag")
                    end
                end
                for flag in Config.FeatureFlags do
                    if not listed[flag] then
                        --[[
                            The worse direction. A flag added to the game and
                            not written down here is a system nobody has
                            decided how to turn off, discovered during the
                            incident that needs it off.
                        ]]
                        table.insert(problems, flag .. " is a flag with no entry in " .. DOC)
                    end
                end
                table.sort(problems)
                TestRunner.truthy(#problems == 0, table.concat(problems, "; "))
            end,
        },
        {
            name = "every switch declares a scope the document defines",
            run = function()
                local allowed = { live = true, rebuild = true, restart = true, none = true }
                local problems: { string } = {}
                for _, row in switchRows() do
                    if not allowed[row.scope] then
                        table.insert(problems, row.flag .. " has scope " .. row.scope)
                    end
                end
                table.sort(problems)
                TestRunner.truthy(#problems == 0, table.concat(problems, "; "))
            end,
        },
        {
            --[[
                The pin. Three encounter switches are baked into a state
                machine at Init and that is a decision with a reason, written
                in the document. A fourth is the cheap move -- a switch nobody
                wants to make live gets a word instead of a fix.
            ]]
            name = "exactly three switches are restart-scoped",
            run = function()
                local restart: { string } = {}
                for _, row in switchRows() do
                    if row.scope == "restart" then
                        table.insert(restart, row.flag)
                    end
                end
                table.sort(restart)
                TestRunner.equal(
                    #restart,
                    RESTART_SCOPED,
                    "restart-scoped switches: " .. table.concat(restart, ", ")
                )
            end,
        },
        {
            --[[
                The property the whole file is for. A cached answer is a switch
                that needs a restart, whatever its row says -- and it looks
                identical to a working one from everywhere except an incident.

                The scope column is what licenses a cache, which is what makes
                that column load-bearing rather than descriptive: a `rebuild`
                switch is stored on purpose, because the states created from it
                have to agree with each other for the life of one manifest. A
                flag declared `live` and cached fails here, and so does one
                cached without a row at all.
            ]]
            name = "no live switch keeps its answer in a field",
            run = function()
                local scope: { [string]: string } = {}
                for _, row in switchRows() do
                    scope[row.flag] = row.scope
                end

                local files: { { path: string, source: string } } = {}
                readTree("src", files)
                local problems: { string } = {}
                for _, file in files do
                    if file.path == "src/server/Services/FeatureFlagService.luau" then
                        continue
                    end
                    for field, flag in
                        string.gmatch(
                            file.source,
                            '(_[%a][%w_]*)%s*=%s*[%w_%.]*[Ff]lags?:isEnabled%("([a-z_]+)"%)'
                        )
                    do
                        if scope[flag] ~= "rebuild" and scope[flag] ~= "restart" then
                            table.insert(
                                problems,
                                string.format(
                                    "%s stores %s in %s but the switch is %s",
                                    file.path,
                                    flag,
                                    field,
                                    scope[flag] or "not listed"
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
                A switch nothing reads turns nothing off. Same question the
                gate and tuning suites ask about emitters and knobs: existing
                and being reached are different facts, and a flag is the
                quietest of the three because reading it wrong raises nothing.
            ]]
            name = "a switch that reads is wired and a switch that does not says so",
            run = function()
                local files: { { path: string, source: string } } = {}
                readTree("src", files)
                local unread: { string } = {}
                local problems: { string } = {}
                for _, row in switchRows() do
                    local found = false
                    for _, file in files do
                        if file.path == "src/shared/Config.luau" then
                            continue
                        end
                        if string.find(file.source, '"' .. row.flag .. '"', 1, true) ~= nil then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(unread, row.flag)
                        if row.scope ~= "none" then
                            table.insert(
                                problems,
                                row.flag .. " is declared " .. row.scope .. " and nothing reads it"
                            )
                        end
                    elseif row.scope == "none" then
                        table.insert(
                            problems,
                            row.flag .. " is declared none but something reads it"
                        )
                    end
                end
                table.sort(problems)
                TestRunner.truthy(#problems == 0, table.concat(problems, "; "))
                table.sort(unread)
                TestRunner.equal(
                    #unread,
                    UNWIRED,
                    "switches nothing reads: " .. table.concat(unread, ", ")
                )
            end,
        },
        {
            --[[
                And the rollback procedure's own precondition. Production
                refuses overrides, which is correct and is also the honest
                limit on how fast the first step of a rollback is; the document
                says so, and this makes sure it stays true of the config it
                describes.
            ]]
            name = "production still refuses flag overrides, as the procedure says",
            run = function()
                TestRunner.equal(Config.Environments.production.AllowFlagOverrides, false)
                local doc = fs.readFile(DOC)
                TestRunner.truthy(
                    string.find(doc, "AllowFlagOverrides = false", 1, true) ~= nil,
                    "the rollback procedure no longer states the production override rule"
                )
            end,
        },
    },
}
