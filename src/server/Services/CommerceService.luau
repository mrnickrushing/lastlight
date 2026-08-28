--!strict

--[[
    The only module in this game that touches a purchase or ownership API.

    `scripts/validate_monetization.py` allows exactly one, by name, and its
    docstring says why the list is meant to stay short and to be read: a branch
    on "does this player own X" is how a cosmetic quietly becomes a
    requirement. So the shape of this file is the whole architecture:

      * **It answers one question and writes down the answer.** What a player
        owns is resolved here, once, and lands in `profile.commerce` as plain
        data. Nothing downstream asks the platform anything, and nothing
        downstream asks *this* anything either -- gameplay branches on what is
        equipped, which is a profile field like every other.
      * **The refusal to wear something unowned lives here**, not where
        cosmetics are drawn. The drawing code takes an id and draws it. That
        keeps the ownership question in one file and out of the HUD, the gear
        visuals, and everything else.
      * **Every decision it makes is somewhere else.** `Entitlements.route` is
        pure and holds the branch a receipt takes; this is the shell that gives
        it a profile, a mailbox and a durable write. `ProcessReceipt` cannot be
        exercised in Studio -- the round trip needs a real purchase on a real
        account -- so anything that decides has to be decidable without it.

    **A receipt is acknowledged only after a durable write**, and that is the
    rule everything else here bends around. Roblox retries until it is told the
    grant is durable, so telling it early loses a purchase and telling it late
    costs nothing but a retry. Two things count as durable: the buyer's profile
    saved, or -- when this server does not hold that profile -- the mailbox
    saved. A mailbox entry is a promise the next load will keep, and it is
    stored outside the profile precisely because its reason for existing is the
    moments when the profile is not ours to write.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CommerceService = {}
CommerceService.__index = CommerceService
CommerceService.Name = "CommerceService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
    warn: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type CommerceService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _config: any,
        _catalog: any,
        _entitlements: any,
        _storeCard: any,
        _profileService: any,
        _featureFlags: any,
        _analyticsService: any,
        _persistent: boolean,
        _mailboxStore: any,
        --[[
            Mailboxes for servers with no DataStore -- Studio, and any
            environment running without persistence. In memory, which is the
            same honest limitation the profile store has there: nothing
            survives the session, and nothing pretends to.
        ]]
        _localMailboxes: { [number]: { any } },
        _productInfo: { [string]: any },
        --[[
            When a product info lookup last failed, so a delisted or erroring
            product is not re-asked on every snapshot build. `storeSnapshot`
            runs on every push for every player and `GetProductInfo` is a
            throttled web call: retrying it there turns one broken product into
            a rate limit for all of them.
        ]]
        _productInfoFailedAt: { [string]: number },
        --[[
            Purchases already counted as lost, so one stuck receipt is one
            event rather than one per redelivery. The platform retries an
            unconsumed receipt for the life of the purchase, and a
            zero-tolerance gate that reads a count would grow without a second
            player being affected. Bounded in practice by how many purchases
            can go wrong on one server, which is the number the gate is asking
            about anyway.
        ]]
        _reportedLoss: { [string]: boolean },
        _onGranted: ((Player, { string }) -> ())?,
    },
    CommerceService
))

local MAILBOX_STORE = "LastLightCommerceMailbox_v1"
local PRODUCT_INFO_RETRY_SECONDS = 60

function CommerceService.new(
    logger: Logger,
    config: any,
    cosmeticCatalog: any,
    entitlements: any,
    storeCard: any,
    profileService: any,
    featureFlags: any,
    analyticsService: any
): CommerceService
    return setmetatable({
        Name = CommerceService.Name,
        _logger = logger,
        _config = config,
        _catalog = cosmeticCatalog,
        _entitlements = entitlements,
        _storeCard = storeCard,
        _profileService = profileService,
        _featureFlags = featureFlags,
        _analyticsService = analyticsService,
        _persistent = false,
        _mailboxStore = nil,
        _localMailboxes = {},
        _productInfo = {},
        _productInfoFailedAt = {},
        _reportedLoss = {},
        _onGranted = nil,
    }, CommerceService)
end

