//
//  ElfPrimaryButtonStyle.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import SwiftUI

// MARK: - Flexible Button Style

/// Flexible button style with customizable size.
/// Use for contextual buttons like "Next day" in ActionPointsBar.
public struct ElfFlexibleButtonStyle: ButtonStyle {
    public var isEnabled: Bool
    public var width: CGFloat?
    public var height: CGFloat
    public var cornerRadius: CGFloat

    public init(
        isEnabled: Bool = true,
        width: CGFloat? = nil,
        height: CGFloat = ElfSizing.buttonHeight,
        cornerRadius: CGFloat = ElfSizing.buttonCornerRadius
    ) {
        self.isEnabled = isEnabled
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ElfFonts.buttonTitle)
            .foregroundStyle(ElfColors.Button.primaryText)
            .frame(maxWidth: width ?? .infinity)
            .frame(height: height)
            .background(
                isEnabled ? ElfColors.Button.primary : ElfColors.disabledBackground,
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .elfShadow(ElfShadows.button)
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.6)
    }
}

// MARK: - Primary Button Style

/// Primary button style with fixed 150×50 size.
/// Use for main action buttons (Hunt, Fight, etc.)
public struct ElfPrimaryButtonStyle: ButtonStyle {
    public var isEnabled: Bool

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        ElfFlexibleButtonStyle(
            isEnabled: isEnabled,
            width: ElfSizing.buttonWidth,
            height: ElfSizing.buttonHeight,
            cornerRadius: ElfSizing.buttonCornerRadius
        ).makeBody(configuration: configuration)
    }
}

// MARK: - ButtonStyle Extensions

public extension ButtonStyle where Self == ElfPrimaryButtonStyle {
    /// Primary button style with default enabled state
    static var elfPrimary: ElfPrimaryButtonStyle {
        ElfPrimaryButtonStyle()
    }

    /// Primary button style with custom enabled state
    static func elfPrimary(isEnabled: Bool) -> ElfPrimaryButtonStyle {
        ElfPrimaryButtonStyle(isEnabled: isEnabled)
    }
}

public extension ButtonStyle where Self == ElfFlexibleButtonStyle {
    /// Flexible button style with default parameters
    static var elfFlexible: ElfFlexibleButtonStyle {
        ElfFlexibleButtonStyle()
    }

    /// Flexible button style with custom parameters
    static func elfFlexible(
        isEnabled: Bool = true,
        width: CGFloat? = nil,
        height: CGFloat = ElfSizing.buttonHeight,
        cornerRadius: CGFloat = ElfSizing.buttonCornerRadius
    ) -> ElfFlexibleButtonStyle {
        ElfFlexibleButtonStyle(
            isEnabled: isEnabled,
            width: width,
            height: height,
            cornerRadius: cornerRadius
        )
    }
}
