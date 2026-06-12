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

    // MARK: - Dependencies (snapshotted at init)

    private let itemsRepository: any ItemsRepository

    // MARK: - Input

    public let heroItemType: HeroItemType

    // MARK: - State

    public var availableItems: [Item] = []
    public var selectedItemId: UUID?
    public var isLoading: Bool = false

    // MARK: - Initialization

    public init(heroType: HeroType, heroItemType: HeroItemType, currentItemId: UUID?) {
        @Dependency(\.itemsRepository) var itemsRepository
        self.itemsRepository = itemsRepository

        self.heroItemType = heroItemType
        self.selectedItemId = currentItemId
    }

    // MARK: - Actions

    public func selectItem(_ itemId: UUID?) {
        selectedItemId = itemId
    }

    // MARK: - Lifecycle

    /// Loads the available items. Call from the view's `.task { }` so the work is
    /// structured and cancelled when the screen disappears.
    public func load() async {
        isLoading = true
        defer { isLoading = false }

        // Get items from repository using the new getItems method
        availableItems = itemsRepository.getItems(for: heroItemType)
    }
}
