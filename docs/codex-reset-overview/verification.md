# Verification evidence

## Local checks

Environment: Windows x64, Swift 6.3.3, repository at `windows/codex-reset-overview`.

| Check | Result | Evidence |
| --- | --- | --- |
| Four focused suites, warnings as errors | 69 tests passed | [focused-tests.log](focused-tests.log) |
| Full native Windows suite after test revisions and formatting | 190 tests / 25 suites passed | [windows-tests.log](windows-tests.log) |
| Native application build, warnings as errors | Passed | [windows-build.log](windows-build.log) |
| Pinned SwiftFormat 0.61.1 on all seven changed Swift files | Passed, 0/7 need formatting | [swiftformat.log](swiftformat.log) |
| `make check`, `make test` in WSL | Cannot start: Windows checkout shell shebangs contain CRLF | [make-check.log](make-check.log), [make-test.log](make-test.log) |
| Offline installer resolver/cleanup and diagnostics tests | Passed under PowerShell 7 | [installer-harness-tests.log](installer-harness-tests.log) |
| Manual packaging, startup and installer lifecycle, x64 + ARM64 | Passed on `7b172fa25` | [final e2e log](installer-e2e-final.log) |

Clean-checkout CI passed lint, all 190 tests on both Windows x64 and ARM64, and all
Linux build/test jobs. See [selected CI logs](ci-checks.log). No live provider,
browser-cookie, or Keychain probes were used.

Initial CI SwiftLint found three `empty_count` violations; all were changed to
`!availableExpiries.isEmpty`, and all 190 native tests passed again. The local pinned
SwiftLint binary could be installed but cannot run in WSL without Linux SourceKit;
the CI runner passed with zero violations. See [initial diagnostics](ci-lint-initial.log)
and [local tool limitation](swiftlint.log).

Run `35559278837` retained the PR's earlier draft event state. Its aggregate gate
failed solely because macOS compatibility tests were deferred; all executed jobs
passed. The PR is ready for review, and the final evidence push triggers a new run
including those compatibility tests. Final checks are visible on [PR #9's checks
page](https://github.com/hinneslung/CodexBar-for-Windows/pull/9/checks).

The ready-state run passed all Windows/Linux jobs and lint, then macOS shard 0 found
two missing provider-specific architecture comments. Both Codex-only inventory gates
now explain their ownership inline. This is a comment-only correction; behavioral
test and manual e2e evidence is unchanged. See [architecture diagnostic](ci-architecture.log)
and the PR checks page for the subsequent complete run.

## Native smoke

`build-smoke.ps1` compiles the actual Windows sources with `SmokeMain.swift` replacing
only the application entry point. It injects synthetic CLI JSON via the real decoder,
uses a temporary configuration and fixture data source, and opens the actual native
overview. It does not load user settings or credentials. This proves native rendering
and navigation, not the availability of reset credits on either real account.

Built executable:
`%TEMP%/CodexBar/qa/reset-overview/CodexBarResetSmoke.exe`.
Build command: `./docs/codex-reset-overview/build-smoke.ps1`.
Build evidence: [smoke-build.log](smoke-build.log).

CUA `launch_app` started that exact executable in interactive session 2.
Window capture was 628 × 380 pixels at the existing display scaling (logical width 360).
The custom Win32 surface exposes no actionable UIA controls; the snapshots correctly
reported degraded accessibility, so navigation used background pixel clicks grounded
in fresh native screenshots.

| Scenario | Observed result | Screenshot |
| --- | --- | --- |
| Work/personal inventories | Work `1 reset (5d)`, Personal `1 reset (2h)`; Claude control has none | [Days/hours](../screenshots/codex-reset-overview-days-hours.png) |
| Minute/no-expiry | Work `1 reset (20m)`; Personal `1 reset` with no parentheses | [Minutes/no-expiry](../screenshots/codex-reset-overview-minutes-no-expiry.png) |
| Empty/multiple | Empty inventory hides; two resets show earliest expiry `(2h)` | [Empty/multiple](../screenshots/codex-reset-overview-empty-multiple.png) |
| Navigation | Clicking Work opens its real detail screen; Back returns to overview with reset labels intact | [Provider detail](../screenshots/codex-reset-overview-provider-detail.png), [back state](cua-back.json) |

Count and expiry fit on each row. Business plan plus count leaves the trailing credit
balance ellipsized by the existing layout; the governing usage percentage and quota
reset time remain intact. No layout change was needed.

The original installed CodexBar process was left untouched. CUA's process ownership
check refused fixture termination, and later taskbar actions did not reliably work.
The user quit all three fixture apps. A process readback at 12:31 HKT confirmed that
`CodexBarResetSmoke` was absent and installed CodexBar PID 3732 remained running.
No process-termination safeguard was bypassed. The CUA lifecycle session and separate
agent-browser QA session were closed after evidence capture.

## Browser smoke and delivery

agent-browser opened the repository successfully and captured
[the repository snapshot](browser-repository-snapshot.log).
- [PR #9](https://github.com/hinneslung/CodexBar-for-Windows/pull/9): agent-browser
  verified the page URL/title and captured [its snapshot](browser-pr-snapshot.log)
  and [screenshot](../screenshots/codex-reset-overview-pr.png).
- [Code validation CI](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35559278837),
  with the draft-state aggregate limitation described above.
- [Manual installer-e2e run](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35559280618),
  dispatched on the feature branch with a QA artifact version, without release publication.
  Code commit: `667da70eb7a4c1ba86ff0e5250edbe8306fde45a`.

The initial manual run passed on ARM64. x64 passed app startup but exposed an existing
test assumption during reinstall: Inno selected `unins001.exe`, while the test invoked
`unins000.exe`. [Diagnostic excerpts](installer-e2e-initial.log) show the overlapping
cleanup. The test now resolves the current registered uninstaller, validates its exact
installation directory/name, and preserves primary failures if cleanup also fails.
Offline fake-registry tests cover stale/current paths and invalid registrations. The
manual workflow was repeated for this repair and [passed on both
architectures](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35561825143).
[Selected final log lines](installer-e2e-final.log) capture the test and lifecycle results.
Final CI run links/results are recorded in [PR #9](https://github.com/hinneslung/CodexBar-for-Windows/pull/9).
