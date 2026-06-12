//
//  WorldTurnRunner+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Dependencies

extension DependencyValues {
    public var worldTurnRunner: any WorldTurnRunner {
        get { self[WorldTurnRunnerKey.self] }
        set { self[WorldTurnRunnerKey.self] = newValue }
    }
}

private enum WorldTurnRunnerKey: DependencyKey {
    static var liveValue: any WorldTurnRunner { DefaultWorldTurnRunner() }
}
