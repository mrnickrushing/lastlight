--!strict
--[[
	The source table's own rules.

	`scripts/validate_localization.py` holds the table against the source tree:
	which files still speak for themselves, which keys nobody reads, which keys
	nobody defines. What a text check cannot see is what `get` does when it is
	asked for something that is not there, and that is what a localized build
	actually fails on -- not at build time, but on a phone, at the moment a
	label is drawn.

	So the rule this file exists for is that a missing string **throws**. Both
	alternatives ship. Returning the key paints `hud.close` on a button, which
	at least looks like a bug somebody will file; returning an empty string
	paints nothing, which looks like a design. This project has paid four times
	for a silent fallback hiding a gap -- 120 recipes with no bench, 24 residents
	with no body, ninety craftable items with no equip button -- and every one of
	them was a lookup that answered instead of refusing.
]]

local Strings = require("../../src/shared/Strings")
local TestRunner = require("../TestRunner")

--[[
	The surfaces a key may name. A surface is where a string is *read*, not the
	file it happens to live in, because a refactor moves a file and does not
	move a label off a screen. New surfaces arrive with the batch that migrates
	them, and the list is here rather than inferred so that a typo in a key
	fails instead of inventing a fourteenth surface nobody meant.

	`tutorial` is the first key here that names something other than a screen,
	and the distinction is worth stating rather than letting it arrive by
	accident. The tutorial's copy is read on three surfaces -- a toast, the
	objective banner, and Mara's own line -- and it follows the step rather than
	the screen, so the step is what the key can honestly name. Content batches
	extend that: a recipe's name is read at a workbench, in the field book and
	in a toast, and naming one of those three would be a lie about the other
	two.
]]
local SURFACES = {
    hud = true,
    client = true,
    objective = true,
    common = true,
    world = true,
    bramblewake = true,
    region = true,
    toast = true,
    tutorial = true,
    chat = true,
    encounter = true,
    enemy = true,
    expedition = true,
    profession = true,
    quest = true,
    resident = true,
    item = true,
    store = true,
    story = true,
    town = true,
}

return {
    name = "Localization",
    cases = {
        {
            name = "a key that exists answers with the text a player reads",
            run = function()
                TestRunner.equal(Strings.get("common.old_growth"), "OLD GROWTH")
            end,
        },
        {
            name = "a missing string refuses rather than answering",
            run = function()
                TestRunner.throws(function()
                    Strings.get("hud.a_label_nobody_wrote")
                end, "hud.a_label_nobody_wrote")
            end,
        },
        {
            name = "it never answers a missing key with the key or with nothing",
            run = function()
                -- The two shipping failures, asserted as failures rather than
                -- assumed absent. A fallback added later out of kindness would
                -- pass every other case in this file.
                local ok, value = pcall(function()
                    return Strings.get("hud.not_a_key")
                end)
                TestRunner.equal(ok, false, "a missing key answered instead of refusing")
                TestRunner.equal(value == "hud.not_a_key", false)
                TestRunner.equal(value == "", false)
            end,
        },
        {
            name = "the count is the number a language decision is made on",
            run = function()
                local keys = Strings.keys()
                TestRunner.equal(Strings.count(), #keys)
                TestRunner.truthy(Strings.count() > 0, "the table is empty")
            end,
        },
        {
            name = "every key names the surface it is read on",
            run = function()
                local wrong = {}
                for _, key in Strings.keys() do
                    local surface = string.match(key, "^([a-z]+)%.")
                    if surface == nil or not SURFACES[surface] then
                        table.insert(wrong, key)
                    end
                end
                TestRunner.equal(
                    #wrong,
                    0,
                    "keys with no known surface: " .. table.concat(wrong, ", ")
                )
            end,
        },
        {
            name = "no two keys hold the same text",
            run = function()
                --[[
					A translator paid twice for one word is the smaller half.
					The larger half is that two keys holding one sentence
					drift: somebody edits the button and the other copy of it
					stays, and the game then says two things in one voice.
					Merging the first duplicate this found -- the Old Growth's
					name, written once in the HUD and once in the client
					bootstrap -- is what the `common` surface exists for.
				]]
                local byText: { [string]: string } = {}
                local duplicates = {}
                for _, key in Strings.keys() do
                    local text = Strings.get(key)
                    if byText[text] ~= nil then
                        table.insert(duplicates, byText[text] .. " and " .. key)
                    end
                    byText[text] = key
                end
                TestRunner.equal(
                    #duplicates,
                    0,
                    "same text under two keys: " .. table.concat(duplicates, "; ")
                )
            end,
        },
        {
            name = "nothing in the table is empty or only punctuation",
            run = function()
                local empty = {}
                for _, key in Strings.keys() do
                    if not string.find(Strings.get(key), "%a") then
                        table.insert(empty, key)
                    end
                end
                TestRunner.equal(
                    #empty,
                    0,
                    "keys with no letters in them: " .. table.concat(empty, ", ")
                )
            end,
        },
    },
}
