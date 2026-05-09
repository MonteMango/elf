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
/// Holds an optional `GameSession` (nil between games). The session itself
/// owns its `GameStore`, mutation service, and persistence — `AppCoordinator`
/// just wires lifecycle events: start, end, save-on-background.
///
/// Lifetime: one instance per app launch, held as `@State` in `ElfApp`.
@MainActor
@Observable
public final class AppCoordinator {

    // MARK: - Session State

    public private(set) var gameSession: GameSession?

    // MARK: - Initialization

    public init() {}

    // MARK: - Session Lifecycle

    /// Starts (or replaces) the active game session. Must be called before
    /// navigating to `.gameSession` so that the session's state is available
    /// to session-bound VMs.
    public func startGame(_ game: Game, playTime: TimeInterval = 0) {
        gameSession = GameSession(game: game, playTime: playTime)
    }

    /// Ends the active game session and releases the session.
    /// Safe to call at any time: screens retain their VM strongly until unmount.
    public func endGame() {
        gameSession = nil
    }

    /// Saves the active game if a session exists (called on scene-phase background).
    public func saveIfNeeded() async {
        try? await gameSession?.save()
    }

    // MARK: - Preview Support

    #if DEBUG
    /// Initializes a game session for SwiftUI previews without side effects.
    public func initializePreviewSession(game: Game) {
        startGame(game)
    }
    #endif
}
