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

    // MARK: - Initialization

    public init(itemsRepository: ItemsRepository) {
        self.itemsRepository = itemsRepository
        // Items are already loaded in DI container initialization
    }
}
