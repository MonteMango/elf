//
//  DungeonID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for catalog `Dungeon` definition IDs
public enum DungeonIDType: IDType {}

/// Type-safe ID for catalog `Dungeon` definitions
public typealias DungeonID = TypedID<DungeonIDType>
