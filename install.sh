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

# Is stderr a real terminal we can draw the TUI on?
have_tui() { [[ -t 2 && -r /dev/tty && -z "${AGENT_SKILLS_NO_TUI:-}" ]]; }

prompt_single() { # $1=prompt $2..=options -> echoes chosen value
  local p="$1"; shift; local opts=("$@") i sel
  echo "$p" >&2
  for i in "${!opts[@]}"; do echo "  $((i+1))) ${opts[$i]}" >&2; done
  read -r -p "Enter number: " sel </dev/tty
  [[ "$sel" =~ ^[0-9]+$ ]] && (( sel>=1 && sel<=${#opts[@]} )) || die "Invalid choice"
  echo "${opts[$((sel-1))]}"
}

# --- checkbox multi-select TUI (arrow keys / j-k, SPACE toggle, a=all, enter=confirm) ---
# Caller sets: PICK_OPTS (values) and PICK_LABELS (display text, same length).
# Result: PICK_RESULT (selected values, in order). Returns 1 if cancelled/empty.
PICK_RESULT=()
_pick_draw() { # uses dynamic scope: PICK_LABELS, checked, cur, n
  local j box ptr line cols avail
  cols="$( (tput cols 2>/dev/null) || echo "${COLUMNS:-80}" )"; [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  for ((j=0; j<n; j++)); do
    box="[ ]"; [[ ${checked[j]} -eq 1 ]] && box="[x]"
    ptr="  ";  [[ $j -eq $cur ]] && ptr="> "
    line="${ptr}${box} ${PICK_LABELS[j]}"
    # truncate to terminal width so each option stays on ONE row (wrapping breaks the redraw)
    avail=$((cols-1)); (( avail < 10 )) && avail=10
    (( ${#line} > avail )) && line="${line:0:avail-1}…"
    printf '\r\033[2K%s\n' "$line" >&2
  done
}
pick_multi() { # $1=title
  local title="$1"
  local n=${#PICK_OPTS[@]} cur=0 checked=() j key rest
  for ((j=0; j<n; j++)); do checked[j]=0; done
  printf '%s\n' "$title  (↑/↓ move · SPACE toggle · a=all · ENTER confirm · q=cancel)" >&2
  _pick_draw
  while true; do
    IFS= read -rsn1 key </dev/tty || break
    if [[ $key == $'\033' ]]; then IFS= read -rsn2 rest </dev/tty || true; key+="$rest"; fi
    case "$key" in
      $'\033[A'|k) ((cur>0)) && ((cur--));;
      $'\033[B'|j) ((cur<n-1)) && ((cur++));;
      ' ') checked[cur]=$((1-checked[cur]));;
      a|A) local all1=1; for ((j=0;j<n;j++)); do [[ ${checked[j]} -eq 0 ]] && all1=0; done
           for ((j=0;j<n;j++)); do checked[j]=$((1-all1)); done;;
      ''|$'\n') break;;                        # ENTER
      q|Q) PICK_RESULT=(); printf '\033[%dA' "$n" >&2; _pick_draw; return 1;;
    esac
    printf '\033[%dA' "$n" >&2   # move cursor back up to redraw in place
    _pick_draw
  done
  PICK_RESULT=()
  for ((j=0; j<n; j++)); do [[ ${checked[j]} -eq 1 ]] && PICK_RESULT+=("${PICK_OPTS[j]}"); done
  [[ ${#PICK_RESULT[@]} -gt 0 ]] || return 1
}

# Plain fallback (no TTY): comma/space-separated numbers/names, or 'all'.
# Caller sets PICK_OPTS; result in PICK_RESULT.
pick_plain() { # $1=title
  local title="$1"; local i raw tok chosen=()
  echo "$title  (comma-separated numbers/names, or 'all')" >&2
  for i in "${!PICK_OPTS[@]}"; do echo "  $((i+1))) ${PICK_LABELS[$i]}" >&2; done
  read -r raw </dev/tty
  [[ -n "$raw" ]] || die "Nothing selected"
  if [[ "$raw" == "all" ]]; then PICK_RESULT=("${PICK_OPTS[@]}"); return; fi
  raw="${raw//,/ }"
  for tok in $raw; do
    if [[ "$tok" =~ ^[0-9]+$ ]]; then
      (( tok>=1 && tok<=${#PICK_OPTS[@]} )) || die "Invalid number: $tok"
      chosen+=("${PICK_OPTS[$((tok-1))]}")
    else
      local ok="false"; for o in "${PICK_OPTS[@]}"; do [[ "$o" == "$tok" ]] && { chosen+=("$tok"); ok="true"; }; done
      [[ "$ok" == "true" ]] || die "Invalid option: $tok"
    fi
  done
  local seen=() out=()
  for c in "${chosen[@]}"; do case " ${seen[*]:-} " in *" $c "*) ;; *) seen+=("$c"); out+=("$c");; esac; done
  PICK_RESULT=("${out[@]}")
}

# Dispatch: TUI if terminal, else plain. Sets PICK_RESULT from PICK_OPTS/PICK_LABELS.
pick() { # $1=title
  if have_tui; then pick_multi "$1" || die "Cancelled"; else pick_plain "$1"; fi
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
  PICK_OPTS=("${ALL_TOOLS[@]}")
  PICK_LABELS=("Claude Code" "Cursor" "Codex")
  pick "Install for which tool(s)?"
  TOOLS=("${PICK_RESULT[@]}")
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
  # Build option/label arrays (labels show category + description) sorted by category.
  PICK_OPTS=(); PICK_LABELS=()
  while IFS=$'\t' read -r c n i; do
    PICK_OPTS+=("$n")
    PICK_LABELS+=("$n  [$c] — $(desc_of "${PATHS[$i]}")")
  done < <(for i in "${!NAMES[@]}"; do printf '%s\t%s\t%s\n' "${CATS[$i]}" "${NAMES[$i]}" "$i"; done | sort)
  pick "Which skill(s) to install?"
  SELECTED=("${PICK_RESULT[@]}")
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

install_one() { # $1=tool $2=src(SKILL.md) $3=dest
  local tool="$1" src="$2" dest="$3"
  local srcdir; srcdir="$(dirname "$src")"
  mkdir -p "$(dirname "$dest")"
  if [[ "$tool" == "cursor" ]]; then
    # Cursor = single .mdc rule. Bundle SKILL.md body + any references/*.md inline
    # (Cursor rules can't reference sibling files), and note supporting assets.
    local DESC BODY
    DESC="$(awk '/^description:/{sub(/^description:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$src")"
    BODY="$(awk 'f==2{print} /^---[[:space:]]*$/{f++}' "$src")"
    { echo "---"; echo "description: $DESC"; echo "globs:"; echo "alwaysApply: false"; echo "---"; echo "";
      printf '%s\n' "$BODY"
      if [[ -d "$srcdir/references" ]]; then
        local rf
        for rf in "$srcdir"/references/*.md; do
          [[ -e "$rf" ]] || continue
          echo ""; echo "---"; echo ""
          echo "<!-- bundled reference: references/$(basename "$rf") -->"
          cat "$rf"
        done
      fi
      # note non-markdown assets (e.g. reactflow-template.html) that can't inline into a rule
      local asset
      for asset in "$srcdir"/*.html "$srcdir"/*.txt; do
        [[ -e "$asset" ]] || continue
        echo ""; echo "<!-- asset in source repo (not bundled): $(basename "$asset") — copy it manually if needed -->"
      done
    } > "$dest"
  else
    # Claude / Codex = folder skill. Copy the WHOLE skill dir (SKILL.md + references/ + assets).
    local destdir; destdir="$(dirname "$dest")"
    rm -rf "$destdir"; mkdir -p "$destdir"
    cp -R "$srcdir"/. "$destdir"/
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
