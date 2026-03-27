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
private func createDefaultWeaponConfig(using repository: ItemsRepository) async -> WeaponConfiguration {
    guard let weaponItem = await repository.getHeroItem(defaultWeaponId) as? WeaponItem else {
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
    public func toWeaponConfiguration(using repository: ItemsRepository) async -> WeaponConfiguration {
        switch type {
        case .empty:
            // Backwards compatibility: old saves with empty config get default weapon
            return await createDefaultWeaponConfig(using: repository)

        case .oneHanded:
            guard let weaponData = weapon,
                  let weapon = await weaponData.toElfWeaponItem(using: repository) else {
                return await createDefaultWeaponConfig(using: repository)
            }
            return .oneHanded(weapon: weapon)

        case .oneHandedWithShield:
            guard let weaponData = weapon,
                  let weapon = await weaponData.toElfWeaponItem(using: repository),
                  let shieldData = shield,
                  let shield = await shieldData.toElfShieldItem(using: repository) else {
                return await createDefaultWeaponConfig(using: repository)
            }
            return .oneHandedWithShield(weapon: weapon, shield: shield)

        case .twoHanded:
            guard let weaponData = weapon,
                  let weapon = await weaponData.toElfWeaponItem(using: repository) else {
                return await createDefaultWeaponConfig(using: repository)
            }
            return .twoHanded(weapon: weapon)

        case .dualWield:
            guard let primaryData = weapon,
                  let primary = await primaryData.toElfWeaponItem(using: repository),
                  let secondaryData = secondaryWeapon,
                  let secondary = await secondaryData.toElfWeaponItem(using: repository) else {
                return await createDefaultWeaponConfig(using: repository)
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
    public func toEquippedItems(using repository: ItemsRepository) async -> EquippedItems {
        let weapons = await weaponConfig.toWeaponConfiguration(using: repository)
        let helmet = await helmet?.toElfDefenseItem(using: repository)
        let gloves = await gloves?.toElfDefenseItem(using: repository)
        let shoes = await shoes?.toElfDefenseItem(using: repository)
        let upperBody = await upperBody?.toElfDefenseItem(using: repository)
        let bottomBody = await bottomBody?.toElfDefenseItem(using: repository)
        let shirt = await shirt?.toElfRobeItem(using: repository)
        let ring = await ring?.toElfJewelryItem(using: repository)
        let necklace = await necklace?.toElfJewelryItem(using: repository)
        let earrings = await earrings?.toElfJewelryItem(using: repository)

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
