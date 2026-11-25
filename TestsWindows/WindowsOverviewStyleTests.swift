#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

@Suite("Windows overview styles and selected numbers")
struct WindowsOverviewStyleTests {
    private static func window(_ label: String, used: Double, key: String?) -> WindowsProviderWindowSnapshot {
        WindowsProviderWindowSnapshot(label: label, usedPercent: used, key: key)
    }

    private static func claudeSnapshot(profileID: WindowsProviderProfileID? = nil) -> WindowsProviderSnapshot {
        WindowsProviderSnapshot(
            provider: .claude,
            profileID: profileID,
            availability: .available,
            sourceText: "Automatic",
            windows: [
                self.window("Session", used: 51, key: "primary"),
                self.window("Weekly", used: 26, key: "secondary"),
                self.window("Sonnet weekly", used: 59, key: "extra:sonnet"),
            ])
    }

    private static func row(
        _ snapshot: WindowsProviderSnapshot,
        hidden: [String]) -> WindowsProviderRowPresentation
    {
        let profile = WindowsProviderConfiguration(
            id: snapshot.provider,
            profileID: snapshot.profileID,
            enabled: true,
            order: 0,
            hiddenOverviewWindowKeys: hidden)
        return WindowsDashboardPresentation.makeRow(snapshot: snapshot, profile: profile, distinguishesProfile: false)
    }

    @Test
    func `compact picks the lowest left among selected numbers only`() {
        let all = Self.row(Self.claudeSnapshot(), hidden: [])
        #expect(all.overviewWindows.map(\.label) == ["Session", "Weekly", "Sonnet weekly"])
        #expect(all.governingWindow?.label == "Sonnet weekly")

        let selected = Self.row(Self.claudeSnapshot(), hidden: ["extra:sonnet"])
        #expect(selected.overviewWindows.map(\.label) == ["Session", "Weekly"])
        #expect(selected.governingWindow?.label == "Session")
        // The detail view keeps every number.
        #expect(selected.windows.map(\.label) == ["Session", "Weekly", "Sonnet weekly"])
    }

    @Test
    func `numbers without a key are always shown and nothing selected falls back to all`() {
        let snapshot = WindowsProviderSnapshot(
            provider: .antigravity,
            availability: .available,
            sourceText: "Automatic",
            windows: [
                Self.window("Gemini weekly", used: 12, key: "extra:gemini-weekly"),
                Self.window("Unnamed bucket", used: 40, key: nil),
            ])
        let keyless = Self.row(snapshot, hidden: ["extra:gemini-weekly"])
        #expect(keyless.overviewWindows.map(\.label) == ["Unnamed bucket"])

        // Antigravity drops its standard slots, so stale hidden keys can match nothing: every number is shown.
        let stale = WindowsProviderSnapshot(
            provider: .antigravity,
            availability: .available,
            sourceText: "Automatic",
            windows: [Self.window("Gemini weekly", used: 12, key: "extra:gemini-weekly")])
        let fallback = Self.row(stale, hidden: ["extra:gemini-weekly", "primary"])
        #expect(fallback.overviewWindows.map(\.label) == ["Gemini weekly"])
        #expect(fallback.governingWindow?.label == "Gemini weekly")
    }

    @Test
    func `each profile keeps its own selection and the tooltip follows it`() {
        let personalID = WindowsProviderProfileID(rawValue: "claude-personal")
        let work = WindowsProviderConfiguration(id: .claude, enabled: true, order: 0)
        let personal = WindowsProviderConfiguration(
            id: .claude,
            profileID: personalID,
            profileName: "Personal",
            enabled: true,
            order: 1,
            hiddenOverviewWindowKeys: ["extra:sonnet"])
        let presentation = WindowsDashboardPresentation.make(
            snapshots: [Self.claudeSnapshot(), Self.claudeSnapshot(profileID: personalID)],
            refreshedAt: Date(),
            profiles: [work, personal])
        #expect(presentation.rows.map { $0.governingWindow?.label } == ["Sonnet weekly", "Session"])
        let tooltip = presentation.trayTooltip(showUsed: true)
        #expect(tooltip.contains("59%"))
        #expect(tooltip.contains("51%"))
    }

