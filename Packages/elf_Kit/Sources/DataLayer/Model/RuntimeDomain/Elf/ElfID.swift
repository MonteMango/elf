//
//  ElfID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `ElfInfo` instance IDs
public enum ElfIDType: IDType {}

/// Type-safe ID for `ElfInfo` instances
public typealias ElfID = TypedID<ElfIDType>
