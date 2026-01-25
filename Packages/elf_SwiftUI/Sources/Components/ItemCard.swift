//
//  ItemCard.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

// MARK: - Rarity Color Abstraction

/// Defines background color for ItemCard based on rarity/tier.
public enum ItemCardColor: Sendable {
    case tier(Int)
    case rarity(RarityLevel)
    case custom(Color)

    public enum RarityLevel: Sendable {
        case common
        case uncommon
        case rare
        case epic
        case legendary
    }

    public var color: Color {
        switch self {
        case .tier(let tier):
            return ElfColors.Tier.color(for: tier)
        case .rarity(let level):
            switch level {
            case .common: return .gray
            case .uncommon: return .green.opacity(0.7)
            case .rare: return .green
            case .epic: return .purple
            case .legendary: return .blue
            }
        case .custom(let color):
            return color
        }
    }
}

// MARK: - ItemCard

/// Unified component for displaying items with colored background based on rarity.
/// Used for fish, drops, loot, and other collectible items.
/// Fixed size: 45x45
public struct ItemCard: View {
    let imageName: String
    let rarityColor: ItemCardColor
    var quantity: Int?
    var showLabel: String?
    var isSelected: Bool
    var onTap: (() -> Void)?

    public init(
        imageName: String,
        rarityColor: ItemCardColor,
        quantity: Int? = nil,
        showLabel: String? = nil,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.imageName = imageName
        self.rarityColor = rarityColor
        self.quantity = quantity
        self.showLabel = showLabel
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: ElfSpacing.xxxs) {
                cardContent
                labelView
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        ZStack {
            // Background colored by rarity/tier
            Rectangle()
                .fill(rarityColor.color)

            // Item image
            itemImage
                .padding(ElfSpacing.xxs)

            // Quantity badge
            quantityBadge

            // Selection overlay
            selectionOverlay
        }
        .frame(width: ElfSizing.ItemCard.size, height: ElfSizing.ItemCard.size)
    }

    // MARK: - Item Image

    private var itemImage: some View {
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "square.dashed")
                    .foregroundStyle(rarityColor.color)
            }
        }
    }

    // MARK: - Quantity Badge

    @ViewBuilder
    private var quantityBadge: some View {
        if let qty = quantity, qty > 1 {
            Text("x\(qty)")
                .font(ElfFonts.Component.itemQuantity)
                .foregroundStyle(.white)
                .padding(.horizontal, ElfSpacing.xxs)
                .padding(.vertical, 1)
                .background(
                    Capsule()
                        .fill(ElfColors.primary)
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topTrailing
                )
                .padding(ElfSpacing.xxxs)
        }
    }

    // MARK: - Label

    @ViewBuilder
    private var labelView: some View {
        if let label = showLabel {
            Text(label)
                .font(ElfFonts.Component.dropItemName)
                .foregroundStyle(ElfColors.Text.primary)
                .lineLimit(1)
                .frame(width: ElfSizing.ItemCard.size)
        }
    }

    // MARK: - Selection Overlay

    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected {
            Rectangle()
                .stroke(ElfColors.Interactive.selected, lineWidth: 3)
                .shadow(color: ElfColors.Interactive.selected.opacity(0.5), radius: 4)
        }
    }
}

// MARK: - Preview

#Preview("Tier-based (Fish)") {
    HStack(spacing: 12) {
        ItemCard(
            imageName: "fish_sunny",
            rarityColor: .tier(1)
        )
        ItemCard(
            imageName: "fish_ember",
            rarityColor: .tier(2)
        )
        ItemCard(
            imageName: "fish_dewdrop",
            rarityColor: .tier(3)
        )
        ItemCard(
            imageName: "fish_pebble",
            rarityColor: .tier(4)
        )
    }
    .padding()
    .background(Color.white)
}

#Preview("Rarity-based (Drops)") {
    HStack(spacing: 12) {
        ItemCard(
            imageName: "material_monster_soul_gem",
            rarityColor: .rarity(.common),
            quantity: 3,
            showLabel: "Soul Gem"
        )
        ItemCard(
            imageName: "material_monster_soul_gem",
            rarityColor: .rarity(.rare),
            quantity: 1,
            showLabel: "Rare Gem"
        )
        ItemCard(
            imageName: "material_monster_soul_gem",
            rarityColor: .rarity(.legendary),
            showLabel: "Legend"
        )
    }
    .padding()
    .background(Color.black)
}

#Preview("Interactive") {
    HStack(spacing: 12) {
        ItemCard(
            imageName: "fish_sunny",
            rarityColor: .tier(2),
            isSelected: false
        )
        ItemCard(
            imageName: "fish_ember",
            rarityColor: .tier(2),
            isSelected: true
        )
    }
    .padding()
    .background(Color.white)
}
