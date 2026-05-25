//
//  Buff.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Catalog buff/debuff definition loaded from `Buffs.json`.
///
/// Lifecycle on an elf is represented by `AppliedBuff` instances stored on
/// either `ElfInfo.globalBuffs` (.global scope) or `CombatantSnapshot.battleBuffs`
/// (.battle scope), each carrying an ID-Reference (`buffId`) back to this type.
public struct Buff: Sendable, Identifiable, Codable, Hashable {

    public let id: UUID
    public let title: String
    public let imageName: String
    public let description: String
    public let polarity: BuffPolarity
    public let scope: BuffScope
    /// Number of in-game days the buff lasts on an elf. `nil` means "no expiry"
    /// (still meaningful only for `.global`; `.battle` buffs are discarded with the battle).
    public let durationDays: Int?
    public let stackingRule: BuffStackingRule
    public let effects: [BuffEffect]

    public init(
        id: UUID,
        title: String,
        imageName: String,
        description: String,
        polarity: BuffPolarity,
        scope: BuffScope,
        durationDays: Int?,
        stackingRule: BuffStackingRule,
        effects: [BuffEffect]
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.description = description
        self.polarity = polarity
        self.scope = scope
        self.durationDays = durationDays
        self.stackingRule = stackingRule
        self.effects = effects
    }
}

/// Whether the buff is helpful (`positive`) or harmful (`negative`).
public enum BuffPolarity: String, Codable, Sendable, Hashable {
    case positive
    case negative
}

/// Where the buff lives. `.global` persists on the elf across battles; `.battle`
/// exists only inside one `Battle` and is discarded with the snapshot.
public enum BuffScope: String, Codable, Sendable, Hashable {
    case battle
    case global
}

/// How re-applying the same buff to an already-affected elf is handled.
/// - `.refresh`: keep one instance, reset its `appliedOnDay`.
/// - `.stack`: increment the existing instance's `stacks` (effects sum additively).
/// - `.ignore`: do nothing if already applied.
public enum BuffStackingRule: String, Codable, Sendable, Hashable {
    case refresh
    case stack
    case ignore
}
