//
//  DropsRevealView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import elf_Kit
import SwiftUI

struct DropsRevealView: View {
    let drops: [DropItem]
    let startReveal: Bool

    @State private var revealedCount: Int = 0

    var body: some View {
        if !drops.isEmpty {
            VStack(spacing: BattleResultConstants.Sizing.smallSpacing) {
                Text("Loot")
                    .font(BattleResultConstants.Fonts.xpGained)
                    .foregroundStyle(BattleResultConstants.Colors.secondaryText)
                    .opacity(revealedCount > 0 ? 1.0 : 0.0)

                HStack(spacing: BattleResultConstants.Sizing.dropItemSpacing) {
                    ForEach(Array(drops.enumerated()), id: \.element.id) { index, item in
                        DropItemCard(
                            item: item,
                            isVisible: index < revealedCount
                        )
                    }
                }
            }
            .onAppear {
                if startReveal {
                    revealDropsSequentially()
                }
            }
            .onChange(of: startReveal) { _, shouldStart in
                if shouldStart {
                    revealDropsSequentially()
                }
            }
        }
    }

    private func revealDropsSequentially() {
        for index in 0..<drops.count {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * BattleResultConstants.Animation.dropItemStagger
            ) {
                withAnimation {
                    revealedCount = index + 1
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        DropsRevealView(
            drops: [
                DropItem(
                    itemType: .material,
                    name: "Wolf Pelt",
                    icon: "leaf",
                    rarity: .common,
                    quantity: 2
                ),
                DropItem(
                    itemType: .weapon,
                    name: "Iron Sword",
                    icon: "sword",
                    rarity: .uncommon,
                    quantity: 1
                )
            ],
            startReveal: true
        )
    }
}