    @Test
    func `the CLI decoder keys standard slots and extra windows by id`() throws {
        let payload = #"""
        [{
          "provider":"antigravity",
          "usage":{
            "primary":{"usedPercent":10},
            "secondary":{"usedPercent":20},
            "extraRateWindows":[
              {"id":"antigravity-quota-summary-gemini-argon-wtu-weekly","title":"Gemini weekly","usageKnown":true,
               "window":{"usedPercent":63}},
              {"title":"No id","usageKnown":true,"window":{"usedPercent":5}}
            ]
          }
        }]
        """#
        let snapshot = try WindowsCanonicalCLIProviderClient.decode(
            data: Data(payload.utf8),
            requestedProvider: .antigravity,
            sourceText: "WSL CLI")
        // Antigravity drops its standard rows when it reports quota buckets; the Argon row is relabeled, but its
        // key still comes from the CLI id.
        #expect(snapshot.windows.map(\.label) == ["Gemini Argon weekly", "No id"])
        #expect(snapshot.windows.map(\.key) == ["extra:antigravity-quota-summary-gemini-argon-wtu-weekly", nil])

        let standard = try WindowsCanonicalCLIProviderClient.decode(
            data: Data(payload.replacingOccurrences(of: "antigravity", with: "claude").utf8),
            requestedProvider: .claude,
            sourceText: "WSL CLI")
        #expect(standard.windows.map(\.key) == [
            "primary", "secondary", "extra:claude-quota-summary-gemini-argon-wtu-weekly", nil,
        ])
        #expect(WindowsCanonicalCLIProviderClient.overviewKey(forExtraID: "  ") == nil)
    }

    @Test
    func `overview settings decode with defaults and fail soft`() throws {
        let legacy = try JSONDecoder().decode(
            WindowsAppConfiguration.self,
            from: Data(#"{"providers":[{"id":"claude","enabled":true,"order":0}]}"#.utf8))
        #expect(legacy.overviewStyle == .detailed)
        #expect(legacy.providers.first?.hiddenOverviewWindowKeys == [])

        let unknown = try JSONDecoder().decode(
            WindowsAppConfiguration.self,
            from: Data(#"{"overviewStyle":"sideways","providers":[]}"#.utf8))
        #expect(unknown.overviewStyle == .detailed)

        let malformed = try JSONDecoder().decode(
            WindowsProviderConfiguration.self,
            from: Data(#"{"id":"claude","enabled":true,"order":0,"hiddenOverviewWindowKeys":"primary"}"#.utf8))
        #expect(malformed.hiddenOverviewWindowKeys == [])

        var configuration = WindowsAppConfiguration(
            overviewStyle: .compact,
            providers: [
                WindowsProviderConfiguration(
                    id: .claude,
                    enabled: true,
                    order: 0,
                    hiddenOverviewWindowKeys: ["primary", " ", "extra:b", "primary"]),
            ])
        #expect(configuration.providers[0].hiddenOverviewWindowKeys == ["extra:b", "primary"])
        let roundTrip = try JSONDecoder().decode(
            WindowsAppConfiguration.self,
            from: JSONEncoder().encode(configuration))
        #expect(roundTrip.overviewStyle == .compact)
        #expect(roundTrip.providers[0].hiddenOverviewWindowKeys == ["extra:b", "primary"])
        configuration.overviewStyle = configuration.overviewStyle.toggled
        #expect(configuration.overviewStyle == .detailed)
    }

    @Test
    func `changing the overview selection counts as an unsaved change`() {
        let saved = WindowsProviderConfiguration(id: .claude, enabled: true, order: 0)
        var draft = saved
        draft.hiddenOverviewWindowKeys = ["extra:sonnet"]
        #expect(WindowsProviderConfigurationPageState.hasUnsavedChanges(draft: draft, saved: saved))
        #expect(!WindowsTrayApplication.routingChanged(from: saved, to: draft))
    }

    @Test
    func `the number catalog remembers hideable numbers from successful readings`() throws {
        var catalog = WindowsOverviewNumberCatalog()
        let profileID = WindowsProviderProfileID.defaultID(for: .claude)
        #expect(catalog.options(for: profileID) == nil)

        let failed = WindowsProviderSnapshot(provider: .claude, availability: .error, sourceText: "Automatic")
        let recordedFailure = catalog.record(failed)
        #expect(!recordedFailure)

        let snapshot = WindowsProviderSnapshot(
            provider: .claude,
            availability: .available,
            sourceText: "Automatic",
            windows: [
                Self.window("Session", used: 1, key: "primary"),
                Self.window("Duplicate", used: 1, key: "primary"),
                Self.window("Keyless", used: 1, key: nil),
                Self.window("Weekly", used: 1, key: "secondary"),
            ])
        let recorded = catalog.record(snapshot)
        let recordedAgain = catalog.record(snapshot)
        #expect(recorded)
        #expect(!recordedAgain)
        #expect(catalog.options(for: profileID) == [
            WindowsOverviewNumberOption(key: "primary", label: "Session"),
            WindowsOverviewNumberOption(key: "secondary", label: "Weekly"),
        ])

        let balanceOnly = WindowsProviderSnapshot(provider: .poe, availability: .available, sourceText: "Automatic")
        catalog.record(balanceOnly)
        #expect(catalog.options(for: .defaultID(for: .poe)) == [])

        let dropped = catalog.retain([profileID])
        #expect(dropped)
        #expect(catalog.options(for: .defaultID(for: .poe)) == nil)
        let droppedAgain = catalog.retain([profileID])
        #expect(!droppedAgain)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("codexbar-overview-catalog-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WindowsOverviewNumberCatalogStore(
            configurationFileURL: directory.appendingPathComponent("config.json"))
        #expect(store.fileURL.lastPathComponent == "overview-numbers.json")
        #expect(store.load() == WindowsOverviewNumberCatalog())
        try store.save(catalog)
        #expect(store.load() == catalog)
        try Data("not json".utf8).write(to: store.fileURL)
        #expect(store.load() == WindowsOverviewNumberCatalog())
    }
}
#endif
