#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

@Suite("Windows provider errors and sign-in folders")
struct WindowsProviderErrorAndSignInFolderTests {
    @Test
    func `provider errors become one capped line with credentials masked`() {
        #expect(WindowsProviderErrorText.displaySafe(nil) == nil)
        #expect(WindowsProviderErrorText.displaySafe("  \n ") == nil)
        #expect(
            WindowsProviderErrorText.displaySafe("Claude OAuth credentials not found.\n  Run `claude`.")
                == "Claude OAuth credentials not found. Run `claude`.")
        #expect(
            WindowsProviderErrorText.displaySafe("rejected key sk-ant-sid01-abcdefgh for org")
                == "rejected key [redacted] for org")
        #expect(
            WindowsProviderErrorText.displaySafe("header Authorization: Bearer abc.def-ghi was refused")
                == "header Authorization: Bearer [redacted] was refused")
        #expect(
            WindowsProviderErrorText.displaySafe("GET https://api.example.test/v1/usage?key=secret failed")
                == "GET https://api.example.test/v1/usage?[redacted] failed")
        #expect(
            WindowsProviderErrorText.displaySafe("token \(String(repeating: "a1", count: 20)) expired")
                == "token [redacted] expired")
        let long = WindowsProviderErrorText.displaySafe(String(repeating: "word ", count: 100))
        #expect(long?.count == WindowsProviderErrorText.maximumLength)
        #expect(long?.hasSuffix("…") == true)
    }

    @Test
    func `a provider error on a failing exit is shown and not retried`() async {
        let payload = #"""
        [{"provider":"claude","source":"web","error":{"code":1,"kind":"provider",
          "message":"claude.ai is behind a Cloudflare challenge. Switch Claude Usage source to OAuth."}}]
        """#
        let runner = ProcessRunnerSequence([
            WindowsHiddenProcessResult(standardOutput: Data(payload.utf8), standardError: Data(), exitCode: 1),
        ])
        let client = WindowsCanonicalCLIProviderClient(
            processRunner: { _, _, _, _, _, _ in try runner.next() },
            retryDelay: {})
        let invocation = WindowsCanonicalCLIInvocation.stagedWSL(
            distribution: "Ubuntu",
            launcherPath: "/opt/codexbar/CodexBarStagingLauncher",
            providerID: "claude",
            source: "web",
            config: Data("{}".utf8),
            credentialPath: "Browser session",
            windowsDirectory: "C:\\Windows")

        let snapshot = await client.fetch(provider: .claude, invocation: invocation)

        #expect(snapshot.availability == .error)
        #expect(
            snapshot.safeErrorText
                == "claude.ai is behind a Cloudflare challenge. Switch Claude Usage source to OAuth.")
        #expect(runner.callCount == 1)
    }

    @Test
    func `a failing exit without a provider error is still retried once`() async {
        let runner = ProcessRunnerSequence([
            WindowsHiddenProcessResult(standardOutput: Data("panic".utf8), standardError: Data(), exitCode: 1),
            WindowsHiddenProcessResult(standardOutput: Data(), standardError: Data(), exitCode: 1),
        ])
        let client = WindowsCanonicalCLIProviderClient(
            processRunner: { _, _, _, _, _, _ in try runner.next() },
            retryDelay: {})
        let invocation = WindowsCanonicalCLIInvocation.wsl(
            distribution: "Ubuntu",
            executablePath: "/opt/codexbar/CodexBarCLI",
            providerID: "claude",
            windowsDirectory: "C:\\Windows")

        let snapshot = await client.fetch(provider: .claude, invocation: invocation)

        #expect(snapshot.availability == .unavailable)
        #expect(snapshot.safeErrorText?.contains("exit code 1") == true)
        #expect(runner.callCount == 2)
    }

    @Test
    func `an error for another provider on a failing exit is not borrowed`() {
        let payload = #"[{"provider":"codex","error":{"message":"Codex failed"}}]"#
        #expect(
            WindowsCanonicalCLIProviderClient.decodeProviderError(
                data: Data(payload.utf8),
                requestedProvider: .claude,
                source: .compatibility("WSL CLI · Ubuntu")) == nil)
        #expect(
            WindowsCanonicalCLIProviderClient.decodeProviderError(
                data: Data(#"[{"provider":"claude","usage":{}}]"#.utf8),
                requestedProvider: .claude,
                source: .compatibility("WSL CLI · Ubuntu")) == nil)
    }

    @Test
    func `a successful run's provider error shows the CLI's message`() throws {
        let payload = #"""
        [{"provider":"claude","source":"oauth","error":{"message":"Claude OAuth credentials not found."}}]
        """#
        let snapshot = try WindowsCanonicalCLIProviderClient.decode(
            data: Data(payload.utf8),
            requestedProvider: .claude,
            sourceText: "WSL CLI · Ubuntu")
        #expect(snapshot.availability == .error)
        #expect(snapshot.safeErrorText == "Claude OAuth credentials not found.")

        let empty = try WindowsCanonicalCLIProviderClient.decode(
            data: Data(#"[{"provider":"claude","error":{"message":""}}]"#.utf8),
            requestedProvider: .claude,
            sourceText: "WSL CLI · Ubuntu")
        #expect(empty.safeErrorText == "Provider usage is unavailable.")
    }

    @Test
    func `only Codex and Claude profiles keep a sign-in folder`() throws {
        let claude = WindowsProviderConfiguration(
            id: .claude,
            enabled: true,
            order: 0,
            claudeConfigDirectory: " ~/.claude-work ")
        #expect(claude.claudeConfigDirectory == "~/.claude-work")
        #expect(claude.signInFolder == "~/.claude-work")
        #expect(
            WindowsProviderConfiguration(id: .codex, enabled: true, order: 0, claudeConfigDirectory: "~/x")
                .claudeConfigDirectory == nil)
        #expect(
            WindowsProviderConfiguration(id: .poe, enabled: true, order: 0, codexHome: "~/x").signInFolder == nil)

        var edited = claude
        edited.signInFolder = "  "
        #expect(edited.claudeConfigDirectory == nil)
        var codex = WindowsProviderConfiguration(id: .codex, enabled: true, order: 0)
        codex.signInFolder = "/home/me/.codex-work"
        #expect(codex.codexHome == "/home/me/.codex-work")

        let decoded = try JSONDecoder().decode(
            WindowsProviderConfiguration.self,
            from: JSONEncoder().encode(claude))
        #expect(decoded.claudeConfigDirectory == "~/.claude-work")
        let invalid = #"{"id":"claude","enabled":true,"order":0,"claudeConfigDirectory":"~/x; rm -rf /"}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(WindowsProviderConfiguration.self, from: Data(invalid.utf8))
        }
        let foreign = #"{"id":"poe","enabled":true,"order":0,"claudeConfigDirectory":"~/.claude-work"}"#
        #expect(
            try JSONDecoder().decode(WindowsProviderConfiguration.self, from: Data(foreign.utf8))
                .claudeConfigDirectory == nil)
    }

    @Test
    func `sign-in folder fields name each provider's folder`() throws {
        let codex = try #require(WindowsProviderSignInFolderField.field(for: .codex))
        #expect(codex.label == "Codex home")
        let claude = try #require(WindowsProviderSignInFolderField.field(for: .claude))
        #expect(claude.label == "Claude config folder")
        #expect(claude.hint.contains("CLAUDE_CONFIG_DIR"))
        #expect(WindowsProviderSignInFolderField.field(for: .poe) == nil)
    }

    @Test
    func `a Claude config folder resolves under the WSL home and must exist`() throws {
        var checked: [String] = []
        let resolved = try WindowsConfiguredProviderDataSource.resolveSignInFolder(
            "~/.claude-work",
            provider: .claude,
            distribution: "Ubuntu",
            defaultLinuxHome: { "/home/me" },
            directoryExists: { checked.append($0); return true })
        #expect(resolved == "/home/me/.claude-work")
        #expect(checked == ["/home/me/.claude-work"])

        #expect(throws: WindowsStagedProviderConfigError.validationRejected(
            "The configured Claude config folder was not found in the selected WSL distribution."))
        {
            try WindowsConfiguredProviderDataSource.resolveSignInFolder(
                "/srv/claude",
                provider: .claude,
                distribution: "Ubuntu",
                defaultLinuxHome: { "/home/me" },
                directoryExists: { _ in false })
        }
        #expect(throws: WindowsStagedProviderConfigError.invalidValue("Claude config folder")) {
            try WindowsConfiguredProviderDataSource.resolveSignInFolder(
                "relative/path",
                provider: .claude,
                distribution: "Ubuntu",
                defaultLinuxHome: { "/home/me" },
                directoryExists: { _ in true })
        }
    }

    @Test
    func `the Claude config folder is forwarded into WSL as CLAUDE_CONFIG_DIR`() {
        #expect(
            WindowsConfiguredProviderDataSource.claudeConfigEnvironment(folder: "/home/me/.claude-work", base: [:])
                == ["CLAUDE_CONFIG_DIR": "/home/me/.claude-work", "WSLENV": "CLAUDE_CONFIG_DIR"])
        #expect(
            WindowsConfiguredProviderDataSource.claudeConfigEnvironment(
                folder: "/home/me/.claude-work",
                base: ["WslEnv": "USERPROFILE/p:CLAUDE_CONFIG_DIR"])["WSLENV"]
                == "USERPROFILE/p:CLAUDE_CONFIG_DIR")
        #expect(
            WindowsConfiguredProviderDataSource.claudeConfigEnvironment(
                folder: "/home/me/.claude-work",
                base: ["WSLENV": "USERPROFILE/p"])["WSLENV"]
                == "USERPROFILE/p:CLAUDE_CONFIG_DIR")
    }

    @Test
    func `only a Claude profile with a config folder adds CLAUDE_CONFIG_DIR to Automatic`() throws {
        let folder = WindowsProviderConfiguration(
            id: .claude,
            enabled: true,
            order: 0,
            claudeConfigDirectory: "~/.claude-work")
        let overrides = try WindowsConfiguredProviderDataSource.automaticOverrides(
            for: folder,
            distribution: "Ubuntu",
            defaultLinuxHome: { "/home/me" },
            directoryExists: { _ in true })
        #expect(overrides["CLAUDE_CONFIG_DIR"] == "/home/me/.claude-work")
        #expect(overrides["WSLENV"]?.split(separator: ":").contains("CLAUDE_CONFIG_DIR") == true)

        for provider in [
            WindowsProviderConfiguration(id: .claude, enabled: true, order: 0),
            WindowsProviderConfiguration(id: .codex, enabled: true, order: 0, codexHome: "~/.codex-work"),
        ] {
            let none = try WindowsConfiguredProviderDataSource.automaticOverrides(
                for: provider,
                distribution: "Ubuntu",
                defaultLinuxHome: { "/home/me" },
                directoryExists: { _ in true })
            #expect(none.isEmpty)
        }
        #expect(throws: WindowsStagedProviderConfigError.self) {
            try WindowsConfiguredProviderDataSource.automaticOverrides(
                for: folder,
                distribution: "Ubuntu",
                defaultLinuxHome: { "/home/me" },
                directoryExists: { _ in false })
        }
    }

    @Test
    func `changing a sign-in folder counts as an unsaved change`() {
        let saved = WindowsProviderConfiguration(id: .claude, enabled: true, order: 0)
        var draft = saved
        draft.signInFolder = "~/.claude-work"
        #expect(WindowsProviderConfigurationPageState.hasUnsavedChanges(draft: draft, saved: saved))
    }
}

private final class ProcessRunnerSequence: @unchecked Sendable {
    private let lock = NSLock()
    private var results: [WindowsHiddenProcessResult]
    private var calls = 0

    init(_ results: [WindowsHiddenProcessResult]) {
        self.results = results
    }

    var callCount: Int {
        self.lock.withLock { self.calls }
    }

    func next() throws -> WindowsHiddenProcessResult {
        try self.lock.withLock {
            self.calls += 1
            guard !self.results.isEmpty else { throw WindowsCanonicalCLIError.commandFailed(1) }
            return self.results.removeFirst()
        }
    }
}
#endif
