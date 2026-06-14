//
//  DungeonOverviewContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Overview-tab body of `DungeonScreen`. Title + region/description on the
/// left (1/4), expected-monsters preview in the middle (2/4), squad preview
/// + mini-map preview on the right (1/4). Possible-drops sits as an overlay
/// in the bottom-leading corner so the action band reads as one row with
/// the parent's Entrance button.
struct DungeonOverviewContent: View {
    @State private var viewModel: DungeonOverviewViewModel

    init(session: DungeonSession) {
        self._viewModel = State(initialValue: session.makeOverviewViewModel())
    }

    var body: some View {
        // TODO: When `containerRelativeFrame(.horizontal, count:span:)` plays
        // nicely with HStack + Spacer (re-evaluate on iOS 18 baseline), we can
        // drop GeometryReader for these column fractions.
        GeometryReader { geo in
            // 3 columns separated by 2 gaps; subtract the gaps so 1/4 + 2/4 + 1/4
            // adds up to the actually available width.
            let columnSpacing = ElfSpacing.small
            let availableWidth = geo.size.width - columnSpacing * 2
            let quarterWidth = availableWidth / 4
            let halfWidth = availableWidth / 2

            HStack(alignment: .top, spacing: columnSpacing) {
                titleSection
                    .frame(width: quarterWidth, alignment: .leading)
                MonstersPlaceholder()
                    .frame(width: halfWidth)
                    .frame(maxHeight: .infinity)
                VStack(spacing: ElfSpacing.xs) {
                    SquadCompactSection(members: viewModel.squad)
                    MiniMapPlaceholder()
                }
                .frame(width: quarterWidth, alignment: .trailing)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay(alignment: .bottomLeading) {
                RewardsSection(
                    title: "Possible drop:",
                    items: dropItems,
                    titleColor: ElfColors.Text.primaryLight
                )
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: ElfSpacing.xs) {
            if viewModel.isCurrentRoomCleared {
                Text("Cleared")
                    .font(ElfFonts.caption)
                    .foregroundStyle(ElfColors.Text.primaryLight)
                    .padding(.horizontal, ElfSpacing.small)
                    .padding(.vertical, ElfSpacing.xxs)
                    .background(ElfColors.Button.primary, in: Capsule())
            }

            Text(viewModel.header.title)
                .font(ElfFonts.title2)
                .foregroundStyle(ElfColors.Text.accent)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.header.regionSubtitle)
                .font(ElfFonts.caption)
                .foregroundStyle(ElfColors.Text.secondaryLight)

            Text(viewModel.header.description)
                .font(ElfFonts.caption)
                .foregroundStyle(ElfColors.Text.primaryLight)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var dropItems: [RewardItemData] {
        viewModel.possibleDrops.map { drop in
            RewardItemData(id: drop.id, imageName: drop.imageName, tier: drop.tier)
        }
    }
}
