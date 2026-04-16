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
    let dayStateViewModel: GameDayStateViewModel

    init(viewModel: FarmViewModel, dayStateViewModel: GameDayStateViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self.dayStateViewModel = dayStateViewModel
    }

    // MARK: - Body

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 0) {
            GameDayHeader(
                viewModel: dayStateViewModel,
                onBack: { router.pop() },
                onCalendarTap: {
                    router.navigate(to: .calendar(
                        calendar: dayStateViewModel.calendar,
                        currentDayNumber: dayStateViewModel.currentDay.dayNumber
                    ))
                }
            )

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
                .modifier(ZoomSourceModifier(id: activity.id, namespace: zoomNamespace))
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

#if DEBUG
#Preview {
    @Previewable @State var gameContainer: ElfGameContainer?
    @Previewable @State var router = AppRouter()

    if let gameContainer, gameContainer.activeGameService != nil {
        NavigationStack(path: $router.navigationPath) {
            FarmScreenContent(
                viewModel: gameContainer.makeFarmViewModel(),
                dayStateViewModel: gameContainer.requireGameDayStateViewModel()
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
