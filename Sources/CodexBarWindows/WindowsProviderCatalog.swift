import Foundation

/// A stable provider identifier used by the Windows application.
///
/// This is intentionally an open raw-value type instead of an enum so a configuration
/// written by a newer CodexBar can still be decoded by an older build.
struct WindowsProviderID: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    init(from decoder: Decoder) throws {
        try self.init(rawValue: decoder.singleValueContainer().decode(String.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    var description: String {
        self.rawValue
    }
}

struct WindowsProviderCatalogEntry: Hashable, Sendable {
    let id: WindowsProviderID
    let displayName: String
    let searchAliases: [String]
    /// Detail rows upstream presents as the provider's balance (`menuBarBalanceDetailLabels`).
    let balanceDetailLabels: [String]

    init(
        id: WindowsProviderID,
        displayName: String,
        searchAliases: [String] = [],
        balanceDetailLabels: [String] = [])
    {
        self.id = id
        self.displayName = displayName
        self.searchAliases = searchAliases
        self.balanceDetailLabels = balanceDetailLabels
    }
}

/// Windows' upstream-derived provider registry. Keep this in the same order as
/// `UsageProvider` so new configurations and settings screens have deterministic order.
enum WindowsProviderCatalog {
    static let entries: [WindowsProviderCatalogEntry] = [
        .init(
            // Provider-specific by design: Mirror upstream provider IDs, names and order without linking the macOS/Core
            // target.
            id: .codex,
            displayName: "Codex",
            searchAliases: ["ChatGPT"]),
        .init(id: .openai, displayName: "OpenAI"),
        .init(id: .azureOpenAI, displayName: "Azure OpenAI"),
        .init(id: .claude, displayName: "Claude"),
        .init(id: .clinePass, displayName: "ClinePass"),
        .init(id: .cursor, displayName: "Cursor"),
        .init(id: .openCode, displayName: "OpenCode"),
        .init(id: .openCodeGo, displayName: "OpenCode Go"),
        .init(id: .alibaba, displayName: "Alibaba Coding Plan"),
        .init(id: .alibabaTokenPlan, displayName: "Alibaba Token Plan"),
        .init(id: .qwenCloud, displayName: "Qwen Cloud"),
        .init(
            id: .factory,
            displayName: "Droid (Factory)",
            searchAliases: ["Droid", "Factory"]),
        .init(id: .fireworks, displayName: "Fireworks"),
        .init(id: .gemini, displayName: "Gemini"),
        .init(id: .antigravity, displayName: "Antigravity"),
        .init(
            id: .copilot,
            displayName: "Copilot",
            searchAliases: ["GitHub Copilot"]),
        .init(id: .devin, displayName: "Devin"),
        .init(
            id: .zai,
            displayName: "z.ai",
            searchAliases: ["Z AI"]),
        .init(id: .minimax, displayName: "MiniMax"),
        .init(id: .manus, displayName: "Manus"),
        .init(id: .kimi, displayName: "Kimi"),
        .init(id: .kilo, displayName: "Kilo"),
        .init(id: .kiro, displayName: "Kiro"),
        .init(id: .vertexAI, displayName: "Vertex AI"),
        .init(id: .augment, displayName: "Augment"),
        .init(id: .jetBrains, displayName: "JetBrains AI"),
        .init(id: .moonshot, displayName: "Moonshot"),
        .init(id: .amp, displayName: "Amp"),
        .init(id: .t3Chat, displayName: "T3 Chat"),
        .init(id: .langdock, displayName: "Langdock"),
        // Provider-specific by design: Continue the upstream registry mirror used by Windows menus and configuration
        // decoding.
        .init(id: .ollama, displayName: "Ollama"),
        .init(id: .synthetic, displayName: "Synthetic"),
        .init(id: .openRouter, displayName: "OpenRouter"),
        .init(id: .elevenLabs, displayName: "ElevenLabs"),
        .init(id: .warp, displayName: "Warp"),
        .init(id: .windsurf, displayName: "Windsurf"),
        .init(id: .zed, displayName: "Zed"),
        .init(id: .perplexity, displayName: "Perplexity"),
        .init(id: .mimo, displayName: "Xiaomi MiMo"),
        .init(id: .doubao, displayName: "Doubao"),
        .init(id: .sakana, displayName: "Sakana AI"),
        .init(id: .abacus, displayName: "Abacus AI"),
        .init(id: .mistral, displayName: "Mistral"),
        .init(id: .deepSeek, displayName: "DeepSeek"),
        .init(id: .deepInfra, displayName: "DeepInfra"),
        .init(id: .codebuff, displayName: "Codebuff"),
        .init(id: .crof, displayName: "Crof"),
        .init(id: .venice, displayName: "Venice"),
        .init(id: .commandCode, displayName: "Command Code"),
        .init(id: .qoder, displayName: "Qoder"),
        .init(id: .stepFun, displayName: "StepFun"),
        .init(id: .bedrock, displayName: "AWS Bedrock"),
        .init(id: .grok, displayName: "Grok"),
        .init(
            id: .groq,
            displayName: "GroqCloud",
            searchAliases: ["Groq"]),
        .init(id: .llmProxy, displayName: "LLM Proxy"),
        .init(id: .liteLLM, displayName: "LiteLLM"),
        .init(id: .bifrost, displayName: "Bifrost"),
        .init(id: .aixy, displayName: "Aixy"),
        .init(id: .deepgram, displayName: "Deepgram"),
        .init(id: .poe, displayName: "Poe"),
        .init(id: .chutes, displayName: "Chutes"),
        .init(id: .neuralwatt, displayName: "Neuralwatt"),
        .init(id: .helmcode, displayName: "Helmcode"),
        .init(id: .clawRouter, displayName: "ClawRouter"),
        .init(id: .longCat, displayName: "LongCat"),
        .init(id: .sub2API, displayName: "Sub2API"),
        .init(id: .wayfinder, displayName: "Wayfinder"),
        .init(id: .zenMux, displayName: "ZenMux"),
        .init(id: .aiAnd, displayName: "ai&"),
        .init(id: .zoomMate, displayName: "ZoomMate"),
        .init(id: .xAI, displayName: "xAI"),
        .init(id: .xAPI, displayName: "X API", searchAliases: ["xAPI", "Twitter"]),
        // Provider-specific by design: Retain the upstream Notion registry entry and ordering in the Windows-only
        // mirror.
        .init(id: .notion, displayName: "Notion AI"),
        .init(id: .ibmBob, displayName: "IBM Bob"),
        // Provider-specific by design: Upstream plugin and provider-owned routes, in upstream order. Balance-only
        // providers name the detail row upstream's menu bar shows as their balance.
        .init(
            id: .nous,
            displayName: "Nous Portal",
            searchAliases: ["Nous", "Hermes"],
            balanceDetailLabels: ["Total usable", "Top-up credits"]),
        .init(id: .muse, displayName: "Muse Code", searchAliases: ["Muse"]),
        .init(id: .codeRabbit, displayName: "CodeRabbit"),
        .init(id: .replicate, displayName: "Replicate", searchAliases: ["r8"]),
        .init(
            id: .huggingFace,
            displayName: "Hugging Face",
            searchAliases: ["HF"]),
        .init(id: .raycast, displayName: "Raycast"),
        .init(id: .v0, displayName: "v0"),
        .init(id: .typeSafe, displayName: "TypeSafe"),
        .init(id: .hyper, displayName: "Charm Hyper", searchAliases: ["Hyper", "Charm"]),
        .init(id: .gitKraken, displayName: "GitKraken AI", searchAliases: ["GitKraken", "GK"]),
        .init(id: .devPass, displayName: "DevPass", balanceDetailLabels: ["Cycle remaining"]),
        .init(id: .atlasCloud, displayName: "Atlas Cloud", balanceDetailLabels: ["Available balance"]),
        .init(
            id: .vercel,
            displayName: "Vercel AI Gateway",
            searchAliases: ["Vercel"],
            balanceDetailLabels: ["Available balance"]),
        .init(id: .xKiro, displayName: "xKiro"),
        // Provider-specific by design: Continue the upstream-ordered plugin provider registry.
        .init(id: .museAI, displayName: "Muse (muse.ai)", searchAliases: ["muse.ai"]),
        .init(id: .lithosAI, displayName: "LithosAI"),
        .init(id: .workBuddy, displayName: "WorkBuddy"),
        .init(id: .tavily, displayName: "Tavily"),
        .init(id: .linkup, displayName: "Linkup", balanceDetailLabels: ["Credit balance"]),
        .init(id: .tinyApi, displayName: "TinyApi", balanceDetailLabels: ["Available credits"]),
        .init(id: .exa, displayName: "Exa"),
        .init(id: .cosmic, displayName: "Cosmic AI", searchAliases: ["Cosmic"]),
        .init(id: .aerostack, displayName: "Aerostack"),
        .init(id: .sailResearch, displayName: "Sail Research", balanceDetailLabels: ["Credit balance"]),
        .init(id: .sofya, displayName: "Sofya", balanceDetailLabels: ["Available credits"]),
        .init(id: .fal, displayName: "fal", balanceDetailLabels: ["Credit balance"]),
        .init(id: .flora, displayName: "FLORA", balanceDetailLabels: ["Available"]),
        .init(id: .parallel, displayName: "Parallel"),
        .init(id: .claudePlatform, displayName: "Claude Platform", searchAliases: ["Anthropic Console"]),
        .init(id: .munito, displayName: "Munito"),
    ]

    static let byID: [WindowsProviderID: WindowsProviderCatalogEntry] =
        Dictionary(uniqueKeysWithValues: Self.entries.map { ($0.id, $0) })
}

enum WindowsProviderSettingsSearch {
    private static let locale = Locale(identifier: "en_US_POSIX")

    static func filteredDisabledProviders(
        in configuration: WindowsAppConfiguration,
        query: String) -> [WindowsProviderConfiguration]
    {
        configuration.disabledProviders.filter {
            self.matches(provider: $0.id, query: query)
                || self.normalized($0.profileName).contains(self.normalized(query))
        }
    }

    static func matches(provider: WindowsProviderID, query: String) -> Bool {
        let needle = self.normalized(query)
        guard !needle.isEmpty else { return true }
        guard let entry = WindowsProviderCatalog.byID[provider] else {
            return self.normalized(provider.rawValue).contains(needle)
        }
        let values = [entry.displayName, provider.rawValue, provider.cliName] + entry.searchAliases
        return values.contains { self.normalized($0).contains(needle) }
    }

    static func alphabeticalOrder(
        _ lhs: WindowsProviderConfiguration,
        _ rhs: WindowsProviderConfiguration) -> Bool
    {
        let leftName = self.normalized(lhs.id.displayName)
        let rightName = self.normalized(rhs.id.displayName)
        if leftName != rightName { return leftName < rightName }
        let leftProfile = self.normalized(lhs.profileName)
        let rightProfile = self.normalized(rhs.profileName)
        if leftProfile != rightProfile { return leftProfile < rightProfile }
        return lhs.profileID.rawValue < rhs.profileID.rawValue
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: self.locale)
            .lowercased(with: self.locale)
    }
}

extension WindowsProviderID {
    /// Providers enabled in a fresh Windows configuration. This is presentation policy only;
    /// every provider uses the same canonical CLI runtime.
    static var initiallyEnabledProviders: [Self] {
        // Provider-specific by design: Fresh installations enable Codex and Claude as the established Windows
        // presentation default.
        [.codex, .claude]
    }

