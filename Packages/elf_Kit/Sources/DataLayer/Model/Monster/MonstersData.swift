//
//  MonstersData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public struct MonstersData: Codable, Sendable {
    public let version: String
    public let upperWorld: WorldLevels
    public let middleWorld: WorldLevels
    public let lowerWorld: WorldLevels

    public init(
        version: String,
        upperWorld: WorldLevels,
        middleWorld: WorldLevels,
        lowerWorld: WorldLevels
    ) {
        self.version = version
        self.upperWorld = upperWorld
        self.middleWorld = middleWorld
        self.lowerWorld = lowerWorld
    }

    /// Creates empty MonstersData for fallback scenarios
    public static func empty() -> MonstersData {
        MonstersData(
            version: "1.0-empty",
            upperWorld: WorldLevels(),
            middleWorld: WorldLevels(),
            lowerWorld: WorldLevels()
        )
    }
}
