//
//  ItemAttributesFormatter.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Formats item details into human-readable description lines for UI display
public struct ItemAttributesFormatter: Sendable {

    public init() {}

    /// Returns formatted description lines for the given item details
    public func descriptionLines(for details: ItemDetails) -> [String] {
        switch details {
        case .weapon(let d):
            formatWeapon(d)
        case .armor(let d):
            formatArmor(d)
        case .shield(let d):
            formatShield(d)
        case .jewelry(let d):
            formatJewelry(d)
        case .material(let d):
            formatMaterial(d)
        case .potionScroll(let d):
            formatPotionScroll(d)
        }
    }

    // MARK: - Private Formatters

    private func formatWeapon(_ attributes: WeaponAttributes) -> [String] {
        var lines: [String] = []
        lines.append("Attack: \(attributes.attackMin)-\(attributes.attackMax)")
        lines.append("Attack points: \(attributes.attackPoints)")
        lines.append("Hands use: \(attributes.handUse)")
        lines.append("")
        appendAttributes(
            to: &lines,
            strength: attributes.strength, agility: attributes.agility,
            power: attributes.power, instinct: attributes.instinct,
            hitPoints: attributes.hitPoints
        )
        if let enchant = attributes.enchantLevel, enchant > 0 {
            lines.append("Enchant: +\(enchant)")
        }
        return lines
    }

    private func formatArmor(_ attributes: ArmorAttributes) -> [String] {
        var lines: [String] = []
        lines.append("Defense: \(attributes.defense)")
        if !attributes.protectedParts.isEmpty {
            lines.append("Protects: \(attributes.protectedParts.joined(separator: ", "))")
        }
        lines.append("")
        appendAttributes(
            to: &lines,
            strength: attributes.strength, agility: attributes.agility,
            power: attributes.power, instinct: attributes.instinct,
            hitPoints: attributes.hitPoints
        )
        return lines
    }

    private func formatShield(_ attributes: ShieldAttributes) -> [String] {
        var lines: [String] = []
        lines.append("Defense: \(attributes.defense)")
        lines.append("Block points: +\(attributes.blockPoints)")
        lines.append("")
        appendAttributes(
            to: &lines,
            strength: attributes.strength, agility: attributes.agility,
            hitPoints: attributes.hitPoints
        )
        return lines
    }

    private func formatJewelry(_ attributes: JewelryAttributes) -> [String] {
        var lines: [String] = []
        if attributes.magicDefense > 0 { lines.append("Magic defense: \(attributes.magicDefense)") }
        lines.append("")
        appendAttributes(
            to: &lines,
            strength: attributes.strength, agility: attributes.agility,
            power: attributes.power, instinct: attributes.instinct,
            hitPoints: attributes.hitPoints, manaPoints: attributes.manaPoints
        )
        return lines
    }

    private func appendAttributes(
        to lines: inout [String],
        strength: Int = 0, agility: Int = 0,
        power: Int = 0, instinct: Int = 0,
        hitPoints: Int = 0, manaPoints: Int = 0
    ) {
        if strength > 0 { lines.append("Strength: \(strength)") }
        if agility > 0 { lines.append("Agility: \(agility)") }
        if power > 0 { lines.append("Power: \(power)") }
        if instinct > 0 { lines.append("Instinct: \(instinct)") }
        if hitPoints > 0 { lines.append("HP: \(hitPoints)") }
        if manaPoints > 0 { lines.append("MP: \(manaPoints)") }
    }

    private func formatMaterial(_ attributes: MaterialAttributes) -> [String] {
        [attributes.description]
    }

    private func formatPotionScroll(_ attributes: PotionScrollAttributes) -> [String] {
        var lines = [attributes.effect]
        if let dur = attributes.duration {
            lines.append("Duration: \(dur) turns")
        }
        return lines
    }
}
