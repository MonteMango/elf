//
//  MainMenuViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import Foundation

@Observable
public final class MainMenuViewModel {

    // MARK: - Dependencies

    private let navigationManager: any NavigationManaging
    private let itemsRepository: ItemsRepository

    // MARK: - State

    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        navigationManager: any NavigationManaging,
        itemsRepository: ItemsRepository
    ) {
        self.navigationManager = navigationManager
        self.itemsRepository = itemsRepository

        // Load items on initialization
        Task {
            await loadItems()
        }
    }

    // MARK: - Actions

    public func startGameAction() {
        // TODO: Implement start game navigation
        print("Start game action")
    }

    public func battleAction() {
        navigationManager.push(AppRoute.battleSetup)
    }

    // MARK: - Private Methods

    private func loadItems() async {
        errorMessage = nil

        do {
            try await itemsRepository.loadHeroItems()
        } catch {
            errorMessage = "Failed to load items: \(error.localizedDescription)"
        }
    }
}
