# Asset License Ledger

Every free or third-party pack used in the project **must** have a row here before import to the Unreal project.

| Pack ID | Source | Path | License | Commercial OK? | URL | Added | Notes |
|---------|--------|------|---------|----------------|-----|-------|-------|
| tribune-proxy-exports | In-house Blender script | `assets/imported/tribune_proxies/` | All rights reserved (project original) | Yes | tools/scripts/export_slice_proxies.py | 2026-08-05 | Greybox proxies; original generation |
| unreal-engine-basicshapes | Epic Games | Engine runtime | Epic EULA | Yes (with UE) | Engine/BasicShapes | 2026-08-05 | Runtime cubes/spheres only |

## How to add a pack

1. Download to `assets/free/<source>/<pack>/`
2. Copy license text into `assets/licenses/texts/<pack-id>.txt` if not in pack
3. Add a ledger row
4. Only then import to Unreal Content

| polyhaven-pbr-hdri | Poly Haven | `assets/free/polyhaven/` | CC0 | Yes | https://polyhaven.com | 2026-08-05 | rock/wood/metal + HDRI for Tribunal demo |
