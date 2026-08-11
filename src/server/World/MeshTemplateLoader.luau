--!strict

local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")

local MeshAssetRegistry = require(script.Parent.MeshAssetRegistry)
local MeshMaterialPlan = require(script.Parent.MeshMaterialPlan)

local MeshTemplateLoader = {}
MeshTemplateLoader.__index = MeshTemplateLoader

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type MeshTemplateLoader = typeof(setmetatable(
    {} :: {
        _logger: Logger,
        _templates: { [string]: Model },
        _templateScale: { [string]: number },
        _failed: { [string]: boolean },
        _permanentFailure: { [string]: boolean },
    },
    MeshTemplateLoader
))

type RestyleRule = { match: { number }, color: { number }?, material: string? }

local function matchesRestyleColor(color: Color3, match: { number }): boolean
    return math.abs(color.R * 255 - match[1]) <= 4
        and math.abs(color.G * 255 - match[2]) <= 4
        and math.abs(color.B * 255 - match[3]) <= 4
end

local function sanitize(
    model: Model,
    stripDecals: boolean,
    restyleParts: { RestyleRule }?
): (number, number)
    local meshParts = 0
    local baseParts = 0
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            baseParts += 1
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.CastShadow = true
            descendant.Massless = true
            if restyleParts ~= nil then
                for _, rule in restyleParts do
                    if matchesRestyleColor(descendant.Color, rule.match) then
                        if rule.color ~= nil and descendant:IsA("UnionOperation") then
                            descendant.UsePartColor = true
                        end
                        if rule.color ~= nil then
                            descendant.Color =
                                Color3.fromRGB(rule.color[1], rule.color[2], rule.color[3])
                        end
                        if rule.material ~= nil then
                            descendant.Material = (Enum.Material :: any)[rule.material]
                        end
                        break
                    end
                end
            end
            if descendant:IsA("MeshPart") then
                meshParts += 1
            end
        elseif
            descendant:IsA("LuaSourceContainer")
            or descendant:IsA("ProximityPrompt")
            or descendant:IsA("ClickDetector")
            or descendant:IsA("DragDetector")
            or descendant:IsA("LayerCollector")
            or descendant:IsA("GuiObject")
            or descendant:IsA("Camera")
            or descendant:IsA("ValueBase")
            or descendant:IsA("Constraint")
            or descendant:IsA("JointInstance")
            or descendant:IsA("Humanoid")
            or descendant:IsA("AnimationController")
            or descendant:IsA("Sound")
            or descendant:IsA("PostEffect")
            or descendant:IsA("BodyMover")
            or (stripDecals and (descendant:IsA("Decal") or descendant:IsA("Texture")))
        then
            descendant:Destroy()
        end
    end
    return meshParts, baseParts
end

local MAX_LOAD_ATTEMPTS = 3

local function longestDimension(size: Vector3): number
    return math.max(size.X, size.Y, size.Z)
end

local ROBLOX_MATERIALS = table.freeze({
    Grass = Enum.Material.Grass,
    Ground = Enum.Material.Ground,
    LeafyGrass = Enum.Material.LeafyGrass,
    Metal = Enum.Material.Metal,
    Neon = Enum.Material.Neon,
    Slate = Enum.Material.Slate,
    Wood = Enum.Material.Wood,
    WoodPlanks = Enum.Material.WoodPlanks,
})

local function applyBuiltInMaterials(
    model: Model,
    customPbr: boolean,
    preserveSourceMaterials: boolean
): (number, number)
    if customPbr or preserveSourceMaterials then
        return 0, 0
    end

    local styled = 0
    local unstyled = 0
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("MeshPart") then
            local style = MeshMaterialPlan.styleForPart(descendant.Name)
            if style == nil then
                unstyled += 1
            else
                local material = ROBLOX_MATERIALS[style.material]
                local color = style.color
                assert(material ~= nil, "unknown built-in mesh material " .. style.material)
                descendant.Material = material
                descendant.MaterialVariant = ""
                descendant.Color = Color3.fromRGB(color[1], color[2], color[3])
                for _, child in descendant:GetChildren() do
                    if child:IsA("SurfaceAppearance") then
                        child:Destroy()
                    end
                end
                styled += 1
            end
        end
    end
    return styled, unstyled
