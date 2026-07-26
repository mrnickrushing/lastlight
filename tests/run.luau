--!strict

local TestRunner = require("./TestRunner")

TestRunner.run({
    require("./specs/ContentId.spec"),
    require("./specs/ContentRegistry.spec"),
    require("./specs/Environment.spec"),
    require("./specs/ExpeditionEventFlow.spec"),
    require("./specs/ExpeditionGenerator.spec"),
    require("./specs/ExpeditionRewardLedger.spec"),
    require("./specs/FeatureFlagService.spec"),
    require("./specs/NightSchedule.spec"),
    require("./specs/RateLimiter.spec"),
    require("./specs/SaveSchema.spec"),
    require("./specs/ServiceRegistry.spec"),
    require("./specs/TutorialFlow.spec"),
})
