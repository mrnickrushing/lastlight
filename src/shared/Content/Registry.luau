--!strict

local Registry = {}
Registry.__index = Registry

export type Definition = {
    id: string,
    kind: string,
    version: number,
    enabled: boolean,
    displayNameKey: string,
    analyticsKey: string,
    assetBundle: string,
    featureFlag: string?,
    tags: { string },
    dependencies: { string },
}

export type Issue = {
    id: string?,
    field: string,
    message: string,
}

export type Registry = typeof(setmetatable(
    {} :: {
        _byId: { [string]: Definition },
        _ids: { string },
    },
    Registry
))

local allowedFields: { [string]: boolean } = {
    id = true,
    kind = true,
    version = true,
    enabled = true,
    displayNameKey = true,
    analyticsKey = true,
    assetBundle = true,
    featureFlag = true,
    tags = true,
    dependencies = true,
}

local function addIssue(issues: { Issue }, id: string?, field: string, message: string)
    table.insert(issues, {
        id = id,
        field = field,
        message = message,
    })
end

local function validateStringArray(issues: { Issue }, id: string?, field: string, value: any)
    if type(value) ~= "table" then
        addIssue(issues, id, field, "must be an array")
        return
    end

    local seen: { [string]: boolean } = {}
    for index, item in value do
        if type(index) ~= "number" or type(item) ~= "string" or item == "" then
            addIssue(issues, id, field, "must contain only non-empty strings")
            return
        end

        if seen[item] then
            addIssue(issues, id, field, string.format("contains duplicate value %q", item))
            return
        end
        seen[item] = true
    end
end

local function validateDefinition(issues: { Issue }, definition: any)
    if type(definition) ~= "table" then
        addIssue(issues, nil, "definition", "must be a table")
        return
    end

    local id = if type(definition.id) == "string" then definition.id else nil
    for field in definition do
        if not allowedFields[field] then
            addIssue(issues, id, field, "is not allowed by content schema version 1")
        end
    end

    for _, field in { "id", "kind", "displayNameKey", "analyticsKey", "assetBundle" } do
        if type(definition[field]) ~= "string" or definition[field] == "" then
            addIssue(issues, id, field, "must be a non-empty string")
        end
    end

    if type(definition.id) == "string" and type(definition.kind) == "string" then
        local expectedPrefix = definition.kind .. "_"
        if string.sub(definition.id, 1, #expectedPrefix) ~= expectedPrefix then
            addIssue(issues, id, "id", string.format("must use the %s prefix", expectedPrefix))
        end
        if
            string.match(definition.id, "^[a-z][a-z0-9_]*$") == nil
            or string.find(definition.id, "__", 1, true) ~= nil
            or string.sub(definition.id, -1) == "_"
        then
            addIssue(issues, id, "id", "must be lowercase snake case")
        end
    end

    if
        type(definition.version) ~= "number"
        or definition.version < 1
        or definition.version % 1 ~= 0
    then
        addIssue(issues, id, "version", "must be a positive integer")
    end

    if type(definition.enabled) ~= "boolean" then
        addIssue(issues, id, "enabled", "must be a boolean")
    end

    if
        definition.featureFlag ~= nil
        and (type(definition.featureFlag) ~= "string" or definition.featureFlag == "")
    then
        addIssue(issues, id, "featureFlag", "must be nil or a non-empty string")
    end

    validateStringArray(issues, id, "tags", definition.tags)
    validateStringArray(issues, id, "dependencies", definition.dependencies)
end

function Registry.validate(definitions: { any }): (boolean, { Issue })
    local issues: { Issue } = {}
    local ids: { [string]: boolean } = {}

    for _, definition in definitions do
        validateDefinition(issues, definition)
        if type(definition) == "table" and type(definition.id) == "string" then
            if ids[definition.id] then
                addIssue(issues, definition.id, "id", "is duplicated")
            end
            ids[definition.id] = true
        end
    end

    for _, definition in definitions do
        if type(definition) == "table" and type(definition.dependencies) == "table" then
            for _, dependency in definition.dependencies do
                if type(dependency) == "string" and not ids[dependency] then
                    addIssue(
                        issues,
                        definition.id,
                        "dependencies",
                        "references missing " .. dependency
                    )
                end
            end
        end
    end

    return #issues == 0, issues
end

function Registry.new(definitions: { Definition }): Registry
    local valid, issues = Registry.validate(definitions)
    if not valid then
        local first = issues[1]
        error(
            string.format(
                "invalid content registry at %s.%s: %s",
                first.id or "<unknown>",
                first.field,
                first.message
            )
        )
    end

    local byId: { [string]: Definition } = {}
    local ids: { string } = {}
    for _, definition in definitions do
        local immutable = table.clone(definition)
        immutable.tags = table.freeze(table.clone(definition.tags))
        immutable.dependencies = table.freeze(table.clone(definition.dependencies))
        byId[definition.id] = table.freeze(immutable)
        table.insert(ids, definition.id)
    end
    table.sort(ids)

    return setmetatable({
        _byId = byId,
        _ids = ids,
    }, Registry)
end

function Registry.get(self: Registry, id: string): Definition?
    return self._byId[id]
end

function Registry.has(self: Registry, id: string): boolean
    return self._byId[id] ~= nil
end

function Registry.count(self: Registry): number
    return #self._ids
end

function Registry.ids(self: Registry): { string }
    return table.clone(self._ids)
end

function Registry.byKind(self: Registry, kind: string): { Definition }
    local matches: { Definition } = {}
    for _, id in self._ids do
        local definition = self._byId[id]
        if definition.kind == kind then
            table.insert(matches, definition)
        end
    end

    return matches
end

return table.freeze(Registry)
