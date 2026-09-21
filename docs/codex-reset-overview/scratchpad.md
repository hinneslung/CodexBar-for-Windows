# Codex reset overview scratchpad

## Current state

- PIC: Pillow.
- Branch: `windows/codex-reset-overview`.
- Base: `fork/windows-native-app` at `0d9f742e0`; fetched and confirmed synchronized.
- Original plan: [plan.md](plan.md). Team rules: [rules.md](rules.md).
- Status: feature/review/native QA complete; manual x64/ARM64 e2e passed; final CI follows a two-comment architecture correction.
- User authorized CUA native app launch, stopping an existing instance if necessary,
  and visual verification. Real-account provider probes have not been requested.

## Team and ownership

| Role | Profile | Scope | Status |
| --- | --- | --- | --- |
| PIC | Pillow | Docs, integration, checks, native QA, PR and CI | Active |
| Implementation | Fattie | Three production Swift files | Complete; agent `38c7f4dc-48ee-463a-8f00-ad71422533fc` |
| Tests | Coco | Four existing Windows test files | Complete, including PIC revisions; agent `b6737d41-d4f3-45ba-a6ad-b1799893872a` |
| Review | Biru | Independent review against original plan | Unavailable: expired OAuth session |
| Review fallback | Chester | Independent review against original plan | Unavailable: session exposed only HTTP tools |
| Independent review fallback | Fresh Fattie session | Review against original plan | Complete, no blockers; agent `aff5fbc1-7b86-420b-bba2-b9b998730296` |

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
- Full native suite passed: 190 tests in 25 suites after final test revisions and formatting.
- Native build passed with warnings as errors; pinned formatter clean on all seven files.
- CUA fixture smoke passed all three inventory scenarios and detail/back navigation;
  see [verification.md](verification.md) and `docs/screenshots/codex-reset-overview-*.png`.
- agent-browser opened PR #9 and captured its page title, snapshot, and screenshot.
- Source/test diff after formatting and architecture comments: 141 production additions, 222 test additions,
  10 deletions. Slightly over the estimate due to strict optional decoding/copy paths
  and meaningful edge-case coverage. Epic evidence is separate from implementation size.
- Initial CI: Windows ARM64 passed; lint failed on three `empty_count` sites. Fattie
  fixed only those sites. Native 190-test suite passed again; formatter is clean.
- Local pinned SwiftLint needs Linux SourceKit, absent in WSL; use the clean CI runner.
- Independent review complete: no correctness blockers; see [review-independent.md](review-independent.md).
- Clean-checkout lint and all Windows/Linux jobs passed. Aggregate failed because
  the event retained draft status and deferred required macOS compatibility tests.
  PR is confirmed ready; the next push starts the full compatibility run.
- Manual ARM64 installer lifecycle passed. x64 uncovered an existing test-harness
  assumption: reinstall used `unins001.exe`, while the test invoked `unins000.exe`.
  PIC assigned a bounded test repair and independent review; production
  app and installer behavior remain unchanged. See [initial evidence](installer-e2e-initial.log).
  Repair touches three existing test scripts (+85/-7): lifecycle resolver (+26/-3),
  fake-registry cleanup tests (+58/-4), and one diagnostics resolver stub (+1).
  Both offline scripts passed under PowerShell 7; [log](installer-harness-tests.log).
- User quit the three fixture apps; process readback confirms none remain and the
  installed CodexBar PID 3732 is still running. CUA and browser QA sessions closed.
- Manual e2e after harness repair passed on both x64 and ARM64; [final log](installer-e2e-final.log).
- Ready-state CI passed Windows/Linux/lint but macOS shard 0 required justification
  comments on the two new Codex gates. Added exactly those two comments, shortened
  them to the formatter limit, and verified formatting. No behavior change.
  The second macOS shard passed; the architecture group was the only failed group.
- Pending: final clean-checkout CI after the comment-only correction.

## Reviewer decision log

- PIC accepted test coverage additions: decoder-to-row integration, malformed dates/mixed
  inventories, copy-helper preservation, and precise accessibility hiding assertions.
- Coco's subsecond warning was stale: production checks the positive interval before integer
  conversion, and the +0.5-second test passed. No additional production change warranted.
- Biru could not authenticate; reassigned independent review to Chester immediately.
- Chester lacked local workspace tools; reassigned to a fresh Fattie-profile reviewer
  who did not author this implementation and reviewed the committed base-to-head diff.
- PIC agrees with the independent no-blocker verdict after inspection and validation.
- Optional review finding: exact plan/reset/balance ordering lacks a dedicated unit assertion.
  Correct observation, low urgency, deferred per user instruction. Production order and
  native screenshots already demonstrate the required behavior; no scope expansion.
- Installer review: PIC accepts fresh registered-path lookup, strict command/path validation,
  registry disposal, and preservation of a primary error if cleanup also fails. These
  address the observed harness failure without changing app, installer, or workflow code.
  Independent final diff review found no blockers; PIC agrees after inspecting the diff
  and running both offline scripts. See the appended [review](review-independent.md).

## Truncation follow-up (2026-09-21)

- User rejected trailing-balance truncation and directed future GUI QA to the SSH VM.
- Fattie changed only `drawOverviewRow` (+17/-1); PIC accepts the independent
  [no-blocker review](review-truncation.md). Actual reset-label measurement reclaims
  unused space while preserving the existing maximum reset width and fallback.
- Formatter completed; native warnings-as-errors test build and all 190 tests passed.
- Fresh offline fixture ran on `g4-vmware-win11` through CUA 0.28.1 at 100% scaling.
  Full reported text, longer reset date, provider detail, and Back passed. See
  [VM evidence](truncation-verification.md). The fixture bundle now includes resources
  so it runs independently of the source checkout.
- CUA refused fixture termination on ownership; normal Quit input also failed.
  User was notified. No safeguard bypassed; the local desktop was untouched.
- Final CI and manual packaging/installer e2e passed; updated x64 EXE was delivered.
  User then authorized merge and release. PR #9 merged as `4096daa82`.
- Release preparation and packaged VM evidence are recorded in [release.md](release.md).
  The user closed the earlier fixture; its PID was confirmed absent.

## Original delivery links

- [PR #9](https://github.com/hinneslung/CodexBar-for-Windows/pull/9), targeting `windows-native-app`.
- [Code validation CI](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35559278837).
- [Successful manual packaging/installer e2e](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35561825143).
- [Current PR checks](https://github.com/hinneslung/CodexBar-for-Windows/pull/9/checks).
- Validated feature code commit: `667da70eb7a4c1ba86ff0e5250edbe8306fde45a`.
