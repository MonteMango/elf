//
//  InventoryCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct InventoryCell: View {
    let item: InventoryDisplayItem
    let isSelected: Bool
    let onTap: () -> Void

    private let cellSize: CGFloat = 45

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.3))

                // Item image
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(4)

                // Equipped label
                if item.isEquipped {
                    Text("equipped")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                        .background(Color.orange)
                        .offset(x: 0, y: 0)
                }

                // Quantity badge
                if let quantity = item.quantity {
                    Text("\(quantity)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(2)
                }

                // Selection border
                if isSelected {
                    Rectangle()
                        .strokeBorder(Color.orange, lineWidth: 3)
                }
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 10) {
        // Normal item
        InventoryCell(
            item: InventoryDisplayItem(
                id: UUID(),
                title: "Sword",
                imageName: "sword",
                category: .weapons,
                itemDetails: .weapon(WeaponDetails(
                    attackMin: 10,
                    attackMax: 15,
                    attackPoints: 1,
                    handUse: "one hand"
                ))
            ),
            isSelected: false,
            onTap: {}
        )

        // Selected item
        InventoryCell(
            item: InventoryDisplayItem(
                id: UUID(),
                title: "Axe",
                imageName: "axe",
                isEquipped: true,
                category: .weapons,
                itemDetails: .weapon(WeaponDetails(
                    attackMin: 10,
                    attackMax: 15,
                    attackPoints: 1,
                    handUse: "one hand"
                ))
            ),
            isSelected: true,
            onTap: {}
        )

        // Material with quantity
        InventoryCell(
            item: InventoryDisplayItem(
                id: UUID(),
                title: "Iron ore",
                imageName: "ore",
                quantity: 12,
                category: .materials,
                itemDetails: .material(MaterialDetails(description: "Raw iron"))
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(Color.white)
}
