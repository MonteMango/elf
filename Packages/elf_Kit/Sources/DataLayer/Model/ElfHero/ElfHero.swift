//
//  ElfHero.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import Foundation

public struct ElfHero: Hashable, Equatable {
    public let id: UUID
    public let level: Int

    public let fightStyleAttributes: HeroAttributes
    public let randomLevelAttributes: HeroAttributes

    // Defense items
    public let helmetElfItem: ElfDefenseItem?
    public let glovesElfItem: ElfDefenseItem?
    public let shoesElfItem: ElfDefenseItem?
    public let upperBodyElfItem: ElfDefenseItem?
    public let bottomBodyElfItem: ElfDefenseItem?

    // Robe
    public let robeElfItem: ElfRobeItem?

    // Weapons
    public let leftHandWeaponElfItem: ElfWeaponItem?
    public let rightHandWeaponElfItem: ElfWeaponItem?

    // Shield
    public let shieldElfItem: ElfShieldItem?

    // Jewelry
    public let ringElfItem: ElfJewelryItem?
    public let necklaceElfItem: ElfJewelryItem?
    public let earringsElfItem: ElfJewelryItem?

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        level: Int,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        helmetElfItem: ElfDefenseItem? = nil,
        glovesElfItem: ElfDefenseItem? = nil,
        shoesElfItem: ElfDefenseItem? = nil,
        upperBodyElfItem: ElfDefenseItem? = nil,
        bottomBodyElfItem: ElfDefenseItem? = nil,
        robeElfItem: ElfRobeItem? = nil,
        leftHandWeaponElfItem: ElfWeaponItem? = nil,
        rightHandWeaponElfItem: ElfWeaponItem? = nil,
        shieldElfItem: ElfShieldItem? = nil,
        ringElfItem: ElfJewelryItem? = nil,
        necklaceElfItem: ElfJewelryItem? = nil,
        earringsElfItem: ElfJewelryItem? = nil
    ) {
        self.id = id
        self.level = level
        self.fightStyleAttributes = fightStyleAttributes
        self.randomLevelAttributes = randomLevelAttributes
        self.helmetElfItem = helmetElfItem
        self.glovesElfItem = glovesElfItem
        self.shoesElfItem = shoesElfItem
        self.upperBodyElfItem = upperBodyElfItem
        self.bottomBodyElfItem = bottomBodyElfItem
        self.robeElfItem = robeElfItem
        self.leftHandWeaponElfItem = leftHandWeaponElfItem
        self.rightHandWeaponElfItem = rightHandWeaponElfItem
        self.shieldElfItem = shieldElfItem
        self.ringElfItem = ringElfItem
        self.necklaceElfItem = necklaceElfItem
        self.earringsElfItem = earringsElfItem
    }

    // MARK: - Computed Properties

    public var atackPointsAmount: Int {
        // 1 point if one weapon, 2 points if dual wielding
        let hasLeftWeapon = leftHandWeaponElfItem != nil
        let hasRightWeapon = rightHandWeaponElfItem != nil

        if hasLeftWeapon && hasRightWeapon {
            return 2
        } else if hasLeftWeapon || hasRightWeapon {
            return 1
        }

        return 1 // Default: at least 1 attack point even without weapons
    }

    public var defensePointsAmount: Int {
        // Base 2 defense points, +1 if shield equipped
        let baseDefense = 2
        let hasShield = shieldElfItem != nil

        return hasShield ? baseDefense + 1 : baseDefense
    }
}
