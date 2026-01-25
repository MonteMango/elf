//
//  ActionPointsBar.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import SwiftUI

/// A progress bar for displaying action points.
/// When action points reach 0 and `showNextDayButton` is true, displays a "Next day" button instead.
public struct ActionPointsBar: View {
    let current: Int
    let max: Int
    let showNextDayButton: Bool
    let isLastDay: Bool
    let nextDayButtonText: String
    let onNextDay: (() -> Void)?

    public init(
        current: Int,
        max: Int,
        showNextDayButton: Bool = false,
        isLastDay: Bool = false,
        nextDayButtonText: String = "Next day",
        onNextDay: (() -> Void)? = nil
    ) {
        self.current = current
        self.max = max
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
            Text("Action points")
                .font(ElfFonts.Component.statLabel)
                .foregroundStyle(ElfColors.Text.secondary)

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
            // Background with Material Design style
            RoundedRectangle(cornerRadius: ElfSizing.ProgressBar.large / 2)
                .fill(ElfColors.ProgressBar.materialBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Progress fill
            Rectangle()
                .fill(ElfColors.ProgressBar.ap)
                .scaleEffect(x: progress, y: 1, anchor: .leading)
                .clipShape(RoundedRectangle(cornerRadius: ElfSizing.ProgressBar.large / 2))

            // Text
            Text("\(current)/\(max)")
                .font(ElfFonts.Component.apFont)
                .foregroundStyle(ElfColors.Text.primary)
                .frame(maxWidth: .infinity)
        }
        .frame(height: ElfSizing.ProgressBar.large)
    }

    private var nextDayButton: some View {
        Button(nextDayButtonText) {
            onNextDay?()
        }
        .buttonStyle(.elfFlexible(
            isEnabled: !isLastDay,
            height: ElfSizing.ProgressBar.large,
            cornerRadius: ElfSizing.ProgressBar.large / 2
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
    .background(ElfColors.Background.secondary)
}
