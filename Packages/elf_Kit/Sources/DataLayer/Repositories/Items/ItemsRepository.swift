//
//  ItemsRepository.swift
//
//
//  Created by Vitalii Lytvynov on 24.09.24.
//

import Foundation

public protocol ItemsRepository: Sendable {

    func getHeroItem(_ id: UUID) -> Item?

    /// Get all items of a specific type
    ///
    /// - Parameter type: The type of items to retrieve
    /// - Returns: Array of items matching the type
    func getItems(for type: HeroItemType) -> [Item]
}
