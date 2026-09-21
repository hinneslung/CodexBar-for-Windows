# Codex reset count and expiry in Windows overview

Status: approved for implementation by the user on 2026-09-21.
PIC: Pillow. This original plan is the source of truth for implementation and review.

## User outcome

Each Codex account's Windows overview row shows remaining manual usage resets and
the nearest expiry relative to now, for example `Pro • 1 reset (5d)`.
The user's work and personal accounts each reportedly have one reset; that is
context, not a hardcoded fixture or a claim of independently verified account state.

## Acceptance criteria

1. Read the existing CLI JSON `usage.codexResetCredits`; use the existing fetch flow.
2. Count only credits with status `available` and no expiry or an expiry after now.
   Recalculate from retained expiry dates when presenting, using one `now` for
   count and nearest expiry. Never use the server count in place of valid entries.
3. Show `1 reset (5d)` / `2 resets (2h)` after the plan and before credit balance in
   the existing secondary overview line. Parentheses mean the earliest remaining
   expiry when several credits are available. Use whole days, hours, then minutes,
   rounded down; a positive interval under one minute is `<1m`.
4. Omit parentheses if none of the available credits has an expiry. Hide the reset
   label for zero, unknown/malformed inventory, errors, or non-Codex providers.
   Optional malformed reset data must not invalidate ordinary usage.
5. Retain expiry dates in per-profile snapshots and copy helpers, including cached
   snapshots. Counts must not leak between accounts or providers. Accessibility
   text describes available usage resets and the nearest expiry.
6. Preserve the compact overview row, its existing usage metric, and scheduled
   quota-reset timestamp. Reuse `WindowsResetLabelFormatter.compact` where possible.
   Use existing repaint/refresh behavior; no new poller, settings, dependency,
   redemption action, upstream provider changes, or configuration migration.
7. Verify decoder-to-presentation behavior with offline fixtures, expiry boundaries,
   missing/malformed data, multiple/no expiries, and independent Codex profiles.
   Verify the freshly built native UI with CUA and save evidence. No live provider
   probes or credential reads are required or implied by the GUI smoke request.

## Intended change map and estimate

| Existing file | Responsibility | Estimated added lines |
| --- | --- | ---: |
| `Sources/CodexBarWindows/WindowsCanonicalCLIProviderClient.swift` | Optional inventory decode and projection | 50–60 |
| `Sources/CodexBarWindows/WindowsProviderModels.swift` | Small typed inventory, snapshot propagation, count/expiry presentation | 60–80 |
| `Sources/CodexBarWindows/WindowsTrayApplication.swift` | Cached snapshot propagation | 1 |
| `TestsWindows/WindowsCanonicalCLIProviderClientTests.swift` | Decoder fixtures and fail-soft coverage | 70–90 |
| `TestsWindows/WindowsTrayPresentationTests.swift` | Countdown, count, visibility, accessibility | 60–80 |
| `TestsWindows/WindowsNamedProviderProfileTests.swift` | Profile isolation | 10–20 |
| `TestsWindows/WindowsProviderSourcePresentationTests.swift` | Cached copy preservation | 5–10 |

Approximately 260–340 added lines including tests, excluding epic evidence.
These are estimates, not quotas; document justified deviations in the scratchpad.

## Validation and delivery

- Focused offline Swift tests, then native Windows full suite and warnings-as-errors build.
- Run `make check` and `make test`; record actual platform/tool limitations and CI substitutes.
- One independent reviewer for this bounded change; add a second if risk or findings warrant it.
- CUA native smoke of the fresh app, including screenshots of count/expiry text and normal navigation.
- Use agent-browser for browser-based PR/CI smoke if available; CUA is explicitly authorized
  for the native app. Browser checks are not a substitute for native feature verification.
- Branch `windows/codex-reset-overview`, PR into `fork/windows-native-app`.
- Monitor relevant CI and run applicable manual e2e/packaging workflow without publishing.
- Record command results, reviewer decisions, PR/run URLs, and limitations under this directory;
  screenshots under `docs/screenshots`.
