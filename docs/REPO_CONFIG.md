# Design note: a `repo-standards` plugin

Status: **design agreed, no code written.** Captured 2026-08-08 so this can be picked up cold.

Goal: a plugin that audits a GitHub repo's configuration against a profile of my standards,
reports drift, and applies fixes when asked. Motivated by the pre-open-source review of this
repo, where the settings that mattered most (squash-message config, Actions permissions, private
vulnerability reporting) were invisible until someone went looking endpoint by endpoint.

## Decisions locked

| Question | Decision |
| --- | --- |
| Mutation authority | Audit + plan by default; `apply` is a separate, explicit invocation |
| Desired state | `public` / `private` profiles ship with the plugin; in-repo file names a base via `extends` and overrides individual properties |
| Scope per run | Current repo only, inferred from the working directory |
| Packaging | Scripts inside a plugin in this marketplace |
| Language | Node, single zero-dependency `.mjs` |

## Verified environment facts

Checked on the WSL2 box, 2026-08-08. Re-verify on macOS before relying on any of it there.

- **`gh` auth works inside the Claude Code sandbox.** Token is read from `~/.config/gh/hosts.yml`
  (mode 0600); no `GH_TOKEN` env var, no keyring. Reads against repo settings and rulesets
  succeeded, including `repos/{owner}/{repo}/rulesets/{id}`, which requires repo admin.
- **Token scopes are `gist`, `read:org`, `repo`.** `repo` covers repo settings and rulesets on
  repos I admin. There is **no `admin:org`** — org-level rulesets and org settings will 403. That
  is fine for personal repos and will bite the first time this points at a work repo, so the
  audit must distinguish "403, couldn't read" from "not set".
- **Only reads were exercised.** Writes use the same network path so the sandbox shouldn't block
  them, but they were never tested. Gate them behind an `ask` permission rule regardless.
- Runtimes present: node v24.16.0, gh 2.45.0, jq 1.7, python3 3.12.3.
- **`gh api --jq` needs no `jq` binary** — gh embeds gojq. But it only filters API responses; it
  cannot run a jq program over a local file, which is why the config merge can't be shell-only.

## Language rationale

`gh` is a hard dependency either way. The real question is the second dependency.

Bash would need real `jq` for the profile merge and the observed-vs-desired diff. macOS doesn't
ship `jq` and I avoid Brew, so on my day-job machine that's the more fragile choice. Node gives
zero *packages* — `node:child_process`, `node:fs`, `node:test`, nothing installed — sidesteps
bash 3.2 on macOS, and makes the layered `extends` merge about fifteen lines instead of a fight.

Honest cost: Node isn't preinstalled on macOS either. A stranger installing this needs both `gh`
and Node, so the README must say so and the script must fail with a clear message, not a stack
trace.

Rejected: **Python** — stdlib-only would work, but maintaining a tool I depend on in a language
I'm still learning is the wrong trade. **Go** — compilation and binary distribution violate the
no-install constraint outright.

Aside, found while checking this: `.github/scripts/validate.sh` hard-requires `jq` at line 36.
CI runners preinstall it so CI is green, but `bash .github/scripts/validate.sh` on a fresh Mac
would fail. Worth a soft-fail path or a note in `CLAUDE.md`.

## Architecture

The split is **mechanical vs judgment**, and both showed up in the review that prompted this.

The mechanical part was eight API calls compared against expectations — that should be a script:
deterministic, no drift about which endpoints to hit, testable offline against fixtures.

The most valuable finding was not mechanical. Issues were disabled while `CONTRIBUTING.md` said
"open an issue before a PR." No JSON schema encodes that; it needed reading two files and
noticing they contradicted a setting. That's the skill's job, and it's why this isn't a bare
script.

Four pieces:

1. **`audit`** — read-only sweep, N `gh api` calls → one unified JSON of observed state. Records
   *why* a field is absent (403 / not set / not applicable), because those need different
   handling.
2. **Profiles** — data shipped with the plugin, not prose in `SKILL.md`.
3. **`plan`** — pure function of `(observed, desired) → diffs`, each carrying the exact `gh`
   command that would fix it. No network, so it's trivially unit-testable. This purity is the
   design point that makes the whole thing verifiable.
4. **`SKILL.md`** — runs the audit, explains what matters and why, and performs the cross-file
   checks that need reading the repo rather than querying it.

## Config schema

```jsonc
// .github/repo-standards.json — in the target repo, version controlled
{
  "extends": "public",
  "rules": {
    "merge.squashOnly": true,
    "ruleset.requiredApprovals": 0,
    "community.codeOfConduct": { "ignore": true, "reason": "personal hobby repo" }
  }
}
```

Three states per rule: enforce a value, inherit from the profile, or ignore **with a required
reason**. The mandatory reason is what keeps legitimate deviations from being re-flagged every
run, and makes each exception reviewable in a PR rather than invisible.

## Checks to implement

Grouped roughly by how often they're wrong. Not final — worth a research pass before building.

