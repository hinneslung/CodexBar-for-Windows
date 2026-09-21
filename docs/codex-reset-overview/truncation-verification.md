# Truncation fix verification

Source of truth: [original plan](plan.md) plus the [user correction](truncation-fix.md).
Independent [review](review-truncation.md) found no blockers; PIC agrees after source
inspection and native verification. Production diff: one file, +17/-1.

## Local checks

- Pinned SwiftFormat: passed for the changed Swift source and fixture
  ([log](truncation-format.log)).
- `swift test --no-parallel -Xswiftc -warnings-as-errors`: 190 tests in 25 suites
  passed; native compilation succeeded ([log](truncation-tests.log)).
- `pwsh -NoProfile -File docs/codex-reset-overview/build-smoke.ps1`: passed
  ([log](truncation-smoke-build.log)). The fixture uses actual production drawing and
  decoder code with synthetic account data and no credential vault.
- `git diff --check`: passed. Repeated `make check`/`make test` both stop at CRLF
  shell shebangs in this Windows checkout ([check](truncation-make-check.log),
  [test](truncation-make-test.log)); clean-checkout CI is the substitute.

## VM native QA

SSH target `hinne@192.168.1.150`, hostname `g4-vmware-win11`, interactive Session 1,
CUA 0.28.1, 100% scaling, native 360-pixel overview width. All launch, capture, and
input used CUA over SSH. No GUI operations ran on the local desktop.

Fresh fixture SHA256:
`C1D05F898EFF89D5E534585F4B655C2436BC3F3282201341D479A52A531FF463`.
Executable, 32 runtime DLLs, and resource bundle were transferred to the VM's
`%TEMP%/CodexBar/qa/reset-overview` directory. An initial launch without the resource
bundle trapped; copying that required bundle fixed startup. The QA build helper now
copies it automatically. No production change was needed for this fixture issue.

| Check | Result | Evidence |
| --- | --- | --- |
| Reported summary | Full `prolite • 1 reset (13d) • 0 credits left` alongside `3h 29m` | [Screenshot](../screenshots/codex-reset-overview-vm-truncation.png), [state](vm-truncation-overview.json) |
| Longer scheduled reset | Full `Business • 2 resets (13d) • 0 credits left` alongside `Sat 14:59`; no overlap | Same overview screenshot |
| Other provider | Claude control remains reset-credit-free | Same overview screenshot |
| Navigation | Work opens its detail screen; Back restores full overview labels | [Detail](../screenshots/codex-reset-overview-vm-detail.png), [detail state](vm-truncation-detail.json), [Back state](vm-truncation-back.json) |

The custom-drawn window exposes no actionable UIA elements, so verified native pixels
were used. Background row/Back input worked. Taskbar/menu input sometimes returned
foreground errors despite visible transitions; screenshots determined the outcome.
Normal Quit did not terminate the fixture. CUA `kill_app` then refused ownership,
and the user was asked to quit the temporary fixture. [Cleanup log](vm-truncation-cleanup.log).

## Delivery

[PR #9](https://github.com/hinneslung/CodexBar-for-Windows/pull/9) remains the delivery
record. CI and a fresh manual packaging/installer lifecycle run are required before
the updated x64 installer is handed over. Their final URLs/results will be added to
the PR without changing the validated source commit. No merge or public release.
