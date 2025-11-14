//
//  BattleSetupScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleSetupScreen: View {
    @State private var viewModel: NewBattleSetupViewModel

    // Local state for items (not bound to ViewModel)
    @State private var playerSelectedItems: [HeroItemType: Item?] = [:]
    @State private var playerArmorValues: [BodyPart: Int16] = [:]
    @State private var botSelectedItems: [HeroItemType: Item?] = [:]
    @State private var botArmorValues: [BodyPart: Int16] = [:]

    internal init(viewModel: NewBattleSetupViewModel) {
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
                                    viewModel.backButtonAction()
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                        .frame(width: 44, height: 44)
                                }
                                Spacer()
                            }

                            // Battle button (centered)
                            Button(action: {
                                viewModel.fightButtonAction()
                            }) {
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
                // Items Grid (local state, not synced with ViewModel)
                HeroItemsGrid(
                    selectedItems: $playerSelectedItems,
                    armorValues: $playerArmorValues,
                    isSecondaryWeaponEnabled: true
                )
                .frame(width: 200)

                // Attributes Panel
                AttributesPanel(
                    alignment: .leading,
                    attributes: viewModel.playerTotalAttributes,
                    fightStyleAttrs: viewModel.playerFightStyleAttributes,
                    levelAttrs: viewModel.playerLevelRandomAttributes,
                    itemsAttrs: nil,  // TODO: implement items later
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
                    itemsAttrs: nil,  // TODO: implement items later
                    damageRange: nil   // TODO: implement damage calculation later
                )

                // Items Grid (local state, not synced with ViewModel)
                HeroItemsGrid(
                    selectedItems: $botSelectedItems,
                    armorValues: $botArmorValues,
                    isSecondaryWeaponEnabled: true
                )
                .frame(width: 200)
            }
        }
    }
}

#Preview {
    let itemsRepository = ElfItemsRepository(dataLoader: ElfDataLoader())

    // Load items asynchronously
    Task {
        try? await itemsRepository.loadHeroItems()
    }

    return BattleSetupScreen(
        viewModel: NewBattleSetupViewModel(
            navigationManager: AppNavigationManager(),
            itemsRepository: itemsRepository,
            attributeService: ElfAttributeService(itemsRepository: itemsRepository),
            armorService: ElfArmorService(itemsRepository: itemsRepository),
            damageService: ElfDamageService()
        )
    )
}
