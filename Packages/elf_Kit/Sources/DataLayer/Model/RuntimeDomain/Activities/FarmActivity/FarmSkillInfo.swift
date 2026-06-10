//
//  FarmSkillInfo.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Information about a farm skill (fishing, foraging, mining)
public struct FarmSkillInfo: Sendable, Equatable {
    public let title: String
    public let level: Int
    public let progress: Double
    public let expInLevel: Int
    public let expPerLevel: Int

    public init(
        title: String,
        level: Int,
        progress: Double,
        expInLevel: Int,
        expPerLevel: Int
    ) {
        self.title = title
        self.level = level
        self.progress = progress
        self.expInLevel = expInLevel
        self.expPerLevel = expPerLevel
    }
}
