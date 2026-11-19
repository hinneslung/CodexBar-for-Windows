# CodexBar for Windows v0.78.0-windows.10

Windows-fork update, still based on upstream CodexBar v0.78.0. The bundled CLI is unchanged.

- Reset times more than a day away now use your Windows time zone. In some time zones, such as Singapore Standard
  Time (UTC+8), CodexBar showed them in UTC, so a reset at 14:22 local time appeared as 06:22. Countdowns under a day
  were already correct.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.10-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.10-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.10/docs/windows.md).

The matching Linux CLI and runtime libraries are bundled. No separate CLI installation is needed.
Upgrades preserve your profiles, application settings, and saved credentials.

## Limitations

- Downloads are unsigned. Windows may display an unknown-publisher or reputation warning.
  SHA-256 checksum files accompany the downloads.
- Provider support varies; some upstream integrations remain unavailable on Windows. FutureAGI, Pi, and llmman are
  not yet exposed. Browser sessions can expire and require a fresh capture. A displayed credential method is not
  proof that an account is connected.
- Offline UI and native installer tests do not verify live authentication for every provider. Providers added in
  v0.78.0-windows.3 and .4 were checked against the bundled CLI's sources, not against live accounts. For TypeSafe,
  Parallel, and muse.ai, upstream names no required cookie, so CodexBar accepts any cookie from that site.
- This is the Windows fork, not an upstream macOS release. It does not update Sparkle or Homebrew.

## Validation

Windows x64 and ARM64 passed native tests, packaging and installer checks in CI, along with upstream's macOS
test suite. On a Windows setup in Singapore Standard Time, the app's time zone changed from GMT to Asia/Singapore,
and a reset at 06:22 UTC was labeled Thu 14:22.

Implemented in [PR #32](https://github.com/hinneslung/CodexBar-for-Windows/pull/32).
Published assets appear as the release workflow jobs complete.
