#!/usr/bin/env bash
# agent-skills installer
# Installs selected skills for Claude Code / Cursor / Codex, at project or global scope.
# Skills live under skills/<category>/<skill-name>/SKILL.md and are auto-discovered.
# Per tool, each skill installs to that tool's correct flat location (converting format
# where needed). Category subfolders are for organization only; they don't affect targets.
#
# Usage:
#   ./install.sh                                  # fully interactive
#   ./install.sh --tool claude --scope global --skills diagram-architect,another
#   ./install.sh --tool cursor --scope project --dir /path --skills all
#   ./install.sh --list
#   ./install.sh --uninstall --tool claude --scope global --skills diagram-architect
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$REPO_DIR/skills"

TOOL=""; SCOPE=""; TARGET_DIR="$PWD"; SEL=""; UNINSTALL="false"; DO_LIST="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)   TOOL="${2:-}"; shift 2;;
    --scope)  SCOPE="${2:-}"; shift 2;;
    --dir)    TARGET_DIR="${2:-}"; shift 2;;
    --skills) SEL="${2:-}"; shift 2;;
    --list)   DO_LIST="true"; shift;;
    --uninstall) UNINSTALL="true"; shift;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }
[[ -d "$SKILLS_ROOT" ]] || die "No skills/ directory found at $SKILLS_ROOT"

# ---- discover skills: fill parallel arrays NAMES / PATHS / CATS ----
NAMES=(); PATHS=(); CATS=()
while IFS= read -r sf; do
  d="$(dirname "$sf")"
  name="$(basename "$d")"
  cat="$(basename "$(dirname "$d")")"
  [[ "$cat" == "skills" ]] && cat="uncategorized"
  NAMES+=("$name"); PATHS+=("$sf"); CATS+=("$cat")
done < <(find "$SKILLS_ROOT" -name SKILL.md -type f | sort)

[[ ${#NAMES[@]} -gt 0 ]] || die "No SKILL.md files found under $SKILLS_ROOT"

# frontmatter description (for listing)
desc_of() { awk '/^description:/{sub(/^description:[[:space:]]*/,""); gsub(/^"|"$/,""); print substr($0,1,90); exit}' "$1"; }

idx_of_name() { local n="$1" i; for i in "${!NAMES[@]}"; do [[ "${NAMES[$i]}" == "$n" ]] && { echo "$i"; return; }; done; echo "-1"; }

print_catalog() {
  local last=""; local i
  # sort indices by category then name for grouped display
  local order; order=$(for i in "${!NAMES[@]}"; do printf '%s\t%s\t%s\n' "${CATS[$i]}" "${NAMES[$i]}" "$i"; done | sort)
  while IFS=$'\t' read -r c n i; do
    [[ "$c" != "$last" ]] && { echo ""; echo "  [$c]"; last="$c"; }
    printf "    %-24s %s\n" "$n" "$(desc_of "${PATHS[$i]}")"
  done <<< "$order"
}

if [[ "$DO_LIST" == "true" ]]; then
  echo "Available skills (${#NAMES[@]}):"; print_catalog; exit 0
fi

# ---- interactive selectors ----
prompt_choice() { # $1=prompt $2..=options -> echoes chosen value
  local p="$1"; shift; local opts=("$@") i sel
  echo "$p" >&2
  for i in "${!opts[@]}"; do echo "  $((i+1))) ${opts[$i]}" >&2; done
  read -r -p "Enter number: " sel </dev/tty
  [[ "$sel" =~ ^[0-9]+$ ]] && (( sel>=1 && sel<=${#opts[@]} )) || die "Invalid choice"
  echo "${opts[$((sel-1))]}"
}

[[ -z "$TOOL"  ]] && TOOL="$(prompt_choice "Install for which tool?" claude cursor codex)"
[[ -z "$SCOPE" ]] && SCOPE="$(prompt_choice "Which scope?" project global)"
[[ "$TOOL" =~ ^(claude|cursor|codex)$ ]] || die "--tool must be claude|cursor|codex"
[[ "$SCOPE" =~ ^(project|global)$ ]] || die "--scope must be project|global"

if [[ "$SCOPE" == "project" ]]; then
  if [[ "$TARGET_DIR" == "$PWD" ]]; then
    read -r -p "Project directory [$PWD]: " d </dev/tty || true
    [[ -n "${d:-}" ]] && TARGET_DIR="$d"
  fi
  [[ -d "$TARGET_DIR" ]] || die "Project dir not found: $TARGET_DIR"
fi

# ---- selection ----
SELECTED=()
if [[ -n "$SEL" ]]; then
  if [[ "$SEL" == "all" ]]; then
    SELECTED=("${NAMES[@]}")
  else
    IFS=',' read -ra reqs <<< "$SEL"
    for r in "${reqs[@]}"; do
      r="$(echo "$r" | xargs)"; i="$(idx_of_name "$r")"
      [[ "$i" == "-1" ]] && die "Unknown skill: $r (use --list)"
      SELECTED+=("$r")
    done
  fi
else
  echo "" >&2
  echo "Available skills:" >&2; print_catalog >&2
  echo "" >&2
  echo "Enter skills to install: 'all', or comma-separated names (e.g. diagram-architect,foo)" >&2
  read -r SEL </dev/tty
  [[ -n "$SEL" ]] || die "Nothing selected"
  if [[ "$SEL" == "all" ]]; then SELECTED=("${NAMES[@]}"); else
    IFS=',' read -ra reqs <<< "$SEL"
    for r in "${reqs[@]}"; do r="$(echo "$r" | xargs)"; i="$(idx_of_name "$r")"
      [[ "$i" == "-1" ]] && die "Unknown skill: $r (use --list)"; SELECTED+=("$r"); done
  fi
fi

# ---- destination resolver for one skill ----
# echoes the destination file path for TOOL/SCOPE/skill
dest_for() { # $1=skill name
  local name="$1"
  case "$TOOL:$SCOPE" in
    claude:global)  echo "$HOME/.claude/skills/$name/SKILL.md";;
    claude:project) echo "$TARGET_DIR/.claude/skills/$name/SKILL.md";;
    cursor:project) echo "$TARGET_DIR/.cursor/rules/$name.mdc";;
    cursor:global)  echo "$HOME/.cursor/rules/$name.mdc";;
    codex:global)   echo "$HOME/.agents/skills/$name/SKILL.md";;
    codex:project)  echo "$TARGET_DIR/.agents/skills/$name/SKILL.md";;
  esac
}

