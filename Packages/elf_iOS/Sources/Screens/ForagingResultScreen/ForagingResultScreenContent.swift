//
//  ForagingResultScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct ForagingResultScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: ForagingResultViewModel

    // Animation states (kept in View)
    @State private var showBackground: Bool = false
    @State private var showCard: Bool = false
    @State private var showHeader: Bool = false
    @State private var showSkillProgress: Bool = false
    @State private var startSkillProgressAnimation: Bool = false
    @State private var startHerbReveal: Bool = false
    @State private var showContinueButton: Bool = false

    init(viewModel: ForagingResultViewModel) {
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
                    experienceGained: viewModel.result.skillProgress.experienceGained,
                    previousLevel: viewModel.result.skillProgress.previousLevel,
                    previousExp: viewModel.result.skillProgress.previousExp,
                    previousExpToNext: viewModel.result.skillProgress.previousExpToNext,
                    newLevel: viewModel.result.skillProgress.newLevel,
                    newExp: viewModel.result.skillProgress.newExp,
                    newExpToNext: viewModel.result.skillProgress.newExpToNext,
                    didLevelUp: viewModel.result.skillProgress.didLevelUp,
                    isVisible: showSkillProgress,
                    showProgress: startSkillProgressAnimation
                )

                // Gathered herbs
                if !viewModel.result.isEmpty {
                    HerbGatherRevealView(
                        gatheredHerbs: viewModel.result.gatheredHerbs,
                        startReveal: startHerbReveal
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
            Image(systemName: viewModel.result.isEmpty ? "leaf" : "leaf.fill")
                .font(.system(size: ElfSizing.BattleResult.outcomeIconSize))
                .foregroundStyle(
                    viewModel.result.isEmpty ? ElfColors.Text.secondary : ElfColors.Battle.victory
                )

            Text(viewModel.result.isEmpty ? "Nothing found..." : "Foraging complete!")
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

        // Start herb reveal
        try? await Task.sleep(for: .seconds(0.5))
        startHerbReveal = true

        // Continue button
        let herbDelay = viewModel.result.isEmpty
            ? 0.3
            : Double(viewModel.result.herbCount) * ElfAnimations.BattleResult.dropItemStagger + 0.3
        try? await Task.sleep(for: .seconds(herbDelay))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showContinueButton = true
        }
    }
}

// MARK: - Preview

#Preview("With Herbs") {
    ForagingResultScreenContent(
        viewModel: ForagingResultViewModel(
            result: ForagingResult(
                gatheredHerbs: [
                    Herb(
                        id: HerbID(),
                        title: "Sunpetal",
                        imageName: "herb_sunpetal",
                        description: "A golden flower",
                        tier: .common,
                        baseGatherChance: 0.35,
                        effects: []
                    ),
                    Herb(
                        id: HerbID(),
                        title: "Bloodberry",
                        imageName: "herb_bloodberry",
                        description: "Deep red berries",
                        tier: .uncommon,
                        baseGatherChance: 0.20,
                        effects: []
                    )
                ],
                skillProgress: SkillProgressData(
                    skillName: "Foraging",
                    experienceGained: 13,
                    previousLevel: 1,
                    previousExp: 30,
                    previousExpToNext: 50,
                    newLevel: 1,
                    newExp: 43,
                    newExpToNext: 50
                )
            )
        )
    )
    .environment(AppRouter())
}

#Preview("Empty") {
    ForagingResultScreenContent(
        viewModel: ForagingResultViewModel(
            result: ForagingResult(
                gatheredHerbs: [],
                skillProgress: SkillProgressData(
                    skillName: "Foraging",
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
