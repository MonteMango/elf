//
//  GameDayHeader.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Composite top-bar used by every day-bound screen (Hunt, Farm, FarmActivity,
/// Quest, QuestList). Wraps `ScreenTopBar` with data from the shared
/// `GameDayStateViewModel` and delegates the back / calendar actions to the
/// hosting screen.
struct GameDayHeader: View {
    @Environment(AppRouter.self) private var router
    let viewModel: GameDayStateViewModel
    let onBack: () -> Void
    let onCalendarTap: () -> Void

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ScreenTopBar(
            currentActionPoints: viewModel.actionPoints.current,
            maxActionPoints: viewModel.actionPoints.maximum,
            isLastDay: viewModel.isLastDay,
            currentDay: viewModel.currentDay.calendarDayData,
            upcomingDays: viewModel.upcomingDays.map(\.calendarDayData),
            onNextDay: {
                Task {
                    await viewModel.advanceToNextDay()
                    if viewModel.currentDay.dayType != .normal {
                        router.popToGameDay()
                    }
                }
            },
            onBack: onBack,
            onCalendarTap: onCalendarTap
        )
        .padding(.top, ElfSizing.standardPadding)
        .padding(.horizontal, ElfSpacing.screen)
    }
}
