//
//  FishingInProgressView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

/// View shown while fishing is in progress
struct FishingInProgressView: View {
    var body: some View {
        VStack(spacing: ElfSpacing.section) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ElfColors.primary)

            Text("Fishing...")
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

#Preview {
    ZStack {
        ElfColors.Background.overlayMedium.ignoresSafeArea()
        FishingInProgressView()
    }
}
