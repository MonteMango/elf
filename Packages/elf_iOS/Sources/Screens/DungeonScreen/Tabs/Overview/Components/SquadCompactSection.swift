//
//  SquadCompactSection.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Compact squad list for the Overview tab. One row per elf: rounded portrait
/// on the left, two stacked lines on the right — first line is `name (level)`,
/// second line is the HP bar with `current/max` numbers at the trailing edge.
struct SquadCompactSection: View {
    let members: [DungeonSquadMemberDisplay]

    var body: some View {
        VStack(alignment: .leading, spacing: ElfSpacing.xs) {
            ForEach(members) { member in
                memberRow(for: member)
            }
        }
    }

    private func memberRow(for member: DungeonSquadMemberDisplay) -> some View {
        HStack(alignment: .center, spacing: ElfSpacing.xs) {
            portraitCircle(for: member)

            VStack(alignment: .leading, spacing: ElfSpacing.xxxs) {
                Text("\(member.name) (\(member.level))")
                    .font(ElfFonts.caption)
                    .fontWeight(member.isHero ? .semibold : .regular)
                    .foregroundStyle(ElfColors.Text.primaryLight)
                    .lineLimit(1)

                HStack(spacing: ElfSpacing.xs) {
                    hpBar(for: member)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: ElfSizing.DungeonSquad.compactHpBarHeight,
                            maxHeight: ElfSizing.DungeonSquad.compactHpBarHeight
                        )

                    Text("\(member.currentHP)/\(member.maxHP)")
                        .font(.system(size: ElfFonts.Size.tiny, weight: .medium, design: .monospaced))
                        .foregroundStyle(ElfColors.Text.secondaryLight)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }

    private func portraitCircle(for member: DungeonSquadMemberDisplay) -> some View {
        ZStack {
            Circle()
                .fill(member.isHero ? ElfColors.Button.primary : ElfColors.Background.compactPortraitFallback)
                .frame(
                    width: ElfSizing.DungeonSquad.compactPortraitOuter,
                    height: ElfSizing.DungeonSquad.compactPortraitOuter
                )

            if let uiImage = UIImage(named: member.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: ElfSizing.DungeonSquad.compactPortraitImage,
                        height: ElfSizing.DungeonSquad.compactPortraitImage
                    )
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: ElfSizing.DungeonSquad.compactPortraitIconSize, weight: .bold))
                    .foregroundStyle(ElfColors.Text.primaryLight)
            }
        }
    }

    /// Bar background + foreground fill scaled to `hpProgress`.
    /// `scaleEffect(x:y:anchor:)` avoids a per-row `GeometryReader`: the fill
    /// rectangle is full-width, scaled down on the leading anchor by the
    /// progress fraction. Outer `clipShape` re-rounds the corners after the
    /// scale, so the cap stays crisp regardless of how short the bar is.
    private func hpBar(for member: DungeonSquadMemberDisplay) -> some View {
        Rectangle()
            .fill(ElfColors.ProgressBar.compactBackground)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(hpFillColor(for: member))
                    .scaleEffect(x: CGFloat(max(0, member.hpProgress)), y: 1, anchor: .leading)
            }
            .clipShape(.rect(cornerRadius: ElfSizing.DungeonSquad.compactHpBarCornerRadius))
    }

    private func hpFillColor(for member: DungeonSquadMemberDisplay) -> Color {
        let progress = member.hpProgress
        if progress > 0.6 { return Color.green }
        if progress > 0.3 { return Color.orange }
        return Color.red
    }
}
