#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

blender --background --python-exit-code 1 --python scripts/generate_mesh_kit.py
blender --background --python-exit-code 1 --python scripts/prepare_mesh_candidate.py -- \
  --input assets/meshes/candidates/mesh_root_arch_tripo.glb \
  --output assets/meshes/generated/mesh_root_arch_a.glb \
  --preview assets/meshes/previews/mesh-root-arch-tripo.png \
  --report assets/meshes/candidates/mesh_root_arch_tripo_report.json \
  --asset-id mesh_root_arch_a \
  --target 25 \
  --max-triangles 8000 \
  --measurements assets/meshes/generated/measurements.json
python3 scripts/validate_mesh_assets.py
