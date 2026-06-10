//
//  WeaponConfiguration.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Represents the valid weapon configurations for an elf.
///
/// The enum — combined with wrapper types `ElfOneHandedWeaponItem` and
/// `ElfTwoHandedWeaponItem` — makes invalid combinations unrepresentable at compile time:
/// a two-handed weapon cannot appear in a one-hand slot and vice versa.
/// There is no "empty" case — an elf must always have a weapon equipped.
public enum WeaponConfiguration: Sendable, Equatable {

    /// One-handed weapon in primary hand, secondary hand empty.
    case oneHanded(weapon: ElfOneHandedWeaponItem)

    /// One-handed weapon in primary hand, shield in secondary hand.
    case oneHandedWithShield(weapon: ElfOneHandedWeaponItem, shield: ElfShieldItem)

    /// Two-handed weapon (occupies both hands).
    case twoHanded(weapon: ElfTwoHandedWeaponItem)

    /// Dual-wielding: one-handed weapon in each hand.
    case dualWield(primary: ElfOneHandedWeaponItem, secondary: ElfOneHandedWeaponItem)

    // MARK: - Computed Properties

    /// Returns the primary weapon as a raw `ElfWeaponItem` (always present).
    public var weapon: ElfWeaponItem {
        switch self {
        case .oneHanded(let wrapper),
             .oneHandedWithShield(let wrapper, _),
             .dualWield(let wrapper, _):
            return wrapper.weapon
        case .twoHanded(let wrapper):
            return wrapper.weapon
        }
    }

    /// Returns the shield if equipped.
    public var shield: ElfShieldItem? {
        if case .oneHandedWithShield(_, let shield) = self { return shield }
        return nil
    }

    /// Returns the off-hand weapon when dual-wielding, otherwise nil.
    public var secondaryWeapon: ElfWeaponItem? {
        if case .dualWield(_, let secondary) = self { return secondary.weapon }
        return nil
    }

    // MARK: - Equatable

    public static func == (lhs: WeaponConfiguration, rhs: WeaponConfiguration) -> Bool {
        switch (lhs, rhs) {
        case (.oneHanded(let lhsWeapon), .oneHanded(let rhsWeapon)):
            return lhsWeapon == rhsWeapon
        case (.oneHandedWithShield(let lhsWeapon, let lhsShield),
              .oneHandedWithShield(let rhsWeapon, let rhsShield)):
            return lhsWeapon == rhsWeapon && lhsShield.id == rhsShield.id
        case (.twoHanded(let lhsWeapon), .twoHanded(let rhsWeapon)):
            return lhsWeapon == rhsWeapon
        case (.dualWield(let lhsPrimary, let lhsSecondary),
              .dualWield(let rhsPrimary, let rhsSecondary)):
            return lhsPrimary == rhsPrimary && lhsSecondary == rhsSecondary
        default:
            return false
        }
    }
}
