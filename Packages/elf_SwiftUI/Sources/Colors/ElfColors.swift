//
//  ElfColors.swift
//  elf_SwiftUI
//

import SwiftUI

/// App-wide color palette. Colors are fixed and do not depend on light/dark mode.
public enum ElfColors {
    // MARK: - Primary Colors

    public static let elfOrange = Color.orange
    public static let elfRed = Color.red
    public static let elfGreen = Color.green
    public static let elfBlue = Color.blue

    // MARK: - Text Colors

    public static let textPrimary = Color.black
    public static let textSecondary = Color.gray
    public static let textOnAccent = Color.white
    public static let textError = Color.red

    // MARK: - Background Colors

    public static let backgroundPrimary = Color.white
    public static let backgroundSecondary = Color(white: 0.85)

    // MARK: - UI Elements

    public static let headerBackground = Color(red: 0.7, green: 0.85, blue: 0.95)
    public static let disabledBackground = Color.gray

    // MARK: - Stats Colors

    public static let hp = Color.green
    public static let mana = Color.blue
    public static let reputation = Color.orange

    // MARK: - Attribute Colors

    public enum Attributes {
        public static let strength = Color(red: 0.545, green: 0.361, blue: 0.965)   // #8B5CF6 Purple
        public static let agility = Color(red: 0.078, green: 0.722, blue: 0.651)    // #14B8A6 Teal
        public static let power = Color(red: 0.863, green: 0.149, blue: 0.149)      // #DC2626 Crimson
        public static let instinct = Color(red: 0.388, green: 0.400, blue: 0.945)   // #6366F1 Indigo
    }

    // MARK: - Calendar Day Types

    public enum Calendar {
        public static let normalDay = Color(red: 0.847, green: 0.847, blue: 0.847)      // #D8D8D8
        public static let dungeonDay = Color(red: 0.851, green: 0.573, blue: 0.886)     // #D992E2
        public static let eventDay = Color(red: 0.573, green: 0.6, blue: 0.886)         // #9299E2
        public static let houseWarDay = Color(red: 0.886, green: 0.573, blue: 0.573)    // #E29292
        public static let unknownDay = Color.white
    }
}
