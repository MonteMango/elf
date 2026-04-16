//
//  HeroDisplayView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI
import UIKit

// MARK: - HeroDisplayView

struct HeroDisplayView: View {

    // MARK: - Properties

    let snapshot: CombatantSnapshot
    let currentHP: Int
    let maxHP: Int
    let roundResults: [BodyPart: PointStatus]

    // MARK: - Body

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 10) {
            // HP Bar
            hpBar

            // Hero Image with overlays
            ZStack {
                // Layer 1: Combatant image
                combatantImage

                // Layer 2: Items Grid Overlay (show if snapshot has equipment)
                if snapshot.hasEquipment {
                    itemsGridOverlay
                }

                // Layer 3: Result Dots Overlay (top layer)
                resultDotsOverlay
            }

            // Attributes
            elf_SwiftUI.AttributesCompactView(
                strength: snapshot.strength,
                agility: snapshot.agility,
                power: snapshot.power,
                instinct: snapshot.intuition
            )
        }
    }

    // MARK: - Private Views

    private var hpBar: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(ElfColors.ProgressBar.background)

            // Fill
            RoundedRectangle(cornerRadius: 12)
                .fill(ElfColors.ProgressBar.hp)
                .scaleEffect(x: hpPercentage, y: 1, anchor: .leading)

            // Text
            Text("\(currentHP)/\(maxHP)")
                .font(ElfFonts.Component.statValue)
                .foregroundStyle(ElfColors.Text.primaryLight)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: ElfSizing.BattleFight.hpBarHeight)
    }

    @ViewBuilder
    private var combatantImage: some View {
        if UIImage(named: snapshot.imageName) != nil {
            Image(snapshot.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        } else {
            // Fallback placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(maxWidth: .infinity)
                .overlay(
                    Text(snapshot.name)
                        .foregroundStyle(.white.opacity(0.5))
                )
        }
    }

    @ViewBuilder
    private var itemsGridOverlay: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let itemSize = ElfSizing.BattleFight.battleItemSize
            let jewelrySize = ElfSizing.BattleFight.battleJewelrySize
            let spacing: CGFloat = 4

            // Column positioning
            let leftColumnX: CGFloat = spacing
            let rightColumnX: CGFloat = width - itemSize - spacing

            ZStack {
                // LEFT column (4 items)
                VStack(spacing: spacing) {
                    itemSlot(item: snapshot.helmetItem)
                    itemSlot(item: snapshot.glovesItem)
                    itemSlot(item: snapshot.shoesItem)
                    itemSlot(item: snapshot.rightWeaponItem)
                }
                .position(x: leftColumnX + itemSize / 2, y: height / 2)

                // RIGHT column (4 items)
                VStack(spacing: spacing) {
                    itemSlot(item: snapshot.upperBodyItem ?? snapshot.robeItem)
                    itemSlot(item: snapshot.bottomBodyItem)
                    itemSlot(item: nil) // shirt placeholder
                    itemSlot(item: snapshot.shieldItem ?? snapshot.leftWeaponItem)
                }
                .position(x: rightColumnX + itemSize / 2, y: height / 2)

                // CENTER BOTTOM: Jewelry row (3 items)
                HStack(spacing: spacing) {
                    jewelrySlot(item: snapshot.ringItem)
                    jewelrySlot(item: snapshot.necklaceItem)
                    jewelrySlot(item: snapshot.earringsItem)
                }
                .position(x: width / 2, y: height - jewelrySize / 2 - spacing)
            }
        }
    }

    @ViewBuilder
    private func itemSlot(item: (any ElfItem)?) -> some View {
        ZStack {
            // Always show placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(ElfColors.Interactive.slotBackground)
                .frame(
                    width: ElfSizing.BattleFight.battleItemSize,
                    height: ElfSizing.BattleFight.battleItemSize
                )

            // Item image if equipped
            if let elfItem = item {
                itemImage(id: elfItem.id, size: ElfSizing.BattleFight.battleItemSize)
            }
        }
    }

    @ViewBuilder
    private func jewelrySlot(item: (any ElfItem)?) -> some View {
        ZStack {
            // Always show placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(ElfColors.Interactive.slotBackground)
                .frame(
                    width: ElfSizing.BattleFight.battleJewelrySize,
                    height: ElfSizing.BattleFight.battleJewelrySize
                )

            // Item image if equipped
            if let elfItem = item {
                itemImage(id: elfItem.id, size: ElfSizing.BattleFight.battleJewelrySize)
            }
        }
    }

    @ViewBuilder
    private func itemImage(id: UUID, size: CGFloat) -> some View {
        let imageName = id.uuidString.lowercased()

        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.6, height: size * 0.6)
                .foregroundStyle(.gray.opacity(0.5))
        }
    }

    @ViewBuilder
    private var resultDotsOverlay: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let offset: CGFloat = 30

            ZStack {
                // Top - Head
                if let status = roundResults[.head] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY - offset)
                }

                // Center - Body
                if let status = roundResults[.body] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY)
                }

                // Left - Left Hand
                if let status = roundResults[.leftHand] {
                    resultLabel(status: status)
                        .position(x: centerX - offset, y: centerY)
                }

                // Right - Right Hand
                if let status = roundResults[.rightHand] {
                    resultLabel(status: status)
                        .position(x: centerX + offset, y: centerY)
                }

                // Bottom - Legs
                if let status = roundResults[.legs] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY + offset)
                }
            }
        }
    }

    @ViewBuilder
    private func resultLabel(status: PointStatus) -> some View {
        if let text = statusText(for: status) {
            Text(text)
                .font(Font.system(size: 12, weight: .bold))
                .foregroundStyle(statusColor(for: status))
        }
    }

    private func statusText(for status: PointStatus) -> String? {
        switch status {
        case .dodged:
            return "dodge"
        case .hit(let weaponDamage, let strengthDamage, let defenderArmor):
            let damage = max(0, weaponDamage + strengthDamage - defenderArmor)
            return "\(damage)"
        case .critHit(let weaponDamage, let strengthDamage, let defenderArmor, let multiplier):
            let baseDamage = weaponDamage + strengthDamage - defenderArmor
            let damage = max(0, Int(Double(baseDamage) * multiplier))
            return "crit \(damage)"
        case .blocked:
            return "block"
        case .nothing:
            return nil
        }
    }

    private func statusColor(for status: PointStatus) -> Color {
        switch status {
        case .dodged:
            return ElfColors.Battle.dodged
        case .hit:
            return ElfColors.Battle.hit
        case .critHit:
            return ElfColors.Battle.critHit
        case .blocked:
            return ElfColors.Battle.blocked
        case .nothing:
            return ElfColors.Battle.nothing
        }
    }

    // MARK: - Computed Properties

    private var hpPercentage: CGFloat {
        guard maxHP > 0 else { return 0 }
        return CGFloat(currentHP) / CGFloat(maxHP)
    }
}

