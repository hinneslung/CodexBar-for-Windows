# CodexBar for Windows v0.78.0-windows.11

Windows-fork update, still based on upstream CodexBar v0.78.0. The bundled CLI is unchanged.

- The overview now lists each profile's usage numbers, one per line with its reset time (**Detailed**, the new
  default). The button next to the pin switches to **Compact**, which shows only the lowest number left for each
  profile, as earlier versions did.
- Each profile's settings have **Overview numbers**: untick numbers you don't want in the overview, then click Apply.
  Compact and the tray tooltip pick the lowest of the ticked numbers. The detail view always shows every number. The
  list appears after the profile's first successful refresh and is remembered after that.
- The overview grows up to the height of the screen before it scrolls. Other pages keep their size.
- Reset times are a little brighter.

Earlier versions do not know the overview style and Overview numbers settings and drop them if they save the
configuration. If you run an older build again, set them again after upgrading.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.11-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.11-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.11/docs/windows.md).

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
test suite. On a Windows test VM, the Detailed/Compact button switched styles and saved the choice, and the Overview
numbers checklist listed a profile's numbers before its first refresh, kept the last ticked number locked, and saved
the selection for that profile only. The release-candidate installer was checked with real usage on a WSL Ubuntu
setup.

Implemented in [PR #35](https://github.com/hinneslung/CodexBar-for-Windows/pull/35).
Published assets appear as the release workflow jobs complete.