function CommerceService.Init(self: CommerceService, context: any)
    local environmentConfig = context.config.Environments[context.environment]
    self._persistent = environmentConfig ~= nil and environmentConfig.UsePersistentData == true
    if self._persistent then
        local DataStoreService = game:GetService("DataStoreService")
        local ok, store = pcall(function()
            return DataStoreService:GetDataStore(MAILBOX_STORE)
        end)
        if ok then
            self._mailboxStore = store
        else
            self._logger:warn("commerce_mailbox_unavailable", { reason = tostring(store) })
        end
    end
end

function CommerceService.setGrantHandler(self: CommerceService, handler: (Player, { string }) -> ())
    self._onGranted = handler
end

local function mailboxKey(userId: number): string
    return string.format("mailbox_%d", userId)
end

function CommerceService._readMailbox(self: CommerceService, userId: number): { any }
    if not self._persistent or self._mailboxStore == nil then
        return self._entitlements.normalizeMailbox(self._localMailboxes[userId])
    end
    local ok, value = pcall(function()
        return self._mailboxStore:GetAsync(mailboxKey(userId))
    end)
    if not ok then
        self._logger:warn("commerce_mailbox_read_failed", { user = userId })
        return self._entitlements.emptyMailbox()
    end
    return self._entitlements.normalizeMailbox(value)
end

--[[
    Rewrite a mailbox from whatever is stored right now, and say whether it
    landed.

    UpdateAsync rather than a read then a SetAsync. A receipt is retried until
    it is acknowledged, and those retries can reach a different server than the
    one draining the same mailbox -- so two servers can hold the same key, and
    with a plain read-then-write whichever writes second erases the other's
    change. That is a purchase the player has already paid for. UpdateAsync
    hands the transform the value it just read and retries on conflict, so the
    merge happens against current data instead of a stale copy.

    The transform must be pure: DataStore may call it more than once.

    The boolean is load-bearing: it is the difference between telling the
    platform the purchase is safe and telling it to call again. A failed write
    must never read as success.
]]
function CommerceService._updateMailbox(
    self: CommerceService,
    userId: number,
    transform: ({ any }) -> { any }
): boolean
    if not self._persistent or self._mailboxStore == nil then
        local current = self._entitlements.normalizeMailbox(self._localMailboxes[userId])
        self._localMailboxes[userId] = transform(current)
        return true
    end
    local ok, err = pcall(function()
        self._mailboxStore:UpdateAsync(mailboxKey(userId), function(stored: any): { any }
            return transform(self._entitlements.normalizeMailbox(stored))
        end)
    end)
    if not ok then
        self._logger:warn(
            "commerce_mailbox_write_failed",
            { reason = tostring(err), user = userId }
        )
    end
    return ok
end

--[[
    The buyer's commerce state, if this server holds their profile and may
    write it. Nil is a real answer and means "not ours": they are in another
    server, or mid-load, or their profile is read-only because a lock could not
    be taken. Writing anyway is how two servers overwrite one save.
]]
function CommerceService._writableState(self: CommerceService, userId: number): (Player?, any)
    local player = Players:GetPlayerByUserId(userId)
    if player == nil then
        return nil, nil
    end
    if not self._profileService:isLoaded(player) or not self._profileService:isWritable(player) then
        return player, nil
    end
    return player, self._profileService:commerce(player)
end

