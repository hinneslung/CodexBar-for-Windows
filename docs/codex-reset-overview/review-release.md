# Independent release-readiness review

Source of truth: `docs/codex-reset-overview/plan.md` and `docs/codex-reset-overview/truncation-fix.md`.

Reviewed range: `v0.56.8-windows.4...4096daa82` (merged PR #9).

## Verdict

No code or release-note blocker found. One required pre-publication check remains in progress: visually checking the actual packaged app on the Windows VM. The completed synthetic fixture visual check and CI packaged-startup checks do not establish that result. Publish `v0.56.8-windows.5` only after the packaged-app visual check passes.

## Evidence and scope

- PR #9 was merged as `4096daa82`. Its tree is identical to tested PR head `361c03888`; the merge changed commit identity but not content. CI run `35571292227` is successful across lint, Windows x64/ARM64, Linux, both macOS compatibility shards, and the aggregate gate.
- Manual release-artifact run `35571300151` is successful for both Windows architectures and produced the expected workflow artifacts. It passed CI packaged startup and installer lifecycle checks. Separately, the 100%-scaling CUA visual check passed for the synthetic fixture. The actual portable artifact VM smoke has not yet passed and is being performed by the PIC.
- The production feature remains bounded to Codex reset-inventory decoding/presentation, snapshot propagation, and the localized overview allocation correction. The latter preserves popup width, row height, scheduled-reset rendering, and fallback allocation.
- The installer change is test-harness-only: it resolves the currently registered Inno uninstaller instead of assuming `unins000.exe`. It does not change installer payload or runtime behavior.
- The only other release-range behavior is PR #8's release-workflow cleanup: this Windows fork no longer produces macOS CLI archives. Linux backends and Windows x64/ARM64 packaging remain in the workflow, and macOS compatibility tests remain in CI.
- `Sources/CodexBarCLI` and `Sources/CodexBarCore` have no diff from `v0.56.8-windows.4`. The feature consumes the existing CLI JSON contract; it does not modify upstream provider or CLI behavior.
- `v0.56.8-windows.5` is the next unused fork tag after the published `.windows.4` release. `git diff --check` for the merged release range reported no error.
- The draft `CHANGELOG.md` entry and `docs/windows-release-notes.md` are accurate at review time: they claim native tests, CI packaged startup/installer preflight, and synthetic VM visual validation, while explicitly stating that live account inventories were not queried. They do not claim completion of the pending real portable-artifact VM smoke.

## Source-required checks and reviewer recommendations

`docs/windows-fork.md` requires green CI before merge and, before publishing, passing installer tests on both architectures plus a visual check of the packaged app. The architecture installer checks are complete; the packaged-app visual check is the sole outstanding source-required gate.

The following are reviewer recommendations for release confidence and identity control; they are not quoted as additional mandatory rules from `docs/windows-fork.md`:

1. Confirm post-merge target-branch CI succeeds. The merged tree already matches the tested PR tree, so this is additional branch-state assurance rather than evidence of a code delta.
2. After the packaged portable-app VM smoke passes, tag the exact verified `windows-native-app` commit as `v0.56.8-windows.5`; do not move an existing tag.
3. Publish the release for that tag so the release-event workflow uploads the x64/ARM64 installers, portable ZIPs, checksums, and required Linux backends.
4. Verify final published artifact names and checksums. Any post-publication installer smoke is an additional reviewer recommendation, not a substitute for the required pre-publication packaged-app visual check.

## Release-note recommendation

Keep the notes user-facing and include:

- Codex overview rows now show the count of available manual usage resets and nearest expiry per account.
- The compact overview now gives unused scheduled-reset space to the plan/reset/balance summary, fixing the reported trailing balance truncation while retaining the scheduled quota-reset timestamp.
- Installer lifecycle verification now follows Inno Setup's currently registered uninstaller during reinstall/upgrade tests; describe this as test reliability, not an installer behavior change.
- The Windows fork's release workflow no longer publishes macOS CLI archives; macOS compatibility testing remains. There is no Core/CLI behavior change in this release.
- Downloads are unsigned and may trigger an unknown-publisher warning. Windows 10/11 with WSL2 and a configured non-root distribution is required for provider usage; link the Windows setup and download-verification guide.
- State that reset behavior was verified with offline synthetic fixtures and native VM pixels. Do not claim that either reported user account, live authentication, or live reset inventory was independently queried or verified.

No source, tests, branch, PR, tag, release, build, GUI, or remote environment was mutated by this review. Only this review report was updated.
