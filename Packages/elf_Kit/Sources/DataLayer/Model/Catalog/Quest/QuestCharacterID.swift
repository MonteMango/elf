//
//  QuestCharacterID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for Quest Character definition IDs
public enum QuestCharacterIDType: IDType {}

/// Type-safe ID for Quest Character definitions
public typealias QuestCharacterID = TypedID<QuestCharacterIDType>
