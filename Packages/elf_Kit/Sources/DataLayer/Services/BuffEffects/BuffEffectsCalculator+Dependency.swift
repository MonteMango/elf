//
//  BuffEffectsCalculator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var buffEffectsCalculator: any BuffEffectsCalculator {
        get { self[BuffEffectsCalculatorKey.self] }
        set { self[BuffEffectsCalculatorKey.self] = newValue }
    }
}

private enum BuffEffectsCalculatorKey: DependencyKey {
    static var liveValue: any BuffEffectsCalculator { DefaultBuffEffectsCalculator() }
}
