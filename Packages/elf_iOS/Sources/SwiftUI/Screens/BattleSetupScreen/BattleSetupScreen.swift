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
    @ObservedObject private var playerConfig: HeroConfiguration
    @ObservedObject private var botConfig: HeroConfiguration

    internal init(viewModel: NewBattleSetupViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._playerConfig = ObservedObject(wrappedValue: viewModel.playerHeroConfiguration)
        self._botConfig = ObservedObject(wrappedValue: viewModel.botHeroConfiguration)
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
                                .padding(.vertical, 20)

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

                    FightStyleSelector(selectedFightStyle: $playerConfig.fightStyle)
                }

                Spacer()

                // Level (Right)
                LevelSelector(level: $playerConfig.level)
            }

            // Items and Attributes Section
            HStack(alignment: .top, spacing: 15) {
                // Items Grid
                HeroItemsGrid(
                    selectedItems: playerItemsBinding,
                    armorValues: $playerConfig.itemsArmor,
                    isSecondaryWeaponEnabled: playerSecondaryWeaponEnabled
                )
                .frame(width: 200)

                // Attributes Panel
                AttributesPanel(
                    alignment: .leading,
                    attributes: playerTotalAttributes,
                    fightStyleAttrs: playerConfig.fightStyleAttributes,
                    levelAttrs: playerConfig.levelRandomAttributes,
                    itemsAttrs: playerConfig.itemsAttributes,
                    damageRange: playerConfig.minMaxStrengthDamage
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
                LevelSelector(level: $botConfig.level)

                Spacer()

                // Fight Style (Right)
                VStack(alignment: .trailing, spacing: BattleSetupConstants.Spacing.labelToControlSpacing) {
                    Text("Fight Style")
                        .font(BattleSetupConstants.Fonts.labelFont)
                        .foregroundColor(.white)

                    FightStyleSelector(selectedFightStyle: $botConfig.fightStyle)
                }
            }

            // Items and Attributes Section
            HStack(alignment: .top, spacing: 15) {
                // Attributes Panel
                AttributesPanel(
                    alignment: .trailing,
                    attributes: botTotalAttributes,
                    fightStyleAttrs: botConfig.fightStyleAttributes,
                    levelAttrs: botConfig.levelRandomAttributes,
                    itemsAttrs: botConfig.itemsAttributes,
                    damageRange: botConfig.minMaxStrengthDamage
                )

                // Items Grid
                HeroItemsGrid(
                    selectedItems: botItemsBinding,
                    armorValues: $botConfig.itemsArmor,
                    isSecondaryWeaponEnabled: botSecondaryWeaponEnabled
                )
                .frame(width: 200)
            }
        }
    }

    // MARK: - Computed Properties

    // Player
    private var playerTotalAttributes: HeroAttributes? {
        calculateTotalAttributes(
            fightStyle: playerConfig.fightStyleAttributes,
            level: playerConfig.levelRandomAttributes,
            items: playerConfig.itemsAttributes
        )
    }

    private var playerItemsBinding: Binding<[HeroItemType: Item?]> {
        Binding(
            get: { self.convertToItemsDict(self.playerConfig.items) },
            set: { _ in }
        )
    }

    private var playerSecondaryWeaponEnabled: Bool {
        if case .twoHandsWeapon = playerConfig.items.handsUse {
            return false
        }
        return true
    }

    // Bot
    private var botTotalAttributes: HeroAttributes? {
        calculateTotalAttributes(
            fightStyle: botConfig.fightStyleAttributes,
            level: botConfig.levelRandomAttributes,
            items: botConfig.itemsAttributes
        )
    }

    private var botItemsBinding: Binding<[HeroItemType: Item?]> {
        Binding(
            get: { self.convertToItemsDict(self.botConfig.items) },
            set: { _ in }
        )
    }

    private var botSecondaryWeaponEnabled: Bool {
        if case .twoHandsWeapon = botConfig.items.handsUse {
            return false
        }
        return true
    }

    // MARK: - Helper Methods

    private func calculateTotalAttributes(
        fightStyle: HeroAttributes?,
        level: HeroAttributes?,
        items: HeroAttributes?
    ) -> HeroAttributes? {
        guard let fightStyle = fightStyle,
              let level = level,
              let items = items else {
            return nil
        }

        return HeroAttributes(
            hitPoints: fightStyle.hitPoints + level.hitPoints + items.hitPoints,
            manaPoints: fightStyle.manaPoints + level.manaPoints + items.manaPoints,
            agility: fightStyle.agility + level.agility + items.agility,
            strength: fightStyle.strength + level.strength + items.strength,
            power: fightStyle.power + level.power + items.power,
            instinct: fightStyle.instinct + level.instinct + items.instinct
        )
    }

    private func convertToItemsDict(_ configItems: HeroConfigurationItems) -> [HeroItemType: Item?] {
        var dict: [HeroItemType: Item?] = [:]

        dict[.helmet] = configItems.helmet?.item
        dict[.gloves] = configItems.gloves?.item
        dict[.shoes] = configItems.shoes?.item
        dict[.upperBody] = configItems.upperBody?.item
        dict[.bottomBody] = configItems.bottomBody?.item
        dict[.shirt] = configItems.shirt?.item
        dict[.ring] = configItems.ring?.item
        dict[.necklace] = configItems.necklace?.item
        dict[.earrings] = configItems.earrings?.item

        return dict
    }
}
