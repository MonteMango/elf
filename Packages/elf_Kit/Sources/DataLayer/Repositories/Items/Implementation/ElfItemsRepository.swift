//
//  ElfItemsRepository.swift
//
//
//  Created by Vitalii Lytvynov on 24.09.24.
//

import Combine
import Foundation

public final class ElfItemsRepository: ItemsRepository {
    
    // MARK: Properties
    
    private let dataLoader: DataLoader
    
    @Published public private(set) var heroItems: HeroItems?
    public var heroItemsPublisher: Published<HeroItems?>.Publisher {
        $heroItems
    }
    
    private var heroItemLookup: [UUID: Item] = [:]
    
    // MARK: Methods
    
    public init(dataLoader: DataLoader) {
        self.dataLoader = dataLoader
    }
    
    public func loadHeroItems() async throws {
        let data = try await dataLoader.loadHeroItemsData()
        let heroItems = try JSONDecoder().decode(HeroItems.self, from: data)
        self.heroItems = heroItems
        
        // Rebuild the lookup cache
        var lookup: [UUID: Item] = [:]
        
        func index<T: Item>(_ items: [T]) {
            for item in items {
                lookup[item.id] = item
            }
        }
        
        index(heroItems.helmets)
        index(heroItems.gloves)
        index(heroItems.shoes)
        index(heroItems.upperBodies)
        index(heroItems.bottomBodies)
        index(heroItems.robes)
        index(heroItems.weapons)
        index(heroItems.shields)
        index(heroItems.rings)
        index(heroItems.necklaces)
        index(heroItems.earrings)
        
        self.heroItemLookup = lookup
    }
    
    public func getHeroItem(_ id: UUID) async -> Item? {
        return heroItemLookup[id]
    }
    
}
