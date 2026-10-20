# CodexBar for Windows v0.56.8-windows.6

Windows-fork update, based on upstream CodexBar v0.56.8.

- Claude usage in Automatic mode now loads from your Claude OAuth sign-in first, in seconds instead of 24–49s.
  This fixes the intermittent "Automatic took too long to respond" error. When OAuth is unavailable, CodexBar
  falls back once to the interactive Claude CLI as before. Claude's details show which source supplied the data,
  such as `Ubuntu · OAuth`.
- A cancelled refresh no longer starts further provider CLI processes.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.56.8-windows.6-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.56.8-windows.6-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.56.8-windows.6/docs/windows.md).

The matching Linux CLI and runtime libraries are bundled. No separate CLI installation is needed.
Upgrades preserve your profiles, application settings, and saved credentials.

## Limitations

- Downloads are unsigned. Windows may display an unknown-publisher or reputation warning.
  SHA-256 checksum files accompany the downloads.
- Provider support varies; some upstream integrations remain unavailable on Windows. Browser
  sessions can expire and require a fresh capture. A displayed credential method is not proof that
  an account is connected.
- Offline UI and native installer tests do not verify live authentication for every provider.
- With a one-minute refresh interval, a refresh that takes longer than a minute can keep restarting
  without showing new data. The default five-minute interval is unaffected.
- This is the Windows fork, not an upstream macOS release. It does not update Sparkle or Homebrew.

## Validation

Windows x64 and ARM64 passed native tests in CI. A release build was smoke-tested on a real WSL Ubuntu
setup: all seven enabled providers loaded within about 12 seconds, Claude reported `Ubuntu · OAuth`,
and a manual refresh finished in under 10 seconds.

Implemented in [PR #11](https://github.com/hinneslung/CodexBar-for-Windows/pull/11).
Published assets appear as the release workflow jobs complete.
