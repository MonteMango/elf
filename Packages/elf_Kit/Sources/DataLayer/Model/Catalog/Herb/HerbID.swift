//
//  HerbID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for Herb definition IDs
public enum HerbIDType: IDType {}

/// Type-safe ID for Herb definitions
public typealias HerbID = TypedID<HerbIDType>
