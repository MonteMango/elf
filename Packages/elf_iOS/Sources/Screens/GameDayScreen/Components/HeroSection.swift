//
//  HeroSection.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI
import UIKit

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
                    width: ElfSizing.GameDay.heroImageWidth,
                    height: ElfSizing.GameDay.heroImageHeight
                )
                .background { ElfColors.Text.secondary }
                .padding(.bottom, bottomSectionHeight + ElfSpacing.grid)

            // Bottom row with equipment slots + pockets below
            VStack(alignment: .center, spacing: ElfSpacing.medium) {
                // Equipment row (left, jewelry, right - all bottom aligned)
                HStack(spacing: 0) {
                    // HP and MP stats (top left)
                    HStack(spacing: ElfSpacing.xxs) {
                        IconValueLabel(icon: "heart.fill", value: currentHP, color: ElfColors.ProgressBar.hp)
                        IconValueLabel(icon: "sparkles", value: currentMP, color: ElfColors.ProgressBar.mp)
                    }

                    Spacer()

                    // Reputation stats (top right)
                    IconValueLabel(icon: "crown.fill", value: reputation, color: ElfColors.primary)
                }

                HStack(alignment: .bottom, spacing: 0) {
                    // Left column: 4 equipment slots
                    VStack(alignment: .leading, spacing: ElfSpacing.grid) {
                        equipmentSlot(for: .helmet)
                        equipmentSlot(for: .gloves)
                        equipmentSlot(for: .shoes)
                        equipmentSlot(for: .weapons)
                    }

                    Spacer()

                    // Center: 3 jewelry slots (horizontal, centered)
                    HStack(alignment: .bottom, spacing: ElfSpacing.grid) {
                        equipmentSlot(for: .ring)
                        equipmentSlot(for: .necklace)
                        equipmentSlot(for: .earrings)
                    }

                    Spacer()

                    // Right column: 4 equipment slots
                    VStack(alignment: .trailing, spacing: ElfSpacing.grid) {
                        equipmentSlot(for: .upperBody)
                        equipmentSlot(for: .bottomBody)
                        equipmentSlot(for: .shirt)
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
        jewelrySlotSize + ElfSpacing.medium + ElfSizing.GameDay.pocketSize
    }

    private var sideSpacing: CGFloat {
        40
    }

    private var jewelryTypes: Set<HeroItemType> {
        [.ring, .necklace, .earrings]
    }

    // MARK: - Subviews

    @ViewBuilder
    private func equipmentSlot(for itemType: HeroItemType) -> some View {
        let isJewelry = jewelryTypes.contains(itemType)
        let slotSize = isJewelry ? jewelrySlotSize : ElfSizing.GameDay.equipmentSlotSize
        let iconSize = isJewelry ? jewelryIconSize : ElfSizing.GameDay.equipmentIconSize

        Button {
            onEquipmentSlotTapped(itemType)
        } label: {
            ZStack {
                // No corner radius - Rectangle instead of RoundedRectangle
                Rectangle()
                    .fill(ElfColors.Interactive.slotBackground)
                    .frame(width: slotSize, height: slotSize)
                    .overlay(
                        Rectangle()
                            .stroke(ElfColors.Interactive.border, lineWidth: 1)
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
                .foregroundStyle(.gray.opacity(0.5))
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
