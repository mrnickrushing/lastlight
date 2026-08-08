--!strict

--[[
    A town's gate, and the invariant it must not be able to break.

    Two things are being asserted here and they pull in opposite directions.
    The first is that a policy actually refuses somebody -- a setting that
    admits everyone under every value is a setting. The second is the older
    one, from Milestone 4: **no arrival by another player may lower a town.**
    A new role in the middle of that path is exactly the kind of change that
    quietly turns a guard into a hole, so the invariant is re-asserted here
    against the new path rather than assumed to still hold in TownPermissions'
    own suite.

    The wiring case at the end is the one this codebase has learned to write
    first. A policy nobody can set is a policy that does not exist, and this
    project has shipped 120 recipes with no bench, 24 residents with no body
    and ninety craftable items with no equip button. The gate is checked for
    geometry, for a prompt, for an ActionId, and for a server branch that reads
    it.
]]

local fs = require("@lune/fs")
local Config = require("../../src/shared/Config")
local RuntimeIds = require("../../src/shared/RuntimeIds")
local SaveSchema = require("../../src/shared/SaveSchema")
local TownCondition = require("../../src/shared/TownCondition")
local TownPermissions = require("../../src/shared/TownPermissions")
local TownVisitPolicy = require("../../src/shared/TownVisitPolicy")
local TestRunner = require("../TestRunner")

local RELATIONS = { "host", "friend", "invited", "stranger" }

-- What each policy is expected to admit, written out here independently of the
-- table in the module. A spec that reads the same table it is checking proves
-- only that the table equals itself.
local EXPECTED: { [string]: { [string]: boolean } } = {
    open = { host = true, friend = true, invited = true, stranger = true },
    friends = { host = true, friend = true, invited = true, stranger = false },
    invited = { host = true, friend = false, invited = true, stranger = false },
    closed = { host = true, friend = false, invited = false, stranger = false },
}

