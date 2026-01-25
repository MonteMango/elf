//
//  FarmActivity.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Represents the different farm activities available to the player
public enum FarmActivity: String, CaseIterable, Identifiable, Hashable, Sendable {
    case foraging
    case fishing
    case mining

    public var id: String { rawValue }

    public var title: String { rawValue.capitalized }

    public var imageName: String { rawValue }
}
