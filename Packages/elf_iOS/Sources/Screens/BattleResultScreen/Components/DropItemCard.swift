//
//  DropItemCard.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct DropItemCard: View {
    let item: DropItem
    let isVisible: Bool

    var body: some View {
        ItemCard(
            imageName: item.icon,
            rarityColor: item.tier.cardColor,
            quantity: item.quantity > 1 ? item.quantity : nil,
            showLabel: item.name
        )
        .scaleEffect(isVisible ? 1.0 : 0.3)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: isVisible
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 16) {
            DropItemCard(
                item: DropItem(
                    itemType: .material,
                    name: "Soul Gem",
                    icon: "material_monster_soul_gem",
                    tier: .common,
                    quantity: 3
                ),
                isVisible: true
            )

            DropItemCard(
                item: DropItem(
                    itemType: .weapon,
                    name: "Steel Sword",
                    icon: "fa0b6893-6896-4689-a299-b8d271c76b68",
                    tier: .rare,
                    quantity: 1
                ),
                isVisible: true
            )

            DropItemCard(
                item: DropItem(
                    itemType: .armor,
                    name: "Goblin Shield",
                    icon: "c4af732e-4912-4f09-aa2b-77b5bcb6fc11",
                    tier: .legendary,
                    quantity: 1
                ),
                isVisible: true
            )
        }
    }
}
