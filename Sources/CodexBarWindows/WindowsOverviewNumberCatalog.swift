import Foundation

/// A usage number the profile page lets the user show or hide in the overview.
struct WindowsOverviewNumberOption: Codable, Equatable, Sendable {
    let key: String
    let label: String
}

/// Remembers each profile's usage numbers from its last successful reading, so the profile page can list them right
/// after a restart, before the first refresh. It stores number names and keys only, never usage values or accounts.
struct WindowsOverviewNumberCatalog: Codable, Equatable, Sendable {
    static let maximumOptionsPerProfile = 32

    private(set) var profiles: [String: [WindowsOverviewNumberOption]]

    init(profiles: [String: [WindowsOverviewNumberOption]] = [:]) {
        self.profiles = profiles
    }

    /// Nil until the profile has had a successful reading; empty when it reports no number that can be hidden.
    func options(for profileID: WindowsProviderProfileID) -> [WindowsOverviewNumberOption]? {
        self.profiles[profileID.rawValue]
    }

    /// The hideable numbers in a reading, in the provider's order. Numbers without a key are always shown.
    static func options(from snapshot: WindowsProviderSnapshot) -> [WindowsOverviewNumberOption] {
        var seen = Set<String>()
        var options: [WindowsOverviewNumberOption] = []
        for window in snapshot.windows {
            guard let key = window.key, seen.insert(key).inserted else { continue }
            options.append(WindowsOverviewNumberOption(key: key, label: window.label))
            if options.count == self.maximumOptionsPerProfile { break }
        }
        return options
    }

    /// Records a successful reading. Returns whether the catalog changed and should be saved.
    @discardableResult
    mutating func record(_ snapshot: WindowsProviderSnapshot) -> Bool {
        guard snapshot.availability == .available else { return false }
        let options = Self.options(from: snapshot)
        guard self.profiles[snapshot.profileID.rawValue] != options else { return false }
        self.profiles[snapshot.profileID.rawValue] = options
        return true
    }

    /// Drops removed profiles. Returns whether the catalog changed.
    @discardableResult
    mutating func retain(_ profileIDs: Set<WindowsProviderProfileID>) -> Bool {
        let kept = Set(profileIDs.map(\.rawValue))
        let filtered = self.profiles.filter { kept.contains($0.key) }
        guard filtered.count != self.profiles.count else { return false }
        self.profiles = filtered
        return true
    }
}

/// Stores the catalog beside `config.json`. It is a cache: a missing or unreadable file starts an empty catalog.
struct WindowsOverviewNumberCatalogStore: Sendable {
    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    init(configurationFileURL: URL) {
        self.fileURL = configurationFileURL.deletingLastPathComponent()
            .appendingPathComponent("overview-numbers.json", isDirectory: false)
    }

    func load() -> WindowsOverviewNumberCatalog {
        guard let data = try? Data(contentsOf: self.fileURL),
              let catalog = try? JSONDecoder().decode(WindowsOverviewNumberCatalog.self, from: data)
        else { return WindowsOverviewNumberCatalog() }
        return catalog
    }

    func save(_ catalog: WindowsOverviewNumberCatalog, fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(catalog).write(to: self.fileURL, options: .atomic)
    }
}
