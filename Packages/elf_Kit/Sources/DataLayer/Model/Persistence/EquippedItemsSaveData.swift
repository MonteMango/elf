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
    return .twoHanded(weapon: defaultWeapon)
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

    public init(
        type: ConfigType,
        weapon: WeaponSaveData? = nil,
        shield: ShieldSaveData? = nil,
        secondaryWeapon: WeaponSaveData? = nil
    ) {
        self.type = type
        self.weapon = weapon
        self.shield = shield
        self.secondaryWeapon = secondaryWeapon
    }

    /// Create from WeaponConfiguration
    public init(from config: WeaponConfiguration) {
        switch config {
        case .oneHanded(let weapon):
            self.type = .oneHanded
            self.weapon = WeaponSaveData(from: weapon)
            self.shield = nil
            self.secondaryWeapon = nil

        case .oneHandedWithShield(let weapon, let shield):
            self.type = .oneHandedWithShield
            self.weapon = WeaponSaveData(from: weapon)
            self.shield = ShieldSaveData(from: shield)
            self.secondaryWeapon = nil

        case .twoHanded(let weapon):
            self.type = .twoHanded
            self.weapon = WeaponSaveData(from: weapon)
            self.shield = nil
            self.secondaryWeapon = nil

        case .dualWield(let primary, let secondary):
            self.type = .dualWield
            self.weapon = WeaponSaveData(from: primary)
            self.shield = nil
            self.secondaryWeapon = WeaponSaveData(from: secondary)
        }
    }

    /// Convert to WeaponConfiguration using items repository
    /// Note: If loading fails or type is `empty`, returns default weapon configuration
    public func toWeaponConfiguration(using repository: ItemsRepository) -> WeaponConfiguration {
        switch type {
        case .empty:
            // Backwards compatibility: old saves with empty config get default weapon
            return createDefaultWeaponConfig(using: repository)

        case .oneHanded:
            guard let weaponData = weapon,
                  let weapon = weaponData.toElfWeaponItem(using: repository) else {
                return createDefaultWeaponConfig(using: repository)
            }
            return .oneHanded(weapon: weapon)

        case .oneHandedWithShield:
            guard let weaponData = weapon,
                  let weapon = weaponData.toElfWeaponItem(using: repository),
                  let shieldData = shield,
                  let shield = shieldData.toElfShieldItem(using: repository) else {
                return createDefaultWeaponConfig(using: repository)
            }
            return .oneHandedWithShield(weapon: weapon, shield: shield)

        case .twoHanded:
            guard let weaponData = weapon,
                  let weapon = weaponData.toElfWeaponItem(using: repository) else {
                return createDefaultWeaponConfig(using: repository)
            }
            return .twoHanded(weapon: weapon)

        case .dualWield:
            guard let primaryData = weapon,
                  let primary = primaryData.toElfWeaponItem(using: repository),
                  let secondaryData = secondaryWeapon,
                  let secondary = secondaryData.toElfWeaponItem(using: repository) else {
                return createDefaultWeaponConfig(using: repository)
            }
            return .dualWield(primary: primary, secondary: secondary)
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

    public init(
        weaponConfig: WeaponConfigSaveData,
        helmet: DefenseSaveData? = nil,
        gloves: DefenseSaveData? = nil,
        shoes: DefenseSaveData? = nil,
        upperBody: DefenseSaveData? = nil,
        bottomBody: DefenseSaveData? = nil,
        shirt: RobeSaveData? = nil,
        ring: JewelrySaveData? = nil,
        necklace: JewelrySaveData? = nil,
        earrings: JewelrySaveData? = nil
    ) {
        self.weaponConfig = weaponConfig
        self.helmet = helmet
        self.gloves = gloves
        self.shoes = shoes
        self.upperBody = upperBody
        self.bottomBody = bottomBody
        self.shirt = shirt
        self.ring = ring
        self.necklace = necklace
        self.earrings = earrings
    }

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
        EquippedItems(
            weapons: weaponConfig.toWeaponConfiguration(using: repository),
            helmet: helmet?.toElfDefenseItem(using: repository),
            gloves: gloves?.toElfDefenseItem(using: repository),
            shoes: shoes?.toElfDefenseItem(using: repository),
            upperBody: upperBody?.toElfDefenseItem(using: repository),
            bottomBody: bottomBody?.toElfDefenseItem(using: repository),
            shirt: shirt?.toElfRobeItem(using: repository),
            ring: ring?.toElfJewelryItem(using: repository),
            necklace: necklace?.toElfJewelryItem(using: repository),
            earrings: earrings?.toElfJewelryItem(using: repository)
        )
    }
}
