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

## Version-bump discipline (silent gotcha)

Every plugin's `plugin.json` carries an explicit `version` field. **Bump it on every release.** If you push changes without bumping `version`, existing users see no update — Claude Code compares the resolved version to what's installed and skips identical ones.

Alternative: omit `version` entirely and let the git commit SHA drive versioning (every commit = new version, no ceremony). The default here is explicit versions; the choice is open per-plugin.

## CI / validation

`.github/scripts/validate.sh` is the single source of truth for validation, shared by both workflows. It checks manifest shape and marketplace ↔ disk consistency, and runs `claude plugin validate` when the CLI is available.

**When a plugin ships a hook or an installer script, add a smoke-test layer to that script** covering each regime the plugin's README documents (no-op payloads, missing-dependency soft-fail, happy path, installer idempotency). Validation that only checks JSON shape doesn't catch the failures that actually bite users.

## Release strategy

Marketplace-level tags drive releases via `.github/workflows/release.yml`. Pushing a tag matching `v*` triggers `.github/workflows/validate.yml` (matrix over Linux + macOS) and, on success, creates a GitHub Release with auto-generated notes.

The tag represents the state of the marketplace as a whole; each plugin's own `version:` field in `plugin.json` is what end users actually resolve against. Cutting a release:

1. Bump `version:` in `plugin.json` for each plugin whose files changed (see "Version-bump discipline" above).
2. Merge to `main` (PR + green CI).
3. Tag and push: `git tag v0.1.0 && git push origin v0.1.0`.
4. The release workflow re-validates and drafts the GitHub Release. Edit the auto-generated notes to call out which plugin(s) bumped.

`.github/workflows/validate.yml` also runs on every PR to `main` and every push to `main`, so day-to-day work is gated without needing a tag.

## Quick reference

| Need                    | Command                                                                         |
| ----------------------- | ------------------------------------------------------------------------------- |
| Live dev on a plugin    | `claude --plugin-dir ./plugins/<name>`                                          |
| Reload after edits      | `/reload-plugins` (inside Claude)                                               |
| Validate manifests      | `claude plugin validate .`                                                      |
| Run full CI checks      | `bash .github/scripts/validate.sh`                                              |
| Smoke-test a hook       | `echo '{"prompt":"..."}' \| ./plugins/<name>/hooks/<script>.sh`                 |
| Test install end-to-end | `/plugin marketplace add <local-path>` then `/plugin install <name>@cliff-code` |
