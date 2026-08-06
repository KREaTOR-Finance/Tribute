#!/bin/bash
# The Culling - High Autonomy Melee Assets Downloader
# CC0 / Permissive sources only.
# Run from project root: bash scripts/download_melee_assets.sh

set -e

ASSETS_DIR="assets"
mkdir -p $ASSETS_DIR/{models/weapons,models/characters,models/props,audio/impacts}

echo "=== THE CULLING MELEE ASSETS DOWNLOADER ==="
echo "Downloading CC0 assets for sword/axe/dagger feel + arena props + impacts."
echo ""

# === KENNEY (always CC0, excellent low-poly, Godot friendly) ===
# Pirate Kit: swords/cutlasses + barrels/crates (perfect props + weapons)
# Note: Kenney direct zips are usually at https://kenney.nl/assets/zip/<slug> or via their site.
# We use the reliable direct pattern when known. If it fails, use the website "Download" button.

echo "→ Pirate Kit (Kenney - CC0) - weapons + props"
if command -v wget &> /dev/null; then
    wget -q --show-progress -O /tmp/pirate-kit.zip "https://kenney.nl/assets/zip/pirate-kit" || echo "  (direct may have changed - use browser download from https://kenney.nl/assets/pirate-kit)"
else
    curl -L -o /tmp/pirate-kit.zip "https://kenney.nl/assets/zip/pirate-kit" || echo "  (use browser)"
fi

# === OPENGAMEART (CC0 filtered) ===
echo ""
echo "→ Low Poly Sword 3D (mujtaba-io - CC0)"
# Direct .blend from the page
wget -q --show-progress -O $ASSETS_DIR/models/weapons/lowpoly_sword.blend "https://opengameart.org/sites/default/files/sword.blend" || echo "  Manual: https://opengameart.org/content/low-poly-sword-3d-model"

echo ""
echo "→ 3D Swords pack (Lyricsz - CC0)"
wget -q --show-progress -O $ASSETS_DIR/models/weapons/swords_pack.blend "https://opengameart.org/sites/default/files/swords.blend" || echo "  Manual: https://opengameart.org/content/3d-swords"

# === SOUNDS (CC0 melee impacts) ===
# We search for reliable direct audio. Common good sources:
echo ""
echo "→ Searching for CC0 sword/impact sounds (manual step often needed)"
echo "  Recommended manual downloads (CC0):"
echo "  - https://opengameart.org (search 'sword hit' or 'metal impact' + CC0 filter)"
echo "  - Kenney 'UI Audio' or 'Impact' packs"
echo "  - https://freesound.org (CC0 tag) for 'sword clash', 'axe hit', 'flesh impact'"

# === FUTURE / ADDITIONAL ===
# Add more direct links here as we curate:
# - Warrior model
# - Modular props (crates, walls)
# - More impact variants

echo ""
echo "=== DOWNLOAD COMPLETE (or partial) ==="
echo "Next steps:"
echo "1. Unzip pirate-kit.zip into assets/models/props/ and assets/models/weapons/ if it succeeded."
echo "2. Open any .blend in Blender → File > Export > glTF 2.0 (.glb) for best Godot import."
echo "3. Place .glb files in assets/models/weapons/ (sword.glb, axe.glb, dagger.glb)"
echo "4. Run Godot and import. Then attach to players via WeaponVisual."
echo ""
echo "For sounds: Drop .ogg/.wav into assets/audio/impacts/ (light_hit.ogg, heavy_hit.ogg, block.ogg)"
echo ""
echo "Current status: Placeholders + weapon profiles already work. These assets will make it feel real."
