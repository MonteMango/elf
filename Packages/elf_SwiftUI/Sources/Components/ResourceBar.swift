//
//  ResourceBar.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Compact three-column resource bar: short label · thin fill bar · numeric.
/// Used for HP/MP in DungeonScreen Squad cells; reusable for future combat,
/// inventory, and stat screens.
public struct ResourceBar: View {

    // MARK: - Properties

    let label: String
    let current: Int
    let max: Int
    let color: Color

    // MARK: - Constants

    private let labelWidth: CGFloat = 20
    private let numericWidth: CGFloat = 50

    // MARK: - Init

    public init(label: String, current: Int, max: Int, color: Color) {
        self.label = label
        self.current = current
        self.max = max
        self.color = color
    }

    // MARK: - Body

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(spacing: ElfSpacing.xs) {
            Text(label)
                .font(ElfFonts.Component.statLabel)
                .foregroundStyle(ElfColors.Text.secondary)
                .frame(width: labelWidth, alignment: .leading)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(ElfColors.ProgressBar.background)

                Rectangle()
                    .fill(color)
                    .scaleEffect(x: progress, y: 1, anchor: .leading)
            }
            .frame(height: ElfSizing.ProgressBar.thin)

            Text("\(current)/\(max)")
                .font(ElfFonts.Component.statLabel)
                .foregroundStyle(ElfColors.Text.secondary)
                .frame(width: numericWidth, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(current) of \(max)")
    }

    // MARK: - Computed

    private var progress: Double {
        guard max > 0 else { return 0 }
        return Double(current) / Double(max)
    }
}

#Preview {
    VStack(spacing: 8) {
        ResourceBar(label: "HP", current: 83, max: 83, color: ElfColors.ProgressBar.hp)
        ResourceBar(label: "MP", current: 14, max: 20, color: ElfColors.ProgressBar.mp)
    }
    .padding()
    .background(Color.white.opacity(0.8))
}
