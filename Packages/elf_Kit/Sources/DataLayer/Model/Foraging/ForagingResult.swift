//
//  ForagingResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Result of a foraging attempt, containing gathered herbs and skill progress
public struct ForagingResult: Sendable, Equatable {
    public let gatheredHerbs: [Herb]
    public let skillProgress: SkillProgressData

    public var isEmpty: Bool {
        gatheredHerbs.isEmpty
    }

    public var herbCount: Int {
        gatheredHerbs.count
    }

    public init(gatheredHerbs: [Herb], skillProgress: SkillProgressData) {
        self.gatheredHerbs = gatheredHerbs
        self.skillProgress = skillProgress
    }
}
