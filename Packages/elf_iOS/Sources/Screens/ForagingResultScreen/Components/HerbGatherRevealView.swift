//
//  HerbGatherRevealView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// View that reveals gathered herbs one by one with animation
struct HerbGatherRevealView: View {
    let gatheredHerbs: [Herb]
    let startReveal: Bool

    @State private var revealedCount: Int = 0

    var body: some View {
        if !gatheredHerbs.isEmpty {
            VStack(spacing: ElfSizing.BattleResult.smallSpacing) {
                Text("Gathered")
                    .font(ElfFonts.Component.xpGained)
                    .foregroundStyle(ElfColors.Text.secondary)
                    .opacity(revealedCount > 0 ? 1.0 : 0.0)

                HStack(spacing: ElfSizing.BattleResult.dropItemSpacing) {
                    ForEach(Array(gatheredHerbs.enumerated()), id: \.element.id) { index, herb in
                        HerbItemCard(
                            herb: herb,
                            isVisible: index < revealedCount
                        )
                    }
                }
            }
            .task(id: startReveal) {
                if startReveal {
                    await revealHerbsSequentially()
                }
            }
        }
    }

    private func revealHerbsSequentially() async {
        for index in 0..<gatheredHerbs.count {
            if index > 0 {
                try? await Task.sleep(for: .seconds(ElfAnimations.BattleResult.dropItemStagger))
            }
            withAnimation {
                revealedCount = index + 1
            }
        }
    }
}

// MARK: - Herb Item Card

private struct HerbItemCard: View {
    let herb: Herb
    let isVisible: Bool

    var body: some View {
        ItemCard(
            imageName: herb.imageName,
            rarityColor: .tier(herb.tier.rawValue),
            showLabel: herb.title
        )
        .scaleEffect(isVisible ? 1.0 : 0.3)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: isVisible
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HerbGatherRevealView(
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
            startReveal: true
        )
    }
}
