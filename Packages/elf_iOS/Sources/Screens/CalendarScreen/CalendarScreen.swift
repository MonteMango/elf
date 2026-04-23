//
//  CalendarScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Screen for displaying the full game calendar
struct CalendarScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CalendarViewModel

    init(calendar: [GameDay], currentDayNumber: Int) {
        self._viewModel = State(initialValue: CalendarViewModel(
            calendar: calendar,
            currentDayNumber: currentDayNumber
        ))
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
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

#if DEBUG
#Preview {
    CalendarScreen(
        calendar: PreviewMockData.createMockCalendar(),
        currentDayNumber: 25
    )
}
#endif