--[[
    Apply one receipt. The single grant authority in the game.
]]
function CommerceService.applyReceipt(self: CommerceService, receipt: any): boolean
    local userId = tonumber(receipt.userId) or 0
    local player, state = self:_writableState(userId)
    local mailbox = self:_readMailbox(userId)
    -- Measured from when the platform handed the receipt over, not from now.
    -- The gate asks how long a purchase took to become durable, and the wait
    -- in a mailbox while the buyer was in another server is the part of that
    -- wait a player would actually recognise.
    local elapsed = math.max(0, os.time() - (tonumber(receipt.at) or os.time()))

    --[[
        A receipt for something this build cannot resolve.

        Never consumed, correctly -- a later build may know the product, and
        telling the platform a purchase is settled when nothing was granted is
        the one mistake that cannot be undone. But an unconsumed receipt is
        also a player who has paid and holds nothing, retried forever, and
        that is the zero-tolerance case rather than the healthy retry that
        `receipt_result` counts.
    ]]
    -- GATE-METRIC: purchase_loss
    local purchaseKey = tostring(receipt.purchaseId)
    if
        (type(receipt.productId) ~= "string" or #self._catalog.grantsOf(receipt.productId) == 0)
        and not self._reportedLoss[purchaseKey]
    then
        self._reportedLoss[purchaseKey] = true
        self._analyticsService:purchaseLoss(
            userId,
            tostring(receipt.productId),
            "unresolvable_product"
        )
    end
    local nextState, _nextMailbox, verdict = self._entitlements.route(
        state,
        mailbox,
        receipt,
        function(productId: string): { string }
            return self._catalog.grantsOf(productId)
        end
    )

    if verdict == "granted" and player ~= nil and nextState ~= nil then
        self._profileService:setCommerce(player, nextState)
        -- The write, then the answer. Reversing these is the one ordering
        -- mistake that costs a player a purchase they paid for.
        if not self._profileService:save(player) then
            self._logger:warn("commerce_grant_write_failed", { user = userId })
            -- The entitlement was decided and could not be made durable. The
            -- platform will call again, but until one of those calls lands
            -- this is a completed receipt with no grant behind it.
            -- Counted once per purchase for the same reason as above: the
            -- retry is the system working, and a gate that counts retries
            -- reads one stuck receipt as a growing incident.
            if not self._reportedLoss[purchaseKey] then
                self._reportedLoss[purchaseKey] = true
                self._analyticsService:purchaseLoss(
                    userId,
                    tostring(receipt.productId),
                    "grant_write_failed"
                )
            end
            return false
        end
        local granted = self._catalog.grantsOf(receipt.productId)
        self._logger:info("commerce_receipt_granted", {
            product = tostring(receipt.productId),
            purchase = tostring(receipt.purchaseId),
            user = userId,
        })
        -- GATE-METRIC: receipt_result
        -- COMMERCE-EVENT: receipt_result
        self._analyticsService:receiptResult(
            userId,
            tostring(receipt.productId),
            "granted",
            elapsed,
            player
        )
        local handler = self._onGranted
        if handler ~= nil then
            handler(player, granted)
        end
        return true
    end

    if verdict == "held" then
        -- Routed again inside the update against the mailbox the store just
        -- handed back, rather than writing the copy computed from the read
        -- above. `route` is pure, so re-running it merges this receipt into
        -- whatever another server has parked meanwhile instead of erasing it.
        local held = self:_updateMailbox(userId, function(stored: { any }): { any }
            local _, merged = self._entitlements.route(
                state,
                stored,
                receipt,
                function(productId: string): { string }
                    return self._catalog.grantsOf(productId)
                end
            )
            return merged
        end)
        if not held then
            return false
        end
        self._logger:info("commerce_receipt_held", {
            product = tostring(receipt.productId),
            purchase = tostring(receipt.purchaseId),
            user = userId,
        })
        -- A held receipt is durable -- the mailbox saved, which is what this
        -- branch just proved -- so it settles the commerce gate exactly as a
        -- grant does. Leaving it out would make "100% of completed receipts
        -- reach a durable grant" unreadable for every purchase made while its
        -- buyer was in another server, which is the case the mailbox exists
        -- for and therefore the case the gate most needs to see.
        self._analyticsService:receiptResult(
            userId,
            tostring(receipt.productId),
            "held",
            elapsed,
            player
        )
        return true
    end

    self._logger:warn("commerce_receipt_retry", {
        product = tostring(receipt.productId),
        purchase = tostring(receipt.purchaseId),
        user = userId,
    })
    self._analyticsService:receiptResult(
        userId,
        tostring(receipt.productId),
        "retry",
        elapsed,
        player
    )
    return false
end

--[[
    Drain whatever was banked while this player was elsewhere.

    Run at profile load. A receipt this build still cannot resolve stays in the
    mailbox rather than being dropped, because the product may exist in the
    next build and a purchase quietly discarded is a support ticket nobody can
    answer.
]]
function CommerceService.drainFor(self: CommerceService, player: Player)
    local mailbox = self:_readMailbox(player.UserId)
    if #mailbox == 0 then
        return
    end
    if not self._profileService:isWritable(player) then
        return
    end
    local state, remaining, granted = self._entitlements.drain(
        self._profileService:commerce(player),
        mailbox,
        function(productId: string): { string }
            return self._catalog.grantsOf(productId)
        end
    )
    if #granted == 0 then
        return
    end
    self._profileService:setCommerce(player, state)
    if not self._profileService:save(player) then
        -- The mailbox is left exactly as it was. Clearing it before the
        -- profile is safe is the one way a drained purchase disappears.
        self._logger:warn("commerce_drain_write_failed", { user = player.UserId })
        return
    end
    -- Remove exactly the receipts this drain consumed, keeping anything a
    -- concurrent server parked between the read above and this write.
    self:_updateMailbox(player.UserId, function(stored: { any }): { any }
        local consumed: { [string]: boolean } = {}
        for _, receipt in mailbox do
            consumed[tostring(receipt.purchaseId)] = true
        end
        for _, receipt in remaining do
            consumed[tostring(receipt.purchaseId)] = nil
        end
        local merged = table.clone(remaining)
        local present: { [string]: boolean } = {}
        for _, receipt in merged do
            present[tostring(receipt.purchaseId)] = true
        end
        for _, receipt in stored do
            local purchaseId = tostring(receipt.purchaseId)
            if not consumed[purchaseId] and not present[purchaseId] then
                present[purchaseId] = true
                table.insert(merged, receipt)
            end
        end
        return merged
    end)
    self._logger:info("commerce_mailbox_drained", {
        granted = #granted,
        remaining = #remaining,
        user = player.UserId,
    })
    local handler = self._onGranted
    if handler ~= nil then
        handler(player, granted)
    end
end

--[[
    Wear one. The single place ownership is asked about outside a receipt, and
    therefore the reason no gameplay module ever has to.
]]
function CommerceService.equip(
    self: CommerceService,
    player: Player,
    slot: any,
    cosmeticId: any
): any
    if not self._profileService:isLoaded(player) then
        return { applied = false, reason = "profile_loading" }
    end
    local state, result = self._entitlements.equip(
        self._profileService:commerce(player),
        slot,
        cosmeticId,
        function(id: string): string?
            local cosmetic = self._catalog.get(id)
            return if cosmetic == nil then nil else cosmetic.slot
        end
    )
    if result.applied then
        self._profileService:setCommerce(player, state)
        if cosmeticId ~= nil then
            -- COMMERCE-EVENT: cosmetic_equipped
            self._analyticsService:cosmeticEquipped(player, tostring(cosmeticId), tostring(slot))
        end
    end
    return result
end

--[[
    Wear one, named only by the cosmetic.

    The slot comes from the catalog rather than from the caller, which is the
    only version of it worth trusting: a client that could name a slot could
    name the wrong one, and #331's review found exactly that hole on the layer
    below. Pressing something already worn takes it off, so removal needs no
    second field and no second action -- the toggle is what keeps the payload
    at one id.
]]
function CommerceService.equipById(self: CommerceService, player: Player, cosmeticId: any): any
    if not self._profileService:isLoaded(player) then
        return { applied = false, reason = "profile_loading" }
    end
    local cosmetic = self._catalog.get(cosmeticId)
    if cosmetic == nil then
        return { applied = false, reason = "unknown_cosmetic" }
    end
    local state = self._profileService:commerce(player)
    if self._entitlements.equippedIn(state, cosmetic.slot) == cosmetic.id then
        return self:equip(player, cosmetic.slot, nil)
    end
    return self:equip(player, cosmetic.slot, cosmetic.id)
end

--[[
    One card looked at. Nothing is decided here and nothing is returned,
    because a detail view changes nothing -- it is a fact the monetization
    taxonomy asks for by name, and an event with no emitter is a dashboard
    reading nothing.
]]
function CommerceService.viewDetail(self: CommerceService, player: Player, productId: any): boolean
    local product = self._catalog.product(productId)
    if product == nil then
        return false
    end
    -- COMMERCE-EVENT: product_detail_view
    self._analyticsService:productDetailView(player, product.id)
    return true
end

--[[
    The shelf and the wardrobe, built for one player.

    Two lists rather than one, and the reason is the failure this project has
    now paid for four times. A sale card needs a price and a product; a thing
    already owned needs neither. If owned cosmetics were shown only through
    their sale cards, a product delisted in the dashboard -- or a
    `GetProductInfo` call that simply failed -- would make a paid-for coat
    unwearable, which is an entitlement that exists and a cosmetic that cannot
    be worn.

    Every card is built by the shared builder, which refuses to make one
    without a price, a permanence, an owned state and real geometry. A product
    with no dashboard id yields no card at all rather than a card with a blank
    where the price goes.
]]
function CommerceService.storeSnapshot(self: CommerceService, player: Player): any
    if not self._profileService:isLoaded(player) then
        return nil
    end
    local state = self._profileService:commerce(player)
    local cards = {}
    local unpriced = 0
    for _, product in self._catalog.products() do
        local granted = product.grants
        local preview = {}
        local owned = #granted > 0
        local equipped = #granted > 0
        for _, cosmeticId in granted do
            local cosmetic = self._catalog.get(cosmeticId)
            if cosmetic == nil then
                owned = false
                equipped = false
            else
                for _, plan in cosmetic.parts do
                    table.insert(preview, plan)
                end
                if not self._entitlements.owns(state, cosmetic.id) then
                    owned = false
                end
                if self._entitlements.equippedIn(state, cosmetic.slot) ~= cosmetic.id then
                    equipped = false
                end
            end
        end
        local info = self:productInfo(product.id)
        local card, reason = self._storeCard.build(product, {
            priceInRobux = if info == nil then nil else info.priceInRobux,
            owned = owned,
            equipped = equipped,
            preview = preview,
        })
        if card ~= nil then
            table.insert(cards, card)
        elseif reason == "no_price" then
            unpriced += 1
        else
            -- Anything but a missing price is a catalog fault rather than a
            -- dashboard one, and it is worth a line: the card is gone and no
            -- spec would notice a product quietly disappearing from a shelf.
            self._logger:warn("commerce_card_refused", { product = product.id, reason = reason })
        end
    end

    local wardrobe = {}
    for _, cosmetic in self._catalog.list() do
        if self._entitlements.owns(state, cosmetic.id) then
            local row = self._storeCard.wardrobeRow(
                cosmetic,
                self._entitlements.equippedIn(state, cosmetic.slot) == cosmetic.id
            )
            if row ~= nil then
                table.insert(wardrobe, row)
            end
        end
    end

    return {
        enabled = self._featureFlags:isEnabled("cosmetic_store_enabled"),
        cards = cards,
        wardrobe = wardrobe,
        unpricedProducts = unpriced,
        assurance = self._storeCard.assurance(),
    }
end

--[[
    Somebody opened the store. Counted where it happened rather than where it
    was drawn: a client-side count of store views is a count a client decides.
]]
function CommerceService.recordStoreView(self: CommerceService, player: Player, cardCount: number)
    -- COMMERCE-EVENT: store_view
    self._analyticsService:storeView(player, cardCount)
end

--[[
    What a client may be told: what is worn, and what is owned.

    Owned reaches the client because the store card has to show it -- a card
    that cannot say "you already have this" sells a player the same thing
    twice. It is a list of ids and nothing else; no price, no receipt, no
    entitlement machinery.
]]
function CommerceService.snapshot(self: CommerceService, player: Player): any
    if not self._profileService:isLoaded(player) then
        return nil
    end
    local state = self._profileService:commerce(player)
    local owned: { string } = {}
    for _, cosmetic in self._catalog.list() do
        if self._entitlements.owns(state, cosmetic.id) then
            table.insert(owned, cosmetic.id)
        end
    end
    table.sort(owned)
    return {
        enabled = self._featureFlags:isEnabled("cosmetic_store_enabled"),
        owned = owned,
        equipped = state.equipped,
    }
end

--[[
    The Robux price, read from the platform rather than from a constant.

    A price in the source is a price that is wrong the first time the owner
    changes it in the dashboard, and a card showing the wrong number is worse
    than a card showing none. Cached per product for the life of the server:
    prices do not change mid-session, and `GetProductInfo` is a web call.
]]
function CommerceService.productInfo(self: CommerceService, productId: any): any
    if type(productId) ~= "string" then
        return nil
    end
    local cached = self._productInfo[productId]
    if cached ~= nil then
        return cached
    end
    local robloxId = self._config.CommerceProductIds[productId]
    if type(robloxId) ~= "number" then
        return nil
    end
    -- A failure is remembered for a minute. Long enough that a bad product
    -- costs one call rather than one per push; short enough that a dashboard
    -- fix takes effect without a server restart.
    local failedAt = self._productInfoFailedAt[productId]
    if failedAt ~= nil and os.time() - failedAt < PRODUCT_INFO_RETRY_SECONDS then
        return nil
    end
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(robloxId, Enum.InfoType.Product)
    end)
    if not ok or type(info) ~= "table" then
        self._productInfoFailedAt[productId] = os.time()
        self._logger:warn("commerce_product_info_failed", { product = productId })
        return nil
    end
    self._productInfoFailedAt[productId] = nil
    local resolved = {
        priceInRobux = tonumber(info.PriceInRobux) or 0,
        name = tostring(info.Name or ""),
    }
    self._productInfo[productId] = resolved
    return resolved
