//
//  BattleFightScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

internal struct BattleFightScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: BattleFightViewModel
    @State private var showLeaveConfirmation = false

    internal init(viewModel: BattleFightViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Button State

    private var hasNoSelection: Bool {
        viewModel.playerAttackPoints.isEmpty && viewModel.playerDefensePoints.isEmpty
    }

    private var hasFullSelection: Bool {
        viewModel.playerAttackPoints.count == viewModel.playerSnapshot.attackPoints &&
        viewModel.playerDefensePoints.count == viewModel.playerSnapshot.defensePoints
    }

    // MARK: - Body

    internal var body: some View {
        ZStack {
            // Background
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: Player title, Round number with Close button, Bot title
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("[\(viewModel.playerSnapshot.level)] \(viewModel.playerSnapshot.name)")
                        .font(ElfFonts.Component.statLabel)
                        .foregroundStyle(.black)
                    Spacer()
                    Text("Round \(viewModel.currentRoundNumber)")
                        .font(ElfFonts.Component.roundNumber)
                        .foregroundStyle(.black)
                        .overlay(alignment: .trailing) {
                            elf_SwiftUI.CloseButton {
                                showLeaveConfirmation = true
                            }
                            .alignmentGuide(.trailing) { d in d[.leading] - 12 }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                    Spacer()
                    Text("[\(viewModel.botSnapshot.level)] \(viewModel.botSnapshot.name)")
                        .font(ElfFonts.Component.statLabel)
                        .foregroundStyle(.black)
                }

                Spacer()

                // Main horizontal layout
                HStack(alignment: .top, spacing: 0) {
                    // Player Hero
                    VStack {
                        HeroDisplayView(
                            snapshot: viewModel.playerSnapshot,
                            currentHP: viewModel.playerCurrentHP,
                            maxHP: viewModel.playerMaxHP,
                            roundResults: viewModel.playerLastRoundResults
                        )
                        Spacer()
                    }

                    Spacer()
                        .frame(width: 15)

                    VStack {
                        Spacer()

                        // Defense selector
                        BodyPointSelector(
                            mode: .defense,
                            selectedPoints: viewModel.playerDefensePoints,
                            maxPoints: viewModel.playerSnapshot.defensePoints,
                            onToggle: { bodyPart in
                                viewModel.togglePlayerDefensePoint(bodyPart)
                            }
                        )
                    }

                    Spacer()
                        .frame(width: 5)

                    // Duel Pairs with Separator
                    if let battleRound = viewModel.currentBattleRound {
                        DuelPairsColumnView(
                            battleRound: battleRound,
                            leftTeam: viewModel.leftTeam,
                            rightTeam: viewModel.rightTeam
                        )
                    } else {
                        // Fallback: just separator if no round data
                        Rectangle()
                            .fill(ElfColors.Background.overlayLight)
                            .frame(width: 2)
                    }

                    Spacer()
                        .frame(width: 5)

                    VStack {
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
                    }

                    Spacer()
                        .frame(width: 15)

                    VStack {
                        // Bot Hero
                        HeroDisplayView(
                            snapshot: viewModel.botSnapshot,
                            currentHP: viewModel.botCurrentHP,
                            maxHP: viewModel.botMaxHP,
                            roundResults: viewModel.botLastRoundResults
                        )
                        Spacer()
                    }
                }

                Spacer()

                // Auto/Fight button
                if hasNoSelection {
                    // AUTO button - when nothing is selected
                    Button(action: {
                        Task { await viewModel.autoFillPoints() }
                    }) {
                        Text("AUTO")
                            .font(ElfFonts.Component.actionButton)
                            .foregroundStyle(ElfColors.Button.primary)
                            .frame(width: 120)
                            .frame(height: 54)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 27))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                } else {
                    // FIGHT button - when any selection made
                    Button(action: {
                        Task { @MainActor in
                            await viewModel.executeFightRound()
                        }
                    }) {
                        Text("FIGHT")
                            .font(ElfFonts.Component.actionButton)
                            .foregroundStyle(.white)
                            .frame(width: 120)
                            .frame(height: 54)
                            .background(ElfColors.Button.primary, in: RoundedRectangle(cornerRadius: 27))
                    }
                    .disabled(!hasFullSelection)
                    .opacity(hasFullSelection ? 1.0 : 0.5)
                }
            }
        }
        .task { await viewModel.loadInitialData() }
        .onChange(of: viewModel.battleResult) { _, result in
            // When battle result is ready, present modal
            if let result = result {
                router.presentModal(.battleResult(result))
            }
        }
        .onChange(of: viewModel.battleEnded) { _, ended in
            if ended {
                Task { await viewModel.finishBattle() }
            }
        }
        .alert("Leave battle?", isPresented: $showLeaveConfirmation) {
            Button("Stay", role: .cancel) { }
            Button("Leave", role: .destructive) {
                router.pop()
            }
        } message: {
            Text("If you leave, you will automatically lose this battle.")
        }
    }
}

// MARK: - Preview

#Preview("Battle Fight Screen (3v2)") {
    @Previewable @State var gameContainer: ElfGameContainer?

    let elfA = CombatantSnapshot(
        sourceId: UUID(),
        name: "Player Elf",
        imageName: "elf_player",
        combatantType: .elf,
        level: 5,
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

    let elfB = CombatantSnapshot(
        sourceId: UUID(),
        name: "Elf B",
        imageName: "elf_player",
        combatantType: .elf,
        level: 4,
        currentHP: 130,
        maxHP: 130,
        strength: 18,
        agility: 16,
        power: 14,
        intuition: 14,
        attackPoints: 1,
        defensePoints: 2,
        minimumAttack: 6,
        maximumAttack: 12,
        armorValues: [:]
    )

    let elfC = CombatantSnapshot(
        sourceId: UUID(),
        name: "Elf C",
        imageName: "elf_player",
        combatantType: .elf,
        level: 3,
        currentHP: 110,
        maxHP: 110,
        strength: 15,
        agility: 20,
        power: 12,
        intuition: 16,
        attackPoints: 1,
        defensePoints: 2,
        minimumAttack: 5,
        maximumAttack: 10,
        armorValues: [:]
    )

    let goblinD = CombatantSnapshot(
        sourceId: UUID(),
        name: "Goblin D",
        imageName: "monster_goblin",
        combatantType: .monster,
        level: 3,
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

    let goblinE = CombatantSnapshot(
        sourceId: UUID(),
        name: "Goblin E",
        imageName: "monster_goblin",
        combatantType: .monster,
        level: 2,
        currentHP: 100,
        maxHP: 100,
        strength: 12,
        agility: 15,
        power: 18,
        intuition: 12,
        attackPoints: 1,
        defensePoints: 2,
        minimumAttack: 4,
        maximumAttack: 10,
        armorValues: [:]
    )

    let mockBattle = Battle(
        leftTeam: [elfA, elfB, elfC],
        rightTeam: [goblinD, goblinE]
    )

    if let gameContainer {
        NavigationStack {
            BattleFightScreenContent(
                viewModel: gameContainer.makeBattleFightViewModel(battle: mockBattle)
            )
            .environment(AppRouter())
        }
    } else {
        ProgressView()
            .task { gameContainer = await ElfGameContainer() }
    }
}
