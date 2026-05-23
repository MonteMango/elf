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

    private func slotButton(for itemType: HeroItemType) -> some View {
        let slot = equippedItems[itemType]
        // Mirrored slots are a visual reflection of an item that lives in
        // another slot; route the tap to the source slot type.
        let tapTarget = slot?.mirroredFrom ?? itemType
        return EquipmentSlotButton(
            itemType: itemType,
            slot: slot,
            onTap: { onEquipmentSlotTapped(tapTarget) }
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
            EquipmentSlotView(
                item: slot?.slotContent,
                slotSize: slotSize,
                iconSize: iconSize
            )
        }
        .accessibilityLabel(accessibilityLabel(for: slot))
        .accessibilityHint(accessibilityHint(for: slot))
    }

    private func accessibilityLabel(for slot: HeroEquippedSlot?) -> String {
        guard let mirroredFrom = slot?.mirroredFrom else {
            return "\(itemType.accessibilityLabel) slot"
        }
        return "\(itemType.accessibilityLabel) slot, mirroring \(mirroredFrom.accessibilityLabel)"
    }

    private func accessibilityHint(for slot: HeroEquippedSlot?) -> String {
        guard let slot else { return "Empty. Double tap to choose an item." }
        return slot.isMirror
            ? "Double tap to change the source item."
            : "Equipped. Double tap to change."
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

#Preview("Two-Handed Weapon") {
    let weaponId = UUID()
    return HeroSection(
        imageName: "Yuuki Asuna",
        equippedItems: [
            .weapons: HeroEquippedSlot(id: weaponId, imageName: nil),
            .shields: HeroEquippedSlot(id: weaponId, imageName: nil, mirroredFrom: .weapons)
        ],
        currentHP: 100,
        currentMP: 50,
        reputation: 256,
        onEquipmentSlotTapped: { _ in },
        onPocketTapped: { _ in }
    )
}
#endif
