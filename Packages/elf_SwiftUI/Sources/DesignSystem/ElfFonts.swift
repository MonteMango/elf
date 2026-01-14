//
//  ElfFonts.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// App-wide typography definitions.
public enum ElfFonts {

    // MARK: - Size Scale

    public enum Size {
        public static let tiny: CGFloat = 8
        public static let small: CGFloat = 10
        public static let caption: CGFloat = 12
        public static let body: CGFloat = 14
        public static let callout: CGFloat = 16
        public static let headline: CGFloat = 18
        public static let title3: CGFloat = 20
        public static let title2: CGFloat = 24
        public static let title1: CGFloat = 32
        public static let largeTitle: CGFloat = 36
    }

    // MARK: - Headings

    public static let title = Font.title.weight(.bold)
    public static let title2 = Font.title2.weight(.semibold)
    public static let title3 = Font.title3.weight(.semibold)
    public static let headline = Font.headline.weight(.bold)

    // MARK: - Body

    public static let body = Font.body
    public static let subheadline = Font.subheadline
    public static let caption = Font.caption

    // MARK: - Buttons

    public static let buttonTitle = Font.title3.weight(.semibold)
    public static let buttonSmall = Font.system(size: Size.caption, weight: .medium)

    // MARK: - Attributes

    public static let attributeValue = Font.system(size: 16, weight: .bold)

    // MARK: - Component Specific Fonts

    public enum Component {
        // Level and Stats
        public static let levelBadge = Font.system(size: Size.callout, weight: .bold)
        public static let levelNumber = Font.system(size: Size.caption, weight: .bold)
        public static let statValue = Font.system(size: Size.body, weight: .bold)
        public static let statLabel = Font.system(size: Size.caption, weight: .medium)

        // Progress
        public static let progressValue = Font.system(size: Size.body, weight: .bold)
        public static let xpGained = Font.system(size: Size.body, weight: .semibold)

        // Calendar
        public static let calendarDay = Font.system(size: Size.headline, weight: .bold)

        // Hero
        public static let heroName = Font.system(size: Size.title3, weight: .semibold)
        public static let heroLevel = Font.system(size: Size.callout, weight: .bold)
        public static let expLabel = Font.system(size: Size.small, weight: .thin)

        // Battle
        public static let outcomeTitle = Font.system(size: Size.title2, weight: .bold)
        public static let roundNumber = Font.system(size: Size.title2, weight: .bold)

        // Items
        public static let dropItemName = Font.system(size: Size.small, weight: .medium)
        public static let dropItemQuantity = Font.system(size: Size.small + 1, weight: .bold)
        public static let itemQuantity = Font.system(size: Size.small, weight: .bold)

        // Buttons
        public static let actionButton = Font.system(size: Size.headline, weight: .semibold)
        public static let sideButton = Font.system(size: Size.caption, weight: .medium)
        public static let continueButton = Font.system(size: Size.callout, weight: .bold)

        // Misc
        public static let attributeFont = Font.system(size: Size.body, weight: .medium)
        public static let apFont = Font.system(size: Size.body, weight: .bold)
        public static let statsFont = Font.system(size: Size.body, weight: .medium)
        public static let levelUpText = Font.system(size: Size.headline, weight: .bold)
    }
}
