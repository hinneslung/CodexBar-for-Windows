#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

@Suite("Windows configured provider data source", .serialized)
struct WindowsConfiguredProviderDataSourceTests {
    @Test
    func `provider source chooses all distributions automatically or one explicit distribution`() {
        let automatic = WindowsProviderConfiguration(
            id: .gemini,
            enabled: true,
            order: 0,
            sourceMode: .init(rawValue: "nativeCLI"))
        let explicit = WindowsProviderConfiguration(
            id: .cursor,
            enabled: true,
            order: 1,
            sourceMode: .wsl,
            wslDistro: " Ubuntu ")

        #expect(
            WindowsConfiguredProviderDataSource.candidateDistributions(
                for: automatic,
                installed: ["Debian", "Ubuntu"]) == ["Debian", "Ubuntu"])
        #expect(
            WindowsConfiguredProviderDataSource.candidateDistributions(
                for: explicit,
                installed: ["Debian", "ubuntu"]) == ["ubuntu"])
        #expect(automatic.sourceDisplayName == "Automatic distro · Automatic")
        #expect(explicit.sourceDisplayName == "Ubuntu · Automatic")
    }

    @Test
    func `an explicit missing distribution remains selected for a useful source error`() {
        let provider = WindowsProviderConfiguration(
            id: .codex,
            enabled: true,
            order: 0,
            sourceMode: .wsl,
            wslDistro: "Ubuntu-Removed")
        #expect(
            WindowsConfiguredProviderDataSource.candidateDistributions(
                for: provider,
                installed: ["Ubuntu"]) == ["Ubuntu-Removed"])
    }

    @Test
    func `existing CLI in a later distribution wins before bundled provisioning`() async {
        let recorder = ResolutionRecorder()
        let resolved = await WindowsConfiguredProviderDataSource.resolveCLI(
            distributions: [" Debian ", "Ubuntu", "debian"],
            existing: { distribution in await recorder.existing(distribution) },
            bundled: { distribution in await recorder.bundled(distribution) })

        #expect(
            resolved
                == WindowsConfiguredProviderDataSource.ResolvedCLI(
                    distribution: "Ubuntu",
                    executablePath: "/usr/local/bin/codexbar"))
        #expect(await recorder.existingCalls == ["Debian", "Ubuntu"])
        #expect(await recorder.bundledCalls.isEmpty)
    }

    @Test
    func `bundled provisioning starts only after every existing CLI probe misses`() async {
        let recorder = ResolutionRecorder(existingPath: nil, bundledDistribution: "Debian")
        let resolved = await WindowsConfiguredProviderDataSource.resolveCLI(
            distributions: ["Debian", "Ubuntu"],
            existing: { distribution in await recorder.existing(distribution) },
            bundled: { distribution in await recorder.bundled(distribution) })

        #expect(resolved?.distribution == "Debian")
        #expect(await recorder.existingCalls == ["Debian", "Ubuntu"])
        #expect(await recorder.bundledCalls == ["Debian"])
    }

    @Test
    func `automatic diagnose provisions only inside the usage-selected distribution`() async {
        let usageCLI = WindowsConfiguredProviderDataSource.ResolvedCLI(
            distribution: "Ubuntu",
            executablePath: "/usr/local/bin/codexbar")
        let recorder = AutomaticCLIRecorder()

        let diagnose = await WindowsConfiguredProviderDataSource.resolveAutomaticCLI(
            resolvedUsageCLI: usageCLI,
            executionMode: .diagnose,
            bundled: { distribution in await recorder.bundled(distribution) })
        let usage = await WindowsConfiguredProviderDataSource.resolveAutomaticCLI(
            resolvedUsageCLI: usageCLI,
            executionMode: .usage,
            bundled: { distribution in await recorder.bundled(distribution) })

        #expect(
            diagnose
                == WindowsConfiguredProviderDataSource.ResolvedCLI(
                    distribution: "Ubuntu",
                    executablePath: "/app-owned/Ubuntu/CodexBarCLI"))
        #expect(usage == usageCLI)
        #expect(await recorder.calls == ["Ubuntu"])
    }

    @Test
    func `automatic diagnose fails closed without changing distributions`() async {
        let usageCLI = WindowsConfiguredProviderDataSource.ResolvedCLI(
            distribution: "Ubuntu",
            executablePath: "/usr/local/bin/codexbar")
        let requested = AutomaticCLIRecorder(result: nil)
        let result = await WindowsConfiguredProviderDataSource.resolveAutomaticCLI(
            resolvedUsageCLI: usageCLI,
            executionMode: .diagnose,
            bundled: { distribution in await requested.bundled(distribution) })

        #expect(result == nil)
        #expect(await requested.calls == ["Ubuntu"])
    }

    @Test
    func `automatic diagnose provisions bundled CLI in the ordinary-policy selected distro`() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "codexbar-diagnostic-distribution-\(Foundation.UUID().uuidString)",
            isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WindowsConfigurationStore(fileURL: root.appendingPathComponent("config.json"))
        try store.save(
            WindowsAppConfiguration(providers: [
                WindowsProviderConfiguration(id: .longCat, enabled: true, order: 0),
            ]))
        let resolution = ResolutionRecorder(
            existingPath: "/usr/local/bin/codexbar",
            bundledDistribution: "Ubuntu")
        let invocation = DataSourceInvocationCapture(output: Self.longCatDiagnosticPayload)
        let client = WindowsCanonicalCLIProviderClient(
            processRunner: { executable, arguments, timeout, _, environment, standardInput in
                invocation.record(
                    executable: executable,
                    arguments: arguments,
                    timeout: timeout,
                    environment: environment,
                    standardInput: standardInput)
            },
            retryDelay: {})
        let dataSource = WindowsConfiguredProviderDataSource(
            store: store,
            environment: ["WINDIR": "C:\\Windows"],
            wslDistributions: ["Debian", "Ubuntu"],
            cliDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                resolver: { distro, _ in await resolution.existing(distro) }),
            bundledCLIDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                resolver: { distro, _ in await resolution.bundled(distro) }),
            cliClient: client,
            credentialVault: nil)

        let snapshot = try #require(await dataSource.fetchProviderSnapshots().first)

        #expect(snapshot.availability == .available)
        #expect(snapshot.sourceText == "Ubuntu · Browser session")
        #expect(await resolution.existingCalls == ["Debian", "Ubuntu"])
        #expect(await resolution.bundledCalls == ["Ubuntu"])
        #expect(
            invocation.arguments == [
                "-d", "Ubuntu", "--",
                "/home/example/.local/share/codexbar-windows/0.54.1/CodexBarCLI",
                "diagnose", "--provider", "longcat", "--format", "json", "--redact",
            ])
        #expect(invocation.timeout == 90)
        #expect(invocation.environment.isEmpty)
        #expect(invocation.standardInput == nil)
    }

    @Test
    func `DeepSeek manual token stays in staged account input and remains authoritative`() async throws {
        let canary = "fictitious-deepseek-data-source-canary"
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "codexbar-deepseek-manual-\(Foundation.UUID().uuidString)",
            isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WindowsConfigurationStore(fileURL: root.appendingPathComponent("config.json"))
        let vault = WindowsProviderCredentialVault(
            directoryURL: root.appendingPathComponent("Credentials"))
        try store.save(
            WindowsAppConfiguration(providers: [
                WindowsProviderConfiguration(id: .deepSeek, enabled: true, order: 0),
            ]))
        try vault.save(
            provider: .deepSeek,
            credentialSetID: "api-key",
            submittedValues: ["apiKey": canary])
        let invocation = DataSourceInvocationCapture(
            output: Data(
                #"""
                [{
                  "provider":"deepseek",
                  "source":"api",
                  "usage":null,
                  "credits":null,
                  "error":{"kind":"provider","message":"Offline fixture"}
                }]
                """#
                    .utf8))
        let client = WindowsCanonicalCLIProviderClient(
            processRunner: { executable, arguments, timeout, _, environment, standardInput in
                invocation.record(
                    executable: executable,
                    arguments: arguments,
                    timeout: timeout,
                    environment: environment,
                    standardInput: standardInput)
            },
            retryDelay: {})
        let dataSource = WindowsConfiguredProviderDataSource(
            store: store,
            environment: ["WINDIR": "C:\\Windows", "WSLENV": "SAFE_VALUE"],
            wslDistributions: ["Ubuntu"],
            cliDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                resolver: { _, _ in "/usr/local/bin/codexbar" }),
            bundledCLIDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                resolver: { _, _ in "/opt/codexbar/CodexBarCLI" }),
            cliClient: client,
            credentialBridge: WindowsProviderCredentialBridge(
                authDataLoader: { _ in
                    Issue.record("Manual authority must not inspect OpenCode credentials")
                    return nil
                }),
            credentialVault: vault)

        let snapshot = try #require(await dataSource.fetchProviderSnapshots().first)
        let standardInput = try #require(invocation.standardInput)
        let rootPayload = try #require(
            JSONSerialization.jsonObject(with: standardInput) as? [String: Any])
        let providerPayload = try #require(
            (rootPayload["providers"] as? [[String: Any]])?.first)
        let tokenAccounts = try #require(providerPayload["tokenAccounts"] as? [String: Any])
        let accounts = try #require(tokenAccounts["accounts"] as? [[String: Any]])

        #expect(snapshot.sourceText == "Ubuntu · API key")
        #expect(invocation.timeout == 60)
        #expect(invocation.environment.isEmpty)
        #expect(!invocation.arguments.contains(where: { $0.contains(canary) }))
        #expect(providerPayload["apiKey"] == nil)
        #expect(accounts.count == 1)
        #expect(accounts.first?["token"] as? String == canary)
        let stagedText = try #require(String(bytes: standardInput, encoding: .utf8))
        #expect(stagedText.components(separatedBy: canary).count == 2)
        let windowsConfig = try Data(contentsOf: root.appendingPathComponent("config.json"))
        let windowsConfigText = try #require(String(bytes: windowsConfig, encoding: .utf8))
        #expect(!windowsConfigText.contains(canary))
        #expect(snapshot.safeErrorText?.contains(canary) != true)
        #expect(try (store.load()).providers.first?.id == .deepSeek)
    }

    @Test
    func `Claude automatic answers from fast OAuth without the interactive CLI route`() async throws {
        let (snapshot, calls) = try await Self.fetchAutomaticClaude(responses: [
            .init(output: Self.claudeUsagePayload(source: "oauth"), exitCode: 0),
        ])

        #expect(snapshot.availability == .available)
        #expect(snapshot.sourceText == "Ubuntu · OAuth")
        #expect(calls.count == 1)
        #expect(
            calls.first?.arguments == [
                "-d", "Ubuntu", "--", "/usr/local/bin/codexbar",
                "usage", "--provider", "claude", "--source", "oauth", "--json-only",
            ])
        #expect(calls.first?.timeout == WindowsCanonicalCLIInvocation.preferredSourceProcessTimeout)
    }

    @Test
    func `Claude automatic falls back to the ordinary route once when OAuth fails`() async throws {
        let (snapshot, calls) = try await Self.fetchAutomaticClaude(responses: [
            .init(output: Self.claudeOAuthFailure, exitCode: 1),
            .init(output: Self.claudeUsagePayload(source: "cli"), exitCode: 0),
        ])

        #expect(snapshot.availability == .available)
        #expect(snapshot.sourceText == "Ubuntu · Provider CLI")
        #expect(calls.count == 2)
        #expect(calls.first?.arguments.contains("oauth") == true)
        #expect(
            calls.last?.arguments == [
                "-d", "Ubuntu", "--", "/usr/local/bin/codexbar",
                "usage", "--provider", "claude", "--json-only",
            ])
        #expect(calls.last?.timeout == 45)
    }

    @Test
    func `Claude automatic falls back when OAuth exits cleanly with a provider error`() async throws {
        let (snapshot, calls) = try await Self.fetchAutomaticClaude(responses: [
            .init(output: Self.claudeOAuthFailure, exitCode: 0),
            .init(output: Self.claudeUsagePayload(source: "cli"), exitCode: 0),
        ])

        #expect(snapshot.availability == .available)
        #expect(snapshot.sourceText == "Ubuntu · Provider CLI")
        #expect(calls.count == 2)
        #expect(calls.last?.arguments.contains("--source") == false)
    }

    @Test
    func `Claude automatic reports the ordinary route when OAuth and fallback both fail`() async throws {
        let (snapshot, calls) = try await Self.fetchAutomaticClaude(responses: [
            .init(output: Self.claudeOAuthFailure, exitCode: 1),
            .init(output: Data(), exitCode: 1),
            .init(output: Data(), exitCode: 1),
        ])

        #expect(snapshot.availability == .unavailable)
        #expect(snapshot.sourceText == "Ubuntu · Automatic")
        #expect(snapshot.safeErrorText?.contains("exit code 1") == true)
        #expect(calls.count == 3)
    }

    @Test
    func `cancellation after OAuth fails never starts the Claude fallback process`() async throws {
        let relay = TaskCancellationRelay()
        let outcome = SnapshotBox()
        let task = Task {
            let result = try? await Self.fetchAutomaticClaude(
                responses: [
                    .init(output: Self.claudeOAuthFailure, exitCode: 1),
                    .init(output: Self.claudeUsagePayload(source: "cli"), exitCode: 0),
                ],
                onCall: { callIndex, _ in
                    if callIndex == 0 { relay.cancel() }
                })
            outcome.set(result)
        }
        relay.attach(task)
        await task.value

        let (snapshot, calls) = try #require(outcome.value)
        #expect(calls.count == 1)
        #expect(snapshot.discardsRefreshResult)
    }

    @Test
    func `a credential change during OAuth never starts the Claude fallback process`() async throws {
        let (snapshot, calls) = try await Self.fetchAutomaticClaude(
            responses: [
                .init(output: Self.claudeOAuthFailure, exitCode: 1),
                .init(output: Self.claudeUsagePayload(source: "cli"), exitCode: 0),
            ],
            usesCredentialVault: true,
            onCall: { callIndex, vault in
                guard callIndex == 0 else { return }
                _ = try? vault?.save(
                    provider: .claude,
                    credentialSetID: "api-key",
                    submittedValues: ["apiKey": "fictitious-claude-admin-key"])
            })

        #expect(calls.count == 1)
        #expect(snapshot.discardsRefreshResult)
    }

    @Test
    func `a provider removed upstream is never sent to the CLI`() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "codexbar-removed-upstream-\(Foundation.UUID().uuidString)",
            isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WindowsConfigurationStore(fileURL: root.appendingPathComponent("config.json"))
        try store.save(
            WindowsAppConfiguration(providers: [
                WindowsProviderConfiguration(id: .crof, enabled: true, order: 0),
            ]))
        let capture = SequencedInvocationCapture(responses: [])
        let dataSource = WindowsConfiguredProviderDataSource(
            store: store,
            environment: ["WINDIR": "C:\\Windows"],
            wslDistributions: ["Ubuntu"],
            cliDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                resolver: { _, _ in "/usr/local/bin/codexbar" }),
            bundledCLIDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                resolver: { _, _ in "/opt/codexbar/CodexBarCLI" }),
            cliClient: WindowsCanonicalCLIProviderClient(
                processRunner: { _, arguments, timeout, _, _, _ in
                    capture.record(arguments: arguments, timeout: timeout)
                },
                retryDelay: {}),
            credentialVault: nil)

        let snapshots = await dataSource.fetchProviderSnapshots()

        #expect(snapshots.allSatisfy { $0.provider != .crof })
        #expect(capture.calls.isEmpty)
        #expect(try store.load().providers.first { $0.id == .crof }?.enabled == false)
    }

    @Test
    func `automatic source routes are declared only for Claude and Gemini`() {
        let routes = WindowsProviderConfigurationCatalog.automaticSourceRoutes
        #expect(routes == [.claude: .preferred("oauth"), .gemini: .exclusive("api")])
        #expect(routes[.codex] == nil)
    }

    @Test
    func `Gemini automatic always uses its API source with normal timeout`() async throws {
        let (snapshot, calls) = try await Self.fetchAutomatic(
            provider: .gemini,
            responses: [.init(output: Self.usagePayload(provider: "gemini", source: "api"), exitCode: 0)])

        #expect(snapshot.availability == .available)
        #expect(
            calls.map(\.arguments) == [[
                "-d", "Ubuntu", "--", "/usr/local/bin/codexbar",
                "usage", "--provider", "gemini", "--source", "api", "--json-only",
            ]])
        #expect(calls.first?.timeout == 45)
    }

    @Test
    func `Gemini automatic retries its API source and never falls back to plain Automatic`() async throws {
        let (snapshot, calls) = try await Self.fetchAutomatic(
            provider: .gemini,
            responses: [.init(output: Data(), exitCode: 1), .init(output: Data(), exitCode: 1)])

        #expect(snapshot.availability == .unavailable)
        #expect(calls.count == 2)
        #expect(calls.allSatisfy { $0.arguments.contains("--source") && $0.arguments.contains("api") })
    }

    @Test
    func `five provider fetches run together while output order stays stable`() async {
        let inputs = Array(0..<7)
        let probe = ConcurrencyProbe(expectedInitialCount: 5)
        let operation = Task {
            await WindowsBoundedConcurrentMap.map(
                inputs,
                maximumConcurrentTasks: WindowsConfiguredProviderDataSource
                    .maximumConcurrentProviderFetches)
            { value in
                await probe.run(value)
            }
        }

        await probe.waitForInitialTasks()
        #expect(WindowsConfiguredProviderDataSource.maximumConcurrentProviderFetches == 5)
        #expect(await probe.maximumActiveCount == 5)
        #expect(await Set(probe.startedInputs) == Set(inputs.prefix(5)))
        await probe.releaseAll()

        #expect(await operation.value == inputs.map { "provider-\($0)" })
        #expect(await probe.maximumActiveCount == 5)
        #expect(await Set(probe.startedInputs) == Set(inputs))
    }

    @Test
    func `valid manual early failure is invalidated by replacement during a delayed sibling`() async throws {
        let fixture = try DataSourceFixture()
        defer { fixture.remove() }
        try fixture.vault.save(
            provider: .poe,
            credentialSetID: "api-key",
            submittedValues: ["apiKey": "manual-before-delay"])
        let snapshot = try #require(await fixture.fetch(bridge: .init()).first)
        #expect(snapshot.availability == .error)
        #expect(snapshot.publicationAuthorityCheck != nil)

        try await Self.expectRejectedAfterDelayedSibling(snapshot) {
            try fixture.vault.save(
                provider: .poe,
                credentialSetID: "api-key",
                submittedValues: ["apiKey": "manual-after-delay"])
        }
    }

    @Test
    func `corrupt manual early failure is invalidated by clear during a delayed sibling`() async throws {
        let fixture = try DataSourceFixture()
        defer { fixture.remove() }
        try FileManager.default.createDirectory(
            at: fixture.vault.directoryURL,
            withIntermediateDirectories: true)
        try Data([0, 1, 2, 3]).write(
            to: fixture.vault.directoryURL.appendingPathComponent("poe.bin"))
        let snapshot = try #require(await fixture.fetch(bridge: .init()).first)
        #expect(snapshot.availability == .error)
        #expect(snapshot.publicationAuthorityCheck != nil)

        try await Self.expectRejectedAfterDelayedSibling(snapshot) {
            try fixture.vault.clear(.poe)
        }
    }

    @Test
    func `stable blob identity lookup failure publishes once and replacement invalidates it`() async throws {
        let fixture = try DataSourceFixture()
        defer { fixture.remove() }
        try FileManager.default.createDirectory(
            at: fixture.vault.directoryURL.appendingPathComponent("poe.bin"),
            withIntermediateDirectories: true)
        let snapshot = try #require(await fixture.fetch(bridge: .init()).first)
        #expect(snapshot.availability == .error)
        #expect(snapshot.sourceText == "Automatic distro · Manual credential")
        #expect(!snapshot.discardsRefreshResult)
        #expect(try snapshot.publicationAuthorityCheck?() == true)

        let initiallyCommitted = DataSourceCommittedProviders()
        let initialOutcome = WindowsProviderSnapshotPublisher.publish([snapshot]) { value in
            initiallyCommitted.append(value.provider)
        }
        #expect(initialOutcome.rejectedProviders.isEmpty)
        #expect(initiallyCommitted.value == [.poe])

        try FileManager.default.removeItem(
            at: fixture.vault.directoryURL.appendingPathComponent("poe.bin"))
        try fixture.vault.save(
            provider: .poe,
            credentialSetID: "api-key",
            submittedValues: ["apiKey": "manual-after-identity-failure"])
        let replacedOutcome = WindowsProviderSnapshotPublisher.publish([snapshot]) { _ in
            Issue.record("Stale lookup failure must not publish after replacement")
        }
        #expect(replacedOutcome.rejectedProviders == [.poe])
    }

    @Test
    func `OpenCode early failure is invalidated by manual save during a delayed sibling`() async throws {
        let fixture = try DataSourceFixture()
        defer { fixture.remove() }
        let bridge = WindowsProviderCredentialBridge(authDataLoader: { _ in Data("{".utf8) })
        let snapshot = try #require(await fixture.fetch(bridge: bridge).first)
        #expect(snapshot.availability == .error)
        #expect(snapshot.sourceText == "Ubuntu · Automatic")
        #expect(snapshot.safeErrorText?.localizedCaseInsensitiveContains("bridge") == false)
        #expect(snapshot.publicationAuthorityCheck != nil)

        try await Self.expectRejectedAfterDelayedSibling(snapshot) {
            try fixture.vault.save(
                provider: .poe,
                credentialSetID: "api-key",
                submittedValues: ["apiKey": "manual-wins-after-delay"])
        }
    }

    @Test
    func `missing CLI result is invalidated when manual intent changes during resolution`() async throws {
        let fixture = try DataSourceFixture(existingCLI: nil)
        defer { fixture.remove() }
        let snapshot = try #require(await fixture.fetch(bridge: .init()).first)
        #expect(snapshot.availability == .unavailable)
        #expect(snapshot.publicationAuthorityCheck != nil)

        try await Self.expectRejectedAfterDelayedSibling(snapshot) {
            try fixture.vault.save(
                provider: .poe,
                credentialSetID: "api-key",
                submittedValues: ["apiKey": "manual-created-during-resolution"])
        }
    }

    private static func expectRejectedAfterDelayedSibling(
        _ snapshot: WindowsProviderSnapshot,
        mutation: () throws -> Void) async throws
    {
        let siblingStarted = DispatchSemaphore(value: 0)
        let releaseSibling = DispatchSemaphore(value: 0)
        let batch = Task.detached {
            siblingStarted.signal()
            _ = releaseSibling.wait(timeout: .now() + 5)
            return [
                snapshot,
                WindowsProviderSnapshot(
                    provider: .cursor,
                    availability: .available,
                    sourceText: "Automatic · WSL CLI · Ubuntu"),
            ]
        }
        #expect(siblingStarted.wait(timeout: .now() + 2) == .success)
        try mutation()
        releaseSibling.signal()

        let committed = DataSourceCommittedProviders()
        let outcome = await WindowsProviderSnapshotPublisher.publish(batch.value) { value in
            committed.append(value.provider)
        }
        #expect(outcome.rejectedProviders == [.poe])
        #expect(committed.value == [.cursor])
    }

    private static func fetchAutomaticClaude(
        responses: [SequencedInvocationCapture.Response],
        usesCredentialVault: Bool = false,
        onCall: (@Sendable (_ callIndex: Int, _ vault: WindowsProviderCredentialVault?) -> Void)? = nil)
        async throws -> (WindowsProviderSnapshot, [SequencedInvocationCapture.Call])
    {
        try await self.fetchAutomatic(
            provider: .claude,
            responses: responses,
            usesCredentialVault: usesCredentialVault,
            onCall: onCall)
    }

    private static func fetchAutomatic(
        provider: WindowsProviderID,
        responses: [SequencedInvocationCapture.Response],
        usesCredentialVault: Bool = false,
        onCall: (@Sendable (_ callIndex: Int, _ vault: WindowsProviderCredentialVault?) -> Void)? = nil)
        async throws -> (WindowsProviderSnapshot, [SequencedInvocationCapture.Call])
    {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "codexbar-claude-preferred-\(Foundation.UUID().uuidString)",
            isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WindowsConfigurationStore(fileURL: root.appendingPathComponent("config.json"))
        try store.save(
            WindowsAppConfiguration(providers: [
                WindowsProviderConfiguration(id: provider, enabled: true, order: 0),
            ]))
        let vault = usesCredentialVault
            ? WindowsProviderCredentialVault(directoryURL: root.appendingPathComponent("Credentials"))
            : nil
        let capture = SequencedInvocationCapture(responses: responses) { callIndex in
            onCall?(callIndex, vault)
        }
        let client = WindowsCanonicalCLIProviderClient(
            processRunner: { _, arguments, timeout, _, _, _ in
                capture.record(arguments: arguments, timeout: timeout)
            },
            retryDelay: {})
        let dataSource = WindowsConfiguredProviderDataSource(
            store: store,
            environment: ["WINDIR": "C:\\Windows"],
            wslDistributions: ["Ubuntu"],
            cliDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                resolver: { _, _ in "/usr/local/bin/codexbar" }),
            bundledCLIDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                resolver: { _, _ in "/opt/codexbar/CodexBarCLI" }),
            cliClient: client,
            credentialVault: vault)

        let snapshot = try #require(await dataSource.fetchProviderSnapshots().first)
        return (snapshot, capture.calls)
    }

    private static let claudeOAuthFailure = Data(
        #"[{"provider":"claude","source":"oauth","error":{"kind":"provider","message":"No credentials"}}]"#.utf8)

    private static func claudeUsagePayload(source: String) -> Data {
        self.usagePayload(provider: "claude", source: source)
    }

    private static func usagePayload(provider: String, source: String) -> Data {
        Data(
            #"""
            [{
              "provider":"\#(provider)",
              "source":"\#(source)",
              "usage":{"primary":{"usedPercent":2,"resetsAt":"2026-10-20T07:30:00Z"}}
            }]
            """#
                .utf8)
    }

    private static let longCatDiagnosticPayload = Data(
        #"""
        {
          "schemaVersion":"1.0",
          "timestamp":"2026-09-03T00:00:00Z",
          "platform":"Linux",
          "appVersion":"1.2.3",
          "provider":"longcat",
          "displayName":"LongCat",
          "source":"web",
          "sourceMode":"web",
          "auth":{"configured":true,"modes":["web"]},
          "usage":{
            "updatedAt":"2026-09-03T00:00:00Z",
            "dataConfidence":"exact",
            "windows":[{
              "label":"Session",
              "usedPercent":25,
              "windowMinutes":300,
              "resetsAt":null,
              "hasResetDescription":false,
              "nextRegenPercent":null,
              "usageKnown":true
            }],
            "extraWindowCount":0,
            "providerCostPresent":false,
            "providerSpecificData":[],
            "detailSections":[]
          },
          "fetchAttempts":[{"kind":"web","wasAvailable":true,"errorCategory":null}],
          "error":null,
          "settings":{"sourceMode":"web","apiRegion":null},
          "details":null
        }
        """#
            .utf8)

    private actor ResolutionRecorder {
        private let existingPath: String?
        private let bundledDistribution: String
        private(set) var existingCalls: [String] = []
        private(set) var bundledCalls: [String] = []

        init(
            existingPath: String? = "/usr/local/bin/codexbar",
            bundledDistribution: String = "")
        {
            self.existingPath = existingPath
            self.bundledDistribution = bundledDistribution
        }

        func existing(_ distribution: String) -> String? {
            self.existingCalls.append(distribution)
            return distribution == "Ubuntu" ? self.existingPath : nil
        }

        func bundled(_ distribution: String) -> String? {
            self.bundledCalls.append(distribution)
            return distribution == self.bundledDistribution
                ? "/home/example/.local/share/codexbar-windows/0.54.1/CodexBarCLI"
                : nil
        }
    }

    private actor AutomaticCLIRecorder {
        private let result: String?
        private(set) var calls: [String] = []

        init(result: String? = "/app-owned/Ubuntu/CodexBarCLI") {
            self.result = result
        }

        func bundled(_ distribution: String) -> String? {
            self.calls.append(distribution)
            return self.result
        }
    }

    private final class DataSourceFixture: @unchecked Sendable {
        let root: URL
        let store: WindowsConfigurationStore
        let vault: WindowsProviderCredentialVault
        let existingCLI: String?

        init(existingCLI: String? = "/usr/bin/codexbar") throws {
            self.root = FileManager.default.temporaryDirectory.appendingPathComponent(
                "codexbar-data-source-authority-\(Foundation.UUID().uuidString)",
                isDirectory: true)
            self.store = WindowsConfigurationStore(
                fileURL: self.root.appendingPathComponent("config.json"))
            self.vault = WindowsProviderCredentialVault(
                directoryURL: self.root.appendingPathComponent("Credentials"))
            self.existingCLI = existingCLI
            let configuration = WindowsAppConfiguration(providers: [
                WindowsProviderConfiguration(id: .poe, enabled: true, order: 0),
            ])
            try self.store.save(configuration)
        }

        func fetch(bridge: WindowsProviderCredentialBridge) async -> [WindowsProviderSnapshot] {
            let existingCLI = self.existingCLI
            let dataSource = WindowsConfiguredProviderDataSource(
                store: self.store,
                environment: ["WINDIR": "C:\\Windows"],
                wslDistributions: ["Ubuntu"],
                cliDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                    resolver: { _, _ in existingCLI }),
                bundledCLIDiscoveryCache: WindowsCanonicalCLIDiscoveryCache(
                    resolver: { _, _ in nil }),
                credentialBridge: bridge,
                credentialVault: self.vault)
            return await dataSource.fetchProviderSnapshots()
        }

        func remove() {
            try? FileManager.default.removeItem(at: self.root)
        }
    }

    private actor ConcurrencyProbe {
        private let expectedInitialCount: Int
        private var activeCount = 0
        private(set) var maximumActiveCount = 0
        private(set) var startedInputs: [Int] = []
        private var initialTasksContinuation: CheckedContinuation<Void, Never>?
        private var releaseContinuations: [CheckedContinuation<Void, Never>] = []
        private var isReleased = false

        init(expectedInitialCount: Int) {
            self.expectedInitialCount = expectedInitialCount
        }

        func run(_ input: Int) async -> String {
            self.activeCount += 1
            self.maximumActiveCount = max(self.maximumActiveCount, self.activeCount)
            self.startedInputs.append(input)
            if self.startedInputs.count == self.expectedInitialCount {
                self.initialTasksContinuation?.resume()
                self.initialTasksContinuation = nil
            }
            if !self.isReleased {
                await withCheckedContinuation { continuation in
                    self.releaseContinuations.append(continuation)
                }
            }
            self.activeCount -= 1
            return "provider-\(input)"
        }

        func waitForInitialTasks() async {
            guard self.startedInputs.count < self.expectedInitialCount else { return }
            await withCheckedContinuation { continuation in
                self.initialTasksContinuation = continuation
            }
        }

        func releaseAll() {
            self.isReleased = true
            let continuations = self.releaseContinuations
            self.releaseContinuations.removeAll()
            for continuation in continuations {
                continuation.resume()
            }
        }
    }
}

private final class SequencedInvocationCapture: @unchecked Sendable {
    struct Response {
        let output: Data
        let exitCode: Int32
    }

    struct Call {
        let arguments: [String]
        let timeout: TimeInterval
    }

    private let lock = NSLock()
    private let onCall: @Sendable (Int) -> Void
    private var responses: [Response]
    private var storedCalls: [Call] = []

    init(responses: [Response], onCall: @escaping @Sendable (Int) -> Void = { _ in }) {
        self.responses = responses
        self.onCall = onCall
    }

    var calls: [Call] {
        self.lock.withLock { self.storedCalls }
    }

    func record(arguments: [String], timeout: TimeInterval) -> WindowsHiddenProcessResult {
        let (callIndex, response) = self.lock.withLock {
            self.storedCalls.append(Call(arguments: arguments, timeout: timeout))
            return (
                self.storedCalls.count - 1,
                self.responses.isEmpty
                    ? Response(output: Data(), exitCode: 1)
                    : self.responses.removeFirst())
        }
        self.onCall(callIndex)
        return WindowsHiddenProcessResult(
            standardOutput: response.output,
            standardError: Data(),
            exitCode: response.exitCode)
    }
}

private final class SnapshotBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: (WindowsProviderSnapshot, [SequencedInvocationCapture.Call])?

    var value: (WindowsProviderSnapshot, [SequencedInvocationCapture.Call])? {
        self.lock.withLock { self.stored }
    }

    func set(_ value: (WindowsProviderSnapshot, [SequencedInvocationCapture.Call])?) {
        self.lock.withLock { self.stored = value }
    }
}

/// Cancels a task from inside a stubbed process. `cancel()` waits for the task handle, so the cancellation is in
/// effect before the stubbed process returns even when the stub runs before `attach(_:)`.
private final class TaskCancellationRelay: @unchecked Sendable {
    private let lock = NSLock()
    private let attached = DispatchSemaphore(value: 0)
    private var task: Task<Void, Never>?

    func attach(_ task: Task<Void, Never>) {
        self.lock.withLock { self.task = task }
        self.attached.signal()
    }

    func cancel() {
        _ = self.attached.wait(timeout: .now() + 5)
        self.lock.withLock { self.task }?.cancel()
    }
}

private final class DataSourceCommittedProviders: @unchecked Sendable {
    private let lock = NSLock()
    private var providers: [WindowsProviderID] = []

    var value: [WindowsProviderID] {
        self.lock.withLock { self.providers }
    }

    func append(_ provider: WindowsProviderID) {
        self.lock.withLock { self.providers.append(provider) }
    }
}

private final class DataSourceInvocationCapture: @unchecked Sendable {
    private let lock = NSLock()
    private let output: Data
    private var storedArguments: [String] = []
    private var storedTimeout: TimeInterval = 0
    private var storedEnvironment: [String: String] = [:]
    private var storedStandardInput: Data?

    init(output: Data) {
        self.output = output
    }

    var arguments: [String] {
        self.lock.withLock { self.storedArguments }
    }

    var timeout: TimeInterval {
        self.lock.withLock { self.storedTimeout }
    }

    var environment: [String: String] {
        self.lock.withLock { self.storedEnvironment }
    }

    var standardInput: Data? {
        self.lock.withLock { self.storedStandardInput }
    }

    func record(
        executable _: String,
        arguments: [String],
        timeout: TimeInterval,
        environment: [String: String],
        standardInput: Data?) -> WindowsHiddenProcessResult
    {
        self.lock.withLock {
            self.storedArguments = arguments
            self.storedTimeout = timeout
            self.storedEnvironment = environment
            self.storedStandardInput = standardInput
        }
        return WindowsHiddenProcessResult(
            standardOutput: self.output,
            standardError: Data(),
            exitCode: 0)
    }
}
#endif
