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
}
