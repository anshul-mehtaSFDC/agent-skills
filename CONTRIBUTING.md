# Contributing a skill

The installer is **content-agnostic** — you never edit `install.sh` to add a skill.
Just drop a correctly-structured folder under `skills/` and it's auto-discovered.

## Add a skill

1. Pick or create a **category** folder under `skills/` (e.g. `diagramming`, `salesforce`,
   `devops`, `writing`, `data`, `testing`). Categories are for organization/grouping only.
2. Create `skills/<category>/<skill-name>/SKILL.md`.
   - `<skill-name>` = lowercase, hyphens only (this becomes the install folder / rule name).
3. Write the frontmatter (YAML), then the body:

   ```markdown
   ---
   name: your-skill-name
   description: "Use when <specific triggering conditions and symptoms>."
   category: diagramming        # optional; falls back to the parent folder name
   ---

   # Your Skill

   ## Overview
   ...
   ```

4. (Optional) add supporting files in the same folder (scripts, examples, references).
   > Note: for **Claude/Codex** the whole folder is available at runtime; for **Cursor**
   > only the converted `SKILL.md` body ships as a rule. Keep skills self-contained in
   > `SKILL.md` where possible, or reference supporting files by relative path.

5. Verify discovery:
   ```bash
   ./install.sh --list
   ```
   Your skill should appear under its category.

6. Test an install into a throwaway location:
   ```bash
   ./install.sh --tool cursor --scope project --dir /tmp/test --skills your-skill-name
   ```

## Frontmatter rules

- **`name`** — letters, numbers, hyphens only. Required.
- **`description`** — third person, start with "Use when…", describe *triggering
  conditions* (not the workflow). Required. Keep under ~500 chars.
- **`category`** — optional; if omitted, the parent folder under `skills/` is used.

## Naming & scope guidance

- Skills should be **reusable techniques/patterns/references**, not project-specific
  one-offs (those belong in a project's own instructions file).
- One skill = one coherent capability. If it sprawls, split it.

## Removing a skill

Delete its folder under `skills/`. To remove it from an installed machine:
```bash
./install.sh --uninstall --tool <tool> --scope <scope> --skills <skill-name>
```
