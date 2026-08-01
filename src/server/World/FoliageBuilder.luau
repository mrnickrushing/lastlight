--!strict

--[[
    Organic tree, rock, and undergrowth silhouettes for the Bramblewake valley.

    WHY THIS EXISTS

    The valley's trees were a box trunk plus six axis-aligned wedge slabs, and
    its rocks were single spheres. Both read as exactly what they are. The art
    direction asks for "strong silhouettes ... over raw part count", and the
    fastest way to break a box silhouette is not more parts -- it is rotation,
    taper, and asymmetry on the parts already being spent.

    So every generator here spends a similar part budget to the shapes it
    replaces and buys silhouette with it instead of volume:

      * trunks taper and lean, in segments, rather than being one prism;
      * canopies are rotated, offset, non-uniformly scaled masses, so no two
        read as the same object and none present a flat face to the camera;
      * rocks are clustered, part-buried, unevenly scaled boulders;
      * species differ in shape language, not just colour, so the treeline has
        variety at silhouette distance where colour has already washed out.

    Everything is seeded. Two servers, and a Studio build against a live one,
    generate an identical forest.

    NOT MESHES -- AND WHY THAT IS THE RIGHT ORDER

    Real MeshPart foliage would beat all of this. It also needs measured native
    mesh sizes (guessed scales are reliably wrong by ~10x), an asset manifest,
    and art-direction sign-off on specific Creator Store assets. Ground shape
    and composition have to land first regardless: mesh trees standing on a
    flat rectangle still read as props on a yard. This module is the graybox
    the art direction asks for before final art, and its call sites are the
    seams a mesh pass would later swap behind.
]]

local CollectionService = game:GetService("CollectionService")

local FoliageBuilder = {}

export type Tone = {
    bark: Color3,
    barkWet: Color3,
    needle: Color3,
    needleDeep: Color3,
    leaf: Color3,
    leafPale: Color3,
    moss: Color3,
    stone: Color3,
    stoneWarm: Color3,
}

local function newPart(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    canCollide: boolean
): Part
    local instance = Instance.new("Part")
    instance.Name = name
    instance.Size = size
    instance.CFrame = cframe
    instance.Color = color
    instance.Material = material
    instance.Anchored = true
    instance.CanCollide = canCollide
    instance.CanTouch = canCollide
    if not canCollide then
        instance.CanQuery = false
    end
    -- Shadows follow collision, which here is the same line as "structure vs.
    -- decoration": trunks, logs, and the lead boulder cast, while canopy
    -- masses, ferns, moss, and splinters do not. The forest is ~4,200 parts and
    -- the overwhelming majority are decoration, so casting from all of them
    -- would spend the whole shadow budget on foliage that only ever produces
    -- noise -- exactly the "disable shadows on minor parts according to art
    -- budget" rule in the technical architecture. The trunks still ground every
    -- tree, which is the shadow that actually reads.
    instance.CastShadow = canCollide
    instance.TopSurface = Enum.SurfaceType.Smooth
    instance.BottomSurface = Enum.SurfaceType.Smooth
    instance.Parent = parent
    return instance
end

--[[
    A leaning, tapering trunk built from stacked segments.

    Each segment is narrower and slightly more offset than the one below, which
    is what separates a tree from a pole. The lean is derived from position so a
    stand of trees leans coherently, as though the same weather shaped it,
    rather than each one tilting at random.
]]
local function trunk(
    parent: Instance,
    base: Vector3,
    height: number,
    radius: number,
    lean: number,
    tone: Tone
): Vector3
    local segments = 4
    local top = base
    local drift = Vector3.new(math.cos(lean), 0, math.sin(lean))

    for index = 1, segments do
        local fraction = (index - 1) / segments
        local nextFraction = index / segments
        local segmentHeight = height / segments
        local segmentRadius = radius * (1 - fraction * 0.52)
        local offset = drift * (height * 0.05 * nextFraction * nextFraction)
        local center = base + Vector3.new(0, height * fraction + segmentHeight / 2, 0) + offset

        local piece = newPart(
            parent,
            "TreeTrunk",
            Vector3.new(segmentRadius * 2, segmentHeight * 1.04, segmentRadius * 2),
            CFrame.new(center)
                * CFrame.Angles(
                    math.sin(lean) * 0.05 * nextFraction,
                    lean,
                    math.cos(lean) * 0.05 * nextFraction
                ),
            if index == 1 then tone.barkWet else tone.bark,
            Enum.Material.Wood,
            index <= 2
        )
        piece.Shape = Enum.PartType.Cylinder
        -- Cylinder parts extend along X, so stand them upright.
        piece.CFrame = CFrame.new(center)
            * CFrame.Angles(0, lean, math.rad(90))
            * CFrame.Angles(0, 0, math.sin(lean) * 0.06 * nextFraction)

        top = center + Vector3.new(0, segmentHeight / 2, 0) + offset
    end

    -- Root flare: a wider, part-buried base stops the trunk from looking like
    -- it was pushed into the ground.
    local flare = newPart(
        parent,
        "TreeRootFlare",
        Vector3.new(radius * 3.1, radius * 2.1, radius * 3.1),
        CFrame.new(base + Vector3.new(0, radius * 0.35, 0)),
        tone.barkWet,
        Enum.Material.Wood,
        false
    )
    flare.Shape = Enum.PartType.Ball

    return top
