//
//  GameID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `Game` instance IDs
public enum GameIDType: IDType {}

/// Type-safe ID for `Game` instances
public typealias GameID = TypedID<GameIDType>
