//
//  FarmActivityScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct FarmActivityScreenContent: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.farmZoomNamespace) private var zoomNamespace
    @State private var viewModel: FarmActivityViewModel
    @State private var showCalendar = false
    @State private var navigatedToBattle = false
    let dayStateViewModel: GameDayStateViewModel

    init(viewModel: FarmActivityViewModel, dayStateViewModel: GameDayStateViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self.dayStateViewModel = dayStateViewModel
    }

    // MARK: - Items Grid Data

    private var itemsGridData: [GridItemData] {
        viewModel.availableItems.map { item in
            GridItemData(id: item.id, imageName: item.imageName, tier: item.tier.rawValue)
        }
    }

    // MARK: - Activity State

    private var isPerformingActivity: Bool {
        viewModel.activityState == .performing
    }

    // MARK: - Background

    @ViewBuilder
    private var activityBackground: some View {
        if let uiImage = UIImage(named: viewModel.activity.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        } else {
            Color.white
                .ignoresSafeArea()
        }
    }

    // MARK: - Body

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 0) {
            GameDayHeader(
                viewModel: dayStateViewModel,
                onBack: { dismiss() },
                onCalendarTap: { showCalendar = true }
            )

            Spacer()

            SkillInfoSection(
                title: viewModel.skillTitle,
                progress: viewModel.skillProgress,
                currentExp: viewModel.skillExpInLevel,
                maxExp: viewModel.expPerLevel,
                level: viewModel.skillLevel
            )

            Spacer()

            ItemsGridView(items: itemsGridData)
                .padding(.horizontal, ElfSpacing.screen)

            Spacer()

            // Bottom: Action Button + Warning
            HStack(spacing: ElfSpacing.xxxl) {
                Color.clear
                    .frame(maxWidth: 300, maxHeight: 0)

                Button(viewModel.actionButtonTitle) {
                    Task {
                        await viewModel.performActivity()
                    }
                }
                .buttonStyle(.elfPrimary(isEnabled: viewModel.canPerformAction))
                .disabled(!viewModel.canPerformAction)
                .overlay(alignment: .bottomTrailing) {
                    Text("\(viewModel.actionCost) pt")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(4)
                }

                HStack {
                    ActivityWarningBadge(text: viewModel.warningText)
                    Spacer()
                }
                .frame(maxWidth: 300)
            }
            .padding(.horizontal, ElfSpacing.screen)
        }
        .background {
            activityBackground
        }
        .toolbar(.hidden, for: .navigationBar)
        .modifier(ZoomTransitionModifier(sourceID: viewModel.activity.id, namespace: zoomNamespace))
        .navigationDestination(isPresented: $showCalendar) {
            if let session = coordinator.sessionModel {
                CalendarScreenContent(
                    viewModel: session.makeCalendarViewModel(
                        calendar: dayStateViewModel.calendar,
                        currentDayNumber: dayStateViewModel.currentDay.dayNumber
                    )
                )
            }
        }
        .overlay {
            if isPerformingActivity {
                ActivityInProgressView(activity: viewModel.activity)
            }

            if viewModel.attackingMonster != nil {
                MonsterAttackAlertView(
                    activityName: viewModel.activity.rawValue,
                    onFight: {
                        if let battle = viewModel.startBattle() {
                            navigatedToBattle = true
                            router.navigationPath.append(AppRoute.battleFight(battle))
                        }
                    }
                )
            }
        }
        .onChange(of: viewModel.activityResult) { _, result in
            if let result = result {
                switch result {
                case .fishing(let fishingResult):
                    router.presentModal(.fishingResult(fishingResult))
                case .foraging(let foragingResult):
                    router.presentModal(.foragingResult(foragingResult))
                case .mining(let miningResult):
                    router.presentModal(.miningResult(miningResult))
                }
                viewModel.clearActivityResult()
            }
        }
        .onChange(of: router.navigationPath.count) { oldCount, newCount in
            if navigatedToBattle && newCount < oldCount {
                navigatedToBattle = false
                viewModel.onReturnFromBattle()
            }
        }
    }

}

// MARK: - Preview

#if DEBUG
#Preview {
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @Namespace var previewNamespace

    if let coordinator, let session = coordinator.sessionModel {
        NavigationStack {
            FarmActivityScreenContent(
                viewModel: session.makeFarmActivityViewModel(activity: .fishing),
                dayStateViewModel: session.dayState
            )
            .environment(\.farmZoomNamespace, previewNamespace)
            .environment(coordinator)
            .environment(AppRouter())
        }
    } else {
        ProgressView()
            .task {
                await DependencyBootstrap.run()
                let c = AppCoordinator()
                c.initializePreviewSession(game: PreviewMockData.createMockGame())
                coordinator = c
            }
    }
}
#endif
