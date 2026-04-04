//
//  IDTypes.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - ID Type Markers

/// Marker type for Fish definition IDs
public enum FishIDType: IDType {}

/// Marker type for Herb definition IDs
public enum HerbIDType: IDType {}

/// Marker type for Ore definition IDs
public enum OreIDType: IDType {}

/// Marker type for Quest Character definition IDs
public enum QuestCharacterIDType: IDType {}

/// Marker type for Quest definition IDs
public enum QuestIDType: IDType {}

// MARK: - Type Aliases

/// Type-safe ID for Fish definitions
public typealias FishID = TypedID<FishIDType>

/// Type-safe ID for Herb definitions
public typealias HerbID = TypedID<HerbIDType>

/// Type-safe ID for Ore definitions
public typealias OreID = TypedID<OreIDType>

/// Type-safe ID for Quest Character definitions
public typealias QuestCharacterID = TypedID<QuestCharacterIDType>

/// Type-safe ID for Quest definitions
public typealias QuestID = TypedID<QuestIDType>
