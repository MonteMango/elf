//
//  FishCatchRevealView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// View that reveals caught fish one by one with animation
struct FishCatchRevealView: View {
    let caughtFish: [Fish]
    let startReveal: Bool

    @State private var revealedCount: Int = 0

    var body: some View {
        if !caughtFish.isEmpty {
            VStack(spacing: ElfSizing.BattleResult.smallSpacing) {
                Text("Catch")
                    .font(ElfFonts.Component.xpGained)
                    .foregroundStyle(ElfColors.Text.secondary)
                    .opacity(revealedCount > 0 ? 1.0 : 0.0)

                HStack(spacing: ElfSizing.BattleResult.dropItemSpacing) {
                    ForEach(Array(caughtFish.enumerated()), id: \.element.id) { index, fish in
                        FishItemCard(
                            fish: fish,
                            isVisible: index < revealedCount
                        )
                    }
                }
            }
            .task(id: startReveal) {
                if startReveal {
                    await revealFishSequentially()
                }
            }
        }
    }

    private func revealFishSequentially() async {
        for index in 0..<caughtFish.count {
            if index > 0 {
                try? await Task.sleep(for: .seconds(ElfAnimations.BattleResult.dropItemStagger))
            }
            withAnimation {
                revealedCount = index + 1
            }
        }
    }
}

// MARK: - Fish Item Card

private struct FishItemCard: View {
    let fish: Fish
    let isVisible: Bool

    var body: some View {
        ItemCard(
            imageName: fish.imageName,
            rarityColor: .tier(fish.tier),
            showLabel: fish.title
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
        FishCatchRevealView(
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
            startReveal: true
        )
    }
}
