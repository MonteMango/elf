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
    private let buffEffectsCalculator: any BuffEffectsCalculator

    public init() {
        @Dependency(\.armorService) var armorService
        @Dependency(\.buffEffectsCalculator) var buffEffectsCalculator
        self.armorService = armorService
        self.buffEffectsCalculator = buffEffectsCalculator
    }

    // MARK: - CombatantSnapshotBuilder

    public func buildSnapshot(
        elf: ElfInfo,
        level: Int,
        globalBuffs: [AppliedBuff]
    ) -> CombatantSnapshot {
        // Single source of truth: `ElfInfo.totalAttributes` aggregates fight-style
        // + random-per-level + equipped item bonuses. New attribute terms
        // (reputation perk, training bonus, …) added there flow into combat
        // automatically — no second formula to update.
        buildElfSnapshot(
            name: elf.name,
            imageName: elf.imageName,
            level: level,
            totalAttributes: elf.totalAttributes,
            equipped: elf.equipped,
            globalBuffs: globalBuffs
        )
    }

    public func buildSnapshot(
        name: String,
        imageName: String,
        level: Int,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        equipped: EquippedItems,
        globalBuffs: [AppliedBuff]
    ) -> CombatantSnapshot {
        // Synthetic overload for the dev `BattleSetupViewModel` path: the formula
        // below MUST mirror `ElfInfo.totalAttributes`. If `ElfInfo.totalAttributes`
        // grows a new term (e.g. reputation perk), this line will drift — but the
        // synthetic path is dev-only and acceptable to maintain manually.
        let totalAttributes = fightStyleAttributes + randomLevelAttributes + equipped.attributes
        return buildElfSnapshot(
            name: name,
            imageName: imageName,
            level: level,
            totalAttributes: totalAttributes,
            equipped: equipped,
            globalBuffs: globalBuffs
        )
    }

    /// Shared implementation: takes pre-aggregated total attributes (no formula
    /// here) and assembles the snapshot. Weapon placement, attack profiles, and
    /// armor lookup all derive from `equipped` regardless of how `totalAttributes`
    /// was computed by the caller.
    private func buildElfSnapshot(
        name: String,
        imageName: String,
        level: Int,
        totalAttributes: HeroAttributes,
        equipped: EquippedItems,
        globalBuffs: [AppliedBuff]
    ) -> CombatantSnapshot {

        // Type-safe weapon resolution: WeaponConfiguration's exhaustive cases
        // make "no primary weapon" structurally impossible at this boundary.
        let placement = resolveWeaponPlacement(equipped.weapons)
        let attacks = buildAttacks(from: equipped.weapons)

        // Seed currentHP/currentMP from the buff-folded cap so the combatant
        // enters battle at full effective HP/MP, not just base. Battle buffs
        // start empty — only globals are active at construction time.
        let effective = buffEffectsCalculator.apply(buffs: globalBuffs, to: totalAttributes)

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
            currentHP: effective.hitPoints.intValue,
            currentMP: effective.manaPoints.intValue,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            baseHeroAttributes: totalAttributes,
            attacks: attacks,
            defensePoints: placement.defensePoints,
            armorValues: armorValues,
            globalBuffs: globalBuffs,
            battleBuffs: []
        )
    }

    public func buildSnapshot(from monster: Monster, globalBuffs: [AppliedBuff]) -> CombatantSnapshot {
        // Map monster's parts protection to BodyPart keys
        let armorValues: [BodyPart: Int] = [
            .head: monster.partsProtection.head,
            .leftHand: monster.partsProtection.left,
            .body: monster.partsProtection.center,
            .rightHand: monster.partsProtection.right,
            .legs: monster.partsProtection.legs
        ]

        let attacks: [AttackProfile] = [monster.rightAttack] + (monster.leftAttack.map { [$0] } ?? [])

        // Mirror monster's scalar attributes into HeroAttributes so the snapshot
        // exposes a consistent `baseHeroAttributes` for buff math.
        let baseHeroAttributes = HeroAttributes(
            hitPoints: Attribute(Int16(clamping: monster.hitPoints)),
            manaPoints: Attribute(Int16(clamping: monster.manaPoints)),
            agility: Attribute(Int16(clamping: monster.agility)),
            strength: Attribute(Int16(clamping: monster.strength)),
            power: Attribute(Int16(clamping: monster.power)),
            instinct: Attribute(Int16(clamping: monster.instinct)),
            endurance: Attribute(Int16(clamping: monster.endurance))
        )

        // Symmetry with the elf overload: seed currentHP/currentMP from the
        // buff-folded cap so a monster spawned with pre-applied globals enters
        // battle "full" relative to those buffs. Empty `globalBuffs` is the
        // common case and short-circuits inside the calculator to base.
        let effective = buffEffectsCalculator.apply(buffs: globalBuffs, to: baseHeroAttributes)

        return CombatantSnapshot(
            sourceId: monster.id,
            name: monster.title,
            imageName: monster.imageName,
            combatantType: .monster,
            level: 1,  // Monsters don't have levels, default to 1
            currentHP: effective.hitPoints.intValue,
            currentMP: effective.manaPoints.intValue,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            baseHeroAttributes: baseHeroAttributes,
            attacks: attacks,
            defensePoints: monster.defensePoints,
            armorValues: armorValues,
            globalBuffs: globalBuffs
        )
    }

    // MARK: - Private Helpers

    private struct WeaponPlacement {
        let defensePoints: Int
    }

    /// Computes the snapshot's per-round defense count from a `WeaponConfiguration`.
    /// Base defense is 2; a shield grants +1.
    private func resolveWeaponPlacement(_ config: WeaponConfiguration) -> WeaponPlacement {
        switch config {
        case .oneHanded:
            return WeaponPlacement(defensePoints: 2)
        case .oneHandedWithShield:
            return WeaponPlacement(defensePoints: 3)
        case .twoHanded:
            return WeaponPlacement(defensePoints: 2)
        case .dualWield:
            return WeaponPlacement(defensePoints: 2)
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
