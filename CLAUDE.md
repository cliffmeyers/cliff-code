# Claude Code guidance for cliff-code

This is a personal Claude Code plugin marketplace. The plugins here are hobby experiments, partly a learning exercise around the Claude Code plugin/hook system, and intended for public distribution on GitHub.

## Repository shape

```
cliff-code/                               ← marketplace root (= GitHub repo)
  .claude-plugin/
    marketplace.json                      ← marketplace manifest
  plugins/
    <plugin-name>/                        ← one directory per plugin
      .claude-plugin/
        plugin.json                       ← plugin manifest
      README.md                           ← per-plugin docs (linked as plugin homepage)
      hooks/, skills/, commands/, etc.   ← plugin components
  README.md
  LICENSE
```

One marketplace, many plugins. See `.claude-plugin/marketplace.json` for the catalog and `plugins/<name>/.claude-plugin/plugin.json` for per-plugin metadata.

## Plugin granularity principles

- **One plugin per cohesive purpose.** If two components don't share state, scripts, or a clear story, they belong in separate plugins.
- **Hooks especially get their own plugin.** Hooks have system-wide effects every prompt; bundling a hook into a plugin a user installed for an unrelated skill violates the principle of least surprise.
- **Resist mega-plugins.** The marketplace itself is the grab-bag. Each plugin should be describable in one short sentence.

## Local development workflow

For live iteration on a plugin (changes take effect without restart):

```bash
claude --plugin-dir ./plugins/<plugin-name>
```

After editing files, run `/reload-plugins` inside Claude to pick up changes.

For smoke-testing a hook script directly (without launching Claude):

```bash
echo '{"prompt":"sample prompt text"}' | ./plugins/<name>/hooks/<script>.sh
```

For end-to-end validation of the marketplace + plugin install path before pushing:

```bash
# In a fresh Claude Code session:
/plugin marketplace add /home/cliff/projects/cliff-code
/plugin install <plugin-name>@cliff-code
# ...verify it works...
/plugin marketplace remove cliff-code
```

Always run before committing:

```bash
claude plugin validate .
bash .github/scripts/validate.sh
```

## Hook scripts: path conventions

Hook commands inside a plugin must use `${CLAUDE_PLUGIN_ROOT}` (the cache path of the installed plugin), not absolute paths or `$CLAUDE_PROJECT_DIR`.

For per-user persistent state that should survive plugin updates, use `${CLAUDE_PLUGIN_DATA}`.

## Versioning: commit-SHA driven (no `version` field)

Claude Code resolves a plugin's version from the first of these that is set:

1. `version` in the plugin's `plugin.json`
2. `version` in the plugin's `marketplace.json` entry
3. **the git commit SHA of the plugin's source** ← what this repo uses
4. `unknown` (npm sources, or local dirs outside a git repo)

That resolved string is a cache key. `/plugin update` compares it to what's installed and skips the plugin if it matches.

**Plugins here deliberately omit `version`.** Every commit that lands on `main` is therefore a new version, and changes reach users with no bump step. The alternative — an explicit semver — fails silently: push a fix without bumping the string and every existing user keeps the cached copy while CI stays green and the repo looks correct. Semver earns its keep when a version range means something (a published API, plugins depending on each other with `^`/`~` constraints). For skill-only hobby plugins it is bookkeeping with a silent failure mode attached.

Consequences to accept:

- Any commit touching a plugin's files ships to users, including a README typo fix. Keep unrelated churn out of `plugins/`.
- Users see a SHA rather than a friendly version in `/plugin`. Release tags exist for humans who want a version to point at (see below).
- If a plugin ever does need explicit versions, set `version` in `plugin.json` **only** — never in both places, since `plugin.json` wins without warning. `validate.sh` flags a pinned plugin loudly and hard-fails if both are set.

## CI / validation

`.github/scripts/validate.sh` is the single source of truth for validation, shared by both workflows. It checks manifest shape and marketplace ↔ disk consistency, and runs `claude plugin validate` when the CLI is available.

**Expected warning:** `claude plugin validate` reports `No version specified. Consider adding a version following semver` for every plugin here. That is the intended setup, not a defect — do not "fix" it by adding a `version` field. It also means **never add `--strict`** to that call: `--strict` promotes the warning to an error and would fail CI on a correct repo.

**When a plugin ships a hook or an installer script, add a smoke-test layer to that script** covering each regime the plugin's README documents (no-op payloads, missing-dependency soft-fail, happy path, installer idempotency). Validation that only checks JSON shape doesn't catch the failures that actually bite users.

## Release strategy

**Delivery and releases are decoupled here.** Merging to `main` *is* the release: users track the default branch, and the new commit SHA is the new version. Nothing in the install or update path reads a git tag, and nothing reads a GitHub Release at all.

Tags and Releases exist for two human-facing reasons:

- A readable record of what landed, one entry per merged PR.
- An optional pin for cautious users: a marketplace source accepts a `ref`, so `/plugin marketplace add cliffmeyers/cliff-code@v2026.08.02` sticks to that tag.

Because there is no semver to mirror, release tags are dated: `vYYYY.MM.DD` (adding `.2`, `.3` if a day has more than one — a dot rather than a hyphen, which semver would read as a prerelease marker and sort *before* the unsuffixed tag). A date is the honest unit here — it answers "how stale am I?", which is the only question a tag can answer when delivery is continuous.

**Releases are cut automatically.** `release.yml` fires on every push to `main` under `plugins/**` or `.claude-plugin/marketplace.json`, re-runs validation, tags the merge commit, and publishes a Release with auto-generated notes.

This is safe to automate **only because PRs land as squash merges** with the PR description as the commit body. That makes each commit on `main` a curated unit — already a written release note — and makes the path filter an accurate "did this affect users?" test. **The PR is the unit of release: group work by scoping the PR.** If commits to `main` ever stop being squashed, revisit this, because per-commit releases of raw work-in-progress are noise.

Paths outside the filter (root `README.md`, `CLAUDE.md`, CI) don't cut a release. To cut one anyway, or to re-cut with a specific name, use **Actions → release → Run workflow**.

There is deliberately no `tags: [v*]` trigger: a `paths` filter applies to every push its trigger matches, and a tag push has no changed paths, so the combination would silently never fire.

`.github/workflows/validate.yml` runs on every PR to `main` and every push to `main`, so day-to-day work is gated without any tag.

## Quick reference

| Need                    | Command                                                                         |
| ----------------------- | ------------------------------------------------------------------------------- |
| Live dev on a plugin    | `claude --plugin-dir ./plugins/<name>`                                          |
| Reload after edits      | `/reload-plugins` (inside Claude)                                               |
| Validate manifests      | `claude plugin validate .`                                                      |
| Run full CI checks      | `bash .github/scripts/validate.sh`                                              |
| Smoke-test a hook       | `echo '{"prompt":"..."}' \| ./plugins/<name>/hooks/<script>.sh`                 |
| Test install end-to-end | `/plugin marketplace add <local-path>` then `/plugin install <name>@cliff-code` |
