#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

@Suite("Windows update check")
struct WindowsUpdateCheckTests {
    @Test
    func `fork versions parse with an optional v and prerelease suffix`() throws {
        let release = try #require(WindowsAppVersion("v0.78.0-windows.5"))
        #expect(release.upstream == [0, 78, 0])
        #expect(release.windowsRevision == 5)
        #expect(release.prerelease == nil)
        #expect(release.description == "0.78.0-windows.5")

        let candidate = try #require(WindowsAppVersion("0.78.0-windows.5-rc\n"))
        #expect(candidate.prerelease == "rc")
        #expect(candidate.description == "0.78.0-windows.5-rc")

        for invalid in [
            "", "0.78.0", "0.78-windows.5", "0.78.0.1-windows.5", "0.78.0-win.5", "0.78.0-windows.",
            "0.78.0-windows.+5", "0.78.0-windows.5-", "0.78.0-windows.5-rc-1", "0.x.0-windows.5",
            "0.78.0-windows.5-r c",
        ] {
            #expect(WindowsAppVersion(invalid) == nil, "\(invalid) should not parse")
        }
    }

    @Test
    func `versions order by upstream, then Windows revision, then prerelease`() throws {
        func version(_ text: String) throws -> WindowsAppVersion {
            try #require(WindowsAppVersion(text))
        }
        #expect(try version("0.78.0-windows.5") < version("0.78.0-windows.6"))
        #expect(try version("0.78.0-windows.9") < version("0.79.0-windows.1"))
        #expect(try version("0.9.0-windows.1") < version("0.10.0-windows.1"))
        #expect(try version("0.78.0-windows.5-rc") < version("0.78.0-windows.5"))
        #expect(try version("0.78.0-windows.5") == version("v0.78.0-windows.5"))
        #expect(try !(version("0.78.0-windows.5") < version("0.78.0-windows.5")))
    }

    @Test
    func `the packaged VERSION file is the current version; development builds have none`() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("codexbar-update-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(WindowsUpdateCheck.currentVersion(directory: directory) == nil)
        let file = directory.appendingPathComponent("VERSION")
        try Data("0.78.0-windows.5\r\n".utf8).write(to: file)
        #expect(WindowsUpdateCheck.currentVersion(directory: directory)?.description == "0.78.0-windows.5")
        try Data("dev".utf8).write(to: file)
        #expect(WindowsUpdateCheck.currentVersion(directory: directory) == nil)
        #expect(WindowsUpdateCheck.currentVersion(directory: nil) == nil)
    }

