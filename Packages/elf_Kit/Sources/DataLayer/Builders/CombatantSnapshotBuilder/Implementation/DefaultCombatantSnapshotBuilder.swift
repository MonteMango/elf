//
//  DefaultCombatantSnapshotBuilder.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.12.25.
//

import Dependencies
import Foundation

public final class DefaultCombatantSnapshotBuilder: CombatantSnapshotBuilder {

    private let armorService: any ArmorService

    public init() {
        @Dependency(\.armorService) var armorService
        self.armorService = armorService
    }

    // MARK: - CombatantSnapshotBuilder

    public func buildSnapshot(
        name: String,
        imageName: String,
        level: Int,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        equipped: EquippedItems
    ) -> CombatantSnapshot {

        // Type-safe weapon resolution: WeaponConfiguration's exhaustive cases
        // make "no primary weapon" structurally impossible at this boundary.
        let placement = resolveWeaponPlacement(equipped.weapons)
        let attacks = buildAttacks(from: equipped.weapons)

        // Aggregate attributes: fight style + random per-level + equipped item bonuses.
        let totalAttributes = fightStyleAttributes + randomLevelAttributes + equipped.attributes

        // Armor IDs: every wearable slot, plus the off-hand (shield or dual-wield
        // secondary weapon). Primary weapon is never sent to the armor service.
        let equippedItemIds = collectArmorRelevantIds(equipped: equipped)
        let armorValuesInt16 = armorService.getAllItemsArmor(for: equippedItemIds)
        let armorValues = armorValuesInt16.mapValues { Int($0) }

        return CombatantSnapshot(
            sourceId: UUID(),
            name: name,
            imageName: imageName,
            combatantType: .elf,
            level: level,
            currentHP: totalAttributes.hitPoints.intValue,
            maxHP: totalAttributes.hitPoints.intValue,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            strength: totalAttributes.strength.intValue,
            agility: totalAttributes.agility.intValue,
            power: totalAttributes.power.intValue,
            intuition: totalAttributes.instinct.intValue,
            endurance: totalAttributes.endurance.intValue,
            attacks: attacks,
            defensePoints: placement.defensePoints,
            armorValues: armorValues,
            helmetItem: equipped.helmet,
            glovesItem: equipped.gloves,
            shoesItem: equipped.shoes,
            upperBodyItem: equipped.upperBody,
            bottomBodyItem: equipped.bottomBody,
            robeItem: equipped.shirt,
            leftWeaponItem: placement.leftWeapon,
            rightWeaponItem: placement.rightWeapon,
            shieldItem: placement.shield,
            ringItem: equipped.ring,
            necklaceItem: equipped.necklace,
            earringsItem: equipped.earrings
        )
    }

    public func buildSnapshot(from monster: Monster) -> CombatantSnapshot {
        // Map monster's parts protection to BodyPart keys
        let armorValues: [BodyPart: Int] = [
            .head: monster.partsProtection.head,
            .leftHand: monster.partsProtection.left,
            .body: monster.partsProtection.center,
            .rightHand: monster.partsProtection.right,
            .legs: monster.partsProtection.legs
        ]

        let attacks: [AttackProfile] = [monster.rightAttack] + (monster.leftAttack.map { [$0] } ?? [])

        return CombatantSnapshot(
            sourceId: monster.id,
            name: monster.title,
            imageName: monster.imageName,
            combatantType: .monster,
            level: 1,  // Monsters don't have levels, default to 1
            currentHP: monster.hitPoints,
            maxHP: monster.hitPoints,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            strength: monster.strength,
            agility: monster.agility,
            power: monster.power,
            intuition: monster.intuition,
            endurance: monster.endurance,
            attacks: attacks,
            defensePoints: monster.defensePoints,
            armorValues: armorValues
            // Equipment is nil for monsters (for now)
        )
    }

    // MARK: - Private Helpers

