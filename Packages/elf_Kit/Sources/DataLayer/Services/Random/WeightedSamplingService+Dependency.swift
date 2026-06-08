//
//  WeightedSamplingService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var weightedSamplingService: any WeightedSamplingService {
        get { self[WeightedSamplingServiceKey.self] }
        set { self[WeightedSamplingServiceKey.self] = newValue }
    }
}

private enum WeightedSamplingServiceKey: DependencyKey {
    static var liveValue: any WeightedSamplingService { ElfWeightedSamplingService() }
}
