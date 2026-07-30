#!/usr/bin/env bash
# agent-skills installer
# Installs selected skills into one or more of Claude Code / Cursor / Codex,
# at project or global scope. Skills live under skills/<category>/<name>/SKILL.md
# and are auto-discovered. Per tool, each skill installs to that tool's correct
# flat location (converting format where needed). Category subfolders are for
# organization only; they don't affect targets.
#
# Both --tool and --skills are MULTI-select (comma-separated, or 'all').
#
# Usage:
#   ./install.sh                                          # fully interactive
#   ./install.sh --tool claude,cursor --scope global --skills diagram-architect,another
#   ./install.sh --tool all --scope project --dir /path --skills all
#   ./install.sh --list
#   ./install.sh --uninstall --tool claude --scope global --skills diagram-architect
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$REPO_DIR/skills"
ALL_TOOLS=(claude cursor codex)

TOOLSEL=""; SCOPE=""; TARGET_DIR="$PWD"; SEL=""; UNINSTALL="false"; DO_LIST="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool|--tools) TOOLSEL="${2:-}"; shift 2;;
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

# ---- discover skills: parallel arrays NAMES / PATHS / CATS ----
NAMES=(); PATHS=(); CATS=()
while IFS= read -r sf; do
  d="$(dirname "$sf")"
  name="$(basename "$d")"
  cat="$(basename "$(dirname "$d")")"
  [[ "$cat" == "skills" ]] && cat="uncategorized"
  NAMES+=("$name"); PATHS+=("$sf"); CATS+=("$cat")
done < <(find "$SKILLS_ROOT" -name SKILL.md -type f | sort)

