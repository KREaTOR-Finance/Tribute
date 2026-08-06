# Tribunal

**Console-ready melee battle royale.**  
**Reference bar:** *The Culling* (combat soul — not the product name).

| | |
|--|--|
| **Product** | **Tribunal** |
| **Reference** | *The Culling* |
| **Playable now** | `games/tribunal/` (Godot 4.3) · `./dist/run-tribunal.sh` |
| **Ship / console path** | `games/culling/` (Unreal 5.8+ module; still branded Tribunal) |
| **Repo** | https://github.com/KREaTOR-Finance/Tribute |
| **Identity** | `design/PRODUCT.md` |
| **GDD** | `design/GDD.md` |
| **Method** | Gauntlet Loop (builder ≠ critic) |

## Play the slice

```bash
cd ~/ForgeStudio
./dist/run-tribunal.sh
```

Godot 4.3: `~/tools/Godot_v4.3-stable_linux.x86_64` (or set `GODOT=`).

**Round:** INTRO → FIGHT (scavenge, traps, hunters, zone) → **FINISH BOARD** → **R** rematch.

## Product vs reference

- **Tribunal** = what we ship (name on UI, launcher, store later).
- **The Culling** = feel bar we must meet or beat. We do not brand as Culling.

## Stack

| Layer | Tech |
|-------|------|
| Vertical slice | Godot 4.3 · MeleeTest finished arena |
| Production / console | Unreal Engine 5.8+ · `Culling.uproject` (path only) |
| Assets | Free / CC0 (Poly Haven ledger) |
| Quality | Gauntlet · `design/gauntlet/` |

## Docs

- `design/PRODUCT.md` — naming freeze  
- `design/GDD.md` — design  
- `design/BUDGETS.md` — console budgets  
- `design/gauntlet/STATE.md` — live board  
