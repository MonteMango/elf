//
//  CombatantSnapshot.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

/// A unified snapshot of a combatant's state for battle calculations.
/// This struct captures all relevant combat stats from either an ElfHero or Monster,
/// enabling unified battle logic regardless of combatant type.
///
/// Combat attributes are stored as a single `baseHeroAttributes: HeroAttributes`
/// (post-equipment, pre-buff). Effective values with buff math are NOT computed
/// on the snapshot — `ElfSnapshotCombatCalculator` resolves them through
/// `BuffEffectsCalculator` at the use site, keeping this type free of DI.
///
/// UI-side equipment layout (`[HeroItemType: HeroEquippedSlot]`) is NOT carried
/// here — it lives on `Battle.equippedItemsByCombatantId` keyed by snapshot id,
/// so per-round HP / battleBuffs mutations don't invalidate equipment rendering.
public struct CombatantSnapshot: Sendable, Identifiable, Hashable {

    // MARK: - Identity

    /// Unique identifier for this snapshot instance
    public let id: UUID

    /// Original ID from the source entity (ElfInfo.id or Monster.id)
    public let sourceId: UUID

    /// Display name of the combatant
    public let name: String

    /// Image asset name for UI display
    public let imageName: String

    /// Type of combatant (elf or monster)
    public let combatantType: CombatantType

    /// Level of the combatant (1-12)
    public let level: Int

    // MARK: - Health

    /// Current hit points (mutable during battle)
    public var currentHP: Int

    // MARK: - Mana

    /// Current mana points (mutable during battle). Cosmetic today — no
    /// combat consumer yet — but kept parallel to `currentHP` so flat MP
    /// buffs in `BuffEffect.vitalsFlat` round-trip honestly through the
    /// snapshot rather than being silently dropped.
    public var currentMP: Int

    // MARK: - Endurance Points

    /// Current endurance points (mutable during battle, spent on blocks)
    public var currentEP: Int

    /// Maximum endurance points
    public let maxEP: Int

    // MARK: - Attributes

    /// Base attributes for combat math: post-equipment, pre-buff. Single source
    /// of truth — scalar `baseStrength` / `baseAgility` / ... below are simple
    /// `Int` projections of these values. Combat code combines this with
    /// `globalBuffs` + `battleBuffs` via `BuffEffectsCalculator` to get
    /// effective values.
    ///
    /// TODO: [combat/equipment-mutation] becomes mutable once item-destruction
    /// lands. Will need to recompute on each equipped-item-destroyed event,
    /// alongside `attacks`, `armorValues`, `defensePoints`. The single-source-of-
    /// truth formula will then live on a mutating method (e.g. `recomputeAttrs`)
    /// driven by the current `equipped` set, not from `ElfInfo.totalAttributes`
    /// (which becomes the initial value only).
    public let baseHeroAttributes: HeroAttributes

    /// Global-scope buffs copied from the elf at the start of the battle.
    /// Immutable here — the source of truth is `ElfInfo.globalBuffs`. Empty
    /// for monsters and for snapshots constructed without buff context.
    public let globalBuffs: [AppliedBuff]

    /// Battle-scope buffs gained during the fight. Mutated by
    /// `BattleFightViewModel.applyBattleBuff` and discarded with the snapshot
    /// at `finishBattle` — never propagated back to `ElfInfo`.
    public var battleBuffs: [AppliedBuff]

    // MARK: - Attacks

    /// Per-strike profile (damage range + EP-block cost). One element per
    /// attack point per round.
    ///
    /// Hero: index 0 is the primary (right-hand) weapon; index 1 (when
    /// dual-wielding) is the off-hand weapon. Monster: index 0 is
    /// `Monster.rightAttack`, index 1 is `Monster.leftAttack` when present.
    ///
    /// `ElfSnapshotCombatCalculator` walks body parts in a fixed order and
    /// the i-th attacked body part consumes `attacks[i]`.
    public let attacks: [AttackProfile]

    // MARK: - Combat Points

    /// Number of attack points per round (= `attacks.count`).
    public var attackPoints: Int { attacks.count }

    /// Number of defense points per round
    public let defensePoints: Int

    // MARK: - Armor

    /// Armor values per body part
    public let armorValues: [BodyPart: Int]

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        sourceId: UUID,
        name: String,
        imageName: String,
        combatantType: CombatantType,
        level: Int = 1,
        currentHP: Int,
        currentMP: Int,
        currentEP: Int,
        maxEP: Int,
        baseHeroAttributes: HeroAttributes,
        attacks: [AttackProfile],
        defensePoints: Int,
        armorValues: [BodyPart: Int],
        globalBuffs: [AppliedBuff] = [],
        battleBuffs: [AppliedBuff] = []
    ) {
        self.id = id
        self.sourceId = sourceId
        self.name = name
        self.imageName = imageName
        self.combatantType = combatantType
        self.level = level
        self.currentHP = currentHP
        self.currentMP = currentMP
        self.currentEP = currentEP
        self.maxEP = maxEP
        self.baseHeroAttributes = baseHeroAttributes
        self.attacks = attacks
        self.defensePoints = defensePoints
        self.armorValues = armorValues
        self.globalBuffs = globalBuffs
        self.battleBuffs = battleBuffs
    }

    // MARK: - Base attribute projections

    /// Maximum hit points — `Int` projection of `baseHeroAttributes.hitPoints`.
    /// Pre-buff cap; for the buff-folded value use
    /// `SnapshotCombatCalculator.effectiveAttributes(of:)`. `currentHP` is the
    /// mutable in-battle counter.
    public var maxHP: Int { baseHeroAttributes.hitPoints.intValue }

    /// Maximum mana points — `Int` projection of `baseHeroAttributes.manaPoints`.
    /// Pre-buff cap; for the buff-folded value use
    /// `SnapshotCombatCalculator.effectiveAttributes(of:)`.
    public var maxMP: Int { baseHeroAttributes.manaPoints.intValue }

    /// `Int` projection of `baseHeroAttributes.strength`. Pre-buff value; combat
    /// math should use the effective value computed through `BuffEffectsCalculator`.
    public var baseStrength: Int { Int(baseHeroAttributes.strength.value) }
    public var baseAgility: Int { Int(baseHeroAttributes.agility.value) }
    public var basePower: Int { Int(baseHeroAttributes.power.value) }
    public var baseInstinct: Int { Int(baseHeroAttributes.instinct.value) }
    public var baseEndurance: Int { Int(baseHeroAttributes.endurance.value) }

    // MARK: - Computed Properties

    /// Whether the combatant is still alive
    public var isAlive: Bool {
        currentHP > 0
    }

    /// Whether the combatant carries the battle-scoped Exhausted debuff.
    /// Applied by `DefaultBattleRoundRunner` when EP first reaches 0; checked
    /// by `ElfSnapshotCombatCalculator` to branch into the weak-block path.
    public var isExhausted: Bool {
        battleBuffs.contains { $0.buffId == BuffCatalogID.exhaustedBattle }
    }
}
