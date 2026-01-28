//
//  OreMineRevealView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// View that reveals mined ores one by one with animation
struct OreMineRevealView: View {
    let minedOres: [Ore]
    let startReveal: Bool

    @State private var revealedCount: Int = 0

    var body: some View {
        if !minedOres.isEmpty {
            VStack(spacing: ElfSizing.BattleResult.smallSpacing) {
                Text("Mined")
                    .font(ElfFonts.Component.xpGained)
                    .foregroundStyle(ElfColors.Text.secondary)
                    .opacity(revealedCount > 0 ? 1.0 : 0.0)

                HStack(spacing: ElfSizing.BattleResult.dropItemSpacing) {
                    ForEach(Array(minedOres.enumerated()), id: \.element.id) { index, ore in
                        OreItemCard(
                            ore: ore,
                            isVisible: index < revealedCount
                        )
                    }
                }
            }
            .task(id: startReveal) {
                if startReveal {
                    await revealOresSequentially()
                }
            }
        }
    }

    private func revealOresSequentially() async {
        for index in 0..<minedOres.count {
            if index > 0 {
                try? await Task.sleep(for: .seconds(ElfAnimations.BattleResult.dropItemStagger))
            }
            withAnimation {
                revealedCount = index + 1
            }
        }
    }
}

// MARK: - Ore Item Card

private struct OreItemCard: View {
    let ore: Ore
    let isVisible: Bool

    var body: some View {
        ItemCard(
            imageName: ore.imageName,
            rarityColor: .tier(ore.tier.rawValue),
            showLabel: ore.title
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
        OreMineRevealView(
            minedOres: [
                Ore(
                    id: OreID(),
                    title: "Copper Chunk",
                    imageName: "ore_copper_chunk",
                    description: "Basic copper ore",
                    tier: .common,
                    baseMineChance: 0.35,
                    effects: []
                ),
                Ore(
                    id: OreID(),
                    title: "Gold Nugget",
                    imageName: "ore_gold_nugget",
                    description: "Precious gold ore",
                    tier: .rare,
                    baseMineChance: 0.10,
                    effects: []
                )
            ],
            startReveal: true
        )
    }
}
