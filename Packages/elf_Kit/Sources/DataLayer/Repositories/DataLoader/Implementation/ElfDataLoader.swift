//
//  ElfDataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation

public final class ElfDataLoader: DataLoader {

    public init() {}

    public func loadHeroItemsData() throws -> Data {
        guard let fileURL = Bundle.main.url(forResource: "HeroItems", withExtension: "json") else {
            throw NSError(domain: "File HeroItems.json not found in bundle", code: 404, userInfo: nil)
        }

        return try Data(contentsOf: fileURL)
    }

    public func loadMonstersData() throws -> Data {
        guard let fileURL = Bundle.main.url(forResource: "Monsters", withExtension: "json") else {
            throw NSError(domain: "File Monsters.json not found in bundle", code: 404, userInfo: nil)
        }

        return try Data(contentsOf: fileURL)
    }

    public func loadMaterialsData() throws -> Data {
        guard let fileURL = Bundle.main.url(forResource: "Materials", withExtension: "json") else {
            throw NSError(domain: "File Materials.json not found in bundle", code: 404, userInfo: nil)
        }

        return try Data(contentsOf: fileURL)
    }

    public func loadFishData() throws -> Data {
        guard let fileURL = Bundle.main.url(forResource: "Fish", withExtension: "json") else {
            throw NSError(domain: "File Fish.json not found in bundle", code: 404, userInfo: nil)
        }

        return try Data(contentsOf: fileURL)
    }
}
