//
//  WorldTurnMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var worldTurnMutator: any WorldTurnMutator {
        get { self[WorldTurnMutatorKey.self] }
        set { self[WorldTurnMutatorKey.self] = newValue }
    }
}

private enum WorldTurnMutatorKey: DependencyKey {
    static var liveValue: any WorldTurnMutator { DefaultWorldTurnMutator() }
    static var testValue: any WorldTurnMutator { liveValue }
}
