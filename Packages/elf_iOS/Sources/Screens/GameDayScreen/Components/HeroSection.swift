//
//  HeroSection.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct HeroSection: View {
    let imageName: String
    let equippedItems: [HeroItemType: HeroEquippedSlot]
    let currentHP: Int
    let currentMP: Int
    let reputation: Int
    let onEquipmentSlotTapped: (HeroItemType) -> Void
    let onPocketTapped: (Int) -> Void

    private let bottomSectionHeight: CGFloat =
        ElfSizing.GameDay.jewelrySlotSize + ElfSpacing.medium + ElfSizing.GameDay.pocketSize

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ZStack(alignment: .bottom) {
            // Hero image centered, positioned above the bottom row
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: ElfSizing.GameDay.heroImageWidth,
                    height: ElfSizing.GameDay.heroImageHeight
                )
                .background { ElfColors.Image.placeholder }
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("HP \(currentHP), MP \(currentMP)")

                    Spacer()

                    // Reputation stats (top right)
                    IconValueLabel(icon: "crown.fill", value: reputation, color: ElfColors.primary)
                        .accessibilityLabel("Reputation \(reputation)")
                }

                HStack(alignment: .bottom, spacing: 0) {
                    // Left column: 4 equipment slots
                    VStack(alignment: .leading, spacing: ElfSpacing.grid) {
                        slotButton(for: .helmet)
                        slotButton(for: .gloves)
                        slotButton(for: .shoes)
                        slotButton(for: .weapons)
                    }

                    Spacer()

                    // Center: 3 jewelry slots (horizontal, centered)
                    HStack(alignment: .bottom, spacing: ElfSpacing.grid) {
                        slotButton(for: .ring)
                        slotButton(for: .necklace)
                        slotButton(for: .earrings)
                    }

                    Spacer()

                    // Right column: 4 equipment slots
                    VStack(alignment: .trailing, spacing: ElfSpacing.grid) {
                        slotButton(for: .upperBody)
                        slotButton(for: .bottomBody)
                        slotButton(for: .shirt)
                        slotButton(for: .shields)
                    }
                }

                // Pockets below all equipment
                PocketsView(onPocketTapped: onPocketTapped)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func slotButton(for itemType: HeroItemType) -> some View {
        EquipmentSlotButton(
            itemType: itemType,
            slot: equippedItems[itemType],
            onTap: { onEquipmentSlotTapped(itemType) }
        )
    }
}

// MARK: - EquipmentSlotButton

/// Single equipment slot. Extracted as a struct so SwiftUI can diff each slot
/// independently (each receives a different `itemType` + `slot` per call).
private struct EquipmentSlotButton: View {
    let itemType: HeroItemType
    let slot: HeroEquippedSlot?
    let onTap: () -> Void

    var body: some View {
        let isJewelry = itemType.isJewelry
        let slotSize = isJewelry ? ElfSizing.GameDay.jewelrySlotSize : ElfSizing.GameDay.equipmentSlotSize
        let iconSize = isJewelry ? ElfSizing.GameDay.jewelryIconSize : ElfSizing.GameDay.equipmentIconSize

        Button(action: onTap) {
            Rectangle()
                .fill(ElfColors.Interactive.slotBackground)
                .frame(width: slotSize, height: slotSize)
                .overlay {
                    Rectangle()
                        .stroke(ElfColors.Interactive.border, lineWidth: 1)
                }
                .overlay {
                    if let slot {
                        ItemIconImage(imageName: slot.imageName, size: iconSize)
                    }
                }
                .contentShape(Rectangle())
        }
        .accessibilityLabel("\(itemType.accessibilityLabel) slot")
        .accessibilityHint(slot == nil
            ? "Empty. Double tap to choose an item."
            : "Equipped. Double tap to change.")
    }
}

#if DEBUG
#Preview("Empty") {
    HeroSection(
        imageName: "Yuuki Asuna",
        equippedItems: [:],
        currentHP: 83,
        currentMP: 24,
        reputation: 148,
        onEquipmentSlotTapped: { _ in },
        onPocketTapped: { _ in }
    )
}

#Preview("Equipped") {
    HeroSection(
        imageName: "Yuuki Asuna",
        equippedItems: [
            .helmet: HeroEquippedSlot(id: UUID(), imageName: nil),
            .gloves: HeroEquippedSlot(id: UUID(), imageName: nil),
            .weapons: HeroEquippedSlot(id: UUID(), imageName: nil),
            .ring: HeroEquippedSlot(id: UUID(), imageName: nil),
            .necklace: HeroEquippedSlot(id: UUID(), imageName: nil),
            .upperBody: HeroEquippedSlot(id: UUID(), imageName: nil),
            .shields: HeroEquippedSlot(id: UUID(), imageName: nil)
        ],
        currentHP: 100,
        currentMP: 50,
        reputation: 256,
        onEquipmentSlotTapped: { _ in },
        onPocketTapped: { _ in }
    )
}
#endif
