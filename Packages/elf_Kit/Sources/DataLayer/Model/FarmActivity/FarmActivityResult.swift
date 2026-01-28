//
//  FarmActivityResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Unified result type for all farm activities
public enum FarmActivityResult: Sendable, Equatable {
    case fishing(FishingResult)
    case foraging(ForagingResult)
    case mining(MiningResult)

    // MARK: - Common Properties

    /// Skill progress data from the activity
    public var skillProgress: SkillProgressData {
        switch self {
        case .fishing(let result):
            return result.skillProgress
        case .foraging(let result):
            return result.skillProgress
        case .mining(let result):
            return result.skillProgress
        }
    }

    /// Whether the activity yielded any items
    public var isEmpty: Bool {
        switch self {
        case .fishing(let result):
            return result.isEmpty
        case .foraging(let result):
            return result.isEmpty
        case .mining(let result):
            return result.isEmpty
        }
    }

    /// Number of items gathered/caught
    public var itemCount: Int {
        switch self {
        case .fishing(let result):
            return result.fishCount
        case .foraging(let result):
            return result.herbCount
        case .mining(let result):
            return result.oreCount
        }
    }

    /// The activity type this result belongs to
    public var activity: FarmActivity {
        switch self {
        case .fishing:
            return .fishing
        case .foraging:
            return .foraging
        case .mining:
            return .mining
        }
    }
}
