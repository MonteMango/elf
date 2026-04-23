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
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.armorService) var armorService
        return DefaultCombatantSnapshotBuilder(
            itemsRepository: itemsRepository,
            armorService: armorService
        )
    }
}
