//
//  QuestID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for Quest definition IDs
public enum QuestIDType: IDType {}

/// Type-safe ID for Quest definitions
public typealias QuestID = TypedID<QuestIDType>
