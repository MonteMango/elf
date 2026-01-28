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

// MARK: - Factory

extension FarmSkillInfo {

    private static let farmExpPerLevel = 50

    /// Create skill info for a specific farm activity and player
    public static func make(for activity: FarmActivity, player: ElfInfo) -> FarmSkillInfo {
        switch activity {
        case .fishing:
            return FarmSkillInfo(
                title: "\(activity.title) skill",
                level: player.fishingLevel,
                progress: player.fishingProgress,
                expInLevel: player.fishingExp % farmExpPerLevel,
                expPerLevel: farmExpPerLevel
            )
        case .foraging:
            return FarmSkillInfo(
                title: "\(activity.title) skill",
                level: player.foragingLevel,
                progress: player.foragingProgress,
                expInLevel: player.foragingExp % farmExpPerLevel,
                expPerLevel: farmExpPerLevel
            )
        case .mining:
            return FarmSkillInfo(
                title: "\(activity.title) skill",
                level: player.miningLevel,
                progress: player.miningProgress,
                expInLevel: player.miningExp % farmExpPerLevel,
                expPerLevel: farmExpPerLevel
            )
        }
    }
}
