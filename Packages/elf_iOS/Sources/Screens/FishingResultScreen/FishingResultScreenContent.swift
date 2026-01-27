//
//  FishingResultScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct FishingResultScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: FishingResultViewModel

    // Animation states (kept in View)
    @State private var showBackground: Bool = false
    @State private var showCard: Bool = false
    @State private var showHeader: Bool = false
    @State private var showSkillProgress: Bool = false
    @State private var startSkillProgressAnimation: Bool = false
    @State private var startFishReveal: Bool = false
    @State private var showContinueButton: Bool = false

    init(viewModel: FishingResultViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Dimmed background
            ElfColors.Background.overlay
                .ignoresSafeArea()
                .opacity(showBackground ? 1.0 : 0.0)

            // Result card - VStack layout
            VStack(spacing: ElfSizing.BattleResult.sectionSpacing) {
                // Header
                resultHeader
                    .scaleEffect(showHeader ? 1.0 : 0.5)
                    .opacity(showHeader ? 1.0 : 0.0)

                // Skill progress
                SkillProgressView(
                    progress: viewModel.result.skillProgress,
                    isVisible: showSkillProgress,
                    showProgress: startSkillProgressAnimation
                )

                // Caught fish
                if !viewModel.result.isEmpty {
                    FishCatchRevealView(
                        caughtFish: viewModel.result.caughtFish,
                        startReveal: startFishReveal
                    )
                }

                Spacer()

                // Continue button (single button, unlike Battle which has Analyze)
                HStack {
                    Spacer()

                    Button("Continue") {
                        router.dismissModal()
                    }
                    .buttonStyle(.elfPrimary)
                    .opacity(showContinueButton ? 1.0 : 0.0)
                    .scaleEffect(showContinueButton ? 1.0 : 0.8)
                }
            }
            .padding(ElfSizing.BattleResult.cardPadding)
            .frame(width: ElfSizing.FishingResult.cardWidth, height: ElfSizing.FishingResult.cardHeight)
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

    // MARK: - Header

    @ViewBuilder
    private var resultHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: ElfSizing.BattleResult.smallSpacing) {
            Image(systemName: viewModel.result.isEmpty ? "fish" : "fish.fill")
                .font(.system(size: ElfSizing.BattleResult.outcomeIconSize))
                .foregroundStyle(
                    viewModel.result.isEmpty ? ElfColors.Text.secondary : ElfColors.Battle.victory
                )

            Text(viewModel.result.isEmpty ? "Nothing caught..." : "Fishing complete!")
                .font(ElfFonts.Component.outcomeTitle)
                .foregroundStyle(
                    viewModel.result.isEmpty ? ElfColors.Text.secondary : ElfColors.Text.primary
                )
        }
    }

    // MARK: - Animation Sequence

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

        // Skill progress appear
        try? await Task.sleep(for: .seconds(0.2))
        withAnimation(.easeInOut(duration: 0.3)) {
            showSkillProgress = true
        }

        // Start skill progress animation
        try? await Task.sleep(for: .seconds(0.2))
        startSkillProgressAnimation = true

        // Start fish reveal
        try? await Task.sleep(for: .seconds(0.5))
        startFishReveal = true

        // Continue button
        let fishDelay = viewModel.result.isEmpty
            ? 0.3
            : Double(viewModel.result.fishCount) * ElfAnimations.BattleResult.dropItemStagger + 0.3
        try? await Task.sleep(for: .seconds(fishDelay))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showContinueButton = true
        }
    }
}

// MARK: - Preview

#Preview("With Fish") {
    FishingResultScreenContent(
        viewModel: FishingResultViewModel(
            result: FishingResult(
                caughtFish: [
                    Fish(
                        id: UUID(),
                        title: "Sunny",
                        imageName: "fish_sunny",
                        description: "A bright golden fish",
                        tier: 4,
                        baseCatchChance: 0.35,
                        effects: []
                    ),
                    Fish(
                        id: UUID(),
                        title: "Ember",
                        imageName: "fish_ember",
                        description: "A fiery fish",
                        tier: 3,
                        baseCatchChance: 0.18,
                        effects: []
                    )
                ],
                skillProgress: SkillProgressData(
                    skillName: "Fishing",
                    experienceGained: 15,
                    previousLevel: 1,
                    previousExp: 30,
                    previousExpToNext: 50,
                    newLevel: 1,
                    newExp: 45,
                    newExpToNext: 50
                )
            )
        )
    )
    .environment(AppRouter())
}

#Preview("Empty") {
    FishingResultScreenContent(
        viewModel: FishingResultViewModel(
            result: FishingResult(
                caughtFish: [],
                skillProgress: SkillProgressData(
                    skillName: "Fishing",
                    experienceGained: 0,
                    previousLevel: 1,
                    previousExp: 30,
                    previousExpToNext: 50,
                    newLevel: 1,
                    newExp: 30,
                    newExpToNext: 50
                )
            )
        )
    )
    .environment(AppRouter())
}
