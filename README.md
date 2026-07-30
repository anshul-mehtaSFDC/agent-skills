# agent-skills

A portable collection of AI-agent **skills** (and rules) installable into
**Claude Code**, **Cursor**, or **Codex** — at **project** or **global** scope —
with a single installer. Tool-neutral: the same skill content is copied or
format-converted to whatever each tool expects.

---

## Table of contents
- [Requirements & OS support](#requirements--os-support)
- [Install](#install)
- [What installs where](#what-installs-where)
- [Using skills per tool](#using-skills-per-tool)
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

The interactive flow asks three things:
1. **Tool** — `claude` / `cursor` / `codex`
2. **Scope** — `project` (one repo) / `global` (all your projects)
3. **Skills** — `all`, or a comma-separated list (menu is grouped by category)

Non-interactive (CI / scripting):
```bash
./install.sh --tool claude --scope global  --skills all
./install.sh --tool cursor --scope project --dir /path/to/project --skills diagram-architect
./install.sh --tool codex  --scope global  --skills diagram-architect,another-skill
./install.sh --list                        # show all skills, grouped by category
./install.sh --uninstall --tool claude --scope global --skills diagram-architect
```

---

## What installs where

| Tool | Scope | Destination | Format |
|---|---|---|---|
| Claude Code | global | `~/.claude/skills/<name>/SKILL.md` | copied as-is |
| Claude Code | project | `<project>/.claude/skills/<name>/SKILL.md` | copied as-is |
| Cursor | project | `<project>/.cursor/rules/<name>.mdc` | converted to a Cursor rule |
| Cursor | global | `~/.cursor/rules/<name>.mdc` | converted (see note) |
| Codex | global | `~/.agents/skills/<name>/SKILL.md` | copied (cross-runtime path) |
| Codex | project | `<project>/.agents/skills/<name>/SKILL.md` | copied |

- **Cursor** uses *rules* (`.mdc`), not skills — the installer rewrites the frontmatter
  (`description` / `globs` / `alwaysApply: false`) and keeps the full body.
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

## Repository layout

```
agent-skills/
├── install.sh                     # the one installer (auto-discovers skills)
├── README.md
├── CONTRIBUTING.md                # full guide to adding a skill
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
