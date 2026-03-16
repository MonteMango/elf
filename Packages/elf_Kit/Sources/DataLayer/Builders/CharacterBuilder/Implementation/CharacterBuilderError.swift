//
//  CharacterBuilderError.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Errors that can occur during character building
public enum CharacterBuilderError: Error, Sendable, Equatable {
    case missingAppearance
    case missingName
    case missingFightStyle
}
