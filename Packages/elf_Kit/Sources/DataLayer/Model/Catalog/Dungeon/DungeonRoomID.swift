//
//  DungeonRoomID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `DungeonRoom` node IDs
public enum DungeonRoomIDType: IDType {}

/// Type-safe ID for `DungeonRoom` nodes
public typealias DungeonRoomID = TypedID<DungeonRoomIDType>
