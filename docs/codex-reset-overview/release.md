# Windows release record

User authorization: merge and release, 2026-09-21. Target version:
`v0.56.8-windows.5`, following the published `.windows.4` release.

## Validated source

- [PR #9](https://github.com/hinneslung/CodexBar-for-Windows/pull/9) was squash-merged
  into `windows-native-app` as `4096daa8282ee29154d7f75282524b20226c45b8`.
- Its tested head was `361c03888bd75082d094fbbef9b20caa1dd5f595`.
  `git diff --exit-code 361c03888 4096daa82 -- Sources TestsWindows TestsLinux Scripts .github`
  returned 0: merging did not alter production, tests, packaging, or workflows.
- [Full CI](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35571292227)
  passed all Windows, Linux, macOS, lint, and aggregate checks.
- [Manual packaging](https://github.com/hinneslung/CodexBar-for-Windows/actions/runs/35571300151)
  passed startup and installer lifecycle tests on both Windows architectures.
- [Independent release review](review-release.md) found no code blocker. PIC accepts
  its source checklist and release-note boundaries. Reviewer recommendations are
  distinguished from the repository's explicit release requirements.

## Packaged x64 VM smoke

The actual portable artifact from the successful manual run was downloaded, checked
against its SHA256 sidecar, and transferred to `hinne@192.168.1.150`.

```text
Archive: CodexBar-v0.56.8-reset-overview-fix-qa-windows-x86_64.zip
SHA256: 68B7E42FED10896894507B403676693665844B73A19CE93E485452F0F866410E
Extracted CodexBar.exe SHA256:
80FB5F492C347474324417188E0EF1AF4395AB98DA11FF8E466006FC79CB98EE
CUA launch: PID 4676, running=true, interactive VM session
Native popup: HWND 2621492, width=360
Settings: rendered; no providers enabled
Back: returned to overview
```

CUA launched the unmodified packaged executable and drove Settings/Back. Its resources,
provider logos, fonts, and native controls rendered correctly. [Overview screenshot](../screenshots/codex-reset-overview-packaged-vm.png)
and [Settings screenshot](../screenshots/codex-reset-overview-packaged-settings-vm.png).
The empty overview is expected with all providers disabled. The separate
[fixture verification](truncation-verification.md) proves populated reset labels.
No live accounts were queried.

The VM had no existing CodexBar configuration or running app. QA created a configuration
with no providers enabled and startup disabled. The packaged QA app remains available
on that VM. The user closed the earlier fixture; SSH confirmed PID 2160 was absent.
The local desktop was untouched.

## Publication

The release preparation changes only documentation and screenshots. It records the
dated changelog and current Windows release notes without changing upstream macOS
version metadata. Publish the next unused immutable tag from the merged default branch
through the existing release-event workflow. That workflow reruns both native installer
tests and uploads the versioned assets; this fork does not dispatch Homebrew updates.

The [release page](https://github.com/hinneslung/CodexBar-for-Windows/releases/tag/v0.56.8-windows.5)
will carry final asset links and validation outcomes. PIC must verify workflow success,
asset completeness, tag/source identity, and published x64 checksum before handoff.
