//
//  NewSelectHeroItemViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import Foundation

@Observable
public final class NewSelectHeroItemViewModel {

    // MARK: - Dependencies

    private let navigationManager: any NavigationManaging
    private let itemsRepository: ItemsRepository
    private let onItemSelected: (UUID?) -> Void

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
        navigationManager: any NavigationManaging,
        itemsRepository: ItemsRepository,
        onItemSelected: @escaping (UUID?) -> Void
    ) {
        self.heroType = heroType
        self.heroItemType = heroItemType
        self.currentItemId = currentItemId
        self.navigationManager = navigationManager
        self.itemsRepository = itemsRepository
        self.onItemSelected = onItemSelected
        self.selectedItemId = currentItemId

        Task {
            await loadItems()
        }
    }

    // MARK: - Actions

    public func selectItem(_ itemId: UUID?) {
        selectedItemId = itemId
    }

    public func equipButtonAction() {
        onItemSelected(selectedItemId)
        navigationManager.dismissModal()
    }

    public func closeButtonAction() {
        navigationManager.dismissModal()
    }

    // MARK: - Private Methods

    private func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        // Get hero items from repository
        guard let heroItems = itemsRepository.heroItems else {
            // Try to load if not available
            do {
                try await itemsRepository.loadHeroItems()
                guard let items = itemsRepository.heroItems else { return }
                availableItems = filterItems(for: heroItemType, in: items)
            } catch {
                print("Error loading hero items: \(error)")
            }
            return
        }

        availableItems = filterItems(for: heroItemType, in: heroItems)
    }

    private func filterItems(for type: HeroItemType, in heroItems: HeroItems) -> [Item] {
        switch type {
        case .helmet:
            return heroItems.helmets
        case .gloves:
            return heroItems.gloves
        case .shoes:
            return heroItems.shoes
        case .upperBody:
            return heroItems.upperBodies
        case .bottomBody:
            return heroItems.bottomBodies
        case .shirt:
            return heroItems.robes
        case .weapons:
            return heroItems.weapons
        case .shields:
            // Shields include both shield items and weapons with secondary hand use
            return heroItems.shields + heroItems.weapons.filter { $0.handUse == .secondary }
        case .ring:
            return heroItems.rings
        case .necklace:
            return heroItems.necklaces
        case .earrings:
            return heroItems.earrings
        }
    }
}
