//
//  DungeonType.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public enum DungeonType: String, Codable, Sendable, CaseIterable {
    case onePath
    case splitPath
    case randomPath
}
