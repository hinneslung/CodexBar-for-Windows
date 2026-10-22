#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

/// Upstream plugin providers that need a workspace or base URL, a manual browser session, or the provider's own
/// sign-in in WSL.
@Suite("Windows upstream plugin provider batches")
struct WindowsPluginProviderBatchTests {
    @Test
    func `workspace and project companions stage as the workspace ID`() throws {
        let exa = try Self.stage(.exa, "api-key", ["apiKey": "service", "workspaceID": "key_123"])
        #expect(exa["apiKey"] as? String == "service")
        #expect(exa["workspaceID"] as? String == "key_123")
        let exaID = try Self.field(.exa, "api-key", "workspaceID")
        #expect(exaID.required)
        #expect(!exaID.accepts("."))
        #expect(!exaID.accepts(".."))
        #expect(!exaID.accepts("a/b"))

        let flora = try Self.field(.flora, "api-key", "workspaceID")
        #expect(flora.accepts("ws_AbC123"))
        #expect(!flora.accepts("ws_"))
        #expect(!flora.accepts("ws_a-b"))
        #expect(!flora.accepts("workspace"))

        let cosmic = try Self.stage(.cosmic, "api-key", ["apiKey": "token", "workspaceID": "project-1"])
        #expect(cosmic["workspaceID"] as? String == "project-1")
        #expect(try Self.field(.cosmic, "api-key", "apiKey").label == "Personal access token")
    }

    @Test
    func `GitKraken's organization is optional printable ASCII`() throws {
        let organization = try Self.field(.gitKraken, "api-key", "workspaceID")
        #expect(!organization.required)
        #expect(organization.accepts("org-1_A"))
        #expect(!organization.accepts("org 1"))
        #expect(!organization.accepts(String(repeating: "a", count: 257)))
        let unscoped = try Self.stage(.gitKraken, "api-key", ["apiKey": "token"])
        #expect(unscoped["workspaceID"] == nil)
    }

    @Test
    func `gateway base URLs follow upstream's private-network rule`() throws {
        let bifrost = try Self.field(.bifrost, "api-key", "enterpriseHost")
        #expect(bifrost.required)
        #expect(bifrost.accepts("https://bifrost.example.test"))
        #expect(bifrost.accepts("http://192.168.1.10:8080"))
        #expect(!bifrost.accepts("http://bifrost.example.test"))
        #expect(try Self.field(.bifrost, "api-key", "apiKey").label == "Virtual key")
        let staged = try Self.stage(
            .bifrost,
            "api-key",
            ["apiKey": "vk", "enterpriseHost": "https://bifrost.example.test"])
        #expect(staged["enterpriseHost"] as? String == "https://bifrost.example.test")

        let aixy = try Self.field(.aixy, "api-key", "enterpriseHost")
        #expect(!aixy.required)
        #expect(aixy.accepts("https://api.aixy-gateway.com/v1"))
        #expect(aixy.accepts("http://localhost:4000"))
        #expect(!aixy.accepts("https://api.aixy-gateway.com/?team=1"))
        #expect(!aixy.accepts("https://api.aixy-gateway.com/#usage"))
        #expect(try Self.stage(.aixy, "api-key", ["apiKey": "key"])["enterpriseHost"] == nil)
    }

    @Test
    func `Charm Hyper offers a key or a manual session, and Automatic uses its API source`() throws {
        let schema = try #require(WindowsProviderConfigurationCatalog.byProvider[.hyper])
        #expect(schema.manualCredentialSets.map(\.label) == ["API key", "Browser session"])
        #expect(WindowsProviderConfigurationCatalog.automaticSourceRoutes[.hyper] == .exclusive("api"))

        let session = try Self.stage(.hyper, "browser-session", ["cookieHeader": "session=abc"])
        #expect(session["source"] as? String == "web")
        #expect(session["cookieSource"] as? String == "manual")
        let key = try Self.stage(.hyper, "api-key", ["apiKey": "hyper-key"])
        #expect(key["source"] as? String == "api")
        #expect(key["cookieSource"] == nil)
    }

