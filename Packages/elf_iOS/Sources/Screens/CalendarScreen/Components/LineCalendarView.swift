//
//  LineCalendarView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import SwiftUI

/// Horizontal scrollable line view of the calendar
struct LineCalendarView: View {
    let calendar: [GameDay]
    let currentDayNumber: Int

    private let cellSize: CGFloat = 70
    private let spacing: CGFloat = 12

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: spacing) {
                    ForEach(calendar) { day in
                        DayCell(
                            day: day,
                            isCurrentDay: day.dayNumber == currentDayNumber
                        )
                        .frame(width: cellSize, height: cellSize)
                        .id(day.dayNumber)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                // Scroll to current day with some offset to show context
                withAnimation {
                    proxy.scrollTo(currentDayNumber, anchor: .center)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    LineCalendarView(
        calendar: PreviewMockData.createMockCalendar(),
        currentDayNumber: 25
    )
    .frame(height: 150)
    .background(Color.white)
}
#endif
