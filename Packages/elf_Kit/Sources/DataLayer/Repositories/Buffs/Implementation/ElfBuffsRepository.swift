//
//  ElfBuffsRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfBuffsRepository: BuffsRepository {

    private let items: [Buff]
    private let lookup: [UUID: Buff]

    public init(buffsData: BuffsData) {
        self.items = buffsData.buffs
        var lookup: [UUID: Buff] = [:]
        for buff in buffsData.buffs {
            lookup[buff.id] = buff
        }
        self.lookup = lookup
    }

    public func getAll() -> [Buff] { items }

    public func getById(id: UUID) -> Buff? { lookup[id] }
}
