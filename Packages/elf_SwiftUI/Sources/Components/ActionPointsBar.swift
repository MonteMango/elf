//
//  ActionPointsBar.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import SwiftUI

/// A reusable progress bar for displaying action points or similar resources.
/// When action points reach 0 and `showNextDayButton` is true, displays a "Next day" button instead.
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

    // Next day button configuration
    let showNextDayButton: Bool
    let isLastDay: Bool
    let nextDayButtonText: String
    let onNextDay: (() -> Void)?

    public init(
        current: Int,
        max: Int,
        label: String = "Action points",
        barHeight: CGFloat = ElfSizing.ProgressBar.large,
        labelFont: Font = ElfFonts.Component.statLabel,
        barFont: Font = ElfFonts.Component.apFont,
        labelColor: Color = ElfColors.Text.secondary,
        fillColor: Color = ElfColors.ProgressBar.ap,
        backgroundColor: Color = ElfColors.ProgressBar.background,
        showNextDayButton: Bool = false,
        isLastDay: Bool = false,
        nextDayButtonText: String = "Next day",
        onNextDay: (() -> Void)? = nil
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
        self.showNextDayButton = showNextDayButton
        self.isLastDay = isLastDay
        self.nextDayButtonText = nextDayButtonText
        self.onNextDay = onNextDay
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

            // Progress bar OR Next Day button
            if showNextDayButton && current == 0 {
                nextDayButton
            } else {
                progressBar
            }
        }
    }

    // MARK: - Private Views

    private var progressBar: some View {
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
                .foregroundColor(ElfColors.Text.primary)
                .frame(maxWidth: .infinity)
        }
        .frame(height: barHeight)
    }

    private var nextDayButton: some View {
        Button(nextDayButtonText) {
            onNextDay?()
        }
        .buttonStyle(.elfFlexible(
            isEnabled: !isLastDay,
            height: barHeight,
            cornerRadius: barHeight / 2
        ))
        .disabled(isLastDay)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Standard progress bar states
        ActionPointsBar(current: 100, max: 100)
        ActionPointsBar(current: 50, max: 100)
        ActionPointsBar(current: 0, max: 100)

        Divider()

        // Next day button (active)
        ActionPointsBar(
            current: 0,
            max: 100,
            showNextDayButton: true,
            isLastDay: false,
            onNextDay: { print("Next day tapped") }
        )

        // Next day button (disabled - last day)
        ActionPointsBar(
            current: 0,
            max: 100,
            showNextDayButton: true,
            isLastDay: true,
            onNextDay: { print("Should not fire") }
        )
    }
    .padding()
    .background(Color.white)
}
