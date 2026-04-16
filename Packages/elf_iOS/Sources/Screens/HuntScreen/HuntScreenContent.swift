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
    @Environment(DefaultGameService.self) private var gameService
    @State private var viewModel: HuntViewModel

    init(viewModel: HuntViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    private var currentDayData: CalendarDayData {
        CalendarDayData(
            id: gameService.currentDay.id,
            dayNumber: gameService.currentDay.dayNumber,
            backgroundColor: ElfColors.Calendar.dayColor(for: gameService.currentDay.dayType.rawValue)
        )
    }

    private var upcomingDaysData: [CalendarDayData] {
        gameService.upcomingDays.map {
            CalendarDayData(
                id: $0.id,
                dayNumber: $0.dayNumber,
                backgroundColor: ElfColors.Calendar.dayColor(for: $0.dayType.rawValue)
            )
        }
    }

    private var canHunt: Bool {
        gameService.actionPoints.current >= viewModel.huntCost && !viewModel.isHunting
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenTopBar(
                currentActionPoints: gameService.actionPoints.current,
                maxActionPoints: gameService.actionPoints.maximum,
                isLastDay: gameService.isLastDay,
                currentDay: currentDayData,
                upcomingDays: upcomingDaysData,
                onNextDay: { Task { await viewModel.advanceToNextDay() } },
                onBack: { router.pop() },
                onCalendarTap: {
                    router.navigate(to: .calendar(
                        calendar: gameService.calendar,
                        currentDayNumber: gameService.currentDay.dayNumber
                    ))
                }
            )
            .padding(.top, ElfSizing.standardPadding)
            .padding(.horizontal, ElfSpacing.screen)

            Spacer()

            monsterCollection

            Spacer()

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
            if let battle = viewModel.startHunt() {
                router.navigationPath.append(AppRoute.battleFight(battle))
            }
        }
        .buttonStyle(.elfPrimary(isEnabled: canHunt))
        .disabled(!canHunt)
        .overlay(alignment: .bottomTrailing) {
            Text("\(viewModel.huntCost) pt")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .padding(4)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var gameContainer: ElfGameContainer?
    @Previewable @State var router = AppRouter()

    if let gameContainer, let gameService = gameContainer.activeGameService {
        NavigationStack(path: $router.navigationPath) {
            HuntScreenContent(
                viewModel: gameContainer.makeHuntViewModel()
            )
            .environment(router)
            .environment(gameService)
        }
    } else {
        ProgressView()
            .task {
                let container = await ElfGameContainer()
                container.initializePreviewSession(game: PreviewMockData.createMockGame())
                gameContainer = container
            }
    }
}
#endif
