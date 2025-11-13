//
//  BattleSetupConstants.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI

enum BattleSetupConstants {

    // MARK: - Colors
    enum Colors {
        static let buttonNormalBackground = Color(red: 0.2, green: 0.3, blue: 0.5)
        static let buttonSelectedBackground = Color.orange
        static let buttonHighlightedBackground = Color(red: 0.3, green: 0.4, blue: 0.6)

        static let buttonNormalBorder = Color.gray
        static let buttonSelectedBorder = Color.red

        static let attributeTotalText = Color.orange
        static let attributeBreakdownText = Color.white.opacity(0.8)

        static let separatorLine = Color.white.opacity(0.5)

        static let armorOverlayTint = Color.white.opacity(0.35)
    }

    // MARK: - Spacing
    enum Spacing {
        static let fightStyleButtonSpacing: CGFloat = 20
        static let sectionVerticalSpacing: CGFloat = 15
        static let panelHorizontalPadding: CGFloat = 20
        static let panelTopPadding: CGFloat = 10
        static let labelToControlSpacing: CGFloat = 5
        static let attributeRowSpacing: CGFloat = 8
        static let itemGridSpacing: CGFloat = 10
        static let jewelrySpacing: CGFloat = 15
    }

    // MARK: - Sizing
    enum Sizing {
        static let fightStyleButtonSize: CGFloat = 45
        static let levelButtonSize: CGFloat = 35
        static let itemButtonSize: CGFloat = 45
        static let jewelryButtonSize: CGFloat = 35

        static let levelButtonCornerRadius: CGFloat = 17.5

        static let buttonBorderWidth: CGFloat = 1
        static let selectedButtonBorderWidth: CGFloat = 6

        static let separatorWidth: CGFloat = 2

        static let armorIconSize: CGFloat = 20
    }

    // MARK: - Fonts
    enum Fonts {
        static let attributeTotal = Font.system(size: 12, weight: .bold)
        static let attributeBreakdown = Font.system(size: 8, weight: .regular)
        static let labelFont = Font.system(size: 14, weight: .medium)
        static let levelFont = Font.system(size: 18, weight: .bold)
    }
}
