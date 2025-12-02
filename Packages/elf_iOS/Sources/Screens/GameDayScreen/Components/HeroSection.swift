//
//  HeroSection.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI
import UIKit
import elf_Kit

struct HeroSection: View {
    let imageName: String
    let equippedItems: [HeroItemType: UUID]
    let currentHP: Int
    let maxHP: Int
    let currentMP: Int
    let maxMP: Int
    let reputation: Int
    let onEquipmentSlotTapped: (HeroItemType) -> Void
    let onPocketTapped: (Int) -> Void

    private let maxHeroSectionWidth: CGFloat = 350

    var body: some View {
        ZStack(alignment: .bottom) {
            // Hero image centered, positioned above the bottom row
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: GameDayConstants.Sizing.heroImageWidth,
                    height: GameDayConstants.Sizing.heroImageHeight
                )
                .background { Color.gray }
                .padding(.bottom, bottomSectionHeight + GameDayConstants.Spacing.gridSpacing)

            // Bottom row with equipment slots + pockets below
            VStack(alignment: .center, spacing: 10) {
                // Equipment row (left, jewelry, right - all bottom aligned)
                HStack(spacing: 0) {
                    // HP and MP stats (top left)
                    HStack(spacing: 4) {
                        statsLabel(icon: "heart.fill", value: currentHP, color: GameDayConstants.Colors.hpBarFill)
                        statsLabel(icon: "sparkles", value: currentMP, color: GameDayConstants.Colors.mpBarFill)
                    }

                    Spacer()

                    // Reputation stats (top right)
                    statsLabel(icon: "crown.fill", value: reputation, color: .orange)
                }
                
                HStack(alignment: .bottom, spacing: 0) {
                    // Left column: 4 equipment slots
                    VStack(alignment: .leading, spacing: GameDayConstants.Spacing.gridSpacing) {
                        equipmentSlot(for: .helmet)
                        equipmentSlot(for: .upperBody)
                        equipmentSlot(for: .bottomBody)
                        equipmentSlot(for: .shoes)
                    }
                    
                    Spacer()

                    // Center: 3 jewelry slots (horizontal, centered)
                    HStack(alignment: .bottom, spacing: GameDayConstants.Spacing.gridSpacing) {
                        equipmentSlot(for: .ring)
                        equipmentSlot(for: .necklace)
                        equipmentSlot(for: .earrings)
                    }
                    
                    Spacer()

                    // Right column: 4 equipment slots
                    VStack(alignment: .trailing, spacing: GameDayConstants.Spacing.gridSpacing) {
                        equipmentSlot(for: .gloves)
                        equipmentSlot(for: .shirt)
                        equipmentSlot(for: .weapons)
                        equipmentSlot(for: .shields)
                    }
                }

                // Pockets below all equipment
                PocketsView(onPocketTapped: onPocketTapped)
            }

        }
    }

    private let jewelrySlotSize: CGFloat = 30
    private let jewelryIconSize: CGFloat = 22

    private var bottomSectionHeight: CGFloat {
        // jewelry + spacing (10) + pockets
        jewelrySlotSize + 10 + GameDayConstants.Sizing.pocketSize
    }

    private var sideSpacing: CGFloat {
        40
    }

    private var jewelryTypes: Set<HeroItemType> {
        [.ring, .necklace, .earrings]
    }

    // MARK: - Subviews

    @ViewBuilder
    private func statsLabel(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
        }
    }

    @ViewBuilder
    private func equipmentSlot(for itemType: HeroItemType) -> some View {
        let isJewelry = jewelryTypes.contains(itemType)
        let slotSize = isJewelry ? jewelrySlotSize : GameDayConstants.Sizing.equipmentSlotSize
        let iconSize = isJewelry ? jewelryIconSize : GameDayConstants.Sizing.equipmentIconSize

        Button {
            onEquipmentSlotTapped(itemType)
        } label: {
            ZStack {
                // No corner radius - Rectangle instead of RoundedRectangle
                Rectangle()
                    .fill(GameDayConstants.Colors.equipmentSlotBackground)
                    .frame(width: slotSize, height: slotSize)
                    .overlay(
                        Rectangle()
                            .stroke(GameDayConstants.Colors.equipmentSlotBorder, lineWidth: 1)
                    )

                if let itemId = equippedItems[itemType] {
                    itemImage(uuid: itemId, iconSize: iconSize)
                }
            }
        }
    }

    @ViewBuilder
    private func itemImage(uuid: UUID, iconSize: CGFloat) -> some View {
        let imageName = uuid.uuidString.lowercased()

        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        } else {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.gray.opacity(0.5))
        }
    }
}

#Preview {
    HeroSection(
        imageName: "Yuuki Asuna",
        equippedItems: [:],
        currentHP: 83,
        maxHP: 100,
        currentMP: 24,
        maxMP: 50,
        reputation: 148,
        onEquipmentSlotTapped: { _ in },
        onPocketTapped: { _ in }
    )
}
