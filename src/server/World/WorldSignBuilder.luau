--!strict

local WorldArtRegistry = require(script.Parent.WorldArtRegistry)

local WorldSignBuilder = {}

local BARK = Color3.fromRGB(62, 39, 30)
local WET_BARK = Color3.fromRGB(36, 26, 24)
local PARCHMENT = Color3.fromRGB(210, 190, 146)
local IRON = Color3.fromRGB(50, 54, 58)
local WAX = Color3.fromRGB(142, 71, 49)

local function part(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material
): Part
    local instance = Instance.new("Part")
    instance.Name = name
    instance.Size = size
    instance.CFrame = cframe
    instance.Color = color
    instance.Material = material
    instance.Anchored = true
    instance.CanCollide = false
    instance.CanTouch = false
    instance.CanQuery = false
    instance.CastShadow = true
    instance.TopSurface = Enum.SurfaceType.Smooth
    instance.BottomSurface = Enum.SurfaceType.Smooth
    instance.Parent = parent
    return instance
end

local function addSurfaceText(board: BasePart, title: string, accent: Color3)
    local surface = Instance.new("SurfaceGui")
    surface.Name = "PhysicalSignText"
    surface.Face = Enum.NormalId.Front
    surface.LightInfluence = 0.3
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 42
    surface.Parent = board

    local shadow = Instance.new("TextLabel")
    shadow.Name = "SignLetterShadow"
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.fromOffset(2, 2)
    shadow.Size = UDim2.fromScale(1, 1)
    shadow.Font = Enum.Font.GothamBold
    shadow.Text = title
    shadow.TextColor3 = Color3.fromRGB(19, 17, 15)
    shadow.TextScaled = true
    shadow.TextWrapped = true
    shadow.Parent = surface

    local label = Instance.new("TextLabel")
    label.Name = "SignLetters"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = title
    label.TextColor3 = accent
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = surface

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0.16, 0)
    padding.PaddingBottom = UDim.new(0.16, 0)
    padding.PaddingLeft = UDim.new(0.08, 0)
    padding.PaddingRight = UDim.new(0.08, 0)
    padding.Parent = label
end

local function addBoardFrame(board: BasePart, style: string): Folder
    local existing = board:FindFirstChild("PhysicalSignDetails")
    if existing ~= nil then
        existing:Destroy()
    end
    local details = Instance.new("Folder")
    details.Name = "PhysicalSignDetails"
    details.Parent = board

    local width = board.Size.X
    local height = board.Size.Y
    local front = -(board.Size.Z * 0.5 + 0.1)
    local railDepth = math.max(0.22, board.Size.Z * 0.48)
    for side = -1, 1, 2 do
        if style ~= "direction" then
            part(
                details,
                "SignFrameSide",
                Vector3.new(0.42, height + 0.7, railDepth),
                board.CFrame * CFrame.new(side * (width * 0.5 + 0.1), 0, front),
                if side < 0 then WET_BARK else BARK,
                Enum.Material.Wood
            )
        end
        part(
            details,
            "SignFrameRail",
            Vector3.new(width + 0.9, 0.38, railDepth),
            board.CFrame
                * CFrame.new(0, side * (height * 0.5 + 0.1), front)
                * CFrame.Angles(0, 0, math.rad(side * 1.5)),
            if side < 0 then BARK else WET_BARK,
            Enum.Material.Wood
        )
    end
    for pinX = -1, 1, 2 do
        local pinRows = if style == "direction" then { 0 } else { -1, 1 }
        for _, pinY in pinRows do
            local pin = part(
                details,
                "SignIronPin",
                Vector3.new(0.2, 0.2, 0.16),
                board.CFrame * CFrame.new(pinX * width * 0.43, pinY * height * 0.38, front - 0.2),
                IRON,
                Enum.Material.Metal
            )
            pin.Shape = Enum.PartType.Ball
        end
    end
    if style == "direction" then
        local arrowColor = Color3.fromRGB(149, 112, 62)
        part(
            details,
            "CarvedDirectionShaft",
            Vector3.new(width * 0.22, 0.18, 0.12),
            board.CFrame * CFrame.new(width * 0.31, -height * 0.28, front - 0.2),
            arrowColor,
            Enum.Material.WoodPlanks
        )
        local head = part(
            details,
            "CarvedDirectionHead",
            Vector3.new(0.48, 0.6, 0.12),
            board.CFrame
                * CFrame.new(width * 0.44, -height * 0.28, front - 0.2)
                * CFrame.Angles(0, math.rad(90), 0),
            arrowColor,
            Enum.Material.WoodPlanks
        )
        head.Shape = Enum.PartType.Wedge
    end
    board:SetAttribute("PhysicalSignStyle", style)
    return details
end

function WorldSignBuilder.dressBoard(board: BasePart, title: string, accent: Color3, style: string?)
    for _, child in board:GetChildren() do
        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
            child:Destroy()
        end
    end
    addBoardFrame(board, style or "plaque")
    addSurfaceText(board, title, accent)
end

