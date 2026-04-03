//
//  MainMenuViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import Foundation

@MainActor
@Observable
public final class MainMenuViewModel {

    // MARK: - Dependencies

    /// Set when game data finishes loading. Nil before that.
    private var gameRepository: (any GameSaveStorage)?

    // MARK: - State

    /// Whether a saved game exists. False until game data is loaded.
    public var hasSavedGame: Bool = false

    /// Whether game data repos are ready.
    public var isGameDataReady: Bool = false

    /// Whether the load operation is in progress.
    public var isLoading: Bool = false

    /// Error message to display in alert.
    public var loadError: String?

    /// Loaded game — triggers navigation when set.
    public private(set) var loadedGame: Game?

    /// Play time from loaded save.
    public private(set) var loadedPlayTime: TimeInterval = 0

    public init() {}

    // MARK: - Game Data Ready

    /// Called when ElfGameContainer finishes loading.
    /// Receives the game repository for save/load operations.
    public func onGameDataReady(gameRepository: any GameSaveStorage) {
        self.gameRepository = gameRepository
        isGameDataReady = true
        hasSavedGame = gameRepository.hasAnySave()
    }

    // MARK: - Actions

    /// Loads saved game from the default slot.
    public func loadGame() async {
        guard let gameRepository else { return }
        isLoading = true

        do {
            let playTime = await gameRepository.getPlayTime(slotId: SaveSlotInfo.defaultSlotId)
            let game = try await gameRepository.loadDefault()
            loadedPlayTime = playTime
            loadedGame = game
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }

    /// Clears loaded game state after navigation.
    public func consumeLoadedGame() {
        loadedGame = nil
        loadedPlayTime = 0
    }

    /// Dismiss error alert.
    public func dismissError() {
        loadError = nil
    }
}
