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

    /// Per-combatant equipped item set, keyed by `CombatantSnapshot.id`. Pure
    /// domain data (`EquippedItems`) — the UI slot map
    /// (`[HeroItemType: HeroEquippedSlot]`) is resolved on-the-fly at render time
    /// by `BattleFightViewModel.makeDisplay` via `HeroEquippedSlotResolver`,
    /// keeping this model free of presentation types. Kept off `CombatantSnapshot`
    /// so per-round HP / battleBuffs mutations don't ripple through equipment
    /// rendering. Static for the duration of the battle — no mid-fight item swaps.
    ///
    /// Monsters carry no entry; the consumer falls back to an empty map per
    /// missing key.
    ///
    /// TODO: [combat/equipment-mutation] when items can be destroyed mid-battle,
    /// this immutable map goes stale on the first destruction event — it will
    /// then need to track each combatant's live `EquippedItems`.
    public let equippedByCombatantId: [CombatantID: EquippedItems]

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
        equippedByCombatantId: [CombatantID: EquippedItems] = [:]
    ) {
        self.id = id
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
        self.equippedByCombatantId = equippedByCombatantId
    }
}
