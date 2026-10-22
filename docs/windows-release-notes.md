# CodexBar for Windows v0.78.0-windows.3

Windows-fork update, still based on upstream CodexBar v0.78.0. It adds 13 providers that the bundled v0.78.0 Linux
CLI already supports with an API key, and shows each provider's extra usage details. The bundled CLI is unchanged.

- New providers: Hugging Face, v0, DevPass, Atlas Cloud, Vercel AI Gateway, xKiro, Tavily, Linkup, Aerostack,
  Sail Research, Sofya, fal, and Munito. Enable them in Settings and save their key; they are listed at the end of
  the disabled providers, and the search box finds them by name.
  - Hugging Face uses an access token. Automatic also uses a token saved by `hf auth login` in WSL.
  - v0 accepts an optional **Scope**, such as a project ID or slug.
  - Vercel AI Gateway accepts an **AI Gateway API key** for team credits, or an **Access token** and **Team ID** for
    your personal budget.
  - Munito needs an **Admin API key**, and Aerostack its **Account token**.
- Provider pages now show the extra details a provider reports, such as OpenRouter's credits and API key spend.
- Providers that report their balance only as a detail, such as Linkup, fal, or Sail Research, show it as the
  balance in the overview.
- Each provider's logo has a fixed position, so adding providers never changes another provider's logo.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.3-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.3-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.3/docs/windows.md).

The matching Linux CLI and runtime libraries are bundled. No separate CLI installation is needed.
Upgrades preserve your profiles, application settings, and saved credentials.

## Limitations

- Downloads are unsigned. Windows may display an unknown-publisher or reputation warning.
  SHA-256 checksum files accompany the downloads.
- Provider support varies; some upstream integrations remain unavailable on Windows. More providers added upstream
  since v0.56.8 are not yet exposed in the Windows app. Browser sessions can expire and require a fresh capture.
  A displayed credential method is not proof that an account is connected.
- Offline UI and native installer tests do not verify live authentication for every provider. The new providers
  were checked against the bundled CLI's plugin sources, not against live accounts.
- Hugging Face's prepaid credit balance needs a browser session, which the Linux CLI does not read.
- With a one-minute refresh interval, a refresh that takes longer than a minute can keep restarting
  without showing new data. The default five-minute interval is unaffected.
- This is the Windows fork, not an upstream macOS release. It does not update Sparkle or Homebrew.

## Validation

Windows x64 and ARM64 passed native tests, packaging and installer checks in CI, along with upstream's macOS
test suite. A release-candidate package was smoke-tested on a real WSL Ubuntu setup: all seven enabled
providers loaded, OpenRouter's page showed its credits, API key, and spend history details, and Settings listed
the new providers with their logos, including Vercel AI Gateway's AI Gateway key and access-token options.

Implemented in [PR #18](https://github.com/hinneslung/CodexBar-for-Windows/pull/18).
Published assets appear as the release workflow jobs complete.
