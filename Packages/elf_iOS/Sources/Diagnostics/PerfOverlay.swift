//
//  PerfOverlay.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Attaches the perf HUD + smoothness indicator as a non-hit-testing overlay
/// pinned to the top edge. Dev-only.
///
/// Usage:
/// ```
/// someView.perfOverlay(counter: fpsCounter)
/// ```
/// Lifecycle (`counter.start()` / `counter.stop()` / `counter.printReport(...)`)
/// stays with the caller so screens can align measurements with meaningful
/// events (e.g. a single battle run).
private struct PerfOverlayModifier: ViewModifier {
    let counter: FPSCounter

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            HStack {
                PerfHUDView(counter: counter)
                Spacer()
                UISmoothnessIndicator()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 8)
            .allowsHitTesting(false)
        }
    }
}

public extension View {
    /// Overlays the perf HUD + smoothness indicator on top of this view.
    func perfOverlay(counter: FPSCounter) -> some View {
        modifier(PerfOverlayModifier(counter: counter))
    }
}
