//
//  CombatantID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Marker type for `CombatantSnapshot` instance IDs (a combatant within a battle)
public enum CombatantIDType: IDType {}

/// Type-safe ID for `CombatantSnapshot` instances
public typealias CombatantID = TypedID<CombatantIDType>
