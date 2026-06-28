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

    /// Snapshot-in-init (project DI pattern): read once at construction and store,
    /// so the runner is stable for the coordinator's lifetime. `liveValue` is always
    /// available (not async-loaded), so reading it pre-`DependencyBootstrap` is safe.
    private let backgroundTaskRunner: any BackgroundTaskRunner

    public init() {
        @Dependency(\.backgroundTaskRunner) var backgroundTaskRunner
        self.backgroundTaskRunner = backgroundTaskRunner
    }

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
                session.discardDungeonRun()
            }
        }
    }

    /// Route to push on top of `.gameSession` when resuming a saved game, or nil.
    /// Currently only resumes into an active, valid dungeon run. Keeps the
    /// "when + which route to resume" decision out of the menu view.
    internal var resumeRoute: AppRoute? {
        guard let dungeon = gameSession?.dungeonSession, dungeon.isInRun else { return nil }
        return .dungeon(dungeonId: dungeon.dungeonId, allyIds: dungeon.allyIds)
    }

    /// Ends the active game session and releases the session.
    /// Safe to call at any time: screens retain their VM strongly until unmount.
    public func endGame() {
        gameSession = nil
        dayStateViewModel = nil
    }

    /// Saves the active game when the app backgrounds, under a background-task
    /// assertion (via `BackgroundTaskRunner`) so a large save finishes before the
    /// process suspends. Awaits any in-flight checkpoint save first to avoid racing
    /// it on the storage actor, then writes the final snapshot.
    ///
    /// Synchronous on purpose: `run(name:_:)` takes the assertion *before* the async
    /// save is scheduled, so it is registered while the app is still running.
    /// Orchestration only — the UIKit assertion mechanism lives in the runner.
    public func saveOnBackground() {
        guard let session = gameSession else { return }
        backgroundTaskRunner.run(name: "GameSave") {
            await session.awaitInFlightSave()
            do {
                try await session.save()
            } catch {
                #if DEBUG
                print("[AppCoordinator] Background save failed: \(error)")
                #endif
            }
        }
    }

    // MARK: - Preview Support

    #if DEBUG
    /// Initializes a game session for SwiftUI previews without side effects.
    public func initializePreviewSession(game: Game) {
        startGame(game)
    }
    #endif
}
