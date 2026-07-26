--!strict

local ContentId = require("../../src/shared/Content/ContentId")
local TestRunner = require("../TestRunner")

return {
    name = "ContentId",
    cases = {
        {
            name = "accepts stable snake-case IDs",
            run = function()
                local valid, message = ContentId.validate("region_bramblewake", "region")
                TestRunner.truthy(valid, message)
                TestRunner.equal(ContentId.kind("region_bramblewake"), "region")
            end,
        },
        {
            name = "rejects casing and missing type prefixes",
            run = function()
                local valid = ContentId.validate("Bramblewake", "region")
                TestRunner.equal(valid, false)

                local wrongKind, message = ContentId.validate("enemy_rootling", "region")
                TestRunner.equal(wrongKind, false)
                TestRunner.truthy(string.find(message or "", "region_", 1, true))
            end,
        },
    },
}
