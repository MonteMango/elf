//
//  FarmConstants.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import SwiftUI

// MARK: - View Extensions

extension View {
    func textShadow() -> some View {
        shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
    }
}

// MARK: - Farm Activity

enum FarmActivity: String, CaseIterable, Identifiable {
    case foraging
    case fishing
    case mining

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var imageName: String { rawValue }
}

// MARK: - Constants

enum FarmConstants {

    // MARK: - Colors

    enum Colors {
        static let background = Color.white

        // Progress bar
        static let apBarFill = Color.yellow
        static let apBarBackground = Color(white: 0.9)

        // Activity cell
        static let activityLabelText = Color.orange
        static let levelText = Color.white
        static let skillBarFill = Color.blue
        static let skillBarBackground = Color.white.opacity(0.5)
    }

    // MARK: - Spacing

    enum Spacing {
        static let horizontalPadding: CGFloat = 20
        static let activitySpacing: CGFloat = 20
    }

    // MARK: - Sizing

    enum Sizing {
        // Action points bar
        static let apBarHeight: CGFloat = 30
        static let apBarWidth: CGFloat = 300

        // Activity cell
        static let activityCellWidth: CGFloat = 200
        static let activityCellHeight: CGFloat = 200
        static let skillBarHeight: CGFloat = 4
    }

    // MARK: - Fonts

    enum Fonts {
        static let apLabel = Font.system(size: 14, weight: .medium)
        static let apValue = Font.system(size: 14, weight: .bold)
        static let activityLabel = Font.system(size: 36, weight: .bold)
        static let levelText = Font.system(size: 24, weight: .bold)
    }
}
