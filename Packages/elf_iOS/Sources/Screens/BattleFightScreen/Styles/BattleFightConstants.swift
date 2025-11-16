//
//  BattleFightConstants.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import SwiftUI
import elf_Kit

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
        static let separator = Color.white.opacity(0.5)
    }

    // MARK: - Sizing
    enum Sizing {
        // Hero display
        static let heroImageSize: CGFloat = 100
        static let itemIconSize: CGFloat = 25

        // HP bar
        static let hpBarHeight: CGFloat = 20
        static let hpBarCornerRadius: CGFloat = 10

        // Checkboxes
        static let checkboxSize: CGFloat = 30
        static let checkboxCornerRadius: CGFloat = 5
        static let checkboxBorderWidth: CGFloat = 2

        // Result dots
        static let resultDotSize: CGFloat = 8

        // Buttons
        static let fightButtonWidth: CGFloat = 200
        static let fightButtonHeight: CGFloat = 50
        static let closeButtonSize: CGFloat = 40

        // Spacing
        static let roundNumberTopPadding: CGFloat = 20
        static let heroPanelSpacing: CGFloat = 30
        static let itemSpacing: CGFloat = 5
    }

    // MARK: - Fonts
    enum Fonts {
        static let roundNumber = Font.system(size: 24, weight: .bold)
        static let hpText = Font.system(size: 14, weight: .semibold)
        static let fightButton = Font.system(size: 18, weight: .bold)
        static let sectionLabel = Font.system(size: 14, weight: .medium)
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
