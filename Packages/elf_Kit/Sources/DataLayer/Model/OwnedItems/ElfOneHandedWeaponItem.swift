//
//  ElfOneHandedWeaponItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Wrapper around `ElfWeaponItem` with a compile-time guarantee that the underlying
/// weapon's `handUse` is `.primary` or `.secondary`. Used by `WeaponConfiguration`
/// cases that represent single-hand weapon slots, making invalid combinations
/// (e.g. a two-handed weapon inside dual-wield) unrepresentable.
public struct ElfOneHandedWeaponItem: Sendable, Hashable {

    public let weapon: ElfWeaponItem

    public var id: UUID { weapon.id }

    /// Fails when the weapon cannot be resolved to `WeaponItem`, or when its `handUse` is `.both`.
    public init?(weapon: ElfWeaponItem) {
        guard let weaponItem = weapon.item as? WeaponItem else { return nil }
        switch weaponItem.handUse {
        case .primary, .secondary:
            self.weapon = weapon
        case .both:
            return nil
        }
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: ElfOneHandedWeaponItem, rhs: ElfOneHandedWeaponItem) -> Bool {
        lhs.weapon.id == rhs.weapon.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(weapon.id)
    }
}
