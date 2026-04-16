//
//  ScreenTopBar.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 09.01.26.
//

import SwiftUI

/// A reusable top bar component with back button, action points bar, and calendar section.
/// Used in Hunt, Farm, and similar sub-screens.
public struct ScreenTopBar: View {
    let currentActionPoints: Int
    let maxActionPoints: Int
    let isLastDay: Bool
    let currentDay: CalendarDayData
    let upcomingDays: [CalendarDayData]
    let onNextDay: () -> Void
    let onBack: () -> Void
    let onCalendarTap: () -> Void

    public init(
        currentActionPoints: Int,
        maxActionPoints: Int,
        isLastDay: Bool,
        currentDay: CalendarDayData,
        upcomingDays: [CalendarDayData],
        onNextDay: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onCalendarTap: @escaping () -> Void
    ) {
        self.currentActionPoints = currentActionPoints
        self.maxActionPoints = maxActionPoints
        self.isLastDay = isLastDay
        self.currentDay = currentDay
        self.upcomingDays = upcomingDays
        self.onNextDay = onNextDay
        self.onBack = onBack
        self.onCalendarTap = onCalendarTap
    }

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ZStack(alignment: .top) {
            ActionPointsBar(
                current: currentActionPoints,
                max: maxActionPoints,
                showNextDayButton: true,
                isLastDay: isLastDay,
                onNextDay: onNextDay
            )
            .frame(width: 300)
            .overlay(alignment: .topTrailing) {
                CalendarSection(
                    currentDay: currentDay,
                    upcomingDays: upcomingDays,
                    onTap: onCalendarTap
                )
                .alignmentGuide(.trailing) { d in d[.leading] - 16 }
            }

            // Back button on the left
            HStack(alignment: .top) {
                BackButton(action: onBack)
                Spacer()
            }
        }
    }
}

#Preview {
    VStack {
        ScreenTopBar(
            currentActionPoints: 75,
            maxActionPoints: 100,
            isLastDay: false,
            currentDay: CalendarDayData(
                id: UUID(),
                dayNumber: 1,
                backgroundColor: .blue
            ),
            upcomingDays: [
                CalendarDayData(id: UUID(), dayNumber: 2, backgroundColor: .green),
                CalendarDayData(id: UUID(), dayNumber: 3, backgroundColor: .orange)
            ],
            onNextDay: { print("Next day") },
            onBack: { print("Back") },
            onCalendarTap: { print("Calendar") }
        )
        .padding()

        Spacer()
    }
    .background(Color.white)
}
