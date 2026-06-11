//
//  MaterialID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for catalog `Material` definition IDs (monster-drop materials)
public enum MaterialIDType: IDType {}

/// Type-safe ID for catalog `Material` definitions
public typealias MaterialID = TypedID<MaterialIDType>
