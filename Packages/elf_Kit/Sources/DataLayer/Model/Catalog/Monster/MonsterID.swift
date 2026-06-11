//
//  MonsterID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for catalog `Monster` definition IDs
public enum MonsterIDType: IDType {}

/// Type-safe ID for catalog `Monster` definitions
public typealias MonsterID = TypedID<MonsterIDType>
