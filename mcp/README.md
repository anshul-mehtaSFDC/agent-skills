# agent-skills MCP server

Exposes the repo's skills (`skills/<category>/<name>/SKILL.md`) to any MCP-capable
client — Claude Code, Claude Desktop, Cursor, Codex — over a single connection.
The same skill content the installer copies is served live; edit a `SKILL.md` and
every connected client sees the change on the next call (no reinstall).

## MCP vs. the installer

| | Installer (`../install.sh`) | This MCP server |
|---|---|---|
| Delivery | Copies files into each tool | One live connection |
| Updates | Re-run per machine | Central — edit repo, clients are current |
| Auto-trigger | ✅ Native skills fire from `description` | ⚠️ Model must choose to call `get_skill` |
| Needs | Nothing | Node ≥18 + a running server process |

Use the installer for hands-off auto-triggering skills; use the MCP for centralized,
always-fresh access across many clients. They're complementary.

## What it exposes

- **Tools:** `list_skills`, `get_skill(name)`, `search_skills(query)`
- **Prompts:** one per skill (e.g. `diagram-architect`) — clients that support MCP prompts show them natively
- **Resources:** `skill://<name>` — each `SKILL.md` as a readable markdown resource

## Build

```bash
cd mcp
npm install
npm run build     # compiles src/ -> dist/index.js
```

## Run / configure in a client

The server speaks stdio. Point your client at `node /abs/path/to/agent-skills/mcp/dist/index.js`.
By default it reads `../skills`; override with the `AGENT_SKILLS_DIR` env var.

### Claude Code
```bash
claude mcp add agent-skills -- node /abs/path/to/agent-skills/mcp/dist/index.js
```

### Claude Desktop / Cursor / Codex — `mcp.json` / config
```json
{
  "mcpServers": {
    "agent-skills": {
      "command": "node",
      "args": ["/abs/path/to/agent-skills/mcp/dist/index.js"],
      "env": { "AGENT_SKILLS_DIR": "/abs/path/to/agent-skills/skills" }
    }
  }
}
```
- **Claude Desktop:** `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)
- **Cursor:** Settings → MCP, or a project `.cursor/mcp.json`
- **Codex:** its MCP config file

Restart the client after adding. Then ask the model to *list skills* or *use the
diagram-architect skill* and it will call the tools / load the prompt.

## Notes

- **stdout is the MCP channel** — the server logs only to stderr.
- Skills are re-read on every request, so `SKILL.md` edits are picked up live.
- No network access; everything is local files.
