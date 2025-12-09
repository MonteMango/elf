//
//  ActionPointsBar.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import SwiftUI

/// A reusable progress bar for displaying action points or similar resources.
public struct ActionPointsBar: View {
    let current: Int
    let max: Int
    let label: String
    let barHeight: CGFloat
    let labelFont: Font
    let barFont: Font
    let labelColor: Color
    let fillColor: Color
    let backgroundColor: Color

    public init(
        current: Int,
        max: Int,
        label: String = "Action points",
        barHeight: CGFloat = 30,
        labelFont: Font = .system(size: 14),
        barFont: Font = .system(size: 14, weight: .medium),
        labelColor: Color = .gray,
        fillColor: Color = .yellow,
        backgroundColor: Color = Color(white: 0.9)
    ) {
        self.current = current
        self.max = max
        self.label = label
        self.barHeight = barHeight
        self.labelFont = labelFont
        self.barFont = barFont
        self.labelColor = labelColor
        self.fillColor = fillColor
        self.backgroundColor = backgroundColor
    }

    private var progress: Double {
        guard max > 0 else { return 0 }
        return Double(current) / Double(max)
    }

    public var body: some View {
        VStack(spacing: 4) {
            // Label
            Text(label)
                .font(labelFont)
                .foregroundColor(labelColor)

            // Progress bar with text
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(backgroundColor)

                // Fill with clipShape for proper corner radius
                Rectangle()
                    .fill(fillColor)
                    .scaleEffect(x: progress, y: 1, anchor: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: barHeight / 2))

                // Text overlay
                Text("\(current)/\(max)")
                    .font(barFont)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: barHeight)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ActionPointsBar(current: 100, max: 100)
        ActionPointsBar(current: 50, max: 100)
        ActionPointsBar(current: 0, max: 100)
    }
    .padding()
    .background(Color.white)
}
