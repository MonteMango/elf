//
//  AppliedBuffID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `AppliedBuff` instance IDs
public enum AppliedBuffIDType: IDType {}

/// Type-safe ID for `AppliedBuff` instances
public typealias AppliedBuffID = TypedID<AppliedBuffIDType>
