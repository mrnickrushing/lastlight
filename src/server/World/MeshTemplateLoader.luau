--!strict

local InsertService = game:GetService("InsertService")

local MeshAssetRegistry = require(script.Parent.MeshAssetRegistry)

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

local function sanitize(model: Model): number
    local meshParts = 0
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.CastShadow = true
            descendant.Massless = true
            if descendant:IsA("MeshPart") then
                descendant.CollisionFidelity = Enum.CollisionFidelity.Box
                descendant.RenderFidelity = Enum.RenderFidelity.Automatic
                meshParts += 1
            end
        elseif
            descendant:IsA("LuaSourceContainer")
            or descendant:IsA("ProximityPrompt")
            or descendant:IsA("ClickDetector")
            or descendant:IsA("DragDetector")
            or descendant:IsA("Constraint")
            or descendant:IsA("JointInstance")
            or descendant:IsA("Humanoid")
            or descendant:IsA("AnimationController")
        then
            descendant:Destroy()
        end
    end
    return meshParts
end

local function longestDimension(size: Vector3): number
    return math.max(size.X, size.Y, size.Z)
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

    local ok, loaded = pcall(InsertService.LoadAsset, InsertService, entry.assetId)
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
    local meshPartCount = sanitize(loaded)
    local _, nativeSize = loaded:GetBoundingBox()
    local nativeLongest = longestDimension(nativeSize)
    local normalizationScale = MeshAssetRegistry.scaleFor(stableId, nativeLongest)
    if meshPartCount == 0 or normalizationScale == nil then
        loaded:Destroy()
        self._failed[stableId] = true
        self._logger:info("mesh_asset_invalid", {
            assetId = stableId,
            meshParts = meshPartCount,
            nativeLongestDimension = nativeLongest,
        })
        return nil
    end

    local desiredScale = loaded:GetScale() * normalizationScale
    loaded:ScaleTo(desiredScale)
    local boundsCFrame, boundsSize = loaded:GetBoundingBox()
    loaded.WorldPivot = CFrame.new(boundsCFrame.Position - Vector3.new(0, boundsSize.Y * 0.5, 0))
    loaded:PivotTo(CFrame.new())
    loaded.Parent = nil

    self._templates[stableId] = loaded
    self._templateScale[stableId] = desiredScale
    self._logger:info("mesh_asset_ready", {
        assetId = stableId,
        robloxAssetId = entry.assetId,
        meshParts = meshPartCount,
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
    placementScale: number
): Model?
    local template = self:_load(stableId)
    local templateScale = self._templateScale[stableId]
    if template == nil or templateScale == nil or placementScale <= 0 then
        return nil
    end

    local clone = template:Clone()
    clone.Name = "Authored_" .. stableId
    clone:ScaleTo(templateScale * placementScale)
    clone:PivotTo(at)
    clone:SetAttribute("MeshAssetId", stableId)
    clone:SetAttribute("PlacementScale", placementScale)
    clone.Parent = parent
    return clone
end

return table.freeze(MeshTemplateLoader)