    @Test
    func `a newer published release is offered with its release page`() throws {
        let current = try #require(WindowsAppVersion("0.78.0-windows.5"))
        let update = try #require(
            WindowsUpdateCheck.availableUpdate(
                current: current,
                latestRelease: Self.release(tag: "v0.78.0-windows.6")))
        #expect(update.version.description == "0.78.0-windows.6")
        #expect(
            update.releaseURL.absoluteString
                == "https://github.com/hinneslung/CodexBar-for-Windows/releases/tag/v0.78.0-windows.6")
    }

    @Test
    func `the same, older, draft, or prerelease versions are not offered`() throws {
        let current = try #require(WindowsAppVersion("0.78.0-windows.5"))
        let cases = [
            Self.release(tag: "v0.78.0-windows.5"),
            Self.release(tag: "v0.78.0-windows.4"),
            Self.release(tag: "v0.78.0-windows.6", draft: true),
            Self.release(tag: "v0.78.0-windows.6", prerelease: true),
            Self.release(tag: "v0.78.0-windows.6-rc"),
            Self.release(tag: "nightly"),
            Data(#"{"html_url":"https://github.com/hinneslung/CodexBar-for-Windows/releases"}"#.utf8),
            Data(#"{"tag_name":6}"#.utf8),
            Data("not json".utf8),
            Data(repeating: 32, count: 600 * 1024),
        ]
        for data in cases {
            #expect(WindowsUpdateCheck.availableUpdate(current: current, latestRelease: data) == nil)
        }
    }

    @Test
    func `a release candidate build is offered the final release`() throws {
        let candidate = try #require(WindowsAppVersion("0.78.0-windows.6-rc"))
        let update = WindowsUpdateCheck.availableUpdate(
            current: candidate,
            latestRelease: Self.release(tag: "v0.78.0-windows.6"))
        #expect(update?.version.description == "0.78.0-windows.6")
    }

    @Test
    func `an untrusted release link falls back to the releases page`() throws {
        let current = try #require(WindowsAppVersion("0.78.0-windows.5"))
        for link in [
            "https://evil.example/hinneslung/CodexBar-for-Windows/releases/tag/x",
            "http://github.com/hinneslung/CodexBar-for-Windows/releases/tag/x",
            "https://github.com/someone/CodexBar-for-Windows/releases/tag/x",
            "not a url",
        ] {
            let update = WindowsUpdateCheck.availableUpdate(
                current: current,
                latestRelease: Self.release(tag: "v0.78.0-windows.6", link: link))
            #expect(update?.releaseURL == WindowsUpdateCheck.releasesPageURL)
        }
    }

    @Test
    func `only this fork's HTTPS release pages are trusted`() throws {
        let trusted = [
            "https://github.com/hinneslung/CodexBar-for-Windows/releases",
            "https://github.com/hinneslung/CodexBar-for-Windows/releases/tag/v0.78.0-windows.6",
            "https://GitHub.com/hinneslung/CodexBar-for-Windows/releases/latest",
        ]
        let untrusted = [
            "https://github.com/hinneslung/CodexBar-for-Windows",
            "https://github.com/hinneslung/CodexBar-for-Windows/releasesx",
            "https://github.com:8443/hinneslung/CodexBar-for-Windows/releases",
            "https://user@github.com/hinneslung/CodexBar-for-Windows/releases",
            "file:///C:/Windows/System32/cmd.exe",
        ]
        for link in trusted {
            #expect(try WindowsUpdateCheck.isTrustedReleaseURL(#require(URL(string: link))), "\(link)")
        }
        for link in untrusted {
            #expect(try !WindowsUpdateCheck.isTrustedReleaseURL(#require(URL(string: link))), "\(link)")
        }
    }

    @Test
    func `the request asks GitHub's API for the latest release and names the app`() throws {
        let request = try WindowsUpdateCheck.request(currentVersion: #require(WindowsAppVersion("0.78.0-windows.5")))
        #expect(
            request.url?.absoluteString
                == "https://api.github.com/repos/hinneslung/CodexBar-for-Windows/releases/latest")
        #expect(request.httpMethod == nil || request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "CodexBar-for-Windows/0.78.0-windows.5")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func `update checks are on by default and the choice round-trips`() throws {
        let legacy = try JSONDecoder().decode(
            WindowsAppConfiguration.self,
            from: Data(#"{"schemaVersion":8,"providers":[]}"#.utf8))
        #expect(legacy.checkForUpdates)
        #expect(WindowsAppConfiguration.defaults.checkForUpdates)

        var configuration = WindowsAppConfiguration.defaults
        configuration.checkForUpdates = false
        let decoded = try JSONDecoder().decode(
            WindowsAppConfiguration.self,
            from: JSONEncoder().encode(configuration))
        #expect(!decoded.checkForUpdates)
    }

    private static func release(
        tag: String,
        draft: Bool = false,
        prerelease: Bool = false,
        link: String? = nil) -> Data
    {
        let page = link ?? "https://github.com/hinneslung/CodexBar-for-Windows/releases/tag/\(tag)"
        let json = """
        {"tag_name":"\(tag)","html_url":"\(page)","draft":\(draft),"prerelease":\(prerelease),"name":"\(tag)"}
        """
        return Data(json.utf8)
    }
}
#endif
