//
//  ElfDataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation

public final class ElfDataLoader: DataLoader {

    public init() {}

    public func loadJSON(_ resourceName: String) throws -> Data {
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
