//
//  PlayerInfoSection.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI

struct PlayerInfoSection: View {
    let level: Int
    let name: String
    let currentExp: Int
    let expToNextLevel: Int
    let xpProgress: Double

    private let xpBarHeight: CGFloat = 4

    private let labelWidth: CGFloat = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Level and Name
            HStack(spacing: GameDayConstants.Spacing.smallSpacing) {
                Text("LVL\(level)")
                    .font(GameDayConstants.Fonts.levelFont)
                    .foregroundColor(.gray)
                    .frame(width: labelWidth, alignment: .leading)

                Text(name)
                    .font(GameDayConstants.Fonts.nameFont)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }

            // Experience bar with label on the left
            HStack(spacing: GameDayConstants.Spacing.smallSpacing) {
                Text("Exp: \(currentExp)/\(expToNextLevel)")
                    .font(GameDayConstants.Fonts.expFont)
                    .foregroundColor(.gray)
                    .frame(width: labelWidth, alignment: .leading)

                ZStack(alignment: .leading) {
                    // Background (no corner radius)
                    Rectangle()
                        .fill(GameDayConstants.Colors.xpBarBackground)

                    // Fill (no corner radius) - uses scaleEffect instead of GeometryReader
                    Rectangle()
                        .fill(GameDayConstants.Colors.xpBarFill)
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
