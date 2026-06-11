//
//  ConsoleDebugGameLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Console implementation of DebugGameLogger with category-based filtering
///
/// Outputs game state to console with emoji-tagged sections.
/// Pass an empty `categories` set to disable all output.
public final class ConsoleDebugGameLogger: DebugGameLogger {

    private let categories: Set<DebugGameLogCategory>

    /// Initialize logger with specific categories to log
    /// - Parameter categories: Set of categories to enable logging for
    public init(categories: Set<DebugGameLogCategory>) {
        self.categories = categories
    }

    public func logGameSave(game: Game, playTime: TimeInterval) {
        guard !categories.isEmpty else { return }

        let player = game.player
        let state = game.gameState

        print("\n💾 ========== GAME SAVE ==========")
        print("🎮 Game ID: \(game.id.rawValue.uuidString.prefix(8))... | Play Time: \(formatTime(playTime))")

        if categories.contains(.playerInfo) {
            logPlayerInfo(player)
        }

        if categories.contains(.gameState) {
            logGameState(state)
        }

        if categories.contains(.inventory) {
            logInventory(player.inventory)
        }

        if categories.contains(.equipment) {
            logEquipment(player.equipped)
        }

        if categories.contains(.houses) {
            logHouses(game.houses, playerHouseIndex: game.playerHouseIndex)
        }

        print("💾 ================================\n")
    }

    // MARK: - Player Info

    private func logPlayerInfo(_ player: ElfInfo) {
        print("\n👤 PLAYER (\(player.name)):")
        print("  📊 Exp: \(player.currentExp) | Fishing: \(player.fishingExp) | Foraging: \(player.foragingExp) | Mining: \(player.miningExp)")
        print("  ❤️ HP: \(player.maxHP)/\(player.maxHP) | 💙 MP: \(player.maxMP)/\(player.maxMP)")
        print("  ⭐ Reputation: \(player.reputation)")
    }

    // MARK: - Game State

    private func logGameState(_ state: GameState) {
        let currentDayNumber = state.currentDay.dayNumber
        let totalDays = state.calendar.count
        print("\n📅 GAME STATE:")
        print("  Day: \(currentDayNumber)/\(totalDays) | AP: \(state.currentActionPoints)/\(state.maxActionPoints)")
    }

    // MARK: - Inventory

    private func logInventory(_ inventory: ElfInventory) {
        let itemCount = inventory.weapons.count + inventory.shields.count
            + inventory.armor.count + inventory.robes.count + inventory.jewelry.count
        let materialCount = inventory.materials.reduce(0) { $0 + $1.quantity }

        print("\n🎒 INVENTORY (\(itemCount) items, \(materialCount) materials):")

        logWeapons(inventory.weapons)
        logShields(inventory.shields)
        logArmor(inventory.armor)
        logRobes(inventory.robes)
        logJewelry(inventory.jewelry)
        logMaterials(inventory.materials)
    }

    private func logWeapons(_ weapons: [ElfWeaponItem]) {
        print("  ⚔️ Weapons (\(weapons.count)):")
        for weapon in weapons {
            let enchant = weapon.enchantLevel > 0 ? " enchant:+\(weapon.enchantLevel)" : ""
            if let w = weapon.item as? WeaponItem {
                print("    - \(w.title) [T\(w.tier)] id:\(shortId(weapon.id.rawValue)) atk:\(w.minimumAttackPoint)-\(w.maximumAttackPoint)\(enchant)")
            } else {
                print("    - Unknown [id:\(shortId(weapon.id.rawValue))]\(enchant)")
            }
        }
    }

    private func logShields(_ shields: [ElfShieldItem]) {
        print("  🛡️ Shields (\(shields.count)):")
        for shield in shields {
            if let s = shield.item as? ShieldItem {
                print("    - \(s.title) [T\(s.tier)] id:\(shortId(shield.id.rawValue)) def:\(s.physicalDefensePoint)")
            } else {
                print("    - Unknown [id:\(shortId(shield.id.rawValue))]")
            }
        }
    }

    private func logArmor(_ armor: [ElfDefenseItem]) {
        print("  🧥 Armor (\(armor.count)):")
        for piece in armor {
            if let d = piece.item as? DefenseItem {
                let parts = d.protectParts.map { $0.rawValue }.joined(separator: ",")
                print("    - \(d.title) [T\(d.tier)] id:\(shortId(piece.id.rawValue)) def:\(d.physicalDefensePoint) parts:[\(parts)]")
            } else {
                print("    - Unknown [id:\(shortId(piece.id.rawValue))]")
            }
        }
    }