end

--[[
    A conifer: stacked, rotated, non-uniform canopy masses.

    The old version used two axis-aligned wedges per layer, so every tree
    presented the same flat triangle to the camera. Rotating each layer off the
    axis and varying its scale means the silhouette changes as the player moves
    around it, which is the property that reads as "a tree" at distance.
]]
function FoliageBuilder.conifer(
    parent: Instance,
    position: Vector3,
    scale: number,
    tone: Tone,
    seed: number,
    swayTag: string?
)
    local random = Random.new(seed)
    local height = 26 * scale
    local lean = position.X * 0.004 + random:NextNumber(-0.14, 0.14)
    local top = trunk(parent, position, height, 1.5 * scale, lean, tone)

    local layers = 5
    for index = 1, layers do
        local fraction = (index - 1) / layers
        local layerY = height * (0.32 + fraction * 0.72)
        local spread = (10.5 - index * 1.35) * scale * random:NextNumber(0.88, 1.12)
        local thickness = (5.4 - index * 0.55) * scale

        -- Three masses per layer at uneven angles: no flat face, no repeat.
        for wedgeIndex = 1, 3 do
            local angle = (wedgeIndex / 3) * math.pi * 2
                + fraction * 1.9
                + random:NextNumber(-0.25, 0.25)
            local reach = spread * random:NextNumber(0.42, 0.6)
            local center = position
                + Vector3.new(
                    math.cos(angle) * reach + math.cos(lean) * layerY * 0.05,
                    layerY,
                    math.sin(angle) * reach + math.sin(lean) * layerY * 0.05
                )

            local needle = newPart(
                parent,
                "ConiferCanopy",
                Vector3.new(
                    spread * random:NextNumber(0.72, 0.95),
                    thickness * random:NextNumber(0.85, 1.15),
                    spread * random:NextNumber(0.72, 0.95)
                ),
                CFrame.new(center)
                    * CFrame.Angles(
                        random:NextNumber(-0.22, 0.22),
                        angle,
                        random:NextNumber(-0.22, 0.22)
                    ),
                if index >= layers - 1 then tone.needle else tone.needleDeep,
                Enum.Material.Grass,
                false
            )
            needle.Shape = Enum.PartType.Ball

            if swayTag ~= nil and index >= layers - 1 and wedgeIndex == 1 then
                CollectionService:AddTag(needle, swayTag)
            end
        end
    end

    -- A crown tip so the tree resolves to a point instead of a dome.
    local tip = newPart(
        parent,
        "ConiferCrown",
        Vector3.new(2.6 * scale, 6.5 * scale, 2.6 * scale),
        CFrame.new(top + Vector3.new(0, height * 0.16, 0)),
        tone.needle,
        Enum.Material.Grass,
        false
    )
    tip.Shape = Enum.PartType.Ball
    if swayTag ~= nil then
        CollectionService:AddTag(tip, swayTag)
    end
end

