//
//  BattleSetupScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleSetupScreenContent: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(ElfAppDependencyContainer.self) private var container
    @State private var viewModel: BattleSetupViewModel

    internal init(viewModel: BattleSetupViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                // Player and Bot panels
                HStack(alignment: .top, spacing: 0) {
                    // Player panel (left)
                    playerPanel
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 10)

                    // Separator
                    Rectangle()
                        .fill(BattleSetupConstants.Colors.separatorLine)
                        .frame(width: BattleSetupConstants.Sizing.separatorWidth)

                    // Bot panel (right)
                    botPanel
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 10)
                }
                .padding(.horizontal)

                // Bottom row with close and battle buttons
                ZStack {
                    // Close button (bottom left)
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                    }

                    // Battle button (centered) - TODO: add validation
                    NavigationLink(value: AppRoute.battleFight(user: HeroConfiguration(), enemy: HeroConfiguration())) {
                        Text("BATTLE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 200)
                            .frame(height: 50)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.top, 60)
        }
        .sheet(item: $viewModel.presentedItemSelector) { state in
            SelectHeroItemScreen(
                heroType: state.heroType,
                heroItemType: state.itemType,
                currentItemId: state.currentItemId,
                onEquip: { selectedItemId in
                    viewModel.equipItem(
                        for: state.heroType,
                        itemType: state.itemType,
                        selectedItemId: selectedItemId
                    )
                }
            )
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Player Panel
    private var playerPanel: some View {
        VStack(alignment: .leading, spacing: BattleSetupConstants.Spacing.sectionVerticalSpacing) {
            // Fight Style and Level Section (Horizontal)
            HStack(alignment: .top, spacing: 20) {
                // Fight Style (Left)
                VStack(alignment: .leading, spacing: BattleSetupConstants.Spacing.labelToControlSpacing) {
                    Text("Fight Style")
                        .font(BattleSetupConstants.Fonts.labelFont)
                        .foregroundColor(.white)

                    FightStyleSelector(selectedFightStyle: $viewModel.playerFightStyle)
                }

                Spacer()

                // Level (Right)
                LevelSelector(level: $viewModel.playerLevel)
            }

            // Items and Attributes Section
            HStack(alignment: .bottom, spacing: 15) {
                // Items Grid (bound to ViewModel)
                HeroItemsGrid(
                    selectedItems: $viewModel.playerSelectedItems,
                    armorValues: $viewModel.playerArmorValues,
                    isSecondaryWeaponEnabled: true,
                    twoHandedWeaponId: viewModel.playerTwoHandedWeaponId,
                    onItemTap: viewModel.handlePlayerItemSelection
                )
                .frame(width: 200)

                // Attributes Panel
                AttributesPanel(
                    alignment: .leading,
                    attributes: viewModel.playerTotalAttributes,
                    fightStyleAttrs: viewModel.playerFightStyleAttributes,
                    levelAttrs: viewModel.playerLevelRandomAttributes,
                    itemsAttrs: viewModel.playerItemsAttributes,
                    damageRange: nil   // TODO: implement damage calculation later
                )
            }
        }
    }

    // MARK: - Bot Panel
    private var botPanel: some View {
        VStack(alignment: .trailing, spacing: BattleSetupConstants.Spacing.sectionVerticalSpacing) {
            // Level and Fight Style Section (Horizontal, reversed order)
            HStack(alignment: .top, spacing: 20) {
                // Level (Left)
                LevelSelector(level: $viewModel.botLevel)

                Spacer()

                // Fight Style (Right)
                VStack(alignment: .trailing, spacing: BattleSetupConstants.Spacing.labelToControlSpacing) {
                    Text("Fight Style")
                        .font(BattleSetupConstants.Fonts.labelFont)
                        .foregroundColor(.white)

                    FightStyleSelector(selectedFightStyle: $viewModel.botFightStyle)
                }
            }

            // Items and Attributes Section
            HStack(alignment: .bottom, spacing: 15) {
                // Attributes Panel
                AttributesPanel(
                    alignment: .trailing,
                    attributes: viewModel.botTotalAttributes,
                    fightStyleAttrs: viewModel.botFightStyleAttributes,
                    levelAttrs: viewModel.botLevelRandomAttributes,
                    itemsAttrs: viewModel.botItemsAttributes,
                    damageRange: nil   // TODO: implement damage calculation later
                )

                // Items Grid (bound to ViewModel)
                HeroItemsGrid(
                    selectedItems: $viewModel.botSelectedItems,
                    armorValues: $viewModel.botArmorValues,
                    isSecondaryWeaponEnabled: true,
                    twoHandedWeaponId: viewModel.botTwoHandedWeaponId,
                    onItemTap: viewModel.handleBotItemSelection
                )
                .frame(width: 200)
            }
        }
    }
}

#Preview {
    let container = ElfAppDependencyContainer()

    NavigationStack {
        BattleSetupScreenContent(
            viewModel: container.makeBattleSetupViewModel()
        )
        .environment(AppRouter())
        .environment(container)
    }
}
