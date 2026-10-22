# CodexBar for Windows v0.78.0-windows.4

Windows-fork update, still based on upstream CodexBar v0.78.0. It adds the remaining providers the bundled v0.78.0
Linux CLI can run on Windows. The bundled CLI is unchanged.

- Providers that take a key plus a workspace or address:
  - Exa: a Team Management **Service key** and the **API key ID** to report on.
  - FLORA: an API key and its **Workspace ID** (`ws_…`).
  - Cosmic AI: a **Personal access token** and **Project ID**.
  - GitKraken AI: an **API token** and an optional **Organization ID**.
  - Bifrost: a **Virtual key** and your gateway's **Base URL**.
  - Aixy: an API key and an optional **Base URL** for a self-hosted gateway.
  - Charm Hyper: an API key, or a browser session from hyper.charm.land.
- Providers that use a browser session: Claude Platform, Replicate, Raycast, TypeSafe, Parallel, X API, LithosAI,
  TinyApi, and Muse (muse.ai). Copy the session cookie as described in each provider's settings.
- Providers that use their own sign-in inside WSL: CodeRabbit (the `coderabbit` CLI), Nous Portal (Hermes Agent),
  and Muse Code. Sign in with the provider's own tool in your WSL distribution, then enable the provider.
- Helmcode, Langdock, and WorkBuddy are listed as unavailable. Their integrations rely on browser access the Linux
  CLI does not have.

New providers start disabled at the end of Settings' disabled list; the search box finds them by name.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.4-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.4-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.4/docs/windows.md).

The matching Linux CLI and runtime libraries are bundled. No separate CLI installation is needed.
Upgrades preserve your profiles, application settings, and saved credentials.

## Limitations

- Downloads are unsigned. Windows may display an unknown-publisher or reputation warning.
  SHA-256 checksum files accompany the downloads.
- Provider support varies; some upstream integrations remain unavailable on Windows. FutureAGI, Pi, and llmman are
  not yet exposed. Browser sessions can expire and require a fresh capture. A displayed credential method is not
  proof that an account is connected.
- Offline UI and native installer tests do not verify live authentication for every provider. The new providers
  were checked against the bundled CLI's sources, not against live accounts. For TypeSafe, Parallel, and muse.ai,
  upstream names no required cookie, so CodexBar accepts any cookie from that site.
- With a one-minute refresh interval, a refresh that takes longer than a minute can keep restarting
  without showing new data. The default five-minute interval is unaffected.
- This is the Windows fork, not an upstream macOS release. It does not update Sparkle or Homebrew.

## Validation

Windows x64 and ARM64 passed native tests, packaging and installer checks in CI, along with upstream's macOS
test suite. A release-candidate package was smoke-tested on a real WSL Ubuntu setup: all seven enabled
providers loaded, and Settings showed X API's browser session, Bifrost's virtual key and base URL, CodeRabbit's
provider sign-in, and WorkBuddy as unavailable.

Implemented in [PR #20](https://github.com/hinneslung/CodexBar-for-Windows/pull/20).
Published assets appear as the release workflow jobs complete.
