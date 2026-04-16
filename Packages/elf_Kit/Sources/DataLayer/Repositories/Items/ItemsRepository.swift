//
//  ItemsRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol ItemsRepository: Sendable {

    /// Get a hero item by UUID.
    func getHeroItem(_ id: UUID) -> Item?

    /// Get all items of a specific type.
    func getItems(for type: HeroItemType) -> [Item]
}
