//
//  MonsterAttackAlertView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

/// Alert view shown when a monster attacks during farm activity
struct MonsterAttackAlertView: View {
    let activityName: String
    let onFight: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Alert panel
            VStack(spacing: ElfSpacing.section) {
                // Warning message
                Text("! During \(activityName) the monster attacked you !")
                    .font(ElfFonts.Component.sectionTitle)
                    .foregroundStyle(ElfColors.Text.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ElfSpacing.large)

                // Fight button
                Button("Fight") {
                    onFight()
                }
                .buttonStyle(.elfPrimary(isEnabled: true))
            }
            .padding(ElfSpacing.xxl)
            .frame(width: ElfSizing.MonsterAlert.width)
            .background(ElfColors.Background.primary)
            .clipShape(RoundedRectangle(cornerRadius: ElfCornerRadius.card))
            .elfShadow(ElfShadows.large)
        }
    }
}

// MARK: - Preview

#Preview {
    MonsterAttackAlertView(
        activityName: "fishing",
        onFight: {}
    )
}
