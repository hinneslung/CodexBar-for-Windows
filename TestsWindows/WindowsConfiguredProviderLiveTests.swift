#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

@Suite("Windows configured provider live checks")
struct WindowsConfiguredProviderLiveTests {
    @Test
    func `configured providers resolve through the canonical CLI runtime`() async throws {
        guard ProcessInfo.processInfo.environment["CODEXBAR_LIVE_PROVIDER_TESTS"] == "1" else {
            return
        }
        let store = try WindowsConfigurationStore()
        // Key by profile: one provider can have several profiles, such as two Codex accounts.
        let enabled = try store.load().providers.filter(\.enabled)
        let snapshots = await WindowsConfiguredProviderDataSource(store: store)
            .fetchProviderSnapshots()
        let byProfile = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.profileID, $0) })

        #expect(Set(byProfile.keys) == Set(enabled.map(\.profileID)))
        for profile in enabled {
            let snapshot = try #require(byProfile[profile.profileID])
            let failure = snapshot.safeErrorText ?? "unavailable"
            #expect(
                snapshot.availability == .available,
                "\(profile.id.displayName) (\(profile.profileName)): \(failure)")
        }
    }
}
#endif
