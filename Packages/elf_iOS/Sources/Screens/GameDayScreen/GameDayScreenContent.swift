//
//  GameDayScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

internal struct GameDayScreenContent: View {
    @Environment(AppRouter.self) private var router
    @Environment(ElfGameContainer.self) private var gameContainer
    @State private var viewModel: GameDayViewModel
    @State private var inventoryViewModel: InventoryViewModel
    let dayStateViewModel: GameDayStateViewModel

    internal init(
        viewModel: GameDayViewModel,
        inventoryViewModel: InventoryViewModel,
        dayStateViewModel: GameDayStateViewModel
    ) {
        self._viewModel = State(initialValue: viewModel)
        self._inventoryViewModel = State(initialValue: inventoryViewModel)
        self.dayStateViewModel = dayStateViewModel
    }

    var body: some View {
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
                        InventoryScreenContent(
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
                currentHP: Int(viewModel.player.currentHP),
                currentMP: Int(viewModel.player.currentMP),
                reputation: viewModel.player.reputation,
                onEquipmentSlotTapped: viewModel.onEquipmentSlotTapped,
                onPocketTapped: viewModel.onPocketTapped
            )

            elf_SwiftUI.AttributesCompactView(
                strength: viewModel.player.totalAttributes.strength.intValue,
                agility: viewModel.player.totalAttributes.agility.intValue,
                power: viewModel.player.totalAttributes.power.intValue,
                instinct: viewModel.player.totalAttributes.instinct.intValue
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
                onNextDay: { Task { await dayStateViewModel.advanceToNextDay() } }
            )

            ActionButtonsList(onAction: { action in
                switch action {
                case .hunt:
                    router.navigate(to: .hunt)
                case .farm:
                    router.navigate(to: .farm)
                case .craft:
                    router.navigate(to: .craft)
                case .quests:
                    router.navigate(to: .questList)
                }
            })

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
                        router.navigate(to: .calendar(
                            calendar: dayStateViewModel.calendar,
                            currentDayNumber: dayStateViewModel.currentDay.dayNumber
                        ))
                    }
                )

                Spacer()

                elf_SwiftUI.CloseButton {
                    Task {
                        await viewModel.exitGame()
                        router.popToRoot()
                        gameContainer.endGameSession()
                    }
                }
            }

            SideMenuButtons(onMenuTapped: viewModel.onSideMenuTapped)

            Spacer()
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var gameContainer: ElfGameContainer?
    @Previewable @State var router = AppRouter()

    if let gameContainer, gameContainer.activeGameService != nil {
        GameDayScreenContent(
            viewModel: gameContainer.makeGameDayViewModel(),
            inventoryViewModel: gameContainer.makeInventoryViewModel(),
            dayStateViewModel: gameContainer.requireGameDayStateViewModel()
        )
        .environment(router)
        .environment(gameContainer)
        .preferredColorScheme(.light)
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
