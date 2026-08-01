"""Inspect, normalize, budget, and preview a GLB candidate with Blender.

Example:
  blender --background --python scripts/prepare_mesh_candidate.py -- \
    --input candidate.glb --output prepared.glb --preview preview.png \
    --report report.json --asset-id mesh_root_arch_a --target 25 --max-triangles 8000
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


def parse_args() -> argparse.Namespace:
    import sys

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--preview", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--asset-id", required=True)
    parser.add_argument("--target", required=True, type=float)
    parser.add_argument("--max-triangles", required=True, type=int)
    parser.add_argument("--measurements")
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1 :])


def bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    return (
        Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points))),
        Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points))),
    )


def triangle_count(objects: list[bpy.types.Object]) -> int:
    total = 0
    for obj in objects:
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    return total


def texture_report(objects: list[bpy.types.Object]) -> list[dict[str, object]]:
    seen: set[str] = set()
    result: list[dict[str, object]] = []
    for obj in objects:
        for slot in obj.material_slots:
            mat = slot.material
            if not mat or not mat.use_nodes:
                continue
            for node in mat.node_tree.nodes:
                if node.type != "TEX_IMAGE" or not node.image or node.image.name in seen:
                    continue
                seen.add(node.image.name)
                result.append(
                    {
                        "name": node.image.name,
                        "width": node.image.size[0],
                        "height": node.image.size[1],
                        "packed": node.image.packed_file is not None,
                    }
                )
    return sorted(result, key=lambda item: str(item["name"]))


def repository_path(path: Path) -> str:
    try:
        return str(path.relative_to(Path(__file__).resolve().parents[1]))
    except ValueError:
        return path.name


def main() -> None:
    args = parse_args()
    source = Path(args.input).resolve()
    output = Path(args.output).resolve()
    preview = Path(args.preview).resolve()
    report_path = Path(args.report).resolve()
    for path in (output, preview, report_path):
        path.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(source))

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("candidate contains no mesh geometry")
    for obj in list(bpy.context.scene.objects):
        if obj.type not in {"MESH", "EMPTY"}:
            bpy.data.objects.remove(obj, do_unlink=True)

    before = triangle_count(meshes)
    if before > args.max_triangles:
        ratio = args.max_triangles / before
        for obj in meshes:
            modifier = obj.modifiers.new(name="LastLightTriangleBudget", type="DECIMATE")
            modifier.ratio = ratio
            modifier.use_collapse_triangulate = True
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier=modifier.name)

    minimum, maximum = bounds(meshes)
    dimensions = maximum - minimum
    scale = args.target / max(dimensions)
    anchor = Vector(((minimum.x + maximum.x) * 0.5, (minimum.y + maximum.y) * 0.5, minimum.z))
    for obj in meshes:
        obj.location = (obj.location - anchor) * scale
        obj.scale *= scale
        obj.name = f"{args.asset_id}__{obj.name}"
        obj["lastLightAssetId"] = args.asset_id

    bpy.context.view_layer.update()
    final_minimum, final_maximum = bounds(meshes)
    final_dimensions = final_maximum - final_minimum
    textures = texture_report(meshes)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
    )

    report = {
        "schemaVersion": 1,
        "assetId": args.asset_id,
        "source": repository_path(source),
        "output": repository_path(output),
        "targetLongestDimension": args.target,
        "boundsMin": [round(value, 4) for value in final_minimum],
        "boundsMax": [round(value, 4) for value in final_maximum],
        "dimensions": [round(value, 4) for value in final_dimensions],
        "longestDimension": round(max(final_dimensions), 4),
        "trianglesBefore": before,
        "trianglesAfter": triangle_count(meshes),
        "meshObjects": len(meshes),
        "materialSlots": sum(len(obj.material_slots) for obj in meshes),
        "textures": textures,
        "bytes": output.stat().st_size,
    }
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    if args.measurements:
        measurements_path = Path(args.measurements).resolve()
        measurements = json.loads(measurements_path.read_text())
        measurements["assets"][args.asset_id] = {
            "boundsMin": report["boundsMin"],
            "boundsMax": report["boundsMax"],
            "dimensions": report["dimensions"],
            "longestDimension": report["longestDimension"],
            "triangles": report["trianglesAfter"],
            "meshObjects": report["meshObjects"],
            "materials": ["embedded_pbr"],
            "textures": report["textures"],
            "bytes": report["bytes"],
        }
        measurements_path.write_text(json.dumps(measurements, indent=2) + "\n")

    bpy.ops.mesh.primitive_plane_add(size=args.target * 2.8, location=(0, 0, -0.03))
    ground = bpy.context.object
    ground_mat = bpy.data.materials.new("LastLightPreviewGround")
    ground_mat.diffuse_color = (0.025, 0.045, 0.055, 1)
    ground_mat.use_nodes = True
    ground_shader = ground_mat.node_tree.nodes.get("Principled BSDF")
    ground_shader.inputs["Base Color"].default_value = ground_mat.diffuse_color
    ground_shader.inputs["Roughness"].default_value = 0.95
    ground.data.materials.append(ground_mat)

    world = bpy.context.scene.world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.005, 0.012, 0.020, 1)
    background.inputs["Strength"].default_value = 0.75

    def area_light(location: tuple[float, float, float], color: tuple[float, float, float], energy: float) -> None:
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.data.energy = energy
        light.data.size = args.target * 0.8
        light.data.color = color
        light.rotation_euler = (Vector((0, 0, args.target * 0.25)) - light.location).to_track_quat("-Z", "Y").to_euler()

    area_light((-args.target, -args.target, args.target * 1.3), (1.0, 0.55, 0.28), 3600)
    area_light((args.target, args.target * 0.3, args.target * 1.1), (0.24, 0.52, 1.0), 3000)
    bpy.ops.object.light_add(type="SUN", location=(0, 0, args.target))
    bpy.context.object.data.energy = 1.0
    bpy.context.object.rotation_euler = (math.radians(28), math.radians(-20), math.radians(-32))

    camera_distance = args.target * 1.65
    bpy.ops.object.camera_add(location=(camera_distance, -camera_distance, args.target * 0.95))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, 0, args.target * 0.32)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 55
    bpy.context.scene.camera = camera

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1100
    scene.render.resolution_y = 1100
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(preview)
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = 1.0
    bpy.ops.render.render(write_still=True)
    print(json.dumps(report))


if __name__ == "__main__":
    main()
