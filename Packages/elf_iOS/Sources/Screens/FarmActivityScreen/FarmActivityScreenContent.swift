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
    @Environment(ElfAppDependencyContainer.self) private var container
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

    // MARK: - Fish Data

    private var fishGridData: [GridItemData] {
        viewModel.availableFish.map { fish in
            GridItemData(id: fish.id, imageName: fish.imageName, tier: fish.tier)
        }
    }

    // MARK: - Fishing State

    private var isFishing: Bool {
        viewModel.fishingState == .fishing
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
            // Top bar
            ScreenTopBar(
                currentActionPoints: viewModel.currentActionPoints,
                maxActionPoints: viewModel.maxActionPoints,
                isLastDay: viewModel.isLastDay,
                currentDay: currentDayData,
                upcomingDays: upcomingDaysData,
                onNextDay: { viewModel.advanceToNextDay() },
                onBack: { dismiss() },
                onCalendarTap: {
                    showCalendar = true
                }
            )
            .padding(.top, ElfSizing.standardPadding)
            .padding(.horizontal, ElfSpacing.screen)

            Spacer()

            // Skill Info Section
            SkillInfoSection(
                title: viewModel.skillTitle,
                progress: viewModel.skillProgress,
                currentExp: viewModel.skillExpInLevel,
                maxExp: viewModel.expPerLevel,
                level: viewModel.skillLevel
            )

            Spacer()

            // Items Grid (fishing only)
            if viewModel.activity == .fishing {
                ItemsGridView(items: fishGridData)
                    .padding(.horizontal, ElfSpacing.screen)
            }

            Spacer()

            // Bottom: Action Button + Warning
            HStack(spacing: ElfSpacing.xxxl) {
                // Left balancing block (same width as right section)
                Color.clear
                    .frame(maxWidth: 300, maxHeight: 0)

                Button(viewModel.actionButtonTitle) {
                    if viewModel.activity == .fishing {
                        Task {
                            await viewModel.startFishing()
                        }
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

                // Right section with warning
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
        .modifier(FarmZoomTransitionModifier(sourceID: viewModel.activity.id, namespace: zoomNamespace))
        .navigationDestination(isPresented: $showCalendar) {
            CalendarScreenContent(
                viewModel: container.makeCalendarViewModel(
                    calendar: viewModel.calendar,
                    currentDayNumber: viewModel.currentDay.dayNumber
                )
            )
        }
        .overlay {
            // Local overlay for fishing progress
            if isFishing {
                FishingInProgressView()
            }

            // Monster attack alert overlay
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
        .onChange(of: viewModel.fishingResult) { _, result in
            if let result = result {
                router.presentModal(.fishingResult(result))
                viewModel.clearFishingResult()
            }
        }
        .onChange(of: router.navigationPath.count) { oldCount, newCount in
            // Handle return from battle (navigation stack decreased)
            if navigatedToBattle && newCount < oldCount {
                navigatedToBattle = false
                viewModel.onReturnFromBattle()
            }
        }
    }

}

// MARK: - Preview

#Preview {
    @Previewable @Namespace var previewNamespace
    let container = ElfAppDependencyContainer()
    container.initializePreviewSession(game: PreviewMockData.createMockGame())

    return NavigationStack {
        FarmActivityScreenContent(
            viewModel: container.makeFarmActivityViewModel(activity: .fishing)
        )
        .environment(\.farmZoomNamespace, previewNamespace)
        .environment(container)
        .environment(AppRouter())
    }
}
