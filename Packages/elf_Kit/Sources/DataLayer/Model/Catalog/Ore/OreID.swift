//
//  OreID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for Ore definition IDs
public enum OreIDType: IDType {}

/// Type-safe ID for Ore definitions
public typealias OreID = TypedID<OreIDType>
