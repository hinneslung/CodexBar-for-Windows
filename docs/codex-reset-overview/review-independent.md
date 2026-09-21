# Independent review: Codex reset overview

Reviewer: independent Fattie profile, reporting to Pillow PIC

Source of truth: `docs/codex-reset-overview/plan.md`

Reviewed implementation: `c03ebd60a` against `fork/windows-native-app`

Scope: the three changed production files and four changed `TestsWindows` files requested by the PIC

## Verdict

No correctness blockers found.

The implementation satisfies the plan's core behavior: it decodes the optional CLI inventory fail-soft, derives inventory from entries rather than the server count, retains only exact `available` statuses, re-filters expiries against a shared row-level `now`, treats exact expiry as unavailable, formats positive subsecond intervals as `<1m`, preserves raw expiries through snapshot copies/cache paths, gates display to available Codex rows, and places the label between plan and balance. Provider and profile isolation are preserved.

I did not run builds, tests, formatters, GUI automation, or real-account probes. Per the handoff, 190 native tests and the warnings-as-errors build passed, formatter output was clean, and the current CI lint failure is the separately tracked set of three `empty_count` violations. The implementing agent's in-progress replacement of those checks with `!availableExpiries.isEmpty` is already owned and is not an independent finding here.

## Blockers

None.

Evidence reviewed against the plan:

- Criteria 1, 2, and 4: `WindowsCanonicalCLIProviderClient.decode` projects `usage.codexResetCredits.credits`, ignores `availableCount`, keeps only `status == "available"`, and contains any optional inventory decoding failure inside `Usage.init` without invalidating normal usage.
- Criteria 2 and 3: `WindowsCodexResetCredits.available(at:)` uses strict `expiry > now`; `compactText(now:)` uses the same `now` after filtering and selects the minimum non-null expiry. `WindowsResetLabelFormatter.compact` handles positive intervals below one minute, including subsecond values, as `<1m` and floors minute/hour/day buckets.
- Criteria 3, 4, and 5: `WindowsDashboardPresentation.makeRow` requires both profile and snapshot provider to be Codex plus `.available` availability, removes expired entries at presentation construction, and suppresses empty inventory. The overview context is ordered plan, reset label, balance; accessibility text names available usage resets and nearest expiry.
- Criteria 5 and 6: `assigningProfile`, `replacingSource`, `requiringPublicationAuthority`, refresh overlays, and stale-success retention propagate the inventory. Existing profile-ID keyed publication/cache behavior is unchanged, and there is no new poller, setting, dependency, migration, or action.
- UI fit: the supplied native fixture screenshots show singular/plural labels, day/hour/minute and no-expiry forms, two named Codex profiles, no reset label on Claude, retained scheduled quota-reset text at right, and normal provider-detail navigation. These are fixture smoke evidence, not live-account evidence.

## Optional findings

### Low: unit tests do not directly lock the required plan-reset-balance ordering

Evidence: production constructs the secondary context as `[plan, codexResetCreditsText, balance]`, so the implementation is currently correct. However, the new presentation assertions build rows without a usage window and balance, and therefore expect only `"Pro  •  1 reset ..."`. The ordering with a credit balance is demonstrated by fixture screenshots but is not protected by a focused source test.

Plan criterion: acceptance criteria 3 and 7 (reset text after plan and before credit balance; decoder-to-presentation verification).

Suggested follow-up: add one presentation case with a governing usage window and `balanceText`, asserting the complete value such as `Pro  •  1 reset (5d)  •  10 credits left`. This is test hardening, not a release blocker.

## Additional review notes

- The conservative all-or-nothing handling of a malformed reset inventory is consistent with the requirement to hide unknown/malformed inventory while preserving ordinary usage.
- The model additions are bounded and reuse `WindowsResetLabelFormatter.compact`; no upstream CLI/Core change is introduced.
- The longer Business fixture line ellipsizes the trailing balance while keeping the new reset count/expiry visible. That is consistent with the existing compact single-line layout and does not obscure the feature's primary information.

## Final installer harness repair review

Verdict: no blocker.

The repair directly addresses the observed x64 failure where a later setup registered `unins001.exe` while stale `unins000.exe` remained during asynchronous self-deletion. `Resolve-RegisteredUninstaller` reads the current per-user uninstall registration for every uninstall attempt, accepts only one fully quoted executable path with no command suffix, disposes the registry key in `finally`, canonicalizes the path, requires its parent to equal the synthetic install directory, restricts the basename to `unins[0-9]+.exe`, and requires an existing leaf. The running-app guard, ordinary uninstall path, and final cleanup all use fresh resolution.

Cleanup retains responsibility after partial setup or failed uninstall. If cleanup also fails, it records separate cleanup evidence without replacing an active primary error; a standalone cleanup failure still fails the lifecycle test. The offline AST test covers stale `unins000` beside registered `unins001`, registration changes, unsafe/malformed/missing registrations, missing leaves, and the prior cleanup-state transitions. The diagnostics test adds only the resolver stub required by its extracted-function harness. Pillow reports both offline PowerShell 7 scripts passed; this reviewer did not rerun them.

Scope is appropriately bounded to the three installer test scripts. No production or workflow change is justified, preserving the original plan's minimal-change constraint.
