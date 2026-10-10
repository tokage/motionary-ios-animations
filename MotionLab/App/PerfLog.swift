import UIKit

/// On-device performance log, off unless the app is launched with `-ML_perfLog YES`
/// (`xcrun devicectl device process launch --console … -ML_perfLog YES`). Prints main-thread stalls
/// (frames that took over 50 ms) and the cost of every still thumbnail, so a slow screen on a real device
/// can be traced without Instruments. The same lines are appended to `Documents/perf-log.txt`
/// (`xcrun devicectl device copy from --domain-type appDataContainer …` brings it back over Wi-Fi).
@MainActor
enum PerfLog {
    static let enabled: Bool = UserDefaults.standard.bool(forKey: "ML_perfLog")

    private static var monitor: HitchMonitor?

    /// Frames seen and milliseconds lost to frames longer than one 60 Hz interval, since the last reset.
    static var frames = 0
    static var lostMilliseconds: Double = 0

    /// The bench prints its own summary instead of every stall.
    static var quiet = false

    static func resetFrameStats() {
        frames = 0
        lostMilliseconds = 0
    }

    private static let file: FileHandle? = {
        guard let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let url = folder.appendingPathComponent("perf-log.txt")
        FileManager.default.createFile(atPath: url.path, contents: nil)
        return try? FileHandle(forWritingTo: url)
    }()

    static func start() {
        guard enabled, monitor == nil else { return }
        monitor = HitchMonitor()
        log("start \(UIDevice.current.model) \(UIDevice.current.systemVersion)")
    }

    static func log(_ message: @autoclosure () -> String) {
        guard enabled else { return }
        let line = "PERF \(String(format: "%.2f", CACurrentMediaTime())) \(message())"
        print(line)
        file?.write(Data((line + "\n").utf8))
    }
}

/// Reports every gap between display-link callbacks longer than 50 ms (a visible stall).
@MainActor
private final class HitchMonitor {
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0

    init() {
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        if last > 0 {
            let gap = (now - last) * 1000
            PerfLog.frames += 1
            if gap > 20 { PerfLog.lostMilliseconds += gap - 16.7 }
            if gap > 50 && !PerfLog.quiet { PerfLog.log("HITCH \(Int(gap)) ms") }
        }
        last = now
    }
}

import SwiftUI

/// `-ML_bench YES` (with `-ML_perfLog YES`): shows every effect's thumbnail live, four copies at iPad grid
/// size, one effect after another, and logs how much of each 1.5 s window was lost to slow frames.
/// `-ML_benchFrom <n>` starts at catalog index n.
struct PreviewBench: View {
    @State private var index = UserDefaults.standard.integer(forKey: "ML_benchFrom")
    private let effects = EffectLibrary.all

    var body: some View {
        let effect = effects[min(index, effects.count - 1)]
        VStack(spacing: 16) {
            Text(verbatim: "\(index) \(effect.id)").font(.caption.monospaced())
            LazyVGrid(columns: [GridItem(.fixed(180)), GridItem(.fixed(180))], spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    PreviewStage(effect: effect)
                        .frame(width: 180, height: 180)
                }
            }
            .id(effect.id)
        }
        .environment(\.previewsAlwaysOnScreen, true)
        .environment(\.previewMotionEnabled, true)
        .task {
            PerfLog.quiet = true
            while index < effects.count {
                try? await Task.sleep(for: .milliseconds(700))
                PerfLog.resetFrameStats()
                try? await Task.sleep(for: .milliseconds(1500))
                let lost = Int(PerfLog.lostMilliseconds / 15)
                PerfLog.log("BENCH \(index) \(effects[index].id) lost=\(lost)% frames=\(PerfLog.frames)")
                index += 1
            }
            PerfLog.log("BENCH done")
        }
    }
}
