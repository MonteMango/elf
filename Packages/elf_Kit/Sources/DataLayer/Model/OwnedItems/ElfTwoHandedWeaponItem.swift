//
//  ElfTwoHandedWeaponItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Wrapper around `ElfWeaponItem` with a compile-time guarantee that the underlying
/// weapon's `handUse` is `.both`. Used by `WeaponConfiguration.twoHanded` so that
/// a one-handed weapon can never appear in a two-handed slot.
public struct ElfTwoHandedWeaponItem: Sendable, Hashable {

    public let weapon: ElfWeaponItem

    public var id: UUID { weapon.id }

    /// Fails when the weapon cannot be resolved to `WeaponItem`, or when its `handUse` is `.oneHand`.
    public init?(weapon: ElfWeaponItem) {
        guard let weaponItem = weapon.item as? WeaponItem else { return nil }
        switch weaponItem.handUse {
        case .both:
            self.weapon = weapon
        case .oneHand:
            return nil
        }
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: ElfTwoHandedWeaponItem, rhs: ElfTwoHandedWeaponItem) -> Bool {
        lhs.weapon.id == rhs.weapon.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(weapon.id)
    }
}