[[ ${#NAMES[@]} -gt 0 ]] || die "No SKILL.md files found under $SKILLS_ROOT"

desc_of() { awk '/^description:/{sub(/^description:[[:space:]]*/,""); gsub(/^"|"$/,""); print substr($0,1,90); exit}' "$1"; }
idx_of_name() { local n="$1" i; for i in "${!NAMES[@]}"; do [[ "${NAMES[$i]}" == "$n" ]] && { echo "$i"; return; }; done; echo "-1"; }

print_catalog() {
  local last="" order
  order=$(for i in "${!NAMES[@]}"; do printf '%s\t%s\t%s\n' "${CATS[$i]}" "${NAMES[$i]}" "$i"; done | sort)
  while IFS=$'\t' read -r c n i; do
    [[ "$c" != "$last" ]] && { echo ""; echo "  [$c]"; last="$c"; }
    printf "    %-24s %s\n" "$n" "$(desc_of "${PATHS[$i]}")"
  done <<< "$order"
}

if [[ "$DO_LIST" == "true" ]]; then
  echo "Available skills (${#NAMES[@]}):"; print_catalog; exit 0
fi

# ---- interactive helpers ----
prompt_single() { # $1=prompt $2..=options -> echoes chosen value
  local p="$1"; shift; local opts=("$@") i sel
  echo "$p" >&2
  for i in "${!opts[@]}"; do echo "  $((i+1))) ${opts[$i]}" >&2; done
  read -r -p "Enter number: " sel </dev/tty
  [[ "$sel" =~ ^[0-9]+$ ]] && (( sel>=1 && sel<=${#opts[@]} )) || die "Invalid choice"
  echo "${opts[$((sel-1))]}"
}

# Multi-select from a fixed option list. Accepts 'all', or comma/space-separated
# numbers and/or names. Echoes chosen values space-separated.
prompt_multi() { # $1=prompt $2..=options
  local p="$1"; shift; local opts=("$@") i raw tok chosen=()
  echo "$p  (comma-separated numbers/names, or 'all')" >&2
  for i in "${!opts[@]}"; do echo "  $((i+1))) ${opts[$i]}" >&2; done
  read -r raw </dev/tty
  [[ -n "$raw" ]] || die "Nothing selected"
  if [[ "$raw" == "all" ]]; then echo "${opts[*]}"; return; fi
  raw="${raw//,/ }"
  for tok in $raw; do
    if [[ "$tok" =~ ^[0-9]+$ ]]; then
      (( tok>=1 && tok<=${#opts[@]} )) || die "Invalid number: $tok"
      chosen+=("${opts[$((tok-1))]}")
    else
      local ok="false"
      for o in "${opts[@]}"; do [[ "$o" == "$tok" ]] && { chosen+=("$tok"); ok="true"; }; done
      [[ "$ok" == "true" ]] || die "Invalid option: $tok"
    fi
  done
  # de-dupe preserving order
  local seen=() out=()
  for c in "${chosen[@]}"; do
    case " ${seen[*]:-} " in *" $c "*) ;; *) seen+=("$c"); out+=("$c");; esac
  done
  echo "${out[*]}"
}

# ---- resolve TOOLS (multi) ----
TOOLS=()
if [[ -n "$TOOLSEL" ]]; then
  if [[ "$TOOLSEL" == "all" ]]; then TOOLS=("${ALL_TOOLS[@]}"); else
    TOOLSEL="${TOOLSEL//,/ }"
    for t in $TOOLSEL; do
      [[ "$t" =~ ^(claude|cursor|codex)$ ]] || die "--tool must be claude|cursor|codex|all"
      TOOLS+=("$t")
    done
  fi
else
  read -ra TOOLS <<< "$(prompt_multi "Install for which tool(s)?" "${ALL_TOOLS[@]}")"
fi
[[ ${#TOOLS[@]} -gt 0 ]] || die "No tool selected"

# ---- resolve SCOPE (single) ----
[[ -z "$SCOPE" ]] && SCOPE="$(prompt_single "Which scope?" project global)"
[[ "$SCOPE" =~ ^(project|global)$ ]] || die "--scope must be project|global"

if [[ "$SCOPE" == "project" ]]; then
  if [[ "$TARGET_DIR" == "$PWD" ]]; then
    read -r -p "Project directory [$PWD]: " d </dev/tty || true
    [[ -n "${d:-}" ]] && TARGET_DIR="$d"
  fi
  [[ -d "$TARGET_DIR" ]] || die "Project dir not found: $TARGET_DIR"
fi

# ---- resolve SKILLS (multi) ----
SELECTED=()
resolve_skills() { # $1=raw selection string
  local raw="$1"
  if [[ "$raw" == "all" ]]; then SELECTED=("${NAMES[@]}"); return; fi
  raw="${raw//,/ }"
  for r in $raw; do
    local i; i="$(idx_of_name "$r")"
    [[ "$i" == "-1" ]] && die "Unknown skill: $r (use --list)"
    SELECTED+=("$r")
  done
}
if [[ -n "$SEL" ]]; then
  resolve_skills "$SEL"
else
  echo "" >&2; echo "Available skills:" >&2; print_catalog >&2; echo "" >&2
  echo "Enter skills to install: 'all', or comma-separated names (e.g. diagram-architect,foo)" >&2
  read -r SEL </dev/tty
  [[ -n "$SEL" ]] || die "Nothing selected"
  resolve_skills "$SEL"
fi

# ---- per-tool destination / writer / remover (tool passed as $1) ----
dest_for() { # $1=tool $2=skill
  local tool="$1" name="$2"
  case "$tool:$SCOPE" in
    claude:global)  echo "$HOME/.claude/skills/$name/SKILL.md";;
    claude:project) echo "$TARGET_DIR/.claude/skills/$name/SKILL.md";;
    cursor:project) echo "$TARGET_DIR/.cursor/rules/$name.mdc";;
    cursor:global)  echo "$HOME/.cursor/rules/$name.mdc";;
    codex:global)   echo "$HOME/.agents/skills/$name/SKILL.md";;
    codex:project)  echo "$TARGET_DIR/.agents/skills/$name/SKILL.md";;
  esac
}

install_one() { # $1=tool $2=src $3=dest
  local tool="$1" src="$2" dest="$3"
  mkdir -p "$(dirname "$dest")"
  if [[ "$tool" == "cursor" ]]; then
    local DESC BODY
    DESC="$(awk '/^description:/{sub(/^description:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$src")"
    BODY="$(awk 'f==2{print} /^---[[:space:]]*$/{f++}' "$src")"
    { echo "---"; echo "description: $DESC"; echo "globs:"; echo "alwaysApply: false"; echo "---"; echo ""; printf '%s\n' "$BODY"; } > "$dest"
  else
    cp "$src" "$dest"
  fi
}

uninstall_one() { # $1=tool $2=dest
  local tool="$1" dest="$2"
  if [[ "$tool" == "cursor" ]]; then rm -f "$dest"; else rm -rf "$(dirname "$dest")"; fi
}

# ---- execute: tools × skills ----
echo ""
CURSOR_GLOBAL_NOTE="false"
for tool in "${TOOLS[@]}"; do
  echo "── $tool ($SCOPE) ──"
  for name in "${SELECTED[@]}"; do
    i="$(idx_of_name "$name")"; src="${PATHS[$i]}"; dest="$(dest_for "$tool" "$name")"
    if [[ "$UNINSTALL" == "true" ]]; then
      uninstall_one "$tool" "$dest"; echo "  ✗ Removed $name  ($dest)"
    else
      install_one "$tool" "$src" "$dest"; echo "  ✓ Installed $name  →  $dest"
      [[ "$tool:$SCOPE" == "cursor:global" ]] && CURSOR_GLOBAL_NOTE="true"
    fi
  done
done

echo ""
if [[ "$UNINSTALL" == "true" ]]; then echo "Done (uninstall)."; exit 0; fi

# ---- post-install hints (only for tools actually installed to) ----
echo "Reload hints:"
for tool in "${TOOLS[@]}"; do
  case "$tool" in
    claude) echo "  • Claude Code: restart / new session. Invoke: /<skill-name> or ask naturally.";;
    cursor) echo "  • Cursor: reload the window. Rules load from .cursor/rules/.";;
    codex)  echo "  • Codex: restart. Skills load from ~/.agents/skills/ (cross-runtime path).";;
  esac
done
if [[ "$CURSOR_GLOBAL_NOTE" == "true" ]]; then
  echo ""
  echo "NOTE (Cursor global): Cursor manages global rules in Settings → Rules (UI). Files were"
  echo "written to ~/.cursor/rules/; if your Cursor version doesn't auto-load them, open"
  echo "Cursor Settings → Rules and paste each file's contents."
fi
