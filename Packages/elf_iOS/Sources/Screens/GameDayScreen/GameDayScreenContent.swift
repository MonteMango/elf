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
    @State private var viewModel: GameDayViewModel
    @State private var inventoryViewModel: InventoryViewModel

    internal init(viewModel: GameDayViewModel, inventoryViewModel: InventoryViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._inventoryViewModel = State(initialValue: inventoryViewModel)
    }

    private var upcomingDaysData: [CalendarDayData] {
        viewModel.gameState.upcomingDays.map {
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
                    // Inventory: overlay inherits size from parent
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
                name: viewModel.characterName,
                currentExp: viewModel.currentExp,
                expToNextLevel: viewModel.expToNextLevel,
                xpProgress: viewModel.xpProgress
            )

            BuffsScrollView(buffs: viewModel.activeBuffs)

            HeroSection(
                imageName: viewModel.characterImageName,
                equippedItems: viewModel.equippedItems,
                currentHP: viewModel.currentHP,
                currentMP: viewModel.currentMP,
                reputation: viewModel.reputation,
                onEquipmentSlotTapped: viewModel.onEquipmentSlotTapped,
                onPocketTapped: viewModel.onPocketTapped
            )

            // Attributes
            elf_SwiftUI.AttributesCompactView(
                strength: viewModel.totalAttributes.strength.intValue,
                agility: viewModel.totalAttributes.agility.intValue,
                power: viewModel.totalAttributes.power.intValue,
                instinct: viewModel.totalAttributes.instinct.intValue
            )
        }
    }

    // MARK: - Center Section

    @ViewBuilder
    private var centerSection: some View {
        VStack(spacing: ElfSpacing.section) {
            elf_SwiftUI.ActionPointsBar(
                current: viewModel.gameState.currentActionPoints,
                max: viewModel.gameState.maxActionPoints,
                showNextDayButton: true,
                isLastDay: viewModel.gameState.isLastDay,
                onNextDay: { viewModel.onConfirmActionPoints() }
            )

            // Action Buttons
            ActionButtonsList(onAction: { action in
                switch action {
                case .hunt:
                    router.navigate(to: .hunt)
                case .farm:
                    router.navigate(to: .farm)
                default:
                    viewModel.onActionTapped(action)
                }
            })

            Spacer()
        }
    }

    // MARK: - Right Section

    @ViewBuilder
    private var rightSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top row: Calendar + Close button
            HStack(alignment: .top, spacing: 0) {

                Spacer()

                elf_SwiftUI.CalendarSection(
                    currentDay: CalendarDayData(
                        id: viewModel.gameState.currentDay.id,
                        dayNumber: viewModel.gameState.currentDay.dayNumber,
                        backgroundColor: ElfColors.Calendar.dayColor(for: viewModel.gameState.currentDay.dayType.rawValue)
                    ),
                    upcomingDays: upcomingDaysData,
                    onTap: {
                        router.navigate(to: .calendar(
                            calendar: viewModel.gameState.calendar,
                            currentDayNumber: viewModel.gameState.currentDay.dayNumber
                        ))
                    }
                )

                Spacer()

                elf_SwiftUI.CloseButton {
                    router.popToRoot()
                }
            }

            // Side Menu Buttons
            SideMenuButtons(onMenuTapped: viewModel.onSideMenuTapped)

            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var router = AppRouter()

    GameDayScreenContent(
        viewModel: PreviewMockData.createMockGameDayViewModel(),
        inventoryViewModel: PreviewMockData.createMockInventoryViewModel()
    )
    .environment(router)
    .preferredColorScheme(.light)
}
