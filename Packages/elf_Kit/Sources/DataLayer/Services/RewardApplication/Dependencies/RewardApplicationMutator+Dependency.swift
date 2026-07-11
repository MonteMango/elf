//
//  RewardApplicationMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var rewardApplicationMutator: any RewardApplicationMutator {
        get { self[RewardApplicationMutatorKey.self] }
        set { self[RewardApplicationMutatorKey.self] = newValue }
    }
}

private enum RewardApplicationMutatorKey: DependencyKey {
    static var liveValue: any RewardApplicationMutator { DefaultRewardApplicationMutator() }
    static var testValue: any RewardApplicationMutator { liveValue }
}