# ---- writer: copy (claude/codex) or convert (cursor) ----
install_one() { # $1=src SKILL.md  $2=dest
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ "$TOOL" == "cursor" ]]; then
    local DESC BODY
    DESC="$(awk '/^description:/{sub(/^description:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$src")"
    BODY="$(awk 'f==2{print} /^---[[:space:]]*$/{f++}' "$src")"
    { echo "---"; echo "description: $DESC"; echo "globs:"; echo "alwaysApply: false"; echo "---"; echo ""; printf '%s\n' "$BODY"; } > "$dest"
  else
    cp "$src" "$dest"
  fi
}

uninstall_one() { # $1=dest
  local dest="$1"
  if [[ "$TOOL" == "cursor" ]]; then rm -f "$dest"; else rm -rf "$(dirname "$dest")"; fi
}

# ---- execute ----
echo ""
CURSOR_GLOBAL_NOTE="false"
for name in "${SELECTED[@]}"; do
  i="$(idx_of_name "$name")"; src="${PATHS[$i]}"; dest="$(dest_for "$name")"
  if [[ "$UNINSTALL" == "true" ]]; then
    uninstall_one "$dest"; echo "✗ Removed $name  ($dest)"
  else
    install_one "$src" "$dest"; echo "✓ Installed $name  →  $dest"
    [[ "$TOOL:$SCOPE" == "cursor:global" ]] && CURSOR_GLOBAL_NOTE="true"
  fi
done

echo ""
if [[ "$UNINSTALL" == "true" ]]; then echo "Done (uninstall)."; exit 0; fi

# ---- post-install hints ----
case "$TOOL" in
  claude) echo "Reload: restart Claude Code / new session. Invoke: /<skill-name> or ask naturally.";;
  cursor) echo "Reload: reload the Cursor window. Rules load from .cursor/rules/.";;
  codex)  echo "Reload: restart Codex. Skills load from ~/.agents/skills/ (cross-runtime path).";;
esac
if [[ "$CURSOR_GLOBAL_NOTE" == "true" ]]; then
  echo ""
  echo "NOTE (Cursor global): Cursor manages global rules in Settings → Rules (UI). Files were"
  echo "written to ~/.cursor/rules/; if your Cursor version doesn't auto-load them, open"
  echo "Cursor Settings → Rules and paste each file's contents."
fi
