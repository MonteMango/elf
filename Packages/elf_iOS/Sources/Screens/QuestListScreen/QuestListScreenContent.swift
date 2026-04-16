//
//  QuestListScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

// MARK: - QuestListScreenContent

struct QuestListScreenContent: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.questZoomNamespace) private var zoomNamespace
    @State private var viewModel: QuestListViewModel

    init(viewModel: QuestListViewModel) {
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
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 0) {
            ScreenTopBar(
                currentActionPoints: viewModel.actionPoints.current,
                maxActionPoints: viewModel.actionPoints.maximum,
                isLastDay: viewModel.isLastDay,
                currentDay: currentDayData,
                upcomingDays: upcomingDaysData,
                onNextDay: { Task { await viewModel.advanceToNextDay() } },
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

            questOwnersList

            Spacer()
        }
        .background(ElfColors.Background.primary)
    }

    // MARK: - Quest Owners List

    @ViewBuilder
    private var questOwnersList: some View {
        HStack(spacing: ElfSpacing.xxl) {
            ForEach(viewModel.questOwners) { owner in
                Button {
                    router.navigate(to: .quest(owner.questId, ownerImageName: owner.imageName))
                } label: {
                    QuestOwnerCell(
                        title: owner.title,
                        name: owner.name,
                        imageName: owner.imageName,
                        questTitle: owner.questTitle,
                        rewardText: owner.rewardText
                    )
                }
                .buttonStyle(.plain)
                .background {
                    Rectangle()
                        .fill(.clear)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .modifier(ZoomSourceModifier(
                    id: owner.imageName,
                    namespace: zoomNamespace
                ))
            }
        }
        .padding(.horizontal, ElfSpacing.screen)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    @Previewable @State var gameContainer: ElfGameContainer?
    @Previewable @State var router = AppRouter()

    if let gameContainer, gameContainer.activeGameService != nil {
        NavigationStack(path: $router.navigationPath) {
            QuestListScreenContent(
                viewModel: gameContainer.makeQuestListViewModel()
            )
            .environment(router)
            .environment(gameContainer)
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
