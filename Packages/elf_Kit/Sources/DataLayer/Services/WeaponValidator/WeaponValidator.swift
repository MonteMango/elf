//
//  WeaponValidator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import Foundation

/// Service for validating and resolving weapon/shield combinations
public protocol WeaponValidator {

    /// Validates item selection and resolves conflicts with currently equipped items
    /// - Parameters:
    ///   - itemId: UUID of the item being selected (nil to unequip)
    ///   - slot: The slot being modified (.weapons or .shields)
    ///   - currentItems: Currently equipped items
    /// - Returns: Updated items dictionary with conflicts resolved
    func validateAndResolve(
        selecting itemId: UUID?,
        for slot: HeroItemType,
        currentItems: [HeroItemType: UUID?]
    ) async -> [HeroItemType: UUID?]
}
