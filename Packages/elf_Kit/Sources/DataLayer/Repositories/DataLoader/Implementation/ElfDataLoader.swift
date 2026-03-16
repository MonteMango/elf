//
//  ElfDataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation

public final class ElfDataLoader: DataLoader {

    public init() {}

    // MARK: - DataLoader

    public func loadHeroItemsData() throws -> Data {
        try loadJSON("HeroItems")
    }

    public func loadMonstersData() throws -> Data {
        try loadJSON("Monsters")
    }

    public func loadMaterialsData() throws -> Data {
        try loadJSON("Materials")
    }

    public func loadFishData() throws -> Data {
        try loadJSON("Fish")
    }

    public func loadHerbsData() throws -> Data {
        try loadJSON("Herbs")
    }

    public func loadOresData() throws -> Data {
        try loadJSON("Ores")
    }

    public func loadRecipesData() throws -> Data {
        try loadJSON("Recipes")
    }

    // MARK: - Private Helpers

    private func loadJSON(_ resourceName: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw NSError(
                domain: "ElfDataLoader",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "File \(resourceName).json not found in bundle"]
            )
        }
        return try Data(contentsOf: url)
    }
}
