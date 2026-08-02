#!/usr/bin/env bash
# Shared validation logic for the validate.yml and release.yml workflows.
#
# Runs two layers of checks:
#
#   1. Manifest sanity — every *.claude-plugin/{marketplace,plugin}.json is
#      valid JSON and carries the fields the plugin system expects.
#   2. Plugin-level invariants — each plugin listed in marketplace.json has
#      a matching directory + plugin.json on disk, and the listed name
#      matches the plugin.json's name.
#
# Plugins that ship hooks or installer scripts should add their own smoke
# tests below (a third layer): exercise the hook in each regime its README
# documents, so a green checkmark actually means something.
#
# Run from the repo root. Designed to be CI-friendly: any failure is a
# hard error (set -e), and progress is logged so a green checkmark is
# meaningful.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

log()  { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
note() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

require_bin() {
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 || fail "required tool not on PATH: $bin"
  done
}

require_bin jq

# ---------------------------------------------------------------------------
# Layer 1: manifest sanity
# ---------------------------------------------------------------------------

log "Validating marketplace.json"
marketplace=".claude-plugin/marketplace.json"
[ -f "$marketplace" ] || fail "missing $marketplace"
jq -e . "$marketplace" >/dev/null || fail "$marketplace is not valid JSON"
for field in name description owner plugins; do
  jq -e "has(\"$field\")" "$marketplace" >/dev/null || fail "$marketplace missing field: $field"
done
jq -e '.plugins | type == "array"' "$marketplace" >/dev/null || fail "$marketplace: plugins must be an array"
ok "$marketplace shape looks good"

log "Validating every plugin.json"
if [ -d plugins ]; then
  found_any=0
  while IFS= read -r manifest; do
    found_any=1
    jq -e . "$manifest" >/dev/null || fail "$manifest is not valid JSON"
    for field in name description; do
      jq -e "has(\"$field\")" "$manifest" >/dev/null || fail "$manifest missing field: $field"
    done
    name="$(jq -r .name "$manifest")"
    # `version` is deliberately absent: with no version field, Claude Code
    # resolves the plugin's version from its commit SHA, so every commit that
    # lands on main reaches users. A plugin that opts back into an explicit
    # version is allowed, but it freezes users until the string changes — so
    # say so loudly rather than letting it pass silently.
    if jq -e 'has("version")' "$manifest" >/dev/null; then
      version="$(jq -r .version "$manifest")"
      note "$name pins version=$version — users get NOTHING until this string changes"
      ok "$manifest ($name@$version, pinned)"
    else
      ok "$manifest ($name, version resolves to the commit SHA)"
    fi
  done < <(find plugins -mindepth 3 -maxdepth 3 -path '*/.claude-plugin/plugin.json' -type f | sort)
  [ "$found_any" -eq 1 ] || ok "no plugin manifests on disk yet — nothing to check"
else
  ok "no plugins/ directory yet — nothing to check"
fi

# ---------------------------------------------------------------------------
# Layer 2: marketplace ↔ disk consistency
# ---------------------------------------------------------------------------

log "Cross-checking marketplace entries against on-disk plugins"
if [ "$(jq -r '.plugins | length' "$marketplace")" -eq 0 ]; then
  ok "marketplace lists no plugins yet"
else
  jq -r '.plugins[] | "\(.name)\t\(.source)"' "$marketplace" |
  while IFS=$'\t' read -r name source; do
    # Every plugin here is a relative path inside this repo. An object source
    # (github/url/git-subdir) would stringify to JSON above and fail below with
    # a confusing "directory is missing", so reject it with a clear message.
    case "$source" in
      ./*) ;;
      *) fail "$name: source \"$source\" is not a relative ./path — this marketplace only ships in-repo plugins" ;;
    esac
    plugin_dir="$source"
    manifest="$plugin_dir/.claude-plugin/plugin.json"
    [ -d "$plugin_dir" ] || fail "marketplace lists $name → $source but directory is missing"
    [ -f "$manifest" ]   || fail "$name has no plugin.json at $manifest"
    actual_name="$(jq -r .name "$manifest")"
    [ "$actual_name" = "$name" ] || fail "$manifest name=\"$actual_name\" disagrees with marketplace name=\"$name\""
    # Claude Code takes plugin.json's version and ignores the marketplace
    # entry's, without warning — so a stale manifest can silently mask the
    # version you thought you shipped. Never set both.
    if jq -e 'has("version")' "$manifest" >/dev/null &&
       jq -e --arg n "$name" '.plugins[] | select(.name == $n) | has("version")' "$marketplace" >/dev/null; then
      fail "$name sets version in BOTH plugin.json and marketplace.json — plugin.json silently wins; remove one"
    fi
    ok "$name → $source"
  done
fi

# Optional: if the Claude Code CLI is present, run its native validator too.
#
# Deliberately NOT --strict. The CLI warns "No version specified" for every
# plugin here, and --strict turns that warning into a failure. Omitting
# `version` is the intended setup (see CLAUDE.md), so the warning is expected
# and the flag would fail CI on a correct repo.
if command -v claude >/dev/null 2>&1; then
  log "Running 'claude plugin validate' (CLI is available)"
  if claude plugin validate .; then
    ok "claude CLI validation passed"
  else
    fail "claude plugin validate reported errors"
  fi
else
  log "Skipping 'claude plugin validate' — CLI not installed (jq checks above cover the basics)"
fi

log "All checks passed."
