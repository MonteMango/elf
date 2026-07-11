//
//  GameDayScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

internal struct GameDayScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel: GameDayViewModel
    @State private var inventoryViewModel: InventoryViewModel
    @Environment(GameDayStateViewModel.self) private var dayStateViewModel
    private let session: GameSession

    internal init(session: GameSession) {
        self.session = session
        self._viewModel = State(initialValue: session.makeGameDayViewModel())
        self._inventoryViewModel = State(initialValue: session.makeInventoryViewModel())
    }

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        GeometryReader { geometry in
            let spacing: CGFloat = 10
            let centerWidth: CGFloat = 250
            let topPadding = ElfSizing.standardPadding
            let sideWidth = max(0, (geometry.size.width - centerWidth - 2 * spacing) / 2)
            let contentHeight = max(0, geometry.size.height - topPadding)

            HStack(alignment: .top, spacing: spacing) {
                leftNewSection
                    .frame(width: sideWidth)

                // Center + Right sections
                HStack(spacing: spacing) {
                    centerSection
                        .frame(width: centerWidth)
                    rightSection
                        .frame(width: sideWidth)
                }
                .opacity(viewModel.isInventoryVisible ? 0 : 1)
                .frame(width: centerWidth + spacing + sideWidth, height: contentHeight)
                .overlay {
                    if viewModel.isInventoryVisible {
                        InventoryView(
                            viewModel: inventoryViewModel,
                            selectedItemId: viewModel.pendingInventoryItemId
                        )
                        .transition(.opacity)
                    }
                }
            }
            .padding(.top, topPadding)
        }
        .background(ElfColors.Background.primary)
        .task {
            inventoryViewModel.onClose = viewModel.closeInventory
        }
    }

    // MARK: - Left Section

    @ViewBuilder
    private var leftNewSection: some View {
        VStack(spacing: 5) {
            PlayerInfoSection(
                level: viewModel.characterLevel,
                name: viewModel.player.name,
                currentExp: viewModel.player.currentExp,
                expToNextLevel: viewModel.expToNextLevel,
                xpProgress: viewModel.xpProgress
            )

            BuffsScrollView(buffs: viewModel.activeBuffs)

            HeroSection(
                imageName: viewModel.player.imageName,
                equippedItems: viewModel.equippedItems,
                currentHP: Int(viewModel.player.maxHP),
                currentMP: Int(viewModel.player.maxMP),
                reputation: viewModel.player.reputation,
                onEquipmentSlotTapped: viewModel.onEquipmentSlotTapped,
                onPocketTapped: viewModel.onPocketTapped
            )

            elf_SwiftUI.AttributesCompactView(
                strength: viewModel.player.totalAttributes.strength.intValue,
                agility: viewModel.player.totalAttributes.agility.intValue,
                power: viewModel.player.totalAttributes.power.intValue,
                instinct: viewModel.player.totalAttributes.instinct.intValue,
                endurance: viewModel.player.totalAttributes.endurance.intValue
            )
        }
    }

    // MARK: - Center Section

    @ViewBuilder
    private var centerSection: some View {
        VStack(spacing: ElfSpacing.section) {
            elf_SwiftUI.ActionPointsBar(
                current: dayStateViewModel.actionPoints.current,
                max: dayStateViewModel.actionPoints.maximum,
                showNextDayButton: true,
                isLastDay: dayStateViewModel.isLastDay,
                isNextDayDisabled: dayStateViewModel.isAdvancingDay,
                onNextDay: { Task { await dayStateViewModel.advanceToNextDay() } }
            )

            ActionButtonsList(
                actions: dayStateViewModel.currentDay.dayType.availableActions,
                onAction: { action in
                    switch action {
                    case .hunt:
                        router.navigate(to: .hunt)
                    case .farm:
                        router.navigate(to: .farm)
                    case .craft:
                        router.navigate(to: .craft)
                    case .quests:
                        router.navigate(to: .questList)
                    case .dungeon:
                        if let run = viewModel.prepareDungeonRun() {
                            session.startDungeonSession(
                                dungeonId: run.dungeonId,
                                allyIds: run.allyIds
                            )
                            router.navigate(to: .dungeon(
                                dungeonId: run.dungeonId,
                                allyIds: run.allyIds
                            ))
                        }
                    }
                }
            )

            Spacer()
        }
    }

    // MARK: - Right Section

    @ViewBuilder
    private var rightSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 0) {

                Spacer()

                elf_SwiftUI.CalendarSection(
                    currentDay: dayStateViewModel.currentDay.calendarDayData,
                    upcomingDays: dayStateViewModel.upcomingDays.map(\.calendarDayData),
                    onTap: {
                        router.navigate(to: .calendar)
                    }
                )

                Spacer()

                elf_SwiftUI.CloseButton {
                    Task {
                        await viewModel.exitGame()
                        router.popToRoot()
                        coordinator.endGame()
                    }
                }
            }

            SideMenuButtons(onMenuTapped: viewModel.onSideMenuTapped)

            #if DEBUG
            Button("Spend AP") {
                dayStateViewModel.spendActionPoints(20)
            }
            .buttonStyle(.elfPrimary)
            #endif

            Spacer()
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @State var router = AppRouter()

    if let coordinator, let session = coordinator.gameSession {
        GameDayScreen(session: session)
            .environment(router)
            .environment(coordinator)
            .preferredColorScheme(.light)
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
