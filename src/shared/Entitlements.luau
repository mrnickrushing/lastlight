--!strict

--[[
    What a player owns, how a receipt becomes that, and the two ways a grant
    can be lost if nobody is careful.

    This module is pure on purpose, and the purpose is not tidiness. Roblox's
    `ProcessReceipt` cannot be exercised in Studio -- the round trip needs a
    real purchase on a real account -- so everything that *decides* anything
    about a purchase has to be testable without it. What is left for the
    platform is the call itself.

    Three rules hold the whole thing up.

    **The purchase id is the idempotency key, and a duplicate is a success.**
    Roblox retries `ProcessReceipt` until it is told the grant is durable. A
    retry of a purchase already recorded must answer "granted" rather than
    grant again -- answering "not yet" would retry forever, and granting again
    would hand out two of something bought once. So `apply` reports both what
    it did and whether the receipt may be acknowledged, and those are different
    answers.

    **An unknown product is never consumed.** A receipt naming a product this
    build has never heard of resolves to nothing, and reporting that as a
    successful grant would tell the platform to stop retrying a purchase the
    player has paid for and not received. It is refused instead, so the receipt
    stays pending until a build that knows the product handles it. This is the
    one case where doing nothing is much better than doing something.

    **A grant that arrives while the profile is away goes in the mailbox.** A
    receipt can land in a server where the player's profile is not loaded, or
    is loaded and locked by another server. Writing entitlements into a profile
    that is not ours is how two servers overwrite one save; refusing outright
    would drop the purchase. The mailbox is a third place -- neither the
    profile nor the platform -- that holds the receipt until a load can drain
    it. It lives outside the profile by construction, because its entire reason
    for existing is the moments when the profile does not.
]]

export type State = {
    -- What is owned, as a set. A set rather than a list because ownership is
    -- a membership question and a list would let the same id appear twice.
    entitlements: { [string]: boolean },
    -- Every purchase id already applied, with when. The ledger that makes a
    -- retry idempotent.
    processed: { [string]: number },
    -- What is worn, per cosmetic slot. Gameplay branches on this and never on
    -- `entitlements` -- what is equipped is a profile field like every other,
    -- and what is owned is a question only the commerce seam is allowed to ask.
    equipped: { [string]: string },
}

export type Receipt = {
    purchaseId: string,
    productId: string,
    at: number,
}

export type Result = {
    applied: boolean,
    -- Whether the platform may stop retrying. True for a fresh grant AND for a
    -- duplicate, false for anything this build could not resolve.
    acknowledge: boolean,
    reason: string,
    granted: { string },
}

local Entitlements = {}

local MAX_ID_LENGTH = 64
-- A mailbox is a holding pen, not a queue with a future. If a player has this
-- many unclaimed receipts something is wrong upstream, and growing without
-- bound would eventually fail the write that is meant to protect them.
local MAX_MAILBOX = 32

local function validId(value: any): boolean
    return type(value) == "string" and #value > 0 and #value <= MAX_ID_LENGTH
end

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Entitlements.default(): State
    return {
        entitlements = {},
        processed = {},
        equipped = {},
    }
end

--[[
    Bound whatever came back off a save.

    Every id is length-checked and every timestamp is a real number, because
    this is storage and storage is the door a forged profile comes through. An
    equipped cosmetic that the catalog no longer knows is dropped rather than
    kept: a slot pointing at nothing is a slot the appearance code has to guard
    forever, and a cosmetic removed from the catalog is removed.
]]
function Entitlements.normalize(value: any, isKnownCosmetic: ((string) -> boolean)?): State
    local state = Entitlements.default()
    if type(value) ~= "table" then
        return state
    end

    if type(value.entitlements) == "table" then
        for cosmeticId, owned in value.entitlements do
            if
                validId(cosmeticId)
                and owned == true
                and (isKnownCosmetic == nil or isKnownCosmetic(cosmeticId))
            then
                state.entitlements[cosmeticId] = true
            end
        end
    end
    if type(value.processed) == "table" then
        for purchaseId, at in value.processed do
            if validId(purchaseId) and finite(at) and at >= 0 then
                state.processed[purchaseId] = at
            end
        end
    end
    if type(value.equipped) == "table" then
        for slot, cosmeticId in value.equipped do
            --[[
                Worn implies owned, on the way back in as well as on the way
                through `equip`. A slot pointing at something this profile does
                not own is a free cosmetic for anyone who can write a save
                field, and it is also the state a refund leaves behind -- both
                arrive here, and both are dropped rather than drawn.
            ]]
            if
                validId(slot)
                and validId(cosmeticId)
                and state.entitlements[cosmeticId] == true
                and (isKnownCosmetic == nil or isKnownCosmetic(cosmeticId))
            then
                state.equipped[slot] = cosmeticId
            end
        end
    end
    return state
