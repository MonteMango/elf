//
//  ItemID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for catalog `Item` definition IDs (weapon/robe/jewelry/defense/shield)
public enum ItemIDType: IDType {}

/// Type-safe ID for catalog `Item` definitions
public typealias ItemID = TypedID<ItemIDType>
