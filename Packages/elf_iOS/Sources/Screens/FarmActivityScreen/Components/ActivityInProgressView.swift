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
        #if DEBUG
        let _ = Self._printChanges()
        #endif
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
        ElfColors.Background.overlayMedium.ignoresSafeArea()
        ActivityInProgressView(activity: .fishing)
    }
}

#Preview("Foraging") {
    ZStack {
        ElfColors.Background.overlayMedium.ignoresSafeArea()
        ActivityInProgressView(activity: .foraging)
    }
}

#Preview("Mining") {
    ZStack {
        ElfColors.Background.overlayMedium.ignoresSafeArea()
        ActivityInProgressView(activity: .mining)
    }
}