end

function Entitlements.owns(state: any, cosmeticId: any): boolean
    if type(state) ~= "table" or type(state.entitlements) ~= "table" then
        return false
    end
    return type(cosmeticId) == "string" and state.entitlements[cosmeticId] == true
end

function Entitlements.equippedIn(state: any, slot: any): string?
    if type(state) ~= "table" or type(state.equipped) ~= "table" then
        return nil
    end
    if type(slot) ~= "string" then
        return nil
    end
    return state.equipped[slot]
end

--[[
    Apply one receipt.

    `resolve` turns a product id into the cosmetic ids it grants; the catalog
    supplies it rather than being required here, so this module knows what a
    grant *is* without knowing what is for sale.
]]
function Entitlements.apply(
    state: any,
    receipt: any,
    resolve: (string) -> { string }
): (State, Result)
    local current = Entitlements.normalize(state)
    if
        type(receipt) ~= "table"
        or not validId(receipt.purchaseId)
        or not validId(receipt.productId)
    then
        return current,
            {
                applied = false,
                acknowledge = false,
                reason = "malformed_receipt",
                granted = {},
            }
    end

    if current.processed[receipt.purchaseId] ~= nil then
        -- Already ours. The platform is retrying because it never heard us the
        -- first time, and the honest answer is yes, we have it.
        return current,
            {
                applied = false,
                acknowledge = true,
                reason = "duplicate",
                granted = {},
            }
    end

    local granted = resolve(receipt.productId)
    if type(granted) ~= "table" or #granted == 0 then
        return current,
            {
                applied = false,
                acknowledge = false,
                reason = "unknown_product",
                granted = {},
            }
    end

    local at = if finite(receipt.at) and receipt.at >= 0 then receipt.at else 0
    local next: State = {
        entitlements = table.clone(current.entitlements),
        processed = table.clone(current.processed),
        equipped = table.clone(current.equipped),
    }
    local applied: { string } = {}
    for _, cosmeticId in granted do
        if validId(cosmeticId) then
            next.entitlements[cosmeticId] = true
            table.insert(applied, cosmeticId)
        end
    end
    if #applied == 0 then
        return current,
            {
                applied = false,
                acknowledge = false,
                reason = "unknown_product",
                granted = {},
            }
    end
    next.processed[receipt.purchaseId] = at
    return next,
        {
            applied = true,
            acknowledge = true,
            reason = "granted",
            granted = applied,
        }
end

