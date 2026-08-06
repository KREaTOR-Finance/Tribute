# ForgeStudio

**Army of game-building agents** for Unreal Engine 5 + Blender + free asset studios.

This repo is both:
1. **Command HQ** — how the agent platoon designs, assets, builds, and ships
2. **First title workspace** — greenfield game under `games/first-title/`

## Stack

| Layer | Tool |
|-------|------|
| Engine | Unreal Engine **5.8+** (MCP plugin: Unreal MCP + All Toolsets) |
| 3D DCC | **Blender 4.x** via [blender-mcp](https://github.com/ahujasid/blender-mcp) |
| Assets | Free marketplaces (Epic Fab free, Quixel/Megascans free tier, OpenGameArt, Kenney, Poly Haven, Sketchfab CC0) |
| Agent runtime | Grok Build (`~/.grok` army + project `.grok/`) |

## Machine notes

- **Blender** is available on this host (`blender` CLI).
- **Unreal Editor** may run on a workstation with more RAM/GPU. MCP is loopback HTTP (`http://127.0.0.1:8000/mcp`) — agent CLI must share that machine or tunnel carefully (local only; no auth).
- This Linux box has ~7–8 GB RAM; full UE5 editor is tight. Prefer a 16 GB+ GPU machine for editor sessions.

## Quick start

```bash
cd ~/ForgeStudio

# 1) Read the army playbook
#    /game-ops-army   (or open ~/.grok/skills/game-ops-army/SKILL.md)

# 2) Blender MCP (with Blender open + addon enabled)
#    See docs/MCP-SETUP.md

# 3) Unreal MCP (UE 5.8+ editor, plugins enabled)
#    Auto Start Server → http://127.0.0.1:8000/mcp
#    Console: ModelContextProtocol.GenerateClientConfig All

# 4) Launch a platoon
#    /workflow game-studio-platoon  { "mission": "...", "root": "." }
#    /workflow vertical-slice       { "slice": "...", "root": "." }
#    /workflow asset-pipeline       { "brief": "...", "root": "." }
```

## Army (roles)

| Agent | Job |
|-------|-----|
| `game-producer` | Mission brief, scope, acceptance, sequencing |
| `game-systems-designer` | GDD, loops, economy, balance |
| `narrative-designer` | Story, VO briefs, quests, tone |
| `unreal-engineer` | UE5 C++/Blueprints, systems, MCP-driven editor work |
| `blender-artist` | Model / UV / rig / export via Blender MCP |
| `technical-artist` | Materials, LODs, VFX, performance budgets |
| `level-designer` | Blockout, flow, encounters, lighting intent |
| `asset-quartermaster` | Free asset sourcing, license ledger, import standards |
| `qa-tester` | Playtest plans, automation, regression |
| `code-reviewer` / `security-auditor` | Code quality & threat model |

## Repo layout

```
ForgeStudio/
  AGENTS.md                 # Rules for every agent
  docs/                     # MCP setup, free asset playbook
  design/                   # GDD, pillars, vertical-slice brief
  assets/
    source/                 # Blender .blend masters
    imported/               # Engine-ready FBX/glTF/textures
    free/                   # Downloaded free packs (gitignored bulk)
    licenses/               # LICENSE ledger per pack
  games/first-title/        # UE project root (once created in editor)
  tools/                    # scripts, MCP helpers
  .grok/                    # project workflows / overrides
```

## First title

Working codename lives in `design/GDD.md`. Fill pillars + core loop before asset spam.
