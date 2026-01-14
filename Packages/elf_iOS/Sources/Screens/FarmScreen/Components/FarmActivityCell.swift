//
//  FarmActivityCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import SwiftUI

struct FarmActivityCell: View {
    let title: String
    let imageName: String
    let level: Int
    let skillProgress: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    width: FarmConstants.Sizing.activityCellWidth,
                    height: FarmConstants.Sizing.activityCellHeight
                )
                .clipShape(Rectangle())
                .contentShape(Rectangle())
                .overlay {
                    cellOverlay
                }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var cellOverlay: some View {
        VStack {
            levelSection
                .padding(.top, 16)
                .padding(.horizontal, 16)

            Spacer()

            Text(title)
                .font(FarmConstants.Fonts.activityLabel)
                .foregroundStyle(FarmConstants.Colors.activityLabelText)
                .textShadow()
                .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var levelSection: some View {
        VStack(spacing: 4) {
            Text("LVL \(level)")
                .font(FarmConstants.Fonts.levelText)
                .foregroundStyle(FarmConstants.Colors.levelText)
                .textShadow()

            Capsule()
                .fill(FarmConstants.Colors.skillBarBackground)
                .frame(height: FarmConstants.Sizing.skillBarHeight)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(FarmConstants.Colors.skillBarFill)
                        .scaleEffect(x: skillProgress, y: 1, anchor: .leading)
                }
                .clipShape(Capsule())
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        FarmActivityCell(
            title: "Foraging",
            imageName: "foraging",
            level: 1,
            skillProgress: 0.3,
            action: {}
        )

        FarmActivityCell(
            title: "Fishing",
            imageName: "fishing",
            level: 1,
            skillProgress: 0.5,
            action: {}
        )

        FarmActivityCell(
            title: "Mining",
            imageName: "mining",
            level: 2,
            skillProgress: 0.8,
            action: {}
        )
    }
    .padding()
}
