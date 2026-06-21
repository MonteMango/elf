//
//  SkillProgressCalculator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var skillProgressCalculator: any SkillProgressCalculator {
        get { self[SkillProgressCalculatorKey.self] }
        set { self[SkillProgressCalculatorKey.self] = newValue }
    }
}

private enum SkillProgressCalculatorKey: DependencyKey {
    static var liveValue: any SkillProgressCalculator { ElfSkillProgressCalculator() }
}
