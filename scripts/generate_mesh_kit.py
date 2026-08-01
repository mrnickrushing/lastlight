"""Generate Last Light's original environment mesh kit with Blender.

Run from the repository root:
  blender --background --python scripts/generate_mesh_kit.py

The output is deterministic. Every GLB is exported at its intended gameplay
size, and measurements.json records the authored bounds and triangle count.
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "meshes" / "generated"
PREVIEW = ROOT / "assets" / "meshes" / "previews" / "mesh-environment-kit.png"
OUTPUT.mkdir(parents=True, exist_ok=True)
PREVIEW.parent.mkdir(parents=True, exist_ok=True)

ASSETS: dict[str, list[bpy.types.Object]] = {}
MATERIALS: dict[str, bpy.types.Material] = {}
TARGET_LONGEST_DIMENSIONS = {
    "mesh_conifer_hero_a": 27.0,
    "mesh_conifer_hero_b": 24.0,
    "mesh_broadleaf_hero_a": 23.0,
    "mesh_boulder_cluster_a": 10.0,
    "mesh_deadfall_a": 17.0,
    "mesh_root_arch_a": 25.0,
    "mesh_fern_cluster_a": 5.0,
    "mesh_hollow_lantern_shrine_a": 28.0,
    "mesh_wayfarer_cabin_a": 20.0,
    "mesh_lantern_post_a": 9.0,
    "mesh_crooked_farmhouse_a": 24.0,
    "mesh_foxfire_windmill_tower_a": 36.0,
}


PALETTE = {
    "bark_dark": ((0.105, 0.050, 0.025, 1), 0.93),
    "bark_mid": ((0.205, 0.095, 0.042, 1), 0.88),
    "bark_cut": ((0.390, 0.205, 0.090, 1), 0.80),
    "pine_dark": ((0.025, 0.120, 0.072, 1), 0.92),
    "pine_mid": ((0.055, 0.215, 0.112, 1), 0.90),
    "leaf_dark": ((0.055, 0.145, 0.052, 1), 0.93),
    "leaf_mid": ((0.125, 0.285, 0.090, 1), 0.90),
    "moss": ((0.225, 0.330, 0.090, 1), 0.96),
    "stone": ((0.205, 0.235, 0.255, 1), 0.97),
    "stone_dark": ((0.105, 0.125, 0.145, 1), 0.98),
    "fungus": ((0.530, 0.235, 0.085, 1), 0.84),
    "foxfire": ((0.075, 0.750, 0.760, 1), 0.58),
    "lantern_amber": ((1.000, 0.390, 0.055, 1), 0.42),
    "iron": ((0.105, 0.115, 0.125, 1), 0.72),
    "meadow": ((0.515, 0.365, 0.095, 1), 0.92),
}


def material(name: str) -> bpy.types.Material:
    cached = MATERIALS.get(name)
    if cached:
        return cached
    color, roughness = PALETTE[name]
    mat = bpy.data.materials.new(f"LL_{name}")
    mat.diffuse_color = color
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = 0.0
    if name in {"foxfire", "lantern_amber"}:
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = 1.4 if name == "foxfire" else 2.1
    MATERIALS[name] = mat
    return mat


# Above this angle a face pair reads as a deliberate hard edge (a box corner,
# a beveled plank end) and should stay faceted. Below it, the pair is meant to
# approximate one continuous curved surface (a cone's barrel, an icosphere's
# canopy bump) and should shade smooth. 40 degrees keeps a cube's 90-degree
# corners crisp while smoothing the ~20-26-degree steps between an 8-9-gon
# cone's side faces and the ~40-degree steps of a subdivision-1/2 icosphere.
SMOOTH_ANGLE = math.radians(40)


def smooth_by_angle(obj: bpy.types.Object) -> None:
    """Shade `obj` smooth, splitting normals back apart above SMOOTH_ANGLE.

    Every primitive used to be forced flat-shaded (every polygon got its own
    normal, so every facet showed a hard edge against its neighbor), which is
    what "boxy/flat" describes literally: it does not matter how organic the
    underlying geometry is -- add_branching_trunk's tapered, curving cone
    segments, irregular_ico's jittered canopy blobs -- if every face is shaded
    as its own flat plane, the result reads as faceted regardless. That also
    worked against the style formula's own "softened bevels" language, since
    box()'s bevel modifier produced a bevel that was itself flat-shaded.

    Angle-based smoothing is the standard middle ground in stylized low-poly
    art: it keeps genuinely sharp edges sharp (a box corner is 90 degrees,
    well above SMOOTH_ANGLE) while blending the shallow steps between faces on
    a surface meant to read as continuously curved. That distinguishes
    "deliberately faceted" from "cheap primitive."

    Called after consolidate_assets_by_material's join, not per-primitive in
    register(): auto_smooth_angle is a mesh-datablock property (pre-4.1) and
    shade_auto_smooth adds an object modifier (4.1+), and bpy.ops.object.join
    keeps only the *active* object's datablock/modifiers -- every other joined
    object's smoothing setup would be silently discarded. Applying it once, to
    the already-joined result, has nothing left to lose.
    """
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    if hasattr(bpy.ops.object, "shade_auto_smooth"):
        # Blender 4.1+: adds a "Smooth by Angle" modifier node group.
        bpy.ops.object.shade_auto_smooth(angle=SMOOTH_ANGLE)
    else:
        # Blender < 4.1: shade_smooth() sets the base smooth flag, then the
        # mesh-level angle threshold splits normals back apart across edges
        # sharper than SMOOTH_ANGLE.
        bpy.ops.object.shade_smooth()
        obj.data.use_auto_smooth = True
        obj.data.auto_smooth_angle = SMOOTH_ANGLE


def register(asset_id: str, obj: bpy.types.Object, mat_name: str) -> bpy.types.Object:
    obj.name = f"{asset_id}__{obj.name}"
    if obj.type == "MESH":
        obj.data.materials.append(material(mat_name))
    obj["lastLightAssetId"] = asset_id
    ASSETS.setdefault(asset_id, []).append(obj)
    return obj


def cone(
    asset_id: str,
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    radius_start: float,
    radius_end: float,
    mat_name: str,
    vertices: int = 8,
) -> bpy.types.Object:
    a, b = Vector(start), Vector(end)
    delta = b - a
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius_start,
        radius2=radius_end,
        depth=delta.length,
        location=(a + b) * 0.5,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(delta.normalized())
    return register(asset_id, obj, mat_name)


def box(
    asset_id: str,
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    rotation: tuple[float, float, float],
    mat_name: str,
    bevel: float = 0.0,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        modifier = obj.modifiers.new(name="softened_edges", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return register(asset_id, obj, mat_name)


def irregular_ico(
    asset_id: str,
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat_name: str,
    seed: int,
    subdivisions: int = 1,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1, location=location)
    obj = bpy.context.object
    obj.name = name
    rng = random.Random(seed)
    for vertex in obj.data.vertices:
        factor = 0.82 + rng.random() * 0.30
        vertex.co *= factor
    obj.scale = scale
    obj.rotation_euler = (
        rng.uniform(-0.16, 0.16),
        rng.uniform(-0.16, 0.16),
        rng.uniform(-math.pi, math.pi),
    )
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return register(asset_id, obj, mat_name)


def leaf_plane(
    asset_id: str,
    name: str,
    base: tuple[float, float, float],
    tip: tuple[float, float, float],
    width: float,
    mat_name: str,
) -> bpy.types.Object:
    a, b = Vector(base), Vector(tip)
    forward = b - a
    side = forward.cross(Vector((0, 0, 1)))
    if side.length < 0.01:
        side = Vector((1, 0, 0))
    side.normalize()
    middle = a.lerp(b, 0.52)
    verts = [a, middle + side * width, b, middle - side * width]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], [(0, 1, 2, 3)])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return register(asset_id, obj, mat_name)


def add_branching_trunk(asset_id: str, crooked: float, height: float, seed: int) -> None:
    rng = random.Random(seed)
    points = [(0.0, 0.0, 0.0)]
    for index in range(1, 6):
        z = height * index / 5
        points.append((crooked * math.sin(index * 1.5), crooked * 0.55 * math.cos(index), z))
    for index in range(5):
        taper = 1 - index / 6
        cone(asset_id, f"trunk_{index}", points[index], points[index + 1], 0.82 * taper, 0.62 * taper, "bark_mid", 9)
    for index in range(2, 5):
        origin = Vector(points[index])
        angle = rng.uniform(0, math.tau)
        reach = height * rng.uniform(0.16, 0.24)
        tip = origin + Vector((math.cos(angle) * reach, math.sin(angle) * reach, height * rng.uniform(0.10, 0.18)))
        cone(asset_id, f"branch_{index}", origin, tip, 0.34, 0.08, "bark_mid", 7)


def make_conifer(asset_id: str, height: float, crooked: float, seed: int) -> None:
    add_branching_trunk(asset_id, crooked, height, seed)
    rng = random.Random(seed)
    for tier in range(5):
        z = height * (0.32 + tier * 0.13)
        radius = height * (0.24 - tier * 0.034)
        for cluster in range(3):
            angle = cluster * math.tau / 3 + tier * 0.61
            location = (
                math.cos(angle) * radius * 0.28 + crooked * math.sin(tier * 1.5),
                math.sin(angle) * radius * 0.28,
                z + rng.uniform(-0.25, 0.25),
            )
            irregular_ico(
                asset_id,
                f"needle_{tier}_{cluster}",
                location,
                (radius, radius * 0.62, height * 0.105),
                "pine_mid" if (tier + cluster) % 3 else "pine_dark",
                seed * 100 + tier * 10 + cluster,
                1,
            )
    irregular_ico(asset_id, "needle_crown", (crooked * 0.3, 0, height * 0.94), (height * 0.085, height * 0.08, height * 0.14), "pine_dark", seed + 999, 1)
    for root_index in range(5):
        angle = root_index * math.tau / 5 + 0.2
        cone(asset_id, f"root_{root_index}", (0, 0, 0.35), (math.cos(angle) * 2.0, math.sin(angle) * 2.0, 0.03), 0.33, 0.08, "bark_dark", 7)


def make_broadleaf(asset_id: str) -> None:
    height = 19.5
    add_branching_trunk(asset_id, 0.55, height, 311)
    branches = [
        ((0.2, 0.0, 9.0), (5.2, 1.4, 15.5)),
        ((0.0, 0.1, 10.2), (-4.6, 2.8, 16.3)),
        ((0.2, 0.0, 11.0), (2.0, -4.6, 17.4)),
    ]
    for index, (start, end) in enumerate(branches):
        cone(asset_id, f"crown_branch_{index}", start, end, 0.52, 0.13, "bark_mid", 8)
    canopies = [
        ((0.0, 0.0, 18.1), (5.4, 4.4, 3.7)),
        ((4.1, 1.1, 16.6), (4.0, 3.2, 2.9)),
        ((-4.0, 2.0, 16.8), (4.2, 3.4, 3.0)),
        ((1.3, -3.7, 17.2), (4.0, 3.2, 3.2)),
        ((-1.8, -2.1, 19.6), (3.8, 3.1, 2.6)),
    ]
    for index, (loc, scale) in enumerate(canopies):
        irregular_ico(asset_id, f"canopy_{index}", loc, scale, "leaf_mid" if index % 2 else "leaf_dark", 900 + index, 2)
    for root_index in range(7):
        angle = root_index * math.tau / 7
        cone(asset_id, f"root_{root_index}", (0, 0, 0.5), (math.cos(angle) * 2.4, math.sin(angle) * 2.4, 0.05), 0.42, 0.07, "bark_dark", 7)


def make_boulders(asset_id: str) -> None:
    specs = [
        ((-1.7, 0.0, 2.1), (3.3, 2.7, 2.3), 400),
        ((2.3, 0.7, 1.55), (2.4, 2.0, 1.7), 401),
        ((0.7, -1.7, 1.0), (1.8, 1.5, 1.2), 402),
        ((-3.0, -1.5, 0.65), (1.3, 1.1, 0.8), 403),
    ]
    for index, (loc, scale, seed) in enumerate(specs):
        irregular_ico(asset_id, f"stone_{index}", loc, scale, "stone" if index < 2 else "stone_dark", seed, 2)
    for index in range(5):
        irregular_ico(asset_id, f"moss_{index}", (-2.8 + index * 1.25, -0.5 + (index % 2) * 0.7, 3.5 - abs(index - 2) * 0.35), (0.9, 0.55, 0.22), "moss", 500 + index, 1)


def make_deadfall(asset_id: str) -> None:
    cone(asset_id, "fallen_trunk", (-7.5, 0, 1.2), (7.5, 0.8, 1.65), 1.2, 0.82, "bark_mid", 11)
    cone(asset_id, "broken_tip", (7.5, 0.8, 1.65), (8.1, 1.0, 1.9), 0.82, 0.06, "bark_cut", 7)
    for index, angle in enumerate((-1.15, -0.55, 0.55, 1.12)):
        start = (-7.1, 0.0, 1.15)
        tip = (-8.2, math.sin(angle) * 2.5, max(0.08, 1.0 + math.cos(angle) * 0.5))
        cone(asset_id, f"root_fan_{index}", start, tip, 0.34, 0.05, "bark_dark", 7)
    for index in range(7):
        x = -3.8 + index * 1.15
        cone(asset_id, f"mushroom_stem_{index}", (x, -0.75, 1.25), (x, -0.82, 1.7 + (index % 2) * 0.22), 0.09, 0.07, "bark_cut", 6)
        irregular_ico(asset_id, f"mushroom_cap_{index}", (x, -0.82, 1.77 + (index % 2) * 0.22), (0.36, 0.3, 0.12), "fungus", 610 + index, 1)
    for index in range(5):
        irregular_ico(asset_id, f"moss_{index}", (-5.0 + index * 2.4, 0.0, 2.05), (1.15, 0.78, 0.23), "moss", 620 + index, 1)


def make_root_arch(asset_id: str) -> None:
    left = [(-10.5, 0, 0), (-9.0, 0.2, 4.0), (-6.5, -0.1, 8.6), (-2.7, 0.2, 12.0), (0, 0, 13.3)]
    right = [(10.5, 0, 0), (8.8, -0.2, 4.3), (6.2, 0.2, 8.8), (2.6, -0.15, 12.1), (0, 0, 13.3)]
    for side_name, points in (("left", left), ("right", right)):
        for index in range(len(points) - 1):
            radius = 1.25 - index * 0.18
            cone(asset_id, f"{side_name}_arch_{index}", points[index], points[index + 1], radius, radius * 0.78, "bark_mid", 9)
    for side, sign in (("left", -1), ("right", 1)):
        for root_index in range(4):
            angle = -1.2 + root_index * 0.8
            cone(asset_id, f"{side}_ground_root_{root_index}", (sign * 9.8, 0, 1.0), (sign * (11.2 + root_index * 0.6), math.sin(angle) * 3.0, 0.08), 0.48, 0.07, "bark_dark", 7)
    for index in range(8):
        angle = index * math.tau / 8
        location = (math.cos(angle) * 1.45, math.sin(angle) * 0.7, 13.35 + math.sin(angle) * 0.25)
        irregular_ico(asset_id, f"crown_moss_{index}", location, (1.5, 0.8, 0.42), "moss", 700 + index, 1)
    for index in range(3):
        irregular_ico(asset_id, f"foxfire_{index}", (-1.4 + index * 1.35, -0.8, 11.8 + (index % 2) * 0.7), (0.23, 0.16, 0.38), "foxfire", 730 + index, 1)


def make_fern(asset_id: str) -> None:
    rng = random.Random(808)
    for frond in range(9):
        angle = frond * math.tau / 9 + rng.uniform(-0.18, 0.18)
        reach = rng.uniform(1.8, 2.5)
        tip = (math.cos(angle) * reach, math.sin(angle) * reach, rng.uniform(1.0, 2.0))
        cone(asset_id, f"stem_{frond}", (0, 0, 0.08), tip, 0.055, 0.025, "leaf_dark", 5)
        base = Vector((0, 0, 0.1))
        end = Vector(tip)
        direction = end - base
        for leaflet in range(1, 5):
            center = base + direction * (leaflet / 5)
            tangent = Vector((-math.sin(angle), math.cos(angle), 0))
            length = 0.46 * (1 - leaflet * 0.08)
            for side in (-1, 1):
                leaf_tip = center + tangent * side * length + Vector((0, 0, 0.12))
                leaf_plane(asset_id, f"leaf_{frond}_{leaflet}_{side}", center, leaf_tip, 0.14, "leaf_mid")


def make_hollow_lantern_shrine(asset_id: str) -> None:
    """Build a walk-through stump sanctuary from thick, readable forms."""
    pillars = [
        ((-4.7, -2.1, 0.0), (-4.0, -1.7, 12.2), 2.25, 1.35),
        ((4.7, -2.1, 0.0), (4.0, -1.7, 11.4), 2.30, 1.30),
        ((-4.5, 2.7, 0.0), (-3.8, 2.2, 11.0), 2.10, 1.20),
        ((4.5, 2.7, 0.0), (3.9, 2.2, 12.6), 2.15, 1.25),
        ((-6.0, 0.3, 0.0), (-5.1, 0.2, 9.5), 1.85, 1.05),
        ((6.0, 0.4, 0.0), (5.2, 0.1, 10.2), 1.90, 1.00),
    ]
    for index, (start, end, radius_start, radius_end) in enumerate(pillars):
        cone(
            asset_id,
            f"hollow_trunk_{index}",
            start,
            end,
            radius_start,
            radius_end,
            "bark_dark" if index % 3 == 0 else "bark_mid",
            9,
        )

    # Broken crown pieces bridge above both entrances while preserving a
    # player-sized opening through the centre of the landmark.
    crown_segments = [
        ((-4.0, -1.7, 11.7), (-1.0, -1.6, 15.7), 1.35, 0.95),
        ((4.0, -1.7, 10.9), (0.8, -1.6, 15.5), 1.30, 0.90),
        ((-3.8, 2.2, 10.5), (-0.8, 2.0, 14.8), 1.25, 0.82),
        ((3.9, 2.2, 12.1), (0.7, 2.0, 15.0), 1.30, 0.88),
        ((-1.0, -1.6, 15.7), (-0.5, -1.5, 18.0), 0.95, 0.36),
        ((0.8, -1.6, 15.5), (1.5, -1.4, 17.2), 0.90, 0.30),
    ]
    for index, (start, end, radius_start, radius_end) in enumerate(crown_segments):
        cone(asset_id, f"broken_crown_{index}", start, end, radius_start, radius_end, "bark_mid", 9)

    # Buttress roots keep the silhouette grounded from every camera angle.
    root_origins = [(-4.7, -2.1), (4.7, -2.1), (-4.5, 2.7), (4.5, 2.7), (-6.0, 0.3), (6.0, 0.4)]
    for index, (x, y) in enumerate(root_origins):
        outward = Vector((x, y, 0)).normalized()
        for fan in (-0.42, 0.42):
            direction = Vector(
                (
                    outward.x * math.cos(fan) - outward.y * math.sin(fan),
                    outward.x * math.sin(fan) + outward.y * math.cos(fan),
                    0,
                )
            )
            cone(
                asset_id,
                f"buttress_root_{index}_{fan}",
                (x, y, 0.8),
                (x + direction.x * 5.0, y + direction.y * 5.0, 0.08),
                0.72,
                0.10,
                "bark_dark",
                7,
            )

    # Hand-fitted braces tell the player this is shelter, not merely a tree.
    braces = [
        ((-6.0, -2.5, 3.2), (-3.8, -2.6, 7.9)),
        ((6.0, -2.5, 3.0), (3.8, -2.6, 7.4)),
        ((-5.8, 3.0, 3.5), (-3.7, 3.1, 7.7)),
        ((5.8, 3.0, 3.4), (3.8, 3.1, 8.0)),
    ]
    for index, (start, end) in enumerate(braces):
        cone(asset_id, f"timber_brace_{index}", start, end, 0.36, 0.29, "bark_cut", 6)

    # A fractured stone threshold makes the route through the shrine legible.
    for index, x in enumerate((-2.8, -0.9, 1.0, 2.9)):
        irregular_ico(
            asset_id,
            f"threshold_stone_{index}",
            (x, -2.4 + (index % 2) * 0.25, 0.28),
            (1.35, 1.1, 0.32),
            "stone" if index % 2 == 0 else "stone_dark",
            1200 + index,
            1,
        )

    # Three restrained lights create a memorable safe landmark without neon
    # washing the whole forest.
    lanterns = [(-4.9, -3.15, 6.5), (4.8, -3.12, 5.8), (0.0, -2.05, 13.9)]
    for index, location in enumerate(lanterns):
        irregular_ico(
            asset_id,
            f"lantern_glass_{index}",
            location,
            (0.38, 0.24, 0.62),
            "lantern_amber",
            1300 + index,
            1,
        )

    for index, location in enumerate(((-5.2, -2.0, 9.0), (5.3, 0.0, 7.5), (-3.6, 2.3, 12.0))):
        irregular_ico(
            asset_id,
            f"shrine_moss_{index}",
            location,
            (1.25, 0.65, 0.30),
            "moss",
            1400 + index,
            1,
        )


def make_wayfarer_cabin(asset_id: str) -> None:
    """Build an open-front camp cabin with a readable handmade silhouette."""
    box(asset_id, "floor", (0, 0, 0.35), (14.8, 12.4, 0.7), (0, 0, 0), "bark_cut", 0.12)

    # Separate uneven planks replace the single rectangular wall masses used
    # by the runtime placeholder while keeping the doorway fully open.
    for index in range(8):
        x = -6.2 + index * 1.78
        height = 7.5 + (index % 3) * 0.35
        box(
            asset_id,
            f"back_plank_{index}",
            (x, 5.65, height * 0.5 + 0.45),
            (1.65, 0.62, height),
            (0, math.radians((index % 3 - 1) * 1.4), math.radians((index % 2 - 0.5) * 1.2)),
            "bark_mid" if index % 3 else "bark_dark",
            0.10,
        )
    for side in (-1, 1):
        for index in range(6):
            y = -4.5 + index * 1.85
            height = 7.4 + (index % 2) * 0.45
            box(
                asset_id,
                f"side_plank_{side}_{index}",
                (side * 7.0, y, height * 0.5 + 0.45),
                (0.68, 1.72, height),
                (math.radians((index % 3 - 1) * 1.0), 0, math.radians(side * (index % 2) * 1.2)),
                "bark_mid" if index % 3 else "bark_dark",
                0.10,
            )

    for side in (-1, 1):
        cone(
            asset_id,
            f"door_post_{side}",
            (side * 5.3, -5.7, 0.5),
            (side * 5.0, -5.6, 8.5),
            0.52,
            0.42,
            "bark_dark",
            7,
        )
    cone(asset_id, "front_beam", (-5.2, -5.65, 8.2), (5.2, -5.65, 8.45), 0.52, 0.48, "bark_dark", 7)

    # Proper gabled roof panels create a shelter silhouette instead of a flat
    # slab. Their overhang protects the open porch and windows.
    box(
        asset_id,
        "roof_front",
        (0, -3.15, 9.75),
        (16.4, 7.4, 0.7),
        (math.radians(-29), 0, 0),
        "stone_dark",
        0.12,
    )
    box(
        asset_id,
        "roof_back",
        (0, 3.15, 9.75),
        (16.4, 7.4, 0.7),
        (math.radians(29), 0, 0),
        "stone_dark",
        0.12,
    )
    box(asset_id, "porch", (0, -7.0, 0.45), (10.5, 3.2, 0.42), (0, 0, 0), "bark_cut", 0.10)

    for side in (-1, 1):
        cone(
            asset_id,
            f"front_brace_{side}",
            (side * 5.1, -5.9, 2.0),
            (side * 2.8, -5.9, 7.8),
            0.26,
            0.20,
            "bark_cut",
            6,
        )

    box(asset_id, "chimney", (4.7, 2.7, 11.0), (2.0, 2.0, 5.0), (0, 0, 0), "stone", 0.18)
    for index, location in enumerate(((-5.8, 5.3, 7.9), (5.7, 5.25, 8.2), (-6.8, -0.5, 7.0))):
        irregular_ico(
            asset_id,
            f"roof_moss_{index}",
            location,
            (1.35, 0.65, 0.28),
            "moss",
            1600 + index,
            1,
        )


def make_lantern_post(asset_id: str) -> None:
    cone(asset_id, "post_lower", (0, 0, 0), (0.28, 0.05, 5.6), 0.48, 0.37, "bark_mid", 8)
    cone(asset_id, "post_upper", (0.28, 0.05, 5.4), (0.75, 0.0, 7.5), 0.38, 0.26, "bark_dark", 8)
    cone(asset_id, "crooked_arm", (0.65, 0, 7.15), (2.05, 0, 7.4), 0.30, 0.20, "bark_dark", 7)
    cone(asset_id, "arm_hook", (2.0, 0, 7.35), (2.0, 0, 6.75), 0.12, 0.09, "iron", 6)

    # Four cage rails and a faceted amber core stay legible without becoming a
    # giant neon sphere like the old placeholder.
    for rail_x in (-0.42, 0.42):
        for rail_y in (-0.34, 0.34):
            cone(
                asset_id,
                f"cage_rail_{rail_x}_{rail_y}",
                (2.0 + rail_x, rail_y, 5.2),
                (2.0 + rail_x * 0.72, rail_y * 0.72, 6.65),
                0.065,
                0.05,
                "iron",
                5,
            )
    box(asset_id, "cage_base", (2.0, 0, 5.15), (1.15, 0.95, 0.18), (0, 0, 0), "iron", 0.06)
    box(asset_id, "cage_cap", (2.0, 0, 6.65), (0.9, 0.76, 0.18), (0, 0, 0), "iron", 0.06)
    irregular_ico(asset_id, "amber_core", (2.0, 0, 5.9), (0.46, 0.36, 0.72), "lantern_amber", 1701, 1)
    for root_index in range(3):
        angle = root_index * math.tau / 3 + 0.3
        cone(
            asset_id,
            f"post_root_{root_index}",
            (0, 0, 0.25),
            (math.cos(angle) * 1.0, math.sin(angle) * 1.0, 0.04),
            0.20,
            0.04,
            "bark_dark",
            6,
        )


def make_crooked_farmhouse(asset_id: str) -> None:
    """Build Bramblewake's abandoned farm as a rooted, handmade landmark."""
    box(asset_id, "stone_foundation", (0, 0.3, 0.65), (18.5, 14.5, 1.3), (0, 0, 0), "stone_dark", 0.20)
    box(asset_id, "timber_floor", (0, -0.2, 1.2), (17.2, 13.0, 0.55), (0, 0, 0), "bark_cut", 0.12)

    # Uneven plank walls and an off-centre doorway make the facade readable at
    # route distance without turning it into another rectangular Roblox box.
    for index in range(9):
        x = -7.2 + index * 1.8
        height = 9.0 + (index % 3) * 0.35
        if index not in {4, 5}:
            box(
                asset_id,
                f"front_plank_{index}",
                (x, -6.35, height * 0.5 + 1.1),
                (1.65, 0.65, height),
                (0, math.radians((index % 3 - 1) * 1.2), math.radians((index % 2 - 0.5) * 1.4)),
                "bark_mid" if index % 3 else "bark_dark",
                0.10,
            )
        box(
            asset_id,
            f"back_plank_{index}",
            (x, 6.35, height * 0.5 + 1.1),
            (1.65, 0.65, height),
            (0, math.radians((index % 3 - 1) * -1.0), math.radians((index % 2 - 0.5) * -1.2)),
            "bark_mid" if index % 2 else "bark_dark",
            0.10,
        )
    for side in (-1, 1):
        for index in range(7):
            y = -5.25 + index * 1.75
            height = 8.8 + (index % 2) * 0.45
            box(
                asset_id,
                f"side_plank_{side}_{index}",
                (side * 8.15, y, height * 0.5 + 1.1),
                (0.65, 1.62, height),
                (math.radians((index % 3 - 1) * 1.1), 0, math.radians(side * (index % 2) * 1.0)),
                "bark_mid" if index % 3 else "bark_dark",
                0.10,
            )

    for side in (-1, 1):
        cone(asset_id, f"door_post_{side}", (side * 2.0, -6.7, 1.0), (side * 1.85, -6.65, 8.4), 0.38, 0.31, "bark_cut", 7)
    cone(asset_id, "door_lintel", (-2.2, -6.65, 8.2), (2.2, -6.65, 8.4), 0.40, 0.36, "bark_cut", 7)

    # Deep, asymmetrical gable with a repaired patch and chimney silhouette.
    box(asset_id, "roof_left", (-4.15, 0, 11.4), (10.6, 16.2, 0.85), (0, math.radians(-31), 0), "stone_dark", 0.14)
    box(asset_id, "roof_right", (4.15, 0, 11.4), (10.6, 16.2, 0.85), (0, math.radians(31), 0), "stone_dark", 0.14)
    box(asset_id, "roof_patch", (-2.0, -2.6, 13.65), (4.0, 5.0, 0.28), (0, math.radians(-31), math.radians(5)), "bark_cut", 0.08)
    box(asset_id, "chimney", (5.25, 2.8, 13.5), (2.1, 2.1, 6.2), (0, 0, math.radians(-2)), "stone", 0.20)
    box(asset_id, "porch", (0, -8.0, 1.1), (10.5, 3.8, 0.48), (0, 0, 0), "bark_cut", 0.10)

    for root_index in range(6):
        angle = root_index * math.tau / 6 + 0.18
        start = (math.cos(angle) * 7.6, math.sin(angle) * 5.9, 1.2)
        end = (math.cos(angle) * 11.3, math.sin(angle) * 9.0, 0.08)
        cone(asset_id, f"foundation_root_{root_index}", start, end, 0.46, 0.08, "bark_dark", 7)
    for index, location in enumerate(((-5.2, 2.5, 14.0), (2.0, 5.0, 13.9), (6.8, -1.0, 10.8))):
        irregular_ico(asset_id, f"roof_moss_{index}", location, (1.5, 0.8, 0.28), "moss", 1800 + index, 1)


