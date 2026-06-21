//
//  QuestScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

// MARK: - QuestScreen

struct QuestScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.questZoomNamespace) private var zoomNamespace
    @State private var viewModel: QuestViewModel
    @Environment(GameDayStateViewModel.self) private var dayStateViewModel
    private let zoomSourceID: String

    init(questId: QuestID, ownerImageName: String, session: GameSession) {
        self._viewModel = State(initialValue: session.makeQuestViewModel(questId: questId))
        self.zoomSourceID = ownerImageName
    }

    // MARK: - Image Aspect Ratio

    /// Matches QuestOwnerCell aspect ratio (width / height)
    private let imageAspectRatio: CGFloat = 784 / 1176

    // MARK: - Body

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ownerImage(safeAreaInsets: geometry.safeAreaInsets)

                if let questData = viewModel.questData {
                    // Right panel: quest info + button
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()

                        Text(questData.questTitle)
                            .font(.system(size: ElfFonts.Size.title2, weight: .bold))
                            .foregroundStyle(ElfColors.Text.primary)
                            .padding(.bottom, ElfSpacing.large)

                        Text(questData.questDescription)
                            .font(.system(size: ElfFonts.Size.body, weight: .regular))
                            .foregroundStyle(ElfColors.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        // Bottom row: rewards left, requirements + button right
                        HStack(alignment: .bottom) {
                            rewardsSection(questData.rewards)

                            Spacer()

                            VStack(alignment: .trailing, spacing: ElfSpacing.small) {
                                requirementsSection(questData.conditions)

                                Button("Complete") {
                                    // Quest completion not yet implemented
                                }
                                .buttonStyle(.elfPrimary(isEnabled: questData.canComplete))
                                .disabled(!questData.canComplete)
                            }
                        }
                    }
                    .padding(ElfSpacing.screen)
                    .padding(.top, ElfSizing.standardPadding + ElfSizing.minTouchTarget)
                    .padding(.trailing, geometry.safeAreaInsets.trailing)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                } else {
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) {
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
        }
        .background(ElfColors.Background.primary)
        .toolbar(.hidden, for: .navigationBar)
        .modifier(ZoomTransitionModifier(
            sourceID: zoomSourceID,
            namespace: zoomNamespace
        ))
    }

    // MARK: - Owner Image

    @ViewBuilder
    private func ownerImage(safeAreaInsets: EdgeInsets) -> some View {
        if let imageName = viewModel.questData?.ownerImageName,
           let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(imageAspectRatio, contentMode: .fit)
                .overlay(alignment: .bottomLeading) {
                    ownerInfoOverlay
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.bottom, safeAreaInsets.bottom)
                }
        } else {
            Color.gray
                .aspectRatio(imageAspectRatio, contentMode: .fit)
        }
    }

    // MARK: - Owner Info Overlay

    @ViewBuilder
    private var ownerInfoOverlay: some View {
        if let questData = viewModel.questData {
            VStack(alignment: .leading, spacing: ElfSpacing.xxs) {
                Text(questData.ownerTitle)
                    .font(.system(size: ElfFonts.Size.title1, weight: .bold))
                    .foregroundStyle(ElfColors.Text.accent)

                Text(questData.ownerName)
                    .font(.system(size: ElfFonts.Size.title3, weight: .medium))
                    .foregroundStyle(ElfColors.Text.primaryLight)
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.8), radius: 4, x: 1, y: 1)
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
            .padding(ElfSpacing.xl)
        }
    }

    // MARK: - Requirements Section

    @ViewBuilder
    private func requirementsSection(_ conditions: [QuestConditionDisplay]) -> some View {
        if !conditions.isEmpty {
            VStack(alignment: .trailing, spacing: ElfSpacing.xxxs) {
                ForEach(conditions) { condition in
                    RequirementRow(
                        imageName: condition.imageName,
                        amount: condition.amount
                    )
                }
            }
        }
    }

    // MARK: - Rewards Section

    private func rewardsSection(_ rewards: [QuestRewardDisplay]) -> some View {
        RewardsSection(
            title: "Rewards:",
            items: rewards.map {
                RewardItemData(id: $0.id, imageName: $0.imageName, quantity: $0.quantity)
            }
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @State var router = AppRouter()
    @Previewable @Namespace var previewNamespace

    if let coordinator, let session = coordinator.gameSession {
        NavigationStack(path: router.navigationStackBinding) {
            QuestScreen(
                questId: QuestID(),
                ownerImageName: "quest_preview",
                session: session
            )
            .environment(\.questZoomNamespace, previewNamespace)
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
