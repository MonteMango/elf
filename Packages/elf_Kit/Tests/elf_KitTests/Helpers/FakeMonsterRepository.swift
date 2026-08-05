//
//  FakeMonsterRepository.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Foundation
@testable import elf_Kit

/// Empty-catalog `MonsterRepository` stub — enough to satisfy `@Dependency`
/// resolution in ViewModel init for tests that don't exercise monster data.
final class FakeMonsterRepository: MonsterRepository, @unchecked Sendable {
    func getMonsters(world: WorldType, level: Int) -> [Monster] { [] }
    func getAll() -> [Monster] { [] }
    func getById(id: Monster.ID) -> Monster? { nil }
}