def make_foxfire_windmill_tower(asset_id: str) -> None:
    """Build a root-swallowed mill tower while leaving its rotor functional."""
    cone(asset_id, "tapered_tower", (0, 0, 0.4), (0.35, 0.2, 29.0), 4.8, 3.45, "bark_mid", 10)
    for side in (-1, 1):
        for depth in (-1, 1):
            cone(
                asset_id,
                f"tower_brace_{side}_{depth}",
                (side * 3.7, depth * 3.25, 0.5),
                (side * 2.7, depth * 2.65, 28.2),
                0.36,
                0.24,
                "bark_dark",
                7,
            )
    cone(asset_id, "mill_cap", (0.35, 0.2, 28.5), (0.35, 0.2, 35.0), 6.0, 0.8, "stone_dark", 10)
    box(asset_id, "rotor_mount", (0.35, -4.0, 23.0), (3.3, 2.0, 3.3), (math.radians(5), 0, 0), "iron", 0.20)

    # Living roots visibly claim the mill without blocking the authored route.
    for index in range(5):
        angle = index * math.tau / 5 + 0.35
        cone(
            asset_id,
            f"swallowing_root_{index}",
            (math.cos(angle) * 3.4, math.sin(angle) * 3.4, 8.0 + (index % 2) * 3.5),
            (math.cos(angle) * 8.4, math.sin(angle) * 8.4, 0.08),
            0.95,
            0.12,
            "bark_dark",
            8,
        )
    for index, location in enumerate(((-3.2, 1.4, 18.0), (2.5, 2.7, 26.5), (0.5, -2.8, 31.0))):
        irregular_ico(asset_id, f"tower_moss_{index}", location, (1.2, 0.65, 0.3), "moss", 1900 + index, 1)
    for index, location in enumerate(((-3.5, -3.7, 13.0), (3.0, -3.4, 19.0), (0.4, -4.5, 27.0))):
        irregular_ico(asset_id, f"foxfire_memory_{index}", location, (0.24, 0.18, 0.42), "foxfire", 1950 + index, 1)


