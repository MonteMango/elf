//
//  PairResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Per-pair record returned by `BattleRoundRunner`: the inputs used, the raw
/// `CombatRoundResult`, the HP delta, and a flag identifying the hero pair.
/// Carries everything any consumer needs (UI logging, statistics aggregation,
/// future replay), so the runner doesn't grow side-effect dependencies.
public struct PairResult: Sendable {
    public let pair: DuelPair
    /// Snapshot of the left combatant **before** this round's damage was
    /// applied. Use for round-start logging (HP, stats at the moment of
    /// engagement). After the round, the team array's snapshot will have
    /// updated HP — this preserves the pre-round view.
    public let leftSnapshot: CombatantSnapshot
    /// Snapshot of the right combatant **before** this round's damage was applied.
    public let rightSnapshot: CombatantSnapshot
    public let leftAttack: Set<BodyPart>
    public let leftDefense: Set<BodyPart>
    public let rightAttack: Set<BodyPart>
    public let rightDefense: Set<BodyPart>
    public let result: CombatRoundResult
    public let leftOldHP: Int
    public let leftNewHP: Int
    public let rightOldHP: Int
    public let rightNewHP: Int
    public let isHeroPair: Bool

    public var leftCombatantId: UUID { leftSnapshot.id }
    public var rightCombatantId: UUID { rightSnapshot.id }

    public init(
        pair: DuelPair,
        leftSnapshot: CombatantSnapshot,
        rightSnapshot: CombatantSnapshot,
        leftAttack: Set<BodyPart>,
        leftDefense: Set<BodyPart>,
        rightAttack: Set<BodyPart>,
        rightDefense: Set<BodyPart>,
        result: CombatRoundResult,
        leftOldHP: Int,
        leftNewHP: Int,
        rightOldHP: Int,
        rightNewHP: Int,
        isHeroPair: Bool
    ) {
        self.pair = pair
        self.leftSnapshot = leftSnapshot
        self.rightSnapshot = rightSnapshot
        self.leftAttack = leftAttack
        self.leftDefense = leftDefense
        self.rightAttack = rightAttack
        self.rightDefense = rightDefense
        self.result = result
        self.leftOldHP = leftOldHP
        self.leftNewHP = leftNewHP
        self.rightOldHP = rightOldHP
        self.rightNewHP = rightNewHP
        self.isHeroPair = isHeroPair
    }
}
