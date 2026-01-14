//
//  SelectHeroItemViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import Foundation

@Observable
@MainActor
public final class SelectHeroItemViewModel<ItemsRepo: ItemsRepository> {

    // MARK: - Dependencies

    private let itemsRepository: ItemsRepo

    // MARK: - Input

    public let heroType: HeroType
    public let heroItemType: HeroItemType
    public let currentItemId: UUID?

    // MARK: - State

    public var availableItems: [Item] = []
    public var selectedItemId: UUID?
    public var isLoading: Bool = false

    // MARK: - Initialization

    public init(
        heroType: HeroType,
        heroItemType: HeroItemType,
        currentItemId: UUID?,
        itemsRepository: ItemsRepo
    ) {
        self.heroType = heroType
        self.heroItemType = heroItemType
        self.currentItemId = currentItemId
        self.itemsRepository = itemsRepository
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