return {
    name = "TownVisitPolicy",
    cases = {
        {
            name = "every policy value admits and refuses the right relations",
            run = function()
                local policies = TownVisitPolicy.list()
                TestRunner.equal(#policies, 4)
                for _, policy in policies do
                    local expected = EXPECTED[policy]
                    TestRunner.truthy(expected ~= nil, policy .. " has no expectation written")
                    for _, relation in RELATIONS do
                        TestRunner.equal(
                            TownVisitPolicy.admits(policy, relation).allowed,
                            expected[relation],
                            string.format("%s / %s decided the wrong way", policy, relation)
                        )
                    end
                end
            end,
        },
        {
            -- A founder locked out of the town they built by their own setting
            -- would be the worst possible bug in this feature, so it is
            -- checked against every value including ones nobody wrote.
            name = "a host is admitted to their own town under any value at all",
            run = function()
                for _, policy in TownVisitPolicy.list() do
                    TestRunner.equal(TownVisitPolicy.admits(policy, "host").allowed, true)
                    TestRunner.equal(TownVisitPolicy.roleFor(policy, "host"), "host")
                end
                for _, junk in { "", "OPEN", 7, nil, {} } do
                    TestRunner.equal(TownVisitPolicy.admits(junk, "host").allowed, true)
                end
            end,
        },
        {
            --[[
                The closed case, from every direction a caller could come at
                it: an unknown relation, a junk policy, a relation invented
                later. Closed must refuse everything that is not the host, and
                an unknown relation must resolve downward -- a new relation
                kind shipping admitted by every closed town in the game is
                exactly the accident this guards.
            ]]
            name = "closed refuses everyone but the host, including relations nobody wrote",
            run = function()
                for _, relation in { "friend", "invited", "stranger", "moderator", "", 3 } do
                    TestRunner.equal(
                        TownVisitPolicy.admits("closed", relation).allowed,
                        false,
                        "closed admitted " .. tostring(relation)
                    )
                    TestRunner.equal(TownVisitPolicy.roleFor("closed", relation), "outsider")
                end
            end,
        },
        {
            name = "an unreadable policy resolves open rather than shut",
            run = function()
                for _, junk in { nil, "", "friend", 12, {}, true } do
                    TestRunner.equal(TownVisitPolicy.normalize(junk), TownVisitPolicy.Default)
                end
                TestRunner.equal(TownVisitPolicy.Default, "open")
            end,
        },
        {
            -- The gate is one prompt, so the order is what a press means. It
            -- is pinned so a value inserted in the middle is a deliberate
            -- change to what the gate does rather than a side effect.
            name = "the gate cycles open, friends, invited, closed, and wraps",
            run = function()
                TestRunner.equal(TownVisitPolicy.next("open"), "friends")
                TestRunner.equal(TownVisitPolicy.next("friends"), "invited")
                TestRunner.equal(TownVisitPolicy.next("invited"), "closed")
                TestRunner.equal(TownVisitPolicy.next("closed"), "open")
                -- four presses return a founder to where they started, so the
                -- gate can always be walked back without knowing the list
                local policy = "open"
                for _ = 1, 4 do
                    policy = TownVisitPolicy.next(policy)
                end
                TestRunner.equal(policy, "open")
                for _, value in TownVisitPolicy.list() do
                    TestRunner.truthy(#TownVisitPolicy.label(value) > 0, value .. " has no label")
                end
            end,
        },
        {
            --[[
                Milestone 4's invariant, re-asserted against this path.

                An outsider contributes nothing, so a policy can only ever
                subtract from what a visitor could do. The test is stated the
                way the gate is: take a wrecked town from a late night, offer
                it as an arrival, and check that neither role can lower the
                integrity of the town standing there.
            ]]
            name = "no policy value lets an arrival lower a town",
            run = function()
                local intact = TownCondition.default()
                -- A town that has already held nights and taken damage: the
                -- exact record a veteran arrives carrying, and the one that
                -- used to replace an intact town outright.
                local wrecked = TownCondition.afterNight(TownCondition.default(), 10, 9, {
                    "building_sawmill",
                    "building_forge",
                })
                local before = TownCondition.averageIntegrity(intact)
                TestRunner.truthy(
                    TownCondition.averageIntegrity(wrecked) < before,
                    "the arriving record is not actually damaged"
                )
                local resolved = TownPermissions.resolveCondition(
                    intact,
                    wrecked,
                    "visitor",
                    TownCondition.merge,
                    TownCondition.averageIntegrity
                )
                TestRunner.truthy(
                    TownCondition.averageIntegrity(resolved) >= before,
                    "a visitor lowered the town"
                )
                -- and an outsider never reaches that call at all, which the
                -- service asserts by role; here the point is that the role it
                -- would pass is one of exactly two TownPermissions knows.
                for _, policy in TownVisitPolicy.list() do
                    for _, relation in RELATIONS do
                        local role = TownVisitPolicy.roleFor(policy, relation)
                        TestRunner.truthy(
                            role == "host" or role == "visitor" or role == "outsider",
                            "an unknown role escaped the policy: " .. tostring(role)
                        )
                    end
                end
            end,
        },
        {
            name = "the policy persists, and a value nobody offered is refused",
            run = function()
                local profile = SaveSchema.default(1000)
                TestRunner.equal(SaveSchema.visitPolicy(profile), "open")
                local closed = SaveSchema.withVisitPolicy(profile, "closed", 1100)
                TestRunner.equal(SaveSchema.visitPolicy(closed), "closed")
                TestRunner.equal(closed.revision, profile.revision + 1)
                -- a write of the value already stored is not a write
                TestRunner.equal(SaveSchema.withVisitPolicy(closed, "closed", 1200), closed)
                -- and junk changes nothing at all
                for _, junk in { "OPEN", "", 4, {}, nil } do
                    TestRunner.equal(SaveSchema.withVisitPolicy(closed, junk, 1300), closed)
                end
                TestRunner.equal(
                    SaveSchema.visitPolicy(SaveSchema.normalize({
                        social = {
                            visitPolicy = "nonsense",
                        },
                    }, 1400)),
                    "open"
                )
                TestRunner.equal(Config.SaveSchemaVersion, 24)
            end,
        },
        {
            --[[
                The reachability case. A policy the player cannot set is a
                field in a save file. The gate is world geometry with a prompt
                on it, so what is checked is that the geometry exists, that the
                prompt carries the action, and that the server reads it -- the
                same four-part wiring ActionWiring asks of every other action.
            ]]
            name = "the gate exists in the world and something answers it",
            run = function()
                local world = fs.readFile("src/server/Services/WorldService.luau")
                TestRunner.truthy(
                    string.find(world, "InteractionIds.TownGate", 1, true) ~= nil,
                    "nothing in the world carries the gate's interaction id"
                )
                TestRunner.truthy(
                    string.find(world, "Actions.SetVisitPolicy", 1, true) ~= nil,
                    "the gate prompt is stamped with no action"
                )
                TestRunner.truthy(
                    string.find(world, '"GatePost"', 1, true) ~= nil
                        and string.find(world, '"GateLintel"', 1, true) ~= nil,
                    "the gate is a label with no gate behind it"
                )
                local tutorial = fs.readFile("src/server/Services/TutorialService.luau")
                TestRunner.truthy(
                    string.find(tutorial, "Actions.SetVisitPolicy", 1, true) ~= nil,
                    "no server branch answers the gate"
                )
                TestRunner.truthy(
                    string.find(tutorial, "setHostPolicy", 1, true) ~= nil,
                    "a gate press never reaches the live town"
                )
                TestRunner.equal(RuntimeIds.InteractionIds.TownGate, "town_gate_policy")
            end,
        },
        {
            --[[
                The bypass case: every path that could adopt an arrival's town
                record has to go through one door. The service holds exactly
                one call to TownPermissions.resolveCondition, and it is inside
                the function that has already refused an outsider. A second
                call site would be a second door, and a policy with two doors
                is a policy with one.
            ]]
            name = "there is exactly one door a town record can arrive through",
            run = function()
                local service = fs.readFile("src/server/Services/TownNightService.luau")
                local doors = 0
                for _ in string.gmatch(service, "resolveCondition%(") do
                    doors += 1
                end
                TestRunner.equal(doors, 1, "the town record has more than one way in")
                TestRunner.truthy(
                    string.find(service, 'role == "outsider"', 1, true) ~= nil,
                    "the door does not refuse an outsider"
                )
                TestRunner.truthy(
                    string.find(service, "_pendingContributions", 1, true) ~= nil,
                    "an undecided arrival is applied rather than held"
                )
            end,
        },
    },
}
