//
//  FishingResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Result of a fishing attempt, containing caught fish and skill progress
public struct FishingResult: Sendable, Equatable {
    public let caughtFish: [Fish]
    public let skillProgress: SkillProgressData

    public var isEmpty: Bool {
        caughtFish.isEmpty
    }

    public var fishCount: Int {
        caughtFish.count
    }

    public init(caughtFish: [Fish], skillProgress: SkillProgressData) {
        self.caughtFish = caughtFish
        self.skillProgress = skillProgress
    }
}
