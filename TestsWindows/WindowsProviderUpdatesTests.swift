#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

/// Provider routes aligned with the upstream v0.78.0 Linux CLI.
@Suite("Windows provider updates for upstream v0.78.0")
struct WindowsProviderUpdatesTests {
    @Test
    func `Claude browser session requires a sessionKey cookie and stages a manual web source`() throws {
        let set = try Self.set(.claude, "browser-session")
        let field = try #require(set.fields.first)
        #expect(field.accepts("sessionKey=sk-ant-fixture; theme=dark"))
        #expect(!field.accepts("theme=dark"))

        let payload = try Self.stage(.claude, set, ["cookieHeader": "sessionKey=sk-ant-fixture"])
        #expect(payload["source"] as? String == "web")
        #expect(payload["cookieSource"] as? String == "manual")
        #expect(payload["cookieHeader"] as? String == "sessionKey=sk-ant-fixture")
    }

    @Test
    func `Devin stages its bearer token and organization as a manual session`() throws {
        #expect(WindowsProviderConfigurationCatalog.unavailableInfo(for: .devin) == nil)
        let set = try Self.set(.devin, "bearer-token")
        #expect(set.fields.map(\.storage) == [.cookieHeader, .workspaceID])
        #expect(set.fields.filter { !$0.required }.isEmpty)

        let payload = try Self.stage(
            .devin,
            set,
            ["cookieHeader": "Bearer fixture-devin-token", "workspaceID": "org-fixture"])
        #expect(payload["source"] as? String == "web")
        #expect(payload["cookieSource"] as? String == "manual")
        #expect(payload["cookieHeader"] as? String == "Bearer fixture-devin-token")
        #expect(payload["workspaceID"] as? String == "org-fixture")
    }

    @Test
    func `Mistral manual sessions run normal usage with only an ory session cookie`() throws {
        let schema = try #require(WindowsProviderConfigurationCatalog.byProvider[.mistral])
        #expect(schema.automaticExecutionMode == .usage)
        let set = try Self.set(.mistral, "browser-session")
        #expect(set.executionMode == .usage)
        #expect(try #require(set.fields.first).accepts("ory_session_fixture=abc"))
    }

    @Test
    func `Command Code accepts a saved API key`() throws {
        let set = try Self.set(.commandCode, "api-key")
        #expect(set.acceptsManual)
        #expect(try Self.stage(.commandCode, set, ["apiKey": "fixture-command-code"])["apiKey"] as? String
            == "fixture-command-code")
    }

    @Test
    func `Kimi region is optional and limited to upstream values`() throws {
        let api = try Self.set(.kimi, "api-key")
        let region = try #require(api.fields.first { $0.storage == .region })
        #expect(!region.required)
        #expect(region.accepts("international"))
        #expect(region.accepts("china"))
        #expect(!region.accepts("global"))

        #expect(try Self.stage(.kimi, api, ["apiKey": "fixture-kimi"])["region"] == nil)
        #expect(
            try Self.stage(.kimi, api, ["apiKey": "fixture-kimi", "region": "international"])["region"] as? String
                == "international")
    }

    @Test
    func `Kimi browser session accepts a kimi-auth cookie or the bare token`() throws {
        let field = try #require(Self.set(.kimi, "browser-session").fields.first)
        #expect(field.normalized("fixture-kimi-token") == "kimi-auth=fixture-kimi-token")
        #expect(field.normalized("Cookie: kimi-auth=fixture") == "kimi-auth=fixture")
        #expect(field.normalized("theme=dark") == nil)
    }

    @Test
    func `Notion workspace ID is optional and staged when set`() throws {
        let set = try Self.set(.notion, "browser-session")
        #expect(set.executionMode == .diagnose)
        let workspace = try #require(set.fields.first { $0.storage == .workspaceID })
        #expect(!workspace.required)
        let payload = try Self.stage(.notion, set, ["cookieHeader": "token_v2=fixture", "workspaceID": "fixture-ws"])
        #expect(payload["workspaceID"] as? String == "fixture-ws")
    }

    @Test
    func `Azure OpenAI API version is staged only when set`() throws {
        let set = try Self.set(.azureOpenAI, "api-key")
        let base = [
            "apiKey": "fixture-azure",
            "enterpriseHost": "https://fixture.openai.azure.com",
            "workspaceID": "fixture-deployment",
        ]
        #expect(try Self.stage(.azureOpenAI, set, base)["azureOpenAIAPIVersion"] == nil)
        var versioned = base
        versioned["azureOpenAIAPIVersion"] = "v1"
        #expect(try Self.stage(.azureOpenAI, set, versioned)["azureOpenAIAPIVersion"] as? String == "v1")
    }

    @Test
    func `z.ai region is optional for saved keys and limited to upstream values`() throws {
        let region = try #require(Self.set(.zai, "api-key").fields.first { $0.storage == .region })
        #expect(!region.required)
        #expect(region.accepts("bigmodel-cn"))
        #expect(region.accepts("global"))
        #expect(!region.accepts("china"))
    }

    @Test
    func `OpenCode BigModel keys stage the bigmodel-cn region for z.ai`() throws {
        let bridge = WindowsProviderCredentialBridge(authDataLoader: { _ in
            Data(#"{"zhipuai":{"type":"api","key":"fixture-zhipu"}}"#.utf8)
        })
        let projection = try bridge.projection(for: .zai, base: [:])
        let config = try WindowsStagedProviderConfig.encodeBridge(
            provider: .zai,
            companionValues: projection.companionValues)
        let payload = try Self.provider(config)
        #expect(payload["region"] as? String == "bigmodel-cn")
        #expect(payload["apiKey"] == nil)
        #expect(projection.environment["ZHIPU_API_KEY"] == "fixture-zhipu")
    }

    @Test
    func `Cursor and ClinePass declare their Linux sign-in routes`() {
        let evidence = WindowsProviderConfigurationCatalog.providerAppOrCLIEvidence
        #expect(evidence[.cursor] == .providerCLI)
        #expect(evidence[.clinePass] == .providerOwnedAuthenticationState)
    }

    @Test
    func `Zed and Abacus explain that the Linux CLI rejects their browser routes`() throws {
        let zed = try #require(WindowsProviderConfigurationCatalog.unavailableInfo(for: .zed))
        let abacus = try #require(WindowsProviderConfigurationCatalog.unavailableInfo(for: .abacus))
        #expect(zed.explanation.contains("Linux CLI"))
        #expect(abacus.explanation.contains("Linux CLI"))
    }

    private static func set(_ provider: WindowsProviderID, _ id: String) throws -> WindowsProviderCredentialSet {
        try #require(WindowsProviderConfigurationCatalog.byProvider[provider]?.credentialSets.first { $0.id == id })
    }

    private static func stage(
        _ provider: WindowsProviderID,
        _ set: WindowsProviderCredentialSet,
        _ values: [String: String]) throws -> [String: Any]
    {
        let record = WindowsProviderCredentialRecord(provider: provider, credentialSetID: set.id, values: values)
        return try self.provider(WindowsStagedProviderConfig.encodeManual(provider: provider, record: record).data)
    }

    private static func provider(_ data: Data) throws -> [String: Any] {
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let providers = try #require(object["providers"] as? [[String: Any]])
        return try #require(providers.first)
    }
}
#endif
