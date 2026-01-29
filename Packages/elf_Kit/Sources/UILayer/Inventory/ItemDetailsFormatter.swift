//
//  ItemDetailsFormatter.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Formats item details into human-readable description lines for UI display
public struct ItemDetailsFormatter: Sendable {

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

    private func formatWeapon(_ details: WeaponDetails) -> [String] {
        var lines: [String] = []
        lines.append("Attack: \(details.attackMin)-\(details.attackMax)")
        lines.append("Attack points: \(details.attackPoints)")
        lines.append("Hands use: \(details.handUse)")
        lines.append("")
        appendAttributes(
            to: &lines,
            strength: details.strength, agility: details.agility,
            power: details.power, instinct: details.instinct,
            hitPoints: details.hitPoints
        )
        if let enchant = details.enchantLevel, enchant > 0 {
            lines.append("Enchant: +\(enchant)")
        }
        return lines
    }

    private func formatArmor(_ details: ArmorDetails) -> [String] {
        var lines: [String] = []
        lines.append("Defense: \(details.defense)")
        if !details.protectedParts.isEmpty {
            lines.append("Protects: \(details.protectedParts.joined(separator: ", "))")
        }
        lines.append("")
        appendAttributes(
            to: &lines,
            strength: details.strength, agility: details.agility,
            power: details.power, instinct: details.instinct,
            hitPoints: details.hitPoints
        )
        return lines
    }

    private func formatShield(_ details: ShieldDetails) -> [String] {
        var lines: [String] = []
        lines.append("Defense: \(details.defense)")
        lines.append("Block points: +\(details.blockPoints)")
        lines.append("")
        appendAttributes(
            to: &lines,
            strength: details.strength, agility: details.agility,
            hitPoints: details.hitPoints
        )
        return lines
    }

    private func formatJewelry(_ details: JewelryDetails) -> [String] {
        var lines: [String] = []
        if details.magicDefense > 0 { lines.append("Magic defense: \(details.magicDefense)") }
        lines.append("")
        appendAttributes(
            to: &lines,
            strength: details.strength, agility: details.agility,
            power: details.power, instinct: details.instinct,
            hitPoints: details.hitPoints, manaPoints: details.manaPoints
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

    private func formatMaterial(_ details: MaterialDetails) -> [String] {
        [details.description]
    }

    private func formatPotionScroll(_ details: PotionScrollDetails) -> [String] {
        var lines = [details.effect]
        if let dur = details.duration {
            lines.append("Duration: \(dur) turns")
        }
        return lines
    }
}
