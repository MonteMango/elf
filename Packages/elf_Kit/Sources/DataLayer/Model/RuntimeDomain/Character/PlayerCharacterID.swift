//
//  PlayerCharacterID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `PlayerCharacter` instance IDs
public enum PlayerCharacterIDType: IDType {}

/// Type-safe ID for `PlayerCharacter` instances
public typealias PlayerCharacterID = TypedID<PlayerCharacterIDType>
