--!strict

local Logger = {}
Logger.__index = Logger

export type Fields = { [string]: any }
export type Sink = (level: string, line: string, fields: Fields) -> ()
export type Logger = typeof(setmetatable(
    {} :: {
        _environment: string,
        _minimumLevel: number,
        _sink: Sink,
    },
    Logger
))

local levels = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4,
}

local function defaultSink(level: string, line: string, _fields: Fields)
    if level == "warn" or level == "error" then
        warn(line)
    else
        print(line)
    end
end

local function formatFields(fields: Fields): string
    local keys: { string } = {}
    for key in fields do
        table.insert(keys, key)
    end
    table.sort(keys)

    local output: { string } = {}
    for _, key in keys do
        table.insert(output, string.format("%s=%s", key, tostring(fields[key])))
    end

    return table.concat(output, " ")
end

function Logger.new(environment: string, minimumLevel: string, sink: Sink?): Logger
    assert(levels[minimumLevel] ~= nil, "unknown minimum log level")
    return setmetatable({
        _environment = environment,
        _minimumLevel = levels[minimumLevel],
        _sink = sink or defaultSink,
    }, Logger)
end

function Logger._emit(self: Logger, level: string, event: string, fields: Fields?)
    if levels[level] < self._minimumLevel then
        return
    end

    local safeFields = fields or {}
    local suffix = formatFields(safeFields)
    local line =
        string.format("[LastLight][%s][%s] %s", string.upper(level), self._environment, event)
    if suffix ~= "" then
        line ..= " " .. suffix
    end

    self._sink(level, line, safeFields)
end

function Logger.debug(self: Logger, event: string, fields: Fields?)
    self:_emit("debug", event, fields)
end

function Logger.info(self: Logger, event: string, fields: Fields?)
    self:_emit("info", event, fields)
end

function Logger.warn(self: Logger, event: string, fields: Fields?)
    self:_emit("warn", event, fields)
end

function Logger.error(self: Logger, event: string, fields: Fields?)
    self:_emit("error", event, fields)
end

return table.freeze(Logger)
