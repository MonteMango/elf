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
   
    @Published public private(set) var heroItems: HeroItems?
    public var heroItemsPublisher: Published<HeroItems?>.Publisher {
        $heroItems
    }
    
    // MARK: Methods
    
    public init() {
        
    }
    
    public func loadHeroItems() async throws {
        guard let fileURL = Bundle.main.url(forResource: "HeroItems", withExtension: "json") else {
            throw NSError(domain: "File HeroItems.json not found in bundle", code: 404, userInfo: nil)
        }

        let data = try await Task { () -> Data in
            return try Data(contentsOf: fileURL)
        }.value

        let heroItems = try JSONDecoder().decode(HeroItems.self, from: data)
        self.heroItems = heroItems
    }

}
