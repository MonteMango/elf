//
//  SkillProgressView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Generic skill progress view that can be used for any skill type (battle XP, fishing, foraging, etc.)
struct SkillProgressView: View {
    let progress: SkillProgressData
    let isVisible: Bool
    let showProgress: Bool

    @State private var animatedProgress: Double = 0
    @State private var showLevelUp: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // XP gained text
            Text("+\(progress.experienceGained) XP")
                .font(ElfFonts.Component.xpGained)
                .foregroundStyle(ElfColors.ProgressBar.xp)
                .opacity(isVisible ? 1.0 : 0.0)

            // Level and progress bar
            HStack(spacing: ElfSizing.BattleResult.smallSpacing) {
                // Current level badge
                levelBadge(level: progress.didLevelUp ? progress.newLevel : progress.previousLevel)

                // Progress bar
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: ElfSizing.BattleResult.xpBarCornerRadius)
                        .fill(ElfColors.ProgressBar.background)

                    // Fill
                    RoundedRectangle(cornerRadius: ElfSizing.BattleResult.xpBarCornerRadius)
                        .fill(ElfColors.ProgressBar.xp)
                        .scaleEffect(x: animatedProgress, y: 1, anchor: .leading)
                }
                .frame(
                    width: ElfSizing.BattleResult.xpBarWidth,
                    height: ElfSizing.BattleResult.xpBarHeight
                )

                // Next level badge
                levelBadge(level: progress.newLevel + 1)
                    .opacity(0.5)
            }
            .opacity(isVisible ? 1.0 : 0.0)

            // Level up text
            if progress.didLevelUp && showLevelUp {
                Text("LEVEL UP!")
                    .font(ElfFonts.Component.levelUpText)
                    .foregroundStyle(ElfColors.ProgressBar.levelUpGlow)
                    .shadow(color: ElfColors.ProgressBar.levelUpGlow, radius: 10)
                    .scaleEffect(showLevelUp ? 1.0 : 0.5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .task(id: showProgress) {
            if showProgress {
                await animateProgress()
            }
        }
    }

    private func levelBadge(level: Int) -> some View {
        ZStack {
            Circle()
                .fill(ElfColors.ProgressBar.xp)
                .frame(
                    width: ElfSizing.BattleResult.levelBadgeSize,
                    height: ElfSizing.BattleResult.levelBadgeSize
                )

            Text("\(level)")
                .font(ElfFonts.Component.levelNumber)
                .foregroundStyle(ElfColors.Text.primary)
        }
    }

    private func animateProgress() async {
        // Calculate target progress
        let targetProgress = Double(progress.newExp) / Double(progress.newExpToNext)

        // If leveled up, animate to 100% then reset to new progress
        if progress.didLevelUp {
            // First animate to 100%
            withAnimation(.easeInOut(duration: ElfAnimations.BattleResult.xpBarFillDuration * 0.6)) {
                animatedProgress = 1.0
            }

            // Then show level up and reset
            try? await Task.sleep(for: .seconds(ElfAnimations.BattleResult.xpBarFillDuration * 0.6))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showLevelUp = true
            }

            // Reset progress bar and animate to new value
            animatedProgress = 0
            withAnimation(.easeInOut(duration: ElfAnimations.BattleResult.xpBarFillDuration * 0.4)) {
                animatedProgress = targetProgress
            }
        } else {
            // Simple animation from previous to new
            let startProgress = Double(progress.previousExp) / Double(progress.previousExpToNext)
            animatedProgress = startProgress

            withAnimation(.easeInOut(duration: ElfAnimations.BattleResult.xpBarFillDuration)) {
                animatedProgress = targetProgress
            }
        }
    }
}

// MARK: - Preview

#Preview("Normal Progress") {
    ZStack {
        Color.black.ignoresSafeArea()
        SkillProgressView(
            progress: SkillProgressData(
                skillName: "Fishing",
                experienceGained: 15,
                previousLevel: 1,
                previousExp: 30,
                previousExpToNext: 50,
                newLevel: 1,
                newExp: 45,
                newExpToNext: 50
            ),
            isVisible: true,
            showProgress: true
        )
    }
}

#Preview("Level Up") {
    ZStack {
        Color.black.ignoresSafeArea()
        SkillProgressView(
            progress: SkillProgressData(
                skillName: "Fishing",
                experienceGained: 25,
                previousLevel: 1,
                previousExp: 40,
                previousExpToNext: 50,
                newLevel: 2,
                newExp: 15,
                newExpToNext: 50
            ),
            isVisible: true,
            showProgress: true
        )
    }
}
