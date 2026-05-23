//
//  ElfColors.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// App-wide color palette. Colors are fixed and do not depend on light/dark mode.
public enum ElfColors {

    // MARK: - Primary Colors

    public static let primary = Color.orange
    public static let success = Color.green
    public static let error = Color.red
    public static let info = Color.blue
    public static let warning = Color.yellow

    // Legacy aliases (for backwards compatibility)
    public static let elfOrange = Color.orange
    public static let elfRed = Color.red
    public static let elfGreen = Color.green
    public static let elfBlue = Color.blue

    // MARK: - Text Colors

    public enum Text {
        public static let primary = Color.black
        public static let primaryLight = Color.white
        public static let secondary = Color.gray
        public static let secondaryLight = Color.white.opacity(0.7)
        public static let accent = Color.orange
        public static let onAccent = Color.white
        public static let error = Color.red
        /// Hint text shown on top of a missing-image placeholder.
        public static let placeholderOnDark = Color.white.opacity(0.5)
    }

    // Legacy text colors (for backwards compatibility)
    public static let textPrimary = Color.black
    public static let textSecondary = Color.gray
    public static let textOnAccent = Color.white
    public static let textError = Color.red

    // MARK: - Background Colors

    public enum Background {
        public static let primary = Color.white
        public static let secondary = Color(white: 0.85)
        public static let dark = Color.black
        public static let panel = Color(red: 0.15, green: 0.15, blue: 0.2)
        public static let overlay = Color.black.opacity(0.7)
        public static let overlayMedium = Color.black.opacity(0.5)
        public static let overlayLight = Color.black.opacity(0.3)
        public static let card = Color(white: 0.96)
        /// Translucent white card used by squad cells laid over the dungeon background.
        public static let dungeonCard = Color.white.opacity(0.8)
        /// Translucent white pip behind compact squad-row portraits when not the hero.
        public static let compactPortraitFallback = Color.white.opacity(0.4)
    }

    // MARK: - Image Colors

    /// Semantic colors used as placeholders / backings for image content.
    public enum Image {
        /// Backing fill behind a hero / character image while it renders.
        public static let placeholder = Color.gray
        /// Soft tint behind a placeholder rectangle when an image asset is missing.
        public static let placeholderTint = Color.gray.opacity(0.3)
    }

    // Legacy background colors (for backwards compatibility)
    public static let backgroundPrimary = Color.white
    public static let backgroundSecondary = Color(white: 0.85)

    // MARK: - UI Elements

    public static let headerBackground = Color(red: 0.7, green: 0.85, blue: 0.95)
    public static let disabledBackground = Color.gray

    // MARK: - Button Colors

    public enum Button {
        public static let primary = Color.orange
        public static let primaryText = Color.white
        public static let secondary = Color.white
        public static let secondaryText = Color.orange
        public static let close = Color.red
        public static let closeText = Color.white
    }

    // MARK: - Progress Bar Colors

    public enum ProgressBar {
        public static let background = Color.gray.opacity(0.3)
        public static let materialBackground = Color.white
        public static let hp = Color.green
        public static let mp = Color.blue
        public static let xp = Color.blue
        public static let ap = Color.yellow
        public static let ep = Attributes.endurance
        public static let levelUpGlow = Color.yellow
        /// Background fill for compact resource bars rendered on translucent cards.
        public static let compactBackground = Color.white.opacity(0.25)
    }

    // Legacy stat colors (for backwards compatibility)
    public static let hp = Color.green
    public static let mana = Color.blue
    public static let reputation = Color.orange

    // MARK: - Battle Colors

    public enum Battle {
        public static let victory = Color.green
        public static let defeat = Color.red
        public static let draw = Color.orange
        public static let blocked = Color.green
        public static let hit = Color.red
        public static let critHit = Color.orange
        public static let dodged = Color.yellow
        public static let nothing = Color.gray.opacity(0.5)
    }

    // MARK: - Tier Colors (Fish, Items)

    public enum Tier {
        public static let tier1 = Color.purple       // Legendary
        public static let tier2 = Color.blue         // Rare
        public static let tier3 = Color.green        // Uncommon
        public static let tier4 = Color.gray         // Common

        /// Returns color for a tier level (1 = best/legendary, 4 = common)
        public static func color(for tier: Int) -> Color {
            switch tier {
            case 1: return tier1
            case 2: return tier2
            case 3: return tier3
            default: return tier4
            }
        }
    }

    // MARK: - Interactive Element Colors

    public enum Interactive {
        public static let normal = Color.gray.opacity(0.5)
        public static let selected = Color.orange
        public static let disabled = Color.gray.opacity(0.2)
        public static let border = Color.gray.opacity(0.5)
        public static let slotBackground = Color.gray.opacity(0.3)
    }

    // MARK: - Attribute Colors

    public enum Attributes {
        public static let strength = Color(red: 0.545, green: 0.361, blue: 0.965)   // #8B5CF6 Purple
        public static let agility = Color(red: 0.078, green: 0.722, blue: 0.651)    // #14B8A6 Teal
        public static let power = Color(red: 0.863, green: 0.149, blue: 0.149)      // #DC2626 Crimson
        public static let instinct = Color(red: 0.388, green: 0.400, blue: 0.945)   // #6366F1 Indigo
        public static let endurance = Color(red: 0.961, green: 0.620, blue: 0.043)  // #F59E0B Orange
    }

    // MARK: - Calendar Day Types

    public enum Calendar {
        public static let normalDay = Color(red: 0.847, green: 0.847, blue: 0.847)      // #D8D8D8
        public static let dungeonDay = Color(red: 0.851, green: 0.573, blue: 0.886)     // #D992E2
        public static let eventDay = Color(red: 0.573, green: 0.6, blue: 0.886)         // #9299E2
        public static let houseWarDay = Color(red: 0.886, green: 0.573, blue: 0.573)    // #E29292
        public static let unknownDay = Color.white
        public static let currentDayBorder = Color.orange
        public static let upcomingDayBorder = Color(white: 0.8)

        /// Returns color for day type based on raw value
        /// - Parameter rawValue: DayType.rawValue (0=normal, 1=dungeon, 2=randomEvent, 3=houseWar, 4+=unknown)
        public static func dayColor(for rawValue: Int) -> Color {
            switch rawValue {
            case 0: return normalDay
            case 1: return dungeonDay
            case 2: return eventDay
            case 3: return houseWarDay
            default: return unknownDay
            }
        }
    }
}

// MARK: - Selection Border

public extension View {
    @ViewBuilder
    func elfSelectionBorder(_ isSelected: Bool, cornerRadius: CGFloat = 0) -> some View {
        if cornerRadius > 0 {
            self.overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(isSelected ? ElfColors.primary : Color.clear, lineWidth: 3)
            )
        } else {
            self.overlay {
                Rectangle()
                    .strokeBorder(isSelected ? ElfColors.primary : Color.clear, lineWidth: 3)
            }
        }
    }
}
