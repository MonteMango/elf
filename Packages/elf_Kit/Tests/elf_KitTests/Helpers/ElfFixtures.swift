//
//  ElfFixtures.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Foundation
@testable import elf_Kit

extension TestFixtures {

    /// Build a minimal but valid `ElfInfo` (one one-handed weapon equipped) for
    /// tests that don't care about combat specifics — world-turn planning,
    /// reward application, AP bookkeeping. Each call gets a fresh `ElfID` unless
    /// one is supplied.
    static func elf(
        id: ElfID = ElfID(),
        name: String = "Tester",
        currentExp: Int = 0,
        actionPoints: ActionPoints = .unsafeCreate(current: 100, maximum: 100),
        inventory: ElfInventory = ElfInventory()
    ) -> ElfInfo {
        // swiftlint:disable:next force_try
        let weaponItem = try! TestFixtures.weaponItem(handUse: .oneHand)
        let weapon = ElfWeaponItem(weaponItem: weaponItem)
        guard let oneHanded = ElfOneHandedWeaponItem(weapon: weapon) else {
            fatalError("Fixture weapon must be one-handed")
        }
        let attributes = HeroAttributes(
            hitPoints: 80, manaPoints: 20, agility: 1,
            strength: 1, power: 1, instinct: 1, endurance: 0
        )
        return ElfInfo(
            id: id,
            name: name,
            imageName: "elf_1",
            fightStyle: .dodge,
            currentExp: currentExp,
            actionPoints: actionPoints,
            fightStyleAttributes: attributes,
            randomLevelAttributes: HeroAttributes(),
            equipped: EquippedItems(weapons: .oneHanded(weapon: oneHanded)),
            inventory: inventory
        )
    }
}
