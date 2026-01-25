//
//  ItemsGridView.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Data model for grid items
public struct GridItemData: Identifiable {
    public let id: UUID
    public let imageName: String
    public let tier: Int

    public init(id: UUID, imageName: String, tier: Int) {
        self.id = id
        self.imageName = imageName
        self.tier = tier
    }
}

/// Displays items in a wrapping grid layout
public struct ItemsGridView: View {
    let items: [GridItemData]

    public init(items: [GridItemData]) {
        self.items = items
    }

    public var body: some View {
        let columnCount = max(items.count, 1)
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.fixed(ElfSizing.ItemCard.size), spacing: ElfSpacing.small),
                count: columnCount
            ),
            spacing: ElfSpacing.small
        ) {
            ForEach(items) { item in
                ItemCard(
                    imageName: item.imageName,
                    rarityColor: .tier(item.tier)
                )
            }
        }
    }
}

#Preview {
    let sampleItems = [
        GridItemData(id: UUID(), imageName: "fish_sunny", tier: 3),
        GridItemData(id: UUID(), imageName: "fish_ember", tier: 2),
        GridItemData(id: UUID(), imageName: "fish_dewdrop", tier: 3),
        GridItemData(id: UUID(), imageName: "fish_pebble", tier: 4),
        GridItemData(id: UUID(), imageName: "fish_duskfin", tier: 1),
        GridItemData(id: UUID(), imageName: "fish_ribbontail", tier: 2)
    ]

    return ItemsGridView(items: sampleItems)
        .padding()
        .background(Color.white)
}
