//
//  ElfEquipmentQueryService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default implementation of equipment query service
///
/// Provides stateless query methods for equipment data.
public final class ElfEquipmentQueryService: EquipmentQueryService {

    // MARK: - Initialization

    public init() {}

    // MARK: - Item Checks

    public func isItemEquipped(_ itemId: UUID, in equipped: EquippedItems) async -> Bool {
        allItemIds(from: equipped.weapons).contains(itemId)
            || equipped.helmet?.id == itemId
            || equipped.gloves?.id == itemId
            || equipped.shoes?.id == itemId
            || equipped.upperBody?.id == itemId
            || equipped.bottomBody?.id == itemId
            || equipped.shirt?.id == itemId
            || equipped.ring?.id == itemId
            || equipped.necklace?.id == itemId
            || equipped.earrings?.id == itemId
    }

    // MARK: - Slot Queries

    public func equippedItemId(for slot: HeroItemType, in equipped: EquippedItems) async -> UUID? {
        switch slot {
        case .weapons: return equipped.weapons.weapon.id
        case .shields: return equipped.weapons.shield?.id
        case .helmet: return equipped.helmet?.id
        case .gloves: return equipped.gloves?.id
        case .shoes: return equipped.shoes?.id
        case .upperBody: return equipped.upperBody?.id
        case .bottomBody: return equipped.bottomBody?.id
        case .shirt: return equipped.shirt?.id
        case .ring: return equipped.ring?.id
        case .necklace: return equipped.necklace?.id
        case .earrings: return equipped.earrings?.id
        }
    }

    public func equippedBaseItemIds(from equipped: EquippedItems) async -> [HeroItemType: UUID] {
        var result: [HeroItemType: UUID] = [:]
        result[.weapons] = equipped.weapons.weapon.item.id
        if let shield = equipped.weapons.shield { result[.shields] = shield.item.id }
        if let helmet = equipped.helmet { result[.helmet] = helmet.item.id }
        if let gloves = equipped.gloves { result[.gloves] = gloves.item.id }
        if let shoes = equipped.shoes { result[.shoes] = shoes.item.id }
        if let upperBody = equipped.upperBody { result[.upperBody] = upperBody.item.id }
        if let bottomBody = equipped.bottomBody { result[.bottomBody] = bottomBody.item.id }
        if let shirt = equipped.shirt { result[.shirt] = shirt.item.id }
        if let ring = equipped.ring { result[.ring] = ring.item.id }
        if let necklace = equipped.necklace { result[.necklace] = necklace.item.id }
        if let earrings = equipped.earrings { result[.earrings] = earrings.item.id }
        return result
    }

    // MARK: - Weapon Configuration Queries (private helpers)

    private func allItemIds(from weapons: WeaponConfiguration) -> Set<UUID> {
        switch weapons {
        case .oneHanded(let weapon),
             .twoHanded(let weapon):
            return [weapon.id]
        case .oneHandedWithShield(let weapon, let shield):
            return [weapon.id, shield.id]
        case .dualWield(let primary, let secondary):
            return [primary.id, secondary.id]
        }
    }
}
