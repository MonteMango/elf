//
//  HuntConstants.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import SwiftUI

enum HuntConstants {

    // MARK: - Colors

    enum Colors {
        static let background = Color.white

        // Progress bar
        static let apBarFill = Color.yellow
        static let apBarBackground = Color(white: 0.9)

        // Monster cell
        static let monsterCellBackground = Color.clear
        static let monsterNameText = Color.black

        // Drop items
        static let dropItemBackground = Color(white: 0.95)
        static let dropItemBorder = Color.orange

        // Hunt button
        static let huntButtonBackground = Color.orange
        static let huntButtonText = Color.white
        static let huntCostText = Color.gray
    }

    // MARK: - Spacing

    enum Spacing {
        static let topPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 30
        static let monsterSpacing: CGFloat = 20
        static let dropItemSpacing: CGFloat = 8
        static let componentSpacing: CGFloat = 8
    }

    // MARK: - Sizing

    enum Sizing {
        // Action points bar
        static let apBarHeight: CGFloat = 30
        static let apBarWidth: CGFloat = 300

        // Monster cell
        static let monsterImageSize: CGFloat = 150
        static let monsterCellWidth: CGFloat = 200

        // Drop items
        static let dropItemSize: CGFloat = 50
        static let dropItemCornerRadius: CGFloat = 8
        static let dropItemBorderWidth: CGFloat = 2

        // Hunt button
        static let huntButtonWidth: CGFloat = 200
        static let huntButtonHeight: CGFloat = 50
        static let huntButtonCornerRadius: CGFloat = 12
    }

    // MARK: - Fonts

    enum Fonts {
        static let apLabel = Font.system(size: 14, weight: .medium)
        static let apValue = Font.system(size: 14, weight: .bold)
        static let monsterName = Font.system(size: 18, weight: .semibold)
        static let huntButton = Font.system(size: 20, weight: .bold)
        static let huntCost = Font.system(size: 16, weight: .medium)
    }
}