--[[
    A broadleaf: a shorter, heavier canopy on a forking trunk.

    Present so the treeline is not one repeated species. Difference is in shape
    language -- wide clustered crown, visible limbs -- not just a colour swap,
    because colour is the first thing distance and night lighting remove.
]]
function FoliageBuilder.broadleaf(
    parent: Instance,
    position: Vector3,
    scale: number,
    tone: Tone,
    seed: number,
    swayTag: string?
)
    local random = Random.new(seed)
    local height = 19 * scale
    local lean = random:NextNumber(-0.2, 0.2)
    local top = trunk(parent, position, height, 1.8 * scale, lean, tone)

    -- Limbs, so the canopy has something to sit on.
    for limbIndex = 1, 3 do
        local angle = (limbIndex / 3) * math.pi * 2 + random:NextNumber(-0.4, 0.4)
        local limb = newPart(
            parent,
            "BroadleafLimb",
            Vector3.new(1.05 * scale, 8 * scale, 1.05 * scale),
            CFrame.new(
                top
                    + Vector3.new(
                        math.cos(angle) * 2.2 * scale,
                        1.4 * scale,
                        math.sin(angle) * 2.2 * scale
                    )
            )
                * CFrame.Angles(math.cos(angle) * 0.6, angle, math.sin(angle) * 0.6),
            tone.bark,
            Enum.Material.Wood,
            false
        )
        limb.Shape = Enum.PartType.Cylinder
        limb.CFrame = CFrame.new(
            top
                + Vector3.new(
                    math.cos(angle) * 2.6 * scale,
                    2.2 * scale,
                    math.sin(angle) * 2.6 * scale
                )
        ) * CFrame.Angles(0, angle, math.rad(52))
    end

    for cluster = 1, 6 do
        local angle = (cluster / 6) * math.pi * 2 + random:NextNumber(-0.3, 0.3)
        local reach = random:NextNumber(3.4, 6.6) * scale
        local blobSize = random:NextNumber(7.5, 11.5) * scale
        local center = top
            + Vector3.new(
                math.cos(angle) * reach,
                random:NextNumber(3.2, 6.4) * scale,
                math.sin(angle) * reach
            )

        local leaves = newPart(
            parent,
            "BroadleafCanopy",
            Vector3.new(blobSize, blobSize * random:NextNumber(0.62, 0.82), blobSize),
            CFrame.new(center)
                * CFrame.Angles(random:NextNumber(-0.3, 0.3), angle, random:NextNumber(-0.3, 0.3)),
            if cluster % 3 == 0 then tone.leafPale else tone.leaf,
            Enum.Material.LeafyGrass,
            false
        )
        leaves.Shape = Enum.PartType.Ball

        if swayTag ~= nil and cluster % 3 == 1 then
            CollectionService:AddTag(leaves, swayTag)
        end
    end
end

--[[
    A dead snag: bare, broken, leaning.

    Cheap silhouette variety and the shape language the art direction assigns to
    the Long Night -- "broken repetition, inverted familiar shapes". A treeline
    of nothing but healthy trees has no story in it.
]]
function FoliageBuilder.snag(
    parent: Instance,
    position: Vector3,
    scale: number,
    tone: Tone,
    seed: number
)
    local random = Random.new(seed)
    local height = random:NextNumber(13, 21) * scale
    local lean = random:NextNumber(-0.34, 0.34)
    local top = trunk(parent, position, height, 1.25 * scale, lean, tone)

    for _ = 1, random:NextInteger(2, 4) do
        local angle = random:NextNumber(0, math.pi * 2)
        local length = random:NextNumber(3.5, 7) * scale
        local branch = newPart(
            parent,
            "SnagBranch",
            Vector3.new(0.55 * scale, length, 0.55 * scale),
            CFrame.new(top),
            tone.barkWet,
            Enum.Material.Wood,
            false
        )
        branch.Shape = Enum.PartType.Cylinder
        branch.CFrame = CFrame.new(
            top
                + Vector3.new(
                    math.cos(angle) * length * 0.32,
                    -random:NextNumber(0.5, 4) * scale,
                    math.sin(angle) * length * 0.32
                )
        ) * CFrame.Angles(0, angle, math.rad(random:NextNumber(38, 74)))
    end
end

--[[
    A boulder cluster: several unevenly scaled, part-buried, rotated masses.

    One sphere reads as a ball. Three overlapping spheres of different sizes,
    each sunk into the ground at a different depth, read as rock -- the buried
    contact is what sells it, because a rock resting exactly on a surface looks
    dropped.
]]
function FoliageBuilder.boulders(
    parent: Instance,
    position: Vector3,
    scale: number,
    tone: Tone,
    seed: number
)
    local random = Random.new(seed)
    local count = random:NextInteger(2, 4)

    for index = 1, count do
        local offset = Vector3.new(
            random:NextNumber(-3.4, 3.4) * scale,
            0,
            random:NextNumber(-3.4, 3.4) * scale
        )
        local size = random:NextNumber(2.6, 6.4) * scale
        -- Sink each boulder a different amount so the cluster has contact with
        -- the ground instead of sitting on it.
        local sink = random:NextNumber(0.22, 0.48)

        local stone = newPart(
            parent,
            "Boulder",
            Vector3.new(
                size * random:NextNumber(1, 1.5),
                size * random:NextNumber(0.62, 0.95),
                size
            ),
            CFrame.new(position + offset + Vector3.new(0, size * (0.5 - sink), 0))
                * CFrame.Angles(
                    random:NextNumber(-0.3, 0.3),
                    random:NextNumber(0, math.pi * 2),
                    random:NextNumber(-0.3, 0.3)
                ),
            if index == 1 then tone.stone else tone.stoneWarm,
            Enum.Material.Rock,
            index == 1
        )
        stone.Shape = Enum.PartType.Ball

        if index == count and random:NextNumber() < 0.6 then
            local cap = newPart(
                parent,
                "BoulderMoss",
                Vector3.new(size * 0.92, size * 0.34, size * 0.86),
                CFrame.new(position + offset + Vector3.new(0, size * (0.72 - sink), 0))
                    * CFrame.Angles(0, random:NextNumber(0, math.pi), 0),
                tone.moss,
                Enum.Material.Grass,
                false
            )
            cap.Shape = Enum.PartType.Ball
        end
    end
