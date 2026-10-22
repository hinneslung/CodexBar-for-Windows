import Foundation

/// Upstream API-key plugin providers. The Linux CLI runs each through its API source with the key from the staged
/// config.
extension WindowsProviderConfigurationCatalog {
    static var pluginProviderSchemas: [WindowsProviderConfigurationSchema] {
        [
            // Provider-specific by design: Declare each plugin provider's staged API-key contract.
            apiSchema(.huggingFace, "huggingface", apiKeyField: huggingFaceToken),
            apiSchema(.v0, "v0", companions: [v0Scope]),
            apiSchema(.devPass, "devpass", apiKeyField: devPassKey),
            apiSchema(.atlasCloud, "atlascloud"),
            apiSchema(
                .vercel,
                "vercel",
                additionalSets: [vercelAccessTokenSet],
                apiKeyField: vercelGatewayKey),
            apiSchema(.xKiro, "xkiro"),
            apiSchema(.tavily, "tavily"),
            apiSchema(.linkup, "linkup"),
            apiSchema(.aerostack, "aerostack", apiKeyField: aerostackToken),
            apiSchema(.sailResearch, "sailresearch"),
            apiSchema(.sofya, "sofya"),
            apiSchema(.fal, "fal", apiKeyField: falKey),
            apiSchema(.munito, "munito", apiKeyField: munitoKey),
        ]
    }

    /// Provider-specific by design: Key labels and guidance for upstream plugin providers whose key is not a plain API
    /// key, mirroring each upstream provider guide.
    private static func pluginKey(
        label: String = "API key",
        placeholder: String = "Paste API key",
        guidance: String) -> WindowsProviderConfigurationField
    {
        WindowsProviderConfigurationField(
            id: "apiKey",
            storage: .apiKey,
            label: label,
            placeholder: placeholder,
            guidance: guidance,
            style: .secureSingleLine,
            required: true,
            validation: .secret)
    }

    private static let huggingFaceToken = Self.pluginKey(
        label: "Access token",
        placeholder: "hf_…",
        guidance: "A read token works. Fine-grained tokens need the Billing read permission.")

    private static let falKey = Self.pluginKey(
        guidance: "Use a key with billing read access: the Billing, Read only, or Full preset.")

    private static let devPassKey = Self.pluginKey(guidance: "Use a regular LLM Gateway API key.")

    private static let munitoKey = Self.pluginKey(
        label: "Admin API key",
        placeholder: "Paste Admin API key",
        guidance: "Needs the Read account data permission.")

    private static let aerostackToken = Self.pluginKey(
        label: "Account token",
        placeholder: "Paste account token",
        guidance: "Your Aerostack account token, not an aek_ Agent Endpoint key. CodexBar does not refresh it.")

    private static let vercelGatewayKey = Self.pluginKey(
        label: "AI Gateway API key",
        placeholder: "Paste AI Gateway API key",
        guidance: "Shows team credits. Choose Access token instead for your personal budget.")

    private static let v0Scope = WindowsProviderConfigurationField(
        id: "workspaceID",
        storage: .workspaceID,
        label: "Scope (optional)",
        placeholder: "Project ID or slug",
        guidance: "Leave blank for the key's default scope.",
        style: .plainText,
        required: false,
        validation: .nonempty)

    /// Provider-specific by design: Vercel's budget route reads an access token from upstream's plugin secrets and the
    /// team from workspaceID. Upstream prefers it over a gateway key, so the two stay separate credential choices.
    private static var vercelAccessTokenSet: WindowsProviderCredentialSet {
        .init(
            id: "access-token",
            label: "Access token",
            source: "api",
            acceptsManual: true,
            acceptsOpenCode: false,
            derivesManualCookieSource: false,
            fields: [
                .init(
                    id: "vercelAccessToken",
                    storage: .vercelAccessToken,
                    label: "Access token",
                    placeholder: "Paste Vercel access token",
                    guidance: "Shows your personal AI Gateway budget for the team.",
                    style: .secureSingleLine,
                    required: true,
                    validation: .secret),
                .init(
                    id: "workspaceID",
                    storage: .workspaceID,
                    label: "Team ID",
                    placeholder: "team_…",
                    guidance: "Copy it from the team's Settings > General page.",
                    style: .plainText,
                    required: true,
                    validation: .vercelTeamID),
            ],
            role: .alternateRoute)
    }
}
