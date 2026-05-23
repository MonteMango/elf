//
//  SquadCompactSection.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Compact squad list for the Overview tab. Five rows in a single `Grid` so
/// every column has the same width across rows — the HP bar starts at the
/// same x for every elf, and HP labels never truncate.
///
/// Column behaviour (left → right):
/// 1. portrait (fixed)
/// 2. `name (lvl)` — sized to the widest name in the squad, never truncated
///    (`.fixedSize`)
/// 3. HP bar — the only flexible column, fills whatever width is left
/// 4. `current/max` HP — sized to the widest pair in the squad, never
///    truncated (`.fixedSize`)
///
/// HP bar shrinks first when there isn't enough space, since every other
/// element is `.fixedSize()`.
struct SquadCompactSection: View {
    let members: [DungeonSquadMemberDisplay]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: ElfSpacing.xs, verticalSpacing: ElfSpacing.xxs) {
            ForEach(members) { member in
                GridRow(alignment: .center) {
                    portraitCircle(for: member)

                    Text("\(member.name) (\(member.level))")
                        .font(ElfFonts.caption)
                        .fontWeight(member.isHero ? .semibold : .regular)
                        .foregroundStyle(ElfColors.Text.primaryLight)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    hpBar(for: member)
                        .frame(maxWidth: .infinity)
                        .frame(height: 5)

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
                .fill(member.isHero ? ElfColors.Button.primary : Color.white.opacity(0.4))
                .frame(width: 22, height: 22)

            if let uiImage = UIImage(named: member.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 11, weight: .bold))
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
            .fill(Color.white.opacity(0.25))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(hpFillColor(for: member))
                    .scaleEffect(x: CGFloat(max(0, member.hpProgress)), y: 1, anchor: .leading)
            }
            .clipShape(.rect(cornerRadius: 2))
    }

    private func hpFillColor(for member: DungeonSquadMemberDisplay) -> Color {
        let progress = member.hpProgress
        if progress > 0.6 { return Color.green }
        if progress > 0.3 { return Color.orange }
        return Color.red
    }
}
