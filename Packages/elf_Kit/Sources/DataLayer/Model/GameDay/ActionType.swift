//
//  ActionType.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

/// Types of actions available during a normal day
public enum ActionType: String, CaseIterable, Sendable {
    case farm = "Farm"
    case hunt = "Hunt"
    case craft = "Craft"
    case quests = "Quests"

    /// SF Symbol icon name for the action
    public var iconName: String {
        switch self {
        case .farm: return "leaf.fill"
        case .hunt: return "target"
        case .craft: return "hammer.fill"
        case .quests: return "scroll.fill"
        }
    }
}
