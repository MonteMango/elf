//
//  AppCoordinator.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import elf_Kit
import Foundation

/// App-level owner of the active game session and its lifecycle.
///
/// Non-optional services are resolved via `@Dependency` — the coordinator itself
/// only tracks the current `GameSessionModel` (nil between games) and exposes
/// start/end/save operations.
///
/// Lifetime: one instance per app launch, held as `@State` in `ElfApp`.
@MainActor
@Observable
public final class AppCoordinator {

    // MARK: - Session State

    public private(set) var sessionModel: GameSessionModel?

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.gameRepository) private var gameRepository

    @ObservationIgnored
    @Dependency(\.inventoryService) private var inventoryService

    @ObservationIgnored
    @Dependency(\.craftService) private var craftService

    @ObservationIgnored
    @Dependency(\.debugGameLogger) private var debugGameLogger

    // MARK: - Initialization

    public init() {}

    // MARK: - Session Lifecycle

    /// Starts (or replaces) the active game session. Must be called before navigating
    /// to `.gameSession` so that `DefaultGameService` is available to session-bound VMs.
    public func startGame(_ game: Game, playTime: TimeInterval = 0) {
        let service = DefaultGameService(
            game: game,
            gameRepository: gameRepository,
            inventoryService: inventoryService,
            craftService: craftService,
            debugGameLogger: debugGameLogger,
            playTime: playTime
        )
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
