# Security policy

This is a personal hobby marketplace. Response is best-effort, but security reports are taken seriously — please report instead of dropping a public issue.

## Reporting a vulnerability

Open a private [GitHub Security Advisory](https://github.com/cliffmeyers/cliff-code/security/advisories/new) on this repo. If GitHub Advisories isn't an option, email `cliff.meyers@gmail.com` with subject line `[cliff-code security]`.

Please include:

- Which plugin (and version) is affected.
- A description of the issue and its impact.
- Reproduction steps or a proof-of-concept where applicable.

You should expect an initial acknowledgement within ~7 days. Coordinated disclosure is appreciated — please give a reasonable window before going public.

## Scope

Plugins in this marketplace may install shell hooks that execute on file-write or prompt-submit events. Issues that fall in scope include, but are not limited to:

- Command injection or arbitrary code execution in hook scripts.
- Path traversal or unauthorized filesystem writes outside documented locations.
- Integrity issues in installer scripts that download third-party binaries.
- Credential, token, or sensitive-data leakage.

Out of scope:

- Vulnerabilities in third-party tools the plugins shell out to (e.g., `curl`, or any formatter/linter a plugin wraps). Report those upstream.
- Issues that require an attacker to already have local code execution as the user.
- Social-engineering or phishing scenarios that don't involve a defect in this repo.

## Supply-chain stance

- Plugin scripts run with the user's privileges. Each plugin's `README.md` includes an explicit "Security note" describing what its hooks and scripts do; review before installing.
- Third-party binaries downloaded by installers are pinned to a specific version with a hardcoded SHA256 checksum, verified before execution.
- No telemetry. No outbound network calls except where explicitly documented (e.g., a binary download during a user-initiated install).
