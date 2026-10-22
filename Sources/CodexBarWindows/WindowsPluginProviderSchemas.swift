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
            // Provider-specific by design: Keys paired with the workspace, project, or base URL upstream reads.
            apiSchema(.exa, "exa", companions: [exaKeyID], apiKeyField: exaServiceKey),
            apiSchema(.flora, "flora", companions: [floraWorkspace], apiKeyField: floraKey),
            apiSchema(.cosmic, "cosmic", companions: [cosmicProject], apiKeyField: cosmicToken),
            apiSchema(.gitKraken, "gitkraken", companions: [gitKrakenOrganization], apiKeyField: gitKrakenToken),
            apiSchema(.bifrost, "bifrost", companions: [bifrostBaseURL], apiKeyField: bifrostVirtualKey),
            apiSchema(.aixy, "aixy", companions: [aixyBaseURL]),
            apiSchema(
                .hyper,
                "hyper",
                additionalSets: [browserSet(site: "hyper.charm.land", hosts: ["hyper.charm.land"])]),
            // Provider-specific by design: Browser sessions the Linux CLI accepts as a manual cookie.
            webSchema(
                .claudePlatform,
                "claudeplatform",
                set: browserSet(
                    site: "platform.claude.com",
                    hosts: ["platform.claude.com"],
                    requiredCookieNames: ["sessionKey"])),
            webSchema(
                .replicate,
                "replicate",
                set: browserSet(
                    site: "replicate.com",
                    hosts: ["replicate.com", "www.replicate.com"],
                    requiredCookieNames: ["sessionid"])),
            // Provider-specific by design: Each browser session names the host and cookies upstream requires.
            webSchema(
                .raycast,
                "raycast",
                set: browserSet(
                    site: "raycast.com",
                    hosts: ["www.raycast.com", "raycast.com"],
                    requiredCookieNames: ["__raycast_session"])),
            webSchema(
                .typeSafe,
                "typesafe",
                set: browserSet(site: "console.typesafe.ai", hosts: ["console.typesafe.ai", "typesafe.ai"])),
            webSchema(
                .parallel,
                "parallel",
                set: browserSet(site: "platform.parallel.ai", hosts: ["platform.parallel.ai"])),
            webSchema(
                .xAPI,
                "xapi",
                set: browserSet(
                    site: "console.x.com",
                    hosts: ["console.x.com", "x.com"],
                    requiredCookieNames: ["auth_token", "ct0"],
                    requiresAllCookieNames: true)),
            webSchema(
                .lithosAI,
                "lithosai",
                set: browserSet(
                    site: "console.lithosai.cloud",
                    hosts: ["console.lithosai.cloud"],
                    requiredCookieNames: ["__Host-console_session", "__Host-console_csrf"],
                    requiresAllCookieNames: true)),
            webSchema(
                .tinyApi,
                "tinyapi",
                set: browserSet(
                    site: "tinyapi.rest",
                    hosts: ["tinyapi.rest", "www.tinyapi.rest"],
                    requiredCookieNamePrefixes: ["__Secure-authjs.session-token"])),
            webSchema(
                .museAI,
                "museai",
                set: browserSet(site: "muse.ai", hosts: ["muse.ai", "www.muse.ai"])),
        ]
    }

    private static let exaServiceKey = Self.pluginKey(
        label: "Service key",
        placeholder: "Paste Team Management service key",
        guidance: "The Team Management service key, which can read API key usage.")

    private static let floraKey = Self.pluginKey(guidance: "The key needs billing permission.")

    private static let cosmicToken = Self.pluginKey(
        label: "Personal access token",
        placeholder: "Paste personal access token",
        guidance: "Bucket keys are not supported.")

    private static let gitKrakenToken = Self.pluginKey(
        label: "API token",
        placeholder: "Paste API token",
        guidance: "A GitKraken API token that can read AI usage.")

    private static let bifrostVirtualKey = Self.pluginKey(
        label: "Virtual key",
        placeholder: "Paste virtual key",
        guidance: "The Bifrost virtual key whose quota to show.")

    private static let exaKeyID = WindowsProviderConfigurationField(
        id: "workspaceID",
        storage: .workspaceID,
        label: "API key ID",
        placeholder: "ID of the API key to report on",
        guidance: "The ID of the API key whose usage to show, not the service key.",
        style: .plainText,
        required: true,
        validation: .pathSegment)

    private static let floraWorkspace = WindowsProviderConfigurationField(
        id: "workspaceID",
        storage: .workspaceID,
        label: "Workspace ID",
        placeholder: "ws_…",
        guidance: nil,
        style: .plainText,
        required: true,
        validation: .floraWorkspaceID)

    private static let cosmicProject = WindowsProviderConfigurationField(
        id: "workspaceID",
        storage: .workspaceID,
        label: "Project ID",
        placeholder: "Cosmic project ID",
        guidance: nil,
        style: .plainText,
        required: true,
        validation: .nonempty)

    private static let gitKrakenOrganization = WindowsProviderConfigurationField(
        id: "workspaceID",
        storage: .workspaceID,
        label: "Organization ID (optional)",
        placeholder: "GitKraken organization ID",
        guidance: "Leave blank for your default organization.",
        style: .plainText,
        required: false,
        validation: .printableASCII(maximumLength: 256))

    private static let bifrostBaseURL = WindowsProviderConfigurationField(
        id: "enterpriseHost",
        storage: .enterpriseHost,
        label: "Base URL",
        placeholder: "https://bifrost.example.test",
        guidance: "HTTPS, or HTTP on a local or private network.",
        style: .plainText,
        required: true,
        validation: .privateNetworkHTTPURL)

    private static let aixyBaseURL = WindowsProviderConfigurationField(
        id: "enterpriseHost",
        storage: .enterpriseHost,
        label: "Base URL (optional)",
        placeholder: "https://api.aixy-gateway.com",
        guidance: "Leave blank for the hosted gateway.",
        style: .plainText,
        required: false,
        validation: .privateNetworkBaseURL)

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
