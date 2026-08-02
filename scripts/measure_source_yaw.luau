--!strict

--[[
    Report the yaw a Creator Store model is stored at, and its true footprint.

    Creator Store models are routinely saved rotated off-axis in whatever place
    they were built in. That breaks two things quietly:

      * every placement comes out turned by that angle, whatever yaw the call
        site asks for; and
      * the axis-aligned bounding box MeshTemplateLoader normalizes against is
        inflated by the rotation, so targetLongestDimension stops meaning the
        asset's real longest dimension and the asset loads too small.

    Neither failure throws. The wayfarer bed shipped 32.85 degrees off with an
    inflated 15.97-stud box standing in for its real 14.28-stud length, and it
    took a screenshot to catch.

    Feed the number this prints into the registry entry's sourceYawDegrees and
    the loader cancels it once, at template load.

      lune run scripts/measure_source_yaw <model.rbxm> [...]
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

-- Lune exposes the Roblox datatypes on the module rather than as globals.
local CFrame = roblox.CFrame

local paths = process.args
assert(#paths > 0, "usage: lune run scripts/measure_source_yaw <model.rbxm> [...]")

-- Corner-accurate extents: part positions alone understate a rotated model,
-- because the corners are what the bounding box actually has to contain.
local function extents(parts: { BasePart }, correctionDegrees: number): (number, number, number)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    local correction = CFrame.Angles(0, math.rad(correctionDegrees), 0)
    for _, part in parts do
        local frame = correction * part.CFrame
        local half = part.Size * 0.5
        for signX = -1, 1, 2 do
            for signY = -1, 1, 2 do
                for signZ = -1, 1, 2 do
                    local corner = (
                        frame * CFrame.new(half.X * signX, half.Y * signY, half.Z * signZ)
                    ).Position
                    minX, maxX = math.min(minX, corner.X), math.max(maxX, corner.X)
                    minY, maxY = math.min(minY, corner.Y), math.max(maxY, corner.Y)
                    minZ, maxZ = math.min(minZ, corner.Z), math.max(maxZ, corner.Z)
                end
            end
        end
    end
    return maxX - minX, maxY - minY, maxZ - minZ
end

for _, path in paths do
    assert(fs.isFile(path), "missing Creator Store model " .. path)
    local parts: { BasePart } = {}
    for _, root in roblox.deserializeModel(fs.readFile(path)) do
        for _, descendant in root:GetDescendants() do
            if descendant:IsA("BasePart") then
                table.insert(parts, descendant)
            end
        end
    end
    assert(#parts > 0, path .. " has no BaseParts")

    -- The modal yaw is the model's own resting rotation: decorative pieces
    -- vary, but the bulk of a model shares one angle.
    local counts: { [number]: number } = {}
    local modal, modalCount = 0, 0
    for _, part in parts do
        local _, yaw = part.CFrame:ToOrientation()
        local rounded = math.floor(math.deg(yaw) * 100 + 0.5) / 100
        counts[rounded] = (counts[rounded] or 0) + 1
        if counts[rounded] > modalCount then
            modalCount, modal = counts[rounded], rounded
        end
    end

    local storedX, storedY, storedZ = extents(parts, 0)
    local trueX, trueY, trueZ = extents(parts, -modal)
    print(string.format("%s", path))
    print(string.format("  sourceYawDegrees = %.2f  (%d/%d parts)", modal, modalCount, #parts))
    print(
        string.format(
            "  as stored  %6.2f x %6.2f x %6.2f  longest %6.2f",
            storedX,
            storedY,
            storedZ,
            math.max(storedX, storedY, storedZ)
        )
    )
    print(
        string.format(
            "  corrected  %6.2f x %6.2f x %6.2f  longest %6.2f",
            trueX,
            trueY,
            trueZ,
            math.max(trueX, trueY, trueZ)
        )
    )
end
