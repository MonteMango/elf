//
//  FishID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for Fish definition IDs
public enum FishIDType: IDType {}

/// Type-safe ID for Fish definitions
public typealias FishID = TypedID<FishIDType>
