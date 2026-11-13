# CodexBar for Windows v0.78.0-windows.8

Windows-fork update, still based on upstream CodexBar v0.78.0. The bundled CLI is unchanged.

- Antigravity lists each quota once. The **Gemini Models** and **Claude and GPT** rows, which only repeated the
  most-used limit in each group, are gone; the detail view shows each 5-hour and weekly limit on its own row.
- The separate Gemini 4 Argon weekly limit is now labeled **Gemini Argon weekly** instead of appearing as a second
  **Gemini weekly** row with a different value.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.8-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.8-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.8/docs/windows.md).

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
test suite. The change was smoke-tested on a real WSL Ubuntu setup with `agy` 1.5.8: the Antigravity detail view
listed Gemini 5-hour, Gemini weekly, Gemini Argon weekly, Claude/GPT 5-hour and Claude/GPT weekly, and the Argon
row matched the `gemini-argon-wtu-weekly` bucket reported by `agy -p /usage --output-format json`. The
release-candidate installer was also installed and checked on that setup.

Implemented in [PR #28](https://github.com/hinneslung/CodexBar-for-Windows/pull/28).
Published assets appear as the release workflow jobs complete.
