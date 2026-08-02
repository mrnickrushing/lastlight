"""Downscale the packed textures inside a generated GLB, in place.

Meshy returns 2048-square PBR sets. That is generous for props a player sees
at gameplay distance, and four of them on one asset is real memory on a phone.
This halves each map to 1024 and re-exports, which is a texture-memory saving
of about four times per asset with no change to geometry, UVs, or scale.

  blender --background --python scripts/downscale_mesh_textures.py -- \
    --input assets/meshes/generated/mesh_zombie_a.glb --max-size 1024

Run scripts/prepare_mesh_candidate.py afterwards so the manifest's measured
byte count and texture list match what is now on disk; validate_mesh_assets.py
compares them and will fail if they drift.
"""

from __future__ import annotations

import argparse
import sys

import bpy


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--max-size", type=int, default=1024)
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.input)

    resized = 0
    for image in bpy.data.images:
        if image.size[0] <= args.max_size and image.size[1] <= args.max_size:
            continue
        width = min(image.size[0], args.max_size)
        height = min(image.size[1], args.max_size)
        image.scale(width, height)
        image.pack()
        resized += 1

    bpy.ops.export_scene.gltf(
        filepath=args.input,
        export_format="GLB",
        export_materials="EXPORT",
        export_yup=True,
    )
    print(f"DOWNSCALED {args.input} images={resized} max={args.max_size}")


if __name__ == "__main__":
    main()
