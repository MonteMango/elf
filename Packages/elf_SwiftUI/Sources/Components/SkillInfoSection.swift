//
//  SkillInfoSection.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Displays skill information with title, progress bar, and level
public struct SkillInfoSection: View {
    let title: String
    let progress: Double
    let currentExp: Int
    let maxExp: Int
    let level: Int

    public init(
        title: String,
        progress: Double,
        currentExp: Int,
        maxExp: Int,
        level: Int
    ) {
        self.title = title
        self.progress = progress
        self.currentExp = currentExp
        self.maxExp = maxExp
        self.level = level
    }

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: ElfSpacing.small) {
            // Title (italic, orange)
            Text(title)
                .font(.system(size: ElfFonts.Size.title2, weight: .bold))
                .italic()
                .foregroundStyle(ElfColors.primary)

            // Progress bar with XP text
            progressBar

            // Level (bold, orange)
            Text("LVL \(level)")
                .font(.system(size: ElfFonts.Size.titleLarge, weight: .bold))
                .foregroundStyle(ElfColors.primary)
        }
    }

    private var progressBar: some View {
        Capsule()
            .fill(ElfColors.ProgressBar.background)
            .frame(width: 200, height: ElfSizing.ProgressBar.regular)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(ElfColors.ProgressBar.xp)
                    .scaleEffect(x: progress, y: 1, anchor: .leading)
            }
            .overlay {
                Text("\(currentExp)/\(maxExp)")
                    .font(ElfFonts.Component.progressValue)
                    .foregroundStyle(ElfColors.Text.primary)
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        SkillInfoSection(
            title: "Fishing skill",
            progress: 0.6,
            currentExp: 30,
            maxExp: 50,
            level: 1
        )

        SkillInfoSection(
            title: "Mining skill",
            progress: 0.3,
            currentExp: 15,
            maxExp: 50,
            level: 2
        )
    }
    .padding()
    .background(Color.white)
}