end

local function applyProfileScale(model: Model, profileScale: Vector3)
    if profileScale == Vector3.one then
        return
    end

    local pivot = model:GetPivot()
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            local relative = pivot:ToObjectSpace(descendant.CFrame)
            descendant.Size *= profileScale
            descendant.CFrame = pivot
                * CFrame.new(relative.Position * profileScale)
                * relative.Rotation
        end
    end
end

type PartOrientationFix = {
    matchSize: { number },
    localRotationDegrees: { number }?,
    copyOrientationFromSize: { number }?,
}

-- Sizes are compared with a small epsilon rather than exactly: they survive
-- the LoadAsset round-trip bit-for-bit in practice, but a Union's Size is
-- derived geometry and float noise on the order of 1e-5 has been observed
-- between otherwise-identical loads.
local SIZE_MATCH_EPSILON = 0.01

local function sizeCloseEnough(a: Vector3, b: { number }): boolean
    return math.abs(a.X - b[1]) <= SIZE_MATCH_EPSILON
        and math.abs(a.Y - b[2]) <= SIZE_MATCH_EPSILON
        and math.abs(a.Z - b[3]) <= SIZE_MATCH_EPSILON
end

local function findPartBySize(model: Model, size: { number }, exclude: BasePart?): BasePart?
    for _, descendant in model:GetDescendants() do
        if
            descendant:IsA("BasePart")
            and descendant ~= exclude
            and sizeCloseEnough(descendant.Size, size)
        then
            return descendant
        end
    end
    return nil
end

-- Runs once per template load (see the field comment on
-- MeshAssetRegistry.Entry.partOrientationFixes for why this is not the same
-- job as sourceYawDegrees). Matching by Size rather than by name or index
-- because Creator Store imports generally don't carry stable, descriptive
-- part names -- Size is the one property that's both distinctive enough to
-- pick out one part among a model's siblings and untouched by anything this
-- loader does before this point in the pipeline.
local function applyPartOrientationFixes(
    model: Model,
    fixes: { PartOrientationFix }?,
    logger: Logger,
    stableId: string
)
    if fixes == nil then
        return
    end
    for _, fix in fixes do
        local target = findPartBySize(model, fix.matchSize)
        if target == nil then
            logger:info("mesh_orientation_fix_part_not_found", {
                assetId = stableId,
                matchSize = tostring(fix.matchSize),
            })
            continue
        end
        if fix.localRotationDegrees ~= nil then
            local r = fix.localRotationDegrees
            target.CFrame = target.CFrame
                * CFrame.Angles(math.rad(r[1]), math.rad(r[2]), math.rad(r[3]))
        elseif fix.copyOrientationFromSize ~= nil then
            local reference = findPartBySize(model, fix.copyOrientationFromSize, target)
            if reference == nil then
                logger:info("mesh_orientation_fix_reference_not_found", {
                    assetId = stableId,
                    matchSize = tostring(fix.copyOrientationFromSize),
                })
                continue
            end
            target.CFrame = CFrame.new(target.Position)
                * (reference.CFrame - reference.CFrame.Position)
        end
    end
end

function MeshTemplateLoader.new(logger: Logger): MeshTemplateLoader
    return setmetatable({
        _logger = logger,
        _templates = {},
        _templateScale = {},
        _failed = {},
        _permanentFailure = {},
    }, MeshTemplateLoader)
end

