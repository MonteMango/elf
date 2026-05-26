//
//  EnduranceDamageReductionDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

public protocol EnduranceDamageReductionDistributionStrategy: Sendable {
    func distribution(for endurance: Int16) -> DamageDistribution
}