    private struct WeaponPlacement {
        let leftWeapon: ElfWeaponItem?
        let rightWeapon: ElfWeaponItem?
        let shield: ElfShieldItem?
        let defensePoints: Int
    }

    /// Maps a `WeaponConfiguration` to the snapshot's hand-slot layout and
    /// per-round defense count. Base defense is 2; a shield grants +1.
    private func resolveWeaponPlacement(_ config: WeaponConfiguration) -> WeaponPlacement {
        switch config {
        case .oneHanded(let wrapper):
            return WeaponPlacement(
                leftWeapon: nil,
                rightWeapon: wrapper.weapon,
                shield: nil,
                defensePoints: 2
            )
        case .oneHandedWithShield(let wrapper, let shield):
            return WeaponPlacement(
                leftWeapon: nil,
                rightWeapon: wrapper.weapon,
                shield: shield,
                defensePoints: 3
            )
        case .twoHanded(let wrapper):
            return WeaponPlacement(
                leftWeapon: nil,
                rightWeapon: wrapper.weapon,
                shield: nil,
                defensePoints: 2
            )
        case .dualWield(let primary, let secondary):
            return WeaponPlacement(
                leftWeapon: secondary.weapon,
                rightWeapon: primary.weapon,
                shield: nil,
                defensePoints: 2
            )
        }
    }

    /// Builds the per-strike `AttackProfile` array from a `WeaponConfiguration`.
    /// Index 0 is the primary (right-hand) weapon; index 1 (only for dual-wield)
    /// is the off-hand weapon.
    private func buildAttacks(from config: WeaponConfiguration) -> [AttackProfile] {
        switch config {
        case .oneHanded(let wrapper):
            return [profile(from: wrapper.weapon)]
        case .oneHandedWithShield(let wrapper, _):
            return [profile(from: wrapper.weapon)]
        case .twoHanded(let wrapper):
            return [profile(from: wrapper.weapon)]
        case .dualWield(let primary, let secondary):
            return [profile(from: primary.weapon), profile(from: secondary.weapon)]
        }
    }

    /// Extracts `AttackProfile` (damage range + EP-block cost) from an
    /// `ElfWeaponItem`. The cast is a programming-error backstop — every
    /// weapon wrapper is constructed from a `WeaponItem`.
    private func profile(from weapon: ElfWeaponItem) -> AttackProfile {
        guard let weaponItem = weapon.item as? WeaponItem else {
            assertionFailure("Weapon wrapper's underlying item must be a WeaponItem")
            return AttackProfile(minimumAttack: 0, maximumAttack: 0, epBlockCost: 0)
        }
        return AttackProfile(
            minimumAttack: Int(weaponItem.minimumAttackPoint),
            maximumAttack: Int(weaponItem.maximumAttackPoint),
            epBlockCost: Int(weaponItem.epBlockCost)
        )
    }

    /// Collects base-item UUIDs of every item that contributes armor: all
    /// wearable slots plus the off-hand (shield or dual-wield secondary).
    /// Primary weapon is excluded — main-hand weapons aren't armor.
    ///
    /// Uses `item.id` (the JSON-defined base item id) rather than the
    /// wrapper's per-instance `id`, because `ArmorService` looks values up
    /// in `ItemsRepository` keyed by base id.
    private func collectArmorRelevantIds(equipped: EquippedItems) -> [UUID] {
        var ids: [UUID] = []
        if let id = equipped.helmet?.item.id { ids.append(id) }
        if let id = equipped.gloves?.item.id { ids.append(id) }
        if let id = equipped.shoes?.item.id { ids.append(id) }
        if let id = equipped.upperBody?.item.id { ids.append(id) }
        if let id = equipped.bottomBody?.item.id { ids.append(id) }
        if let id = equipped.shirt?.item.id { ids.append(id) }
        if let id = equipped.weapons.shield?.item.id { ids.append(id) }
        if let secondary = equipped.weapons.secondaryWeapon {
            ids.append(secondary.item.id)
        }
        return ids
    }
}
