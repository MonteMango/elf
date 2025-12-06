//
//  CalendarScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import SwiftUI

struct CalendarScreenContent: View {
    @Environment(AppRouter.self) private var router
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
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            // Title
            Text("Calendar")
                .foregroundStyle(.black)
                .font(.title2)
                .fontWeight(.bold)

            // Back button
            HStack {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "arrow.backward")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.orange)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    @Previewable @State var router = AppRouter()
    let calendarService = DefaultCalendarService()
    let calendar = calendarService.generateFullCalendar()

    CalendarScreenContent(
        viewModel: CalendarViewModel(
            calendar: calendar,
            currentDayNumber: 25,
            daysPerIteration: calendarService.daysPerIteration
        )
    )
    .environment(router)
}
