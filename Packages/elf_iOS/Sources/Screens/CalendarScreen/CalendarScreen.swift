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
    @Environment(ElfGameContainer.self) private var gameContainer

    let calendar: [GameDay]
    let currentDayNumber: Int

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = gameContainer.sessionModel {
            CalendarScreenContent(
                viewModel: session.makeCalendarViewModel(
                    calendar: calendar,
                    currentDayNumber: currentDayNumber
                )
            )
        }
    }
}