function MeshTemplateLoader._load(self: MeshTemplateLoader, stableId: string): Model?
    local cached = self._templates[stableId]
    if cached ~= nil then
        return cached
    end
    if self._failed[stableId] then
        return nil
    end

    local entry = MeshAssetRegistry.get(stableId)
    if entry == nil then
        self._failed[stableId] = true
        self._permanentFailure[stableId] = true
        self._logger:info("mesh_asset_unknown", { assetId = stableId })
        return nil
    end
    if entry.placementBand == "retired_visual_failure" then
        self._failed[stableId] = true
        self._permanentFailure[stableId] = true
        self._logger:info("mesh_asset_retired", { assetId = stableId })
        return nil
    end

    --[[
        Retry a failed fetch before condemning the asset for the session.

        One blip used to cost the whole run. A failure here sets
        self._failed[stableId], which is checked before every later placement
        of the same asset -- so a single transient error does not lose one
        prop, it silently drops every instance of that asset in the world and
        leaves procedural fallbacks in their place. Observed repeatedly under
        Wine: the same IDs that fail one boot load cleanly the next, reporting
        "User is not authorized to access Asset" for an asset the account
        plainly can access. That is throttling or CDN flakiness, not a
        permission fact.

        Three attempts with a widening pause. Bounded on purpose: a genuinely
        unavailable asset still gets condemned quickly rather than being
        retried once per placement, and the cost is paid once per asset at
        template load, not per instance.
    ]]
    local ok, loaded
    local attempts = 0
    repeat
        attempts += 1
        if entry.creatorStore then
            ok, loaded = pcall(AssetService.LoadAssetAsync, AssetService, entry.assetId)
        else
            ok, loaded = pcall(InsertService.LoadAsset, InsertService, entry.assetId)
        end
        local usable = ok and typeof(loaded) == "Instance" and loaded:IsA("Model")
        if usable then
            break
        end
        if ok and typeof(loaded) == "Instance" then
            loaded:Destroy()
        end
        self._logger:info("mesh_asset_load_retry", {
            assetId = stableId,
            robloxAssetId = entry.assetId,
            attempt = attempts,
            error = if ok then "LoadAsset returned a non-Model" else tostring(loaded),
        })
        if attempts < MAX_LOAD_ATTEMPTS then
            task.wait(attempts * 0.75)
        end
    until attempts >= MAX_LOAD_ATTEMPTS
    if not ok or typeof(loaded) ~= "Instance" or not loaded:IsA("Model") then
        if ok and typeof(loaded) == "Instance" then
            loaded:Destroy()
        end
        self._failed[stableId] = true
        self._logger:info("mesh_asset_load_failed", {
            assetId = stableId,
            robloxAssetId = entry.assetId,
            attempts = attempts,
            error = if ok then "LoadAsset returned a non-Model" else tostring(loaded),
        })
        return nil
    end

    loaded.Name = "Template_" .. stableId
    local meshPartCount, basePartCount =
        sanitize(loaded, entry.stripDecals == true, entry.restyleParts)
    local styledParts, unstyledParts =
        applyBuiltInMaterials(loaded, entry.pbr, entry.preserveSourceMaterials)
    -- Cancel the source model's stored rotation BEFORE measuring anything. A
    -- model saved off-axis inflates its own axis-aligned bounding box -- the
    -- bed reads 13.85 x 15.97 as stored but is really 8.04 x 14.28 -- so
    -- normalizing against the inflated box quietly shrinks the asset while
    -- targetLongestDimension still looks honoured. Correcting here rather than
    -- at each call site also makes placement yaw mean what it says everywhere
    -- the asset is used, instead of every caller carrying the same offset.
    local sourceYaw = entry.sourceYawDegrees
    if sourceYaw ~= nil and sourceYaw ~= 0 then
        -- Post-multiply so the yaw is cancelled about the model's own pivot.
        -- Pre-multiplying rotates about the world origin instead, which also
        -- drags the model's position -- harmless while the pivot rotation is
        -- identity, but wrong the moment a source model ships with a
        -- PrimaryPart carrying its own rotation, which Creator Store models do.
        loaded:PivotTo(loaded:GetPivot() * CFrame.Angles(0, -math.rad(sourceYaw), 0))
    end
    -- Per-part corrections (a sub-part authored wrong relative to the rest
    -- of the SAME asset) run after the whole-model yaw cancel above and
    -- before the bounding box is measured, so a corrected part's true
    -- extents are what normalization and every later placement see.
    applyPartOrientationFixes(loaded, entry.partOrientationFixes, self._logger, stableId)
    local _, nativeSize = loaded:GetBoundingBox()
    local nativeLongest = longestDimension(nativeSize)
    local normalizationScale = MeshAssetRegistry.scaleFor(stableId, nativeLongest)
    if basePartCount == 0 or normalizationScale == nil then
        loaded:Destroy()
        self._failed[stableId] = true
        self._logger:info("mesh_asset_invalid", {
            assetId = stableId,
            meshParts = meshPartCount,
            baseParts = basePartCount,
            nativeLongestDimension = nativeLongest,
        })
        return nil
    end

    local desiredScale = loaded:GetScale() * normalizationScale
    loaded:ScaleTo(desiredScale)
    local boundsCFrame, boundsSize = loaded:GetBoundingBox()
    loaded.WorldPivot = CFrame.new(boundsCFrame.Position - Vector3.new(0, boundsSize.Y * 0.5, 0))
    loaded:PivotTo(CFrame.new())
    loaded:SetAttribute("SourceMaterialsPreserved", entry.preserveSourceMaterials)
    loaded.Parent = nil

    self._templates[stableId] = loaded
    self._templateScale[stableId] = desiredScale
    self._logger:info("mesh_asset_ready", {
        assetId = stableId,
        robloxAssetId = entry.assetId,
        meshParts = meshPartCount,
        baseParts = basePartCount,
        styledParts = styledParts,
        unstyledParts = unstyledParts,
        preserveSourceMaterials = entry.preserveSourceMaterials,
        nativeLongestDimension = nativeLongest,
        targetLongestDimension = entry.targetLongestDimension,
    })
    return loaded
