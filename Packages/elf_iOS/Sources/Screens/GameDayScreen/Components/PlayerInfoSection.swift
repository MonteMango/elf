//
//  PlayerInfoSection.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_SwiftUI
import SwiftUI

struct PlayerInfoSection: View {
    let level: Int
    let name: String
    let currentExp: Int
    let expToNextLevel: Int
    let xpProgress: Double

    private let xpBarHeight: CGFloat = ElfSizing.ProgressBar.thin
    private let labelWidth: CGFloat = 60

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(alignment: .leading, spacing: 0) {
            // Level and Name
            HStack(spacing: ElfSpacing.component) {
                Text("LVL\(level)")
                    .font(ElfFonts.Component.heroLevel)
                    .foregroundStyle(ElfColors.Text.secondary)
                    .frame(width: labelWidth, alignment: .leading)

                Text(name)
                    .font(ElfFonts.Component.heroName)
                    .bold()
                    .foregroundStyle(ElfColors.Text.primary)
            }

            // Experience bar with label on the left
            HStack(spacing: ElfSpacing.component) {
                Text("Exp: \(currentExp)/\(expToNextLevel)")
                    .font(ElfFonts.Component.expLabel)
                    .foregroundStyle(ElfColors.Text.secondary)
                    .frame(width: labelWidth, alignment: .leading)

                ZStack(alignment: .leading) {
                    // Background (no corner radius)
                    Rectangle()
                        .fill(ElfColors.ProgressBar.background)

                    // Fill (no corner radius) - uses scaleEffect instead of GeometryReader
                    Rectangle()
                        .fill(ElfColors.ProgressBar.xp)
                        .scaleEffect(x: xpProgress, y: 1, anchor: .leading)
                }
                .frame(height: xpBarHeight)
            }
        }
    }
}

#Preview {
    PlayerInfoSection(
        level: 1,
        name: "Asuna Yuuki",
        currentExp: 20,
        expToNextLevel: 100,
        xpProgress: 0.2
    )
    .padding()
    .background(Color.white)
}
