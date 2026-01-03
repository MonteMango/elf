//
//  WeaponConfiguration.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Represents the valid weapon configurations for an elf.
/// Using an enum ensures that only valid combinations are possible.
/// Note: There is no "empty" case - an elf must always have a weapon equipped.
public enum WeaponConfiguration: Sendable, Equatable {

    /// One-handed weapon in primary hand, secondary hand empty
    case oneHanded(weapon: ElfWeaponItem)

    /// One-handed weapon in primary hand, shield in secondary hand
    case oneHandedWithShield(weapon: ElfWeaponItem, shield: ElfShieldItem)

    /// Two-handed weapon (occupies both hands)
    case twoHanded(weapon: ElfWeaponItem)

    /// Dual-wielding: one-handed weapon in each hand
    case dualWield(primary: ElfWeaponItem, secondary: ElfWeaponItem)

    // MARK: - Computed Properties

    /// Returns the primary weapon (always present)
    public var weapon: ElfWeaponItem {
        switch self {
        case .oneHanded(let weapon),
             .oneHandedWithShield(let weapon, _),
             .twoHanded(let weapon),
             .dualWield(let weapon, _):
            return weapon
        }
    }

    /// Returns the shield if equipped
    public var shield: ElfShieldItem? {
        switch self {
        case .oneHandedWithShield(_, let shield):
            return shield
        default:
            return nil
        }
    }

    /// Returns the secondary weapon for dual-wield configuration
    public var secondaryWeapon: ElfWeaponItem? {
        switch self {
        case .dualWield(_, let secondary):
            return secondary
        default:
            return nil
        }
    }

    /// Returns all weapon IDs in this configuration
    public var allWeaponIds: [UUID] {
        switch self {
        case .oneHanded(let weapon),
             .twoHanded(let weapon):
            return [weapon.id]
        case .oneHandedWithShield(let weapon, _):
            return [weapon.id]
        case .dualWield(let primary, let secondary):
            return [primary.id, secondary.id]
        }
    }

    /// Returns all item IDs in this configuration (weapons + shield)
    public var allItemIds: Set<UUID> {
        switch self {
        case .oneHanded(let weapon),
             .twoHanded(let weapon):
            return [weapon.id]
        case .oneHandedWithShield(let weapon, let shield):
            return [weapon.id, shield.id]
        case .dualWield(let primary, let secondary):
            return [primary.id, secondary.id]
        }
    }

    /// Checks if the given item ID is part of this configuration
    public func contains(itemId: UUID) -> Bool {
        allItemIds.contains(itemId)
    }

    // MARK: - Equatable

    public static func == (lhs: WeaponConfiguration, rhs: WeaponConfiguration) -> Bool {
        switch (lhs, rhs) {
        case (.oneHanded(let lhsWeapon), .oneHanded(let rhsWeapon)):
            return lhsWeapon.id == rhsWeapon.id
        case (.oneHandedWithShield(let lhsWeapon, let lhsShield),
              .oneHandedWithShield(let rhsWeapon, let rhsShield)):
            return lhsWeapon.id == rhsWeapon.id && lhsShield.id == rhsShield.id
        case (.twoHanded(let lhsWeapon), .twoHanded(let rhsWeapon)):
            return lhsWeapon.id == rhsWeapon.id
        case (.dualWield(let lhsPrimary, let lhsSecondary),
              .dualWield(let rhsPrimary, let rhsSecondary)):
            return lhsPrimary.id == rhsPrimary.id && lhsSecondary.id == rhsSecondary.id
        default:
            return false
        }
    }
}
