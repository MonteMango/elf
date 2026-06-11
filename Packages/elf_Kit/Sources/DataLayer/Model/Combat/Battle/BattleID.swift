//
//  BattleID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `Battle` instance IDs
public enum BattleIDType: IDType {}

/// Type-safe ID for `Battle` instances
public typealias BattleID = TypedID<BattleIDType>