    /// Providers with a working Windows data path, derived from the explicit unavailable set.
    static var supportedProviders: [Self] {
        WindowsProviderCatalog.entries.map(\.id).filter {
            !WindowsProviderConfigurationCatalog.unavailableProviderIDs.contains($0)
        }
    }

    var displayName: String {
        WindowsProviderCatalog.byID[self]?.displayName ?? self.rawValue
    }

    /// Canonical name accepted by the unchanged upstream CLI. Most match the stable provider ID;
    /// the exceptions are pinned here so every Windows source uses the same argument mapping.
    var cliName: String {
        switch self {
        // Provider-specific by design: Map stable Windows IDs to upstream CLI argument aliases and raw-value constants.
        case .abacus: "abacusai"
        case .alibaba: "alibaba-coding-plan"
        case .alibabaTokenPlan: "alibaba-token-plan"
        case .azureOpenAI: "azure-openai"
        case .groq: "groqcloud"
        case .qwenCloud: "qwen-cloud"
        default: self.rawValue
        }
    }

    static let githubCopilot = Self.copilot
    static let codex = Self(rawValue: "codex")
    static let openai = Self(rawValue: "openai")
    static let azureOpenAI = Self(rawValue: "azureopenai")
    static let claude = Self(rawValue: "claude")
    static let clinePass = Self(rawValue: "clinepass")
    static let cursor = Self(rawValue: "cursor")
    static let openCode = Self(rawValue: "opencode")
    static let openCodeGo = Self(rawValue: "opencodego")
    static let alibaba = Self(rawValue: "alibaba")
    static let alibabaTokenPlan = Self(rawValue: "alibabatokenplan")
    static let qwenCloud = Self(rawValue: "qwencloud")
    static let factory = Self(rawValue: "factory")
    static let gemini = Self(rawValue: "gemini")
    static let antigravity = Self(rawValue: "antigravity")
    static let copilot = Self(rawValue: "copilot")
    static let devin = Self(rawValue: "devin")
    static let zai = Self(rawValue: "zai")
    static let minimax = Self(rawValue: "minimax")
    static let manus = Self(rawValue: "manus")
    static let kimi = Self(rawValue: "kimi")
    static let kilo = Self(rawValue: "kilo")
    static let kiro = Self(rawValue: "kiro")
    static let vertexAI = Self(rawValue: "vertexai")
    static let augment = Self(rawValue: "augment")
    static let jetBrains = Self(rawValue: "jetbrains")
    static let moonshot = Self(rawValue: "moonshot")
    static let amp = Self(rawValue: "amp")
    static let t3Chat = Self(rawValue: "t3chat")
    static let ollama = Self(rawValue: "ollama")
    // Provider-specific by design: Continue the stable raw-value ID definitions required for Windows configuration
    // compatibility.
    static let synthetic = Self(rawValue: "synthetic")
    static let warp = Self(rawValue: "warp")
    static let openRouter = Self(rawValue: "openrouter")
    static let elevenLabs = Self(rawValue: "elevenlabs")
    static let windsurf = Self(rawValue: "windsurf")
    static let zed = Self(rawValue: "zed")
    static let perplexity = Self(rawValue: "perplexity")
    static let mimo = Self(rawValue: "mimo")
    static let doubao = Self(rawValue: "doubao")
    static let sakana = Self(rawValue: "sakana")
    static let abacus = Self(rawValue: "abacus")
    static let mistral = Self(rawValue: "mistral")
    static let deepSeek = Self(rawValue: "deepseek")
    static let fireworks = Self(rawValue: "fireworks")
    static let deepInfra = Self(rawValue: "deepinfra")
    static let codebuff = Self(rawValue: "codebuff")
    static let crof = Self(rawValue: "crof")
    static let venice = Self(rawValue: "venice")
    static let commandCode = Self(rawValue: "commandcode")
    static let qoder = Self(rawValue: "qoder")
    static let stepFun = Self(rawValue: "stepfun")
    static let bedrock = Self(rawValue: "bedrock")
    static let grok = Self(rawValue: "grok")
    static let groq = Self(rawValue: "groq")
    static let llmProxy = Self(rawValue: "llmproxy")
    static let liteLLM = Self(rawValue: "litellm")
    static let deepgram = Self(rawValue: "deepgram")
    static let poe = Self(rawValue: "poe")
    static let chutes = Self(rawValue: "chutes")
    static let neuralwatt = Self(rawValue: "neuralwatt")
    static let clawRouter = Self(rawValue: "clawrouter")
    static let longCat = Self(rawValue: "longcat")
    static let sub2API = Self(rawValue: "sub2api")
    static let wayfinder = Self(rawValue: "wayfinder")
    static let zenMux = Self(rawValue: "zenmux")
    static let aiAnd = Self(rawValue: "aiand")
    static let zoomMate = Self(rawValue: "zoommate")
    static let xAI = Self(rawValue: "xai")
    static let notion = Self(rawValue: "notion")
    static let ibmBob = Self(rawValue: "ibmbob")
    // Provider-specific by design: Stable raw-value IDs for upstream's API-key plugin providers.
    static let huggingFace = Self(rawValue: "huggingface")
    static let v0 = Self(rawValue: "v0")
    static let devPass = Self(rawValue: "devpass")
    static let atlasCloud = Self(rawValue: "atlascloud")
    static let vercel = Self(rawValue: "vercel")
    static let xKiro = Self(rawValue: "xkiro")
    static let tavily = Self(rawValue: "tavily")
    static let linkup = Self(rawValue: "linkup")
    static let aerostack = Self(rawValue: "aerostack")
    static let sailResearch = Self(rawValue: "sailresearch")
    static let sofya = Self(rawValue: "sofya")
    static let fal = Self(rawValue: "fal")
    static let munito = Self(rawValue: "munito")
    // Provider-specific by design: Stable raw-value IDs for upstream plugin and provider-owned routes.
    static let langdock = Self(rawValue: "langdock")
    static let bifrost = Self(rawValue: "bifrost")
    static let aixy = Self(rawValue: "aixy")
    static let helmcode = Self(rawValue: "helmcode")
    static let xAPI = Self(rawValue: "xapi")
    static let nous = Self(rawValue: "nous")
    static let muse = Self(rawValue: "muse")
    static let codeRabbit = Self(rawValue: "coderabbit")
    static let replicate = Self(rawValue: "replicate")
    static let raycast = Self(rawValue: "raycast")
    static let typeSafe = Self(rawValue: "typesafe")
    static let hyper = Self(rawValue: "hyper")
    static let gitKraken = Self(rawValue: "gitkraken")
    static let museAI = Self(rawValue: "museai")
    static let lithosAI = Self(rawValue: "lithosai")
    static let workBuddy = Self(rawValue: "workbuddy")
    static let tinyApi = Self(rawValue: "tinyapi")
    static let exa = Self(rawValue: "exa")
    static let cosmic = Self(rawValue: "cosmic")
    static let flora = Self(rawValue: "flora")
    static let parallel = Self(rawValue: "parallel")
    static let claudePlatform = Self(rawValue: "claudeplatform")
}
