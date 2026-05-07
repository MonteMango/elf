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
    let currentEP: Int
    let maxEP: Int
    let roundResults: [BodyPart: PointStatus]

    // MARK: - Body

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                hpBar
                epBar
            }

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
                instinct: snapshot.intuition,
                endurance: snapshot.endurance
            )
        }
    }

    // MARK: - Private Views

    private var hpBar: some View {
        // GeometryReader gives the fill an explicit width — corner radius
        // stays correct at low percentages (scaleEffect would distort it).
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.hpBarHeight / 2)
                    .fill(ElfColors.ProgressBar.background)

                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.hpBarHeight / 2)
                    .fill(ElfColors.ProgressBar.hp)
                    .frame(width: geometry.size.width * hpPercentage)

                Text("\(currentHP)/\(maxHP)")
                    .font(ElfFonts.Component.statValue)
                    .foregroundStyle(ElfColors.Text.primaryLight)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: ElfSizing.BattleFight.hpBarHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hit points")
        .accessibilityValue("\(currentHP) of \(maxHP)")
    }

    private var epBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.epBarHeight / 2)
                    .fill(ElfColors.ProgressBar.background)

                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.epBarHeight / 2)
                    .fill(ElfColors.ProgressBar.ep)
                    .frame(width: geometry.size.width * epPercentage)

                Text("\(currentEP)/\(maxEP)")
                    .font(ElfFonts.Component.statLabel)
                    .foregroundStyle(ElfColors.Text.primaryLight)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: ElfSizing.BattleFight.epBarHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Endurance points")
        .accessibilityValue("\(currentEP) of \(maxEP)")
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

            // Item image if equipped. Use the BASE item id (`item.id`) — the
            // asset catalog is keyed by the JSON-defined item UUID, not by
            // the wrapper's per-instance id (which can be a fresh UUID when
            // the wrapper was built via `init(defenseItem:)`/`init(weaponItem:)`).
            if let elfItem = item {
                itemImage(id: elfItem.item.id, size: ElfSizing.BattleFight.battleItemSize)
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

            // Item image if equipped — see `itemSlot` for why we use `item.id`.
            if let elfItem = item {
                itemImage(id: elfItem.item.id, size: ElfSizing.BattleFight.battleJewelrySize)
            }
        }
    }

    @ViewBuilder
    private func itemImage(id: UUID, size: CGFloat) -> some View {
        ItemIconImage(uuid: id, size: size, placeholderScale: 0.6)
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
        case .critHit(let weaponDamage, let strengthDamage, let defenderArmor, let multiplier, _):
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
        return min(max(0, CGFloat(currentHP) / CGFloat(maxHP)), 1)
    }

    private var epPercentage: CGFloat {
        guard maxEP > 0 else { return 0 }
        return min(max(0, CGFloat(currentEP) / CGFloat(maxEP)), 1)
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
        currentEP: 1400,
        maxEP: 2000,
        strength: 15,
        agility: 10,
        power: 12,
        intuition: 8,
        endurance: 0,
        attacks: [
            AttackProfile(minimumAttack: 5, maximumAttack: 10, epBlockCost: 200)
        ],
        defensePoints: 2,
        armorValues: [:]
    )

    let elfSnapshot = CombatantSnapshot(
        sourceId: UUID(),
        name: "Elara",
        imageName: "elf_warrior",
        combatantType: .elf,
        currentHP: 180,
        maxHP: 225,
        currentEP: 2000,
        maxEP: 2000,
        strength: 18,
        agility: 12,
        power: 14,
        intuition: 10,
        endurance: 0,
        attacks: [
            AttackProfile(minimumAttack: 8, maximumAttack: 15, epBlockCost: 200),
            AttackProfile(minimumAttack: 4, maximumAttack: 8, epBlockCost: 100)
        ],
        defensePoints: 3,
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
            currentEP: 1400,
            maxEP: 2000,
            roundResults: [
                .head: .blocked(wasCrit: false, epSpent: 200),
                .body: .hit(weaponDamage: 8, strengthDamage: 5, defenderArmor: 3),
                .leftHand: .nothing,
                .rightHand: .critHit(weaponDamage: 12, strengthDamage: 8, defenderArmor: 0, multiplier: 2.0, epSpent: 200),
                .legs: .dodged(wasCrit: false)
            ]
        )
        .frame(width: 150)

        HeroDisplayView(
            snapshot: elfSnapshot,
            currentHP: 180,
            maxHP: 225,
            currentEP: 2000,
            maxEP: 2000,
            roundResults: [
                .head: .hit(weaponDamage: 4, strengthDamage: 3, defenderArmor: 2),
                .body: .blocked(wasCrit: false, epSpent: 200),
                .leftHand: .dodged(wasCrit: true),
                .rightHand: .critHit(weaponDamage: 15, strengthDamage: 10, defenderArmor: 0, multiplier: 1.5, epSpent: 0),
                .legs: .nothing
            ]
        )
        .frame(width: 150)
    }
    .padding()
    .background(Color.white)
}
