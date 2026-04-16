//
//  CharacterCreationStage.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 25.11.25.
//

import Foundation

/// Stages of character creation flow
public enum CharacterCreationStage: Int, CaseIterable, Sendable, Hashable {
    case selectAppearance = 1
    case enterName = 2
    case selectFightStyle = 3
    case reviewAndFinalize = 4

    /// Next stage in the flow, or nil if this is the last stage
    public var next: CharacterCreationStage? {
        CharacterCreationStage(rawValue: self.rawValue + 1)
    }

    /// Previous stage in the flow, or nil if this is the first stage
    public var previous: CharacterCreationStage? {
        CharacterCreationStage(rawValue: self.rawValue - 1)
    }

    /// Whether this is the first stage
    public var isFirst: Bool {
        self == .selectAppearance
    }

    /// Whether this is the last stage
    public var isLast: Bool {
        self == .reviewAndFinalize
    }

    /// Human-readable title for the stage
    public var title: String {
        switch self {
        case .selectAppearance:
            return "Select Appearance"
        case .enterName:
            return "Enter Name"
        case .selectFightStyle:
            return "Select Fight Style"
        case .reviewAndFinalize:
            return "Review Character"
        }
    }

    /// Number representation for UI (1-4)
    public var number: Int {
        rawValue
    }
}
