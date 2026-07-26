--!strict

local TestRunner = require("./TestRunner")

TestRunner.run({
    require("./specs/BramblewakeEnemies.spec"),
    require("./specs/CombatState.spec"),
    require("./specs/ContentId.spec"),
    require("./specs/ContentRegistry.spec"),
    require("./specs/Environment.spec"),
    require("./specs/EnemyAttackFlow.spec"),
    require("./specs/EnemyCombatRules.spec"),
    require("./specs/ExpeditionEventFlow.spec"),
    require("./specs/ExpeditionGenerator.spec"),
    require("./specs/ExpeditionInventory.spec"),
    require("./specs/ExpeditionRewardLedger.spec"),
    require("./specs/FeatureFlagService.spec"),
    require("./specs/NightSchedule.spec"),
    require("./specs/OldGrowthEncounter.spec"),
    require("./specs/ProfessionState.spec"),
    require("./specs/RateLimiter.spec"),
    require("./specs/ReviveFlow.spec"),
    require("./specs/SaveSchema.spec"),
    require("./specs/ServiceRegistry.spec"),
    require("./specs/SurvivalState.spec"),
    require("./specs/StatusEffectState.spec"),
    require("./specs/TutorialFlow.spec"),
    require("./specs/WardenStagEncounter.spec"),
    require("./specs/BramblewakeBlackout.spec"),
    require("./specs/TownNightSchedule.spec"),
})
