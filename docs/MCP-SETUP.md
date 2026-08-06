# MCP Setup — Unreal 5.8+ & Blender

## Unreal MCP (official, experimental)

Source: [Unreal MCP in Unreal Editor](https://dev.epicgames.com/documentation/unreal-engine/unreal-mcp-in-unreal-editor)

### Enable plugins

1. Edit → Plugins
2. Enable **Unreal MCP** (identifier: `ModelContextProtocol`)
3. Enable **All Toolsets** (or pick individual toolsets)
4. Restart editor

### Auto-start server

1. Edit → Editor Preferences → General → **Model Context Protocol**
2. Enable **Auto Start Server**
3. Default bind: `http://127.0.0.1:8000/mcp`
4. Server name: `unreal-mcp`

Console alternatives:

```
ModelContextProtocol.StartServer 8000
ModelContextProtocol.StopServer
ModelContextProtocol.RefreshTools
ModelContextProtocol.GenerateClientConfig All
```

### Client config (Grok / Claude / Cursor)

From editor console after server is up:

```
ModelContextProtocol.GenerateClientConfig All
```

Writes project-root configs. For Grok user config (`~/.grok/config.toml`):

```toml
[mcp_servers.unreal]
url = "http://127.0.0.1:8000/mcp"
enabled = true
# Only works when UE editor is running on this machine
```

Or project `.mcp.json`:

```json
{
  "mcpServers": {
    "unreal-mcp": {
      "type": "http",
      "url": "http://127.0.0.1:8000/mcp"
    }
  }
}
```

### Tool discovery

Default is **tool-search mode**:

1. `list_toolsets`
2. `describe_toolset`
3. `call_tool`

Mutating tools run on the **game thread serially** — do not fire overlapping writes.

### Safety

- Loopback only, **no auth**
- Never bind to LAN/WAN
- Do not commit secrets into toolsets

---

## Blender MCP

Primary open server: [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)

### Components

1. **Blender addon** — socket server inside Blender
2. **MCP server** — `uvx blender-mcp` (or installed package)

### Install outline

1. Install Blender 4.x (this host: system package 4.0.2)
2. Install the blender-mcp addon into Blender Preferences → Add-ons
3. Start Blender, enable the addon, ensure the socket is listening
4. Add MCP server to Grok:

```toml
[mcp_servers.blender]
command = "uvx"
args = ["blender-mcp"]
enabled = true
startup_timeout_sec = 60
```

### Agent workflow

1. Inspect scene (objects, materials)
2. Create / modify geometry
3. UV / simple materials as needed
4. Export FBX/glTF → `assets/imported/<pack>/`
5. Keep `.blend` in `assets/source/`

### Scale convention

- Unreal: **1 uu = 1 cm**
- Export with Apply Transform; document axis (Y-up Blender → UE)

---

## Health check checklist

| Check | How |
|-------|-----|
| Blender CLI | `blender --version` |
| blender-mcp | `uvx blender-mcp` starts without crash (Blender must be open for full tools) |
| Unreal MCP | Browser/Inspector → `http://127.0.0.1:8000/mcp` with editor up |
| Grok sees tools | `search_tool` / `grok mcp list` |

## This machine status (scaffold day)

| Component | Status |
|-----------|--------|
| Blender 4.0.2 | Installed |
| uv / uvx | Installed |
| Unreal Editor | Not on PATH — install UE 5.8+ on a GPU workstation if needed |
| RAM | ~7–8 GB — prefer external UE machine for editor |
