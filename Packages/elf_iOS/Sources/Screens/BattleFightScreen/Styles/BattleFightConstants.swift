//
//  BattleFightConstants.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import elf_Kit
import SwiftUI

enum BattleFightConstants {

    // MARK: - Colors
    enum Colors {
        // HP Bar colors
        static let hpBarBackground = Color.gray.opacity(0.3)
        static let hpBarFill = Color.green
        static let hpBarText = Color.white

        // Point status colors (for result dots)
        static let blocked = Color.green
        static let hit = Color.red
        static let critHit = Color.orange
        static let dodged = Color.yellow
        static let nothing = Color.gray.opacity(0.5)

        // Checkbox colors
        static let checkboxNormal = Color.gray.opacity(0.5)
        static let checkboxSelected = Color.orange
        static let checkboxDisabled = Color.gray.opacity(0.2)

        // Button colors
        static let fightButton = Color.orange
        static let closeButton = Color.red

        // Background colors
        static let panelBackground = Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.9)
        static let separator = Color.black.opacity(0.5)
    }

    // MARK: - Sizing
    enum Sizing {
        // Hero display
        static let heroImageSize: CGFloat = 150
        static let itemIconSize: CGFloat = 30
        static let hpBarWidth: CGFloat = 150

        // HP bar
        static let hpBarHeight: CGFloat = 24
        static let hpBarCornerRadius: CGFloat = 12

        // Checkboxes (for BodyPointSelector)
        static let checkboxSize: CGFloat = 45
        static let checkboxBorderWidth: CGFloat = 2
        static let checkboxSpacing: CGFloat = 10
        static let bodySelectorWidth: CGFloat = 180
        static let bodySelectorHeight: CGFloat = 250

        // Result dots
        static let resultDotSize: CGFloat = 10

        // Battle item icons (smaller than setup screen)
        static let battleItemSize: CGFloat = 20
        static let battleJewelrySize: CGFloat = 15
        static let itemGridSpacing: CGFloat = 2

        // Buttons
        static let fightButtonWidth: CGFloat = 250
        static let fightButtonHeight: CGFloat = 60
        static let closeButtonSize: CGFloat = 44

        // Spacing
        static let roundNumberTopPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 40
        static let fightButtonBottomPadding: CGFloat = 30

        // Separator
        static let separatorWidth: CGFloat = 2

        // Team combatant images (duel pairs display)
        static let teamImageSize: CGFloat = 20
        static let teamImageActiveSize: CGFloat = 30
        static let teamImageSpacing: CGFloat = 8
    }

    // MARK: - Fonts
    enum Fonts {
        static let roundNumber = Font.system(size: 24, weight: .bold)
        static let hpText = Font.system(size: 14, weight: .semibold)
        static let fightButton = Font.system(size: 18, weight: .bold)
        static let sectionLabel = Font.system(size: 14, weight: .medium)
        static let resultStatusText = Font.system(size: 12, weight: .bold)
    }

    // MARK: - Point Status Color Mapping
    static func color(for pointStatus: PointStatus) -> Color {
        switch pointStatus {
        case .blocked:
            return Colors.blocked
        case .hit:
            return Colors.hit
        case .critHit:
            return Colors.critHit
        case .dodged:
            return Colors.dodged
        case .nothing:
            return Colors.nothing
        }
    }
}
