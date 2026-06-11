//
//  BuffID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for catalog `Buff` definition IDs
public enum BuffIDType: IDType {}

/// Type-safe ID for catalog `Buff` definitions
public typealias BuffID = TypedID<BuffIDType>
