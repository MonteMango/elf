//
//  GameDayID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `GameDay` instance IDs
public enum GameDayIDType: IDType {}

/// Type-safe ID for `GameDay` instances
public typealias GameDayID = TypedID<GameDayIDType>
