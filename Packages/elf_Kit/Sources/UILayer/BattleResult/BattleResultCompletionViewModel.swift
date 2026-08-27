//
//  BattleResultCompletionViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Session-aware companion to `BattleResultViewModel` for the hero-death
/// continuation path: owns no display state itself, only delegates the
/// "finish the run" action to the single-owner `GameSession.completeDungeonRun()`
/// so reward flush + save stay centralized in one place.
@MainActor
public final class BattleResultCompletionViewModel {

    private let gameSession: GameSession

    init(gameSession: GameSession) {
        self.gameSession = gameSession
    }

    /// Ends the active dungeon run (if any), flushing rewards and persisting.
    /// A no-op when there is no active run.
    public func finishRun() {
        gameSession.completeDungeonRun()
    }
}
