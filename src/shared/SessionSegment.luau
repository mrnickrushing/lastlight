--!strict

--[[
    The two slices every per-segment release gate is read on.

    RELEASE_GATES.md sets a second, looser threshold for every reliability and
    comprehension gate and then says who it applies to: "each advertised
    platform class -- phone, tablet, desktop, and console" and "each supported
    device/performance segment". A threshold that can only be read across the
    whole population is half a gate, because the whole population is exactly
    where a phone-only failure hides.

    So a session carries two labels, and both are decided here:

      * **platform class** is what the player is holding. It is a client fact
        and nothing else can know it -- a server sees a userId and a network
        connection, not a screen. It arrives over the telemetry remote as one
        of four bounded words and is never trusted for anything but a label; no
        rule, reward or refusal in this game reads it.
      * **performance tier** is how well that device is actually running,
        taken from the frame rate the client reports. Two phones are not one
        segment: the gate that matters is whether the game is playable on the
        slow half of them, and averaging the slow half into the fast half is
        the arithmetic that hides it.

    Pure and free of Roblox datatypes, because the Lune runner has none: the
    caller passes booleans and numbers and gets a word back.
]]

local SessionSegment = {}

-- The four classes RELEASE_GATES.md advertises, plus the honest fifth. A
-- session whose client has not introduced itself yet is `unknown` rather than
-- being guessed into `desktop`, which is the class it would be assumed into by
-- a "has a keyboard" test run against no data at all.
local PLATFORMS = table.freeze({
    console = true,
    desktop = true,
    phone = true,
    tablet = true,
    unknown = true,
})

local TIERS = table.freeze({
    high = true,
    low = true,
    mid = true,
    unknown = true,
})

-- Where a touch screen stops being a phone. Measured on the shorter edge in
-- points, because a phone held sideways is still a phone; 600 is the width at
-- which the HUD's portrait rules stop applying and is therefore the same line
-- the layout already draws.
local TABLET_MIN_SHORT_EDGE = 600

function SessionSegment.isValidPlatform(value: any): boolean
    return type(value) == "string" and PLATFORMS[value] == true
end

function SessionSegment.isValidTier(value: any): boolean
    return type(value) == "string" and TIERS[value] == true
end

--[[
    What the player is holding, from what the client can see about itself.

    Order matters. A console reports a ten-foot interface and also a gamepad; a
    Windows tablet reports touch and a keyboard. The first question is always
    the most specific one, so a device that answers yes to two tests is filed
    under the narrower.
]]
function SessionSegment.platformClass(
    tenFootInterface: boolean,
    touchEnabled: boolean,
    keyboardEnabled: boolean,
    viewportWidth: number,
    viewportHeight: number
): string
    if tenFootInterface then
        return "console"
    end
    if not touchEnabled then
        return "desktop"
    end
    -- A touch screen with a keyboard attached is a laptop or a Windows tablet
    -- being used as one. It is filed by its screen rather than its keyboard,
    -- because the reach and safe-area problems the mobile gates exist for are
    -- a property of the screen.
    if
        viewportWidth <= 0
        or viewportHeight <= 0
        or viewportWidth ~= viewportWidth
        or viewportHeight ~= viewportHeight
    then
        return if keyboardEnabled then "desktop" else "unknown"
    end
    local shortEdge = math.min(viewportWidth, viewportHeight)
    if shortEdge >= TABLET_MIN_SHORT_EDGE then
        return "tablet"
    end
    return "phone"
end

--[[
    How well it is running, from the frame rate the client reported.

    The boundaries are the two numbers the performance budget already treats as
    meaningful -- 30 is the floor a session is expected to hold and 50 is
    comfortably above it -- so a tier cannot disagree with a budget verdict
    about the same device.
]]
function SessionSegment.tier(fps: any): string
    if type(fps) ~= "number" or fps ~= fps or fps <= 0 then
        return "unknown"
    end
    if fps >= 50 then
        return "high"
    end
    if fps >= 30 then
        return "mid"
    end
    return "low"
end

-- The device/performance segment as one word, which is the unit the sample
-- minimum is counted in: "each supported device/performance segment needs at
-- least 50 first-session samples".
function SessionSegment.id(platform: any, tier: any): string
    local resolvedPlatform = if SessionSegment.isValidPlatform(platform)
        then platform
        else "unknown"
    local resolvedTier = if SessionSegment.isValidTier(tier) then tier else "unknown"
    return resolvedPlatform .. "/" .. resolvedTier
end

--[[
    The platform a telemetry payload claims, or nil.

    Read separately from the frame samples because it arrives separately: a
    client says what it is on its first frame and does not have a frame rate
    to report for another five seconds. A session that ends inside those five
    seconds is precisely the session the join and crash gates are about, so its
    platform has to be known before its first sample rather than with it.
]]
function SessionSegment.platformOf(payload: any): string?
    if type(payload) ~= "table" then
        return nil
    end
    local platform = payload.platform
    if not SessionSegment.isValidPlatform(platform) or platform == "unknown" then
        return nil
    end
    return platform
end

return table.freeze(SessionSegment)
