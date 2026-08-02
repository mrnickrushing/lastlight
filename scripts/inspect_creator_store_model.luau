--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local paths = table.clone(process.args)
local showParts = paths[1] == "--parts"
if showParts then
    table.remove(paths, 1)
end
assert(#paths > 0, "usage: lune run scripts/inspect_creator_store_model <model.rbxm> [...]")

for _, path in paths do
    assert(fs.isFile(path), "missing Creator Store model " .. path)
    local roots = roblox.deserializeModel(fs.readFile(path))
    local classCounts: { [string]: number } = {}
    local scripts = 0
    local meshParts = 0
    local baseParts = 0
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    local function inspect(instance: Instance)
        classCounts[instance.ClassName] = (classCounts[instance.ClassName] or 0) + 1
        if instance:IsA("LuaSourceContainer") then
            scripts += 1
        elseif instance:IsA("MeshPart") then
            meshParts += 1
            baseParts += 1
        elseif instance:IsA("BasePart") then
            baseParts += 1
        end
        if instance:IsA("BasePart") then
            local half = instance.Size * 0.5
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        local point = instance.CFrame
                            * roblox.Vector3.new(half.X * x, half.Y * y, half.Z * z)
                        minX = math.min(minX, point.X)
                        minY = math.min(minY, point.Y)
                        minZ = math.min(minZ, point.Z)
                        maxX = math.max(maxX, point.X)
                        maxY = math.max(maxY, point.Y)
                        maxZ = math.max(maxZ, point.Z)
                    end
                end
            end
        end
        for _, child in instance:GetChildren() do
            inspect(child)
        end
    end

    for _, root in roots do
        inspect(root)
    end

    local boundsSize = roblox.Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)

    print(
        string.format(
            "%s roots=%d baseParts=%d meshParts=%d scripts=%d min=(%.4f, %.4f, %.4f) max=(%.4f, %.4f, %.4f) bounds=(%.4f, %.4f, %.4f) longest=%.4f",
            path,
            #roots,
            baseParts,
            meshParts,
            scripts,
            minX,
            minY,
            minZ,
            maxX,
            maxY,
            maxZ,
            boundsSize.X,
            boundsSize.Y,
            boundsSize.Z,
            math.max(boundsSize.X, boundsSize.Y, boundsSize.Z)
        )
    )
    local names = {}
    for className in classCounts do
        table.insert(names, className)
    end
    table.sort(names)
    for _, className in names do
        print(string.format("  %s=%d", className, classCounts[className]))
    end
    if showParts then
        local function printParts(instance: Instance)
            if instance:IsA("BasePart") then
                local position = instance.CFrame.Position
                local size = instance.Size
                print(
                    string.format(
                        "  part=%s class=%s position=(%.3f, %.3f, %.3f) size=(%.3f, %.3f, %.3f)",
                        instance.Name,
                        instance.ClassName,
                        position.X,
                        position.Y,
                        position.Z,
                        size.X,
                        size.Y,
                        size.Z
                    )
                )
            end
            for _, child in instance:GetChildren() do
                printParts(child)
            end
        end
        for _, root in roots do
            printParts(root)
        end
    end
end
