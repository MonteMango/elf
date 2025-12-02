//
//  ItemCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import SwiftUI
import elf_Kit

internal struct ItemCell: View {
    let item: Item
    let isSelected: Bool

    var body: some View {
        // Item image
        Image("card_\(item.id.uuidString.lowercased())")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 150, height: 240)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .top) {
                // Item title overlay on top of image
                Text(item.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 8,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 8
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.5) : Color.clear, radius: 8)
    }
}

// MARK: - Preview

#Preview("Selected") {
    struct MockItem: Item {
        let id: UUID
        let title: String
        let tier: Int16
        var isUnique: Bool?
        var strength: Int16?
        var agility: Int16?
        var power: Int16?
        var instinct: Int16?
        var hitPoints: Int16?
        var manaPoints: Int16?
    }

    let mockItem = MockItem(
        id: UUID(uuidString: "898a28b5-7189-4b21-b821-6b67ad2e8269")!,
        title: "Dragon Helmet",
        tier: 3,
        strength: 15,
        agility: 5,
        hitPoints: 30
    )

    return ItemCell(item: mockItem, isSelected: true)
        .background(Color.black)
}

#Preview("Not Selected") {
    struct MockItem: Item {
        let id: UUID
        let title: String
        let tier: Int16
        var isUnique: Bool?
        var strength: Int16?
        var agility: Int16?
        var power: Int16?
        var instinct: Int16?
        var hitPoints: Int16?
        var manaPoints: Int16?
    }

    let mockItem = MockItem(
        id: UUID(uuidString: "6023cc65-b183-4d41-8742-f1ecb0172942")!,
        title: "Legendary Helmet",
        tier: 4,
        isUnique: true,
        strength: 20,
        agility: 10,
        power: 5,
        hitPoints: 50
    )

    return ItemCell(item: mockItem, isSelected: false)
        .background(Color.black)
}
