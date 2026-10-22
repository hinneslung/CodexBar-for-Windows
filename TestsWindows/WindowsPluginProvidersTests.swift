#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

/// Upstream API-key plugin providers and the generic `usage.details` rendering they rely on.
@Suite("Windows upstream plugin providers")
struct WindowsPluginProvidersTests {
    private static let providers: [WindowsProviderID] = [
        .huggingFace, .v0, .devPass, .atlasCloud, .vercel, .xKiro, .tavily, .linkup, .aerostack,
        .sailResearch, .sofya, .fal, .munito,
    ]

    @Test
    func `every plugin provider is supported through a saved key on the API source`() throws {
        for provider in Self.providers {
            #expect(WindowsProviderID.supportedProviders.contains(provider))
            #expect(provider.cliName == provider.rawValue)
            let schema = try #require(WindowsProviderConfigurationCatalog.byProvider[provider])
            let key = try #require(schema.credentialSet(id: "api-key"))
            #expect(key.source == "api")
            #expect(key.fields.first?.storage == .apiKey)
            #expect(schema.automaticExecutionMode == .usage)

            let payload = try Self.stage(provider, key, Self.requiredValues(key, apiKey: "fixture-key"))
            #expect(payload["id"] as? String == provider.rawValue)
            #expect(payload["source"] as? String == "api")
            #expect(payload["apiKey"] as? String == "fixture-key")
            #expect(payload["pluginSecrets"] == nil)
        }
        #expect(WindowsProviderCapabilityPresentation.summary(provider: .tavily) == "API key")
        #expect(
            WindowsProviderCapabilityPresentation.summary(provider: .huggingFace) == "Provider app/CLI · API key")
        #expect(WindowsProviderCapabilityPresentation.summary(provider: .vercel) == "API key · Access token")
    }

    @Test
    func `provider-specific key labels follow the upstream guides`() throws {
        func keyLabel(_ provider: WindowsProviderID) throws -> String {
            try #require(Self.set(provider, "api-key").fields.first?.label)
        }
        #expect(try keyLabel(.huggingFace) == "Access token")
        #expect(try keyLabel(.munito) == "Admin API key")
        #expect(try keyLabel(.aerostack) == "Account token")
        #expect(try keyLabel(.vercel) == "AI Gateway API key")
        #expect(try keyLabel(.linkup) == "API key")
    }

    @Test
    func `v0 scope is optional and staged as the workspace ID`() throws {
        let set = try Self.set(.v0, "api-key")
        #expect(set.fields.map(\.storage) == [.apiKey, .workspaceID])
        #expect(set.fields.last?.required == false)

        let unscoped = try Self.stage(.v0, set, ["apiKey": "v0-fixture"])
        #expect(unscoped["workspaceID"] == nil)
        let scoped = try Self.stage(.v0, set, ["apiKey": "v0-fixture", "workspaceID": "my-project"])
        #expect(scoped["workspaceID"] as? String == "my-project")
    }

    @Test
    func `Vercel access tokens stage as a plugin secret with the team`() throws {
        let schema = try #require(WindowsProviderConfigurationCatalog.byProvider[.vercel])
        #expect(schema.manualCredentialSets.map(\.id) == ["api-key", "access-token"])
        let set = try Self.set(.vercel, "access-token")
        #expect(set.source == "api")
        #expect(!set.acceptsOpenCode)
        #expect(set.fields.map(\.storage) == [.vercelAccessToken, .workspaceID])
        #expect(set.fields.filter { !$0.required }.isEmpty)

        let payload = try Self.stage(
            .vercel,
            set,
            ["vercelAccessToken": "vercel-fixture", "workspaceID": "team_fixture-1"])
        #expect(payload["source"] as? String == "api")
        #expect(payload["apiKey"] == nil)
        #expect(payload["workspaceID"] as? String == "team_fixture-1")
        #expect(payload["pluginSecrets"] as? [String: String] == ["VERCEL_ACCESS_TOKEN": "vercel-fixture"])
    }

    @Test
    func `Vercel team IDs follow the upstream budget plugin's check`() throws {
        let team = try #require(Self.set(.vercel, "access-token").fields.last)
        #expect(team.accepts("team_AbC-123"))
        #expect(team.accepts(String(repeating: "a", count: 128)))
        #expect(!team.accepts(String(repeating: "a", count: 129)))
        #expect(!team.accepts("team/other"))
        #expect(!team.accepts("team id"))
        #expect(!team.accepts("équipe"))
    }

    @Test
    func `usage details decode into display sections`() throws {
        let snapshot = try Self.decode(
            .v0,
            usage: #"""
            "details":[
              {"title":"v0 API","rows":[
                {"label":"Billing remaining","value":"1,234","secondaryValue":"of 5,000"},
                {"label":"Scope","value":"  my   project  "}
              ],"chart":{"kind":"bars","points":[{"label":"Mon","value":1}]}},
              {"rows":[{"label":"Billing type","value":"tokens"}]}
            ]
            """#)
        #expect(
            snapshot.detailSections == [
                WindowsProviderDetailSection(
                    title: "v0 API",
                    rows: [
                        .init(label: "Billing remaining", value: "1,234", secondaryValue: "of 5,000"),
                        .init(label: "Scope", value: "my project"),
                    ]),
                WindowsProviderDetailSection(title: nil, rows: [.init(label: "Billing type", value: "tokens")]),
            ])
        #expect(snapshot.detailSections.first?.rows.first?.displayValue == "1,234 of 5,000")
        // v0 names no balance row, so nothing is promoted out of its details.
        #expect(snapshot.balanceText == nil)
    }

    @Test
    func `malformed details are skipped without failing the reading`() throws {
        let snapshot = try Self.decode(
            .tavily,
            usage: #"""
            "details":[
              {"title":7,"rows":[{"label":"Used","value":3},{"label":"Limit","value":"1,000"},{"value":"x"}]},
              {"title":"Empty","rows":"none"},
              "not a section"
            ]
            """#)
        #expect(snapshot.availability == .available)
        #expect(snapshot.detailSections == [.init(title: nil, rows: [.init(label: "Limit", value: "1,000")])])

        let notArray = try Self.decode(.tavily, usage: #""details":{"title":"x"}"#)
        #expect(notArray.availability == .available)
        #expect(notArray.detailSections.isEmpty)
    }

    @Test
    func `details are capped at upstream's section and row limits`() throws {
        let row = #"{"label":"Row","value":"1"}"#
        let section = #"{"rows":[\#(Array(repeating: row, count: 30).joined(separator: ","))]}"#
        let snapshot = try Self.decode(
            .tavily,
            usage: #""details":[\#(Array(repeating: section, count: 10).joined(separator: ","))]"#)
        #expect(snapshot.detailSections.count == 8)
        #expect(snapshot.detailSections.allSatisfy { $0.rows.count == 24 })
    }

    @Test
    func `balance-only providers show their balance row as the balance, once`() throws {
        let snapshot = try Self.decode(
            .linkup,
            usage: #""details":[{"title":"Account balance","rows":[{"label":"Credit balance","value":"$12.34"}]}]"#)
        #expect(snapshot.balanceText == "$12.34 remaining")
        #expect(snapshot.detailSections.isEmpty)

        let row = WindowsDashboardPresentation.makeRow(
            snapshot: snapshot,
            profile: WindowsProviderConfiguration(id: .linkup, enabled: true, order: 0),
            distinguishesProfile: false)
        #expect(row.governingWindow == nil)
        #expect(WindowsProviderBalanceFormatter.compact(row.balanceText) == "$12.34")
        #expect(row.detailSections.isEmpty)
    }

    @Test
    func `a promoted balance row leaves the rest of its section`() throws {
        let snapshot = try Self.decode(
            .sailResearch,
            usage: #"""
            "details":[{"title":"Organization billing","rows":[
              {"label":"Credit balance","value":"$40.00"},
              {"label":"Last 30 days spend","value":"$3.20"}
            ]}]
            """#)
        #expect(snapshot.balanceText == "$40.00 remaining")
        #expect(
            snapshot.detailSections == [
                .init(title: "Organization billing", rows: [.init(label: "Last 30 days spend", value: "$3.20")]),
            ])
    }

    @Test
    func `a balance row without an amount stays in the details`() throws {
        let snapshot = try Self.decode(
            .sailResearch,
            usage: #"""
            "details":[{"title":"Organization billing","rows":[{"label":"Credit balance","value":"Unavailable"}]}]
            """#)
        #expect(snapshot.balanceText == nil)
        #expect(snapshot.detailSections.first?.rows.first?.value == "Unavailable")
    }

    @Test
    func `a reported balance takes precedence over a balance row`() throws {
        let snapshot = try Self.decode(
            .linkup,
            usage: #"""
            "providerCost":{"currencyCode":"USD","balance":5},
            "details":[{"title":"Account balance","rows":[{"label":"Credit balance","value":"$12.34"}]}]
            """#)
        #expect(snapshot.balanceText == "$5.00 remaining")
        #expect(snapshot.detailSections.first?.rows.first?.value == "$12.34")
    }

    @Test
    func `detail rows reach the presentation and its accessibility text`() throws {
        let snapshot = try Self.decode(
            .tavily,
            usage: #"""
            "primary":{"usedPercent":25},
            "details":[{"title":"Account plan","rows":[{"label":"Remaining","value":"750"}]}]
            """#)
        let row = WindowsDashboardPresentation.makeRow(
            snapshot: snapshot,
            profile: WindowsProviderConfiguration(id: .tavily, enabled: true, order: 0),
            distinguishesProfile: false)
        #expect(row.detailSections == snapshot.detailSections)
        #expect(row.accessibilityText.contains("Remaining: 750"))

        let retained = WindowsTrayApplication.snapshotRetainingLastSuccess(
            WindowsProviderSnapshot(provider: .tavily, availability: .error, sourceText: "WSL CLI · Ubuntu"),
            cached: snapshot)
        #expect(retained.detailSections == snapshot.detailSections)
    }

    @Test
    func `detail layout height counts titles, rows, and section padding`() {
        #expect(WindowsProviderDetailLayout.contentHeight([]) == 0)
        let sections = [
            WindowsProviderDetailSection(
                title: "Plan",
                rows: [.init(label: "A", value: "1"), .init(label: "B", value: "2")]),
            WindowsProviderDetailSection(title: nil, rows: [.init(label: "C", value: "3")]),
        ]
        #expect(WindowsProviderDetailLayout.contentHeight(sections) == (10 + 24 + 48 + 6) + (10 + 24 + 6))
    }

    private static func set(_ provider: WindowsProviderID, _ id: String) throws -> WindowsProviderCredentialSet {
        try #require(WindowsProviderConfigurationCatalog.byProvider[provider]?.credentialSets.first { $0.id == id })
    }

    private static func requiredValues(_ set: WindowsProviderCredentialSet, apiKey: String) -> [String: String] {
        Dictionary(uniqueKeysWithValues: set.fields.filter(\.required).map { ($0.id, apiKey) })
    }

    private static func stage(
        _ provider: WindowsProviderID,
        _ set: WindowsProviderCredentialSet,
        _ values: [String: String]) throws -> [String: Any]
    {
        let record = WindowsProviderCredentialRecord(provider: provider, credentialSetID: set.id, values: values)
        let data = try WindowsStagedProviderConfig.encodeManual(provider: provider, record: record).data
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let providers = try #require(object["providers"] as? [[String: Any]])
        return try #require(providers.first)
    }

    private static func decode(_ provider: WindowsProviderID, usage: String) throws -> WindowsProviderSnapshot {
        let json = #"[{"provider":"\#(provider.rawValue)","source":"api","usage":{\#(usage)}}]"#
        return try WindowsCanonicalCLIProviderClient.decode(
            data: Data(json.utf8),
            requestedProvider: provider,
            sourceText: "WSL CLI · Ubuntu")
    }
}
#endif
