//
//  BattleSetupDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Hero Configuration State

@MainActor
@Observable
public final class HeroConfigurationState {
    public var level: Int
    public var fightStyle: FightStyle?
    public var fightStyleAttributes: HeroAttributes?
    public var levelRandomAttributes: HeroAttributes?
    public var itemsAttributes: HeroAttributes?
    public var armorValues: [BodyPart: Int16]
    public var leftHandDamage: (minDmg: Int16, maxDmg: Int16)?
    public var rightHandDamage: (minDmg: Int16, maxDmg: Int16)?
    public var selectedItems: [HeroItemType: UUID?]
    public var twoHandedWeaponId: UUID?

    public var totalAttributes: HeroAttributes? {
        guard let fightStyle = fightStyleAttributes,
              let level = levelRandomAttributes else {
            return nil
        }

        let items = itemsAttributes ?? HeroAttributes()

        return HeroAttributes(
            hitPoints: fightStyle.hitPoints + level.hitPoints + items.hitPoints,
            manaPoints: fightStyle.manaPoints + level.manaPoints + items.manaPoints,
            agility: fightStyle.agility + level.agility + items.agility,
            strength: fightStyle.strength + level.strength + items.strength,
            power: fightStyle.power + level.power + items.power,
            instinct: fightStyle.instinct + level.instinct + items.instinct,
            endurance: fightStyle.endurance + level.endurance + items.endurance
        )
    }

    public init(level: Int = 1) {
        self.level = level
        self.fightStyle = nil
        self.fightStyleAttributes = nil
        self.levelRandomAttributes = nil
        self.itemsAttributes = nil
        self.armorValues = [:]
        self.leftHandDamage = nil
        self.rightHandDamage = nil
        self.selectedItems = [:]
        self.twoHandedWeaponId = nil
    }
}

// MARK: - EquippedItems Adapter

extension HeroConfigurationState {

    /// UUID of "Recruit's Spear" — the canonical starter weapon used by
    /// `DefaultElfInfoFactory` for new heroes. Mirrored here so the Dev
    /// BattleSetup screen can fall back to it when the user hasn't picked
    /// a weapon, instead of disabling the "Start Battle" button.
    private static let defaultWeaponId = UUID(uuidString: "dfbd2742-5470-4f97-84ea-fb17b5f3a6d2")

    /// Materialise a type-safe `EquippedItems` from the in-flux dict
    /// configuration. Falls back to Recruit's Spear when no weapon is
    /// selected — preserves the dev screen's "always able to start a
    /// battle" UX while pushing the type guarantee down to the snapshot
    /// builder.
    ///
    /// - Parameter itemsRepository: used to resolve UUIDs to typed items.
    public func makeEquipped(itemsRepository: any ItemsRepository) -> EquippedItems {
        let weaponConfig = makeWeaponConfiguration(itemsRepository: itemsRepository)

        return EquippedItems(
            weapons: weaponConfig,
            helmet: resolveDefenseItem(.helmet, itemsRepository: itemsRepository),
            gloves: resolveDefenseItem(.gloves, itemsRepository: itemsRepository),
            shoes: resolveDefenseItem(.shoes, itemsRepository: itemsRepository),
            upperBody: resolveDefenseItem(.upperBody, itemsRepository: itemsRepository),
            bottomBody: resolveDefenseItem(.bottomBody, itemsRepository: itemsRepository),
            shirt: resolveRobeItem(itemsRepository: itemsRepository),
            ring: resolveJewelryItem(.ring, itemsRepository: itemsRepository),
            necklace: resolveJewelryItem(.necklace, itemsRepository: itemsRepository),
            earrings: resolveJewelryItem(.earrings, itemsRepository: itemsRepository)
        )
    }

