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
    @State private var viewModel: ElfAppDependencyContainer.HuntVM

    init(viewModel: ElfAppDependencyContainer.HuntVM) {
        self._viewModel = State(initialValue: viewModel)
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
                upcomingDays: viewModel.upcomingDays.map {
                    CalendarDayData(
                        id: $0.id,
                        dayNumber: $0.dayNumber,
                        backgroundColor: ElfColors.Calendar.dayColor(for: $0.dayType.rawValue)
                    )
                },
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
                .padding(.bottom, ElfSpacing.huge)
        }
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
                .foregroundColor(.white.opacity(0.7))
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
