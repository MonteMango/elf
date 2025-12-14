//
//  ElfSecondaryButtonStyle.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import SwiftUI

/// Secondary button style used for secondary action buttons throughout the app.
/// Standard size: 150x50, corner radius 8, white background, orange text.
public struct ElfSecondaryButtonStyle: ButtonStyle {
    public var isEnabled: Bool

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ElfFonts.buttonTitle)
            .foregroundColor(ElfColors.elfOrange)
            .frame(width: ElfSizing.buttonWidth, height: ElfSizing.buttonHeight)
            .background(isEnabled ? Color.white : ElfColors.disabledBackground)
            .cornerRadius(ElfSizing.buttonCornerRadius)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.6)
    }
}

// MARK: - ButtonStyle Extension

public extension ButtonStyle where Self == ElfSecondaryButtonStyle {
    /// Secondary button style with enabled state.
    static var elfSecondary: ElfSecondaryButtonStyle {
        ElfSecondaryButtonStyle()
    }

    /// Secondary button style with custom enabled state.
    static func elfSecondary(isEnabled: Bool) -> ElfSecondaryButtonStyle {
        ElfSecondaryButtonStyle(isEnabled: isEnabled)
    }
}
