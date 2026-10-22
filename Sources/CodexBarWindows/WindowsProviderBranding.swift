import Foundation
import WinSDK

struct WindowsProviderLogoReference: Equatable, Sendable {
    let provider: WindowsProviderID
    let upstreamResourceName: String
    let atlasIndex: Int
    let usesFallback: Bool
}

enum WindowsProviderBranding {
    static let atlasCellSize: Int32 = 20
    static let atlasResourceName = "ProviderLogos"
    static let atlasResourceExtension = "bmp"

    /// Matches the intentional resource sharing in the upstream provider descriptors.
    private static let sharedResourceNames: [WindowsProviderID: String] = [
        // Provider-specific by design: Mirror upstream shared logo assets; the Windows target cannot import Core
        // descriptors.
        .openai: "ProviderIcon-codex",
        .azureOpenAI: "ProviderIcon-codex",
        .alibabaTokenPlan: "ProviderIcon-alibaba",
        .moonshot: "ProviderIcon-kimi",
    ]

    /// Fixed atlas cells, independent of catalog order. Append new providers and their artwork at the end; never
    /// reorder or remove a cell, so inserting or retiring a catalog entry cannot shift another provider's logo.
    /// The cell after the last provider is the fallback.
    static let atlasCells: [WindowsProviderID] = [
        // Provider-specific by design: Pin each provider to the atlas cell holding its pre-rasterized logo.
        .codex, .openai, .azureOpenAI, .claude, .clinePass, .cursor, .openCode, .openCodeGo, .alibaba,
        .alibabaTokenPlan, .qwenCloud, .factory, .fireworks, .gemini, .antigravity, .copilot, .devin, .zai,
        .minimax, .manus, .kimi, .kilo, .kiro, .vertexAI, .augment, .jetBrains, .moonshot, .amp, .t3Chat,
        .ollama, .synthetic, .openRouter, .elevenLabs, .warp, .windsurf, .zed, .perplexity, .mimo, .doubao,
        .sakana, .abacus, .mistral, .deepSeek, .deepInfra, .codebuff, .crof, .venice, .commandCode, .qoder,
        .stepFun, .bedrock, .grok, .groq, .llmProxy, .liteLLM, .deepgram, .poe, .chutes, .neuralwatt,
        .clawRouter, .longCat, .sub2API, .wayfinder, .zenMux, .aiAnd, .zoomMate, .xAI, .notion, .ibmBob,
        .huggingFace, .v0, .devPass, .atlasCloud, .vercel, .xKiro, .tavily, .linkup, .aerostack,
        .sailResearch, .sofya, .fal, .munito,
    ]

    static var fallbackAtlasIndex: Int {
        self.atlasCells.count
    }

    private static let atlasIndices: [WindowsProviderID: Int] =
        Dictionary(
            uniqueKeysWithValues: Self.atlasCells.enumerated().map {
                ($0.element, $0.offset)
            })

    static func logo(for provider: WindowsProviderID) -> WindowsProviderLogoReference {
        guard let index = atlasIndices[provider] else {
            return WindowsProviderLogoReference(
                provider: provider,
                upstreamResourceName: "ProviderIcon-fallback",
                atlasIndex: self.fallbackAtlasIndex,
                usesFallback: true)
        }
        return WindowsProviderLogoReference(
            provider: provider,
            upstreamResourceName: Self.sharedResourceNames[provider]
                ?? "ProviderIcon-\(provider.rawValue)",
            atlasIndex: index,
            usesFallback: false)
    }
}

/// Owns the single pre-rasterized GDI bitmap shared by every provider row and header.
///
/// Cells follow `WindowsProviderBranding.atlasCells`; the final cell is a safe fallback for
/// forward-compatible provider IDs. Each cell is an upstream provider SVG rendered white at 18×18 px, centred on
/// the dark dashboard background.
final class WindowsProviderLogoAtlas {
    private let bitmap: HBITMAP
    private let sourceDC: HDC
    private let previousBitmap: HGDIOBJ?

    private init(bitmap: HBITMAP, sourceDC: HDC, previousBitmap: HGDIOBJ?) {
        self.bitmap = bitmap
        self.sourceDC = sourceDC
        self.previousBitmap = previousBitmap
    }

    deinit {
        if let previousBitmap = self.previousBitmap {
            _ = SelectObject(self.sourceDC, previousBitmap)
        }
        _ = DeleteDC(self.sourceDC)
        _ = DeleteObject(self.bitmap)
    }

    static func load(bundle: Bundle = .module) -> WindowsProviderLogoAtlas? {
        guard
            let url = bundle.url(
                forResource: WindowsProviderBranding.atlasResourceName,
                withExtension: WindowsProviderBranding.atlasResourceExtension)
        else { return nil }
        return WindowsWideString.withPointer(url.path) { path in
            guard
                let handle = LoadImageW(
                    nil,
                    path,
                    UINT(IMAGE_BITMAP),
                    0,
                    0,
                    UINT(LR_LOADFROMFILE | LR_CREATEDIBSECTION)),
                let sourceDC = CreateCompatibleDC(nil)
            else { return nil }
            let bitmap = handle.assumingMemoryBound(to: HBITMAP__.self)
            let previousBitmap = SelectObject(sourceDC, bitmap)
            return WindowsProviderLogoAtlas(
                bitmap: bitmap,
                sourceDC: sourceDC,
                previousBitmap: previousBitmap)
        }
    }

    @discardableResult
    func draw(provider: WindowsProviderID, dc: HDC?, rect: RECT) -> Bool {
        guard let dc else { return false }
        let width = rect.right - rect.left
        let height = rect.bottom - rect.top
        guard width > 0, height > 0 else { return false }

        let reference = WindowsProviderBranding.logo(for: provider)
        let previousMode = SetStretchBltMode(dc, Int32(HALFTONE))
        defer {
            if previousMode != 0 { _ = SetStretchBltMode(dc, previousMode) }
        }
        _ = SetBrushOrgEx(dc, rect.left, rect.top, nil)
        return StretchBlt(
            dc,
            rect.left,
            rect.top,
            width,
            height,
            self.sourceDC,
            Int32(reference.atlasIndex) * WindowsProviderBranding.atlasCellSize,
            0,
            WindowsProviderBranding.atlasCellSize,
            WindowsProviderBranding.atlasCellSize,
            DWORD(SRCCOPY))
    }
}
