--!strict

local TestRunner = require("./TestRunner")

TestRunner.run({
    require("./specs/ContentId.spec"),
    require("./specs/ContentRegistry.spec"),
    require("./specs/Environment.spec"),
    require("./specs/FeatureFlagService.spec"),
    require("./specs/ServiceRegistry.spec"),
})
