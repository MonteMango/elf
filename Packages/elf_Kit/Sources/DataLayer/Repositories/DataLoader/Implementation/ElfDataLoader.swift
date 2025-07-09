//
//  ElfDataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation

public final class ElfDataLoader: DataLoader  {
    
    public init() {}
    
    public func loadHeroItemsData() async throws -> Data {
        guard let fileURL = Bundle.main.url(forResource: "HeroItems", withExtension: "json") else {
            throw NSError(domain: "File HeroItems.json not found in bundle", code: 404, userInfo: nil)
        }
        
        return try Data(contentsOf: fileURL)
    }
}