function WorldSignBuilder.createDirectionSign(
    parent: Instance,
    name: string,
    at: CFrame,
    title: string,
    accent: Color3
): Model
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("PhysicalSign", true)
    model.Parent = parent

    local board = part(
        model,
        "DirectionBoard",
        Vector3.new(8, 2.45, 0.52),
        at,
        Color3.fromRGB(83, 57, 38),
        Enum.Material.WoodPlanks
    )
    part(
        model,
        "DirectionPost",
        Vector3.new(0.68, 5.8, 0.68),
        at * CFrame.new(-2.65, -3.7, 0.18) * CFrame.Angles(0, 0, math.rad(-4)),
        WET_BARK,
        Enum.Material.Wood
    )
    part(
        model,
        "DirectionPostBrace",
        Vector3.new(0.4, 3.1, 0.4),
        at * CFrame.new(-3.25, -4.25, 0.3) * CFrame.Angles(0, 0, math.rad(24)),
        BARK,
        Enum.Material.Wood
    )
    WorldSignBuilder.dressBoard(board, title, accent, "direction")
    model.PrimaryPart = board
    return model
end

local function addNoticeArtwork(paper: BasePart, panelId: string)
    local panel = WorldArtRegistry.noticePanel(panelId)
    assert(panel ~= nil, "unknown notice artwork " .. panelId)
    local surface = Instance.new("SurfaceGui")
    surface.Name = "NoticeArtwork"
    surface.Face = Enum.NormalId.Front
    surface.LightInfluence = 0.2
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 96
    surface.Parent = paper

    local image = Instance.new("ImageLabel")
    image.Name = "NoticeImage_" .. panelId
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromScale(1, 1)
    image.Image = "rbxassetid://" .. tostring(panel.assetId)
    image.ImageRectOffset = Vector2.new(panel.offsetX, panel.offsetY)
    image.ImageRectSize = Vector2.new(panel.width, panel.height)
    image.ScaleType = Enum.ScaleType.Stretch
    image.Parent = surface
    paper:SetAttribute("NoticePanelId", panelId)
    paper:SetAttribute("NoticeAssetId", panel.assetId)
end

function WorldSignBuilder.dressNoticeBoard(
    board: BasePart,
    title: string,
    accent: Color3,
    panelIds: { string }
)
    WorldSignBuilder.dressBoard(board, title, accent, "notice")
    local details = board:FindFirstChild("PhysicalSignDetails")
    assert(details ~= nil, "notice board frame missing")

    local titlePlate = part(
        details,
        "NoticeBoardHeader",
        Vector3.new(math.min(board.Size.X * 0.7, 8), 1.05, 0.3),
        board.CFrame
            * CFrame.new(0, board.Size.Y * 0.5 + 0.72, -(board.Size.Z * 0.5 + 0.3))
            * CFrame.Angles(0, 0, math.rad(-1.5)),
        WET_BARK,
        Enum.Material.WoodPlanks
    )
    addSurfaceText(titlePlate, title, accent)

    -- The header owns the wording; the board face holds actual pinned art.
    local boardSurface = board:FindFirstChild("PhysicalSignText")
    if boardSurface ~= nil then
        boardSurface:Destroy()
    end

    local columns = math.min(3, #panelIds)
    local rows = math.ceil(#panelIds / columns)
    local paperWidth = math.min(2.55, (board.Size.X - 1.2) / columns - 0.3)
    local paperHeight = paperWidth / 1.5
    local usableHeight = board.Size.Y - 0.9
    local rowSpacing = math.min(paperHeight + 0.35, usableHeight / rows)
    for index, panelId in panelIds do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        local columnsInRow = math.min(columns, #panelIds - row * columns)
        local x = (column - (columnsInRow - 1) * 0.5) * (paperWidth + 0.35)
        local y = (rows - 1) * rowSpacing * 0.5 - row * rowSpacing - 0.12
        local rotation = math.rad(((index * 7) % 9) - 4)
        local paper = part(
            details,
            if board.Name == "TownBoard" then "TownNotice_" .. panelId else "ArchiveNotice",
            Vector3.new(paperWidth, paperHeight, 0.1),
            board.CFrame
                * CFrame.new(x, y, -(board.Size.Z * 0.5 + 0.22))
                * CFrame.Angles(0, 0, rotation),
            PARCHMENT,
            Enum.Material.Fabric
        )
        paper.CastShadow = false
        addNoticeArtwork(paper, panelId)

        local pin = part(
            details,
            "NoticeIronPin",
            Vector3.new(0.16, 0.16, 0.13),
            paper.CFrame * CFrame.new(0, paperHeight * 0.38, -0.12),
            IRON,
            Enum.Material.Metal
        )
        pin.Shape = Enum.PartType.Ball
        if index % 2 == 0 then
            local seal = part(
                details,
                "NoticeWaxSeal",
                Vector3.new(0.32, 0.32, 0.1),
                paper.CFrame * CFrame.new(paperWidth * 0.34, -paperHeight * 0.34, -0.12),
                WAX,
                Enum.Material.SmoothPlastic
            )
            seal.Shape = Enum.PartType.Ball
        end
    end
    board:SetAttribute("NoticeCount", #panelIds)
    board:SetAttribute("PhysicalNoticeBoard", true)
end

return table.freeze(WorldSignBuilder)
