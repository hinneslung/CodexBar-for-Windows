# Codex reset overview scratchpad

## Current state

- PIC: Pillow.
- Branch: `windows/codex-reset-overview`.
- Base: `fork/windows-native-app` at `0d9f742e0`; fetched and confirmed synchronized.
- Original plan: [plan.md](plan.md). Team rules: [rules.md](rules.md).
- Status: implementation landed; 69 focused tests passed; independent review and native QA underway.
- User authorized CUA native app launch, stopping an existing instance if necessary,
  and visual verification. Real-account provider probes have not been requested.

## Team and ownership

| Role | Profile | Scope | Status |
| --- | --- | --- | --- |
| PIC | Pillow | Docs, integration, checks, native QA, PR and CI | Active |
| Implementation | Fattie | Three production Swift files | Complete; agent `38c7f4dc-48ee-463a-8f00-ad71422533fc` |
| Tests | Coco | Four existing Windows test files | Tests landed; PIC requested integration/edge-case additions; agent `b6737d41-d4f3-45ba-a6ad-b1799893872a` |
| Review | Biru | Independent review against original plan | Unavailable: expired OAuth session |
| Review fallback | Chester | Independent review against original plan | Active; agent `5b4b7345-6f25-4435-a4c2-9d84de9a2a36` |

## Decisions

- Retain lightweight available-credit expiry data, not a frozen count.
- Windows executable has no dependency on CodexBarCore; consume its existing JSON
  using a small Windows value type rather than importing the upstream core.
- The cached-snapshot copier is an additional one-line propagation touchpoint.
- CUA supplies native smoke evidence; browser tooling cannot drive Win32 overview UI.

## Verification ledger

- Focused Swift run: 69 tests in 4 suites passed; `focused-tests.log`.
- `make check` / `make test` attempted via Ubuntu-24.04 WSL: both fail before execution
  because checked-out shell script shebangs contain CRLF (`bash\r`). Logs retained.
  No repository-wide line-ending conversion planned for this feature.
- Pinned local SwiftFormat 0.61.1 available via WSL; native Swift 6.3.3 available.
- CUA interactive daemon confirmed accessible despite shell-local doctor Session 0 warning.
- agent-browser headless repository navigation succeeded; `browser-repository-snapshot.log`.
- Windows gh login is invalid, but the existing Ubuntu gh login works; use it for PR/CI.
- Pending: full native suite, build, formatting/lint, independent review, CUA fixture
  smoke/screenshots, PR creation, CI and manual installer e2e.

## Reviewer decision log

- PIC accepted test coverage additions: decoder-to-row integration, malformed dates/mixed
  inventories, copy-helper preservation, and precise accessibility hiding assertions.
- Coco's subsecond warning was stale: production checks the positive interval before integer
  conversion, and the +0.5-second test passed. No additional production change warranted.
- Biru could not authenticate; reassigned independent review to Chester immediately.

## Delivery links

PR and pipeline URLs pending.
