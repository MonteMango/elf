//
//  CombatantSnapshotBuilder+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var snapshotBuilder: any CombatantSnapshotBuilder {
        get { self[CombatantSnapshotBuilderKey.self] }
        set { self[CombatantSnapshotBuilderKey.self] = newValue }
    }
}

private enum CombatantSnapshotBuilderKey: DependencyKey {
    static var liveValue: any CombatantSnapshotBuilder {
        fatalError("CombatantSnapshotBuilder must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It depends on async-loaded GameDataRepository and armorService.")
    }
}
