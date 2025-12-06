//
//  CalendarScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import SwiftUI

/// Screen for displaying the full game calendar
struct CalendarScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    let calendar: [GameDay]
    let currentDayNumber: Int

    var body: some View {
        CalendarScreenContent(
            viewModel: CalendarViewModel(
                calendar: calendar,
                currentDayNumber: currentDayNumber,
                daysPerIteration: container.calendarService.daysPerIteration
            )
        )
    }
}
