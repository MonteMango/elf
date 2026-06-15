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

    /// Day-level VM, kept alive for the lifetime of `gameSession`. Injected
    /// into the view tree by `SessionRouteView` via `.environment(...)` so
    /// every in-game screen reads the same instance through `@Environment`.
    public private(set) var dayStateViewModel: GameDayStateViewModel?

    // MARK: - Initialization

    public init() {}

    // MARK: - Session Lifecycle

    /// Starts (or replaces) the active game session. Must be called before
    /// navigating to `.gameSession` so that the session's state is available
    /// to session-bound VMs.
    public func startGame(_ game: Game, playTime: TimeInterval = 0, dungeonRun: DungeonRunSaveData? = nil) {
        let session = GameSession(game: game, playTime: playTime)
        gameSession = session
        dayStateViewModel = GameDayStateViewModel(session: session)

        // Resume an in-progress dungeon run, if the save had one. Restore the
        // mutable run state, then discard it if it no longer resolves (e.g. the
        // dungeon/room was removed from the catalog) — the player just resumes
        // on the Game Day screen instead.
        if let dungeonRun {
            let dungeonSession = session.startDungeonSession(
                dungeonId: dungeonRun.dungeonId,
                allyIds: dungeonRun.allyIds
            )
            dungeonSession.restore(from: dungeonRun)
            if !dungeonSession.isResumeStateValid() {
                session.endDungeonSession()
            }
        }
    }

    /// Route to push on top of `.gameSession` when resuming a saved game, or nil.
    /// Currently only resumes into an active, valid dungeon run. Keeps the
    /// "when + which route to resume" decision out of the menu view.
    public var resumeRoute: AppRoute? {
        guard let dungeon = gameSession?.dungeonSession, dungeon.isInRun else { return nil }
        return .dungeon(dungeonId: dungeon.dungeonId, allyIds: dungeon.allyIds)
    }

    /// Ends the active game session and releases the session.
    /// Safe to call at any time: screens retain their VM strongly until unmount.
    public func endGame() {
        gameSession = nil
        dayStateViewModel = nil
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
