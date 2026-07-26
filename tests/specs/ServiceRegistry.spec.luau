--!strict

local ServiceRegistry = require("../../src/server/ServiceRegistry")
local TestRunner = require("../TestRunner")

return {
    name = "ServiceRegistry",
    cases = {
        {
            name = "initializes every service before starting any service",
            run = function()
                local calls: { string } = {}
                local function service(name: string)
                    return {
                        Name = name,
                        Init = function()
                            table.insert(calls, "init:" .. name)
                        end,
                        Start = function()
                            table.insert(calls, "start:" .. name)
                        end,
                    }
                end

                local registry = ServiceRegistry.new({ test = true })
                registry:register(service("One"))
                registry:register(service("Two"))
                registry:initialize()
                registry:start()

                TestRunner.equal(table.concat(calls, ","), "init:One,init:Two,start:One,start:Two")
                TestRunner.equal(registry:state(), "started")
                TestRunner.equal(registry:count(), 2)
            end,
        },
        {
            name = "rejects duplicate service names",
            run = function()
                local registry = ServiceRegistry.new({})
                registry:register({ Name = "Duplicate" })
                TestRunner.throws(function()
                    registry:register({ Name = "Duplicate" })
                end, "duplicate service")
            end,
        },
    },
}
