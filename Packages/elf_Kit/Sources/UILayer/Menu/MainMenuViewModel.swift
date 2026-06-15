//
//  MainMenuViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class MainMenuViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let gameRepository: any GameSaveStorage

    // MARK: - State

    /// Cached save-presence flag. Populated by `refreshSavedGameState()` from
    /// `.task` — never read from disk inside view body, and never in `init()`
    /// (VM init runs on every `MainMenuScreen` re-init because
    /// `State(initialValue: MainMenuViewModel())` eagerly evaluates the RHS
    /// each time the parent's body re-runs, even though SwiftUI keeps only
    /// the first instance).
    public private(set) var hasSavedGame: Bool = false

    /// Whether the load operation is in progress.
    public var isLoading: Bool = false

    /// Error message to display in alert.
    public var loadError: String?

    /// Loaded game — triggers navigation when set.
    public private(set) var loadedGame: Game?

    /// In-progress dungeon run from the loaded save, if any. Drives resuming
    /// straight into the dungeon room on Continue.
    public private(set) var loadedDungeonRun: DungeonRunSaveData?

    /// Play time from loaded save.
    public private(set) var loadedPlayTime: TimeInterval = 0

    public init() {
        @Dependency(\.gameRepository) var gameRepository
        self.gameRepository = gameRepository
    }

    // MARK: - Actions

    /// Re-reads the save slot from disk. Call on menu appear and after actions
    /// that can change whether a save exists.
    public func refreshSavedGameState() {
        hasSavedGame = gameRepository.hasAnySave()
    }

    /// Loads saved game from the default slot.
    public func loadGame() async {
        isLoading = true

        do {
            let playTime = await gameRepository.getPlayTime(slotId: SaveSlotInfo.defaultSlotId)
            let loaded = try await gameRepository.loadDefault()
            loadedPlayTime = playTime
            loadedDungeonRun = loaded.dungeonRun
            loadedGame = loaded.game
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }

    /// Clears loaded game state after navigation.
    public func consumeLoadedGame() {
        loadedGame = nil
        loadedDungeonRun = nil
        loadedPlayTime = 0
    }

    /// Dismiss error alert.
    public func dismissError() {
        loadError = nil
    }
}
