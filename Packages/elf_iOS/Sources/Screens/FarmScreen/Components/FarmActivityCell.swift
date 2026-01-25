//
//  FarmActivityCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import elf_SwiftUI
import SwiftUI

struct FarmActivityCell: View {
    let title: String
    let imageName: String
    let level: Int
    let skillProgress: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            activityImage
                .frame(
                    width: 200,
                    height: 200
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
    private var activityImage: some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Color.white
        }
    }

    @ViewBuilder
    private var cellOverlay: some View {
        VStack {
            levelSection
                .padding(.top, ElfSpacing.xl)
                .padding(.horizontal, ElfSpacing.xl)

            Spacer()

            Text(title)
                .font(.system(size: ElfFonts.Size.largeTitle, weight: .bold))
                .foregroundStyle(ElfColors.Text.accent)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                .padding(.bottom, ElfSpacing.xl)
        }
    }

    @ViewBuilder
    private var levelSection: some View {
        VStack(spacing: ElfSpacing.xxs) {
            Text("LVL \(level)")
                .font(.system(size: ElfFonts.Size.title2, weight: .bold))
                .foregroundStyle(ElfColors.Text.primaryLight)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)

            Capsule()
                .fill(ElfColors.Background.secondary)
                .frame(height: ElfSpacing.xxs)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(ElfColors.ProgressBar.xp)
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
