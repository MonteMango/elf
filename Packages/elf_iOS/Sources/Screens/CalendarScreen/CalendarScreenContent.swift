//
//  CalendarScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct CalendarScreenContent: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CalendarViewModel

    init(viewModel: CalendarViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - does NOT read viewMode, won't re-render on mode change
            header

            // Isolated component - only this re-renders when viewMode changes
            CalendarBodyView(
                viewMode: $viewModel.viewMode,
                calendar: viewModel.calendar,
                currentDayNumber: viewModel.currentDayNumber,
                daysPerIteration: viewModel.daysPerIteration
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            // Title
            Text("Calendar")
                .foregroundStyle(.black)
                .font(.title2)
                .bold()

            // Back button
            HStack {
                BackButton {
                    dismiss()
                }

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    let calendarService = DefaultCalendarService()
    let calendar = calendarService.generateFullCalendar()

    CalendarScreenContent(
        viewModel: CalendarViewModel(
            calendar: calendar,
            currentDayNumber: 25,
            daysPerIteration: calendarService.daysPerIteration
        )
    )
}
