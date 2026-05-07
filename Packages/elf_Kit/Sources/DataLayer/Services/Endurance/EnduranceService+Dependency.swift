//
//  EnduranceService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var enduranceService: any EnduranceService {
        get { self[EnduranceServiceKey.self] }
        set { self[EnduranceServiceKey.self] = newValue }
    }
}

private enum EnduranceServiceKey: DependencyKey {
    static var liveValue: any EnduranceService { ElfEnduranceService() }
}
