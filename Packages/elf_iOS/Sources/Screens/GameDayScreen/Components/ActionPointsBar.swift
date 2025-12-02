//
//  ActionPointsBar.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI

struct ActionPointsBar: View {
    let current: Int
    let max: Int

    private var progress: Double {
        guard max > 0 else { return 0 }
        return Double(current) / Double(max)
    }

    var body: some View {
        VStack(spacing: GameDayConstants.Spacing.componentSpacing) {
            // Label
            Text("Action points")
                .font(GameDayConstants.Fonts.apFont)
                .foregroundColor(GameDayConstants.Colors.secondaryText)

            // Progress bar with text - uses scaleEffect instead of GeometryReader
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 15)
                    .fill(GameDayConstants.Colors.xpBarBackground)

                // Fill with clipShape for proper corner radius
                Rectangle()
                    .fill(GameDayConstants.Colors.apBarFill)
                    .scaleEffect(x: progress, y: 1, anchor: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                // Text overlay
                Text("\(current)/\(max)")
                    .font(GameDayConstants.Fonts.apFont)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: GameDayConstants.Sizing.apBarHeight)
        }
    }
}

#Preview {
    ActionPointsBar(current: 100, max: 100)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