def asset_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    minimum = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maximum = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return minimum, maximum


def asset_triangles(objects: list[bpy.types.Object]) -> int:
    total = 0
    for obj in objects:
        if obj.type == "MESH":
            obj.data.calc_loop_triangles()
            total += len(obj.data.loop_triangles)
    return total


def consolidate_assets_by_material() -> None:
    """Collapse construction pieces to a small MeshPart budget per asset."""
    for asset_id, objects in list(ASSETS.items()):
        groups: dict[str, list[bpy.types.Object]] = {}
        for obj in objects:
            if obj.type != "MESH" or not obj.material_slots or not obj.material_slots[0].material:
                continue
            groups.setdefault(obj.material_slots[0].material.name, []).append(obj)
        consolidated: list[bpy.types.Object] = []
        for material_name, group in sorted(groups.items()):
            bpy.ops.object.select_all(action="DESELECT")
            for obj in group:
                obj.select_set(True)
            bpy.context.view_layer.objects.active = group[0]
            bpy.ops.object.join()
            joined = bpy.context.object
            joined.name = f"{asset_id}__{material_name.removeprefix('LL_')}"
            joined["lastLightAssetId"] = asset_id
            smooth_by_angle(joined)
            consolidated.append(joined)
        ASSETS[asset_id] = consolidated


