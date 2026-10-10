import SwiftUI

/// Work done once per launch while the launch intro plays (or right after the first frame), so the first
/// taps and scrolls do not pay for it: the catalog's lazily built tables and indexes, and every Metal
/// shader's pipeline (compiled on first use otherwise, which stalls the first frame that shows a shader
/// effect, or renders its still, for tens of milliseconds per shader on an older iPad).
@MainActor
enum LaunchWarmup {
    private static var started = false

    static func run() {
        guard !started else { return }
        started = true
        Task(priority: .utility) {
            // After the first frame, in small steps so the intro keeps its frames.
            try? await Task.sleep(for: .milliseconds(120))
            _ = EffectLibrary.byID.count
            await Task.yield()
            _ = EffectLibrary.byCategory.count + EffectLibrary.featured.count
            await Task.yield()
            for category in EffectCategory.allCases {
                _ = EffectFamilies.families(in: category).count
                await Task.yield()
            }
            _ = EffectLibrary.search("a", category: nil, interaction: nil).count
            await Task.yield()
            _ = EffectFamilies.search("a", category: nil, interaction: nil).count
            PerfLog.log("warmup catalog done")
            if #available(iOS 18.0, *) {
                await compileShaders()
            }
        }
    }

    /// Every `[[ stitchable ]]` function in Shaders.metal with the effect it is used as.
    private static let shaders: [(name: String, type: Shader.UsageType)] = [
        ("mlRipple", .layerEffect),
        ("mlPixelate", .layerEffect),
        ("mlGlitch", .layerEffect),
        ("mlDissolve", .colorEffect),
        ("mlBulge", .distortionEffect),
        ("mlLensDrop", .distortionEffect),
        ("mlSwirl", .distortionEffect),
        ("mlPlasma", .colorEffect),
        ("mlCRT", .layerEffect),
        ("mlHalftoneCMYK", .layerEffect),
        ("mlFlagWave", .layerEffect),
        ("mlChromatic", .layerEffect),
        ("mlKaleidoscope", .layerEffect),
        ("mlEdgeScan", .layerEffect),
        ("mlGrainGradient", .colorEffect),
        ("mlGlassLens", .layerEffect),
        ("mlProgressiveBlur", .layerEffect),
        ("mlCaustics", .layerEffect),
        ("mlJellyPress", .layerEffect),
        ("mlLiquidWipe", .layerEffect),
        ("mlTileScatter", .layerEffect),
        ("mlReededGlass", .layerEffect),
        ("mlDither", .layerEffect),
        ("mlVHS", .layerEffect),
        ("mlVoronoiCells", .colorEffect),
        ("mlTunnel", .colorEffect),
        ("mlHeatHaze", .layerEffect),
        ("mlShockwave", .layerEffect),
        ("mlBlackHole", .layerEffect),
        ("mlWaxMelt", .layerEffect),
        ("mlInkBleed", .colorEffect),
        ("mlZoomBlur", .layerEffect),
        ("mlAscii", .layerEffect),
        ("mlThermal", .layerEffect),
        ("mlFrost", .layerEffect),
        ("mlPrism", .layerEffect),
        ("mlLiquidChrome", .colorEffect),
        ("mlNebula", .colorEffect),
        ("mlUnderwater", .layerEffect),
        ("mlWindSmear", .layerEffect),
        ("mlCrumple", .layerEffect),
        ("mlTouchTrail", .layerEffect),
        ("mlDisplaceFade", .layerEffect),
        ("mlGlitchCut", .layerEffect),
        ("mlPageCurl", .layerEffect),
        ("mlSuper8", .layerEffect),
        ("mlNightVision", .layerEffect),
        ("mlSketch", .layerEffect),
        ("mlRainGlass", .layerEffect),
        ("mlGlassBlocks", .layerEffect),
        ("mlFire", .colorEffect),
        ("mlPlasmaGlobe", .colorEffect),
    ]

    @available(iOS 18.0, *)
    private static func compileShaders() async {
        let started = ContinuousClock.now
        for shader in shaders {
            let function = ShaderFunction(library: .default, name: shader.name)
            try? await Shader(function: function, arguments: []).compile(as: shader.type)
        }
        PerfLog.log("warmup shaders compiled in \(ContinuousClock.now - started)")
    }
}
