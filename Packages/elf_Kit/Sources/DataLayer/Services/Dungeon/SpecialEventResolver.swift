//
//  SpecialEventResolver.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Maps a non-combat dungeon `SpecialEvent` to its `DungeonEventOutcome` — the
/// single place that owns "what each event does". Pure policy: no run state, no
/// side effects, so it is trivially testable and `Sendable`. `DungeonSession`
/// applies the returned outcome (it remains the only writer of run state).
///
/// Adding a new event = a new case here, not a new method on `DungeonSession`.
public protocol SpecialEventResolver: Sendable {
    func resolve(_ event: SpecialEvent) -> DungeonEventOutcome
}
