// Offline QA entry point. Compile with the real Windows sources instead of WindowsMain.swift.
// It never loads the user's configuration, credential vault, or provider data source.
import Foundation
import WinSDK

@main
enum ResetOverviewSmoke {
    static func main() throws {
        _ = SetProcessDPIAware()
        let scenario = CommandLine.arguments.dropFirst().first ?? "days-hours"
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexBar/qa/reset-overview", isDirectory: true)
        let store = WindowsConfigurationStore(fileURL: directory.appendingPathComponent("config.json"))
        let profiles = [
            WindowsProviderConfiguration(
                id: .codex, profileID: .init(rawValue: "smoke-work"),
                profileName: "Work", enabled: true, order: 0),
            WindowsProviderConfiguration(
                id: .codex, profileID: .init(rawValue: "smoke-personal"),
                profileName: "Personal", enabled: true, order: 1),
            WindowsProviderConfiguration(id: .claude, enabled: true, order: 2),
        ]
        try store.save(WindowsAppConfiguration(providers: profiles))
        let now = Date()
        let offsets: [[TimeInterval?]] = switch scenario {
        case "minutes-no-expiry": [[20 * 60 + 45], [nil]]
        case "empty-multiple": [[], [2 * 3600 + 1800, 5 * 86400 + 3600]]
        default: [[5 * 86400 + 3600], [2 * 3600 + 1800]]
        }
        var snapshots = try profiles.prefix(2).enumerated().map { index, profile in
            try self.decode(
                profile: profile,
                plan: index == 0 ? "Business" : "Pro",
                expiries: offsets[index].map { $0.map { now.addingTimeInterval($0) } },
                now: now)
        }
        // Deliberately includes reset inventory for Claude: it must stay hidden.
        snapshots.append(try self.decode(profile: profiles[2], plan: "Pro", expiries: [nil], now: now))
        let fixtureSnapshots = snapshots
        let source = AnyWindowsProviderDataSource { fixtureSnapshots }
        let application = WindowsTrayApplication(
            dataSource: source,
            configurationStore: store,
            credentialRouteResolver: .init(credentialVault: nil),
            providerConfigurationClient: WindowsProviderConfigurationClient(vault: nil),
            showPopupOnStart: true)
        ExitProcess(UINT(application.run()))
    }

    private static func decode(
        profile: WindowsProviderConfiguration,
        plan: String,
        expiries: [Date?],
        now: Date) throws -> WindowsProviderSnapshot
    {
        let formatter = ISO8601DateFormatter()
        let credits: [[String: Any]] = expiries.map { expiry in
            ["status": "available", "expires_at": expiry.map { formatter.string(from: $0) } as Any? ?? NSNull()]
        }
        let payload: [String: Any] = [
            "provider": profile.id.rawValue,
            "source": "oauth",
            "usage": [
                "primary": [
                    "usedPercent": 21,
                    "resetsAt": formatter.string(from: now.addingTimeInterval(3 * 3600 + 1800)),
                ],
                "identity": ["loginMethod": plan],
                "updatedAt": formatter.string(from: now),
                "codexResetCredits": ["credits": credits, "availableCount": credits.count],
            ],
            "credits": ["remaining": 0, "balanceReadSucceeded": true],
        ]
        return try WindowsCanonicalCLIProviderClient.decode(
            data: JSONSerialization.data(withJSONObject: payload),
            requestedProvider: profile.id,
            sourceText: "Offline QA fixture").assigningProfile(profile)
    }
}
