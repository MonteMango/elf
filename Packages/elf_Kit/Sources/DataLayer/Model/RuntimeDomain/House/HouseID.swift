//
//  HouseID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `House` instance IDs
public enum HouseIDType: IDType {}

/// Type-safe ID for `House` instances
public typealias HouseID = TypedID<HouseIDType>
