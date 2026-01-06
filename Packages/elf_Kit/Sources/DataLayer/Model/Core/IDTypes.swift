//
//  IDTypes.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - ID Type Markers

/// Marker type for Elf entity IDs
public enum ElfIDType: IDType {}

/// Marker type for Monster entity IDs
public enum MonsterIDType: IDType {}

/// Marker type for base Item definition IDs (from JSON)
public enum ItemIDType: IDType {}

/// Marker type for owned Item instance IDs
public enum ItemInstanceIDType: IDType {}

/// Marker type for Material definition IDs
public enum MaterialIDType: IDType {}

/// Marker type for Battle session IDs
public enum BattleIDType: IDType {}

/// Marker type for Character/Player IDs
public enum CharacterIDType: IDType {}

/// Marker type for GameDay IDs
public enum GameDayIDType: IDType {}

// MARK: - Type Aliases

/// Type-safe ID for Elf entities
public typealias ElfID = TypedID<ElfIDType>

/// Type-safe ID for Monster entities
public typealias MonsterID = TypedID<MonsterIDType>

/// Type-safe ID for base Item definitions (loaded from JSON)
public typealias ItemID = TypedID<ItemIDType>

/// Type-safe ID for owned Item instances (in inventory/equipped)
public typealias ItemInstanceID = TypedID<ItemInstanceIDType>

/// Type-safe ID for Material definitions
public typealias MaterialID = TypedID<MaterialIDType>

/// Type-safe ID for Battle sessions
public typealias BattleID = TypedID<BattleIDType>

/// Type-safe ID for Character/Player entities
public typealias CharacterID = TypedID<CharacterIDType>

/// Type-safe ID for GameDay entries
public typealias GameDayID = TypedID<GameDayIDType>
