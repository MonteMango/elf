//
//  TotalDamageCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Aggregates total damage from combat results
public protocol TotalDamageCalculator: Sendable {

    /// Calculate total damage from point status results
    ///
    /// - Parameter pointStatus: Map of body parts to their combat status
    /// - Returns: Total damage dealt
    func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int
}
