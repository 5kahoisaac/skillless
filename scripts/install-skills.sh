#!/usr/bin/env bash
# Install agent skills listed in a category CSV via `npx skills add`.
#
# CSV columns: repo,skill_name,agents
#   repo        required — GitHub URL or owner/repo
#   skill_name  optional — empty installs ALL skills from the repo
#   agents      optional — space-separated agent names (e.g. "opencode claude-code codex");
#               empty lets the skills CLI auto-detect
#
# SCOPE=global (default) installs with -g (user-level); SCOPE=local installs project-level.
# DRY_RUN=1 prints the commands instead of running them.
# VERBOSE=1 also prints the raw `npx skills add` output for each row.
set -euo pipefail

usage() {
  echo "Usage: $0 <category.csv>" >&2
  exit 64
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  printf '%s' "${s%"${s##*[![:space:]]}"}"
}

# Strip ANSI escapes, cursor codes, and TUI box-drawing characters,
# trimming each line. Blank lines are preserved (used as block separators).
strip_format() {
  sed -E '
    s/\x1b\[[0-9;?]*[a-zA-Z]//g;
    s/\r//g;
    s/[│╭╮╰╯├┤─◇◆●■□▪▫·]+/ /g;
    s/^[[:space:]]+//;
    s/[[:space:]]+$//
  '
}

# ANSI color codes (disabled when stdout isn't a terminal).
if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_CYAN=$'\033[36m'; C_YELLOW=$'\033[33m'; C_RESET=$'\033[0m'
else
  C_GREEN=''; C_RED=''; C_DIM=''; C_BOLD=''; C_CYAN=''; C_YELLOW=''; C_RESET=''
fi

# Reduce raw `npx skills add` output to a readable multi-line summary.
# Prints a "✓"/"✗" header line followed by indented path/agents/risk details.
summarize() {
  local status="$1" repo="$2" skill="$3" clean="$4"
  local label="${C_BOLD}${repo}${skill:+ (${skill})}${C_RESET}"

  if [[ "$status" -ne 0 ]]; then
    local err
    # prefer an explicit error/invalid line; otherwise fall back to the last
    # few non-empty lines of output for context.
    err=$(printf '%s\n' "$clean" | grep -E '^(Invalid|Error|ERROR)' | head -1) || true
    if [[ -z "$err" ]]; then
      err=$(printf '%s\n' "$clean" | sed '/^$/d' | tail -3)
    fi
    echo "${C_RED}✗${C_RESET} $label ${C_DIM}(exit $status)${C_RESET}"
    printf '%s\n' "$err" | sed "s/^/  ${C_RED}> ${C_RESET}/"
    return
  fi

  # `|| true`: grep exits 1 when a section is absent (e.g. --copy installs have no
  # symlink path lines). Without it, pipefail + set -e would abort the whole script.
  local paths agents risk
  paths=$(printf '%s\n' "$clean" \
    | grep -oE '[^[:space:]]*\.agents/skills/[A-Za-z0-9._-]+' \
    | sort -u) || true
  agents=$(printf '%s\n' "$clean" \
    | grep -E '^(universal:|symlinked:)' \
    | sort -u) || true
  # Risk table rows look like: "<skill>  <Gen>  <N alerts>  <Word Risk>"
  # Color each value: safe/low/0 alerts -> green, medium/few alerts -> yellow,
  # high/unsafe/critical/many alerts -> red.
  risk=$(printf '%s\n' "$clean" | awk \
    -v green="$C_GREEN" -v yellow="$C_YELLOW" -v red="$C_RED" -v reset="$C_RESET" '
    function colorval(v,    lc, n_alerts) {
      lc = tolower(v);
      # "N alerts" — bucket by count.
      if (lc ~ /alerts?$/) {
        n_alerts = v + 0;
        if (n_alerts == 0) return green v reset
        if (n_alerts < 5) return yellow v reset
        return red v reset
      }
      # Severe first ("unsafe" contains "safe", so this must precede the green check).
      if (lc ~ /(high|critical|severe|unsafe|malicious|danger|vuln|fail)/) return red v reset
      if (lc ~ /(medium|moderate|warn|caution|elevated)/)                 return yellow v reset
      if (lc ~ /(safe|low|none|no risk|clean|verified|trusted|ok|pass)/)   return green v reset
      # Any other non-empty verdict (e.g. a bare "Risk"): flag as caution, never plain.
      if (lc ~ /[a-z0-9]/) return yellow v reset
      return v
    }
    /Gen[[:space:]]+Socket[[:space:]]+Snyk/ { capture=1; next }
    capture && NF == 0                      { capture=0 }
    capture {
      gsub(/[[:space:]]+/, " ");
      n = NF;
      snyk = $(n-1) " " $n;
      socket = $(n-3) " " $(n-2);
      gen = $(n-4);
      skill_name = $1;
      for (i = 2; i <= n-5; i++) skill_name = skill_name " " $i;
      print skill_name ": Gen=" colorval(gen) ", Socket=" colorval(socket) ", Snyk=" colorval(snyk);
    }
  ')

  echo "${C_GREEN}✓${C_RESET} $label"
  if [[ -n "$paths" ]]; then
    printf '%s\n' "$paths" | sed "s|^|  ${C_DIM}path:${C_RESET}   |"
  fi
  if [[ -n "$risk" ]]; then
    printf '%s\n' "$risk" | sed "s/^/  ${C_DIM}risk:${C_RESET}   /"
  fi
  if [[ -n "$agents" ]]; then
    printf '%s\n' "$agents" | sed "s/^/  ${C_DIM}agents:${C_RESET} /"
  fi
}

[[ $# -eq 1 ]] || usage
csv="$1"
[[ -f "$csv" ]] || { echo "Error: list not found: $csv" >&2; exit 66; }

scope="${SCOPE:-global}"
action="${ACTION:-pack}"
category="$(basename "$csv" .csv)"

# Scope-specific CLI flags. `ls`/`add` default to project; `update` needs -p.
# Local (project) installs use the default mode (NOT --copy): the skill content is
# vendored as real files into <repo>/.agents/skills/<skill> (versioned by the team),
# and the agents in the CSV symlink to that local .agents result. --copy would make
# per-agent duplicate copies instead of symlinking to the shared .agents folder.
if [[ "$scope" == "global" ]]; then
  ls_scope=(-g); add_scope=(-g); update_scope=(-g); remove_scope=(-g)
else
  ls_scope=();   add_scope=();   update_scope=(-p); remove_scope=()
fi

# Snapshot of already-installed skills for this scope, written as
# "<name>\t<sorted,csv,agent,ids>" lines (agent display names normalized:
# "Claude Code" -> claude-code). A temp file keeps this bash 3.2 compatible
# (no associative arrays). Lets us skip/install/update instead of always
# reinstalling from scratch.
INSTALLED_FILE="$(mktemp)"
trap 'rm -f "$INSTALLED_FILE"' EXIT

load_installed() {
  local json
  json=$(npx -y skills ls "${ls_scope[@]+"${ls_scope[@]}"}" --json </dev/null 2>/dev/null || echo '[]')
  printf '%s' "$json" | node -e '
    const fs = require("fs");
    let data = [];
    try { data = JSON.parse(fs.readFileSync(0, "utf8") || "[]"); } catch (e) {}
    const norm = s => String(s).toLowerCase().replace(/\s+/g, "-");
    for (const s of data) {
      console.log(s.name + "\t" + (s.agents || []).map(norm).sort().join(","));
    }
  ' 2>/dev/null >"$INSTALLED_FILE" || true
}

# Echo the installed agent ids for a skill, or nothing. Prints a leading marker
# so callers can distinguish "installed with no agents" from "not installed".
lookup_installed() {
  awk -F'\t' -v k="$1" '$1 == k { print "1" FS $2; exit }' "$INSTALLED_FILE"
}

# 0 if every required agent id (space-separated, $1) is present in the installed
# set (comma-separated, $2). Empty requirement is always satisfied.
agents_satisfied() {
  local required="$1" have=",$2," a
  for a in $required; do
    [[ "$have" == *",$a,"* ]] || return 1
  done
  return 0
}

load_installed
if [[ "$action" == "pack" ]]; then
  echo "Packing ${C_CYAN}${category}${C_RESET} skills in ${C_YELLOW}${scope}${C_RESET} scope" \
       "${C_DIM}($(grep -c . "$INSTALLED_FILE" 2>/dev/null || echo 0) already installed)${C_RESET}"
else
  echo "Unpacking ${C_CYAN}${category}${C_RESET} skills from ${C_YELLOW}${scope}${C_RESET} scope" \
       "${C_DIM}($(grep -c . "$INSTALLED_FILE" 2>/dev/null || echo 0) installed)${C_RESET}"
fi

# List the skill names available in a repo via `skills add <repo> -l`. The CLI
# ignores --json here, so we parse the "Available Skills" block: skill names are
# single kebab-case tokens; descriptions are multi-word lines and get skipped.
enumerate_repo_skills() {
  local repo="$1" raw
  raw=$(npx -y skills add "$repo" -l </dev/null 2>&1 || true)
  printf '%s\n' "$raw" | strip_format | awk '
    /Available Skills/ { cap = 1; next }
    /Use --skill/      { cap = 0 }
    cap && /^[A-Za-z0-9][A-Za-z0-9._-]*$/ { print }
  '
}

# Remove an installed skill from the scope.
unpack_one() {
  local repo="$1" skill="$2" agents="$3" src="$4"
  local label found cmd status raw_file
  label="${C_BOLD}${repo}${skill:+ (${skill})}${C_RESET}"

  if [[ -z "$skill" ]]; then
    echo "Warning: $src: empty skill in unpack (repo-level) — skipping" >&2
    failures+=("$src $repo: empty skill in unpack")
    return
  fi

  found="$(lookup_installed "$skill")"
  if [[ -z "$found" ]]; then
    echo "${C_DIM}-${C_RESET} $label ${C_DIM}not installed${C_RESET}"
    n_skip=$((n_skip + 1))
    return
  fi

  cmd=(npx -y skills remove "${remove_scope[@]+"${remove_scope[@]}"}" -s "$skill" -y)

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "[dry-run:remove] ${cmd[*]}"
    n_install=$((n_install + 1))
    return
  fi

  raw_file=$(mktemp)
  if "${cmd[@]}" </dev/null >"$raw_file" 2>&1; then
    status=0
  else
    status=$?
  fi
  [[ "${VERBOSE:-0}" == "1" ]] && cat "$raw_file"
  rm -f "$raw_file"

  # Removal output has no install paths/risk, so don't reuse summarize() — its
  # grep+pipefail would abort the script under set -e. Print a simple line.
  if [[ "$status" -eq 0 ]]; then
    echo "${C_GREEN}✓${C_RESET} $label ${C_DIM}removed${C_RESET}"
    n_install=$((n_install + 1))
  else
    echo "${C_RED}✗${C_RESET} $label ${C_DIM}(exit $status)${C_RESET}"
    failures+=("$src $repo,$skill")
  fi
}

# Decide and apply the pack action for one (repo, skill, agents) triple.
# Mutates globals: n_install, n_update, n_skip, failures[], to_update[].
# An empty skill means "install all" (used only as an enumeration fallback).
pack_one() {
  local repo="$1" skill="$2" agents="$3" src="$4"
  local label action found agent raw_file status clean
  label="${C_BOLD}${repo}${skill:+ (${skill})}${C_RESET}"

  if [[ -n "$skill" ]]; then
    found="$(lookup_installed "$skill")"
    if [[ -z "$found" ]]; then
      action="install"
    elif agents_satisfied "$agents" "${found#1$'\t'}"; then
      action="skip"
    else
      action="update"
    fi
  else
    action="install"
  fi

  if [[ "$action" == "skip" ]]; then
    echo "${C_DIM}=${C_RESET} $label ${C_DIM}already installed${C_RESET}"
    to_update+=("$skill")
    n_skip=$((n_skip + 1))
    return
  fi

  local cmd=(npx -y skills add "$repo" -s "${skill:-*}" -y "${add_scope[@]+"${add_scope[@]}"}")
  # the skills CLI takes one agent per -a flag; agents is space-separated
  for agent in $agents; do
    cmd+=(-a "$agent")
  done

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "[dry-run:$action] ${cmd[*]}"
    [[ "$action" == "install" ]] && n_install=$((n_install + 1)) || n_update=$((n_update + 1))
    return
  fi

  raw_file=$(mktemp)
  # </dev/null: npx must not consume the CSV being read on stdin
  if "${cmd[@]}" </dev/null >"$raw_file" 2>&1; then
    status=0
  else
    status=$?
  fi
  clean=$(strip_format <"$raw_file")
  [[ "${VERBOSE:-0}" == "1" ]] && cat "$raw_file"
  rm -f "$raw_file"

  summarize "$status" "$repo" "$skill" "$clean"
  if [[ "$status" -eq 0 ]]; then
    [[ "$action" == "install" ]] && n_install=$((n_install + 1)) || n_update=$((n_update + 1))
  else
    failures+=("$src $repo${skill:+,$skill}")
  fi
}

declare -a failures=()
declare -a to_update=()
n_install=0 n_update=0 n_skip=0
lineno=0

while IFS= read -r line || [[ -n "$line" ]]; do
  lineno=$((lineno + 1))
  line="$(trim "${line%%#*}")"
  [[ -z "$line" ]] && continue

  IFS=, read -r repo skill agents <<<"$line"
  repo="$(trim "${repo:-}")"
  skill="$(trim "${skill:-}")"
  agents="$(trim "${agents:-}")"

  # header row
  [[ "$repo" == "repo" && "$skill" == "skill_name" ]] && continue

  if [[ ! "$repo" =~ ^https?:// && ! "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+ ]]; then
    echo "Warning: $csv:$lineno: invalid repo '$repo' — skipping" >&2
    failures+=("$csv:$lineno invalid repo: $repo")
    continue
  fi

  # Dispatch to pack or unpack handler.
  if [[ "$action" == "pack" ]]; then
    if [[ -n "$skill" ]]; then
      pack_one "$repo" "$skill" "$agents" "$csv:$lineno"
    else
      names="$(enumerate_repo_skills "$repo")"
      if [[ -n "$names" ]]; then
        while IFS= read -r name; do
          [[ -n "$name" ]] && pack_one "$repo" "$name" "$agents" "$csv:$lineno"
        done <<<"$names"
      else
        echo "Warning: $csv:$lineno: could not enumerate '$repo' — installing all" >&2
        pack_one "$repo" "" "$agents" "$csv:$lineno"
      fi
    fi
  elif [[ "$action" == "unpack" ]]; then
    if [[ -n "$skill" ]]; then
      unpack_one "$repo" "$skill" "$agents" "$csv:$lineno"
    else
      names="$(enumerate_repo_skills "$repo")"
      if [[ -n "$names" ]]; then
        while IFS= read -r name; do
          [[ -n "$name" ]] && unpack_one "$repo" "$name" "$agents" "$csv:$lineno"
        done <<<"$names"
      else
        echo "Warning: $csv:$lineno: could not enumerate '$repo' — skipping unpack all" >&2
      fi
    fi
  fi
done <"$csv"

# Staleness check: batch-update the skills that already matched (existence + agents)
# in one pass. `skills update` is a no-op for ones already at the latest version.
if ((${#to_update[@]} > 0)) && [[ "${DRY_RUN:-0}" != "1" && "${SKIP_UPDATE:-0}" != "1" ]]; then
  echo
  echo "Checking ${#to_update[@]} existing skill(s) for updates..."
  upd_raw=$(npx -y skills update "${to_update[@]}" "${update_scope[@]+"${update_scope[@]}"}" -y </dev/null 2>&1 || true)
  printf '%s\n' "$upd_raw" | strip_format \
    | grep -iE 'updated|up to date|up-to-date' \
    | sed "s/^/  ${C_DIM}>${C_RESET} /" || true
fi

echo
if [[ "$action" == "pack" ]]; then
  echo "$csv: ${C_GREEN}${n_install} installed${C_RESET}, ${C_YELLOW}${n_update} updated${C_RESET}, ${C_DIM}${n_skip} skipped${C_RESET}, ${C_RED}${#failures[@]} failed${C_RESET}"
else
  echo "$csv: ${C_GREEN}${n_install} removed${C_RESET}, ${C_DIM}${n_skip} skipped${C_RESET}, ${C_RED}${#failures[@]} failed${C_RESET}"
fi
if ((${#failures[@]} > 0)); then
  printf '  failed: %s\n' "${failures[@]}" >&2
  exit 1
fi
