CC0 Melee Impact Sounds - Place .ogg or .wav here

Recommended sources (all CC0 or public domain):
1. Kenney.nl "UI Audio" or "Impact" packs - https://kenney.nl/assets (search audio)
2. OpenGameArt.org search "sword hit" + CC0 filter
3. Freesound.org (CC0 tag) - sword clash, axe hit, metal impact, flesh thud

Example files to add:
- light_hit.ogg   (quick sword jab)
- heavy_hit.ogg   (axe smash)
- block.ogg       (shield or parry clang)
- death.ogg       (optional heavy impact)

When files are present, PlayerController will play them on hit using AudioStreamPlayer3D.
For now the system is silent or can use Godot's built-in AudioStreamPlayer with a beep if needed.
