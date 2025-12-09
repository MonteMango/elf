//
//  BattleFightScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleFightScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: BattleFightViewModel
    @State private var showWinnerAlert = false

    internal init(viewModel: BattleFightViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: Round number (center) and Close button (right)
                ZStack {
                    // Round number (centered)
                    Text("Round \(viewModel.currentRoundNumber)")
                        .font(BattleFightConstants.Fonts.roundNumber)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Close button (right)
                    HStack {
                        Spacer()
                        Button(action: {
                            router.pop()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(
                                    width: BattleFightConstants.Sizing.closeButtonSize,
                                    height: BattleFightConstants.Sizing.closeButtonSize
                                )
                                .background(BattleFightConstants.Colors.closeButton)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, BattleFightConstants.Sizing.horizontalPadding)
                .padding(.top, BattleFightConstants.Sizing.roundNumberTopPadding)

                Spacer()

                // Main horizontal layout
                HStack(spacing: 0) {
                    // LEFT SECTION: Player Hero (aligned to left safe area)
                    VStack(spacing: 10) {
                        Text("Player")
                            .font(BattleFightConstants.Fonts.sectionLabel)
                            .foregroundColor(.white)

                        HeroDisplayView(
                            snapshot: viewModel.playerSnapshot,
                            currentHP: viewModel.playerCurrentHP,
                            maxHP: viewModel.playerMaxHP,
                            roundResults: viewModel.playerLastRoundResults
                        )
                    }
                    .padding(.leading, BattleFightConstants.Sizing.horizontalPadding)

                    Spacer()
                        .frame(width: 20)

                    // Defense selector
                    BodyPointSelector(
                        mode: .defense,
                        selectedPoints: viewModel.playerDefensePoints,
                        maxPoints: viewModel.playerSnapshot.defensePoints,
                        onToggle: { bodyPart in
                            viewModel.togglePlayerDefensePoint(bodyPart)
                        }
                    )
                    .frame(
                        width: BattleFightConstants.Sizing.bodySelectorWidth,
                        height: BattleFightConstants.Sizing.bodySelectorHeight
                    )

                    Spacer()

                    // CENTER: Vertical Separator
                    Rectangle()
                        .fill(BattleFightConstants.Colors.separator)
                        .frame(width: BattleFightConstants.Sizing.separatorWidth)

                    Spacer()

                    // Attack selector
                    BodyPointSelector(
                        mode: .attack,
                        selectedPoints: viewModel.playerAttackPoints,
                        maxPoints: viewModel.playerSnapshot.attackPoints,
                        onToggle: { bodyPart in
                            viewModel.togglePlayerAttackPoint(bodyPart)
                        }
                    )
                    .frame(
                        width: BattleFightConstants.Sizing.bodySelectorWidth,
                        height: BattleFightConstants.Sizing.bodySelectorHeight
                    )

                    Spacer()
                        .frame(width: 20)

                    // RIGHT SECTION: Bot Hero (aligned to right safe area)
                    VStack(spacing: 10) {
                        Text("Bot")
                            .font(BattleFightConstants.Fonts.sectionLabel)
                            .foregroundColor(.white)

                        HeroDisplayView(
                            snapshot: viewModel.botSnapshot,
                            currentHP: viewModel.botCurrentHP,
                            maxHP: viewModel.botMaxHP,
                            roundResults: viewModel.botLastRoundResults
                        )
                    }
                    .padding(.trailing, BattleFightConstants.Sizing.horizontalPadding)
                }

                // Spacing before FIGHT button
                Spacer()
                    .frame(height: BattleFightConstants.Sizing.fightButtonHeight + 10)
            }

            // FIGHT button overlay (bottom center, aligned to safe area)
            VStack {
                Spacer()

                Button(action: {
                    let vm = viewModel
                    Task { @MainActor in
                        await vm.executeFightRound()
                    }
                }) {
                    Text("FIGHT")
                        .font(BattleFightConstants.Fonts.fightButton)
                        .foregroundColor(.white)
                        .frame(width: BattleFightConstants.Sizing.fightButtonWidth)
                        .frame(height: BattleFightConstants.Sizing.fightButtonHeight)
                        .background(BattleFightConstants.Colors.fightButton)
                        .cornerRadius(8)
                }
                .disabled(
                    viewModel.playerAttackPoints.count != viewModel.playerSnapshot.attackPoints ||
                    viewModel.playerDefensePoints.count != viewModel.playerSnapshot.defensePoints
                )
                .opacity(
                    (viewModel.playerAttackPoints.count == viewModel.playerSnapshot.attackPoints &&
                     viewModel.playerDefensePoints.count == viewModel.playerSnapshot.defensePoints) ? 1.0 : 0.5
                )
            }
            .safeAreaPadding(.bottom, 0)
        }
        .onChange(of: viewModel.battleEnded) { _, ended in
            if ended {
                showWinnerAlert = true
            }
        }
        .alert("Battle Ended", isPresented: $showWinnerAlert) {
            Button("OK") {
                router.pop()
            }
        } message: {
            if let winner = viewModel.getWinner() {
                Text("\(winner) wins!")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BattleFightScreenContent_Previews: PreviewProvider {
    static var previews: some View {
        let mockPlayerSnapshot = CombatantSnapshot(
            sourceId: UUID(),
            name: "Player Elf",
            imageName: "elf_player",
            combatantType: .elf,
            currentHP: 150,
            maxHP: 150,
            strength: 22,
            agility: 15,
            power: 18,
            intuition: 12,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 8,
            maximumAttack: 15,
            armorValues: [
                .head: 5,
                .body: 10,
                .leftHand: 3,
                .rightHand: 3,
                .legs: 7
            ]
        )

        let mockBotSnapshot = CombatantSnapshot(
            sourceId: UUID(),
            name: "Goblin",
            imageName: "monster_goblin",
            combatantType: .monster,
            currentHP: 120,
            maxHP: 120,
            strength: 15,
            agility: 18,
            power: 20,
            intuition: 15,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 5,
            maximumAttack: 12,
            armorValues: [:]
        )

        let mockBattle = Battle(
            leftTeam: [mockPlayerSnapshot],
            rightTeam: [mockBotSnapshot]
        )

        let container = ElfAppDependencyContainer()

        NavigationStack {
            BattleFightScreenContent(
                viewModel: container.makeBattleFightViewModel(battle: mockBattle)
            )
            .environment(AppRouter())
        }
        .previewDisplayName("Battle Fight Screen")
    }
}
#endif
