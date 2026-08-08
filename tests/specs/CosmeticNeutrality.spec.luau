--!strict

--[[
    A cosmetic must not be able to become a requirement.

    `scripts/validate_monetization.py` has asserted since Milestone 4 that no
    gameplay code branches on ownership, and it has been true by *absence* --
    there was no purchase API anywhere to branch on. Its own docstring names
    the risk in that: "an exit-gate item that passes because a thing is missing
    goes on passing right up until someone adds the thing." Milestone 11 adds
    the thing. This suite is what keeps the property true once absence stops
    doing the work.

    Four claims, and each is checkable rather than argued:

      1. **A cosmetic carries no number that is not presentation.** Every
         numeric leaf in the catalog sits under a colour, a size, an offset, a
         rotation. There is no field a stat could hide in.
      2. **No gameplay module names a cosmetic.** Not a recipe, not a drop
         table, not a spawn rule, not a reward. If nothing can read a cosmetic
         id, nothing can gate on one.
      3. **Nothing shared or client-side reaches the commerce seam.** The
         module that talks to the platform is server-only, forever, and this
         fails the day something on the other side of the wire requires it.
      4. **The allowlist stays at one entry.** `validate_monetization.py`'s
         ALLOWED may hold at most `CommerceService`, by name. A second entry is
         the design failing, not the list being too short.
]]

local fs = require("@lune/fs")
local CosmeticCatalog = require("../../src/shared/CosmeticCatalog")
local Entitlements = require("../../src/shared/Entitlements")
local TestRunner = require("../TestRunner")

--[[
    The only keys a number may live under in a cosmetic entry.

    Written as a whitelist rather than a blacklist of stat names, because a
    blacklist is a list of the stats somebody thought of. `power`, `bonus`,
    `capacity`, `multiplier` -- the point is that none of those needs naming,
    since anything not in this list fails whatever it is called.
]]
local PRESENTATION_KEYS: { [string]: boolean } = {
    size = true,
    offset = true,
    rotation = true,
    color = true,
}

local function walkNumbers(
    value: any,
    keyPath: string,
    allowedUnder: boolean,
    offenders: { string }
)
    if type(value) == "number" then
        if not allowedUnder then
            table.insert(offenders, keyPath)
        end
        return
    end
    if type(value) ~= "table" then
        return
    end
    for key, child in value do
        local childAllowed = allowedUnder
        local childPath = keyPath
        if type(key) == "string" then
            childPath = keyPath .. "." .. key
            childAllowed = PRESENTATION_KEYS[key] == true
        end
        walkNumbers(child, childPath, childAllowed, offenders)
    end
end

local function readTree(root: string, files: { { path: string, source: string } })
    for _, entry in fs.readDir(root) do
        local path = root .. "/" .. entry
        if fs.isDir(path) then
            readTree(path, files)
        elseif string.sub(entry, -5) == ".luau" then
            table.insert(files, { path = path, source = fs.readFile(path) })
        end
    end
end

--[[
    Where a cosmetic id is allowed to be named.

    The catalog defines them; the schema and the entitlement rules move them
    around as opaque strings; the spec suite reads them. Everything else in the
    game must be unable to name one, which is what makes gating on one
    impossible rather than merely discouraged.
]]
local COSMETIC_ID_ALLOWED: { [string]: boolean } = {
    ["src/shared/CosmeticCatalog.luau"] = true,
}

