//
//  MainMenuViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import Foundation

@Observable
@MainActor
public final class MainMenuViewModel {

    // MARK: - Dependencies

    private let itemsRepository: ItemsRepository
    private let gameRepository: GameRepository

    // MARK: - State

    /// Whether a saved game exists
    public var hasSavedGame: Bool

    /// Whether the load operation is in progress
    public var isLoading: Bool = false

    /// Error message to display in alert
    public var loadError: String?

    /// Loaded game (set after successful load)
    public var loadedGame: Game?

    /// Play time from loaded save
    public var loadedPlayTime: TimeInterval = 0

    // MARK: - Initialization

    public init(itemsRepository: ItemsRepository, gameRepository: GameRepository) {
        self.itemsRepository = itemsRepository
        self.gameRepository = gameRepository
        self.hasSavedGame = gameRepository.hasAnySave()
    }

    // MARK: - Actions

    /// Load saved game from default slot
    public func loadGame() async {
        isLoading = true
        loadError = nil

        do {
            loadedPlayTime = await gameRepository.getPlayTime(slotId: SaveSlotInfo.defaultSlotId)
            loadedGame = try await gameRepository.loadDefault()
        } catch let error as GameSaveError {
            loadError = error.errorDescription
        } catch {
            loadError = "Failed to load game: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Dismiss error alert
    public func dismissError() {
        loadError = nil
    }

    /// Refresh saved game status
    public func refreshSaveStatus() {
        hasSavedGame = gameRepository.hasAnySave()
    }
}
