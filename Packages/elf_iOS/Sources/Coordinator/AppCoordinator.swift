//
//  AppCoordinator.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import Foundation

/// App-level owner of the active game session and its lifecycle.
///
/// Session-scoped `GameSessionModel` lifecycle (nil between games). `DefaultGameService`
/// resolves its app-scoped service deps internally via `@Dependency`, so the coordinator
/// only passes the session-scoped data (`game`, `playTime`).
///
/// Lifetime: one instance per app launch, held as `@State` in `ElfApp`.
@MainActor
@Observable
public final class AppCoordinator {

    // MARK: - Session State

    public private(set) var sessionModel: GameSessionModel?

    // MARK: - Initialization

    public init() {}

    // MARK: - Session Lifecycle

    /// Starts (or replaces) the active game session. Must be called before navigating
    /// to `.gameSession` so that `DefaultGameService` is available to session-bound VMs.
    public func startGame(_ game: Game, playTime: TimeInterval = 0) {
        let service = DefaultGameService(game: game, playTime: playTime)
        sessionModel = GameSessionModel(gameService: service)
    }

    /// Ends the active game session and releases the `DefaultGameService`.
    /// Safe to call at any time: screens retain their VM strongly until unmount.
    public func endGame() {
        sessionModel = nil
    }

    /// Saves the active game if a session exists (called on scene-phase background).
    public func saveIfNeeded() async {
        guard let gameService = sessionModel?.gameService else { return }
        try? await gameService.saveGame()
    }

    // MARK: - Preview Support

    #if DEBUG
    /// Initializes a game session for SwiftUI previews without side effects.
    public func initializePreviewSession(game: Game) {
        startGame(game)
    }
    #endif
}
