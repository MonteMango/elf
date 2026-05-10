//
//  HuntScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct HuntScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HuntViewModel
    @Environment(GameDayStateViewModel.self) private var dayStateViewModel

    init(session: GameSession) {
        self._viewModel = State(initialValue: session.makeHuntViewModel())
    }

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

#if DEBUG
#Preview {
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @State var router = AppRouter()

    if let coordinator, let session = coordinator.gameSession {
        NavigationStack(path: $router.navigationPath) {
            HuntScreen(session: session)
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
