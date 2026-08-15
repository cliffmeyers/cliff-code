# commit-message

Write a commit message for whatever is currently uncommitted, print it, and copy it to the clipboard. **It never commits** — you stay in control of the actual `git commit`.

## Install

```
/plugin marketplace add cliffmeyers/cliff-code
/plugin install commit-message@cliff-code
```

## Usage

Ask for it in plain language — "write a commit message", "generate a commit message", "message for these changes" — or invoke the skill directly:

```
/commit-message:commit-message
```

Plugin skills are namespaced `/<plugin>:<skill>`, which is why the name appears twice. The bare `/commit-message` works too, unless another command in your setup already claims that name.

## What it does

- **Respects your staging.** If anything is staged, it describes *only* the staged changes — a partial stage is treated as deliberate. Otherwise it covers all modified and untracked files.
- **Matches the repo's conventions.** It checks for a mechanically-enforced convention first (`commitlint.config.*`, `.releaserc*`, a `commitlint` key in `package.json`) since those are enforced by a hook or by CI. Absent that, it mirrors the last 20 subjects — including house style that near-misses a published standard (`feature:` where Conventional Commits would say `feat:`).
- **Picks a shape that fits.** A single phrase for a small change; a summary plus bullets for a broad one; a short paragraph of reasoning only when the *why* can't be recovered from the diff.
- **Imperative mood, always.** "fix the parser", not "fixed the parser" — this holds even when the repo's history is past tense, because git writes its own messages imperatively (`Merge branch…`, `Revert…`).
- **Flags breaking changes structurally** — `feat!:` in a repo using type prefixes, otherwise a `BREAKING CHANGE:` footer, so tooling sees it.

It won't add a generated-by footer, a `Signed-off-by:` trailer, or an invented issue number.

## Clipboard support

The message is copied via the first available of `pbcopy` (macOS), `clip.exe` (WSL), `wl-copy`, `xclip`, or `xsel` (Linux). If none is installed, the skill says so and names what was missing — the message is always printed in a code block first, so nothing is lost.

## Security note

This plugin ships a skill only — no hooks, no installer, nothing that runs on its own. When you invoke it, it runs read-only git commands (`git rev-parse`, `git status`, `git log`, `git diff`) plus one clipboard write. It is explicitly instructed never to run `git commit`, `git add`, or `git stash`, or anything else that mutates the repository or the index.

Your diff is read by the model in order to describe it, the same as any other file you ask Claude to look at.

## License

[MIT](../../LICENSE)