--[[
    Wear one. Refused for a cosmetic that is not owned, and that refusal is the
    only place ownership is ever asked about outside the commerce seam -- which
    is what keeps gameplay branching on what is equipped rather than on what is
    owned.

    Unequipping is `nil`, and it is always allowed: a player who has stopped
    owning something (a refund, a removed product) must be able to take it off.
]]
function Entitlements.equip(
    state: any,
    slot: any,
    cosmeticId: any,
    slotOf: ((string) -> string?)?
): (State, Result)
    local current = Entitlements.normalize(state)
    if not validId(slot) then
        return current,
            { applied = false, acknowledge = false, reason = "unknown_slot", granted = {} }
    end
    if cosmeticId == nil then
        if current.equipped[slot] == nil then
            return current,
                { applied = false, acknowledge = false, reason = "nothing_worn", granted = {} }
        end
        local next: State = {
            entitlements = table.clone(current.entitlements),
            processed = table.clone(current.processed),
            equipped = table.clone(current.equipped),
        }
        next.equipped[slot] = nil
        return next, { applied = true, acknowledge = false, reason = "removed", granted = {} }
    end
    if not Entitlements.owns(current, cosmeticId) then
        return current, { applied = false, acknowledge = false, reason = "not_owned", granted = {} }
    end
    --[[
        A cosmetic goes in its own slot and no other. Without this an outfit
        could be worn as a lantern shell -- owned, so the ownership check
        passes -- and the appearance code would be asked to hang a coat on a
        lamp. The catalog answers where each one belongs; passing the resolver
        rather than requiring the catalog keeps this module ignorant of what is
        for sale, which is what lets the spec drive it with a stub.
    ]]
    if slotOf ~= nil and slotOf(cosmeticId) ~= slot then
        return current,
            { applied = false, acknowledge = false, reason = "wrong_slot", granted = {} }
    end
    if current.equipped[slot] == cosmeticId then
        return current,
            { applied = false, acknowledge = false, reason = "already_worn", granted = {} }
    end
    local next: State = {
        entitlements = table.clone(current.entitlements),
        processed = table.clone(current.processed),
        equipped = table.clone(current.equipped),
    }
    next.equipped[slot] = cosmeticId
    return next, { applied = true, acknowledge = false, reason = "equipped", granted = {} }
end

--[[
    The mailbox: receipts held for a profile that was not available.

    A plain list, because it is written by a server that may not be the one
    that drains it and the simplest durable shape is the one least able to go
    wrong. Enqueuing a purchase id already held is a no-op for the same reason
    applying one already processed is: the platform retries.
]]
function Entitlements.emptyMailbox(): { Receipt }
    return {}
end

function Entitlements.normalizeMailbox(value: any): { Receipt }
    local mailbox: { Receipt } = {}
    if type(value) ~= "table" then
        return mailbox
    end
    local seen: { [string]: boolean } = {}
    for _, entry in value do
        if
            type(entry) == "table"
            and validId(entry.purchaseId)
            and validId(entry.productId)
            and not seen[entry.purchaseId]
            and #mailbox < MAX_MAILBOX
        then
            seen[entry.purchaseId] = true
            table.insert(mailbox, {
                purchaseId = entry.purchaseId,
                productId = entry.productId,
                at = if finite(entry.at) and entry.at >= 0 then entry.at else 0,
            })
        end
    end
    return mailbox
end

function Entitlements.enqueue(mailbox: any, receipt: any): ({ Receipt }, boolean)
    local current = Entitlements.normalizeMailbox(mailbox)
    if
        type(receipt) ~= "table"
        or not validId(receipt.purchaseId)
        or not validId(receipt.productId)
    then
        return current, false
    end
    for _, held in current do
        if held.purchaseId == receipt.purchaseId then
            return current, false
        end
    end
    if #current >= MAX_MAILBOX then
        return current, false
    end
    local next = table.clone(current)
    table.insert(next, {
        purchaseId = receipt.purchaseId,
        productId = receipt.productId,
        at = if finite(receipt.at) and receipt.at >= 0 then receipt.at else 0,
    })
    return next, true
end

--[[
    Drain the mailbox into a profile's commerce state.

    A receipt this build cannot resolve stays in the mailbox rather than being
    dropped, for the same reason `apply` refuses to acknowledge it: the product
    may exist in the next build, and a purchase quietly discarded is a support
    ticket nobody can answer.
]]
function Entitlements.drain(
    state: any,
    mailbox: any,
    resolve: (string) -> { string }
): (State, { Receipt }, { string })
    local current = Entitlements.normalize(state)
    local held = Entitlements.normalizeMailbox(mailbox)
    local remaining: { Receipt } = {}
    local granted: { string } = {}
    for _, receipt in held do
        local next, result = Entitlements.apply(current, receipt, resolve)
        current = next
        if result.acknowledge then
            for _, cosmeticId in result.granted do
                table.insert(granted, cosmeticId)
            end
        else
            table.insert(remaining, receipt)
        end
    end
    return current, remaining, granted
end

return table.freeze(Entitlements)
