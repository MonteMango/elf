//
//  ElfFonts.swift
//  elf_SwiftUI
//

import SwiftUI

/// App-wide typography definitions.
public enum ElfFonts {
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
}