**Merge hygiene**
- squash-only (`allow_squash_merge` on; merge commit and rebase off)
- `squash_merge_commit_title=PR_TITLE`, `squash_merge_commit_message=PR_BODY` — silently wrong by
  default, and it's what makes this repo's release notes work
- `delete_branch_on_merge`, `allow_auto_merge`, `allow_update_branch`

**Default-branch ruleset**
- require PR; required status checks with `strict_required_status_checks_policy`
- linear history; block deletion; block force-push
- approval count — 0 is correct for a solo repo; a checker that demands 1 is wrong for me
- allowed merge methods on the ruleset itself (see the trap below)

**Security**
- private vulnerability reporting (only readable/settable once public)
- secret scanning + push protection
- Dependabot alerts and security updates
- whether `dependabot.yml` covers every ecosystem actually present in the repo

**Actions**
- `default_workflow_permissions` should be `read`
- `can_approve_pull_request_reviews` should be `false`
- fork-PR approval policy
- third-party actions pinned to full SHAs

**Metadata & community**
- description, topics, homepage, detected license, social preview
- presence of README / LICENSE / CONTRIBUTING / SECURITY
- feature toggles: issues, projects, wiki, discussions

**Cross-file consistency — skill, not script; defer past v1**
- docs pointing at disabled features
- `SECURITY.md` claims that don't match what's actually shipped
- README setup steps that contradict the ruleset

## Safety constraints

- **Never blind-`PUT` a ruleset.** `PUT /repos/{owner}/{repo}/rulesets/{id}` replaces the whole
  object: you must resend every rule, and a malformed payload drops merge protection silently
  rather than erroring. Either do targeted edits or print the UI path and let a human click it.
- **Classify each rule reversible vs irreversible.** Turning off Issues hides existing issues;
  most other toggles are a round-trip. `apply` should prompt harder on the first kind.
- **`apply` prints each mutation before running it**, and is never reachable from the audit
  command.

## Layout

```
plugins/repo-standards/
  .claude-plugin/plugin.json
  README.md                          ← install, dependencies, security note
  skills/repo-standards/SKILL.md
  scripts/
    repo-standards.mjs               ← audit | plan | apply
    profiles/{public,private}.json
  tests/
    fixtures/*.json                  ← recorded API responses
    repo-standards.test.mjs          ← node --test, no network
```

## Reference: cliff-code's observed state, 2026-08-08

Verified via `gh api`. Good seed for the first test fixture.

```jsonc
{
  "visibility": "PRIVATE",              // pre-open-source
  "hasIssuesEnabled": true,             // was false; enabled during the review
  "has_discussions": false,
  "squashMergeAllowed": true,
  "mergeCommitAllowed": false,
  "rebaseMergeAllowed": false,
  "squash_merge_commit_title": "PR_TITLE",
  "squash_merge_commit_message": "PR_BODY",
  "deleteBranchOnMerge": true,
  "allow_update_branch": true,
  "web_commit_signoff_required": false,
  "topics": ["claude-code", "claude-code-plugin"],
  "homepageUrl": "",                    // unset
  "licenseInfo": null,                  // LICENSE is on the branch, not main; resolves on merge
  "actions.default_workflow_permissions": "read",
  "actions.can_approve_pull_request_reviews": false,
  "security_and_analysis": null,        // not readable while private
  "ruleset:merge-main": {
    "enforcement": "active",
    "conditions": "~DEFAULT_BRANCH",
    "rules": [
      "deletion", "non_fast_forward", "required_linear_history",
      { "pull_request": { "required_approving_review_count": 0,
                          "allowed_merge_methods": ["merge", "squash", "rebase"] } },
      { "required_status_checks": { "strict": true,
                                    "contexts": ["validate (macos-latest)",
                                                 "validate (ubuntu-latest)"] } }
    ]
  }
}
```

Known drift at capture time: repo is private; `allowed_merge_methods` on the ruleset still lists
all three even though repo-level settings permit only squash; private vulnerability reporting not
yet enabled; homepage unset.

## Sequencing and consequences for this repo

Land the current initial-import PR first. This is its own PR and its own release afterward.

It would be the **first plugin here shipping executable code**, which triggers three things:

- `SECURITY.md`'s "What's currently shipped" section becomes wrong and needs updating, along with
  a per-plugin security note covering what the script does and that it can mutate repo settings.
- `CLAUDE.md`'s rule kicks in: a plugin shipping a script needs a smoke-test layer covering each
  regime its README documents.
- The `ubuntu-latest` / `macos-latest` matrix in `validate.yml` starts testing something real.
  Today it validates JSON twice; with a script that shells out to `gh` and runs on both macOS and
  WSL, both legs earn their keep.

## Open questions

- **Name.** `repo-standards` is descriptive but dry.
- **v1 scope.** Recommendation: mechanical audit only. Defer cross-file consistency checks — they
  are the highest-value findings but the most prone to false positives, and they're easier to get
  right once the mechanical layer is stable.
- **Profile contents.** The `public` / `private` defaults haven't been written yet; the check list
  above is the raw material. Worth a research pass for anything missed.
- **macOS verification.** Every environment fact above was checked on WSL2 only.
