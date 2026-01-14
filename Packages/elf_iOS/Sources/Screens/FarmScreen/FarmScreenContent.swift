//
//  FarmScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct FarmScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: FarmViewModel

    init(viewModel: FarmViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Calendar Data

    private var currentDayData: CalendarDayData {
        CalendarDayData(
            id: viewModel.currentDay.id,
            dayNumber: viewModel.currentDay.dayNumber,
            backgroundColor: ElfColors.Calendar.dayColor(for: viewModel.currentDay.dayType.rawValue)
        )
    }

    private var upcomingDaysData: [CalendarDayData] {
        viewModel.upcomingDays.map {
            CalendarDayData(
                id: $0.id,
                dayNumber: $0.dayNumber,
                backgroundColor: ElfColors.Calendar.dayColor(for: $0.dayType.rawValue)
            )
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScreenTopBar(
                currentActionPoints: viewModel.currentActionPoints,
                maxActionPoints: viewModel.maxActionPoints,
                isLastDay: viewModel.isLastDay,
                currentDay: currentDayData,
                upcomingDays: upcomingDaysData,
                onNextDay: { viewModel.advanceToNextDay() },
                onBack: { router.pop() },
                onCalendarTap: {
                    router.navigate(to: .calendar(
                        calendar: viewModel.calendar,
                        currentDayNumber: viewModel.currentDay.dayNumber
                    ))
                }
            )
            .padding(.top, ElfSizing.standardPadding)
            .padding(.horizontal, FarmConstants.Spacing.horizontalPadding)

            Spacer()

            activityButtons

            Spacer()
        }
        .background(FarmConstants.Colors.background)
    }

    // MARK: - Activity Buttons

    @ViewBuilder
    private var activityButtons: some View {
        HStack(spacing: FarmConstants.Spacing.activitySpacing) {
            ForEach(FarmActivity.allCases) { activity in
                FarmActivityCell(
                    title: activity.title,
                    imageName: activity.imageName,
                    level: level(for: activity),
                    skillProgress: progress(for: activity),
                    action: {
                        // TODO: Navigate to activity
                    }
                )
            }
        }
        .padding(.horizontal, FarmConstants.Spacing.horizontalPadding)
    }

    // MARK: - Helpers

    private func level(for activity: FarmActivity) -> Int {
        switch activity {
        case .foraging: viewModel.foragingLevel
        case .fishing: viewModel.fishingLevel
        case .mining: viewModel.miningLevel
        }
    }

    private func progress(for activity: FarmActivity) -> Double {
        switch activity {
        case .foraging: viewModel.foragingProgress
        case .fishing: viewModel.fishingProgress
        case .mining: viewModel.miningProgress
        }
    }
}

#Preview {
    FarmScreenContent(
        viewModel: FarmViewModel(
            gameService: PreviewMockData.createMockGameService()
        )
    )
    .environment(AppRouter())
}
