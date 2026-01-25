//
//  FarmScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

// MARK: - FarmScreenContent

struct FarmScreenContent: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.farmZoomNamespace) private var zoomNamespace
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
            .padding(.horizontal, ElfSpacing.screen)

            Spacer()

            activityButtons

            Spacer()
        }
        .background(ElfColors.Background.primary)
    }

    // MARK: - Activity Buttons

    @ViewBuilder
    private var activityButtons: some View {
        HStack(spacing: ElfSpacing.xxl) {
            ForEach(FarmActivity.allCases) { activity in
                FarmActivityCell(
                    title: activity.title,
                    imageName: activity.imageName,
                    level: level(for: activity),
                    skillProgress: progress(for: activity),
                    action: {
                        router.navigate(to: .farmActivity(activity))
                    }
                )
                .modifier(FarmZoomSourceModifier(id: activity.id, namespace: zoomNamespace))
            }
        }
        .padding(.horizontal, ElfSpacing.screen)
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

// MARK: - Preview

#Preview {
    @Previewable @State var router = AppRouter()
    let container = ElfAppDependencyContainer()
    container.initializePreviewSession(game: PreviewMockData.createMockGame())

    return NavigationStack(path: $router.navigationPath) {
        FarmScreenContent(
            viewModel: container.makeFarmViewModel()
        )
        .environment(router)
        .environment(container)
    }
}
