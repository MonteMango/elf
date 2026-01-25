//
//  ItemDetailPanel.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct ItemDetailPanel: View {
    let item: InventoryDisplayItem?
    let onEquip: () -> Void
    let onUnequip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let item = item {
                itemContent(item)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.gray.opacity(0.2)
        }
    }

    // MARK: - Item Content

    @ViewBuilder
    private func itemContent(_ item: InventoryDisplayItem) -> some View {
        VStack(spacing: 15) {
            // Item image
            itemImage(item)

            // Item title
            Text(item.title)
                .font(ElfFonts.Component.itemTitle)
                .foregroundStyle(.black)

            // Item description/stats (scrollable for long descriptions)
            ScrollView {
                itemStats(item)
            }

            // Equip/Unequip button
            equipButton(item)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Item Image

    private func itemImage(_ item: InventoryDisplayItem) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))

            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .padding(10)
        }
        .frame(width: 90, height: 90)
    }

    // MARK: - Item Stats

    @ViewBuilder
    private func itemStats(_ item: InventoryDisplayItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(item.itemDetails.descriptionLines, id: \.self) { line in
                if line.isEmpty {
                    Spacer().frame(height: 8)
                } else {
                    Text("- \(line)")
                        .font(ElfFonts.Component.itemDetail)
                        .foregroundStyle(.black)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Equip Button

    @ViewBuilder
    private func equipButton(_ item: InventoryDisplayItem) -> some View {
        // Don't show equip button for materials
        if item.category != .materials {
            Button(action: {
                if item.isEquipped {
                    onUnequip()
                } else {
                    onEquip()
                }
            }) {
                Text(item.isEquipped ? "Unequip" : "Equip")
                    .font(ElfFonts.Component.itemTitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("Select an item")
                .font(ElfFonts.Component.itemEmptyState)
                .foregroundStyle(.gray)
            Spacer()
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        // With item selected
        ItemDetailPanel(
            item: InventoryDisplayItem(
                id: UUID(),
                title: "Wooden club",
                imageName: "weapon_club",
                isEquipped: true,
                category: .weapons,
                itemDetails: .weapon(WeaponDetails(
                    attackMin: 8,
                    attackMax: 9,
                    attackPoints: 1,
                    handUse: "one hand",
                    strength: 2,
                    agility: 1,
                    power: 1,
                    instinct: 1,
                    hitPoints: 10
                ))
            ),
            onEquip: {},
            onUnequip: {}
        )

        // Empty state
        ItemDetailPanel(
            item: nil,
            onEquip: {},
            onUnequip: {}
        )
    }
    .frame(height: 400)
}
