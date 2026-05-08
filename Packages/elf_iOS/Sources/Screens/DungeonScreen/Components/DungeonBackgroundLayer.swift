//
//  DungeonBackgroundLayer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

/// Full-bleed dungeon background — image plus a top→bottom readability scrim.
///
/// `Equatable` short-circuits body re-evaluation: while `imageName` is
/// unchanged, SwiftUI never re-runs `body`, so the image stays pixel-stable
/// when the parent screen swaps the body of its segmented control.
struct DungeonBackgroundLayer: View, Equatable {
    let imageName: String

    var body: some View {
        ZStack {
            backgroundImage
            LinearGradient(
                colors: [
                    Color.white.opacity(0.85),
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var backgroundImage: some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ElfColors.Background.dark
        }
    }
}
