//
//  DamageService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

/// Composite protocol that combines all damage-related services
///
/// This protocol aggregates focused interfaces for:
/// - Strength-based damage calculation
/// - Weapon-based damage calculation
/// - Total damage aggregation
public protocol DamageService: StrengthDamageCalculator,
                               WeaponDamageCalculator,
                               TotalDamageCalculator {}