end

function MeshTemplateLoader.place(
    self: MeshTemplateLoader,
    stableId: string,
    parent: Instance,
    at: CFrame,
    placementScale: number,
    profileScale: Vector3?
): Model?
    local template = self:_load(stableId)
    local templateScale = self._templateScale[stableId]
    if template == nil or templateScale == nil or placementScale <= 0 then
        return nil
    end

    local clone = template:Clone()
    clone.Name = "Authored_" .. stableId
    clone:ScaleTo(templateScale * placementScale)
    local resolvedProfileScale = profileScale or Vector3.one
    applyProfileScale(clone, resolvedProfileScale)
    clone:PivotTo(at)
    clone:SetAttribute("MeshAssetId", stableId)
    clone:SetAttribute("PlacementScale", placementScale)
    clone:SetAttribute("ProfileScale", resolvedProfileScale)
    clone.Parent = parent
    return clone
end

--[[
    Give condemned assets another chance.

    A load failure marks an asset failed for the whole session, which is the
    right call per placement -- but boot loads sixty assets in a burst, and
    the platform sometimes answers a burst with throttling errors dressed as
    permission errors (see the retry comment in _load). One bad boot minute
    left all eleven town-ring buildings as dark fallback shells for the whole
    server lifetime. This clears only the transient failures, so a later
    recovery pass can try again; unknown and retired assets stay condemned.

    Returns the asset ids that were forgiven.
]]
function MeshTemplateLoader.forgetTransientFailures(self: MeshTemplateLoader): { string }
    local forgiven = {}
    for stableId in self._failed do
        if not self._permanentFailure[stableId] then
            table.insert(forgiven, stableId)
        end
    end
    for _, stableId in forgiven do
        self._failed[stableId] = nil
    end
    return forgiven
end

return table.freeze(MeshTemplateLoader)
