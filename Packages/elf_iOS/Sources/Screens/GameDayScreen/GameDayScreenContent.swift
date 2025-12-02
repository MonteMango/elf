//
//  GameDayScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
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
            ActionPointsBar(
                current: viewModel.gameState.currentActionPoints,
                max: viewModel.gameState.maxActionPoints
            )

            // Action Buttons
            ActionButtonsList(onAction: viewModel.onActionTapped)

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
                    upcomingDays: viewModel.gameState.upcomingDays
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

    let mockCharacter = PlayerCharacter(
        name: "Asuna Yuuki",
        appearance: .appearance1,
        fightStyle: .dodge,
        fightStyleAttributes: HeroAttributes(
            hitPoints: 80,
            manaPoints: 20,
            agility: 5,
            strength: 2,
            power: 1,
            instinct: 2
        ),
        randomLevelAttributes: HeroAttributes(
            hitPoints: 3,
            manaPoints: 4,
            agility: 0,
            strength: 0,
            power: 0,
            instinct: 0
        )
    )

    let viewModel = GameDayViewModel(character: mockCharacter)

    GameDayScreenContent(viewModel: viewModel)
        .environment(router)
        .preferredColorScheme(.light)
}
