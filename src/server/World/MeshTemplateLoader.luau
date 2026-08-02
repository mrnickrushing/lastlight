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
    },
    MeshTemplateLoader
))

local function sanitize(model: Model): (number, number)
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
        then
            descendant:Destroy()
        end
    end
    return meshParts, baseParts
end

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

function MeshTemplateLoader.new(logger: Logger): MeshTemplateLoader
    return setmetatable({
        _logger = logger,
        _templates = {},
        _templateScale = {},
        _failed = {},
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
        self._logger:info("mesh_asset_unknown", { assetId = stableId })
        return nil
    end
    if entry.placementBand == "retired_visual_failure" then
        self._failed[stableId] = true
        self._logger:info("mesh_asset_retired", { assetId = stableId })
        return nil
    end

    local ok, loaded
    if entry.creatorStore then
        ok, loaded = pcall(AssetService.LoadAssetAsync, AssetService, entry.assetId)
    else
        ok, loaded = pcall(InsertService.LoadAsset, InsertService, entry.assetId)
    end
    if not ok or not loaded:IsA("Model") then
        if ok then
            loaded:Destroy()
        end
        self._failed[stableId] = true
        self._logger:info("mesh_asset_load_failed", {
            assetId = stableId,
            robloxAssetId = entry.assetId,
            error = if ok then "LoadAsset returned a non-Model" else tostring(loaded),
        })
        return nil
    end

    loaded.Name = "Template_" .. stableId
    local meshPartCount, basePartCount = sanitize(loaded)
    local styledParts, unstyledParts =
        applyBuiltInMaterials(loaded, entry.pbr, entry.preserveSourceMaterials)
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

return table.freeze(MeshTemplateLoader)
