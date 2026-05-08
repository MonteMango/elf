//
//  BattleSetupScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

internal struct BattleSetupScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var viewModel: BattleSetupViewModel

    internal init() {
        self._viewModel = State(initialValue: BattleSetupViewModel())
    }

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
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

                // Bottom row with close, battle, and autobattle buttons
                ZStack {
                    // Close button (bottom left)
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                    }

                    // Battle button (centered)
                    Button(action: {
                        Task {
                            if let battle = await viewModel.startBattle() {
                                router.navigationPath.append(AppRoute.battleFight(battle))
                            }
                        }
                    }) {
                        Text("BATTLE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 200)
                            .frame(height: 50)
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 8))
                    }

                    // Auto battle buttons (bottom right)
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            // Opponent picker
                            Picker("Opponent", selection: $viewModel.selectedOpponent) {
                                Text("Elf").tag(OpponentSelection.elf)
                                ForEach(viewModel.allMonsters, id: \.id) { monster in
                                    Text(monster.title).tag(OpponentSelection.monster(monster))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .frame(height: 44)
                            .padding(.horizontal, 8)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))

                            // 1000x Auto Battle button
                            Button(action: {
                                Task {
                                    guard let battle = await viewModel.startBattle() else {
                                        return
                                    }
                                    router.navigationPath.append(AppRoute.multiBattleResult(battle))
                                }
                            }) {
                                Text("1000x")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 50)
                                    .frame(height: 44)
                                    .background(Color.purple, in: RoundedRectangle(cornerRadius: 8))
                            }

                            // 1x AutoBattle button
                            Button(action: {
                                Task {
                                    guard let battle = await viewModel.startBattle() else {
                                        return
                                    }
                                    router.navigationPath.append(AppRoute.autoBattleResult(battle))
                                }
                            }) {
                                Text("1x")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 50)
                                    .frame(height: 44)
                                    .background(Color.green, in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, ElfSpacing.screenTop)
            .padding(.bottom)
        }
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
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
                        .foregroundStyle(.white)

                    FightStyleSelector(selectedFightStyle: $viewModel.playerState.fightStyle)
                        .onChange(of: viewModel.playerState.fightStyle) { _, newValue in
                            viewModel.updatePlayerFightStyle(newValue)
                        }
                }

                Spacer()

                // Level (Right)
                LevelSelector(level: $viewModel.playerState.level)
                    .onChange(of: viewModel.playerState.level) { _, newValue in
                        viewModel.updatePlayerLevel(newValue)
                    }
            }

            // Items and Attributes Section
            HStack(alignment: .bottom, spacing: 15) {
                // Items Grid (bound to ViewModel)
                HeroItemsGrid(
                    selectedItems: $viewModel.playerState.selectedItems,
                    armorValues: $viewModel.playerState.armorValues,
                    isSecondaryWeaponEnabled: true,
                    twoHandedWeaponId: viewModel.playerState.twoHandedWeaponId,
                    onItemTap: viewModel.handlePlayerItemSelection
                )
                .frame(width: 200)

                // Attributes Panel
                AttributesPanel(
                    alignment: .leading,
                    attributes: viewModel.playerState.totalAttributes,
                    fightStyleAttrs: viewModel.playerState.fightStyleAttributes,
                    levelAttrs: viewModel.playerState.levelRandomAttributes,
                    itemsAttrs: viewModel.playerState.itemsAttributes,
                    leftHandDamage: viewModel.playerState.leftHandDamage,
                    rightHandDamage: viewModel.playerState.rightHandDamage
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
                LevelSelector(level: $viewModel.botState.level)
                    .onChange(of: viewModel.botState.level) { _, newValue in
                        viewModel.updateBotLevel(newValue)
                    }

                Spacer()

                // Fight Style (Right)
                VStack(alignment: .trailing, spacing: BattleSetupConstants.Spacing.labelToControlSpacing) {
                    Text("Fight Style")
                        .font(BattleSetupConstants.Fonts.labelFont)
                        .foregroundStyle(.white)

                    FightStyleSelector(selectedFightStyle: $viewModel.botState.fightStyle)
                        .onChange(of: viewModel.botState.fightStyle) { _, newValue in
                            viewModel.updateBotFightStyle(newValue)
                        }
                }
            }

            // Items and Attributes Section
            HStack(alignment: .bottom, spacing: 15) {
                // Attributes Panel
                AttributesPanel(
                    alignment: .trailing,
                    attributes: viewModel.botState.totalAttributes,
                    fightStyleAttrs: viewModel.botState.fightStyleAttributes,
                    levelAttrs: viewModel.botState.levelRandomAttributes,
                    itemsAttrs: viewModel.botState.itemsAttributes,
                    leftHandDamage: viewModel.botState.leftHandDamage,
                    rightHandDamage: viewModel.botState.rightHandDamage
                )

                // Items Grid (bound to ViewModel)
                HeroItemsGrid(
                    selectedItems: $viewModel.botState.selectedItems,
                    armorValues: $viewModel.botState.armorValues,
                    isSecondaryWeaponEnabled: true,
                    twoHandedWeaponId: viewModel.botState.twoHandedWeaponId,
                    onItemTap: viewModel.handleBotItemSelection
                )
                .frame(width: 200)
            }
        }
    }
}

#Preview {
    @Previewable @State var isReady = false
    @Previewable @State var router = AppRouter()

    if isReady {
        NavigationStack(path: $router.navigationPath) {
            BattleSetupScreen()
                .environment(router)
        }
    } else {
        ProgressView()
            .task {
                await DependencyBootstrap.run()
                isReady = true
            }
    }
}
