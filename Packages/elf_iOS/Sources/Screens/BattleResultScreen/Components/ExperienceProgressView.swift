//
//  ExperienceProgressView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct ExperienceProgressView: View {
    let result: ManualBattleResult
    let isVisible: Bool
    let showProgress: Bool

    @State private var animatedProgress: Double = 0
    @State private var showLevelUp: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // XP gained text
            Text("+\(result.experienceGained) XP")
                .font(ElfFonts.Component.xpGained)
                .foregroundStyle(ElfColors.ProgressBar.xp)
                .opacity(isVisible ? 1.0 : 0.0)

            // Level and progress bar
            HStack(spacing: ElfSizing.BattleResult.smallSpacing) {
                // Current level badge
                levelBadge(level: Int(result.didLevelUp ? result.newLevel : result.previousLevel))

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: ElfSizing.BattleResult.xpBarCornerRadius)
                            .fill(ElfColors.ProgressBar.background)

                        // Fill
                        RoundedRectangle(cornerRadius: ElfSizing.BattleResult.xpBarCornerRadius)
                            .fill(ElfColors.ProgressBar.xp)
                            .frame(width: geometry.size.width * animatedProgress)
                    }
                }
                .frame(
                    width: ElfSizing.BattleResult.xpBarWidth,
                    height: ElfSizing.BattleResult.xpBarHeight
                )

                // Next level badge
                levelBadge(level: Int(result.newLevel) + 1)
                    .opacity(0.5)
            }
            .opacity(isVisible ? 1.0 : 0.0)

            // Level up text
            if result.didLevelUp && showLevelUp {
                Text("LEVEL UP!")
                    .font(ElfFonts.Component.levelUpText)
                    .foregroundStyle(ElfColors.ProgressBar.levelUpGlow)
                    .shadow(color: ElfColors.ProgressBar.levelUpGlow, radius: 10)
                    .scaleEffect(showLevelUp ? 1.0 : 0.5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: showProgress) { _, shouldShow in
            if shouldShow {
                animateProgress()
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

    private func animateProgress() {
        // Calculate target progress
        let targetProgress = Double(result.newExp) / Double(result.newExpToNext)

        // If leveled up, animate to 100% then reset to new progress
        if result.didLevelUp {
            // First animate to 100%
            withAnimation(.easeInOut(duration: ElfAnimations.BattleResult.xpBarFillDuration * 0.6)) {
                animatedProgress = 1.0
            }

            // Then show level up and reset
            DispatchQueue.main.asyncAfter(
                deadline: .now() + ElfAnimations.BattleResult.xpBarFillDuration * 0.6
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showLevelUp = true
                }

                // Reset progress bar and animate to new value
                animatedProgress = 0
                withAnimation(.easeInOut(duration: ElfAnimations.BattleResult.xpBarFillDuration * 0.4)) {
                    animatedProgress = targetProgress
                }
            }
        } else {
            // Simple animation from previous to new
            let startProgress = Double(result.previousExp) / Double(result.previousExpToNext)
            animatedProgress = startProgress

            withAnimation(.easeInOut(duration: ElfAnimations.BattleResult.xpBarFillDuration)) {
                animatedProgress = targetProgress
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ExperienceProgressView(
            result: ManualBattleResult(
                outcome: .victory,
                experienceGained: 15,
                drops: [],
                previousLevel: 1,
                previousExp: 80,
                previousExpToNext: 100,
                newLevel: 2,
                newExp: 15,
                newExpToNext: 120
            ),
            isVisible: true,
            showProgress: true
        )
    }
}