end

--[[
    A fallen log with a torn end and a couple of shelf fungi.

    Horizontal mass among vertical trunks; the treeline needs both or it reads
    as a fence.
]]
function FoliageBuilder.deadfall(
    parent: Instance,
    position: Vector3,
    scale: number,
    tone: Tone,
    seed: number
)
    local random = Random.new(seed)
    local angle = random:NextNumber(0, math.pi * 2)
    local length = random:NextNumber(12, 20) * scale
    local radius = random:NextNumber(1.1, 1.8) * scale

    local log = newPart(
        parent,
        "FallenLog",
        Vector3.new(radius * 2, length, radius * 2),
        CFrame.new(position + Vector3.new(0, radius * 0.78, 0)),
        tone.barkWet,
        Enum.Material.Wood,
        true
    )
    log.Shape = Enum.PartType.Cylinder
    log.CFrame = CFrame.new(position + Vector3.new(0, radius * 0.78, 0))
        * CFrame.Angles(0, angle, math.rad(90))
        * CFrame.Angles(0, math.rad(random:NextNumber(-6, 6)), 0)

    -- Splintered end, so the log looks broken rather than sawn.
    for splinter = 1, 3 do
        local shard = newPart(
            parent,
            "LogSplinter",
            Vector3.new(radius * 0.42, radius * random:NextNumber(1.4, 2.6), radius * 0.42),
            CFrame.new(
                position
                    + Vector3.new(
                        math.cos(angle) * length * 0.5,
                        radius * random:NextNumber(0.6, 1.5),
                        math.sin(angle) * length * 0.5
                    )
            )
                * CFrame.Angles(math.rad(random:NextNumber(50, 84)), angle + splinter, 0),
            tone.bark,
            Enum.Material.Wood,
            false
        )
        shard.Shape = Enum.PartType.Cylinder
    end

    for shelf = 1, random:NextInteger(1, 3) do
        local along = random:NextNumber(-0.34, 0.34)
        local fungus = newPart(
            parent,
            "ShelfFungus",
            Vector3.new(radius * 1.9, radius * 0.3, radius * 1.35),
            CFrame.new(
                position
                    + Vector3.new(
                        math.cos(angle) * length * along,
                        radius * 1.5,
                        math.sin(angle) * length * along
                    )
            )
                * CFrame.Angles(0, angle + shelf, math.rad(random:NextNumber(-14, 14))),
            tone.leafPale,
            Enum.Material.Fabric,
            false
        )
        fungus.Shape = Enum.PartType.Ball
    end
end

--[[
    Low undergrowth: ferns splayed from a common root.

    Kept cheap and non-colliding. Placed only where the route is not, so it
    never blocks navigation or the mobile camera.
]]
function FoliageBuilder.undergrowth(
    parent: Instance,
    position: Vector3,
    scale: number,
    tone: Tone,
    seed: number,
    swayTag: string?
)
    local random = Random.new(seed)
    local fronds = random:NextInteger(5, 8)

    for index = 1, fronds do
        local angle = (index / fronds) * math.pi * 2 + random:NextNumber(-0.2, 0.2)
        local length = random:NextNumber(2.4, 4.2) * scale
        local frond = newPart(
            parent,
            "FernFrond",
            Vector3.new(0.42 * scale, 0.16 * scale, length),
            CFrame.new(
                position
                    + Vector3.new(
                        math.cos(angle) * length * 0.34,
                        random:NextNumber(0.4, 0.9) * scale,
                        math.sin(angle) * length * 0.34
                    )
            ) * CFrame.Angles(math.rad(random:NextNumber(16, 34)), angle, 0),
            if index % 2 == 0 then tone.moss else tone.leaf,
            Enum.Material.Grass,
            false
        )

        if swayTag ~= nil and index == 1 then
            CollectionService:AddTag(frond, swayTag)
        end
    end
end

return table.freeze(FoliageBuilder)
