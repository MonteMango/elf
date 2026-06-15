//
//  Battle.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct Battle: Sendable, Identifiable {
    public let id: BattleID

    /// Left team combatants (player team). Uses CombatantSnapshot for unified elf/monster handling.
    public let leftTeam: [CombatantSnapshot]

    /// Right team combatants (opponent team). Uses CombatantSnapshot for unified elf/monster handling.
    public let rightTeam: [CombatantSnapshot]

    /// Pre-resolved per-combatant equipment slot map, keyed by `CombatantSnapshot.id`.
    /// UI-only data (consumed by `BattleFightViewModel+Display.makeDisplay` to feed
    /// `HeroDisplayState.equippedItems`); kept off `CombatantSnapshot` so combat
    /// invalidations don't ripple through the equipment layout. Static for the
    /// duration of the battle — no mid-fight item swaps.
    ///
    /// Monsters carry no entry (or `[:]` if explicitly included); the consumer
    /// falls back to an empty map per missing key.
    ///
    /// TODO: [combat/equipment-mutation] when items can be destroyed mid-battle,
    /// this immutable map goes stale on the first destruction event. Cleaner
    /// future state: move raw `EquippedItems` onto `CombatantSnapshot` (mutable),
    /// drop this field, and have VM `makeDisplay` resolve the UI map on-the-fly
    /// per render via `HeroEquippedSlotResolver`.
    public let equippedItemsByCombatantId: [CombatantID: [HeroItemType: HeroEquippedSlot]]

    /// `MonsterID` of the first opponent when it's a monster (`nil` for
    /// synthetic / elf opponents). Single source for resolving the bot monster
    /// behind reward calculation.
    public var botMonsterID: MonsterID? {
        guard let bot = rightTeam.first, case .monster(let monsterId) = bot.source else { return nil }
        return monsterId
    }

    public init(
        id: BattleID = BattleID(),
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        equippedItemsByCombatantId: [CombatantID: [HeroItemType: HeroEquippedSlot]] = [:]
    ) {
        self.id = id
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
        self.equippedItemsByCombatantId = equippedItemsByCombatantId
    }
}