end

function CommerceService.promptPurchase(self: CommerceService, player: Player, productId: any): any
    if not self._featureFlags:isEnabled("cosmetic_store_enabled") then
        return { accepted = false, reason = "store_closed" }
    end
    local product = self._catalog.product(productId)
    if product == nil then
        return { accepted = false, reason = "unknown_product" }
    end
    local robloxId = self._config.CommerceProductIds[product.id]
    if type(robloxId) ~= "number" then
        --[[
            The dashboard half does not exist yet. Refused with a reason rather
            than prompting into nothing, which on a client looks like the button
            being broken -- and counted, which is the part a live pass found
            missing.

            Returning here without emitting meant a player pressing BUY on a
            product nobody had configured produced no telemetry at all. That is
            the exact shape this wave's spec exists to catch one level up: a
            dashboard reading nothing, indistinguishable from a store nobody
            opened, in the one case where somebody did press the button.
        ]]
        -- COMMERCE-EVENT: purchase_prompt
        self._analyticsService:purchasePrompt(player, product.id, false)
        return { accepted = false, reason = "product_not_configured" }
    end
    local ok = pcall(function()
        MarketplaceService:PromptProductPurchase(player, robloxId)
    end)
    self._analyticsService:purchasePrompt(player, product.id, ok)
    return { accepted = ok, reason = if ok then "prompted" else "prompt_failed" }
