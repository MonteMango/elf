//
//  FPSCounter.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import Observation
import UIKit

/// Main-thread frame-rate meter backed by `CADisplayLink`.
///
/// Dev-only tool. Attach via `.perfOverlay(counter:)` or use `PerfHUDView`
/// directly in a custom layout. Call `start()` when you want to begin a
/// measurement window, `stop()` to tear down the display link, and
/// `printReport(label:)` at any point to dump a summary to the console.
///
/// Metrics:
/// - `fps` — frames-per-second averaged over a rolling 0.5s window (updated twice/sec)
/// - `worstFrameMs` — longest observed frame interval since `start()`, in milliseconds
/// - `totalFrames` — frames observed since `start()`
/// - `droppedFrames` — frames whose interval exceeded `droppedThresholdMs` (default 17ms)
@MainActor
@Observable
public final class FPSCounter: NSObject {

    // MARK: - Observed metrics

    public private(set) var fps: Double = 0
    public private(set) var worstFrameMs: Double = 0
    public private(set) var totalFrames: Int = 0
    public private(set) var droppedFrames: Int = 0

    // MARK: - Config

    /// Frame interval above which a frame counts as "dropped". Default 17ms
    /// (just above 60Hz). On 120Hz ProMotion this undercounts drops; it only
    /// catches visible stutters, which is usually what you care about.
    public let droppedThresholdMs: Double = 17.0

    // MARK: - Internal state

    @ObservationIgnored private var displayLink: CADisplayLink?
    @ObservationIgnored private var startTimestamp: CFTimeInterval = 0
    @ObservationIgnored private var lastTimestamp: CFTimeInterval = 0
    @ObservationIgnored private var windowFrameCount: Int = 0
    @ObservationIgnored private var windowAccumulatedTime: CFTimeInterval = 0

    public override init() {
        super.init()
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - Control

    public func start() {
        stop()
        startTimestamp = 0
        lastTimestamp = 0
        windowFrameCount = 0
        windowAccumulatedTime = 0
        fps = 0
        worstFrameMs = 0
        totalFrames = 0
        droppedFrames = 0

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    public func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    /// Prints a summary of frame-rate metrics since the last `start()`.
    public func printReport(label: String) {
        let duration = (startTimestamp > 0 && lastTimestamp > startTimestamp)
            ? lastTimestamp - startTimestamp
            : 0
        let avgFps = duration > 0 ? Double(totalFrames) / duration : 0
        let dropPct = totalFrames > 0 ? Double(droppedFrames) / Double(totalFrames) * 100 : 0

        print(String(format: """

        ┌─── 🎬 %@ ────────────────────────────────────────
        │ Duration:      %.3fs
        │ Total frames:  %d
        │ Avg FPS:       %.1f
        │ Dropped:       %d  (%.2f%%  — frames > %.0f ms)
        │ Worst frame:   %.2f ms
        └─────────────────────────────────────────────────────────

        """,
        label,
        duration,
        totalFrames,
        avgFps,
        droppedFrames, dropPct, droppedThresholdMs,
        worstFrameMs))
    }

    // MARK: - DisplayLink tick

    @objc private func tick(_ link: CADisplayLink) {
        let timestamp = link.timestamp
        guard lastTimestamp > 0 else {
            startTimestamp = timestamp
            lastTimestamp = timestamp
            return
        }

        let dt = timestamp - lastTimestamp
        lastTimestamp = timestamp

        let frameMs = dt * 1000
        if frameMs > worstFrameMs {
            worstFrameMs = frameMs
        }
        if frameMs > droppedThresholdMs {
            droppedFrames += 1
        }
        totalFrames += 1

        windowAccumulatedTime += dt
        windowFrameCount += 1
        if windowAccumulatedTime >= 0.5 {
            fps = Double(windowFrameCount) / windowAccumulatedTime
            windowFrameCount = 0
            windowAccumulatedTime = 0
        }
    }
}
