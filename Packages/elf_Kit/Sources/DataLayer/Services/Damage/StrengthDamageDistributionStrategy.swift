//
//  StrengthDamageDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.07.25.
//

public protocol StrengthDamageDistributionStrategy {
    func distribution(for strength: Int16) -> DamageDistribution
}
