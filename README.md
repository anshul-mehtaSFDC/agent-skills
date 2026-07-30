# agent-skills

A portable collection of AI-agent **skills** (and rules) installable into
**Claude Code**, **Cursor**, or **Codex** — at **project** or **global** scope —
with a single installer. Tool-neutral: the same skill content is copied or
format-converted to whatever each tool expects.

## Quick start

```bash
git clone <repo-url> agent-skills
cd agent-skills
./install.sh            # interactive: pick tool, scope, and skills
```

Non-interactive:
```bash
./install.sh --tool claude --scope global  --skills all
./install.sh --tool cursor --scope project --dir /path/to/project --skills diagram-architect
./install.sh --tool codex  --scope global  --skills diagram-architect,another-skill
./install.sh --list                        # show all skills, grouped by category
./install.sh --uninstall --tool claude --scope global --skills diagram-architect
```

## What installs where

| Tool | Scope | Destination | Format |
|---|---|---|---|
| Claude Code | global | `~/.claude/skills/<name>/SKILL.md` | copied as-is |
| Claude Code | project | `<project>/.claude/skills/<name>/SKILL.md` | copied as-is |
| Cursor | project | `<project>/.cursor/rules/<name>.mdc` | converted to a Cursor rule |
| Cursor | global | `~/.cursor/rules/<name>.mdc` | converted (see note) |
| Codex | global | `~/.agents/skills/<name>/SKILL.md` | copied as-is (cross-runtime path) |
| Codex | project | `<project>/.agents/skills/<name>/SKILL.md` | copied as-is |

- **Cursor** uses *rules* (`.mdc`), not skills — the installer rewrites the frontmatter
  (`description` / `globs` / `alwaysApply: false`) and keeps the full body.
- **Cursor global** rules are usually set in Settings → Rules (UI); the installer drops
  files in `~/.cursor/rules/` and prints a note if manual paste is needed.
- **Codex** (and other runtimes) recognize the cross-runtime `~/.agents/skills/` path.

## Repository layout

```
agent-skills/
├── install.sh                     # the one installer (auto-discovers skills)
├── README.md
├── CONTRIBUTING.md                # how to add a skill
└── skills/
    └── <category>/                # organizational only — doesn't affect install target
        └── <skill-name>/
            ├── SKILL.md           # required (frontmatter: name, description; optional category)
            └── ...                # optional supporting files (scripts, examples)
```

**Categories** (subfolders under `skills/`) are for browsing/grouping in the `--list`
menu only. The installer discovers skills by finding every `skills/**/SKILL.md`, and
always installs each to its tool's correct **flat** location — so category nesting never
breaks tool auto-discovery, and moving a skill between categories is just a folder move.

## Adding a skill

See [CONTRIBUTING.md](CONTRIBUTING.md). In short: create
`skills/<category>/<skill-name>/SKILL.md` with valid frontmatter and it's picked up
automatically — no installer edits needed.
