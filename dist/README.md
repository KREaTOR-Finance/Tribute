# Tribunal — The Culling Mirror

Main scene: **MeleeTest** (same spine as The Culling Godot prototype).

## Run

```bash
cd ~/ForgeStudio
./dist/run-tribunal.sh
```

## Culling controls (mirrored)

| | P1 | P2 |
|--|----|----|
| Move | WASD + mouse | IJKL |
| Light | LMB | U |
| Heavy windup | RMB | O |
| Block | Space | P |
| Shove | F | ; |
| Weapons | 1 Sword · 2 Axe · 3 Dagger | 4/5/6 |

ESC mouse · TAB swap follow cam · R restart

## What is live

- PlayerController Culling melee soul (hitstop, knockback, particles, stamina)
- 2P hotseat in MeleeTest arena
- Weapon profiles + WeaponVisual
- Poly Haven PBR ground/crates/barrels + HDRI
- Team-colored bodies (red/blue)

## Unreal

`games/culling/Culling.uproject` on GPU UE 5.8+
