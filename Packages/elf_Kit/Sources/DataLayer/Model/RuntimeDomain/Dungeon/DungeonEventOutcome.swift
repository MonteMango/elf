//
//  DungeonEventOutcome.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// How much of a squad member's reserves an event restores. A closed set so new
/// magnitudes are explicit; `nil` outcome means "no restore". Extend with e.g.
/// `case fraction(Double)` when an event needs partial healing.
public enum VitalsRestore: Sendable, Equatable {
    /// Restore HP/MP to full (living members only — no revive).
    case full
}

/// Declarative result of resolving a `SpecialEvent`: *what* should change in the
/// run. Produced by `SpecialEventResolver` (pure policy) and applied by
/// `DungeonSession` (the single writer of run state). Keeping this a small value
/// type lets new events add a field here instead of growing `DungeonSession`
/// with a per-event method.
public struct DungeonEventOutcome: Sendable, Equatable {

    /// Vitals restoration to apply to the living squad, if any.
    public let restore: VitalsRestore?

    /// Whether resolving the event clears the current room (advances the run).
    public let clearsRoom: Bool

    public init(restore: VitalsRestore? = nil, clearsRoom: Bool = false) {
        self.restore = restore
        self.clearsRoom = clearsRoom
    }
}
