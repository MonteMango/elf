//
//  CharacterAppearance.swift
//  elf_Kit
//
//  Created by Claude on 23.11.25.
//

import Foundation

/// Available character appearances for selection during character creation
public enum CharacterAppearance: Int, CaseIterable, Sendable {
    case appearance1 = 0
    case appearance2 = 1
    case appearance3 = 2

    /// Asset name for the appearance image
    public var imageName: String {
        switch self {
        case .appearance1:
            return "Yuuki Asuna"
        case .appearance2:
            return "Frieren"
        case .appearance3:
            return "Ais Wallenstein"
        }
    }
}