// MARK: - Preview

#Preview {
    let monsterSnapshot = CombatantSnapshot(
        sourceId: UUID(),
        name: "Goblin",
        imageName: "monster_goblin",
        combatantType: .monster,
        currentHP: 120,
        maxHP: 150,
        strength: 15,
        agility: 10,
        power: 12,
        intuition: 8,
        attackPoints: 1,
        defensePoints: 2,
        minimumAttack: 5,
        maximumAttack: 10,
        armorValues: [:]
    )

    let elfSnapshot = CombatantSnapshot(
        sourceId: UUID(),
        name: "Elara",
        imageName: "elf_warrior",
        combatantType: .elf,
        currentHP: 180,
        maxHP: 225,
        strength: 18,
        agility: 12,
        power: 14,
        intuition: 10,
        attackPoints: 2,
        defensePoints: 3,
        minimumAttack: 8,
        maximumAttack: 15,
        armorValues: [
            .head: 5,
            .body: 10,
            .leftHand: 3,
            .rightHand: 3,
            .legs: 7
        ]
    )

    return HStack(spacing: 30) {
        HeroDisplayView(
            snapshot: monsterSnapshot,
            currentHP: 120,
            maxHP: 150,
            roundResults: [
                .head: .blocked(wasCrit: false),
                .body: .hit(weaponDamage: 8, strengthDamage: 5, defenderArmor: 3),
                .leftHand: .nothing,
                .rightHand: .critHit(weaponDamage: 12, strengthDamage: 8, defenderArmor: 0, multiplier: 2.0),
                .legs: .dodged(wasCrit: false)
            ]
        )
        .frame(width: 150)

        HeroDisplayView(
            snapshot: elfSnapshot,
            currentHP: 180,
            maxHP: 225,
            roundResults: [
                .head: .hit(weaponDamage: 4, strengthDamage: 3, defenderArmor: 2),
                .body: .blocked(wasCrit: false),
                .leftHand: .dodged(wasCrit: true),
                .rightHand: .critHit(weaponDamage: 15, strengthDamage: 10, defenderArmor: 0, multiplier: 1.5),
                .legs: .nothing
            ]
        )
        .frame(width: 150)
    }
    .padding()
    .background(Color.white)
}
