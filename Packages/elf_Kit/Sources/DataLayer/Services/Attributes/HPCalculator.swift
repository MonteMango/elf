//
//  HPCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Calculates hit points from attributes
public protocol HPCalculator: Sendable {

    /// Calculate total hit points from multiple attribute sources
    ///
    /// - Parameter attributes: Array of attribute sources
    /// - Returns: Total calculated HP
    func calculateTotalHP(from attributes: [HeroAttributes]) -> Int
}
