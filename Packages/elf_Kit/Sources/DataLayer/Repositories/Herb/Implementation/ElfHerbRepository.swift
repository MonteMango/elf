//
//  ElfHerbRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import os.log

public final class ElfHerbRepository: HerbRepository {

    // MARK: - Properties

    private static let log = OSLog(subsystem: "com.elfy.kit", category: "HerbRepository")
    private let base: BaseCollectionRepository<HerbData>

    // MARK: - Initialization

    public init(dataLoader: DataLoader = ElfDataLoader()) {
        self.base = BaseCollectionRepository(
            loadData: dataLoader.loadHerbsData,
            log: Self.log,
            resourceName: "Herbs.json"
        )
    }

    // MARK: - HerbRepository

    public func getHerb(id: HerbID) -> Herb? {
        base.getItem(id: id)
    }

    public func getAllHerbs() -> [Herb] {
        base.getAllItems()
    }

}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// `base` contains immutable dictionaries of value types.
extension ElfHerbRepository: @unchecked Sendable {}
