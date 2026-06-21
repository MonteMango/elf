//
//  BuffApplicationService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var buffApplicationService: any BuffApplicationService {
        get { self[BuffApplicationServiceKey.self] }
        set { self[BuffApplicationServiceKey.self] = newValue }
    }
}

private enum BuffApplicationServiceKey: DependencyKey {
    static var liveValue: any BuffApplicationService { DefaultBuffApplicationService() }

    /// The default impl is stateless and reads its own dependencies via
    /// `@Dependency` — safe for tests that don't care about buff behaviour.
    /// `buffsRepository.testValue` provides an empty catalog so apply-calls
    /// no-op cleanly.
    static var testValue: any BuffApplicationService { DefaultBuffApplicationService() }
}
