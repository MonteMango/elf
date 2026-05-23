//
//  CombatantBodyView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI
import UIKit

/// Portrait + 3-column equipment overlay used by `HeroDisplayView` (battle)
/// and by `SquadElfCell` (dungeon squad brief). HP/EP bars, attributes, and
/// per-round result dots live on the outer caller — this view is purely the
/// combatant's silhouette with its equipped items laid over it.
///
/// `equippedItems` is the same shared display DTO consumed by `HeroSection`:
/// the resolver populates the off-hand slot with a mirrored entry when the
/// combatant wields a two-handed weapon, so this view simply renders whatever
/// is under each `HeroItemType` key and lets `EquipmentSlotView` dim mirrors.
struct CombatantBodyView: View {

    // MARK: - Properties

    let imageName: String
    let equippedItems: [HeroItemType: HeroEquippedSlot]

    // MARK: - Body

    var body: some View {
        ZStack {
            combatantImage
            if !equippedItems.isEmpty {
                itemsGridOverlay
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var combatantImage: some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        } else {
            Rectangle()
                .fill(ElfColors.Image.placeholderTint)
                .frame(maxWidth: .infinity)
                .overlay(
                    Text(imageName)
                        .foregroundStyle(ElfColors.Text.placeholderOnDark)
                )
        }
    }

    private var itemsGridOverlay: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let itemSize = ElfSizing.BattleFight.battleItemSize
            let jewelrySize = ElfSizing.BattleFight.battleJewelrySize
            let spacing: CGFloat = ElfSpacing.xxs

            let leftColumnX: CGFloat = spacing
            let rightColumnX: CGFloat = width - itemSize - spacing

            ZStack {
                // LEFT column (4 items)
                VStack(spacing: spacing) {
                    itemSlot(for: .helmet)
                    itemSlot(for: .gloves)
                    itemSlot(for: .shoes)
                    itemSlot(for: .weapons)
                }
                .position(x: leftColumnX + itemSize / 2, y: height / 2)

                // RIGHT column (4 items)
                VStack(spacing: spacing) {
                    itemSlot(for: .upperBody)
                    itemSlot(for: .bottomBody)
                    itemSlot(for: .shirt)
                    itemSlot(for: .shields)
                }
                .position(x: rightColumnX + itemSize / 2, y: height / 2)

                // CENTER BOTTOM: Jewelry row (3 items)
                HStack(spacing: spacing) {
                    jewelrySlot(for: .ring)
                    jewelrySlot(for: .necklace)
                    jewelrySlot(for: .earrings)
                }
                .position(x: width / 2, y: height - jewelrySize / 2 - spacing)
            }
        }
    }

    private func itemSlot(for type: HeroItemType) -> some View {
        EquipmentSlotView(
            item: equippedItems[type]?.slotContent,
            slotSize: ElfSizing.BattleFight.battleItemSize,
            showBorder: false,
            placeholderScale: 0.6
        )
    }

    private func jewelrySlot(for type: HeroItemType) -> some View {
        EquipmentSlotView(
            item: equippedItems[type]?.slotContent,
            slotSize: ElfSizing.BattleFight.battleJewelrySize,
            showBorder: false,
            placeholderScale: 0.6
        )
    }
}