end

function CommerceService.Start(self: CommerceService)
    --[[
        The platform's own entry point, and the only one. Wrapped so an error
        anywhere inside becomes NotProcessedYet rather than an unhandled throw
        -- a throw is read by the platform as "no answer", which is the same as
        a retry, but it loses the log line that says why.
    ]]
    MarketplaceService.ProcessReceipt = function(receiptInfo: any): Enum.ProductPurchaseDecision
        local ok, granted = pcall(function(): boolean
            return self:applyReceipt({
                purchaseId = tostring(receiptInfo.PurchaseId),
                productId = self:_productIdFor(receiptInfo.ProductId),
                userId = receiptInfo.PlayerId,
                at = os.time(),
            })
        end)
        if not ok then
            self._logger:warn("commerce_receipt_error", { reason = tostring(granted) })
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
        return if granted
            then Enum.ProductPurchaseDecision.PurchaseGranted
            else Enum.ProductPurchaseDecision.NotProcessedYet
    end

    --[[
        What the platform's own prompt came back as.

        "Canceled prompts produce no receipt and no grant" is a gate about
        something not happening, and the only way to check that a cancel
        produced nothing is to know a cancel happened. Without this the metric
        is the absence of an event, which reads exactly the same as the store
        being shut.
    ]]
    -- GATE-METRIC: purchase_platform_result
    -- COMMERCE-EVENT: purchase_platform_result
    MarketplaceService.PromptProductPurchaseFinished:Connect(
        function(userId: number, robloxProductId: number, purchased: boolean)
            self._analyticsService:purchasePlatformResult(
                userId,
                self:_productIdFor(robloxProductId),
                purchased
            )
        end
    )

    self._profileService:onLoaded(function(player: Player, _profile: any)
        task.spawn(function()
            self:drainFor(player)
        end)
    end)

    self:_watchStudioStore()

    self._logger:info("commerce_started", {
        configured = self:_configuredCount(),
        products = #self._catalog.products(),
        storeEnabled = self._featureFlags:isEnabled("cosmetic_store_enabled"),
    })
