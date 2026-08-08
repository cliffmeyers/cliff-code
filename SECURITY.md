# Security policy

This is a personal hobby marketplace. Response is best-effort, but security reports are taken seriously — please report privately instead of dropping a public issue.

## Reporting a vulnerability

Open a private [GitHub Security Advisory](https://github.com/cliffmeyers/cliff-code/security/advisories/new) on this repo. If GitHub Advisories isn't an option, email `cliff.meyers@gmail.com` with subject line `[cliff-code security]`.

Include which plugin is affected, the commit SHA you have installed (plugins here carry no `version` field), and reproduction steps or a proof-of-concept where applicable. Coordinated disclosure is appreciated — please give a reasonable window before going public.

## Out of scope

- Vulnerabilities in third-party tools a plugin shells out to. Report those upstream.
- Issues that require an attacker to already have local code execution as the user.
- Social-engineering scenarios that don't involve a defect in this repo.

## What's currently shipped

As of this writing the marketplace contains one plugin, `commit-message`, which is skill-only: markdown instructions, no hooks, no installer, no bundled binaries, nothing that runs on its own. Each plugin's `README.md` carries a "Security note" describing what it does when invoked; review it before installing.

No telemetry, and no outbound network calls.
