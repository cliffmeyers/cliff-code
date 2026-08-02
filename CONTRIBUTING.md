# Contributing

`cliff-code` is a personal Claude Code plugin marketplace — built as a hobby project and learning exercise. Updates land when they land, and priorities reflect whatever I find interesting at the time.

That said, collaboration is welcome. A few notes if you'd like to participate:

- **Open an issue before a PR.** A short conversation up-front avoids wasted effort on either side. Bug reports, feature ideas, and new-plugin proposals are all fair game.
- **Keep PRs scoped.** See [CLAUDE.md](./CLAUDE.md) for the granularity principles (one plugin per cohesive purpose; hooks especially get their own plugin).
- **Run validation locally.** `claude plugin validate .` plus `bash .github/scripts/validate.sh` cover the basics; CI re-runs the same checks on every PR.
- **Be patient.** Response time is best-effort.

For security issues, don't open a public issue — see [SECURITY.md](./SECURITY.md) for the disclosure path.

By contributing, you agree your contributions will be licensed under the repository's [MIT License](./LICENSE).
