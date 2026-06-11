//
//  OwnedItemID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `ElfItem` owned-instance IDs (a player-owned instance of a catalog item)
public enum OwnedItemIDType: IDType {}

/// Type-safe ID for `ElfItem` owned instances
public typealias OwnedItemID = TypedID<OwnedItemIDType>
