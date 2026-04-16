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
    @Environment(DefaultGameService.self) private var gameService
    @Environment(ElfGameContainer.self) private var gameContainer
    @State private var viewModel: GameDayViewModel
    @State private var inventoryViewModel: InventoryViewModel

    internal init(viewModel: GameDayViewModel, inventoryViewModel: InventoryViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._inventoryViewModel = State(initialValue: inventoryViewModel)
    }

    private var upcomingDaysData: [CalendarDayData] {
        gameService.upcomingDays.map {
            CalendarDayData(
                id: $0.id,
                dayNumber: $0.dayNumber,
                backgroundColor: ElfColors.Calendar.dayColor(for: $0.dayType.rawValue)
            )
        }
    }

    var body: some View {
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
                name: gameService.player.name,
                currentExp: gameService.player.currentExp,
                expToNextLevel: viewModel.expToNextLevel,
                xpProgress: viewModel.xpProgress
            )

            BuffsScrollView(buffs: viewModel.activeBuffs)

            HeroSection(
                imageName: gameService.player.imageName,
                equippedItems: viewModel.equippedItems,
                currentHP: Int(gameService.player.currentHP),
                currentMP: Int(gameService.player.currentMP),
                reputation: gameService.player.reputation,
                onEquipmentSlotTapped: viewModel.onEquipmentSlotTapped,
                onPocketTapped: viewModel.onPocketTapped
            )

            elf_SwiftUI.AttributesCompactView(
                strength: gameService.player.totalAttributes.strength.intValue,
                agility: gameService.player.totalAttributes.agility.intValue,
                power: gameService.player.totalAttributes.power.intValue,
                instinct: gameService.player.totalAttributes.instinct.intValue
            )
        }
    }

    // MARK: - Center Section

    @ViewBuilder
    private var centerSection: some View {
        VStack(spacing: ElfSpacing.section) {
            elf_SwiftUI.ActionPointsBar(
                current: gameService.actionPoints.current,
                max: gameService.actionPoints.maximum,
                showNextDayButton: true,
                isLastDay: gameService.isLastDay,
                onNextDay: { Task { await viewModel.onConfirmActionPoints() } }
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
                    currentDay: CalendarDayData(
                        id: gameService.currentDay.id,
                        dayNumber: gameService.currentDay.dayNumber,
                        backgroundColor: ElfColors.Calendar.dayColor(for: gameService.currentDay.dayType.rawValue)
                    ),
                    upcomingDays: upcomingDaysData,
                    onTap: {
                        router.navigate(to: .calendar(
                            calendar: gameService.calendar,
                            currentDayNumber: gameService.currentDay.dayNumber
                        ))
                    }
                )

                Spacer()

                elf_SwiftUI.CloseButton {
                    Task {
                        await viewModel.exitGame()
                        router.popToRoot()
                        // Defer one tick so SwiftUI unmounts the game-session views
                        // before the DefaultGameService environment disappears.
                        await Task.yield()
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
    @Previewable @State var router = AppRouter()

    GameDayScreenContent(
        viewModel: PreviewMockData.createMockGameDayViewModel(),
        inventoryViewModel: PreviewMockData.createMockInventoryViewModel()
    )
    .environment(router)
    .preferredColorScheme(.light)
}
#endif
