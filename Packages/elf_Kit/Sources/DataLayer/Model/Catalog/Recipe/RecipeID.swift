//
//  RecipeID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for catalog `Recipe` definition IDs
public enum RecipeIDType: IDType {}

/// Type-safe ID for catalog `Recipe` definitions
public typealias RecipeID = TypedID<RecipeIDType>
