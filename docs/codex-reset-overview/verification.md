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

CI will provide clean-checkout lint and native architecture coverage. No live provider,
browser-cookie, or Keychain probes were used.

Initial CI SwiftLint found three `empty_count` violations; all were changed to
`!availableExpiries.isEmpty`, and all 190 native tests passed again. The local pinned
SwiftLint binary could be installed but cannot run in WSL without Linux SourceKit;
the CI runner supplies that toolchain. See [initial diagnostics](ci-lint-initial.log)
and [local tool limitation](swiftlint.log).

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

The original installed CodexBar process was left untouched. CUA could not terminate
the fixture process through `kill_app` (runtime ownership refusal), and desktop capture
for reaching the tray Quit menu failed with an invalid handle. Cleanup remains pending;
the fixture processes only use synthetic data and temporary settings.

## Browser smoke and delivery

agent-browser opened the repository successfully and captured
[the repository snapshot](browser-repository-snapshot.log).
- [PR #9](https://github.com/hinneslung/CodexBar-for-Windows/pull/9): agent-browser
  verified the page URL/title and captured [its snapshot](browser-pr-snapshot.log)
  and [screenshot](../screenshots/codex-reset-overview-pr.png).
- [Initial CI](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35558929650).
- [Manual installer-e2e run](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35558929791),
  dispatched on the feature branch with a QA artifact version, without release publication.