return {
    name = "CosmeticNeutrality",
    cases = {
        {
            name = "no cosmetic carries a number that is not presentation",
            run = function()
                local offenders: { string } = {}
                for _, cosmetic in CosmeticCatalog.list() do
                    walkNumbers(cosmetic, cosmetic.id, false, offenders)
                end
                TestRunner.truthy(
                    #offenders == 0,
                    "numbers outside the presentation whitelist: " .. table.concat(offenders, ", ")
                )
            end,
        },
        {
            -- The same walk over what is for sale. A product that carried a
            -- number would be a product whose *purchase* changed something.
            name = "no product carries a number at all",
            run = function()
                local offenders: { string } = {}
                for _, product in CosmeticCatalog.products() do
                    walkNumbers(product, product.id, false, offenders)
                end
                TestRunner.truthy(
                    #offenders == 0,
                    "a product carries a number: " .. table.concat(offenders, ", ")
                )
                -- and every one of them states its permanence, which the store
                -- card is required to show
                for _, product in CosmeticCatalog.products() do
                    TestRunner.equal(
                        product.permanence,
                        "permanent",
                        product.id .. " is not permanent"
                    )
                end
            end,
        },
        {
            --[[
                The structural half. A cosmetic id that no gameplay module can
                name is a cosmetic no gameplay branch can read, which is a
                stronger statement than "we did not write that branch".
            ]]
            name = "nothing outside the catalog names a cosmetic",
            run = function()
                local files: { { path: string, source: string } } = {}
                readTree("src", files)
                local offenders: { string } = {}
                for _, file in files do
                    if not COSMETIC_ID_ALLOWED[file.path] then
                        for _, cosmetic in CosmeticCatalog.list() do
                            if string.find(file.source, cosmetic.id, 1, true) ~= nil then
                                table.insert(
                                    offenders,
                                    string.format("%s names %s", file.path, cosmetic.id)
                                )
                            end
                        end
                    end
                end
                TestRunner.truthy(#offenders == 0, table.concat(offenders, ", "))
            end,
        },
        {
            --[[
                The commerce seam is server-only. A shared or client module that
                required it would put the ownership question on the wrong side
                of the wire, where a client could be asked it -- and a client
                that can be asked what it owns is a client that can answer.
            ]]
            name = "nothing shared or client-side reaches the commerce seam",
            run = function()
                local files: { { path: string, source: string } } = {}
                readTree("src/shared", files)
                readTree("src/client", files)
                for _, file in files do
                    TestRunner.equal(
                        string.find(file.source, "CommerceService", 1, true),
                        nil,
                        file.path .. " reaches the commerce seam"
                    )
                    TestRunner.equal(
                        string.find(file.source, "MarketplaceService", 1, true),
                        nil,
                        file.path .. " reaches the platform's purchase API"
                    )
                end
            end,
        },
        {
            --[[
                The allowlist, pinned by name and by size.

                Stated as "at most one, and if it is there it is
                CommerceService" rather than "exactly one", so the claim is
                true both before that module exists and after. What it refuses
                in every state is a second module -- which would be the design
                failing rather than the list being too short.
            ]]
            name = "the monetization allowlist holds at most CommerceService",
            run = function()
                local script = fs.readFile("scripts/validate_monetization.py")
                local block = string.match(script, "ALLOWED: dict%[str, str%] = {(.-)}")
                TestRunner.truthy(block ~= nil, "the allowlist is not where the spec expects it")
                local entries: { string } = {}
                for path in string.gmatch(block :: string, '"([^"]+)"%s*:') do
                    table.insert(entries, path)
                end
                TestRunner.truthy(
                    #entries <= 1,
                    "the allowlist grew past one entry: " .. table.concat(entries, ", ")
                )
                if #entries == 1 then
                    TestRunner.equal(entries[1], "src/server/Services/CommerceService.luau")
                end
            end,
        },
        {
            --[[
                And the rule the whole architecture exists for, stated as a
                behaviour: what is owned and what is worn are different
                questions, and only the second is a plain profile field
                gameplay may read.
            ]]
            name = "wearing something you do not own is refused",
            run = function()
                local state = Entitlements.default()
                local _, refused =
                    Entitlements.equip(state, "outfit", "cosmetic_lantern_keeper_coat")
                TestRunner.equal(refused.applied, false)
                TestRunner.equal(refused.reason, "not_owned")

                local owned = Entitlements.normalize({
                    entitlements = { cosmetic_lantern_keeper_coat = true },
                })
                local worn, result =
                    Entitlements.equip(owned, "outfit", "cosmetic_lantern_keeper_coat")
                TestRunner.equal(result.applied, true)
                TestRunner.equal(
                    Entitlements.equippedIn(worn, "outfit"),
                    "cosmetic_lantern_keeper_coat"
                )
                -- taking it off is always allowed, even for something no
                -- longer owned: a refund must not leave a player stuck wearing
                -- a thing they cannot remove
                local stripped = Entitlements.normalize({
                    equipped = { outfit = "cosmetic_lantern_keeper_coat" },
                }, function(): boolean
                    return true
                end)
                local bare, removal = Entitlements.equip(stripped, "outfit", nil)
                TestRunner.equal(removal.applied, true)
                TestRunner.equal(Entitlements.equippedIn(bare, "outfit"), nil)
            end,
        },
    },
}