    @Test
    func `browser-session providers stage a manual web source and run normal usage`() throws {
        let cookies: [WindowsProviderID: String] = [
            .claudePlatform: "sessionKey=sk-ant-fixture",
            .replicate: "sessionid=fixture; csrftoken=x",
            .raycast: "__raycast_session=fixture",
            .typeSafe: "anything=fixture",
            .parallel: "anything=fixture",
            .xAPI: "auth_token=fixture; ct0=csrf",
            .lithosAI: "__Host-console_session=fixture; __Host-console_csrf=csrf",
            .tinyApi: "__Secure-authjs.session-token.0=fixture",
            .museAI: "anything=fixture",
        ]
        for (provider, cookie) in cookies {
            let schema = try #require(WindowsProviderConfigurationCatalog.byProvider[provider])
            #expect(schema.automaticExecutionMode == .usage)
            #expect(schema.manualCredentialSets.map(\.id) == ["browser-session"])
            let staged = try Self.stage(provider, "browser-session", ["cookieHeader": cookie])
            #expect(staged["source"] as? String == "web")
            #expect(staged["cookieSource"] as? String == "manual")
            #expect(staged["cookieHeader"] as? String == cookie)
        }
    }

    @Test
    func `browser sessions require the cookies upstream needs`() throws {
        let xAPI = try Self.field(.xAPI, "browser-session", "cookieHeader")
        #expect(!xAPI.accepts("auth_token=fixture"))
        #expect(xAPI.accepts("auth_token=fixture; ct0=csrf"))

        let lithos = try Self.field(.lithosAI, "browser-session", "cookieHeader")
        #expect(!lithos.accepts("__Host-console_session=fixture"))

        let replicate = try Self.field(.replicate, "browser-session", "cookieHeader")
        #expect(!replicate.accepts("csrftoken=x"))

        let tinyApi = try Self.field(.tinyApi, "browser-session", "cookieHeader")
        #expect(tinyApi.accepts("__Secure-authjs.session-token=fixture"))
        #expect(!tinyApi.accepts("other=fixture"))
    }

    @Test
    func `provider-owned sign-ins need no saved credential`() {
        let expected: [WindowsProviderID: WindowsProviderConfigurationCatalog.ProviderAppOrCLIEvidence] = [
            .codeRabbit: .providerCLI,
            .nous: .providerOwnedAuthenticationState,
            .muse: .providerOwnedAuthenticationState,
        ]
        for (provider, evidence) in expected {
            #expect(WindowsProviderID.supportedProviders.contains(provider))
            #expect(WindowsProviderConfigurationCatalog.providerAppOrCLIEvidence[provider] == evidence)
            #expect(WindowsProviderConfigurationCatalog.byProvider[provider] == nil)
            #expect(WindowsProviderCapabilityPresentation.summary(provider: provider) == "Provider app/CLI")
        }
    }

    @Test
    func `routes the Linux CLI cannot run are unavailable with an explanation`() throws {
        for provider in [WindowsProviderID.helmcode, .langdock, .workBuddy] {
            let info = try #require(WindowsProviderConfigurationCatalog.unavailableInfo(for: provider))
            #expect(!info.removedUpstream)
            #expect(!WindowsProviderID.supportedProviders.contains(provider))
            #expect(WindowsProviderConfigurationCatalog.byProvider[provider] == nil)
            #expect(WindowsProviderCapabilityPresentation.summary(provider: provider) == "Unavailable on Windows")
        }
    }

    @Test
    func `FLORA promotes its available balance and keeps the other rows`() throws {
        let json = #"""
        [{"provider":"flora","source":"api","usage":{"details":[{"title":"Workspace balance","rows":[
          {"label":"Available","value":"$25.00","secondaryValue":"Workspace pool"},
          {"label":"Spent this month","value":"$4.00"}
        ]}]}}]
        """#
        let snapshot = try WindowsCanonicalCLIProviderClient.decode(
            data: Data(json.utf8),
            requestedProvider: .flora,
            sourceText: "WSL CLI · Ubuntu")
        #expect(snapshot.balanceText == "$25.00 remaining")
        #expect(
            snapshot.detailSections == [
                .init(title: "Workspace balance", rows: [.init(label: "Spent this month", value: "$4.00")]),
            ])
    }

    private static func field(
        _ provider: WindowsProviderID,
        _ setID: String,
        _ fieldID: String) throws -> WindowsProviderConfigurationField
    {
        let set = try #require(
            WindowsProviderConfigurationCatalog.byProvider[provider]?.credentialSets.first { $0.id == setID })
        return try #require(set.fields.first { $0.id == fieldID })
    }

    private static func stage(
        _ provider: WindowsProviderID,
        _ setID: String,
        _ values: [String: String]) throws -> [String: Any]
    {
        let record = WindowsProviderCredentialRecord(provider: provider, credentialSetID: setID, values: values)
        let data = try WindowsStagedProviderConfig.encodeManual(provider: provider, record: record).data
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let providers = try #require(object["providers"] as? [[String: Any]])
        return try #require(providers.first)
    }
}
#endif
