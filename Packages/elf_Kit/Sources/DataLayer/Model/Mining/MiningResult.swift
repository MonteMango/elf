//
//  MiningResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Result of a mining attempt, containing mined ores and skill progress
public struct MiningResult: Sendable, Equatable {
    public let minedOres: [Ore]
    public let skillProgress: SkillProgressData

    public var isEmpty: Bool {
        minedOres.isEmpty
    }

    public var oreCount: Int {
        minedOres.count
    }

    public init(minedOres: [Ore], skillProgress: SkillProgressData) {
        self.minedOres = minedOres
        self.skillProgress = skillProgress
    }
}
