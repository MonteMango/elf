//
//  QuestListScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

// MARK: - QuestListScreen

struct QuestListScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.questZoomNamespace) private var zoomNamespace
    @State private var viewModel: QuestListViewModel
    @Environment(GameDayStateViewModel.self) private var dayStateViewModel

    init(session: GameSession) {
        self._viewModel = State(initialValue: session.makeQuestListViewModel())
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
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @State var router = AppRouter()

    if let coordinator, let session = coordinator.gameSession {
        NavigationStack(path: $router.navigationPath) {
            QuestListScreen(session: session)
                .environment(router)
                .environment(coordinator)
        }
    } else {
        ProgressView()
            .task {
                await DependencyBootstrap.run()
                let c = AppCoordinator()
                c.initializePreviewSession(game: PreviewGame.createMockGame())
                coordinator = c
            }
    }
}
#endif
