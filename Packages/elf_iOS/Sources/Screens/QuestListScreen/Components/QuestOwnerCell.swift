//
//  QuestOwnerCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

struct QuestOwnerCell: View {
    let title: String
    let name: String
    let imageName: String
    let questTitle: String
    let rewardText: String

    @State private var image: UIImage?
    private let downsampler = ImageDownsampler()
    private let cellWidth: CGFloat = 180
    private let aspectRatio: CGFloat = 784 / 1176

    private var cellSize: CGSize {
        CGSize(width: cellWidth, height: cellWidth / aspectRatio)
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        characterImage
            .frame(
                width: cellSize.width,
                height: cellSize.height
            )
            .clipped()
            .contentShape(Rectangle())
            .overlay {
                QuestOwnerCellOverlay(
                    title: title,
                    name: name,
                    questTitle: questTitle,
                    rewardText: rewardText
                )
            }
            .task {
                image = await downsampler.downsample(
                    assetNamed: imageName,
                    targetSize: cellSize,
                    scale: UIScreen.main.scale
                )
            }
    }

    // MARK: - Character Image

    @ViewBuilder
    private var characterImage: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Color.gray
        }
    }

}

// MARK: - Overlay (separate struct for independent skip-diffing)

private struct QuestOwnerCellOverlay: View {
    let title: String
    let name: String
    let questTitle: String
    let rewardText: String

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.6),
                            .black.opacity(0),
                            .black.opacity(0),
                            .black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack {
                ownerInfo
                    .padding(.top, ElfSpacing.xl)

                Spacer()

                questInfo
                    .padding(.bottom, ElfSpacing.xl)
            }
            .padding(.horizontal, ElfSpacing.large)
        }
    }

    // MARK: - Owner Info (Top)

    @ViewBuilder
    private var ownerInfo: some View {
        VStack(spacing: ElfSpacing.xxs) {
            Text(title)
                .font(.system(size: ElfFonts.Size.title2, weight: .bold))
                .foregroundStyle(ElfColors.Text.accent)

            Text(name)
                .font(.system(size: ElfFonts.Size.caption, weight: .medium))
                .foregroundStyle(ElfColors.Text.primaryLight)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
    }

    // MARK: - Quest Info (Bottom)

    @ViewBuilder
    private var questInfo: some View {
        VStack(spacing: ElfSpacing.xxs) {
            Text(questTitle)
                .font(.system(size: ElfFonts.Size.body, weight: .semibold))
                .foregroundStyle(ElfColors.Text.primaryLight)
                .multilineTextAlignment(.center)

            HStack(spacing: ElfSpacing.xxs) {
                Image(systemName: "gift.fill")
                    .font(.system(size: ElfFonts.Size.caption))
                Text(rewardText)
                    .font(.system(size: ElfFonts.Size.caption, weight: .medium))
            }
            .foregroundStyle(ElfColors.Text.accent)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        QuestOwnerCell(
            title: "Blacksmith",
            name: "Tharion Ironveil",
            imageName: "quest_blacksmith",
            questTitle: "Ore for the Forge",
            rewardText: "5x Small Soul Gem"
        )

        QuestOwnerCell(
            title: "Village Girl",
            name: "Elowen Dawnpetal",
            imageName: "quest_villageGirl",
            questTitle: "Flowers for a Bouquet",
            rewardText: "5x Small Soul Gem"
        )

        QuestOwnerCell(
            title: "Hunter",
            name: "Kael Shadowthorn",
            imageName: "quest_hunter",
            questTitle: "Wolf Hunt",
            rewardText: "5x Small Soul Gem"
        )
    }
    .padding()
}