def normalize_assets() -> None:
    """Center each asset on X/Y, ground it on Z, and size it exactly."""
    for asset_id, objects in ASSETS.items():
        minimum, maximum = asset_bounds(objects)
        dimensions = maximum - minimum
        target = TARGET_LONGEST_DIMENSIONS[asset_id]
        scale = target / max(dimensions)
        anchor = Vector(((minimum.x + maximum.x) * 0.5, (minimum.y + maximum.y) * 0.5, minimum.z))
        for obj in objects:
            obj.location = (obj.location - anchor) * scale
            obj.scale *= scale


def export_assets() -> dict[str, dict[str, object]]:
    measurements: dict[str, dict[str, object]] = {}
    for asset_id, objects in sorted(ASSETS.items()):
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        path = OUTPUT / f"{asset_id}.glb"
        bpy.ops.export_scene.gltf(
            filepath=str(path),
            export_format="GLB",
            use_selection=True,
            export_apply=True,
            export_yup=True,
            export_materials="EXPORT",
        )
        minimum, maximum = asset_bounds(objects)
        dimensions = maximum - minimum
        measurements[asset_id] = {
            "boundsMin": [round(value, 4) for value in minimum],
            "boundsMax": [round(value, 4) for value in maximum],
            "dimensions": [round(value, 4) for value in dimensions],
            "longestDimension": round(max(dimensions), 4),
            "triangles": asset_triangles(objects),
            "meshObjects": sum(1 for obj in objects if obj.type == "MESH"),
            "materials": sorted({slot.material.name for obj in objects if obj.type == "MESH" for slot in obj.material_slots if slot.material}),
            "bytes": path.stat().st_size,
        }
    (OUTPUT / "measurements.json").write_text(json.dumps({"schemaVersion": 1, "assets": measurements}, indent=2) + "\n")
    return measurements


