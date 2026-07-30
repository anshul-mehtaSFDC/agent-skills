# agent-skills

A portable collection of AI-agent **skills** (and rules) usable from
**Claude Code**, **Cursor**, or **Codex** two ways:

1. **Installer** — copies/converts skills into each tool at **project** or **global** scope (native auto-triggering).
2. **MCP server** — serves skills live over one connection to any MCP client (centralized, always-fresh). See [`mcp/`](mcp/README.md).

Tool-neutral: the same `SKILL.md` content is copied, format-converted, or served as-is.

---

## Table of contents
- [Requirements & OS support](#requirements--os-support)
- [Install](#install)
- [What installs where](#what-installs-where)
- [Using skills per tool](#using-skills-per-tool)
- [Use as an MCP server](#use-as-an-mcp-server)
- [Repository layout](#repository-layout)
- [Contribution guidelines](#contribution-guidelines)
- [Troubleshooting](#troubleshooting)

---

## Requirements & OS support

The installer is a POSIX **bash** script — no runtime, no dependencies beyond
`bash`, `git`, and coreutils (all present by default on macOS/Linux).

| OS | How to run | Notes |
|---|---|---|
| **macOS** | `./install.sh` in Terminal | Works out of the box (bash 3.2+). |
| **Linux** | `./install.sh` in any shell | Works out of the box. |
| **Windows — WSL** (recommended) | `./install.sh` inside your WSL distro | Installs to the paths your WSL tools use. Run it from the same environment your LLM/IDE runs in. |
| **Windows — Git Bash** | `bash install.sh` | Fine for Cursor project rules and Claude paths under your user home. |
| **Windows — PowerShell/CMD** | not supported directly | Use WSL or Git Bash. (A native `.ps1` port can be added later.) |

> Windows path note: Claude/Codex user-scope paths resolve under your home
> (`%USERPROFILE%` ≈ `~`). If you run your agent inside WSL, install inside WSL so
> the `~` matches.

If `./install.sh` reports "permission denied", run `chmod +x install.sh` first, or
invoke it as `bash install.sh`.

---

## Install

```bash
git clone <repo-url> agent-skills
cd agent-skills
./install.sh            # interactive: pick tool, scope, and skills
```

The interactive flow asks three things. **Tools and skills use a checkbox picker** —
`↑`/`↓` (or `j`/`k`) to move, **SPACE to toggle**, `a` to select all, ENTER to confirm,
`q` to cancel:
1. **Tool(s)** — check any of Claude Code / Cursor / Codex
2. **Scope** — `project` (one repo) / `global` (all your projects)
3. **Skills** — check any (menu grouped by category with descriptions)

> If run without a terminal (piped/CI), it falls back to a text prompt (comma-separated
> numbers/names, or `all`). Force the fallback with `AGENT_SKILLS_NO_TUI=1`.

Non-interactive (CI / scripting) — `--tool` and `--skills` both accept comma lists or `all`:
```bash
./install.sh --tool claude --scope global  --skills all
./install.sh --tool claude,cursor,codex --scope global --skills all      # every tool
./install.sh --tool all --scope project --dir /path --skills diagram-architect,foo
./install.sh --tool cursor --scope project --dir /path/to/project --skills diagram-architect
./install.sh --list                        # show all skills, grouped by category
./install.sh --uninstall --tool claude,cursor --scope global --skills diagram-architect
```

---

## What installs where

| Tool | Scope | Destination | Format |
|---|---|---|---|
| Claude Code | global | `~/.claude/skills/<name>/` | whole folder (SKILL.md + references/ + assets) |
| Claude Code | project | `<project>/.claude/skills/<name>/` | whole folder |
| Cursor | project | `<project>/.cursor/rules/<name>.mdc` | one rule; references bundled inline |
| Cursor | global | `~/.cursor/rules/<name>.mdc` | converted (see note) |
| Codex | global | `~/.agents/skills/<name>/` | whole folder (cross-runtime path) |
| Codex | project | `<project>/.agents/skills/<name>/` | whole folder |

- **Folder skills:** a skill may be a folder — `SKILL.md` (the router, always loaded) plus
  a `references/` dir and assets that the agent reads on demand. Claude/Codex get the whole
  folder; the installer copies it intact.
- **Cursor** uses a single *rule* (`.mdc`) that can't reference sibling files, so the installer
  **bundles `references/*.md` inline** into the one rule (and notes any non-markdown assets).
- **Cursor global** rules are usually set in Settings → Rules (UI); the installer drops
  files in `~/.cursor/rules/` and prints a note if manual paste is needed.
- **Codex** (and other runtimes) recognize the cross-runtime `~/.agents/skills/` path.

---

## Using skills per tool

After installing, **reload the tool**, then:

| Tool | Reload | How to invoke a skill |
|---|---|---|
| **Claude Code** | Restart / new session | Type `/<skill-name>`, or just describe the task — skills auto-trigger from their `description`. |
| **Cursor** | Reload window | Rules auto-apply per their `description` (`alwaysApply: false` = agent-requested), or reference the rule in chat. |
| **Codex** | Restart Codex | Skills load from `~/.agents/skills/`; invoke by name or describe the task. |

Example: after installing `diagram-architect`, in Claude Code type
`/diagram-architect` or say *"draw our data architecture as a diagram"* and it runs
its intake → preview → export workflow.

---

## Use as an MCP server

Instead of installing files, you can serve the skills to any MCP-capable client over
one connection. Skills become **tools** (`list_skills`, `get_skill`, `search_skills`),
**prompts** (one per skill), and **resources** (`skill://<name>`).

```bash
cd mcp && npm install && npm run build
```
Then register with your client, e.g. Claude Code:
```bash
claude mcp add agent-skills -- node /abs/path/to/agent-skills/mcp/dist/index.js
```
Or in an `mcp.json` (Claude Desktop / Cursor / Codex):
```json
{ "mcpServers": { "agent-skills": {
  "command": "node",
  "args": ["/abs/path/to/agent-skills/mcp/dist/index.js"],
  "env": { "AGENT_SKILLS_DIR": "/abs/path/to/agent-skills/skills" }
}}}
```

**Installer vs MCP:** the installer gives native **auto-triggering** skills (the model
loads them by `description` automatically); the MCP gives **centralized, always-fresh**
access but the model must choose to call `get_skill`. Use whichever fits — or both.
Full details in [`mcp/README.md`](mcp/README.md).

---

## Repository layout

```
agent-skills/
├── install.sh                     # the one installer (auto-discovers skills)
├── README.md
├── CONTRIBUTING.md                # full guide to adding a skill
├── mcp/                           # optional MCP server (tools + prompts + resources)
│   ├── src/index.ts
│   └── README.md
└── skills/
    └── <category>/                # organizational only — doesn't affect install target
        └── <skill-name>/
            ├── SKILL.md           # required (frontmatter: name, description; optional category)
            └── ...                # optional supporting files (scripts, examples)
```

**Categories** (subfolders under `skills/`) group the `--list` menu only. The installer
finds every `skills/**/SKILL.md` and installs each to its tool's correct **flat**
location — so category nesting never breaks tool auto-discovery, and re-categorizing a
skill is just a folder move.

---

## Contribution guidelines

The installer is **content-agnostic** — you never edit `install.sh` to add a skill.
Drop a correctly-structured folder under `skills/` and it's auto-discovered.
Full details in [CONTRIBUTING.md](CONTRIBUTING.md); the essentials:

**1. Create the folder**
```
skills/<category>/<skill-name>/SKILL.md
```
`<skill-name>` = lowercase, hyphens only (becomes the install folder / rule name).

**2. Write valid frontmatter + body**
```markdown
---
name: your-skill-name
description: "Use when <specific triggering conditions and symptoms>."
category: diagramming        # optional; defaults to the parent folder name
---

# Your Skill
## Overview
...
```

**3. Frontmatter rules**
- `name` — letters, numbers, hyphens only. Required.
- `description` — third person, start with **"Use when…"**, describe *triggering
  conditions* not the workflow. Required, keep under ~500 chars.
- `category` — optional; falls back to the parent folder under `skills/`.

**4. Keep it self-contained & reusable**
- One skill = one coherent capability. Reusable technique/pattern/reference — not a
  project-specific one-off (those belong in a project's own instructions file).
- Prefer everything in `SKILL.md`. Supporting files are available at runtime for
  **Claude/Codex**; for **Cursor** only the converted `SKILL.md` body ships.

**5. Verify before committing**
```bash
./install.sh --list                                   # your skill appears under its category
./install.sh --tool cursor --scope project --dir /tmp/test --skills your-skill-name
```

**6. Open a PR** with a one-line summary of what the skill does and when it triggers.
If it enforces discipline (a rule agents might skip), note how you tested it.

**Removing a skill:** delete its folder under `skills/`. To remove from an installed
machine: `./install.sh --uninstall --tool <tool> --scope <scope> --skills <name>`.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `permission denied` running installer | `chmod +x install.sh` or run `bash install.sh` |
| Skill not showing after install | Reload the tool (restart Claude/Codex, reload Cursor window) |
| Cursor global rule not loading | Open Cursor Settings → Rules and paste the file from `~/.cursor/rules/<name>.mdc` |
| Windows: `~` path wrong | Run the installer inside the **same** environment (WSL) your agent runs in |
| `--skills` says "Unknown skill" | Run `./install.sh --list` for exact names |
| Nothing discovered | Ensure each skill has `skills/<category>/<name>/SKILL.md` with YAML frontmatter |
