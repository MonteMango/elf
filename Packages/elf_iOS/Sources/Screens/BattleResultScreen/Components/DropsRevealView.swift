//
//  DropsRevealView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct DropsRevealView: View {
    let drops: [DropItem]
    let startReveal: Bool

    @State private var revealedCount: Int = 0

    var body: some View {
        if !drops.isEmpty {
            VStack(spacing: ElfSizing.BattleResult.smallSpacing) {
                Text("Loot")
                    .font(ElfFonts.Component.xpGained)
                    .foregroundStyle(ElfColors.Text.secondary)
                    .opacity(revealedCount > 0 ? 1.0 : 0.0)

                HStack(spacing: ElfSizing.BattleResult.dropItemSpacing) {
                    ForEach(Array(drops.enumerated()), id: \.element.id) { index, item in
                        DropItemCard(
                            item: item,
                            isVisible: index < revealedCount
                        )
                    }
                }
            }
            .task(id: startReveal) {
                if startReveal {
                    await revealDropsSequentially()
                }
            }
        }
    }

    private func revealDropsSequentially() async {
        for index in 0..<drops.count {
            if index > 0 {
                try? await Task.sleep(for: .seconds(ElfAnimations.BattleResult.dropItemStagger))
            }
            withAnimation {
                revealedCount = index + 1
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
                    tier: .common,
                    quantity: 2
                ),
                DropItem(
                    itemType: .weapon,
                    name: "Iron Sword",
                    icon: "sword",
                    tier: .uncommon,
                    quantity: 1
                )
            ],
            startReveal: true
        )
    }
}
