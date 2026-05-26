//
//  BuffBadgeView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI
import UIKit

/// Single buff cell shown in `BuffBadgeStripView`. Renders the catalog icon
/// inside a polarity-colored border. Stack count appears as a corner pill
/// when `stacks >= 2`. Days remaining is shown as a tiny footer when the
/// buff is global with a finite duration; battle-scoped buffs and global
/// buffs without expiry render no footer.
struct BuffBadgeView: View {

    let badge: BuffBadgeViewState

    var body: some View {
        ZStack(alignment: .topTrailing) {
            iconTile
            if badge.stacks >= 2 {
                stacksPill
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.title)
        .accessibilityValue(accessibilityValueText)
    }

    // MARK: - Private Views

    private var iconTile: some View {
        RoundedRectangle(cornerRadius: ElfSizing.BattleFight.buffBadgeCornerRadius)
            .fill(ElfColors.Buff.badgeBackground)
            .overlay {
                iconImage
                    .padding(2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.buffBadgeCornerRadius)
                    .stroke(borderColor, lineWidth: ElfSizing.BattleFight.buffBadgeBorderWidth)
            }
            .frame(
                width: ElfSizing.BattleFight.buffBadgeSize,
                height: ElfSizing.BattleFight.buffBadgeSize
            )
    }

    @ViewBuilder
    private var iconImage: some View {
        if let uiImage = UIImage(named: badge.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            // Asset not in the bundle yet — fall back to a polarity-coded
            // SF Symbol so the badge is still visible during development.
            Image(systemName: fallbackSymbolName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(borderColor)
        }
    }

    private var stacksPill: some View {
        Text("\(badge.stacks)")
            .font(.system(size: ElfSizing.BattleFight.buffBadgeStacksFontSize, weight: .bold))
            .foregroundStyle(ElfColors.Buff.stacksText)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(
                Capsule().fill(ElfColors.Buff.stacksBackground)
            )
            .offset(x: 3, y: -3)
    }

    private var borderColor: Color {
        switch badge.polarity {
        case .positive: ElfColors.Buff.positive
        case .negative: ElfColors.Buff.negative
        }
    }

    private var fallbackSymbolName: String {
        switch badge.polarity {
        case .positive: "sparkles"
        case .negative: "exclamationmark.triangle.fill"
        }
    }

    private var accessibilityValueText: String {
        var parts: [String] = []
        if badge.stacks >= 2 { parts.append("\(badge.stacks) stacks") }
        if let days = badge.daysRemaining { parts.append("\(days) days left") }
        return parts.joined(separator: ", ")
    }
}
