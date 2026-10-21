# CodexBar for Windows v0.78.0-windows.1

Windows-fork update, based on upstream CodexBar v0.78.0 (previously v0.56.8).

- The bundled Linux CLI moves from upstream v0.56.8 to v0.78.0. Upstream changes since then include:
  - Claude: Automatic tries your OAuth sign-in before the interactive Claude CLI, and the CLI fallback is more
    reliable.
  - OpenRouter: pay-as-you-go spend, and balances that survive a failed or slow request.
  - OpenCode Go: quota and prepaid balance for workspaces migrated to the OpenCode Console.
  - Security: the CLI no longer runs programs from the current directory or relative PATH entries, Claude usage
    probes no longer run your Claude hooks, and diagnostics redact environment values.
- Windows now show each provider's own names from upstream, such as "5-hour" for OpenCode Go or "Premium" for
  Copilot, instead of generic Session, Weekly, and Monthly labels.
- Gemini keeps working in Automatic mode. The new CLI refuses Gemini's plain Automatic route on Linux, so CodexBar
  now uses Gemini's API source, which is the same CLI sign-in.
- OpenCode and OpenCode Go browser sessions accept the OpenCode Console cookie (`__Host-console_session`).
- Crof is marked as removed: upstream dropped it after the service shut down. Existing Crof profiles are disabled
  and no longer refreshed.
- The packages include the bundled CLI's third-party notices.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.1-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.1-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.1/docs/windows.md).

The matching Linux CLI and runtime libraries are bundled. No separate CLI installation is needed.
Upgrades preserve your profiles, application settings, and saved credentials.

## Limitations

- Downloads are unsigned. Windows may display an unknown-publisher or reputation warning.
  SHA-256 checksum files accompany the downloads.
- Provider support varies; some upstream integrations remain unavailable on Windows. Providers added upstream
  since v0.56.8 are not yet exposed in the Windows app. Browser sessions can expire and require a fresh capture.
  A displayed credential method is not proof that an account is connected.
- Offline UI and native installer tests do not verify live authentication for every provider.
- With a one-minute refresh interval, a refresh that takes longer than a minute can keep restarting
  without showing new data. The default five-minute interval is unaffected.
- This is the Windows fork, not an upstream macOS release. It does not update Sparkle or Homebrew.

## Validation

Windows x64 and ARM64 passed native tests, packaging and installer checks in CI, along with upstream's macOS
test suite. A release-candidate package was smoke-tested on a real WSL Ubuntu setup: all seven enabled
providers loaded, Claude reported `Ubuntu · OAuth`, upstream window names appeared, and a manual refresh
finished in about 20 seconds. Before the update, upstream's published v0.78.0 Linux CLI produced identical
Windows usage readings to v0.56.8 for those providers.

Implemented in [PR #13](https://github.com/hinneslung/CodexBar-for-Windows/pull/13).
Published assets appear as the release workflow jobs complete.
