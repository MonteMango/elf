//
//  DungeonEventOutcome.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

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
