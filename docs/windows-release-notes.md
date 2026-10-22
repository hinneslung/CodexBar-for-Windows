# CodexBar for Windows v0.78.0-windows.2

Windows-fork update, still based on upstream CodexBar v0.78.0. It exposes more of what the bundled v0.78.0 Linux
CLI already supports for existing providers. The bundled CLI is unchanged.

- Claude: new **Browser session** option, using the `sessionKey` cookie from claude.ai.
- Devin is now available, with a **Bearer token** and **Organization** captured from a Devin request.
- Kimi: new **Browser session** option, accepting the `kimi-auth` cookie or its bare token, and an optional region
  (`china` by default, or `international` for kimi.ai accounts).
- Mistral browser sessions need only the `ory_session_*` cookie; `csrftoken` is no longer required.
- Command Code can use a saved **API key**.
- Azure OpenAI accepts an optional **API version**; `v1` selects the OpenAI-compatible endpoint.
- Notion accepts an optional **Workspace ID**.
- z.ai: OpenCode BigModel keys (`zhipuai`) now work. Before, the CLI ignored them because it never received the
  BigModel region. Saved z.ai keys can also choose a region.
- Providers that report only a balance, such as Grok's purchased credits, now show it as a remaining balance.
- In Automatic mode, Cursor uses its `cursor-agent` sign-in in WSL, and ClinePass uses Cline's own sign-in state.
- Zed and Abacus AI remain unavailable; their explanations now say that the Linux CLI rejects their browser
  routes.

## Download and install

- Intel/AMD Windows: `CodexBar-v0.78.0-windows.2-windows-x86_64-setup.exe`.
- Windows on ARM: `CodexBar-v0.78.0-windows.2-windows-arm64-setup.exe`.
- Portable packages use the same names without `-setup.exe`, ending in `.zip` instead.

Requires Windows 10/11 and WSL2 with a configured distribution and non-root default user.
Install the EXE and open CodexBar from the Start menu, or extract the entire portable ZIP and run
`CodexBar.exe`. Enable and configure providers in Settings. See the
[Windows guide](https://github.com/hinneslung/CodexBar-for-Windows/blob/v0.78.0-windows.2/docs/windows.md).

The matching Linux CLI and runtime libraries are bundled. No separate CLI installation is needed.
Upgrades preserve your profiles, application settings, and saved credentials.

## Limitations

- Downloads are unsigned. Windows may display an unknown-publisher or reputation warning.
  SHA-256 checksum files accompany the downloads.
- Provider support varies; some upstream integrations remain unavailable on Windows. Providers added upstream
  since v0.56.8 are not yet exposed in the Windows app. Browser sessions can expire and require a fresh capture.
  A displayed credential method is not proof that an account is connected.
- Offline UI and native installer tests do not verify live authentication for every provider. The new credential
  options were checked against the bundled CLI's source and tests, not against live accounts.
- With a one-minute refresh interval, a refresh that takes longer than a minute can keep restarting
  without showing new data. The default five-minute interval is unaffected.
- This is the Windows fork, not an upstream macOS release. It does not update Sparkle or Homebrew.

## Validation

Windows x64 and ARM64 passed native tests, packaging and installer checks in CI, along with upstream's macOS
test suite. A release-candidate package was smoke-tested on a real WSL Ubuntu setup: all seven enabled
providers loaded, and Settings showed the new Claude, Kimi, and Mistral browser sessions, Devin's bearer token
and organization, Kimi's region, and Azure OpenAI's API version.

Implemented in [PR #16](https://github.com/hinneslung/CodexBar-for-Windows/pull/16).
Published assets appear as the release workflow jobs complete.
