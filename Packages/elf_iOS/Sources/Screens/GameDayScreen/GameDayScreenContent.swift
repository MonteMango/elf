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

    internal init(viewModel: GameDayViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {

        HStack(spacing: 10) {
              leftNewSection
                  .frame(maxWidth: .infinity)
              centerSection
                  .frame(width: 250)
              rightSection
                  .frame(maxWidth: .infinity)
          }
        .padding(.top, 15)
        .background(Color.white)
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
                maxHP: viewModel.maxHP,
                currentMP: viewModel.currentMP,
                maxMP: viewModel.maxMP,
                reputation: viewModel.reputation,
                onEquipmentSlotTapped: viewModel.onEquipmentSlotTapped,
                onPocketTapped: viewModel.onPocketTapped
            )

            // Attributes
            AttributesCompactView(attributes: viewModel.totalAttributes)
        }
    }

    // MARK: - Center Section

    @ViewBuilder
    private var centerSection: some View {
        VStack(spacing: GameDayConstants.Spacing.sectionSpacing) {
            // Action Points Bar
            elf_SwiftUI.ActionPointsBar(
                current: viewModel.gameState.currentActionPoints,
                max: viewModel.gameState.maxActionPoints,
                label: "Action points",
                barHeight: GameDayConstants.Sizing.apBarHeight,
                labelFont: GameDayConstants.Fonts.apFont,
                barFont: GameDayConstants.Fonts.apFont,
                labelColor: GameDayConstants.Colors.secondaryText,
                fillColor: GameDayConstants.Colors.apBarFill,
                backgroundColor: GameDayConstants.Colors.xpBarBackground
            )

            // Action Buttons
            ActionButtonsList(onAction: { action in
                switch action {
                case .hunt:
                    router.navigate(to: .hunt)
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
            HStack(spacing: 0) {

                Spacer()

                CalendarSection(
                    currentDay: viewModel.gameState.currentDay,
                    upcomingDays: viewModel.gameState.upcomingDays,
                    onTap: {
                        router.navigate(to: .calendar(
                            calendar: viewModel.gameState.calendar,
                            currentDayNumber: viewModel.gameState.currentDay.dayNumber
                        ))
                    }
                )

                Spacer()

                CloseButton {
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

    GameDayScreenContent(viewModel: PreviewMockData.createMockGameDayViewModel())
        .environment(router)
        .preferredColorScheme(.light)
}
