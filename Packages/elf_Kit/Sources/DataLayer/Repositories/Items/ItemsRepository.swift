//
//  ItemsRepository.swift
//
//
//  Created by Vitalii Lytvynov on 24.09.24.
//

import Combine
import Foundation

public protocol ItemsRepository {
    
    var heroItems: HeroItems? { get }
    var heroItemsPublisher: AnyPublisher<HeroItems?, Never> { get }
    
    func loadHeroItems() async throws
    func getHeroItem(_ id: UUID) async -> Item?
}
