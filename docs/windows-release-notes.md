# CodexBar for Windows v0.56.8-windows.5

Windows-fork update, based on upstream CodexBar v0.56.8.

- Each Codex account's overview now shows its available usage resets and nearest expiry,
  such as `1 reset (5d)`, `2 resets (2h)`, or `1 reset (20m)`.
- The plan, reset count, and credit balance use the space left beside the scheduled quota reset.
  The reported `prolite • 1 reset (13d) • 0 credits left` summary now fits without widening the popup.
- Unavailable, expired, or malformed reset inventory stays hidden and does not interrupt ordinary usage.
- Release artifacts include Windows x64/ARM64 installers and portable ZIPs with Linux CLI backends.
  This Windows fork no longer publishes macOS CLI packages.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.56.8-windows.5-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.56.8-windows.5-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.56.8-windows.5/docs/windows.md).

The matching Linux CLI and runtime libraries are bundled. No separate CLI installation is needed.
Upgrades preserve your profiles, application settings, and saved credentials.

## Limitations

- Downloads are unsigned. Windows may display an unknown-publisher or reputation warning.
  SHA-256 checksum files accompany the downloads.
- Provider support varies; some upstream integrations remain unavailable on Windows. Browser
  sessions can expire and require a fresh capture. A displayed credential method is not proof that
  an account is connected.
- Offline UI and native installer tests do not verify live authentication for every provider.
- This is the Windows fork, not an upstream macOS release. It does not update Sparkle or Homebrew.

## Validation

Windows x64 and ARM64 passed native tests, packaged startup, and installer lifecycle preflight.
The reset labels and navigation were visually verified with synthetic account data on the Windows VM.
Live account inventories were not queried. The installer test harness also now handles Inno choosing
`unins001.exe` after a reinstall, keeping the release checks reliable.

Implemented in [PR #9](https://github.com/hinneslung/CodexBar-for-Windows/pull/9).
Published assets appear as the release workflow jobs complete.
