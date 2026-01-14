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
        VStack(spacing: 2) {
            // Item icon with rarity border
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(ElfColors.Background.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                rarityColor(for: item.rarity),
                                lineWidth: ElfSizing.BattleResult.dropItemBorderWidth
                            )
                    )

                // Icon
                itemIcon
                    .padding(6)

                // Quantity badge (top-right corner)
                if item.quantity > 1 {
                    Text("x\(item.quantity)")
                        .font(ElfFonts.Component.dropItemQuantity)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topTrailing
                        )
                        .padding(2)
                }
            }
            .frame(
                width: ElfSizing.BattleResult.dropItemSize,
                height: ElfSizing.BattleResult.dropItemSize
            )

            // Item name
            Text(item.name)
                .font(ElfFonts.Component.dropItemName)
                .foregroundStyle(ElfColors.Text.primary)
                .lineLimit(1)
                .frame(width: ElfSizing.BattleResult.dropItemSize)
        }
        .scaleEffect(isVisible ? 1.0 : 0.3)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: isVisible
        )
    }

    private var itemIcon: some View {
        Image(item.icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private func rarityColor(for rarity: ItemRarity) -> Color {
        switch rarity {
        case .common:
            return ElfColors.Rarity.common
        case .uncommon:
            return ElfColors.Rarity.uncommon
        case .rare:
            return ElfColors.Rarity.rare
        case .epic:
            return ElfColors.Rarity.epic
        case .legendary:
            return ElfColors.Rarity.legendary
        }
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
                    rarity: .common,
                    quantity: 3
                ),
                isVisible: true
            )

            DropItemCard(
                item: DropItem(
                    itemType: .weapon,
                    name: "Steel Sword",
                    icon: "fa0b6893-6896-4689-a299-b8d271c76b68",
                    rarity: .rare,
                    quantity: 1
                ),
                isVisible: true
            )

            DropItemCard(
                item: DropItem(
                    itemType: .armor,
                    name: "Goblin Shield",
                    icon: "c4af732e-4912-4f09-aa2b-77b5bcb6fc11",
                    rarity: .legendary,
                    quantity: 1
                ),
                isVisible: true
            )
        }
    }
}
