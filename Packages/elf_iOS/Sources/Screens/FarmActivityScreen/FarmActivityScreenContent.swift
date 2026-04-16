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
    @Environment(ElfGameContainer.self) private var gameContainer
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.farmZoomNamespace) private var zoomNamespace
    @State private var viewModel: FarmActivityViewModel
    @State private var showCalendar = false
    @State private var navigatedToBattle = false

    init(viewModel: FarmActivityViewModel) {
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

    private var canPerformAction: Bool {
        viewModel.actionPoints.current >= viewModel.actionCost && viewModel.activityState == .idle
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
        VStack(spacing: 0) {
            ScreenTopBar(
                currentActionPoints: viewModel.actionPoints.current,
                maxActionPoints: viewModel.actionPoints.maximum,
                isLastDay: viewModel.isLastDay,
                currentDay: currentDayData,
                upcomingDays: upcomingDaysData,
                onNextDay: { Task { await viewModel.advanceToNextDay() } },
                onBack: { dismiss() },
                onCalendarTap: {
                    showCalendar = true
                }
            )
            .padding(.top, ElfSizing.standardPadding)
            .padding(.horizontal, ElfSpacing.screen)

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
                .buttonStyle(.elfPrimary(isEnabled: canPerformAction))
                .disabled(!canPerformAction)
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
            CalendarScreenContent(
                viewModel: gameContainer.makeCalendarViewModel(
                    calendar: viewModel.calendar,
                    currentDayNumber: viewModel.currentDay.dayNumber
                )
            )
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
    @Previewable @State var gameContainer: ElfGameContainer?
    @Previewable @Namespace var previewNamespace

    if let gameContainer, gameContainer.activeGameService != nil {
        NavigationStack {
            FarmActivityScreenContent(
                viewModel: gameContainer.makeFarmActivityViewModel(activity: .fishing)
            )
            .environment(\.farmZoomNamespace, previewNamespace)
            .environment(gameContainer)
            .environment(AppRouter())
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
