//
//  GameDayConstants.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI

enum GameDayConstants {

    // MARK: - Colors
    enum Colors {
        static let background = Color.black
        static let panelBackground = Color(red: 0.15, green: 0.15, blue: 0.2)

        // Progress bars
        static let xpBarBackground = Color.gray.opacity(0.3)
        static let xpBarFill = Color.blue
        static let hpBarFill = Color.green
        static let mpBarFill = Color.blue
        static let apBarFill = Color.yellow

        // Buttons
        static let actionButtonBackground = Color.orange
        static let actionButtonText = Color.white
        static let sideButtonBackground = Color.orange
        static let closeButtonBackground = Color.red

        // Equipment slots
        static let equipmentSlotBackground = Color.gray.opacity(0.3)
        static let equipmentSlotBorder = Color.gray.opacity(0.5)

        // Pockets
        static let pocketBackground = Color.gray.opacity(0.3)
        static let pocketBorder = Color.gray.opacity(0.5)

        // Buffs
        static let buffBackground = Color.gray.opacity(0.3)

        // Text
        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.7)
        static let accentText = Color.orange
    }

    // MARK: - Spacing
    enum Spacing {
        static let sectionSpacing: CGFloat = 20
        static let componentSpacing: CGFloat = 5
        static let smallSpacing: CGFloat = 5
        static let buttonSpacing: CGFloat = 25
        static let gridSpacing: CGFloat = 1
    }

    // MARK: - Sizing
    enum Sizing {
        // Hero section
        static let heroImageWidth: CGFloat = 100
        static let heroImageHeight: CGFloat = 180

        // Equipment
        static let equipmentSlotSize: CGFloat = 40
        static let equipmentIconSize: CGFloat = 30

        // Buttons
        static let actionButtonHeight: CGFloat = 50
        static let actionButtonWidth: CGFloat = 200
        static let actionButtonCornerRadius: CGFloat = 12
        static let sideButtonSize: CGFloat = 50
        static let sideButtonCornerRadius: CGFloat = 8
        static let closeButtonSize: CGFloat = 50

        // Calendar
        static let calendarDaySize: CGFloat = 50
        static let calendarDayCornerRadius: CGFloat = 4

        // Pockets
        static let pocketSize: CGFloat = 35

        // Buffs
        static let buffSize: CGFloat = 30

        // Progress bars
        static let progressBarHeight: CGFloat = 16
        static let apBarHeight: CGFloat = 30

        // Attribute icons
        static let attributeIconSize: CGFloat = 20
    }

    // MARK: - Fonts
    enum Fonts {
        static let levelFont = Font.system(size: 16, weight: .bold)
        static let nameFont = Font.system(size: 20, weight: .semibold)
        static let expFont = Font.system(size: 10, weight: .thin)
        static let attributeFont = Font.system(size: 14, weight: .medium)
        static let attributeValueFont = Font.system(size: 16, weight: .bold)
        static let buttonFont = Font.system(size: 18, weight: .semibold)
        static let sideButtonFont = Font.system(size: 12, weight: .medium)
        static let calendarDayFont = Font.system(size: 18, weight: .bold)
        static let apFont = Font.system(size: 14, weight: .bold)
        static let statsFont = Font.system(size: 14, weight: .medium)
    }
}
