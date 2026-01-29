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
}
