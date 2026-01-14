//
//  ElfShadows.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// App-wide shadow definitions.
public enum ElfShadows {

    public struct Shadow: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat

        public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }

    public static let small = Shadow(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )

    public static let medium = Shadow(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )

    public static let large = Shadow(
        color: Color.black.opacity(0.2),
        radius: 8,
        x: 0,
        y: 4
    )

    public static let button = Shadow(
        color: Color.black.opacity(0.3),
        radius: 3,
        x: 0,
        y: 2
    )
}

// MARK: - View Extension

public extension View {
    func elfShadow(_ shadow: ElfShadows.Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
