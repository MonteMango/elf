//
//  GridCalendarView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Grid view of the calendar (10 rows × 16 columns)
struct GridCalendarView: View {
    let calendar: [GameDay]
    let currentDayNumber: Int
    let daysPerIteration: Int

    private let spacing: CGFloat = 4
    private let maxCellSize: CGFloat = 80
    private let columns: [GridItem]

    init(calendar: [GameDay], currentDayNumber: Int, daysPerIteration: Int) {
        self.calendar = calendar
        self.currentDayNumber = currentDayNumber
        self.daysPerIteration = daysPerIteration
        self.columns = Array(
            repeating: GridItem(.flexible(minimum: 30, maximum: 80), spacing: 4),
            count: daysPerIteration
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: spacing) {
                    // Header row with day numbers 1-16
                    headerRow

                    // Grid of days
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(calendar) { day in
                            DayCell(
                                day: day,
                                isCurrentDay: day.dayNumber == currentDayNumber
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .id(day.dayNumber)
                        }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.visible)
            .onAppear {
                // Scroll to current day
                withAnimation {
                    proxy.scrollTo(currentDayNumber, anchor: .center)
                }
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(1...daysPerIteration, id: \.self) { dayInIteration in
                Text("\(dayInIteration)")
                    .font(ElfFonts.Component.calendarHeader)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    let calendarService = DefaultCalendarService()
    let calendar = calendarService.generateFullCalendar()

    GridCalendarView(
        calendar: calendar,
        currentDayNumber: 25,
        daysPerIteration: calendarService.daysPerIteration
    )
    .background(Color.white)
}
