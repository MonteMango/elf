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

    // MARK: - State

    public var errorMessage: String?

    // MARK: - Initialization

    public init(itemsRepository: ItemsRepository) {
        self.itemsRepository = itemsRepository

        // Load items on initialization
        Task {
            await loadItems()
        }
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