    private func makeWeaponConfiguration(itemsRepository: any ItemsRepository) -> WeaponConfiguration {
        let primaryWeapon = resolvePrimaryWeapon(itemsRepository: itemsRepository)

        guard let primaryBase = primaryWeapon.item as? WeaponItem else {
            fatalError("Resolved primary weapon is not a WeaponItem")
        }

        switch primaryBase.handUse {
        case .both:
            guard let twoHanded = ElfTwoHandedWeaponItem(weapon: primaryWeapon) else {
                fatalError("Two-handed weapon failed to wrap as ElfTwoHandedWeaponItem")
            }
            return .twoHanded(weapon: twoHanded)
        case .oneHand:
            guard let primaryWrapper = ElfOneHandedWeaponItem(weapon: primaryWeapon) else {
                fatalError("One-handed weapon failed to wrap as ElfOneHandedWeaponItem")
            }
            return resolveOneHandedConfiguration(
                primary: primaryWrapper,
                itemsRepository: itemsRepository
            )
        }
    }

    /// Returns the player-selected weapon, or Recruit's Spear if nothing is
    /// selected (or the selected UUID can't be resolved).
    private func resolvePrimaryWeapon(itemsRepository: any ItemsRepository) -> ElfWeaponItem {
        if let selectedId = selectedItems[.weapons] ?? nil,
           let item = itemsRepository.getHeroItem(selectedId) as? WeaponItem {
            return ElfWeaponItem(weaponItem: item)
        }

        guard let defaultId = Self.defaultWeaponId,
              let fallback = itemsRepository.getHeroItem(defaultId) as? WeaponItem else {
            fatalError("Default weapon (Recruit's Spear) not found in repository")
        }
        return ElfWeaponItem(weaponItem: fallback)
    }

    /// Picks between `.oneHanded`, `.oneHandedWithShield`, and `.dualWield`
    /// based on what the user dropped into the shields slot.
    private func resolveOneHandedConfiguration(
        primary: ElfOneHandedWeaponItem,
        itemsRepository: any ItemsRepository
    ) -> WeaponConfiguration {
        guard let shieldSlotId = selectedItems[.shields] ?? nil,
              let shieldSlotItem = itemsRepository.getHeroItem(shieldSlotId) else {
            return .oneHanded(weapon: primary)
        }

        if let shieldBase = shieldSlotItem as? ShieldItem {
            let shield = ElfShieldItem(id: shieldSlotId, item: shieldBase)
            return .oneHandedWithShield(weapon: primary, shield: shield)
        }

        if let secondaryBase = shieldSlotItem as? WeaponItem,
           secondaryBase.handUse == .oneHand {
            let secondaryRaw = ElfWeaponItem(weaponItem: secondaryBase)
            guard let secondary = ElfOneHandedWeaponItem(weapon: secondaryRaw) else {
                return .oneHanded(weapon: primary)
            }
            return .dualWield(primary: primary, secondary: secondary)
        }

        return .oneHanded(weapon: primary)
    }

    private func resolveDefenseItem(
        _ slot: HeroItemType,
        itemsRepository: any ItemsRepository
    ) -> ElfDefenseItem? {
        guard let id = selectedItems[slot] ?? nil,
              let item = itemsRepository.getHeroItem(id),
              item is DefenseItem else {
            return nil
        }
        return ElfDefenseItem(id: id, item: item)
    }

    private func resolveRobeItem(itemsRepository: any ItemsRepository) -> ElfRobeItem? {
        guard let id = selectedItems[.shirt] ?? nil,
              let item = itemsRepository.getHeroItem(id),
              item is RobeItem else {
            return nil
        }
        return ElfRobeItem(id: id, item: item)
    }

    private func resolveJewelryItem(
        _ slot: HeroItemType,
        itemsRepository: any ItemsRepository
    ) -> ElfJewelryItem? {
        guard let id = selectedItems[slot] ?? nil,
              let item = itemsRepository.getHeroItem(id),
              item is JewelryItem else {
            return nil
        }
        return ElfJewelryItem(id: id, item: item)
    }
}

// MARK: - Item Selector State

public struct ItemSelectorState: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let heroType: HeroType
    public let itemType: HeroItemType
    public let currentItemId: UUID?

    public init(heroType: HeroType, itemType: HeroItemType, currentItemId: UUID?) {
        self.heroType = heroType
        self.itemType = itemType
        self.currentItemId = currentItemId
    }
}
