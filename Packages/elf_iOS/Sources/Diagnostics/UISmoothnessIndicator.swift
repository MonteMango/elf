//
//  UISmoothnessIndicator.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Continuously-rotating square used to VISUALLY verify main-thread smoothness.
/// If the main thread stalls, you see the square hang or jitter mid-rotation.
/// Dev-only — intended to be embedded via `.perfOverlay(counter:)`.
public struct UISmoothnessIndicator: View {
    @State private var angle: Double = 0

    public init() {}

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.pink, .orange, .yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 36, height: 36)
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}
