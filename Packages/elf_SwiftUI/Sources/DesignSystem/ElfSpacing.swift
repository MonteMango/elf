//
//  ElfSpacing.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// App-wide spacing and padding constants.
/// Uses semantic naming for easy understanding of intent.
public enum ElfSpacing {
    // MARK: - Scale

    public static let xxxs: CGFloat = 2
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 6
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 10
    public static let large: CGFloat = 12
    public static let xl: CGFloat = 16
    public static let xxl: CGFloat = 20
    public static let xxxl: CGFloat = 24
    public static let huge: CGFloat = 32

    // MARK: - Semantic Aliases

    /// Spacing within a component (5pt)
    public static let component: CGFloat = 5

    /// Spacing between sections (20pt)
    public static let section: CGFloat = 20

    /// Screen edge padding (20pt)
    public static let screen: CGFloat = 20

    /// Top padding for screen-level content directly below the safe area
    /// edge (segmented controls, headers, hero rows). Use this instead of
    /// `medium` / `xl` / literal values so every screen lines up the same.
    public static let screenTop: CGFloat = 10

    /// Spacing between buttons (25pt)
    public static let button: CGFloat = 25

    /// Grid spacing (1pt)
    public static let grid: CGFloat = 1
}
