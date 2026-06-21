//
//  GatheringEngine+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var gatheringEngine: any GatheringEngine {
        get { self[GatheringEngineKey.self] }
        set { self[GatheringEngineKey.self] = newValue }
    }
}

private enum GatheringEngineKey: DependencyKey {
    static var liveValue: any GatheringEngine { DefaultGatheringEngine() }
}
