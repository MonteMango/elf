//
//  ElfPrimaryButtonStyle.swift
//  elf_SwiftUI
//

import SwiftUI

/// Primary button style used for main action buttons throughout the app.
/// Standard size: 150x50, corner radius 8, orange background, white text.
public struct ElfPrimaryButtonStyle: ButtonStyle {
    public var isEnabled: Bool

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ElfFonts.buttonTitle)
            .foregroundColor(ElfColors.textOnAccent)
            .frame(width: ElfSizing.buttonWidth, height: ElfSizing.buttonHeight)
            .background(isEnabled ? ElfColors.elfOrange : ElfColors.disabledBackground)
            .cornerRadius(ElfSizing.buttonCornerRadius)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.6)
    }
}

// MARK: - ButtonStyle Extension

public extension ButtonStyle where Self == ElfPrimaryButtonStyle {
    /// Primary button style with enabled state.
    static var elfPrimary: ElfPrimaryButtonStyle {
        ElfPrimaryButtonStyle()
    }

    /// Primary button style with custom enabled state.
    static func elfPrimary(isEnabled: Bool) -> ElfPrimaryButtonStyle {
        ElfPrimaryButtonStyle(isEnabled: isEnabled)
    }
}
