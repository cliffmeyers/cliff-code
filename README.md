# cliff-code

A small, personal [Claude Code](https://code.claude.com/docs) plugin marketplace. Grab-bag of hobby plugins I built while exploring what's possible.

## Install the marketplace

```
/plugin marketplace add cliffmeyers/cliff-code
```

Then install individual plugins:

```
/plugin install <plugin-name>@cliff-code
```

## Plugins

| Name                                             | What it does                                                                                                                    |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| [`commit-message`](./plugins/commit-message)     | Write a commit message for your uncommitted changes, matching the repo's own conventions, and copy it to the clipboard. Never commits. |

## A word on what's in here

These are personal experiments. They're packaged properly (manifest, docs, CI) but the bar for "is this useful to anyone but me" is low. Install at your own discretion.

Plugins that execute shell commands are clearly noted in their own README — read those before installing, and feel free to inspect the scripts in this repo.

## Adding a new plugin

For my own future reference (and any contributor's):

1. Create `plugins/<plugin-name>/` and `plugins/<plugin-name>/.claude-plugin/`.
2. Write `plugins/<plugin-name>/.claude-plugin/plugin.json` with `name`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`. Leave `version` out — see [`CLAUDE.md`](./CLAUDE.md) for why.
3. Add the component dirs you need at the plugin root: `hooks/`, `skills/`, `commands/`, `agents/`, etc.
4. Write `plugins/<plugin-name>/README.md` (install command, usage, security notes, any disclaimers).
5. Add an entry to `.claude-plugin/marketplace.json` under `plugins` with `name`, `source: ./plugins/<plugin-name>`, `description`, plus `homepage` / `repository` / `license` / `keywords`.
6. Validate: `claude plugin validate .`
7. Test in dev: `claude --plugin-dir ./plugins/<plugin-name>`
8. Test the full install path: `/plugin marketplace add /path/to/cliff-code` then `/plugin install <plugin-name>@cliff-code` in a fresh session.
9. Commit and push. Merging to `main` is the release — plugins here carry no `version` field, so Claude Code versions them by commit SHA and users pick up changes on the next `/plugin update`.

See [`CLAUDE.md`](./CLAUDE.md) for more detail on the dev workflow, granularity principles, and how versioning works here.

## License

[MIT](./LICENSE). Use, fork, modify freely.

## Issues / feedback

File an issue on the [GitHub repo](https://github.com/cliffmeyers/cliff-code/issues).

For anything security-related, don't open a public issue — see [`SECURITY.md`](./SECURITY.md) for the private disclosure path and what's in scope.
