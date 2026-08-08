# TODO

Loose ideas, not commitments. Anything here that becomes real work belongs in an issue or a PR.

## Possibly bundle a commit message linter

The `commit-message` skill writes messages but nothing checks them. Worth deciding whether a
linter belongs in this repo at all, and separately whether the skill should know about more of
them.

Candidates, roughly in order of how widely used they are:

| Tool | Runtime | Config file |
| --- | --- | --- |
| commitlint | Node | `commitlint.config.*`, `.commitlintrc*`, `package.json` |
| gitlint | Python | `.gitlint` |
| committed | Rust (single binary) | `committed.toml` |
| cocogitto (`cog`) | Rust | `cog.toml` |
| Commitizen Tools (`cz check`) | Python | `.cz.toml`, `pyproject.toml` |
| conform | Go | `.conform.yaml` |

Two open questions, which are independent:

**1. Should this repo enforce a convention on itself?** Two things cut against it. The history
here isn't Conventional Commits (`omit version from plugin so that…`), so adopting commitlint's
conventional config is a style migration, not a switch to flip. And PRs land as squash merges
with the PR description as the body, so the subject that reaches `main` comes from the PR title
— a `commit-msg` hook never sees it. If we ever want mechanical enforcement, the tool that
matches how commits are actually produced here is `amannn/action-semantic-pull-request`, which
lints the PR title.

**2. Should the skill detect more linters?** Step 3 of `SKILL.md` already checks for commitlint
and semantic-release configs and treats them as authoritative over history. Extending that `ls`
to the rest of the table above is cheap and independent of question 1. Also worth checking
`git config --get commit.template` — a `.gitmessage` is a strong signal of house style even
though nothing enforces it.
