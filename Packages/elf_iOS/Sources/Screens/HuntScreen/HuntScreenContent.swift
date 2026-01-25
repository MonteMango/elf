//
//  HuntScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct HuntScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HuntViewModel

    init(viewModel: HuntViewModel) {
        self._viewModel = State(initialValue: viewModel)
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

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: Back button + Action Points
            ScreenTopBar(
                currentActionPoints: viewModel.currentActionPoints,
                maxActionPoints: viewModel.maxActionPoints,
                isLastDay: viewModel.isLastDay,
                currentDay: CalendarDayData(
                    id: viewModel.currentDay.id,
                    dayNumber: viewModel.currentDay.dayNumber,
                    backgroundColor: ElfColors.Calendar.dayColor(for: viewModel.currentDay.dayType.rawValue)
                ),
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

            // Monster collection
            monsterCollection

            Spacer()

            // Hunt button
            huntButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ElfColors.Background.primary)
    }

    // MARK: - Monster Collection

    @ViewBuilder
    private var monsterCollection: some View {
        HStack(spacing: ElfSpacing.xxl) {
            ForEach(viewModel.availableMonstersDisplayData) { displayData in
                MonsterCell(displayData: displayData)
            }
        }
        .padding(.horizontal, ElfSpacing.screen)
    }

    // MARK: - Hunt Button

    @ViewBuilder
    private var huntButton: some View {
        Button("Hunt") {
            Task {
                if let battle = await viewModel.startHunt() {
                    router.navigationPath.append(AppRoute.battleFight(battle))
                }
            }
        }
        .buttonStyle(.elfPrimary(isEnabled: viewModel.canHunt))
        .disabled(!viewModel.canHunt)
        .overlay(alignment: .bottomTrailing) {
            Text("\(viewModel.huntCost) pt")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .padding(4)
        }
    }
}

#Preview {
    @Previewable @State var router = AppRouter()
    let container = ElfAppDependencyContainer()
    container.initializePreviewSession(game: PreviewMockData.createMockGame())

    return NavigationStack(path: $router.navigationPath) {
        HuntScreenContent(
            viewModel: container.makeHuntViewModel()
        )
        .environment(router)
    }
}
