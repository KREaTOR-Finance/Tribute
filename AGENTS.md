# ForgeStudio — Agent Rules

You are part of the **Game Forge Army**. Build a shippable Unreal 5 game with Blender + free asset studios. Prefer small vertical slices over sprawling systems.

## Stack pins

- **Engine:** Unreal Engine 5.8+ with experimental **Unreal MCP** + **All Toolsets**
- **DCC:** Blender 4.x + blender-mcp (socket + MCP server)
- **Assets:** Free / CC0 / Epic free only unless user explicitly approves paid
- **MCP Unreal default:** `http://127.0.0.1:8000/mcp` (loopback only)
- **Languages:** C++ for core systems when needed; Blueprints for iteration; Python for editor toolsets

## Non-negotiables

1. **License before import.** Every free pack needs a row in `assets/licenses/LEDGER.md`. No mystery assets in Content.
2. **GDD drives code.** If implementation diverges, update `design/GDD.md` or stop and flag the conflict.
3. **Vertical slice first.** Playable loop > content volume. No open-world until slice is fun.
4. **Performance budgets** live in `design/BUDGETS.md`. LODs, texture sizes, draw calls — respect them.
5. **MCP is local.** Never expose Unreal/Blender MCP beyond localhost. No secrets in Content or commits.
6. **Small diffs.** One mission, one surface when possible. No drive-by refactors.
7. **Evidence.** Don't claim "built in editor" without MCP tool results, screenshots paths, or log snippets.

## Workspace map

| Path | Owner roles |
|------|-------------|
| `design/` | producer, systems, narrative, level |
| `assets/source/` | blender-artist |
| `assets/imported/`, `assets/free/` | quartermaster, tech art |
| `assets/licenses/` | quartermaster (all write; all must read) |
| `games/first-title/` | unreal-engineer, level, tech art, QA |
| `tools/` | unreal-engineer, devops |

## MCP usage

### Unreal (editor running)

1. Discover tools: `list_toolsets` → `describe_toolset` → `call_tool` (tool-search mode is default).
2. One tool call at a time when mutating the scene (game-thread serial).
3. After authoring Python toolsets: user runs `ModelContextProtocol.RefreshTools` in editor.

### Blender (Blender + addon + blender-mcp)

1. Prefer scene inspection before destructive ops.
2. Export to `assets/imported/` with consistent scale (cm or UE units: 1 uu = 1 cm).
3. Keep masters in `assets/source/*.blend`.

## Definition of done (feature)

- [ ] Spec note in design or ticket acceptance
- [ ] Assets licensed + ledgered
- [ ] Works in PIE / automated test if available
- [ ] Budget check if art-heavy
- [ ] Short handoff: files, how to play, known issues

## Anti-patterns

- Random marketplace packs with unclear licenses
- Nanite/Lumen mega-scenes on low-RAM machines without LODs
- "I'll polish later" core-loop bugs
- Hardcoded absolute paths to one developer's drive
- Committing multi-GB free packs without LFS policy
