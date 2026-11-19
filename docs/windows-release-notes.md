# CodexBar for Windows v0.78.0-windows.9

Windows-fork update, still based on upstream CodexBar v0.78.0. The bundled CLI is unchanged.

- Antigravity profiles can set an **Antigravity home** to track another Google account through Automatic, like
  **Codex home** and **Claude config folder**. In WSL, run `HOME=~/.antigravity-work agy` and sign in, then enter
  `~/.antigravity-work` in the profile. `agy` has no setting for its sign-in folder, so CodexBar runs it with that
  folder as its home, and finds `agy` with your real home first.

Earlier versions do not know the Antigravity home setting and drop it if they save the configuration. If you run an
older build again, re-enter the folder after upgrading.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.9-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.9-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.9/docs/windows.md).

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
test suite. The change was smoke-tested on a real WSL Ubuntu setup with `agy` 1.5.9: a second Antigravity profile
with its own home folder showed a different Google account's limits from the default profile, both through the
bundled CLI.

Implemented in [PR #30](https://github.com/hinneslung/CodexBar-for-Windows/pull/30).
Published assets appear as the release workflow jobs complete.
