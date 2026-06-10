//
//  WorldLevels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public struct WorldLevels: Codable, Sendable {
    public let level1: [Monster]
    public let level2: [Monster]
    public let level3: [Monster]

    public init(
        level1: [Monster] = [],
        level2: [Monster] = [],
        level3: [Monster] = []
    ) {
        self.level1 = level1
        self.level2 = level2
        self.level3 = level3
    }

    /// Returns monsters for a specific level (1, 2, or 3)
    public func monsters(for level: Int) -> [Monster] {
        switch level {
        case 1: return level1
        case 2: return level2
        case 3: return level3
        default: return []
        }
    }
}
