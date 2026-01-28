//
//  ActivityInProgressView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// View shown while a farm activity (fishing, foraging, mining) is in progress
struct ActivityInProgressView: View {
    let activity: FarmActivity

    var body: some View {
        VStack(spacing: ElfSpacing.section) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ElfColors.primary)

            Text("\(activity.title)...")
                .font(ElfFonts.Component.sectionTitle)
                .foregroundStyle(ElfColors.Text.primary)
        }
        .frame(width: ElfSizing.FishingProgress.width, height: ElfSizing.FishingProgress.height)
        .background(ElfColors.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: ElfCornerRadius.card))
        .elfShadow(ElfShadows.medium)
    }
}

// MARK: - Preview

#Preview("Fishing") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        ActivityInProgressView(activity: .fishing)
    }
}

#Preview("Foraging") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        ActivityInProgressView(activity: .foraging)
    }
}

#Preview("Mining") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        ActivityInProgressView(activity: .mining)
    }
}
