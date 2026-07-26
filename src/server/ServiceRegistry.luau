--!strict

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

export type Service = {
    Name: string,
    Init: ((self: any, context: any) -> ())?,
    Start: ((self: any) -> ())?,
}

export type Registry = typeof(setmetatable(
    {} :: {
        _context: any,
        _ordered: { Service },
        _byName: { [string]: Service },
        _state: string,
    },
    ServiceRegistry
))

function ServiceRegistry.new(context: any): Registry
    return setmetatable({
        _context = context,
        _ordered = {},
        _byName = {},
        _state = "registering",
    }, ServiceRegistry)
end

function ServiceRegistry.register(self: Registry, service: Service)
    assert(self._state == "registering", "services can only register before initialization")
    assert(type(service.Name) == "string" and service.Name ~= "", "service must have a Name")
    assert(self._byName[service.Name] == nil, "duplicate service " .. service.Name)

    self._byName[service.Name] = service
    table.insert(self._ordered, service)
end

function ServiceRegistry.get(self: Registry, name: string): Service?
    return self._byName[name]
end

function ServiceRegistry.initialize(self: Registry)
    assert(self._state == "registering", "service registry already initialized")
    self._state = "initializing"

    for _, service in self._ordered do
        local initialize = service.Init
        if initialize ~= nil then
            local ok, message = xpcall(function()
                initialize(service, self._context)
            end, debug.traceback)
            if not ok then
                self._state = "failed"
                error(string.format("service %s failed to initialize: %s", service.Name, message))
            end
        end
    end

    self._state = "initialized"
end

function ServiceRegistry.start(self: Registry)
    assert(self._state == "initialized", "services must initialize before start")
    self._state = "starting"

    for _, service in self._ordered do
        local start = service.Start
        if start ~= nil then
            local ok, message = xpcall(function()
                start(service)
            end, debug.traceback)
            if not ok then
                self._state = "failed"
                error(string.format("service %s failed to start: %s", service.Name, message))
            end
        end
    end

    self._state = "started"
end

function ServiceRegistry.state(self: Registry): string
    return self._state
end

function ServiceRegistry.count(self: Registry): number
    return #self._ordered
end

return table.freeze(ServiceRegistry)
