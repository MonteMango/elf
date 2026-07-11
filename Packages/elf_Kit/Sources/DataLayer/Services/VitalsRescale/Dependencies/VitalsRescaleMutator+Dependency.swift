//
//  VitalsRescaleMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var vitalsRescaleMutator: any VitalsRescaleMutator {
        get { self[VitalsRescaleMutatorKey.self] }
        set { self[VitalsRescaleMutatorKey.self] = newValue }
    }
}

private enum VitalsRescaleMutatorKey: DependencyKey {
    static var liveValue: any VitalsRescaleMutator { DefaultVitalsRescaleMutator() }
    static var testValue: any VitalsRescaleMutator { liveValue }
}
