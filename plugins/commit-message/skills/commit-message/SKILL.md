---
name: commit-message
description: >-
  Author a git commit message describing the current uncommitted changes, print it, and copy it
  to the clipboard. Use when the user says "commit message", "write a commit message", "generate
  a commit message", "write a commit", or "message for these changes".
---

# Commit Message

Author a commit message for the work that is currently uncommitted, print it, and copy it to
the clipboard.

**This skill never commits.** Do not run `git commit`, `git add`, `git stash`, or anything else
that mutates the repository or the index. It is read-only over git, plus one clipboard write.
The user commits themselves.

## Step 1: Confirm a git repo

```sh
git rev-parse --show-toplevel
```

If this fails, tell the user the current directory is not a git repository and stop.

## Step 2: Determine scope

```sh
git status --porcelain
```

- **If anything is staged** (any entry with a non-space, non-`?` character in column 1),
  describe **only the staged changes**. A partial stage is deliberate — respect it.
  Read them with `git diff --cached --stat` and `git diff --cached`.
- **Otherwise**, describe **all modified and untracked files**. Read them with
  `git diff HEAD --stat` and `git diff HEAD`, then read the untracked files themselves
  (they have no diff — use the Read tool, and skip anything that is binary or generated).
- **If there is nothing to describe**, say the working tree is clean and stop.

If the diff is very large, use `--stat` plus targeted diffs of the most significant files
rather than dumping everything.

## Step 3: Match the repo's subject convention

First check whether the repo enforces a convention mechanically:

```sh
ls commitlint.config.* .commitlintrc* .releaserc* release.config.* 2>/dev/null
```

Also check `package.json` for a `commitlint` or `release` key. **If any of these exist, that
config wins over history** — its type list and case rules are enforced by a commit hook or by
CI, so a message that contradicts them is rejected, or silently produces no release. Follow the
config and tell the user in one line if the repo's history disagrees with it.

Otherwise mirror the repo:

```sh
git log --oneline -20
```

- If those subjects carry type prefixes (`feature:`, `fix:`, `chore:`, `docs:`), use the same
  vocabulary — reuse the prefixes that actually appear, do not import a different set. House
  style wins even when it is a near-miss of a published standard (`feature:` where Conventional
  Commits would say `feat:`); consistency with the repo is worth more than conformance to a spec
  the repo has not adopted.
- If they are bare phrases, write a bare phrase.
- Match their capitalization.

Ignore artifacts that the forge adds on merge — a trailing `(#123)` on past subjects comes from
squash-merging a PR, not from the author. Never append one. Do leave room for it: if every
recent subject carries one, the forge will add ~8 characters to whatever you write.

## Step 4: Write the message

Use the context of the work in this session — what was being built and why — not just the
mechanical shape of the diff. Describe the change, not the process: no mention of the
conversation, the tooling, or how many attempts it took.

Pick one of three shapes.

**Small change** — one cohesive change, typically a file or two, where the diff speaks for
itself. A single phrase or sentence, nothing else:

```
pin pnpm to v11
```

```
fix a bug where the 'name' field was not respecting sort
```

**Larger change** — several distinct changes, or one change spanning several concerns. A summary
phrase or sentence, a blank line, then bullets of similar length:

```
refactor search apis and command flags

- collapse the three search endpoints into a single parameterized route
- rename --filter to --where; the old flag still works but warns
- drop the unused pagination cursor from the response payload
```

**Change with non-obvious reasoning** — regardless of size, when the *why* cannot be recovered
from the diff. Use this when there is a discarded alternative worth recording, a bug whose
reproduction matters, or a constraint that explains an otherwise odd-looking fix. A subject, a
blank line, then one short paragraph — optionally followed by bullets if the change is also
broad:

```
fix a race in the session cache

Two requests arriving in the same tick both saw an empty cache and
both populated it, so the second overwrote the first's entry. Locking
the write was rejected because it serializes every read.
```

This shape is the exception, not the default. Reach for it when a reader six months from now
would otherwise have to reconstruct the reasoning from scratch — not to demonstrate effort.

Keep the prose plain and factual: state the problem, the cause, and why this approach over the
alternative. No build-up, no adjectives for emphasis, no restating what the diff already shows,
no closing summary. Five lines is a lot. If the reasoning cannot be given in that space, it
belongs in the PR description instead, and the commit stays terse.

Rules for all shapes:

- **Write the subject in the imperative mood** — "fix the parser", not "fixed the parser" or
  "fixes the parser". The test: *if applied, this commit will ___*. This one rule is absolute
  and overrides Step 3: follow it even when the repo's history is written in past tense, because
  git generates its own messages imperatively (`Merge branch…`, `Revert…`) and a mixed history
  reads badly against them.
- Keep the subject line under ~72 characters, and no trailing period.
- Wrap body lines at 72 characters. Git does not wrap them for you. Indent the continuation of
  a bullet by two spaces.
- Each bullet is a phrase or sentence, at most two sentences. Bullets cover distinct changes.
  Do not restate the subject or pad the list to look thorough.
- **If the change breaks compatibility, say so structurally**, not just in prose — tooling reads
  the marker and ignores the paragraph. In a repo using type prefixes, add `!` before the colon
  (`feat!: drop node 18`). Otherwise add a `BREAKING CHANGE: <what breaks>` footer after a blank
  line.
- No generated-by footer — the user is the committer, and this skill is not a co-author.
- A `Fixes #123` / `Closes #123` footer is fine when the issue number is genuinely known from
  the work at hand or the branch name. Never invent ticket numbers, issue links, or scopes.
- Never add a `Signed-off-by:` trailer, even if the repo's history is full of them.

## Step 5: Print it

Print the message in a fenced code block so it can be read and copied by hand if the clipboard
step fails. Print nothing above it but a one-line note about scope when it is non-obvious —
for example, that only staged changes were described.

## Step 6: Copy to clipboard

Pipe the exact same text to the platform's clipboard command. Run it as a single Bash call with
a quoted heredoc so nothing in the message is expanded:

```sh
msg=$(cat <<'COMMIT_MSG'
<the message, verbatim>
COMMIT_MSG
)
if command -v pbcopy >/dev/null 2>&1; then printf '%s' "$msg" | pbcopy
elif command -v clip.exe >/dev/null 2>&1; then printf '%s' "$msg" | clip.exe
elif command -v wl-copy >/dev/null 2>&1; then printf '%s' "$msg" | wl-copy
elif command -v xclip   >/dev/null 2>&1; then printf '%s' "$msg" | xclip -selection clipboard
elif command -v xsel    >/dev/null 2>&1; then printf '%s' "$msg" | xsel --clipboard --input
else echo "NO_CLIPBOARD"; fi
```

`pbcopy` covers macOS; `clip.exe` covers WSL; the rest cover bare Linux.

Then print exactly:

> Copied to clipboard.

If the script printed `NO_CLIPBOARD` or the command failed, say the clipboard could not be
written and which tool was missing. Never claim the copy succeeded when it did not.