    private func logRobes(_ robes: [ElfRobeItem]) {
        print("  👗 Robes (\(robes.count)):")
        for robe in robes {
            print("    - \(robe.item.title) [T\(robe.item.tier)] id:\(shortId(robe.id.rawValue))")
        }
    }

    private func logJewelry(_ jewelry: [ElfJewelryItem]) {
        print("  💍 Jewelry (\(jewelry.count)):")
        for piece in jewelry {
            if let j = piece.item as? JewelryItem {
                print("    - \(j.title) [T\(j.tier)] id:\(shortId(piece.id.rawValue)) mdef:\(j.magicalDefensePoint)")
            } else {
                print("    - Unknown [id:\(shortId(piece.id.rawValue))]")
            }
        }
    }

    private func logMaterials(_ materials: [InventoryMaterial]) {
        print("  📦 Materials (\(materials.count) types):")
        for material in materials {
            print("    - id:\(shortId(material.ref.rawValue)) x\(material.quantity)")
        }
    }

    // MARK: - Equipment

    private func logEquipment(_ equipped: EquippedItems) {
        print("\n⚔️ EQUIPMENT:")

        // Weapon configuration
        switch equipped.weapons {
        case .oneHanded(let weapon):
            print("  Weapon: \(formatItem(weapon.weapon)) (one-handed)")
        case .oneHandedWithShield(let weapon, let shield):
            print("  Weapon: \(formatItem(weapon.weapon)) (one-handed + shield)")
            print("  Shield: \(formatItem(shield))")
        case .twoHanded(let weapon):
            print("  Weapon: \(formatItem(weapon.weapon)) (two-handed)")
        case .dualWield(let primary, let secondary):
            print("  Weapon L: \(formatItem(primary.weapon)) (dual wield)")
            print("  Weapon R: \(formatItem(secondary.weapon))")
        }

        print("  Helmet: \(formatSlot(equipped.helmet))")
        print("  Upper Body: \(formatSlot(equipped.upperBody))")
        print("  Bottom Body: \(formatSlot(equipped.bottomBody))")
        print("  Shoes: \(formatSlot(equipped.shoes))")
        print("  Gloves: \(formatSlot(equipped.gloves))")
        print("  Shirt: \(formatSlot(equipped.shirt))")
        print("  Ring: \(formatSlot(equipped.ring))")
        print("  Necklace: \(formatSlot(equipped.necklace))")
        print("  Earrings: \(formatSlot(equipped.earrings))")
    }

    // MARK: - Houses

    private func logHouses(_ houses: [House], playerHouseIndex: Int) {
        print("\n🏠 HOUSES (\(houses.count)):")
        let parts = houses.enumerated().map { index, house in
            let prefix = index == playerHouseIndex ? "⭐ " : ""
            let suffix = house.isEliminated ? " ❌" : ""
            return "\(prefix)\(house.name)\(suffix)"
        }
        print("  \(parts.joined(separator: " | "))")
    }

    // MARK: - Formatting Helpers

    private func formatItem(_ weapon: ElfWeaponItem) -> String {
        let enchant = weapon.enchantLevel > 0 ? " +\(weapon.enchantLevel)" : ""
        return "\(weapon.item.title) [T\(weapon.item.tier)]\(enchant)"
    }

    private func formatItem(_ shield: ElfShieldItem) -> String {
        "\(shield.item.title) [T\(shield.item.tier)]"
    }

    private func formatSlot(_ item: ElfDefenseItem?) -> String {
        guard let item else { return "—" }
        return "\(item.item.title) [T\(item.item.tier)]"
    }

    private func formatSlot(_ item: ElfRobeItem?) -> String {
        guard let item else { return "—" }
        return "\(item.item.title) [T\(item.item.tier)]"
    }

    private func formatSlot(_ item: ElfJewelryItem?) -> String {
        guard let item else { return "—" }
        return "\(item.item.title) [T\(item.item.tier)]"
    }

    private func shortId(_ id: UUID) -> String {
        String(id.uuidString.prefix(8)).lowercased()
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
