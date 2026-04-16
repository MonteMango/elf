//
//  CalendarBodyView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import SwiftUI

/// Isolated component for viewMode changes
/// Only this view re-renders when viewMode changes, not the parent
struct CalendarBodyView: View {
    @Binding var viewMode: CalendarViewModel.ViewMode
    let calendar: [GameDay]
    let currentDayNumber: Int
    let daysPerIteration: Int

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 0) {
            // View mode picker (styled globally in ElfApp.configureAppearance)
            Picker("View Mode", selection: $viewMode) {
                ForEach(CalendarViewModel.ViewMode.allCases, id: \.self) { mode in
                    Label(mode.title, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding(.bottom, 20)

            // Content
            switch viewMode {
            case .line:
                LineCalendarView(
                    calendar: calendar,
                    currentDayNumber: currentDayNumber
                )
            case .grid:
                GridCalendarView(
                    calendar: calendar,
                    currentDayNumber: currentDayNumber,
                    daysPerIteration: daysPerIteration
                )
            }
        }
    }
}
