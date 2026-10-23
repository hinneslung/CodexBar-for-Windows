# CodexBar for Windows v0.78.0-windows.6

Windows-fork update, still based on upstream CodexBar v0.78.0. The bundled CLI is unchanged.

- CodexBar now tells you when a newer release is available. A download icon appears next to the pin at the bottom
  left of the overview; click it to open the release page. CodexBar does not download or install anything itself.
- To check, the app asks GitHub for the latest release a minute after it starts and then once a day. This is the
  only request the Windows app makes itself. Turn off **Check for updates** in Settings to stop it.
- Only published releases are offered, never test builds.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.6-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.6-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.6/docs/windows.md).

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
test suite. A release-candidate package was smoke-tested on a real WSL Ubuntu setup with its version set to
v0.78.0-windows.4: the update icon appeared after the first check, clicking it opened the v0.78.0-windows.5
release page, and turning off **Check for updates** saved the setting and hid the icon.

Implemented in [PR #24](https://github.com/hinneslung/CodexBar-for-Windows/pull/24).
Published assets appear as the release workflow jobs complete.
