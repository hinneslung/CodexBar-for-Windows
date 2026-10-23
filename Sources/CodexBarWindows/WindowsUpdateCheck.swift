import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A Windows fork version such as `0.78.0-windows.5`, optionally with a prerelease suffix (`-rc`).
struct WindowsAppVersion: Comparable, Sendable, CustomStringConvertible {
    let upstream: [Int]
    let windowsRevision: Int
    let prerelease: String?

    /// Accepts `MAJOR.MINOR.PATCH-windows.N[-SUFFIX]`, with an optional leading `v`.
    init?(_ raw: String) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("v") { text.removeFirst() }
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2 || parts.count == 3 else { return nil }
        let components = parts[0].split(separator: ".", omittingEmptySubsequences: false)
        let numbers = components.compactMap(Self.number)
        guard components.count == 3, numbers.count == 3 else { return nil }
        let windowsPrefix = "windows."
        guard parts[1].hasPrefix(windowsPrefix),
              let revision = Self.number(parts[1].dropFirst(windowsPrefix.count))
        else { return nil }
        var prerelease: String?
        if parts.count == 3 {
            let suffix = parts[2]
            let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "."))
            guard !suffix.isEmpty, suffix.unicodeScalars.allSatisfy({ $0.isASCII && allowed.contains($0) })
            else { return nil }
            prerelease = String(suffix)
        }
        self.upstream = numbers
        self.windowsRevision = revision
        self.prerelease = prerelease
    }

    var description: String {
        let base = "\(self.upstream.map(String.init).joined(separator: "."))-windows.\(self.windowsRevision)"
        return self.prerelease.map { "\(base)-\($0)" } ?? base
    }

    /// Orders by upstream version, then Windows revision; a prerelease precedes its release.
    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.upstream != rhs.upstream { return lhs.upstream.lexicographicallyPrecedes(rhs.upstream) }
        if lhs.windowsRevision != rhs.windowsRevision { return lhs.windowsRevision < rhs.windowsRevision }
        switch (lhs.prerelease, rhs.prerelease) {
        case (.some, .none): return true
        case let (.some(left), .some(right)): return left < right
        default: return false
        }
    }

    private static func number(_ text: Substring) -> Int? {
        guard !text.isEmpty, text.count <= 9, text.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
        return Int(text)
    }
}

/// A newer published release, ready to show in the dashboard.
struct WindowsAvailableUpdate: Equatable, Sendable {
    let version: WindowsAppVersion
    let releaseURL: URL
}

/// Checks the fork's latest GitHub release. Only the release page is opened; nothing is downloaded or installed.
enum WindowsUpdateCheck {
    static let latestReleaseAPIURL =
        URL(string: "https://api.github.com/repos/hinneslung/CodexBar-for-Windows/releases/latest")!
    static let releasesPageURL = URL(string: "https://github.com/hinneslung/CodexBar-for-Windows/releases")!
    static let firstCheckDelaySeconds = 60
    static let checkIntervalSeconds = 24 * 60 * 60
    private static let releasesPath = "/hinneslung/CodexBar-for-Windows/releases"
    private static let maximumResponseBytes = 512 * 1024

    /// The packaged version from `VERSION` next to the executable. Development builds have none and skip checks.
    static func currentVersion(
        directory: URL? = Bundle.main.executableURL?.deletingLastPathComponent()) -> WindowsAppVersion?
    {
        guard let file = directory?.appendingPathComponent("VERSION", isDirectory: false),
              let data = try? Data(contentsOf: file),
              data.count <= 256,
              let text = String(data: data, encoding: .utf8)
        else { return nil }
        return WindowsAppVersion(text)
    }

    /// The release to offer, if the latest published release is newer than `current`.
    static func availableUpdate(current: WindowsAppVersion, latestRelease data: Data) -> WindowsAvailableUpdate? {
        guard data.count <= self.maximumResponseBytes,
              let release = try? JSONDecoder().decode(LatestRelease.self, from: data),
              release.draft != true, release.prerelease != true,
              let tag = release.tagName,
              let version = WindowsAppVersion(tag), version.prerelease == nil,
              version > current
        else { return nil }
        let pageURL = release.htmlURL.flatMap(URL.init(string:)).flatMap { self.isTrustedReleaseURL($0) ? $0 : nil }
        return WindowsAvailableUpdate(version: version, releaseURL: pageURL ?? self.releasesPageURL)
    }

    /// Only HTTPS pages under this fork's GitHub releases are opened.
    static func isTrustedReleaseURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              components.host?.lowercased() == "github.com",
              components.user == nil, components.password == nil, components.port == nil
        else { return false }
        let path = components.path
        return path == self.releasesPath || path.hasPrefix(self.releasesPath + "/")
    }

    static func request(currentVersion: WindowsAppVersion) -> URLRequest {
        var request = URLRequest(url: self.latestReleaseAPIURL, cachePolicy: .reloadIgnoringLocalCacheData)
        request.timeoutInterval = 20
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CodexBar-for-Windows/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        return request
    }

    /// Fetches the latest release document. Any failure yields nil; the next scheduled check retries.
    static func fetchLatestRelease(currentVersion: WindowsAppVersion) async -> Data? {
        let request = self.request(currentVersion: currentVersion)
        return await withCheckedContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil, let data, data.count <= self.maximumResponseBytes,
                      (response as? HTTPURLResponse)?.statusCode == 200
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: data)
            }
            task.resume()
        }
    }

    private struct LatestRelease: Decodable {
        let tagName: String?
        let htmlURL: String?
        let draft: Bool?
        let prerelease: Bool?

        private enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case draft
            case prerelease
        }
    }
}
