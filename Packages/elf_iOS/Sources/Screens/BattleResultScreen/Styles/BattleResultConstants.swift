//
//  BattleResultConstants.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import elf_Kit
import SwiftUI

enum BattleResultConstants {

    // MARK: - Colors

    enum Colors {
        // Outcome colors
        static let victory = Color.green
        static let defeat = Color.red
        static let draw = Color.orange

        // Background
        static let overlayBackground = Color.black.opacity(0.7)
        static let cardBackground = Color.white

        // XP bar
        static let xpBarBackground = Color.gray.opacity(0.3)
        static let xpBarFill = Color.blue
        static let levelUpGlow = Color.yellow

        // Rarity colors for drops
        static let rarityCommon = Color.gray
        static let rarityUncommon = Color.green
        static let rarityRare = Color.blue
        static let rarityEpic = Color.purple
        static let rarityLegendary = Color.orange

        // Text
        static let primaryText = Color.black
        static let secondaryText = Color.gray
    }

    // MARK: - Sizing (optimized for landscape)

    enum Sizing {
        // Card - no fixed width, use max width constraint
        static let cardMaxWidth: CGFloat = 600
        static let cardPadding: CGFloat = 20
        static let cardVerticalPadding: CGFloat = 30
        static let cardCornerRadius: CGFloat = 16

        // Header - fixed width for left section in HStack
        static let headerWidth: CGFloat = 120
        static let outcomeIconSize: CGFloat = 40
        static let outcomeTitleFontSize: CGFloat = 24

        // XP bar - compact for landscape
        static let xpBarWidth: CGFloat = 250
        static let xpBarHeight: CGFloat = 14
        static let xpBarCornerRadius: CGFloat = 7
        static let levelBadgeSize: CGFloat = 28

        // Drop items - smaller for landscape
        static let dropItemSize: CGFloat = 50
        static let dropItemIconSize: CGFloat = 28
        static let dropItemSpacing: CGFloat = 10
        static let dropItemBorderWidth: CGFloat = 2

        // Continue button - compact
        static let continueButtonWidth: CGFloat = 140
        static let continueButtonHeight: CGFloat = 40

        // Spacing - reduced for landscape
        static let sectionSpacing: CGFloat = 16
        static let smallSpacing: CGFloat = 6

        // Separator
        static let separatorWidth: CGFloat = 1
    }

    // MARK: - Fonts (compact for landscape)

    enum Fonts {
        static let outcomeTitle = Font.system(size: 24, weight: .bold)
        static let xpGained = Font.system(size: 14, weight: .semibold)
        static let levelNumber = Font.system(size: 12, weight: .bold)
        static let levelUp = Font.system(size: 18, weight: .bold)
        static let dropItemName = Font.system(size: 10, weight: .medium)
        static let dropItemQuantity = Font.system(size: 11, weight: .bold)
        static let continueButton = Font.system(size: 16, weight: .bold)
    }

    // MARK: - Animation Timing (slightly faster for compact layout)

    enum Animation {
        static let backgroundFadeDuration: Double = 0.25
        static let cardAppearDelay: Double = 0.15
        static let cardAppearDuration: Double = 0.35
        static let headerAppearDelay: Double = 0.3
        static let xpBarFillDelay: Double = 0.6
        static let xpBarFillDuration: Double = 1.0
        static let levelUpDelay: Double = 1.6
        static let dropItemDelay: Double = 1.8
        static let dropItemStagger: Double = 0.2
        static let continueButtonDelay: Double = 0.4
    }

    // MARK: - Rarity Color Mapping

    static func color(for rarity: ItemRarity) -> Color {
        switch rarity {
        case .common:
            return Colors.rarityCommon
        case .uncommon:
            return Colors.rarityUncommon
        case .rare:
            return Colors.rarityRare
        case .epic:
            return Colors.rarityEpic
        case .legendary:
            return Colors.rarityLegendary
        }
    }

    // MARK: - Outcome Color Mapping

    static func color(for outcome: BattleOutcome) -> Color {
        switch outcome {
        case .victory:
            return Colors.victory
        case .defeat:
            return Colors.defeat
        case .draw:
            return Colors.draw
        }
    }

    // MARK: - Outcome Title

    static func title(for outcome: BattleOutcome) -> String {
        switch outcome {
        case .victory:
            return "VICTORY"
        case .defeat:
            return "DEFEAT"
        case .draw:
            return "DRAW"
        }
    }
}