def make_preview() -> None:
    placements = {
        "mesh_conifer_hero_a": (-28, 6, 0),
        "mesh_conifer_hero_b": (-16, 6, 0),
        "mesh_broadleaf_hero_a": (-2, 8, 0),
        "mesh_root_arch_a": (17, 8, 0),
        "mesh_hollow_lantern_shrine_a": (34, 8, 0),
        "mesh_wayfarer_cabin_a": (-15, 30, 0),
        "mesh_lantern_post_a": (24, -10, 0),
        "mesh_crooked_farmhouse_a": (10, 31, 0),
        "mesh_foxfire_windmill_tower_a": (38, 25, 0),
        "mesh_boulder_cluster_a": (-18, -10, 0),
        "mesh_deadfall_a": (0, -10, 0),
        "mesh_fern_cluster_a": (15, -10, 0),
    }
    for asset_id, objects in ASSETS.items():
        offset = Vector(placements[asset_id])
        minimum, _ = asset_bounds(objects)
        offset.z -= minimum.z
        for obj in objects:
            obj.location += offset

    bpy.ops.mesh.primitive_plane_add(size=110, location=(0, 0, -0.03))
    ground = bpy.context.object
    ground.data.materials.append(material("stone_dark"))

    world = bpy.context.scene.world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.008, 0.014, 0.021, 1)
    background.inputs["Strength"].default_value = 0.82

    bpy.ops.object.light_add(type="AREA", location=(-15, -20, 30))
    key = bpy.context.object
    key.data.energy = 3600
    key.data.use_shadow = False
    key.data.shape = "DISK"
    key.data.size = 18
    key.data.color = (1.0, 0.52, 0.25)
    key.rotation_euler = (Vector((0, 2, 8)) - key.location).to_track_quat("-Z", "Y").to_euler()

    bpy.ops.object.light_add(type="AREA", location=(18, 8, 26))
    fill = bpy.context.object
    fill.data.energy = 3200
    fill.data.use_shadow = False
    fill.data.size = 24
    fill.data.color = (0.22, 0.52, 1.0)
    fill.rotation_euler = (Vector((4, 4, 9)) - fill.location).to_track_quat("-Z", "Y").to_euler()

    bpy.ops.object.light_add(type="SUN", location=(0, 0, 30))
    moon = bpy.context.object
    moon.data.energy = 1.8
    moon.data.angle = math.radians(28)
    moon.data.color = (0.38, 0.55, 0.82)
    moon.rotation_euler = (math.radians(32), math.radians(-18), math.radians(-28))

    bpy.ops.object.camera_add(location=(86, -126, 58))
    camera = bpy.context.object
    direction = Vector((3, 5, 9.0)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 52
    bpy.context.scene.camera = camera

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(PREVIEW)
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)


def main() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for item in list(block):
            block.remove(item)

    make_conifer("mesh_conifer_hero_a", 27.0, 0.38, 101)
    make_conifer("mesh_conifer_hero_b", 24.0, 0.82, 202)
    make_broadleaf("mesh_broadleaf_hero_a")
    make_boulders("mesh_boulder_cluster_a")
    make_deadfall("mesh_deadfall_a")
    make_root_arch("mesh_root_arch_a")
    make_fern("mesh_fern_cluster_a")
    make_hollow_lantern_shrine("mesh_hollow_lantern_shrine_a")
    make_wayfarer_cabin("mesh_wayfarer_cabin_a")
    make_lantern_post("mesh_lantern_post_a")
    make_crooked_farmhouse("mesh_crooked_farmhouse_a")
    make_foxfire_windmill_tower("mesh_foxfire_windmill_tower_a")
    consolidate_assets_by_material()
    normalize_assets()
    measurements = export_assets()
    make_preview()
    print(json.dumps({"generated": sorted(measurements), "preview": str(PREVIEW)}))


if __name__ == "__main__":
    main()