end

--[[
    The Studio half of a surface whose real half needs a Creator Dashboard.

    Everything about the store that a camera can judge -- the panel on a
    portrait canvas, a card's price line, the owned state, the wardrobe, the
    preview of a cosmetic's own geometry -- is invisible until a product has a
    price, and a product has no price until somebody creates it in the
    dashboard and pastes the number into `Config.CommerceProductIds`. That is
    the owner's, and it is not going to happen before this ships.

    The failure that leaves behind is written down elsewhere in this codebase
    in as many words: a live pass went to look at two rewritten HUD surfaces,
    found both correctly empty, and ended knowing nothing. `LastLightSkipTutorial`
    and `LastLightStockProfile` exist because of that pass. These two are the
    same tool pointed at the store.

    **Neither one grants anything the real path would not.** A price is a
    number to draw, not a product id -- `promptPurchase` still refuses with
    `product_not_configured`, because a dashboard product genuinely does not
    exist. And a grant goes through `applyReceipt`, the single grant authority,
    with a synthetic receipt: the platform's own `ProcessReceipt` cannot be
    driven in Studio, and feeding the real handler a receipt is the closest
    honest thing to it. Studio only, on both, and logged loudly every time.
]]
function CommerceService._watchStudioStore(self: CommerceService)
    if not RunService:IsStudio() then
        return
    end

    local function applyPrice()
        local price = tonumber(game:GetAttribute("LastLightStudioStore"))
        if price == nil or price <= 0 then
            return
        end
        self._featureFlags:setOverride("cosmetic_store_enabled", true)
        for _, product in self._catalog.products() do
            self._productInfo[product.id] =
                { priceInRobux = math.floor(price), name = product.displayName }
        end
        self._logger:warn("studio_store_priced", {
            price = math.floor(price),
            products = #self._catalog.products(),
        })
    end

    local function applyGrant()
        local productId = game:GetAttribute("LastLightStudioGrant")
        if type(productId) ~= "string" or #productId == 0 then
            return
        end
        for _, player in Players:GetPlayers() do
            self:applyReceipt({
                purchaseId = string.format("studio_%s_%d", productId, player.UserId),
                productId = productId,
                userId = player.UserId,
                at = os.time(),
            })
        end
        self._logger:warn("studio_store_granted", { product = productId })
    end

    --[[
        Isolated, because these run inside Start. A Studio helper that throws
        would take the rest of commerce startup with it, and the whole point of
        these two is that they are scaffolding: they may not be able to break
        the thing they exist to look at.
    ]]
    for name, apply in { LastLightStudioStore = applyPrice, LastLightStudioGrant = applyGrant } do
        local ok, err = pcall(apply)
        if not ok then
            self._logger:warn("studio_store_hook_failed", { hook = name, reason = tostring(err) })
        end
        game:GetAttributeChangedSignal(name):Connect(function()
            local applied, failure = pcall(apply)
            if not applied then
                self._logger:warn(
                    "studio_store_hook_failed",
                    { hook = name, reason = tostring(failure) }
                )
            end
        end)
    end
end

-- The dashboard number back to this game's own product id. A receipt names
-- Roblox's id; everything here names ours.
function CommerceService._productIdFor(self: CommerceService, robloxProductId: any): string
    for productId, configured in self._config.CommerceProductIds do
        if configured == robloxProductId then
            return productId
        end
    end
    return ""
end

function CommerceService._configuredCount(self: CommerceService): number
    local count = 0
    for _ in self._config.CommerceProductIds do
        count += 1
    end
    return count
end

return table.freeze(CommerceService)
