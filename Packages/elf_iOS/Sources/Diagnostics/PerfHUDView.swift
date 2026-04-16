//
//  PerfHUDView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Translucent overlay that shows live FPS + dropped-frame stats.
/// Dev-only — intended to be embedded via `.perfOverlay(counter:)`.
public struct PerfHUDView: View {
    let counter: FPSCounter

    public init(counter: FPSCounter) {
        self.counter = counter
    }

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(fpsColor)
                    .frame(width: 8, height: 8)
                Text("\(Int(counter.fps.rounded())) FPS")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            Text("Dropped: \(counter.droppedFrames) / \(counter.totalFrames)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
            Text("Worst frame: \(String(format: "%.1f", counter.worstFrameMs)) ms")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(counter.worstFrameMs > 33 ? .red : .white.opacity(0.9))
        }
        .padding(8)
        .background(Color.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(fpsColor.opacity(0.6), lineWidth: 1)
        )
    }

    private var fpsColor: Color {
        let fps = counter.fps
        if fps >= 58 { return .green }
        if fps >= 50 { return .yellow }
        if fps >= 30 { return .orange }
        return .red
    }
}
