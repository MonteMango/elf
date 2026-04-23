//
//  SelectHeroItemViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class SelectHeroItemViewModel {

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.itemsRepository) private var itemsRepository

    // MARK: - Input

    public let heroItemType: HeroItemType

    // MARK: - State

    public var availableItems: [Item] = []
    public var selectedItemId: UUID?
    public var isLoading: Bool = false

    // MARK: - Initialization

    public init(heroType: HeroType, heroItemType: HeroItemType, currentItemId: UUID?) {
        self.heroItemType = heroItemType
        self.selectedItemId = currentItemId

        Task {
            await loadItems()
        }
    }

    // MARK: - Actions

    public func selectItem(_ itemId: UUID?) {
        selectedItemId = itemId
    }

    // MARK: - Private Methods

    private func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        // Get items from repository using the new getItems method
        availableItems = itemsRepository.getItems(for: heroItemType)
    }
}
