//
//  EquippedItemsSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Default Weapon Constants

/// Default weapon ID (Recruit's Spear) used when no weapon is available
private let defaultWeaponId = UUID(uuidString: "dfbd2742-5470-4f97-84ea-fb17b5f3a6d2")!

/// Creates the default weapon configuration using the repository
private func createDefaultWeaponConfig(using repository: ItemsRepository) -> WeaponConfiguration {
    guard let weaponItem = repository.getHeroItem(defaultWeaponId) as? WeaponItem else {
        fatalError("Default weapon (Recruit's Spear) not found in repository")
    }
    let defaultWeapon = ElfWeaponItem(weaponItem: weaponItem)
    guard let twoHanded = ElfTwoHandedWeaponItem(weapon: defaultWeapon) else {
        fatalError("Default weapon (Recruit's Spear) must be two-handed")
    }
    return .twoHanded(weapon: twoHanded)
}

// MARK: - WeaponConfigSaveData

/// Persistence DTO for WeaponConfiguration enum.
public struct WeaponConfigSaveData: Codable, Sendable, Equatable {

    public enum ConfigType: String, Codable, Sendable {
        // Note: `empty` is kept for backwards compatibility with old saves
        // When loading, it will be converted to default weapon
        case empty
        case oneHanded
        case oneHandedWithShield
        case twoHanded
        case dualWield
    }

    public let type: ConfigType
    public let weapon: WeaponSaveData?
    public let shield: ShieldSaveData?
    public let secondaryWeapon: WeaponSaveData?

    /// Create from WeaponConfiguration
    public init(from config: WeaponConfiguration) {
        switch config {
        case .oneHanded(let weapon):
            self.type = .oneHanded
            self.weapon = WeaponSaveData(from: weapon.weapon)
            self.shield = nil
            self.secondaryWeapon = nil

        case .oneHandedWithShield(let weapon, let shield):
            self.type = .oneHandedWithShield
            self.weapon = WeaponSaveData(from: weapon.weapon)
            self.shield = ShieldSaveData(from: shield)
            self.secondaryWeapon = nil

        case .twoHanded(let weapon):
            self.type = .twoHanded
            self.weapon = WeaponSaveData(from: weapon.weapon)
            self.shield = nil
            self.secondaryWeapon = nil

        case .dualWield(let primary, let secondary):
            self.type = .dualWield
            self.weapon = WeaponSaveData(from: primary.weapon)
            self.shield = nil
            self.secondaryWeapon = WeaponSaveData(from: secondary.weapon)
        }
    }

    /// Convert to WeaponConfiguration using items repository.
    /// If the persisted data is stale (missing weapon, wrong handUse for the declared slot), falls back
    /// to the default weapon configuration — same behaviour as before the type-safe refactor, so no
    /// save migration is needed; invalid states from older saves are silently corrected on load.
    public func toWeaponConfiguration(using repository: ItemsRepository) -> WeaponConfiguration {
        switch type {
        case .empty:
            return createDefaultWeaponConfig(using: repository)

        case .oneHanded:
            guard let weaponData = weapon,
                  let weapon = weaponData.toElfWeaponItem(using: repository),
                  let oneHanded = ElfOneHandedWeaponItem(weapon: weapon) else {
                return createDefaultWeaponConfig(using: repository)
            }
            return .oneHanded(weapon: oneHanded)

        case .oneHandedWithShield:
            guard let weaponData = weapon,
                  let weapon = weaponData.toElfWeaponItem(using: repository),
                  let oneHanded = ElfOneHandedWeaponItem(weapon: weapon),
                  let shieldData = shield,
                  let shield = shieldData.toElfShieldItem(using: repository) else {
                return createDefaultWeaponConfig(using: repository)
            }
            return .oneHandedWithShield(weapon: oneHanded, shield: shield)

        case .twoHanded:
            guard let weaponData = weapon,
                  let weapon = weaponData.toElfWeaponItem(using: repository),
                  let twoHanded = ElfTwoHandedWeaponItem(weapon: weapon) else {
                return createDefaultWeaponConfig(using: repository)
            }
            return .twoHanded(weapon: twoHanded)

        case .dualWield:
            guard let primaryData = weapon,
                  let primary = primaryData.toElfWeaponItem(using: repository),
                  let primaryOneHanded = ElfOneHandedWeaponItem(weapon: primary),
                  let secondaryData = secondaryWeapon,
                  let secondary = secondaryData.toElfWeaponItem(using: repository),
                  let secondaryOneHanded = ElfOneHandedWeaponItem(weapon: secondary) else {
                return createDefaultWeaponConfig(using: repository)
            }
            return .dualWield(primary: primaryOneHanded, secondary: secondaryOneHanded)
        }
    }
}

// MARK: - EquippedItemsSaveData

/// Persistence DTO for EquippedItems struct.
public struct EquippedItemsSaveData: Codable, Sendable, Equatable {

    // MARK: - Weapons

    public let weaponConfig: WeaponConfigSaveData

    // MARK: - Armor

    public let helmet: DefenseSaveData?
    public let gloves: DefenseSaveData?
    public let shoes: DefenseSaveData?
    public let upperBody: DefenseSaveData?
    public let bottomBody: DefenseSaveData?

    // MARK: - Clothing

    public let shirt: RobeSaveData?

    // MARK: - Jewelry

    public let ring: JewelrySaveData?
    public let necklace: JewelrySaveData?
    public let earrings: JewelrySaveData?

    // MARK: - Initialization

    /// Create from EquippedItems
    public init(from equipped: EquippedItems) {
        self.weaponConfig = WeaponConfigSaveData(from: equipped.weapons)
        self.helmet = equipped.helmet.map { DefenseSaveData(from: $0) }
        self.gloves = equipped.gloves.map { DefenseSaveData(from: $0) }
        self.shoes = equipped.shoes.map { DefenseSaveData(from: $0) }
        self.upperBody = equipped.upperBody.map { DefenseSaveData(from: $0) }
        self.bottomBody = equipped.bottomBody.map { DefenseSaveData(from: $0) }
        self.shirt = equipped.shirt.map { RobeSaveData(from: $0) }
        self.ring = equipped.ring.map { JewelrySaveData(from: $0) }
        self.necklace = equipped.necklace.map { JewelrySaveData(from: $0) }
        self.earrings = equipped.earrings.map { JewelrySaveData(from: $0) }
    }

    /// Convert to EquippedItems using items repository
    public func toEquippedItems(using repository: ItemsRepository) -> EquippedItems {
        let weapons = weaponConfig.toWeaponConfiguration(using: repository)
        let helmet = helmet?.toElfDefenseItem(using: repository)
        let gloves = gloves?.toElfDefenseItem(using: repository)
        let shoes = shoes?.toElfDefenseItem(using: repository)
        let upperBody = upperBody?.toElfDefenseItem(using: repository)
        let bottomBody = bottomBody?.toElfDefenseItem(using: repository)
        let shirt = shirt?.toElfRobeItem(using: repository)
        let ring = ring?.toElfJewelryItem(using: repository)
        let necklace = necklace?.toElfJewelryItem(using: repository)
        let earrings = earrings?.toElfJewelryItem(using: repository)

        return EquippedItems(
            weapons: weapons,
            helmet: helmet,
            gloves: gloves,
            shoes: shoes,
            upperBody: upperBody,
            bottomBody: bottomBody,
            shirt: shirt,
            ring: ring,
            necklace: necklace,
            earrings: earrings
        )
    }
}
