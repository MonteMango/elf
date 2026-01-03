//
//  InventoryGrid.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct InventoryGrid: View {
    let items: [InventoryDisplayItem]
    let selectedItemId: UUID?
    let onItemTap: (InventoryDisplayItem) -> Void

    private let cellSize: CGFloat = 45
    private let spacing: CGFloat = 5

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: spacing, alignment: .leading)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
                ForEach(items) { item in
                    InventoryCell(
                        item: item,
                        isSelected: item.id == selectedItemId,
                        onTap: { onItemTap(item) }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    InventoryGrid(
        items: [
            InventoryDisplayItem(
                id: UUID(),
                title: "Wooden club",
                imageName: "weapon_club",
                isEquipped: true,
                category: .weapons,
                itemDetails: .weapon(WeaponDetails(
                    attackMin: 8, attackMax: 9, attackPoints: 1, handUse: "one hand"
                ))
            ),
            InventoryDisplayItem(
                id: UUID(),
                title: "Iron sword",
                imageName: "weapon_sword",
                category: .weapons,
                itemDetails: .weapon(WeaponDetails(
                    attackMin: 12, attackMax: 15, attackPoints: 1, handUse: "one hand"
                ))
            )
        ],
        selectedItemId: nil,
        onItemTap: { _ in }
    )
    .frame(width: 300, height: 200)
    .background(Color.white)
}
