#if canImport(CodexBarWindows)
import Foundation
import Testing
@testable import CodexBarWindows

struct WindowsProviderBrandingTests {
    @Test
    func `every catalog provider maps to a unique atlas cell backed by an upstream logo`() {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let upstreamResources =
            repositoryRoot
                .appendingPathComponent("Sources/CodexBar/Resources", isDirectory: true)

        var usedCells = Set<Int>()
        for entry in WindowsProviderCatalog.entries {
            let reference = WindowsProviderBranding.logo(for: entry.id)
            #expect(usedCells.insert(reference.atlasIndex).inserted, "Shared atlas cell for \(entry.id)")
            #expect(reference.atlasIndex < WindowsProviderBranding.fallbackAtlasIndex)
            #expect(!reference.usesFallback)
            // Providers removed upstream keep their existing atlas artwork; upstream deleted the source SVG.
            guard WindowsProviderConfigurationCatalog.unavailableInfo(for: entry.id)?.removedUpstream != true
            else { continue }
            #expect(
                FileManager.default.fileExists(
                    atPath:
                    upstreamResources
                        .appendingPathComponent("\(reference.upstreamResourceName).svg")
                        .path),
                "Missing upstream logo for \(entry.id)")
        }
    }

    @Test
    func `atlas cells are fixed, cover the catalog exactly, and match the bitmap`() throws {
        let cells = WindowsProviderBranding.atlasCells
        #expect(Set(cells).count == cells.count)
        #expect(Set(cells) == Set(WindowsProviderCatalog.entries.map(\.id)))
        // Cells already shipped never move: catalog changes append artwork instead of shifting it.
        let shipped: [WindowsProviderID] = [.codex, .openai, .azureOpenAI, .claude]
        #expect(Array(cells.prefix(shipped.count)) == shipped)
        #expect(WindowsProviderBranding.logo(for: .crof).atlasIndex == 45)
        #expect(WindowsProviderBranding.logo(for: .ibmBob).atlasIndex == 68)
        #expect(WindowsProviderBranding.logo(for: .huggingFace).atlasIndex == 69)
        #expect(WindowsProviderBranding.logo(for: .munito).atlasIndex == 81)

        let bitmapURL = try #require(
            Bundle.module.url(
                forResource: WindowsProviderBranding.atlasResourceName,
                withExtension: WindowsProviderBranding.atlasResourceExtension))
        let header = try Data(contentsOf: bitmapURL).prefix(26)
        let width = header.subdata(in: 18..<22).withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
        let height = header.subdata(in: 22..<26).withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
        #expect(Int(width) == (cells.count + 1) * Int(WindowsProviderBranding.atlasCellSize))
        #expect(abs(height) == WindowsProviderBranding.atlasCellSize)
    }

    @Test
    func `descriptor aliases reuse their upstream artwork`() {
        #expect(
            WindowsProviderBranding.logo(for: .openai).upstreamResourceName == "ProviderIcon-codex")
        #expect(
            WindowsProviderBranding.logo(for: .azureOpenAI).upstreamResourceName
                == "ProviderIcon-codex")
        #expect(
            WindowsProviderBranding.logo(for: .alibabaTokenPlan).upstreamResourceName
                == "ProviderIcon-alibaba")
        #expect(
            WindowsProviderBranding.logo(for: .moonshot).upstreamResourceName == "ProviderIcon-kimi")
    }

    @Test
    func `unknown providers map to the final fallback cell`() {
        let reference = WindowsProviderBranding.logo(for: WindowsProviderID("future-provider"))
        #expect(reference.atlasIndex == WindowsProviderBranding.atlasCells.count)
        #expect(reference.usesFallback)
    }

    @Test
    func `bundled atlas loads as a GDI bitmap`() {
        #expect(WindowsProviderLogoAtlas.load() != nil)
    }
}
#endif
