//
//  InventoryGrid.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct InventoryGrid: View {
    let items: [InventoryItemDisplay]
    let selectedItemId: UUID?
    let onItemTap: (InventoryItemDisplay) -> Void

    private let cellSize: CGFloat = 45
    private let spacing: CGFloat = 5

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: spacing, alignment: .leading)]
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
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
            InventoryItemDisplay(
                id: UUID(),
                title: "Wooden club",
                imageName: "weapon_club",
                isEquipped: true,
                category: .weapons,
                itemDetails: .weapon(WeaponAttributes(
                    attackMin: 8, attackMax: 9, attackPoints: 1, handUse: "one hand"
                ))
            ),
            InventoryItemDisplay(
                id: UUID(),
                title: "Iron sword",
                imageName: "weapon_sword",
                category: .weapons,
                itemDetails: .weapon(WeaponAttributes(
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
