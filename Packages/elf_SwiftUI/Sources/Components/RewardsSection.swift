//
//  RewardsSection.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Plain data carrier for one reward/drop entry. Lives in `elf_SwiftUI` so
/// feature-specific Display DTOs (`QuestRewardDisplay`, `DungeonDropDisplay`,
/// …) can map down into a single shared component without leaking their own
/// types into the design system.
public struct RewardItemData: Identifiable, Equatable, Sendable {
    public let id: String
    public let imageName: String
    public let quantity: Int?
    public let tier: Int

    public init(id: String, imageName: String, quantity: Int? = nil, tier: Int = 4) {
        self.id = id
        self.imageName = imageName
        self.quantity = quantity
        self.tier = tier
    }
}

/// Title + horizontal row of `ItemCard`s. Used for quest rewards, dungeon
/// possible-drops, and any other "here's what you'll walk away with" preview.
/// Returns nothing when `items` is empty so the surrounding layout collapses.
public struct RewardsSection: View {
    private let title: String
    private let items: [RewardItemData]
    private let titleColor: Color

    public init(
        title: String,
        items: [RewardItemData],
        titleColor: Color = ElfColors.Text.primary
    ) {
        self.title = title
        self.items = items
        self.titleColor = titleColor
    }

    public var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: ElfSpacing.small) {
                Text(title)
                    .font(.system(size: ElfFonts.Size.callout, weight: .semibold))
                    .foregroundStyle(titleColor)

                HStack(spacing: ElfSpacing.small) {
                    ForEach(items) { item in
                        ItemCard(
                            imageName: item.imageName,
                            rarityColor: .tier(item.tier),
                            quantity: item.quantity
                        )
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Rewards") {
    RewardsSection(
        title: "Rewards:",
        items: [
            RewardItemData(id: "1", imageName: "fish_sunny", quantity: 3, tier: 1),
            RewardItemData(id: "2", imageName: "fish_ember", quantity: 1, tier: 3)
        ]
    )
    .padding()
    .background(Color.white)
}

#Preview("Empty") {
    RewardsSection(title: "Rewards:", items: [])
        .padding()
        .background(Color.white)
}
#endif
