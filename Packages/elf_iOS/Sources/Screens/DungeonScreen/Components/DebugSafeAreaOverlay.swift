//
//  DebugSafeAreaOverlay.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Debug-only overlay that paints every region OUTSIDE the safe area in
/// translucent red. Useful for verifying which device-level zones (dynamic
/// island, home indicator, status bar) the layout has to respect.
struct DebugSafeAreaOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let insets = geo.safeAreaInsets
            let totalWidth = geo.size.width + insets.leading + insets.trailing
            let totalHeight = geo.size.height + insets.top + insets.bottom
            ZStack(alignment: .topLeading) {
                Color.red.opacity(0.7)
                    .frame(width: totalWidth, height: insets.top)
                    .offset(x: -insets.leading, y: -insets.top)

                Color.red.opacity(0.7)
                    .frame(width: totalWidth, height: insets.bottom)
                    .offset(x: -insets.leading, y: geo.size.height)

                Color.red.opacity(0.7)
                    .frame(width: insets.leading, height: totalHeight)
                    .offset(x: -insets.leading, y: -insets.top)

                Color.red.opacity(0.7)
                    .frame(width: insets.trailing, height: totalHeight)
                    .offset(x: geo.size.width, y: -insets.top)
            }
            .allowsHitTesting(false)
        }
    }
}
