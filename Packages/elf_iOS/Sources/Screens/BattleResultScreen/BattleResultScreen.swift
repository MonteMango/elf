//
//  BattleResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct BattleResultScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel: BattleResultViewModel

    // Animation states (kept in View)
    @State private var showBackground: Bool = false
    @State private var showCard: Bool = false
    @State private var showHeader: Bool = false
    @State private var showXP: Bool = false
    @State private var startXPProgress: Bool = false
    @State private var startDropReveal: Bool = false
    @State private var showContinueButton: Bool = false

    init(result: ManualBattleResult) {
        self._viewModel = State(initialValue: BattleResultViewModel(result: result))
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ZStack {
            // Dimmed background
            ElfColors.Background.overlay
                .ignoresSafeArea()
                .opacity(showBackground ? 1.0 : 0.0)

            // Result card - VStack layout
            VStack(spacing: ElfSizing.BattleResult.sectionSpacing) {
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
                        continueAfterBattle()
                    }
                    .buttonStyle(.elfPrimary)
                    .opacity(showContinueButton ? 1.0 : 0.0)
                    .scaleEffect(showContinueButton ? 1.0 : 0.8)
                }
            }
            .padding(ElfSizing.BattleResult.cardPadding)
            .frame(width: 600, height: 340)
            .background(
                RoundedRectangle(cornerRadius: ElfSizing.BattleResult.cardCornerRadius)
                    .fill(ElfColors.Background.primary)
            )
            .scaleEffect(showCard ? 1.0 : 0.8)
            .opacity(showCard ? 1.0 : 0.0)
        }
        .task {
            await startAnimationSequence()
        }
    }

    /// Routes away from the result overlay. During a dungeon run the
    /// destination depends on the hero: a downed hero ends the run and returns
    /// to the Game Day screen, a surviving hero returns to the (now cleared)
    /// room. Hunt / dev battles keep the plain pop-back.
    private func continueAfterBattle() {
        router.dismissModal()
        if let dungeon = coordinator.gameSession?.dungeonSession, dungeon.isInRun {
            if dungeon.heroIsDowned {
                // Pop first, then release the run (see DungeonRouteView): removing
                // the route before nil-ing the session keeps DungeonScreen from
                // being rebuilt against a released session.
                router.popToGameDay()
                coordinator.gameSession?.endDungeonSession()
                // Persist the cleared run (dungeonSession now nil → no run).
                coordinator.gameSession?.saveInBackground()
            } else {
                router.pop()
            }
        } else {
            router.pop()
        }
    }

    // Animation delays use relative timing: (targetDelay - previousDelay) for sequential execution
    private func startAnimationSequence() async {
        // Background fade in
        withAnimation(.easeIn(duration: ElfAnimations.BattleResult.backgroundFadeDuration)) {
            showBackground = true
        }

        // Card appear
        try? await Task.sleep(for: .seconds(ElfAnimations.BattleResult.cardAppearDelay))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showCard = true
        }

        // Header appear
        try? await Task.sleep(for: .seconds(
            ElfAnimations.BattleResult.headerAppearDelay - ElfAnimations.BattleResult.cardAppearDelay
        ))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showHeader = true
        }

        // XP section appear
        try? await Task.sleep(for: .seconds(
            ElfAnimations.BattleResult.xpBarFillDelay - 0.2 - ElfAnimations.BattleResult.headerAppearDelay
        ))
        withAnimation(.easeInOut(duration: 0.3)) {
            showXP = true
        }

        // XP bar fill animation
        try? await Task.sleep(for: .seconds(0.2))
        startXPProgress = true

        // Drops reveal
        try? await Task.sleep(for: .seconds(
            ElfAnimations.BattleResult.dropItemDelay - ElfAnimations.BattleResult.xpBarFillDelay
        ))
        startDropReveal = true

        // Buttons appear
        let dropsDelay = viewModel.result.drops.isEmpty
            ? 0
            : Double(viewModel.result.drops.count) * ElfAnimations.BattleResult.dropItemStagger
        try? await Task.sleep(for: .seconds(dropsDelay + ElfAnimations.BattleResult.continueButtonDelay))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showContinueButton = true
        }
    }
}

// MARK: - Preview

#Preview("Victory with drops") {
    BattleResultScreen(
        result: ManualBattleResult(
            outcome: .victory,
            experienceGained: 15,
            drops: [
                DropItem(
                    itemType: .material,
                    name: "Soul Gem",
                    icon: "material_monster_soul_gem",
                    tier: .common,
                    quantity: 2
                ),
                DropItem(
                    itemType: .weapon,
                    name: "Steel Sword",
                    icon: "fa0b6893-6896-4689-a299-b8d271c76b68",
                    tier: .rare,
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
    .environment(AppRouter())
    .environment(AppCoordinator())
}

#Preview("Defeat") {
    BattleResultScreen(
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
    .environment(AppRouter())
    .environment(AppCoordinator())
}

#Preview("Draw") {
    BattleResultScreen(
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
    .environment(AppRouter())
    .environment(AppCoordinator())
}
