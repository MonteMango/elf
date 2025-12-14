//
//  BattleResultScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct BattleResultScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: BattleResultViewModel

    // Animation states (kept in View)
    @State private var showBackground: Bool = false
    @State private var showCard: Bool = false
    @State private var showHeader: Bool = false
    @State private var showXP: Bool = false
    @State private var startXPProgress: Bool = false
    @State private var startDropReveal: Bool = false
    @State private var showContinueButton: Bool = false

    init(viewModel: BattleResultViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Dimmed background
            BattleResultConstants.Colors.overlayBackground
                .ignoresSafeArea()
                .opacity(showBackground ? 1.0 : 0.0)

            // Result card - VStack layout
            VStack(spacing: BattleResultConstants.Sizing.sectionSpacing) {
                // Header
                BattleResultHeader(
                    outcome: viewModel.result.outcome,
                    isVisible: showHeader
                )

                // Experience progress
                ExperienceProgressView(
                    result: viewModel.result,
                    isVisible: showXP,
                    showProgress: startXPProgress
                )

                // Drops (only for victory)
                if viewModel.result.outcome == .victory {
                    DropsRevealView(
                        drops: viewModel.result.drops,
                        startReveal: startDropReveal
                    )
                }

                Spacer()

                // Buttons row (Analyze left, Continue right)
                HStack {
                    Button("Analyze") {
                        // TODO: implement
                    }
                    .buttonStyle(.elfSecondary)
                    .opacity(showContinueButton ? 1.0 : 0.0)
                    .scaleEffect(showContinueButton ? 1.0 : 0.8)

                    Spacer()

                    Button("Continue") {
                        router.pop()
                        router.dismissModal()
                    }
                    .buttonStyle(.elfPrimary)
                    .opacity(showContinueButton ? 1.0 : 0.0)
                    .scaleEffect(showContinueButton ? 1.0 : 0.8)
                }
            }
            .padding(BattleResultConstants.Sizing.cardPadding)
            .frame(width: 600, height: 340)
            .background(
                RoundedRectangle(cornerRadius: BattleResultConstants.Sizing.cardCornerRadius)
                    .fill(BattleResultConstants.Colors.cardBackground)
            )
            .scaleEffect(showCard ? 1.0 : 0.8)
            .opacity(showCard ? 1.0 : 0.0)
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        // Background fade in
        withAnimation(.easeIn(duration: BattleResultConstants.Animation.backgroundFadeDuration)) {
            showBackground = true
        }

        // Card appear
        DispatchQueue.main.asyncAfter(
            deadline: .now() + BattleResultConstants.Animation.cardAppearDelay
        ) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showCard = true
            }
        }

        // Header appear
        DispatchQueue.main.asyncAfter(
            deadline: .now() + BattleResultConstants.Animation.headerAppearDelay
        ) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showHeader = true
            }
        }

        // XP section appear
        DispatchQueue.main.asyncAfter(
            deadline: .now() + BattleResultConstants.Animation.xpBarFillDelay - 0.2
        ) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showXP = true
            }
        }

        // XP bar fill animation
        DispatchQueue.main.asyncAfter(
            deadline: .now() + BattleResultConstants.Animation.xpBarFillDelay
        ) {
            startXPProgress = true
        }

        // Drops reveal
        DispatchQueue.main.asyncAfter(
            deadline: .now() + BattleResultConstants.Animation.dropItemDelay
        ) {
            startDropReveal = true
        }

        // Buttons appear
        let dropsDelay = viewModel.result.drops.isEmpty ? 0 : Double(viewModel.result.drops.count) * BattleResultConstants.Animation.dropItemStagger
        DispatchQueue.main.asyncAfter(
            deadline: .now() + BattleResultConstants.Animation.dropItemDelay + dropsDelay + BattleResultConstants.Animation.continueButtonDelay
        ) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showContinueButton = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Victory with drops") {
    BattleResultScreenContent(
        viewModel: BattleResultViewModel(
            result: ManualBattleResult(
                outcome: .victory,
                experienceGained: 15,
                drops: [
                    DropItem(
                        itemType: .material,
                        name: "Soul Gem",
                        icon: "material_monster_soul_gem",
                        rarity: .common,
                        quantity: 2
                    ),
                    DropItem(
                        itemType: .weapon,
                        name: "Steel Sword",
                        icon: "fa0b6893-6896-4689-a299-b8d271c76b68",
                        rarity: .rare,
                        quantity: 1
                    )
                ],
                previousLevel: 1,
                previousExp: 80,
                previousExpToNext: 100,
                newLevel: 2,
                newExp: 15,
                newExpToNext: 120
            )
        )
    )
    .environment(AppRouter())
}

#Preview("Defeat") {
    BattleResultScreenContent(
        viewModel: BattleResultViewModel(
            result: ManualBattleResult(
                outcome: .defeat,
                experienceGained: 0,
                drops: [],
                previousLevel: 1,
                previousExp: 50,
                previousExpToNext: 100,
                newLevel: 1,
                newExp: 50,
                newExpToNext: 100
            )
        )
    )
    .environment(AppRouter())
}

#Preview("Draw") {
    BattleResultScreenContent(
        viewModel: BattleResultViewModel(
            result: ManualBattleResult(
                outcome: .draw,
                experienceGained: 5,
                drops: [],
                previousLevel: 1,
                previousExp: 50,
                previousExpToNext: 100,
                newLevel: 1,
                newExp: 55,
                newExpToNext: 100
            )
        )
    )
    .environment(AppRouter())
}
