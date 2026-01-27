//
//  ElfSizing.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// App-wide sizing constants for UI components.
public enum ElfSizing {

    // MARK: - Touch Targets

    /// Minimum touch target size per Apple HIG (44pt)
    public static let minTouchTarget: CGFloat = 44

    // MARK: - Standard Padding

    public static let standardPadding: CGFloat = 10

    // MARK: - Icons

    public enum Icon {
        public static let tiny: CGFloat = 15
        public static let small: CGFloat = 20
        public static let medium: CGFloat = 30
        public static let large: CGFloat = 40
        public static let xlarge: CGFloat = 50
    }

    // Legacy alias
    public static let attributeIconSize: CGFloat = 20

    // MARK: - Buttons

    public enum Button {
        public static let height: CGFloat = 50
        public static let heightSmall: CGFloat = 40
        public static let heightLarge: CGFloat = 60

        public static let widthCompact: CGFloat = 140
        public static let widthStandard: CGFloat = 150
        public static let widthWide: CGFloat = 200
        public static let widthExtraWide: CGFloat = 250

        public static let closeSize: CGFloat = 44
        public static let sideSize: CGFloat = 50
    }

    // Legacy button aliases
    public static let buttonWidth: CGFloat = 150
    public static let buttonHeight: CGFloat = 50
    public static let buttonCornerRadius: CGFloat = 8
    public static let closeButtonSize: CGFloat = 44

    // MARK: - Progress Bars

    public enum ProgressBar {
        public static let thin: CGFloat = 4
        public static let regular: CGFloat = 14
        public static let standard: CGFloat = 16
        public static let thick: CGFloat = 24
        public static let large: CGFloat = 30
    }

    // MARK: - Cells and Slots

    public enum Cell {
        public static let tiny: CGFloat = 28
        public static let small: CGFloat = 35
        public static let medium: CGFloat = 45
        public static let large: CGFloat = 50
    }

    // MARK: - Item Cards

    public enum ItemCard {
        public static let size: CGFloat = 45
        public static let borderWidth: CGFloat = 2
    }

    // MARK: - GameDay Screen Specific

    public enum GameDay {
        public static let heroImageWidth: CGFloat = 100
        public static let heroImageHeight: CGFloat = 180
        public static let equipmentSlotSize: CGFloat = 40
        public static let equipmentIconSize: CGFloat = 30
        public static let calendarDaySize: CGFloat = 50
        public static let pocketSize: CGFloat = 35
        public static let buffSize: CGFloat = 30
        public static let actionButtonWidth: CGFloat = 200
        public static let actionButtonCornerRadius: CGFloat = 12
        public static let sideButtonCornerRadius: CGFloat = 8
    }

    // MARK: - Battle Result Screen Specific

    public enum BattleResult {
        public static let cardMaxWidth: CGFloat = 600
        public static let cardPadding: CGFloat = 20
        public static let cardVerticalPadding: CGFloat = 30
        public static let cardCornerRadius: CGFloat = 16
        public static let headerWidth: CGFloat = 120
        public static let outcomeIconSize: CGFloat = 40
        public static let dropItemSize: CGFloat = 50
        public static let dropItemIconSize: CGFloat = 28
        public static let dropItemBorderWidth: CGFloat = 2
        public static let dropItemSpacing: CGFloat = 10
        public static let levelBadgeSize: CGFloat = 28
        public static let xpBarWidth: CGFloat = 250
        public static let xpBarHeight: CGFloat = 14
        public static let xpBarCornerRadius: CGFloat = 7
        public static let continueButtonWidth: CGFloat = 140
        public static let separatorWidth: CGFloat = 1
        public static let sectionSpacing: CGFloat = 16
        public static let smallSpacing: CGFloat = 6
    }

    // MARK: - Battle Fight Screen Specific

    public enum BattleFight {
        public static let hpBarHeight: CGFloat = 24
        public static let checkboxSize: CGFloat = 45
        public static let separatorHeight: CGFloat = 1
        public static let teamImageSize: CGFloat = 20
        public static let teamImageActiveSize: CGFloat = 30
        public static let battleItemSize: CGFloat = 20
        public static let battleJewelrySize: CGFloat = 15
    }

    // MARK: - Hunt Screen Specific

    public enum Hunt {
        public static let monsterImageSize: CGFloat = 60
        public static let monsterCellHeight: CGFloat = 80
        public static let dropItemSize: CGFloat = 40
    }

    // MARK: - Farm Screen Specific

    public enum Farm {
        public static let activityCellHeight: CGFloat = 60
        public static let skillBarHeight: CGFloat = 8
    }

    // MARK: - Fishing Result Screen Specific

    public enum FishingResult {
        public static let cardWidth: CGFloat = 500
        public static let cardHeight: CGFloat = 340
    }

    // MARK: - Fishing In Progress Overlay

    public enum FishingProgress {
        public static let width: CGFloat = 300
        public static let height: CGFloat = 200
    }

    // MARK: - Monster Attack Alert Overlay

    public enum MonsterAlert {
        public static let width: CGFloat = 400
    }
}
