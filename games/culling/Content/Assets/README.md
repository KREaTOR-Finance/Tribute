# Culling — Asset System (First-Class)

This folder is the **source of truth** for every art asset in the spiritual successor to *The Culling*.

**Rule:** Describe before model. Spec before polish. Ledger before third-party import.

## Layout

```
Content/Assets/
  README.md                 ← you are here
  Descriptions/             ← visual goals + gameplay role (required first)
    Characters/
    Weapons/
    Tools/
    Environments/
    Props/
    VFX/
    UI/
  Specs/                    ← polycounts, LODs, textures, memory
  Source/                   ← Blender notes / export recipes (mirrors assets/source)
  Optimized/                ← console-ready variants notes
```

Related studio paths (outside Content):

| Path | Role |
|------|------|
| `~/ForgeStudio/assets/source/` | `.blend` masters |
| `~/ForgeStudio/assets/imported/` | Engine-ready FBX/glTF |
| `~/ForgeStudio/assets/free/` | Free packs (gitignored bulk) |
| `~/ForgeStudio/assets/licenses/LEDGER.md` | License law |

## Pipeline

```
1. Description  → Descriptions/<Category>/<AssetId>.md
2. Specs        → Specs/<AssetId>.md  (or section in description)
3. Blender MCP  → build / iterate  → assets/source/
4. Export       → assets/imported/<pack>/
5. Unreal import→ Content/ThirdParty/... or Content/Gameplay/...
6. Optimize     → LODs, collision, materials; notes in Optimized/
7. Critic pass  → visual quality + console fitness
```

## Naming

| Prefix | Use |
|--------|-----|
| `SK_` | Skeletal mesh |
| `SM_` | Static mesh |
| `T_` | Texture |
| `M_` / `MI_` | Material / instance |
| `WPN_` | Weapon data asset |
| `CHAR_` | Character |

## Description template

Copy `_TEMPLATE.md` from any Descriptions category.

## MCP

- **Blender MCP** — create/iterate 3D
- **Unreal MCP** — place, materials, validate in editor (`http://127.0.0.1:8000/mcp`)

## Gauntlet

Assets is a full Gauntlet system: Builder (quartermaster + blender + tech art) vs Assets Critic (blind quality + console budgets).
